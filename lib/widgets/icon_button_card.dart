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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final hasSub = sublabels != null && sublabels!.isNotEmpty;
              // scale icon & text based on available height
              final iconSize = (h * 0.32).clamp(24.0, 70.0);
              final labelSize = (h * 0.10).clamp(12.0, 20.0);
              final chipFontSize = (h * 0.07).clamp(9.0, 12.0);
              final chipPadV = (h * 0.02).clamp(2.0, 4.0);
              final chipPadH = (h * 0.04).clamp(4.0, 8.0);

              return ElevatedButton(
                onPressed: onPressed ?? () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFED7422),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, h),
                  maximumSize: Size(double.infinity, h),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: iconSize),
                    SizedBox(height: h * 0.03),
                    Text(label, style: TextStyle(fontSize: labelSize)),
                    if (hasSub) ...[
                      SizedBox(height: h * 0.03),
                      const Divider(
                        color: Colors.white38,
                        thickness: 1,
                        indent: 12,
                        endIndent: 12,
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 3,
                        children: sublabels!
                            .map(
                              (s) => Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: chipPadH, vertical: chipPadV),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: chipFontSize,
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
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}