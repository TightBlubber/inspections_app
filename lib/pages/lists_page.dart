import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/db.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  bool _loading = false;

  Future<void> _generateProjectsPdf({required bool activeOnly}) async {
    setState(() => _loading = true);
    try {
      final doc = await _buildProjectsDoc(activeOnly: activeOnly);
      final bytes = Uint8List.fromList(await doc.save());
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfViewPage(
            title: activeOnly ? 'Active Projects' : 'All Projects',
            pdfBytes: bytes,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _reportNavy = PdfColor.fromInt(0xFF1F2A6B);
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  String _projectDescription(Map<String, dynamic> p) => [
        p['address_line1'],
        p['city'],
        p['state_province'],
      ]
          .map((v) => (v as String? ?? '').trim())
          .where((v) => v.isNotEmpty)
          .join(', ');

  // Whole numbers print without a trailing ".0".
  String _num(dynamic v) {
    if (v == null) return '';
    if (v is num && v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  /// Builds a report in the shared house style. Row cells are a String, or a
  /// bool which is drawn as a checkbox.
  pw.Document _buildReportDoc({
    required String title,
    required List<_ReportCol> columns,
    required List<List<Object>> rows,
  }) {
    final serifItalic = pw.TextStyle(
      font: pw.Font.timesBoldItalic(),
      color: _reportNavy,
    );
    final body = pw.TextStyle(font: pw.Font.helvetica(), fontSize: 8);
    final head = serifItalic.copyWith(fontSize: 9);

    pw.Widget cell(Object value, _ReportCol col, pw.TextStyle style) {
      final pw.Widget child;
      if (value is bool) {
        child = pw.Container(
          width: 8,
          height: 8,
          padding: const pw.EdgeInsets.all(1.5),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.7)),
          child: value ? pw.Container(color: PdfColors.black) : null,
        );
      } else {
        child = pw.Text(value as String, style: style);
      }
      return pw.Container(
        width: col.width,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
        alignment:
            col.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: child,
      );
    }

    pw.Widget row(List<Object> values, pw.TextStyle style) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns.length; i++)
              cell(values[i], columns[i], style),
          ],
        );

    final now = DateTime.now();
    final today = '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} '
        '${now.day}, ${now.year}';

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(72),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: serifItalic.copyWith(fontSize: 17)),
            pw.SizedBox(height: 16),
            row([for (final c in columns) c.label], head),
            pw.SizedBox(height: 3),
            pw.Divider(thickness: 1, height: 1, color: _reportNavy),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(today, style: serifItalic.copyWith(fontSize: 8)),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: serifItalic.copyWith(fontSize: 8),
            ),
          ],
        ),
        build: (context) => [
          for (final r in rows)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: row(r, body),
            ),
        ],
      ),
    );
    return doc;
  }

  Future<pw.Document> _buildProjectsDoc({required bool activeOnly}) async {
    final projects = await DbService.getProjectsReport(activeOnly: activeOnly);
    if (activeOnly) {
      return _buildReportDoc(
        title: 'Active TSI Projects',
        columns: const [
          _ReportCol('Proj #', 36),
          _ReportCol('Project Name', 128),
          _ReportCol('Project Description', 220),
          _ReportCol('Cyl#', 40),
          _ReportCol('Cyl Size', 44),
        ],
        rows: [
          for (final p in projects)
            [
              p['project_id'] as String? ?? '',
              p['project_name'] as String? ?? '',
              _projectDescription(p),
              (p['cyl_number'] ?? '').toString(),
              (p['cyl_size'] ?? '').toString(),
            ],
        ],
      );
    }
    return _buildReportDoc(
      title: 'All TSI Projects',
      columns: const [
        _ReportCol('Project ID', 60, right: true),
        _ReportCol('Project Name', 150),
        _ReportCol('Project Description', 170),
        _ReportCol('Active', 40),
      ],
      rows: [
        for (final p in projects)
          [
            p['project_id'] as String? ?? '',
            p['project_name'] as String? ?? '',
            _projectDescription(p),
            p['active_project'] == true,
          ],
      ],
    );
  }

  pw.Document _buildProctorsDoc(
    List<Map<String, dynamic>> proctors, {
    required bool activeOnly,
  }) {
    return _buildReportDoc(
      title: activeOnly
          ? 'Proctors for Active TSI Projects'
          : 'Proctors for all TSI Projects',
      columns: [
        _ReportCol(activeOnly ? 'Project\nID' : 'Project ID', 56, right: true),
        _ReportCol(activeOnly ? 'Soil\nNo' : 'Soil No', 40, right: true),
        _ReportCol(activeOnly ? 'Max Dry\nDensity' : 'Max Dry Density', 70,
            right: true),
        _ReportCol(activeOnly ? 'Optimum\nMoisture' : 'Optimum Moisture', 80,
            right: true),
        const _ReportCol('Soil Classification', 222),
      ],
      rows: [
        for (final r in proctors)
          [
            r['project_id'] as String? ?? '',
            _num(r['soil_no']),
            _num(r['max_dry_density']),
            _num(r['optimum_moisture']),
            r['soil_classification'] as String? ?? '',
          ],
      ],
    );
  }

  Future<void> _generateProctorsPdf({required bool activeOnly}) async {
    setState(() => _loading = true);
    try {
      final rows = await DbService.getAllProctors(activeOnly: activeOnly);
      final doc = _buildProctorsDoc(rows, activeOnly: activeOnly);

      final bytes = Uint8List.fromList(await doc.save());
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfViewPage(
            title: activeOnly ? 'Active Project Proctors' : 'All Project Proctors',
            pdfBytes: bytes,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lists'),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ListButton(
                      label: 'Active Projects',
                      onPressed: () => _generateProjectsPdf(activeOnly: true),
                    ),
                    const SizedBox(height: 16),
                    _ListButton(
                      label: 'All Projects',
                      onPressed: () => _generateProjectsPdf(activeOnly: false),
                    ),
                    const SizedBox(height: 16),
                    _ListButton(
                      label: 'Active Project Proctors',
                      onPressed: () => _generateProctorsPdf(activeOnly: true),
                    ),
                    const SizedBox(height: 16),
                    _ListButton(
                      label: 'All Project Proctors',
                      onPressed: () => _generateProctorsPdf(activeOnly: false),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ReportCol {
  final String label;
  final double width;
  final bool right;

  const _ReportCol(this.label, this.width, {this.right = false});
}

class _PdfViewPage extends StatelessWidget {
  final String title;
  final Uint8List pdfBytes;

  const _PdfViewPage({required this.title, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (_) async => pdfBytes,
        maxPageWidth: 720,
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}

class _ListButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ListButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFED7422),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
