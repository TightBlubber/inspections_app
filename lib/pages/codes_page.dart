import 'package:flutter/material.dart';
import 'billing_codes_page.dart';
import 'molds_page.dart';
import 'task_codes_page.dart';
import 'ext_task_desc_page.dart';

class CodesPage extends StatelessWidget {
  const CodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Codes'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CodesMenuButton(
              label: 'Billing Codes',
              icon: Icons.receipt_long,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BillingCodesPage()),
              ),
            ),
            const SizedBox(height: 16),
            _CodesMenuButton(
              label: 'Molds',
              icon: Icons.view_in_ar,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoldsPage()),
              ),
            ),
            const SizedBox(height: 16),
            _CodesMenuButton(
              label: 'Task Codes',
              icon: Icons.task,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TaskCodesPage()),
              ),
            ),
            const SizedBox(height: 16),
            _CodesMenuButton(
              label: 'Ext Task Desc',
              icon: Icons.description,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExtTaskDescPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodesMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _CodesMenuButton({
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
