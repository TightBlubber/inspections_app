import 'package:flutter/material.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  int? _selectedIndex;

  // Placeholder data — replace with real data later
  final List<Map<String, String>> _customers = [
    {'id': 'C001', 'company': 'testing1'},
    {'id': 'C002', 'company': 'testing2'},
    {'id': 'C003', 'company': 'testing3'},
    {'id': 'C004', 'company': 'testing4'},
    {'id': 'C005', 'company': 'testing5'},
  ];

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(
                    label: Text('Customer ID',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text('Company Name',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
                rows: List.generate(_customers.length, (index) {
                  final customer = _customers[index];
                  return DataRow(
                    selected: _selectedIndex == index,
                    onSelectChanged: (selected) {
                      setState(() {
                        _selectedIndex =
                            selected == true ? index : null;
                      });
                    },
                    cells: [
                      DataCell(Text(customer['id']!)),
                      DataCell(Text(customer['company']!)),
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
              children: [
                _ActionButton(
                    label: 'Detail',
                    enabled: hasSelection,
                    onPressed: () {}),
                const SizedBox(width: 8),
                _ActionButton(
                    label: 'Projects',
                    enabled: hasSelection,
                    onPressed: () {}),
                const SizedBox(width: 8),
                _ActionButton(
                    label: 'New',
                    enabled: true,
                    onPressed: () {}),
                const SizedBox(width: 8),
                _ActionButton(
                    label: 'Delete',
                    enabled: hasSelection,
                    onPressed: () {}),
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
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFED7422),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}