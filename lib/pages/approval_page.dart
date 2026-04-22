import 'package:flutter/material.dart';
import '../services/db.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  int? _selectedIndex;

  static const List<String> _taskTypeOptions = [
    'Inspection',
    'Testing',
    'Review',
    'Survey',
  ];

  static const List<String> _extendedOptions = [
    'Yes',
    'No',
  ];

  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DbService.getAllTasks();
      setState(() {
        _rows = List<Map<String, dynamic>>.from(data);
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

  Future<void> _save() async {
    try {
      for (final row in _rows) {
        final id = row['id'] as int?;
        if (id == null) continue;
        await DbService.updateTask(id, {
          'task_type': row['task_type'],
          'extended': row['extended'],
        });
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

  bool get _hasSelection => _selectedIndex != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ── Data table ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(
                      label: Text('Project ID',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Sequence',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Task Type',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Extended',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: List.generate(_rows.length, (index) {
                    final row = _rows[index];
                    return DataRow(
                      selected: _selectedIndex == index,
                      onSelectChanged: (selected) {
                        setState(() {
                          _selectedIndex = selected == true ? index : null;
                        });
                      },
                      cells: [
                        DataCell(Text(row['project_id'] as String? ?? '')),
                        DataCell(Text((row['sequence'] ?? '').toString())),
                        DataCell(
                          DropdownButton<String>(
                            value: row['task_type'] as String?,
                            isDense: true,
                            underline: const SizedBox(),
                            items: _taskTypeOptions
                                .map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _rows[index]['task_type'] = value);
                            },
                          ),
                        ),
                        DataCell(
                          DropdownButton<String>(
                            value: row['extended'] as String?,
                            isDense: true,
                            underline: const SizedBox(),
                            items: _extendedOptions
                                .map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _rows[index]['extended'] = value);
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // ── For Selected Task label + 4 buttons ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'For Selected Task',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _ActionButton(
                      label: 'Detail',
                      enabled: _hasSelection,
                      onPressed: () {},
                    ),
                    _ActionButton(
                      label: 'Form',
                      enabled: _hasSelection,
                      onPressed: () {},
                    ),
                    _ActionButton(
                      label: 'Report',
                      enabled: _hasSelection,
                      onPressed: () {},
                    ),
                    _ActionButton(
                      label: 'Approve',
                      enabled: _hasSelection,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── PRINT and Close buttons ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  label: 'PRINT',
                  enabled: true,
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Save',
                  enabled: true,
                  onPressed: _save,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Close',
                  enabled: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFED7422),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade500,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }
}
