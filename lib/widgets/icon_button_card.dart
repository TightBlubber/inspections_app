import 'package:flutter/material.dart';

class IconButtonCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const IconButtonCard({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onPressed ?? () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFED7422),
              foregroundColor: Colors.white,
              fixedSize: const Size(300, 200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 70),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}