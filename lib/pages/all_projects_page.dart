import 'package:flutter/material.dart';
import 'project_detail_page.dart';
import 'project_email_page.dart';
import 'project_tasks_page.dart';
import '../services/db.dart';
import '../widgets/confirm_delete_dialog.dart';

class AllProjectsPage extends StatefulWidget {
  const AllProjectsPage({super.key});

  @override
  State<AllProjectsPage> createState() => _AllProjectsPageState();
}

class _AllProjectsPageState extends State<AllProjectsPage> {
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
      final data = await DbService.getProjects();
      if (!mounted) return;
      setState(() {
        _projects = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load projects: $e')));
    }
  }

  Future<void> _delete() async {
    if (_selectedIndex == null) return;
    final project = _projects[_selectedIndex!];
    final id = project['project_id'] as String;
    final confirmed = await confirmDelete(
      context,
      itemName: 'project $id — ${project['project_name'] ?? ''}',
      details: 'All tasks, billing, proctors, cylinder breaks and break '
          'results linked to this project will be deleted too.',
    );
    if (!confirmed) return;
    try {
      await DbService.deleteProject(id);
      setState(() {
        _projects.removeAt(_selectedIndex!);
        _selectedIndex = null;
      });
    } catch (e) {
      if (mounted) {
        await showDeleteFailed(
          context,
          itemName: 'project $id — ${project['project_name'] ?? ''}',
          error: e,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedIndex != null;

    return Scaffold(
      appBar: AppBar(title: const Text('All Projects')),
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
                          label: Text(
                            'Project ID',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Project Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                            DataCell(
                              Text(project['project_id'] as String? ?? ''),
                            ),
                            DataCell(
                              Text(project['project_name'] as String? ?? ''),
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
                        label: 'Detail',
                        enabled: hasSelection,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailPage(
                                project: _projects[_selectedIndex!],
                              ),
                            ),
                          );
                          if (result == true) _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Tasks',
                        enabled: hasSelection,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectTasksPage(
                                projectId:
                                    _projects[_selectedIndex!]['project_id']
                                        as String,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Email',
                        enabled: hasSelection,
                        onPressed: () async {
                          final projectId =
                              _projects[_selectedIndex!]['project_id']
                                  as String;
                          try {
                            final project = await DbService.getProject(
                              projectId,
                            );
                            if (!mounted) return;
                            if (project == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not load project $projectId details.',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProjectEmailPage(project: project),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to open Email page: $e'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'New',
                        enabled: true,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProjectDetailPage(),
                            ),
                          );
                          if (result == true) _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Delete',
                        enabled: hasSelection,
                        onPressed: _delete,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
