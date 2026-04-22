import 'package:flutter/material.dart';
import 'customer_detail_page.dart';
import '../services/db.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  int? _selectedIndex;
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DbService.getCustomers();
      setState(() {
        _customers = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load customers: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    if (_selectedIndex == null) return;
    final id = _customers[_selectedIndex!]['customer_id'] as String;
    try {
      await DbService.deleteCustomer(id);
      setState(() {
        _customers.removeAt(_selectedIndex!);
        _selectedIndex = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
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
                      DataCell(Text(customer['customer_id'] as String? ?? '')),
                      DataCell(Text(customer['company_name'] as String? ?? '')),
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
                    label: 'Detail',
                    enabled: hasSelection,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailPage(
                            customer: _customers[_selectedIndex!],
                          ),
                        ),
                      );
                      if (result == true) _load();
                    }),
                const SizedBox(width: 8),
                _ActionButton(
                    label: 'Projects',
                    enabled: hasSelection,
                    onPressed: () {}),
                const SizedBox(width: 8),
                _ActionButton(
                    label: 'New',
                    enabled: true,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerDetailPage(),
                        ),
                      );
                      if (result == true) _load();
                    }),
                const SizedBox(width: 8),
                _ActionButton(
                    label: 'Delete',
                    enabled: hasSelection,
                    onPressed: _delete),
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
    return ElevatedButton(
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
    );
  }
}