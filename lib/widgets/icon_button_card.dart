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

  static const _orange = Color(0xFFED7422);
  static const _iconBg = Color(0xFFFDF1E9);
  static const _labelColor = Color(0xFF2D3142);
  static const _chipBg = Color(0xFFF0F2F5);
  static const _chipText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final hasSub = sublabels != null && sublabels!.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: Color.fromRGBO(237, 116, 34, 0.1),
        highlightColor: Color.fromRGBO(237, 116, 34, 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Icon(icon, size: 26, color: _orange),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _labelColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (hasSub) ...[
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: sublabels!
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: const BoxDecoration(
                            color: _chipBg,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 10,
                              color: _chipText,
                              fontWeight: FontWeight.w500,
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
    );
  }
}