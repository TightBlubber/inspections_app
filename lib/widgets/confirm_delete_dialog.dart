import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns a delete error into a short explanation the user can act on.
String describeDeleteError(Object error) {
  if (error is PostgrestException) {
    switch (error.code) {
      case '23503':
        final table = RegExp(r'constraint "[^"]+" on table "([^"]+)"')
            .firstMatch(error.message)
            ?.group(1);
        final related = _friendlyTableNames[table] ?? 'other records';
        return 'It still has $related linked to it. '
            'Delete or reassign those first, then try again.';
      case '42501':
        return 'You do not have permission to delete it.';
    }
    return error.message;
  }
  return error.toString();
}

const _friendlyTableNames = {
  'Tasks': 'tasks',
  'Projects': 'projects',
  'ProjectBilling': 'billing rows',
  'Proctors': 'proctors',
  'Customers': 'customers',
  'Employees': 'employees',
  'BillingCodes': 'billing codes',
  'TaskCodes': 'task codes',
};

/// Tells the user a delete failed and why.
Future<void> showDeleteFailed(
  BuildContext context, {
  required String itemName,
  required Object error,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete failed'),
      content: Text('Could not delete $itemName.\n\n${describeDeleteError(error)}'),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Asks the user to confirm a delete. The Delete button stays disabled until
/// the confirmation checkbox is ticked. Returns true only if confirmed.
Future<bool> confirmDelete(
  BuildContext context, {
  required String itemName,
  String? details,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ConfirmDeleteDialog(itemName: itemName, details: details),
  );
  return result == true;
}

class _ConfirmDeleteDialog extends StatefulWidget {
  final String itemName;
  final String? details;

  const _ConfirmDeleteDialog({required this.itemName, this.details});

  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Are you sure?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You are about to delete ${widget.itemName}.'),
          if (widget.details != null) ...[
            const SizedBox(height: 8),
            Text(widget.details!),
          ],
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            title: const Text('Yes, I want to delete this'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirmed ? () => Navigator.pop(context, true) : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
