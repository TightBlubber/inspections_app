import 'package:flutter/material.dart';
import '../services/db.dart';

class ProjectBillingPage extends StatefulWidget {
  final String projectId;
  const ProjectBillingPage({super.key, required this.projectId});

  @override
  State<ProjectBillingPage> createState() => _ProjectBillingPageState();
}

class _ProjectBillingPageState extends State<ProjectBillingPage> {
  List<String> _billingCodeOptions = [];
  final List<_BillingRow> _rows = [];
  final List<int> _deletedIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codes = await DbService.getBillingCodes();
      final billing = await DbService.getProjectBilling(widget.projectId);
      setState(() {
        _billingCodeOptions = codes
            .map((c) => c['billing_code_id'] as String)
            .toList();
        for (final b in billing) {
          _rows.add(_BillingRow(
            id: b['id'] as int?,
            code: b['billing_code_id'] as String? ??
                (_billingCodeOptions.isNotEmpty ? _billingCodeOptions.first : ''),
            rate: (b['rate'] ?? '').toString(),
          ));
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.rateController.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    try {
      for (final id in _deletedIds) {
        await DbService.deleteProjectBilling(id);
      }
      for (final row in _rows) {
        final data = {
          'project_id': widget.projectId,
          'billing_code_id': row.code,
          'rate': double.tryParse(row.rateController.text.trim()) ?? 0.0,
        };
        if (row.id != null) {
          await DbService.updateProjectBilling(row.id!, data);
        } else {
          final res = await DbService.insertProjectBilling(data);
          row.id = res['id'] as int?;
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  void _addRow() {
    if (_billingCodeOptions.isEmpty) return;
    setState(() {
      _rows.add(_BillingRow(code: _billingCodeOptions.first));
    });
  }

  void _removeRow(int index) {
    setState(() {
      final id = _rows[index].id;
      if (id != null) _deletedIds.add(id);
      _rows[index].rateController.dispose();
      _rows.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          flex: 3,
                          child: Text('Billing Code',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          flex: 2,
                          child: Text('Rate',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 40), // space for delete icon
                      ],
                    ),
                    const Divider(),
                    ..._rows.asMap().entries.map((entry) {
                      final i = entry.key;
                      final row = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: row.code,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                                items: _billingCodeOptions
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => row.code = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: row.rateController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  prefixText: '\$ ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _removeRow(i),
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Row'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFED7422),
                      ),
                    ),
                  ],
                );

                if (!isWide) return content;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: content,
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED7422),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save & Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingRow {
  int? id;
  String code;
  final TextEditingController rateController;

  _BillingRow({this.id, required this.code, String rate = ''})
      : rateController = TextEditingController(text: rate);
}
