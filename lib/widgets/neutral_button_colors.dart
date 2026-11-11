import 'package:flutter/material.dart';

/// Background/foreground for secondary (non-orange) buttons, adapted to the active theme.
Color neutralButtonBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2B2F38)
        : Colors.grey.shade200;

Color neutralButtonFg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE5E7EB)
        : Colors.black87;

/// Fill for read-only/disabled-looking fields.
Color readOnlyFieldFill(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2B2F38)
        : Colors.grey.shade100;
