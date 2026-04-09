import 'package:flutter/material.dart';

class MoldsPage extends StatefulWidget {
  const MoldsPage({super.key});

  @override
  State<MoldsPage> createState() => _MoldsPageState();
}

class _MoldsPageState extends State<MoldsPage> {
  // Each row: [numberController, descriptionController, volumeController, weightController]
  late final List<List<TextEditingController>> _controllers;

  static const List<List<String>> _initialData = [
    ['M001', 'Standard Round Mold', '500 mL', '2.5 kg'],
    ['M002', 'Square Flat Mold', '750 mL', '3.1 kg'],
    ['M003', 'Cylinder Mold', '1000 mL', '4.0 kg'],
    ['M004', 'Rectangular Mold', '1200 mL', '5.2 kg'],
    ['M005', 'Large Basin Mold', '2000 mL', '7.8 kg'],
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
        title: const Text('Molds'),
      ),
      body: Column(
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
                        DataCell(_EditField(controller: row[2])),
                        DataCell(_EditField(controller: row[3])),
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
