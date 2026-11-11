import 'package:flutter/material.dart';
import 'project_detail_page.dart';
import 'project_email_page.dart';
import 'project_tasks_page.dart';
import '../services/db.dart';

class ActiveProjectsPage extends StatefulWidget {
  const ActiveProjectsPage({super.key});

  @override
  State<ActiveProjectsPage> createState() => _ActiveProjectsPageState();
}

class _ActiveProjectsPageState extends State<ActiveProjectsPage> {
  int? _selectedIndex;
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Compares digit runs numerically so "25-10" sorts after "25-9".
  static int _naturalCompare(String a, String b) {
    final re = RegExp(r'\d+|\D+');
    final pa = re.allMatches(a).map((m) => m.group(0)!).toList();
    final pb = re.allMatches(b).map((m) => m.group(0)!).toList();
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final x = pa[i], y = pb[i];
      final nx = int.tryParse(x), ny = int.tryParse(y);
      final c = (nx != null && ny != null) ? nx.compareTo(ny) : x.compareTo(y);
      if (c != 0) return c;
    }
    return pa.length.compareTo(pb.length);
  }

  Future<void> _load() async {
    try {
      final data = List<Map<String, dynamic>>.from(
          await DbService.getProjects(activeOnly: true))
        ..sort((a, b) => _naturalCompare(
            b['project_id']?.toString() ?? '', a['project_id']?.toString() ?? ''));
      if (!mounted) return;
      setState(() {
        _projects = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load projects: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedIndex != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Projects')),
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
