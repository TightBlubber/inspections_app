import 'package:flutter/material.dart';
import '../services/db.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/neutral_button_colors.dart';

class TaskCodesPage extends StatefulWidget {
  const TaskCodesPage({super.key});

  @override
  State<TaskCodesPage> createState() => _TaskCodesPageState();
}

class _TaskCodesPageState extends State<TaskCodesPage> {
  List<List<TextEditingController>> _controllers = [];
  final List<String> _deletedIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _addRow();
    _load();
  }

  List<TextEditingController> _addRow({String code = '', String desc = ''}) {
    final row = [
      TextEditingController(text: code), // task_code_id (read-only)
      TextEditingController(text: desc), // task_description
    ];
    _controllers.add(row);
    // Typing a description on the blank trailing row assigns the next code.
    row[1].addListener(() {
      if (row[0].text.isEmpty &&
          row[1].text.isNotEmpty &&
          identical(_controllers.last, row)) {
        setState(() {
          row[0].text = _nextCode();
          _addRow();
        });
      }
    });
    return row;
  }

  // Highest numeric code + 1, keeping the zero-padding width of existing codes.
  String _nextCode() {
    var max = 0;
    var width = 0;
    for (final r in _controllers) {
      final text = r[0].text.trim();
      final n = int.tryParse(text);
      if (n == null) continue;
      if (n > max) max = n;
      if (text.length > width && text.startsWith('0')) width = text.length;
    }
    return (max + 1).toString().padLeft(width, '0');
  }

  Future<void> _load() async {
    try {
      final rows = await DbService.getTaskCodes();
      // sort numerically by task_code_id (lowest first)
      rows.sort((a, b) {
        final na = num.tryParse(a['task_code_id'] as String? ?? '') ?? double.maxFinite;
        final nb = num.tryParse(b['task_code_id'] as String? ?? '') ?? double.maxFinite;
        return na.compareTo(nb);
      });
      setState(() {
        for (final row in _controllers) {
          for (final c in row) {c.dispose();}
        }
        _controllers = [];
        for (final r in rows) {
          _addRow(
            code: r['task_code_id'] as String? ?? '',
            desc: r['task_description'] as String? ?? '',
          );
        }
        _addRow();
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

  Future<void> _deleteRow(int index) async {
    final row = _controllers[index];
    final id = row[0].text.trim();
    if (id.isNotEmpty) {
      final confirmed = await confirmDelete(context, itemName: 'task code $id');
      if (!confirmed || !mounted) return;
    }
    if (id.isNotEmpty) _deletedIds.add(id);
    setState(() => _controllers.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in row) {c.dispose();}
    });
  }

  Future<void> _save() async {
    try {
      for (final id in List.of(_deletedIds)) {
        try {
          await DbService.deleteTaskCode(id);
          _deletedIds.remove(id);
        } catch (e) {
          if (mounted) {
            await showDeleteFailed(context, itemName: 'task code $id', error: e);
          }
          return;
        }
      }
      for (final row in _controllers) {
        final id = row[0].text.trim();
        if (id.isEmpty) continue;
        await DbService.upsertTaskCode({
          'task_code_id': id,
          'task_description': row[1].text.trim(),
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

  @override
  void dispose() {
    for (final row in _controllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Codes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(
                    label: Text('Task Code',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text('Task Description',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(label: Text('')),
                ],
                rows: List.generate(_controllers.length, (index) {
                  final row = _controllers[index];
                  return DataRow(
                    cells: [
                      DataCell(_EditField(controller: row[0], readOnly: true)),
                      DataCell(_EditField(controller: row[1])),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Delete row',
                          onPressed: index == _controllers.length - 1
                              ? null
                              : () => _deleteRow(index),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  label: 'Save & Close',
                  onPressed: _save,
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
  final VoidCallback onPressed;

  const _ActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFED7422),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;

  const _EditField({required this.controller, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        filled: readOnly,
        fillColor: readOnly ? readOnlyFieldFill(context) : null,
      ),
    );
  }
}
