import 'package:flutter/material.dart';

Future<void> showDeleteAccountDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    icon: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
    title: const Text('Account deletion unavailable'),
    content: const Text('Account deletion will be available when the secure server-side deletion workflow is ready. Your account has not been changed.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
  ),
);
