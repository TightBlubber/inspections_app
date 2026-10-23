import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../services/invoice_service.dart';

enum _DateRange { forever, dateRange }

enum _IncludeItems { all, unbilledOnly }

enum _OutputMethod { directToPrinter, previewOnScreen }

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  _DateRange _dateRange = _DateRange.forever;
  _IncludeItems _includeItems = _IncludeItems.all;
  _OutputMethod _outputMethod = _OutputMethod.previewOnScreen;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _process() async {
    DateTime? from;
    DateTime? to;
    if (_dateRange == _DateRange.dateRange) {
      from = InvoiceService.parseDate(_fromController.text);
      to = InvoiceService.parseDate(_toController.text);
      if (from == null || to == null) {
        _message('Enter valid From and To dates (MM/DD/YYYY).');
        return;
      }
      if (to.isBefore(from)) {
        _message('The To date must be on or after the From date.');
        return;
      }
    }

    setState(() => _processing = true);
    try {
      final invoices = await InvoiceService.buildInvoices(
        from: from,
        to: to,
        unbilledOnly: _includeItems == _IncludeItems.unbilledOnly,
      );
      if (!mounted) return;
      if (invoices.isEmpty) {
        _message('No billable items found for the selected options.');
        return;
      }
      final pdfBytes = await InvoiceService.buildPdf(invoices);
      if (!mounted) return;

      if (_outputMethod == _OutputMethod.previewOnScreen) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _InvoicePreviewPage(pdfBytes: pdfBytes),
          ),
        );
      } else {
        final printed = await Printing.layoutPdf(
          name: 'invoices.pdf',
          onLayout: (_) async => pdfBytes,
        );
        if (!printed && mounted) {
          _message('Print was canceled or unavailable.');
        }
      }
    } catch (e) {
      if (mounted) _message('Failed to process invoices: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Invoices'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top row: two side-by-side panels ────
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Panel(
                      title: 'Print invoices for:',
                      child: RadioGroup<_DateRange>(
                        groupValue: _dateRange,
                        onChanged: (v) => setState(() => _dateRange = v!),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _RadioRow<_DateRange>(
                              label: 'Forever',
                              value: _DateRange.forever,
                            ),
                            const _RadioRow<_DateRange>(
                              label: 'Date Range',
                              value: _DateRange.dateRange,
                            ),
                            const SizedBox(height: 12),
                            _LabeledField(
                              label: 'From:',
                              controller: _fromController,
                              enabled: _dateRange == _DateRange.dateRange,
                            ),
                            const SizedBox(height: 8),
                            _LabeledField(
                              label: 'To:',
                              controller: _toController,
                              enabled: _dateRange == _DateRange.dateRange,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      children: [
                        _Panel(
                          title: 'Include which items:',
                          child: RadioGroup<_IncludeItems>(
                            groupValue: _includeItems,
                            onChanged: (v) =>
                                setState(() => _includeItems = v!),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _RadioRow<_IncludeItems>(
                                  label: 'Include All Items',
                                  value: _IncludeItems.all,
                                ),
                                _RadioRow<_IncludeItems>(
                                  label: 'Include Only Unbilled Items',
                                  value: _IncludeItems.unbilledOnly,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Panel(
                          title: 'Output method:',
                          child: RadioGroup<_OutputMethod>(
                            groupValue: _outputMethod,
                            onChanged: (v) =>
                                setState(() => _outputMethod = v!),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _RadioRow<_OutputMethod>(
                                  label: 'Direct to printer',
                                  value: _OutputMethod.directToPrinter,
                                ),
                                _RadioRow<_OutputMethod>(
                                  label: 'Preview on screen',
                                  value: _OutputMethod.previewOnScreen,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Bottom buttons ───────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    label: _processing ? 'Processing...' : 'PROCESS',
                    onPressed: _processing ? null : _process,
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    label: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoicePreviewPage extends StatefulWidget {
  final Uint8List pdfBytes;

  const _InvoicePreviewPage({required this.pdfBytes});

  @override
  State<_InvoicePreviewPage> createState() => _InvoicePreviewPageState();
}

class _InvoicePreviewPageState extends State<_InvoicePreviewPage> {
  static const double _minWidth = 300;
  static const double _maxWidth = 1100;
  double _pageWidth = 500;

  void _zoom(double delta) => setState(
      () => _pageWidth = (_pageWidth + delta).clamp(_minWidth, _maxWidth));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          IconButton(
            tooltip: 'Zoom out',
            icon: const Icon(Icons.zoom_out),
            onPressed: _pageWidth > _minWidth ? () => _zoom(-100) : null,
          ),
          IconButton(
            tooltip: 'Zoom in',
            icon: const Icon(Icons.zoom_in),
            onPressed: _pageWidth < _maxWidth ? () => _zoom(100) : null,
          ),
        ],
      ),
      body: PdfPreview(
        maxPageWidth: _pageWidth,
        build: (_) async => widget.pdfBytes,
        pdfFileName: 'invoices.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _RadioRow<T> extends StatelessWidget {
  final String label;
  final T value;

  const _RadioRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<T>(
          value: value,
          activeColor: const Color(0xFFED7422),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            decoration: const InputDecoration(
              hintText: 'MM/DD/YYYY',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _ActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFED7422),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
