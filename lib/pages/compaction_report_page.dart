import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/db.dart';

/// Previews (and prints) the compaction test report for a task.
class CompactionReportPage extends StatelessWidget {
  final int taskId;

  const CompactionReportPage({super.key, required this.taskId});

  static const _navy = PdfColor.fromInt(0xFF1F2A6B);

  static String _fmt(dynamic v) => v == null ? '' : '$v';

  static Future<List<int>> _buildPdf(int taskId) async {
    final task = await DbService.getTask(taskId);
    if (task == null) throw Exception('Task $taskId not found.');
    final test = await DbService.getCompactionTest(taskId);
    final details = await DbService.getCompactionTestDetails(taskId);

    final labelStyle =
        pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
    const valueStyle = pw.TextStyle(fontSize: 10);

    pw.Widget field(String label, dynamic value, {double width = 120}) {
      return pw.Container(
        width: width,
        padding: const pw.EdgeInsets.only(bottom: 8, right: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: labelStyle),
            pw.SizedBox(height: 2),
            pw.Text(_fmt(value), style: valueStyle),
          ],
        ),
      );
    }

    pw.Widget section(String title, List<pw.Widget> fields) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.Divider(thickness: 1, height: 6, color: _navy),
          pw.SizedBox(height: 4),
          pw.Wrap(children: fields),
          pw.SizedBox(height: 8),
        ],
      );
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => [
          pw.Text(
            'Compaction Test Report',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.SizedBox(height: 12),
          section('Task', [
            field('Task ID', task['id'], width: 80),
            field('Project ID', task['project_id'], width: 100),
            field('Sequence', task['sequence'], width: 80),
            field('Task Type', task['task_type'], width: 180),
            field('Extended', task['extended'], width: 180),
            field('Employee ID', task['employee_id']),
            field('Date Started', task['started']),
            field('Date Completed', task['completed']),
          ]),
          section('Test Information', [
            field('Source', test?['source'], width: 180),
            field('Type of Test', test?['test_type'], width: 180),
            field('Mold Number', test?['mold_number']),
            field('Hammer Weight', test?['hammer_weight']),
            field('Drop Distance', test?['drop_distance']),
            field('Number of Layers', test?['number_of_layers']),
            field('Number of Blows', test?['number_of_blows']),
            field(
              'Material Description',
              test?['material_description'],
              width: 360,
            ),
            field('Max Dry Density', test?['max_dry_density']),
            field('Opt Moisture', test?['opt_moisture']),
            field('Max Density w/OC', test?['max_density_oc']),
            field('Opt Moist w/OC', test?['opt_moist_oc']),
          ]),
          pw.Text(
            'Compaction Test Detail',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.Divider(thickness: 1, height: 6, color: _navy),
          pw.SizedBox(height: 4),
          if (details.isEmpty)
            pw.Text('No detail readings recorded.', style: valueStyle)
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Reading',
                'Weight wet sample + mold',
                'Weight wet sample + can',
                'Weight dry sample + can',
                'Weight of can',
              ],
              data: [
                for (var i = 0; i < details.length; i++)
                  [
                    '${i + 1}',
                    _fmt(details[i]['wt_wet_sample_mold']),
                    _fmt(details[i]['wt_wet_sample_can']),
                    _fmt(details[i]['wt_dry_sample_can']),
                    _fmt(details[i]['wt_can']),
                  ],
              ],
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headerDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _navy)),
              ),
            ),
        ],
      ),
    );
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Compaction Test Report — Task $taskId')),
      body: PdfPreview(
        build: (_) async => Uint8List.fromList(await _buildPdf(taskId)),
        pdfFileName: 'compaction_test_task_$taskId.pdf',
        maxPageWidth: 720,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
