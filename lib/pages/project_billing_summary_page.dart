import 'package:flutter/material.dart';
import '../services/db.dart';

/// Read-only view of every task's billing for one project.
class ProjectBillingSummaryPage extends StatefulWidget {
  final String projectId;
  const ProjectBillingSummaryPage({super.key, required this.projectId});

  @override
  State<ProjectBillingSummaryPage> createState() =>
      _ProjectBillingSummaryPageState();
}

class _ProjectBillingSummaryPageState extends State<ProjectBillingSummaryPage> {
  List<Map<String, String>> _rows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codes = await DbService.getBillingCodes();
      final tasks = await DbService.getTasks(widget.projectId);
      final billing = await DbService.getProjectBilling(widget.projectId);

      final descById = <String, String>{
        for (final c in codes)
          (c['billing_code_id'] as String? ?? ''):
              (c['description'] as String? ?? ''),
      };
      final taskById = <int, Map<String, dynamic>>{
        for (final t in tasks) t['id'] as int: t,
      };

      String taskLabel(int? id) {
        final t = taskById[id];
        if (t == null) return 'Project';
        final seq = t['sequence']?.toString() ?? '';
        final type = t['task_type'] as String? ?? '';
        return [seq, type].where((s) => s.isNotEmpty).join(' – ');
      }

      num order(Map<String, dynamic> b) {
        final t = taskById[b['task_id']];
        return num.tryParse(t?['sequence']?.toString() ?? '') ??
            double.maxFinite;
      }

      final sorted = List<Map<String, dynamic>>.from(billing)
        ..sort((a, b) => order(a).compareTo(order(b)));

      final rows = <Map<String, String>>[];
      num grand = 0;
      num taskSum = 0;
      String? currentTask;
      void flushSubtotal() {
        if (currentTask != null) {
          rows.add({
            'task': currentTask,
            'code': 'Task total',
            'rate': taskSum.toStringAsFixed(2),
            'bold': '1',
          });
        }
      }

      for (final b in sorted) {
        final code = b['billing_code_id'] as String? ?? '';
        final desc = descById[code] ?? '';
        final label = taskLabel(b['task_id'] as int?);
        if (label != currentTask) {
          flushSubtotal();
          currentTask = label;
          taskSum = 0;
        }
        final rate = num.tryParse(b['rate']?.toString() ?? '') ?? 0;
        taskSum += rate;
        grand += rate;
        rows.add({
          'task': label,
          'code': desc.isNotEmpty ? desc : code,
          'rate': rate.toStringAsFixed(2),
        });
      }
      flushSubtotal();
      if (rows.isNotEmpty) {
        rows.add({
          'task': 'Project',
          'code': 'Total',
          'rate': grand.toStringAsFixed(2),
          'bold': '1',
        });
      }

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Billing — ${widget.projectId}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _rows.isEmpty
                      ? const Center(
                          child: Text('No billing entered for this project.'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1000),
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(
                                      label: Text('Task',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    DataColumn(
                                      label: Text('Billing Code',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    DataColumn(
                                      label: Text('Rate',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      numeric: true,
                                    ),
                                  ],
                                  rows: _rows.map((r) {
                                    final style = r['bold'] == '1'
                                        ? const TextStyle(
                                            fontWeight: FontWeight.bold)
                                        : null;
                                    return DataRow(cells: [
                                      DataCell(Text(r['task']!, style: style)),
                                      DataCell(Text(r['code']!, style: style)),
                                      DataCell(
                                          Text('\$ ${r['rate']}', style: style)),
                                    ]);
                                  }).toList(),
                                ),
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
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
