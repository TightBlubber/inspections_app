import 'package:flutter/widgets.dart';

/// Formats a rate to two decimal places ("50" -> "50.00"); unparseable text is returned unchanged.
String formatRate(String text) {
  final t = text.trim().replaceAll(',', '');
  final n = num.tryParse(t);
  return n == null ? text.trim() : n.toStringAsFixed(2);
}

/// Rewrites [controller]'s text as a two-decimal rate if it changes.
void applyRateFormat(TextEditingController controller) {
  final formatted = formatRate(controller.text);
  if (formatted != controller.text) controller.text = formatted;
}
