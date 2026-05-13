import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db.dart';

class ExtTaskDescPage extends StatefulWidget {
  const ExtTaskDescPage({super.key});

  @override
  State<ExtTaskDescPage> createState() => _ExtTaskDescPageState();
}

class _ExtTaskDescPageState extends State<ExtTaskDescPage> {
  // Each row: [codeController, shortDescController, longDescController]
  List<List<TextEditingController>> _controllers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<TextEditingController> _makeRow({
    String code = '',
    String shortDesc = '',
    String longDesc = '',
  }) {
    final row = [
      TextEditingController(text: code),
      TextEditingController(text: shortDesc),
      TextEditingController(text: longDesc),
    ];
    row[0].addListener(() {
      if (row[0].text.isNotEmpty &&
          _controllers.isNotEmpty &&
          _controllers.last == row) {
        setState(() {
          _controllers.add(_makeRow());
        });
      }
    });
    return row;
  }

  Future<void> _load() async {
    try {
      final rows = await DbService.getTaskCodeExts();
      rows.sort((a, b) => (a['task_code_id'] as String? ?? '')
          .compareTo(b['task_code_id'] as String? ?? ''));
      setState(() {
        _controllers = rows
            .map((r) => _makeRow(
                  code: r['task_code_id'] as String? ?? '',
                  shortDesc: r['short_description'] as String? ?? '',
                  longDesc: r['long_description'] as String? ?? '',
                ))
            .toList();
        _controllers.add(_makeRow()); // trailing empty row
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _controllers = [_makeRow()];
        _isLoading = false;
      });
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
        await DbService.upsertTaskCodeExt({
          'task_code_id': id,
          'short_description': row[1].text.trim(),
          'long_description': row[2].text.trim(),
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
        title: const Text('Ext Task Descriptions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(
                      label: Text('Task Code',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Short Description',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Long Description',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: List.generate(_controllers.length, (index) {
                    final row = _controllers[index];
                    return DataRow(
                      cells: [
                        DataCell(_EditField(
                          controller: row[0],
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        )),
                        DataCell(_EditField(controller: row[1])),
                        DataCell(
                          SizedBox(
                            width: 300,
                            child: _EditField(controller: row[2]),
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
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _EditField({
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: const InputDecoration(
        isDense: true,
        border: UnderlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 6),
      ),
    );
  }
}
