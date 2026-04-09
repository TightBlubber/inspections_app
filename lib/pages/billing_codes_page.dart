import 'package:flutter/material.dart';

class BillingCodesPage extends StatefulWidget {
  const BillingCodesPage({super.key});

  @override
  State<BillingCodesPage> createState() => _BillingCodesPageState();
}

class _BillingCodesPageState extends State<BillingCodesPage> {
  // Each row: [codeController, descriptionController]
  late final List<List<TextEditingController>> _controllers;

  static const List<List<String>> _initialData = [
    ['BC001', 'Standard Inspection'],
    ['BC002', 'Extended Inspection'],
    ['BC003', 'Emergency Call Out'],
    ['BC004', 'Travel Time'],
    ['BC005', 'Report Writing'],
  ];

  @override
  void initState() {
    super.initState();
    _controllers = _initialData
        .map((row) => row.map((v) => TextEditingController(text: v)).toList())
        .toList();
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
                  label: 'Close',
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
