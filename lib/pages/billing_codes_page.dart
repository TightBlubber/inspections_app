import 'package:flutter/material.dart';
import '../services/db.dart';

class BillingCodesPage extends StatefulWidget {
  const BillingCodesPage({super.key});

  @override
  State<BillingCodesPage> createState() => _BillingCodesPageState();
}

class _BillingCodesPageState extends State<BillingCodesPage> {
  List<List<TextEditingController>> _controllers = [];
  final List<String> _deletedIds = [];

  @override
  void initState() {
    super.initState();
    // show one empty row immediately
    _addEmptyRow();
    _load();
  }

  List<TextEditingController> _addEmptyRow() {
    final row = [
      TextEditingController(),
      TextEditingController(),
    ];
    _controllers.add(row);
    row[0].addListener(() => _onCodeChanged(_controllers.indexOf(row)));
    return row;
  }

  void _onCodeChanged(int index) {
    if (index < 0 || index >= _controllers.length) return;
    final typed = _controllers[index][0].text;
    // remove blank rows that aren't the trailing empty row
    if (typed.isEmpty && index != _controllers.length - 1) {
      final removed = _controllers[index];
      // Track the original ID for deletion on save
      final removedId = removed[0].text.trim();
      if (removedId.isNotEmpty) _deletedIds.add(removedId);
      setState(() => _controllers.removeAt(index));
      // dispose after the listener callback returns
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final c in removed) c.dispose();
      });
      return;
    }
    if (index == _controllers.length - 1 && typed.isNotEmpty) {
      setState(() => _addEmptyRow());
    }
  }

  Future<void> _load() async {
    try {
      final rows = await DbService.getBillingCodes();
      setState(() {
        // dispose placeholder
        for (final row in _controllers) {
          for (final c in row) c.dispose();
        }
        _controllers = rows
            .map((r) => [
                  TextEditingController(text: r['billing_code_id'] as String? ?? ''),
                  TextEditingController(text: r['description'] as String? ?? ''),
                ])
            .toList();
        // attach listeners
        for (var i = 0; i < _controllers.length; i++) {
          final idx = i;
          _controllers[idx][0].addListener(() => _onCodeChanged(idx));
        }
        // always end with one empty row
        _addEmptyRow();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  void _deleteRow(int index) {
    final row = _controllers[index];
    final id = row[0].text.trim();
    if (id.isNotEmpty) _deletedIds.add(id);
    setState(() => _controllers.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in row) c.dispose();
    });
  }

  Future<void> _save() async {
    try {
      // Delete any rows that were removed from the UI
      for (final id in _deletedIds) {
        await DbService.deleteBillingCode(id);
      }
      _deletedIds.clear();
      for (final row in _controllers) {
        final id = row[0].text.trim();
        if (id.isEmpty) continue;
        await DbService.upsertBillingCode({
          'billing_code_id': id,
          'description': row[1].text.trim(),
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
        title: const Text('Billing Codes'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(
                    label: Text('Billing Code',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text('Description',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(label: Text('')),
                ],
                rows: List.generate(_controllers.length, (index) {
                  final row = _controllers[index];
                  return DataRow(
                    cells: [
                      DataCell(_EditField(controller: row[0])),
                      DataCell(_EditField(controller: row[1])),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Delete row',
                          onPressed: () => _deleteRow(index),
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
