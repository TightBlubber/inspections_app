import 'package:flutter/material.dart';
import 'project_detail_page.dart';
import 'project_email_page.dart';
import 'project_tasks_page.dart';

class AllProjectsPage extends StatefulWidget {
  const AllProjectsPage({super.key});

  @override
  State<AllProjectsPage> createState() => _AllProjectsPageState();
}

class _AllProjectsPageState extends State<AllProjectsPage> {
  int? _selectedIndex;

  // Placeholder data — replace with real data later
  final List<Map<String, String>> _projects = [
    {'id': 'P001', 'name': 'Project 1'},
    {'id': 'P002', 'name': 'Project 2'},
    {'id': 'P003', 'name': 'Project 3'},
    {'id': 'P004', 'name': 'Project 4'},
    {'id': 'P005', 'name': 'Project 5'},
  ];

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Projects'),
      ),
      body: Column(
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
                      DataCell(Text(project['id']!)),
                      DataCell(Text(project['name']!)),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(
                            project: _projects[_selectedIndex!],
                          ),
                        ),
                      );
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
                            projectId: _projects[_selectedIndex!]['id']!,
                          ),
                        ),
                      );
                    }),
                const SizedBox(width: 8),
                _ActionButton(
                    label: 'Email',
                    enabled: hasSelection,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectEmailPage(
                            project: _projects[_selectedIndex!],
                          ),
                        ),
                      );
                    }),
                const SizedBox(width: 8),
                _ActionButton(
                    label: 'New',
                    enabled: true,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProjectDetailPage(),
                        ),
                      );
                    }),
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
