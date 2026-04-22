import 'package:flutter/material.dart';
import '../services/db.dart';

class TaskCodesPage extends StatefulWidget {
  const TaskCodesPage({super.key});

  @override
  State<TaskCodesPage> createState() => _TaskCodesPageState();
}

class _TaskCodesPageState extends State<TaskCodesPage> {
  List<List<TextEditingController>> _controllers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await DbService.getTaskCodes();
      setState(() {
        _controllers = rows
            .map((r) => [
                  TextEditingController(text: r['task_code_id'] as String? ?? ''),
                  TextEditingController(text: r['task_description'] as String? ?? ''),
                ])
            .toList();
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
                ],
                rows: List.generate(_controllers.length, (index) {
                  final row = _controllers[index];
                  return DataRow(
                    cells: [
                      DataCell(_EditField(controller: row[0])),
                      DataCell(_EditField(controller: row[1])),
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

  const _EditField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        isDense: true,
        border: UnderlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 6),
      ),
    );
  }
}
