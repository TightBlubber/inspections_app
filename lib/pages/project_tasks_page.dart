import 'package:flutter/material.dart';
import '../services/db.dart';
import '../widgets/confirm_delete_dialog.dart';
import 'compaction_test_page.dart';
import 'project_billing_page.dart';
import 'task_detail_page.dart';

class ProjectTasksPage extends StatefulWidget {
  final String projectId;

  const ProjectTasksPage({super.key, this.projectId = ''});

  @override
  State<ProjectTasksPage> createState() => _ProjectTasksPageState();
}

class _ProjectTasksPageState extends State<ProjectTasksPage> {
  final List<_TaskRow> _rows = [];
  final List<int> _deletedIds = [];
  bool _isLoading = true;
  int? _selectedIndex;

  List<String> _taskTypes = [];
  List<String> _employeeIds = [];
  List<String> _extendedOptions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final employees = await DbService.getEmployeeIds();
      final taskCodes = await DbService.getTaskCodes();
      final taskCodeExts = await DbService.getTaskCodeExts();
      final tasks = widget.projectId.isNotEmpty
          ? await DbService.getTasks(widget.projectId)
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        for (final row in _rows) {
          row.dispose();
        }
        _rows.clear();
        _selectedIndex = null;
        _employeeIds = employees.isNotEmpty ? employees : [''];
        _taskTypes = taskCodes
            .map((c) => c['task_description'] as String? ?? '')
            .where((desc) => desc.isNotEmpty)
            .toList();
        if (_taskTypes.isEmpty) _taskTypes = [''];
        final extDescs = taskCodeExts
            .map((c) => c['long_description'] as String? ?? '')
            .where((d) => d.isNotEmpty)
            .toList();
        _extendedOptions = ['', ...extDescs];
        for (final t in tasks) {
          final savedType = t['task_type'] as String? ?? '';
          if (savedType.isNotEmpty && !_taskTypes.contains(savedType)) {
            _taskTypes.insert(0, savedType);
          }
          final savedExt = t['extended'] as String? ?? '';
          if (savedExt.isNotEmpty && !_extendedOptions.contains(savedExt)) {
            _extendedOptions.insert(1, savedExt);
          }
          final row = _TaskRow(
            id: t['id'] as int?,
            taskType: savedType.isNotEmpty ? savedType : _taskTypes.first,
            extended: savedExt,
            employeeId: t['employee_id'] as String? ?? _employeeIds.first,
          );
          row.started.text = t['started'] as String? ?? '';
          row.completed.text = t['completed'] as String? ?? '';
          _rows.add(row);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (await _persist() && mounted) Navigator.pop(context);
  }

