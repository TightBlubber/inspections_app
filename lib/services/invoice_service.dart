import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'db.dart';

class InvoiceLine {
  final String task;
  final String description;
  final num amount;

  const InvoiceLine({
    required this.task,
    required this.description,
    required this.amount,
  });
}

class ProjectInvoice {
  final Map<String, dynamic> project;
  final Map<String, dynamic>? customer;
  final List<InvoiceLine> lines;

  const ProjectInvoice({
    required this.project,
    required this.customer,
    required this.lines,
  });

  num get total => lines.fold<num>(0, (sum, l) => sum + l.amount);
}

class InvoiceService {
  /// Parses MM/dd/yyyy (the format used by the app) or ISO yyyy-MM-dd.
  static DateTime? parseDate(String? text) {
    final s = (text ?? '').trim();
    if (s.isEmpty) return null;
    final us = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(s);
    if (us != null) {
      final m = int.parse(us.group(1)!);
      final d = int.parse(us.group(2)!);
      final y = int.parse(us.group(3)!);
      final date = DateTime(y, m, d);
      return date.month == m && date.day == d ? date : null;
    }
    final parsed = DateTime.tryParse(s);
    return parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  static String formatMoney(num value) {
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '${value < 0 ? '-' : ''}\$$whole.${parts[1]}';
  }

  /// Builds one invoice per project from the billing entered on its tasks.
  ///
  /// The date range applies to each task's completed date. Project-level
  /// billing (not tied to a task) has no date or billed flag, so it is only
  /// included when no filtering is requested.
  static Future<List<ProjectInvoice>> buildInvoices({
    DateTime? from,
    DateTime? to,
    required bool unbilledOnly,
  }) async {
    final tasks = await DbService.getAllTasksFull();
    final billing = await DbService.getAllProjectBilling();
    final codes = await DbService.getBillingCodes();
    final projects = await DbService.getAllProjectsFull();
    final customers = await DbService.getAllCustomersFull();

    final filtering = from != null || to != null || unbilledOnly;

    bool taskIncluded(Map<String, dynamic> task) {
      if (unbilledOnly &&
          '${task['date_billed'] ?? ''}'.trim().isNotEmpty) {
        return false;
      }
      if (from == null && to == null) return true;
      final completed = parseDate(task['completed']?.toString());
      if (completed == null) return false;
      if (from != null && completed.isBefore(from)) return false;
      if (to != null && completed.isAfter(to)) return false;
      return true;
    }

    final taskById = <int, Map<String, dynamic>>{
      for (final t in tasks)
        if (t['id'] is int) t['id'] as int: t,
    };
    final descByCode = <String, String>{
      for (final c in codes)
        '${c['billing_code_id'] ?? ''}': '${c['description'] ?? ''}',
    };
    final projectById = <String, Map<String, dynamic>>{
      for (final p in projects) '${p['project_id']}': p,
    };
    final customerById = <String, Map<String, dynamic>>{
      for (final c in customers) '${c['customer_id']}': c,
    };

    num sequenceOf(Map<String, dynamic>? task) =>
        num.tryParse('${task?['sequence'] ?? ''}') ?? double.maxFinite;

    final entriesByProject = <String, List<Map<String, dynamic>>>{};
    for (final b in billing) {
      final projectId = '${b['project_id'] ?? ''}';
      if (!projectById.containsKey(projectId)) continue;
      final taskId = b['task_id'];
      final task = taskId is int ? taskById[taskId] : null;
      if (task == null) {
        if (filtering) continue;
      } else if (!taskIncluded(task)) {
        continue;
      }
      entriesByProject.putIfAbsent(projectId, () => []).add(b);
    }

    final invoices = <ProjectInvoice>[];
    for (final entry in entriesByProject.entries) {
      final items = entry.value
        ..sort((a, b) => sequenceOf(a['task_id'] is int ? taskById[a['task_id']] : null)
            .compareTo(sequenceOf(b['task_id'] is int ? taskById[b['task_id']] : null)));

      final lines = <InvoiceLine>[];
      for (final b in items) {
        final taskId = b['task_id'];
        final task = taskId is int ? taskById[taskId] : null;
        final code = '${b['billing_code_id'] ?? ''}';
        final desc = descByCode[code] ?? '';
        final taskLabel = task == null
            ? 'Project'
            : [
                '${task['sequence'] ?? ''}',
                '${task['task_type'] ?? ''}',
              ].where((s) => s.isNotEmpty).join(' - ');
        lines.add(InvoiceLine(
          task: taskLabel,
          description: desc.isNotEmpty ? desc : code,
          amount: num.tryParse('${b['rate'] ?? ''}') ?? 0,
        ));
      }

      final project = projectById[entry.key]!;
      invoices.add(ProjectInvoice(
        project: project,
        customer: customerById['${project['customer_id'] ?? ''}'],
        lines: lines,
      ));
    }

    num idKey(ProjectInvoice i) =>
        num.tryParse('${i.project['project_id']}') ?? double.maxFinite;
    invoices.sort((a, b) {
      final byId = idKey(a).compareTo(idKey(b));
      return byId != 0
          ? byId
          : '${a.project['project_id']}'.compareTo('${b.project['project_id']}');
    });
    return invoices;
  }

  static Future<Uint8List> buildPdf(List<ProjectInvoice> invoices) async {
    final doc = pw.Document();
    final today = formatDate(DateTime.now());

    for (final invoice in invoices) {
      final project = invoice.project;
      final customer = invoice.customer;
      final projectId = '${project['project_id'] ?? ''}';
      final projectName = '${project['project_name'] ?? ''}';

      final billTo = <String>[
        if (customer != null) ...[
          '${customer['company_name'] ?? ''}',
          '${customer['company_department'] ?? ''}',
          [
            '${customer['contact_first_name'] ?? ''}',
            '${customer['contact_last_name'] ?? ''}',
          ].where((s) => s.isNotEmpty).join(' '),
          '${customer['address_line1'] ?? ''}',
          '${customer['address_line2'] ?? ''}',
          _cityLine(customer),
        ],
      ].where((s) => s.trim().isNotEmpty).toList();

      final siteLines = <String>[
        '${project['address_line1'] ?? ''}',
        _cityLine(project),
      ].where((s) => s.trim().isNotEmpty).toList();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date: $today'),
                    pw.Text('Project: $projectId'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _block('Bill To', billTo),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: _block('Project', [
                    if (projectName.isNotEmpty) projectName,
                    ...siteLines,
                  ]),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Task', bold: true),
                    _cell('Description', bold: true),
                    _cell('Amount', bold: true, right: true),
                  ],
                ),
                for (final line in invoice.lines)
                  pw.TableRow(
                    children: [
                      _cell(line.task),
                      _cell(line.description),
                      _cell(formatMoney(line.amount), right: true),
                    ],
                  ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell(''),
                    _cell('Total', bold: true, right: true),
                    _cell(formatMoney(invoice.total), bold: true, right: true),
                  ],
                ),
              ],
            ),
          ],
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ),
      );
    }

    return Uint8List.fromList(await doc.save());
  }

  static String _cityLine(Map<String, dynamic> m) {
    final city = '${m['city'] ?? ''}'.trim();
    final stateZip = [
      '${m['state_province'] ?? ''}'.trim(),
      '${m['postal_code'] ?? ''}'.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    return [city, stateZip].where((s) => s.isNotEmpty).join(', ');
  }

  static pw.Widget _block(String title, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        for (final l in lines) pw.Text(l, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false, bool right = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
