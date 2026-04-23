import 'package:flutter/material.dart';
import 'project_detail_page.dart';
import 'project_email_page.dart';
import 'project_tasks_page.dart';
import '../services/db.dart';

class CustomerProjectsPage extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerProjectsPage({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerProjectsPage> createState() => _CustomerProjectsPageState();
}

class _CustomerProjectsPageState extends State<CustomerProjectsPage> {
  int? _selectedIndex;
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  
  Future<void> _load() async {
    try {
      final data = await DbService.getProjectsByCustomer(widget.customerId);
      setState(() {
        _projects = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load projects: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Projects — ${widget.customerName}'),
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
                          label: Text('Project ID',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Project Name',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                      rows: List.generate(_projects.length, (index) {
                        final project = _projects[index];
                        return DataRow(
                          selected: _selectedIndex == index,
                          onSelectChanged: (selected) {
                            setState(() {
                              _selectedIndex = selected == true ? index : null;
                            });
                          },
                          cells: [
                            DataCell(Text(project['project_id'] as String? ?? '')),
                            DataCell(Text(project['project_name'] as String? ?? '')),
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
                            final project = await DbService.getProject(
                                _projects[_selectedIndex!]['project_id'] as String);
                            if (!mounted || project == null) return;
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProjectDetailPage(project: project),
                              ),
                            );
                            if (result == true) _load();
                          }),
                      const SizedBox(width: 8),
                      _ActionButton(
                          label: 'Tasks',
                          enabled: hasSelection,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProjectTasksPage(
                                  projectId: _projects[_selectedIndex!]['project_id'] as String,
                                ),
                              ),
                            );
                          }),
                      const SizedBox(width: 8),
                      _ActionButton(
                          label: 'Email',
                          enabled: hasSelection,
                          onPressed: () async {
                            final project = await DbService.getProject(
                                _projects[_selectedIndex!]['project_id'] as String);
                            if (!mounted || project == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProjectEmailPage(project: project),
                              ),
                            );
                          }),
                      const SizedBox(width: 8),
                      _ActionButton(
                          label: 'New',
                          enabled: true,
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProjectDetailPage(
                                  project: {'customer_id': widget.customerId},
                                ),
                              ),
                            );
                            if (result == true) _load();
                          }),
                      const SizedBox(width: 8),
                      _ActionButton(
                          label: 'Close',
                          enabled: true,
                          onPressed: () => Navigator.pop(context)),
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
