import 'package:flutter/material.dart';
import '../services/db.dart';
import 'compaction_report_page.dart';
import 'compaction_test_page.dart';
import 'task_detail_page.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  int? _selectedIndex;

  List<String> _extendedOptions = [''];
  List<String> _taskTypes = [];
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final taskCodes = await DbService.getTaskCodes();
      final taskCodeExts = await DbService.getTaskCodeExts();
      final data = await DbService.getAllTasks();
      final types = taskCodes
          .map((c) => c['task_description'] as String? ?? '')
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList();
      final extOptions = taskCodeExts
          .map((c) => c['long_description'] as String? ?? '')
          .where((d) => d.isNotEmpty)
          .toSet();
      if (!mounted) return;
      setState(() {
        _taskTypes = types.isEmpty ? [''] : types;
        _extendedOptions = ['', ...extOptions];
        _rows = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    }
  }

  Future<bool> _persist() async {
    try {
      for (final row in _rows) {
        final id = row['id'] as int?;
        if (id == null) continue;
        await DbService.updateTask(id, {
          'task_type': row['task_type'],
          'extended': row['extended'],
        });
      }
      return true;
    } catch (e) {
      if (mounted) _message('Save failed: $e');
      return false;
    }
  }

  Future<void> _save() async {
    if (await _persist() && mounted) Navigator.pop(context);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  bool get _hasSelection => _selectedIndex != null;

  Map<String, dynamic>? get _selectedRow =>
      _selectedIndex == null ? null : _rows[_selectedIndex!];

  Future<void> _openDetail() async {
    final row = _selectedRow;
    final id = row?['id'] as int?;
    if (row == null || id == null) return;
    // The detail page loads from the database, so grid edits are saved first.
    if (!await _persist() || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailPage(
          taskId: id,
          projectId: row['project_id'] as String? ?? '',
        ),
      ),
    );
    if (!mounted) return;
    await _reloadKeepingSelection(id);
  }

  Future<void> _openForm() async {
    final id = _selectedRow?['id'] as int?;
    if (id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompactionTestPage(taskId: id)),
    );
  }

  Future<void> _openReport() async {
    final id = _selectedRow?['id'] as int?;
    if (id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompactionReportPage(taskId: id)),
    );
  }

  Future<void> _reloadKeepingSelection(int taskId) async {
    await _load();
    if (!mounted) return;
    final index = _rows.indexWhere((r) => r['id'] == taskId);
    setState(() => _selectedIndex = index < 0 ? null : index);
  }

  Future<String?> _askApprover() async {
    final email = DbService.currentUserEmail;
    if (email != null && email.isNotEmpty) return email;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approved By'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Your name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    controller.dispose();
    return (name == null || name.isEmpty) ? null : name;
  }

  Future<void> _approve() async {
    final row = _selectedRow;
    final id = row?['id'] as int?;
    if (row == null || id == null) return;
    if (row['approved'] == true) {
      _message('This task is already approved.');
      return;
    }
    final approver = await _askApprover();
    if (approver == null || !mounted) return;
    final now = DateTime.now();
    final date =
        '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
    try {
      await DbService.updateTask(id, {
        'approved': true,
        'date_approved': date,
        'approved_by': approver,
      });
      if (!mounted) return;
      setState(() => row['approved'] = true);
      _message('Task approved.');
    } catch (e) {
      if (mounted) _message('Approve failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Data table ────
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Project ID',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Sequence',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Task Type',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Extended',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Approved',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: List.generate(_rows.length, (index) {
                          final row = _rows[index];
                          final extended = row['extended'] as String?;
                          return DataRow(
                            selected: _selectedIndex == index,
                            onSelectChanged: (selected) {
                              setState(() {
                                _selectedIndex = selected == true
                                    ? index
                                    : null;
                              });
                            },
                            cells: [
                              DataCell(
                                Text(row['project_id'] as String? ?? ''),
                              ),
                              DataCell(
                                Text((row['sequence'] ?? '').toString()),
                              ),
                              DataCell(
                                DropdownButton<String>(
                                  value: row['task_type'] as String?,
                                  isDense: true,
                                  underline: const SizedBox(),
                                  items:
                                      {
                                            ...(_taskTypes),
                                            if (row['task_type'] != null)
                                              row['task_type'] as String,
                                          }
                                          .map(
                                            (v) => DropdownMenuItem(
                                              value: v,
                                              child: Text(v),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(
                                      () => _rows[index]['task_type'] = value,
                                    );
                                  },
                                ),
                              ),
                              DataCell(
                                DropdownButton<String>(
                                  value: extended,
                                  isDense: true,
                                  underline: const SizedBox(),
                                  items:
                                      [
                                            ..._extendedOptions,
                                            if (extended != null &&
                                                !_extendedOptions.contains(
                                                  extended,
                                                ))
                                              extended,
                                          ]
                                          .map(
                                            (v) => DropdownMenuItem(
                                              value: v,
                                              child: Text(v),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(
                                      () => _rows[index]['extended'] = value,
                                    );
                                  },
                                ),
                              ),
                              DataCell(
                                Text(row['approved'] == true ? 'Yes' : 'No'),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
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
                            onPressed: _openDetail,
                          ),
                          _ActionButton(
                            label: 'Form',
                            enabled: _hasSelection,
                            onPressed: _openForm,
                          ),
                          _ActionButton(
                            label: 'Report',
                            enabled: _hasSelection,
                            onPressed: _openReport,
                          ),
                          _ActionButton(
                            label: 'Approve',
                            enabled: _hasSelection,
                            onPressed: _approve,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
