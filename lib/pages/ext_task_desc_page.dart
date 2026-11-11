import 'package:flutter/material.dart';
import '../services/db.dart';
import '../widgets/neutral_button_colors.dart';

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
    // Typing a description on the blank trailing row assigns the next code.
    void autoAssignCode() {
      if (row[0].text.isEmpty &&
          (row[1].text.isNotEmpty || row[2].text.isNotEmpty) &&
          _controllers.isNotEmpty &&
          _controllers.last == row) {
        row[0].text = _nextCode();
      }
    }

    row[1].addListener(autoAssignCode);
    row[2].addListener(autoAssignCode);
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
      final rows = await DbService.getTaskCodeExts();
      // Numeric order (1, 2, ... 10), with non-numeric codes last.
      rows.sort((a, b) {
        final ca = a['task_code_id'] as String? ?? '';
        final cb = b['task_code_id'] as String? ?? '';
        final na = num.tryParse(ca);
        final nb = num.tryParse(cb);
        if (na != null && nb != null) return na.compareTo(nb);
        if (na != null) return -1;
        if (nb != null) return 1;
        return ca.compareTo(cb);
        
      });
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
      // TaskCodeExt references TaskCodes, so brand-new codes must exist there first.
      final existing = (await DbService.getTaskCodes())
          .map((r) => r['task_code_id']?.toString() ?? '')
          .toSet();
      for (final row in _controllers) {
        final id = row[0].text.trim();
        if (id.isEmpty || existing.contains(id)) continue;
        final desc = row[2].text.trim().isNotEmpty
            ? row[2].text.trim()
            : row[1].text.trim();
        await DbService.upsertTaskCode({
          'task_code_id': id,
          'task_description': desc,
        });
        existing.add(id);
      }
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
                          readOnly: true,
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
  final bool readOnly;

  const _EditField({
    required this.controller,
    this.readOnly = false,
  });

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
