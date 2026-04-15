import 'package:flutter/material.dart';
import 'approval_page.dart';
import 'invoices_page.dart';

class ManagementPage extends StatelessWidget {
  const ManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Management'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ManagementMenuButton(
              label: 'Approval',
              icon: Icons.check_circle_outline,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApprovalPage()),
              ),
            ),
            const SizedBox(height: 16),
            _ManagementMenuButton(
              label: 'Invoices',
              icon: Icons.request_page,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvoicesPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ManagementMenuButton({
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