  Future<bool> _persist() async {
    try {
      for (final id in List.of(_deletedIds)) {
        try {
          await DbService.deleteTask(id);
          _deletedIds.remove(id);
        } catch (e) {
          if (mounted) {
            await showDeleteFailed(context, itemName: 'a task', error: e);
          }
          return false;
        }
      }
      for (var i = 0; i < _rows.length; i++) {
        final row = _rows[i];
        final data = {
          'project_id': widget.projectId,
          'sequence': i + 1,
          'task_type': row.taskType,
          'extended': row.extended,
          'employee_id': row.employeeId.isNotEmpty ? row.employeeId : null,
          'started': row.started.text.isNotEmpty ? row.started.text : null,
          'completed': row.completed.text.isNotEmpty
              ? row.completed.text
              : null,
        };
        if (row.id != null) {
          await DbService.updateTask(row.id!, data);
        } else {
          final res = await DbService.insertTask(data);
          row.id = res['id'] as int?;
        }
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
      return false;
    }
  }

  void _addRow() {
    setState(() {
      _selectedIndex = _rows.length;
      _rows.add(
        _TaskRow(
          taskType: _taskTypes.isNotEmpty ? _taskTypes.first : '',
          extended: _extendedOptions.first,
          employeeId: _employeeIds.isNotEmpty ? _employeeIds.first : '',
        ),
      );
    });
  }

  Future<void> _removeRow(int index) async {
    if (_rows[index].id != null) {
      final confirmed = await confirmDelete(context, itemName: 'this task');
      if (!confirmed || !mounted) return;
    }
    setState(() {
      final id = _rows[index].id;
      if (id != null) _deletedIds.add(id);
      _rows[index].dispose();
      _rows.removeAt(index);
      _selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.projectId.isEmpty ? 'Tasks' : 'Tasks — ${widget.projectId}',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            _buildHeader(),
                            const Divider(height: 8),
                            // Rows
                            ..._rows.asMap().entries.map((entry) {
                              return _buildRow(entry.key, entry.value);
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _bottomButton(
                        'Detail',
                        _openDetail,
                        enabled: hasSelection,
                      ),
                      _bottomButton(
                        'Billing',
                        _openBilling,
                        enabled: hasProject,
                      ),
                      _bottomButton(
                        'Form',
                        _openForm,
                        enabled: hasSelection,
                      ),
                      _bottomButton(
                        'Report',
                        () => _comingSoon('Report'),
                        enabled: hasSelection,
                      ),
                      _bottomButton('New', _addRow),
                      // Saves pending changes before closing.
                      _bottomButton('Close', _save, primary: true),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  bool get hasProject => widget.projectId.isNotEmpty;
  bool get hasSelection => _selectedIndex != null;

  Widget _bottomButton(
    String label,
    VoidCallback onPressed, {
    bool primary = false,
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary
            ? const Color(0xFFED7422)
            : Colors.grey.shade200,
        foregroundColor: primary ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  void _comingSoon(String name) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$name is not available yet.')));
  }

  Future<int?> _persistedSelectedTaskId() async {
    final index = _selectedIndex;
    if (index == null) return null;
    // The detail and form pages load the task from the database, so unsaved rows must be saved first.
    if (!await _persist() || !mounted) return null;
    return _rows[index].id;
  }

  Future<void> _openForm() async {
    final id = await _persistedSelectedTaskId();
    if (id == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompactionTestPage(taskId: id)),
    );
  }

  Future<void> _openDetail() async {
    final index = _selectedIndex;
    final id = await _persistedSelectedTaskId();
    if (index == null || id == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailPage(taskId: id, projectId: widget.projectId),
      ),
    );
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _load();
    if (!mounted) return;
    setState(() {
      if (index < _rows.length) _selectedIndex = index;
    });
  }

  void _openBilling() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectBillingPage(projectId: widget.projectId),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: const [
        SizedBox(
          width: 70,
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
          width: 120,
          child: Text(
            'Employee ID',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: 8),
        SizedBox(
          width: 200,
          child: Text('Started', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 8),
        SizedBox(
          width: 200,
          child: Text(
            'Completed',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: 40),
      ],
    );
  }

  Widget _buildRow(int index, _TaskRow row) {
    final selected = _selectedIndex == index;
    return Listener(
      onPointerDown: (_) {
        if (!selected) setState(() => _selectedIndex = index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFED7422).withValues(alpha: 0.15)
              : null,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sequence
            SizedBox(
              width: 70,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            // Task Type
            SizedBox(
              width: 350,
              child: DropdownButtonFormField<String>(
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
            // Extended
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<String>(
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
                onChanged: (v) => setState(() => row.extended = v ?? ''),
              ),
            ),
            const SizedBox(width: 8),
            // Employee ID
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                initialValue: row.employeeId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                items: _employeeIds
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => row.employeeId = v!),
              ),
            ),
            const SizedBox(width: 8),
            // Started
            SizedBox(
              width: 200,
              child: TextField(
                controller: row.started,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    onPressed: () => _pickDate(context, row.started),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Completed
            SizedBox(
              width: 200,
              child: TextField(
                controller: row.completed,
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    onPressed: () => _pickDate(context, row.completed),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeRow(index),
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }
}

class _TaskRow {
  int? id;
  String taskType;
  String extended;
  String employeeId;
  final TextEditingController started = TextEditingController();
  final TextEditingController completed = TextEditingController();

  _TaskRow({
    this.id,
    required this.taskType,
    required this.extended,
    required this.employeeId,
  });

  void dispose() {
    started.dispose();
    completed.dispose();
  }
}
