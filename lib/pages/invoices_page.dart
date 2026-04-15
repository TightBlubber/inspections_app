import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
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
            // ── Top row: two side-by-side panels ────────────────────────
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Print invoices for
                  Expanded(
                    child: _Panel(
                      title: 'Print invoices for:',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RadioRow<_DateRange>(
                            label: 'Forever',
                            value: _DateRange.forever,
                            groupValue: _dateRange,
                            onChanged: (v) => setState(() => _dateRange = v!),
                          ),
                          _RadioRow<_DateRange>(
                            label: 'Date Range',
                            value: _DateRange.dateRange,
                            groupValue: _dateRange,
                            onChanged: (v) => setState(() => _dateRange = v!),
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

                  const SizedBox(width: 12),

                  // Right: two stacked panels
                  Expanded(
                    child: Column(
                      children: [
                        // Include which items
                        _Panel(
                          title: 'Include which items:',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RadioRow<_IncludeItems>(
                                label: 'Include All Items',
                                value: _IncludeItems.all,
                                groupValue: _includeItems,
                                onChanged: (v) =>
                                    setState(() => _includeItems = v!),
                              ),
                              _RadioRow<_IncludeItems>(
                                label: 'Include Only Unbilled Items',
                                value: _IncludeItems.unbilledOnly,
                                groupValue: _includeItems,
                                onChanged: (v) =>
                                    setState(() => _includeItems = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Output method
                        _Panel(
                          title: 'Output method:',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RadioRow<_OutputMethod>(
                                label: 'Direct to printer',
                                value: _OutputMethod.directToPrinter,
                                groupValue: _outputMethod,
                                onChanged: (v) =>
                                    setState(() => _outputMethod = v!),
                              ),
                              _RadioRow<_OutputMethod>(
                                label: 'Preview on screen',
                                value: _OutputMethod.previewOnScreen,
                                groupValue: _outputMethod,
                                onChanged: (v) =>
                                    setState(() => _outputMethod = v!),
                              ),
                            ],
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
                  _ActionButton(label: 'PROCESS', onPressed: () {}),
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
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const _RadioRow({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<T>(
          value: value,
          groupValue: groupValue,
          activeColor: const Color(0xFFED7422),
          onChanged: onChanged,
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
  final VoidCallback onPressed;

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
