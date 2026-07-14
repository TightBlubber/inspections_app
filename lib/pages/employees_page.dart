import 'package:flutter/material.dart';
import '../services/db.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  int? _selectedIndex;
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DbService.getEmployees();
      setState(() {
        _employees = data;
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

  Future<void> _delete() async {
    if (_selectedIndex == null) return;
    final id = _employees[_selectedIndex!]['employee_id'] as String;
    try {
      await DbService.deleteEmployee(id);
      setState(() {
        _employees.removeAt(_selectedIndex!);
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

  Future<void> _openDetail([Map<String, dynamic> employee = const {}]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployeeDetailPage(employee: employee)),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedIndex != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
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
                          label: Text('Employee ID',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('First Name',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Last Name',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                      rows: List.generate(_employees.length, (index) {
                        final emp = _employees[index];
                        return DataRow(
                          selected: _selectedIndex == index,
                          onSelectChanged: (selected) {
                            setState(() {
                              _selectedIndex = selected == true ? index : null;
                            });
                          },
                          cells: [
                            DataCell(Text(emp['employee_id'] as String? ?? '')),
                            DataCell(Text(emp['first_name'] as String? ?? '')),
                            DataCell(Text(emp['last_name'] as String? ?? '')),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _ActionButton(
                        label: 'Detail',
                        enabled: hasSelection,
                        onPressed: () =>
                            _openDetail(_employees[_selectedIndex!]),
                      ),
                      _ActionButton(
                        label: 'New',
                        enabled: true,
                        onPressed: () => _openDetail(),
                      ),
                      _ActionButton(
                        label: 'Delete',
                        enabled: hasSelection,
                        onPressed: _delete,
                      ),
                      _ActionButton(
                        label: 'Close',
                        enabled: true,
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

// ── Detail page ────────────────────────────────────────────────────────────

class EmployeeDetailPage extends StatefulWidget {
  final Map<String, dynamic> employee;
  const EmployeeDetailPage({super.key, this.employee = const {}});

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  late final TextEditingController _employeeId;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  bool _isNewEmployee = false;

  @override
  void initState() {
    super.initState();
    _employeeId =
        TextEditingController(text: widget.employee['employee_id'] as String? ?? '');
    _firstName =
        TextEditingController(text: widget.employee['first_name'] as String? ?? '');
    _lastName =
        TextEditingController(text: widget.employee['last_name'] as String? ?? '');
    _email =
        TextEditingController(text: widget.employee['email'] as String? ?? '');
    _isNewEmployee = (widget.employee['employee_id'] as String? ?? '').isEmpty;
  }

  @override
  void dispose() {
    _employeeId.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = _employeeId.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee ID is required')),
      );
      return;
    }
    try {
      await DbService.upsertEmployee({
        'employee_id': id,
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewEmployee ? 'New Employee' : 'Employee Detail'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field('Employee ID', _employeeId,
                          readOnly: !_isNewEmployee),
                      _field('First Name', _firstName),
                      _field('Last Name', _lastName),
                      _field('Email', _email),
                    ],
                  ),
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
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFED7422),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
        ),
      ),
    );
  }
}

// ── Shared button widget ───────────────────────────────────────────────────

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
        backgroundColor:
            enabled ? const Color(0xFFED7422) : Colors.grey.shade300,
        foregroundColor: enabled ? Colors.white : Colors.grey,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
