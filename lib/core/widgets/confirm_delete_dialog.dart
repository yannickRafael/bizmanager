import 'package:flutter/material.dart';

/// Reusable delete confirmation dialog.
/// Returns `true` if the user confirms the deletion, `false` otherwise.
Future<bool> showDeleteConfirmation(
  BuildContext context, {
  required String itemName,
  String? warningMessage,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
      title: const Text('Confirmar Eliminação'),
      content: Text(
        'Tem certeza que deseja apagar "$itemName"?\n\n${warningMessage ?? "Esta ação não pode ser desfeita."}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Apagar'),
        ),
      ],
    ),
  );
  return result ?? false;
}
