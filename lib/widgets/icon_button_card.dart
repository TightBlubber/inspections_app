import 'package:flutter/material.dart';

class IconButtonCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final List<String>? sublabels;

  const IconButtonCard({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.sublabels,
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
                if (sublabels != null && sublabels!.isNotEmpty) ...
                  [
                    const SizedBox(height: 8),
                    const Divider(
                      color: Colors.white38,
                      thickness: 1,
                      indent: 12,
                      endIndent: 12,
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: sublabels!
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}