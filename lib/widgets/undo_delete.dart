import 'package:flutter/material.dart';

import '../hub_state.dart';
import '../models.dart';

Future<void> deleteTaskWithUndo(
  BuildContext context,
  HubState state,
  HubTask task,
) async {
  await state.deleteTask(task.id);
  if (!context.mounted) return;
  _showUndo(context, 'Task deleted', () => state.restoreTask(task));
}

Future<void> deleteExpenseWithUndo(
  BuildContext context,
  HubState state,
  ExpenseEntry entry,
) async {
  await state.deleteExpense(entry.id);
  if (!context.mounted) return;
  _showUndo(context, 'Expense deleted', () => state.restoreExpense(entry));
}

Future<void> deletePantryItemWithUndo(
  BuildContext context,
  HubState state,
  PantryEntry item,
) async {
  await state.deletePantryItem(item.id);
  if (!context.mounted) return;
  _showUndo(
    context,
    'Pantry item deleted',
    () => state.restorePantryItem(item),
  );
}

Future<void> deleteShoppingItemWithUndo(
  BuildContext context,
  HubState state,
  ShoppingItem item,
) async {
  await state.deleteShoppingItem(item.id);
  if (!context.mounted) return;
  _showUndo(
    context,
    'Shopping item deleted',
    () => state.restoreShoppingItem(item),
  );
}

void _showUndo(BuildContext context, String message, VoidCallback undo) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Undo', onPressed: undo),
      ),
    );
}
