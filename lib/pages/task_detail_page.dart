import 'package:flutter/material.dart';
import '../services/db.dart';
import 'compaction_report_page.dart';
import 'compaction_test_page.dart';
import 'project_billing_page.dart';

class TaskDetailPage extends StatefulWidget {
  final int taskId;
  final String projectId;

  const TaskDetailPage({super.key, required this.taskId, this.projectId = ''});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final _sequence = TextEditingController();
  final _started = TextEditingController();
  final _completed = TextEditingController();

  Map<String, dynamic> _task = {};
  List<String> _taskTypes = [''];
  List<String> _extendedOptions = [''];
  List<String> _employeeIds = [''];
  String _taskType = '';
  String _extended = '';
  String _employeeId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sequence.dispose();
    _started.dispose();
    _completed.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final employees = await DbService.getEmployeeIds();
      final taskCodes = await DbService.getTaskCodes();
      final taskCodeExts = await DbService.getTaskCodeExts();
      final task = await DbService.getTask(widget.taskId);
      if (!mounted) return;
      if (task == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task not found.')));
        return;
      }
      final types = taskCodes
          .map((c) => c['task_description'] as String? ?? '')
          .where((d) => d.isNotEmpty)
          .toList();
      final exts = [
        '',
        ...taskCodeExts
            .map((c) => c['long_description'] as String? ?? '')
            .where((d) => d.isNotEmpty),
      ];
      final emps = ['', ...employees.where((e) => e.isNotEmpty)];

      // Keep saved values selectable even if they are no longer in the code lists.
      final savedType = task['task_type'] as String? ?? '';
      final savedExt = task['extended'] as String? ?? '';
      final savedEmp = task['employee_id'] as String? ?? '';
      if (savedType.isNotEmpty && !types.contains(savedType)) {
        types.insert(0, savedType);
      }
      if (types.isEmpty) types.add('');
      if (savedExt.isNotEmpty && !exts.contains(savedExt)) {
        exts.insert(1, savedExt);
      }
      if (savedEmp.isNotEmpty && !emps.contains(savedEmp)) {
        emps.insert(1, savedEmp);
      }

      setState(() {
        _task = task;
        _taskTypes = types;
        _extendedOptions = exts;
        _employeeIds = emps;
        _taskType = savedType.isNotEmpty ? savedType : types.first;
        _extended = savedExt;
        _employeeId = savedEmp;
        _sequence.text = '${task['sequence'] ?? ''}';
        _started.text = task['started'] as String? ?? '';
        _completed.text = task['completed'] as String? ?? '';
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

  Future<void> _save() async {
    try {
      await DbService.updateTask(widget.taskId, {
        'sequence': int.tryParse(_sequence.text.trim()),
        'task_type': _taskType,
        'extended': _extended,
        'employee_id': _employeeId.isNotEmpty ? _employeeId : null,
        'started': _started.text.isNotEmpty ? _started.text : null,
        'completed': _completed.text.isNotEmpty ? _completed.text : null,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  String get _projectId =>
      '${_task['project_id'] ?? (widget.projectId.isNotEmpty ? widget.projectId : '')}';

  String _text(String key) => '${_task[key] ?? ''}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Detail')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: _buildForm(),
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
                      _bottomButton('Billing', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProjectBillingPage(
                              projectId: _projectId,
                              taskId: widget.taskId,
                            ),
                          ),
                        );
                      }, enabled: _projectId.isNotEmpty),
                      _bottomButton('Form', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CompactionTestPage(taskId: widget.taskId),
                          ),
                        );
                      }),
                      _bottomButton('Report', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CompactionReportPage(taskId: widget.taskId),
                          ),
                        );
                      }),
                      _bottomButton('Save', _save, primary: true),
                      _bottomButton('Cancel', () => Navigator.pop(context)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildForm() {
    final approved = _task['approved'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row([
          _box('Task ID', _readOnly(_text('id')), flex: 2),
          _box(
            'Sequence',
            TextField(
              controller: _sequence,
              keyboardType: TextInputType.number,
              decoration: _decoration(),
            ),
            flex: 2,
          ),
          _box(
            'Task Type',
            _dropdown(
              _taskTypes,
              _taskType,
              (v) => setState(() => _taskType = v ?? ''),
            ),
            flex: 5,
          ),
          _box(
            'Extended',
            _dropdown(
              _extendedOptions,
              _extended,
              (v) => setState(() => _extended = v ?? ''),
            ),
            flex: 5,
          ),
        ]),
        _row([
          _box('Date Started', _dateField(_started)),
          _box('Date Completed', _dateField(_completed)),
          _box(
            'Employee ID',
            _dropdown(
              _employeeIds,
              _employeeId,
              (v) => setState(() => _employeeId = v ?? ''),
            ),
          ),
          _box('Project ID', _readOnly(_projectId)),
        ]),
        // These fields are display-only until the Tasks table has columns for them.
        _row([
          _box(
            'Approved',
            _readOnly(
              approved == true
                  ? 'Yes'
                  : approved == false
                  ? 'No'
                  : '',
            ),
          ),
          _box('Date Approved', _readOnly(_text('date_approved'))),
          _box('Date Billed', _readOnly(_text('date_billed'))),
          _box('Date Paid', _readOnly(_text('date_paid'))),
          _box('Approved By', _readOnly(_text('approved_by')), flex: 2),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _box(String label, Widget child, {int flex = 3}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration({Widget? suffixIcon}) => InputDecoration(
    border: const OutlineInputBorder(),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    suffixIcon: suffixIcon,
  );

  Widget _readOnly(String value) {
    return InputDecorator(
      decoration: _decoration().copyWith(
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      child: Text(value, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _dateField(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: _decoration(
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, size: 16),
          onPressed: () => _pickDate(controller),
        ),
      ),
    );
  }

  Widget _dropdown(
    List<String> options,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
    );
  }

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
}
