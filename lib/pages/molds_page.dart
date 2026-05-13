import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/db.dart';

class MoldsPage extends StatefulWidget {
  const MoldsPage({super.key});

  @override
  State<MoldsPage> createState() => _MoldsPageState();
}

class _MoldsPageState extends State<MoldsPage> {
  List<List<TextEditingController>> _controllers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<TextEditingController> _makeRow({
    String num = '',
    String desc = '',
    String vol = '',
    String wt = '',
  }) {
    final row = [
      TextEditingController(text: num),
      TextEditingController(text: desc),
      TextEditingController(text: vol),
      TextEditingController(text: wt),
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
      final rows = await DbService.getMolds();
      setState(() {
        _controllers = rows
            .map((r) => _makeRow(
                  num: r['mold_number'] as String? ?? '',
                  desc: r['mold_description'] as String? ?? '',
                  vol: r['mold_volume'] as String? ?? '',
                  wt: r['mold_weight'] as String? ?? '',
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
        await DbService.upsertMold({
          'mold_number': id,
          'mold_description': row[1].text.trim(),
          'mold_volume': row[2].text.trim(),
          'mold_weight': row[3].text.trim(),
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
        title: const Text('Molds'),
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
                      label: Text('Mold Number',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Mold Description',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Mold Volume',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Mold Weight',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: List.generate(_controllers.length, (index) {
                    final row = _controllers[index];
                    return DataRow(
                      cells: [
                        DataCell(_EditField(controller: row[0])),
                        DataCell(_EditField(controller: row[1])),
                        DataCell(_EditField(
                          controller: row[2],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        )),
                        DataCell(_EditField(
                          controller: row[3],
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        )),
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
