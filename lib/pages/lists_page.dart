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

  Future<pw.ThemeData> _pdfTheme() async {
    final base = await PdfGoogleFonts.nunitoRegular();
    final bold = await PdfGoogleFonts.nunitoBold();
    return pw.ThemeData.withFont(base: base, bold: bold);
  }

  Future<void> _generateProjectsPdf({required bool activeOnly}) async {
    setState(() => _loading = true);
    try {
      final projects = await DbService.getProjects(activeOnly: activeOnly);
      final theme = await _pdfTheme();

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.letter,
          header: (_) => pw.Text(
            activeOnly ? 'Active Projects' : 'All Projects',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          build: (context) => [
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Project ID', bold: true),
                    _cell('Project Name', bold: true),
                  ],
                ),
                ...projects.map(
                  (p) => pw.TableRow(children: [
                    _cell(p['project_id'] as String? ?? ''),
                    _cell(p['project_name'] as String? ?? ''),
                  ]),
                ),
              ],
            ),
          ],
        ),
      );

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

  Future<void> _generateProctorsPdf({required bool activeOnly}) async {
    setState(() => _loading = true);
    try {
      final rows = await DbService.getAllProctors(activeOnly: activeOnly);
      final theme = await _pdfTheme();

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.letter.landscape,
          header: (_) => pw.Text(
            activeOnly ? 'Active Project Proctors' : 'All Project Proctors',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          build: (context) => [
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Project ID', bold: true),
                    _cell('Soil #', bold: true),
                    _cell('Max Dry Density', bold: true),
                    _cell('Optimum Moisture', bold: true),
                    _cell('Soil Classification', bold: true),
                  ],
                ),
                ...rows.map(
                  (r) => pw.TableRow(children: [
                    _cell(r['project_id'] as String? ?? ''),
                    _cell((r['soil_no'] ?? '').toString()),
                    _cell((r['max_dry_density'] ?? '').toString()),
                    _cell((r['optimum_moisture'] ?? '').toString()),
                    _cell(r['soil_classification'] as String? ?? ''),
                  ]),
                ),
              ],
            ),
          ],
        ),
      );

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

  pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
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
