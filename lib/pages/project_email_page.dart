import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/db.dart';

class ProjectEmailPage extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectEmailPage({super.key, required this.project});

  @override
  State<ProjectEmailPage> createState() => _ProjectEmailPageState();
}

class _ProjectEmailPageState extends State<ProjectEmailPage> {
  final List<_EmailReportRow> _rows = [];
  List<String> _taskTypes = [''];
  List<String> _extendedOptions = [''];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final projectId = widget.project['project_id']?.toString() ?? '';
      final taskCodes = await DbService.getTaskCodes();
      final taskCodeExts = await DbService.getTaskCodeExts();
      final tasks = projectId.isNotEmpty
          ? await DbService.getTasks(projectId)
          : <Map<String, dynamic>>[];
      final types = taskCodes
          .map((c) => c['task_description'] as String? ?? '')
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList();
      final extOptions = taskCodeExts
          .map((c) => c['long_description'] as String? ?? '')
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList();
      if (!mounted) return;
      setState(() {
        _taskTypes = types.isEmpty ? [''] : types;
        _extendedOptions = ['', ...extOptions];
        _rows.clear();
        for (final t in tasks) {
          final taskType = t['task_type'] as String? ?? '';
          final extended = t['extended'] as String? ?? '';
          if (taskType.isNotEmpty && !_taskTypes.contains(taskType)) {
            _taskTypes.insert(0, taskType);
          }
          if (extended.isNotEmpty && !_extendedOptions.contains(extended)) {
            _extendedOptions.insert(1, extended);
          }
          _rows.add(
            _EmailReportRow(
              taskType: taskType.isNotEmpty ? taskType : _taskTypes.first,
              extended: extended,
            ),
          );
        }
        if (_rows.isEmpty) {
          _rows.add(
            _EmailReportRow(taskType: _taskTypes.first, extended: ''),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tasks: $e')),
      );
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(
        _EmailReportRow(
          taskType: _taskTypes.first,
          extended: '',
          print: false,
          email: false,
        ),
      );
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _rows.removeAt(index);
    });
  }

  Future<Uint8List> _buildReportPdf(List<_EmailReportRow> selectedRows) async {
    final doc = pw.Document();
    final projectId = widget.project['project_id'] as String? ?? '';
    final projectName = widget.project['project_name'] as String? ?? '';
    final now = DateTime.now();
    final generatedOn =
        '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (context) => [
          pw.Text(
            'Project Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Project: $projectId ${projectName.isEmpty ? '' : '- $projectName'}',
          ),
          pw.Text('Generated: $generatedOn'),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _pdfCell('Seq', bold: true),
                  _pdfCell('Task Type', bold: true),
                  _pdfCell('Extended', bold: true),
                ],
              ),
              ...selectedRows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return pw.TableRow(
                  children: [
                    _pdfCell('${index + 1}'),
                    _pdfCell(row.taskType),
                    _pdfCell(row.extended),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
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

  List<String> _recipientEmails() {
    final parsed = <String>{};
    final rawValues = [
      widget.project['email'] as String? ?? '',
      widget.project['email_breaks'] as String? ?? '',
    ];

    for (final raw in rawValues) {
      for (final token in raw.split(RegExp(r'[;,\s]+'))) {
        final trimmed = token.trim();
        if (trimmed.contains('@')) {
          parsed.add(trimmed);
        }
      }
    }

    return parsed.toList();
  }

  Future<void> _printReports() async {
    final selectedRows = _rows.where((r) => r.print).toList();
    if (selectedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one row to print.')),
      );
      return;
    }

    try {
      final pdfBytes = await _buildReportPdf(selectedRows);
      if (!mounted) return;
      final projectId = widget.project['project_id'] as String? ?? 'project';
      final fileName = 'project_${projectId}_report.pdf';
      final printed = await Printing.layoutPdf(
        name: fileName,
        onLayout: (_) async => pdfBytes,
      );
      if (!printed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print was canceled or unavailable.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create report: $e')));
    }
  }

  Future<void> _emailReports() async {
    final selectedRows = _rows.where((r) => r.email).toList();
    if (selectedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one row to email.')),
      );
      return;
    }

    final canEmail = widget.project['email_reports'] as bool? ?? false;
    if (!canEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is disabled for this project.')),
      );
      return;
    }

    try {
      final pdfBytes = await _buildReportPdf(selectedRows);
      if (!mounted) return;
      final projectId = widget.project['project_id'] as String? ?? 'project';
      final fileName = 'project_${projectId}_report.pdf';
      final recipients = _recipientEmails();

      if (recipients.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No project email found for this project.'),
          ),
        );
        return;
      }

      final response = await Supabase.instance.client.functions.invoke(
        'send-report-email',
        body: {
          'emails': recipients,
          'subject':
              'Inspection Report - ${widget.project['project_name'] ?? ''}',
          'body': 'Attached is your requested inspection report.',
          'filename': fileName,
          'pdfBase64': base64Encode(pdfBytes),
        },
      );

      if (!mounted) return;
      if (response.status < 200 || response.status >= 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Automatic email failed. Please contact support.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email sent to ${recipients.join(', ')}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Reports – ${widget.project['project_name'] ?? ''}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      _buildHeaderRow(),
                      const Divider(height: 1),
                      // Data rows
                      ..._rows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        return _buildDataRow(index, row);
                      }),
                      // Add row button
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton.icon(
                          onPressed: _addRow,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Row'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _printReports,
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Print Reports'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED7422),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _emailReports,
                  icon: const Icon(Icons.email_outlined, size: 16),
                  label: const Text('Email Reports'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED7422),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ], //
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: const [
          SizedBox(
            width: 60,
            child: Text(
              'Seq',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 350,
            child: Text(
              'Task Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 250,
            child: Text(
              'Extended',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              'Print',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 8),
          // Delete column placeholder
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildDataRow(int index, _EmailReportRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Sequence
          SizedBox(
            width: 60,
            child: Text('${index + 1}', textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),
          // Task Type dropdown
          SizedBox(
            width: 350,
            child: DropdownButtonFormField<String>(
              key: ObjectKey(row),
              initialValue: row.taskType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
              items: _taskTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => row.taskType = v!),
            ),
          ),
          const SizedBox(width: 8),
          // Extended dropdown
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String>(
              key: ObjectKey(row),
              initialValue: row.extended,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
              items: _extendedOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => row.extended = v!),
            ),
          ),
          const SizedBox(width: 8),
          // Print checkbox
          SizedBox(
            width: 60,
            child: Center(
              child: Checkbox(
                value: row.print,
                onChanged: (v) => setState(() => row.print = v ?? false),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Email checkbox
          SizedBox(
            width: 60,
            child: Center(
              child: Checkbox(
                value: row.email,
                onChanged: (v) => setState(() => row.email = v ?? false),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red,
              padding: EdgeInsets.zero,
              onPressed: () => _deleteRow(index),
              tooltip: 'Remove row',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailReportRow {
  String taskType;
  String extended;
  bool print;
  bool email;

  _EmailReportRow({
    required this.taskType,
    required this.extended,
    this.print = false,
    this.email = false,
  });
}
