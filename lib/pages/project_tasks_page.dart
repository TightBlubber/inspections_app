import 'package:flutter/material.dart';
import '../services/db.dart';

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
      setState(() {
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
          _rows.add(row);
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
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    try {
      for (final id in _deletedIds) {
        await DbService.deleteTask(id);
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
        };
        if (row.id != null) {
          await DbService.updateTask(row.id!, data);
        } else {
          final res = await DbService.insertTask(data);
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
    setState(() {
      _rows.add(_TaskRow(
        taskType: _taskTypes.isNotEmpty ? _taskTypes.first : '',
        extended: _extendedOptions.first,
        employeeId: _employeeIds.isNotEmpty ? _employeeIds.first : '',
      ));
    });
  }

  void _removeRow(int index) {
    setState(() {
      final id = _rows[index].id;
      if (id != null) _deletedIds.add(id);
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectId.isEmpty
            ? 'Tasks'
            : 'Tasks — ${widget.projectId}'),
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

  Widget _buildHeader() {
    return Row(
      children: const [
        SizedBox(
          width: 70,
          child: Text('Seq',
              style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
        SizedBox(width: 8),
        SizedBox(
          width: 350,
          child: Text('Task Type', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 8),
        SizedBox(
          width: 250,
          child: Text('Extended', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text('Employee ID', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 8),
        SizedBox(
          width: 200,
          child: Text('Started', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 40),
      ],
    );
  }

  Widget _buildRow(int index, _TaskRow row) {
    return Padding(
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
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  onPressed: () => _pickDate(context, row.started),
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
    );
  }

  Future<void> _pickDate(
      BuildContext context, TextEditingController controller) async {
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

  _TaskRow({
    this.id,
    required this.taskType,
    required this.extended,
    required this.employeeId,
  });

  void dispose() {
    started.dispose();
  }
}
