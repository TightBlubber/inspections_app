import 'package:flutter/material.dart';
import 'active_projects_page.dart';
import 'all_projects_page.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProjectMenuButton(
              label: 'Active Projects',
              icon: Icons.folder_open,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ActiveProjectsPage()),
              ),
            ),
            const SizedBox(height: 16),
            _ProjectMenuButton(
              label: 'All Projects',
              icon: Icons.folder,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllProjectsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ProjectMenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFED7422),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
