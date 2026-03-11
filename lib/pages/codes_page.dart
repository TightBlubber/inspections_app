import 'package:flutter/material.dart';

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
            _CodesMenuButton(label: 'Billing Codes', icon: Icons.receipt_long, onPressed: () {}),
            const SizedBox(height: 16),
            _CodesMenuButton(label: 'Molds', icon: Icons.view_in_ar, onPressed: () {}),
            const SizedBox(height: 16),
            _CodesMenuButton(label: 'Task Codes', icon: Icons.task, onPressed: () {}),
            const SizedBox(height: 16),
            _CodesMenuButton(label: 'Ext Task Desc', icon: Icons.description, onPressed: () {}),
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
