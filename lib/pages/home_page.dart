import 'package:flutter/material.dart';
import 'breaksheet_page.dart';
import 'codes_page.dart';
import 'customers_page.dart';
import 'employees_page.dart';
import 'lists_page.dart';
import 'management_page.dart';
import 'projects_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leadingWidth: 160,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Employees',
            color: const Color(0xFF6B7280),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployeesPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: const Color(0xFF6B7280),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const _SectionHeader('Operations'),
          _NavTile(
            icon: Icons.groups_outlined,
            title: 'Customers',
            subtitle: 'Manage customer accounts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomersPage()),
            ),
          ),
          _NavTile(
            icon: Icons.table_chart_outlined,
            title: 'Breaksheets',
            subtitle: 'View and create daily breaksheets',
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null || !context.mounted) return;
              final dateStr =
                  '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BreaksheetPage(date: dateStr)),
              );
            },
          ),
          _NavTile(
            icon: Icons.folder_outlined,
            title: 'Projects',
            subtitle: 'Active projects and full project list',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProjectsPage()),
            ),
          ),
          const _SectionHeader('References'),
          _NavTile(
            icon: Icons.menu_book_outlined,
            title: 'Codes',
            subtitle: 'Billing codes, molds, and task codes',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CodesPage()),
            ),
          ),
          _NavTile(
            icon: Icons.list_alt_outlined,
            title: 'Lists',
            subtitle: 'Project and proctor lists',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListsPage()),
            ),
          ),
          const _SectionHeader('Administration'),
          _NavTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Management',
            subtitle: 'Approvals and invoices',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManagementPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9CA3AF),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDF1E9),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Icon(icon, size: 22, color: const Color(0xFFED7422)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}