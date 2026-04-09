import 'package:flutter/material.dart';

class ExtTaskDescPage extends StatefulWidget {
  const ExtTaskDescPage({super.key});

  @override
  State<ExtTaskDescPage> createState() => _ExtTaskDescPageState();
}

class _ExtTaskDescPageState extends State<ExtTaskDescPage> {
  // Each row: [codeController, shortDescController, longDescController]
  late final List<List<TextEditingController>> _controllers;

  static const List<List<String>> _initialData = [
    ['T001', 'Init Setup', 'Perform initial project setup including site survey and equipment check.'],
    ['T002', 'Sample Coll.', 'Collect samples from designated locations following standard protocols.'],
    ['T003', 'Lab Test', 'Conduct laboratory testing on collected samples per project specifications.'],
    ['T004', 'Field Insp.', 'Perform on-site field inspection and document findings with photographs.'],
    ['T005', 'Report Prep', 'Prepare comprehensive inspection report including findings and recommendations.'],
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
        title: const Text('Ext Task Descriptions'),
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
                        DataCell(_EditField(controller: row[0])),
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
