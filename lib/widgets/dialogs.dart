import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../hub_state.dart';
import '../models.dart';
import '../reminder_service.dart';
import 'dialog_controller_owner.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
String _longDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
}

void _showReminderPermissionMessage(BuildContext context, String itemName) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$itemName saved. Allow Anchor Hub notifications in Android settings, then turn on this reminder.',
      ),
      action: SnackBarAction(
        label: 'Settings',
        onPressed: () => unawaited(
          ReminderService.instance.openNotificationSettings(),
        ),
      ),
    ),
  );
}

Future<void> showTaskDialog(
  BuildContext context,
  HubState state, {
  HubTask? existingTask,
  DateTime? initialDueDate,
}) async {
  final isEditing = existingTask != null;
  final title = TextEditingController(text: existingTask?.title ?? '');
  final subject = TextEditingController(text: existingTask?.subject ?? '');
  final notes = TextEditingController(text: existingTask?.notes ?? '');
  final formKey = GlobalKey<FormState>();

  var dueDate =
      existingTask?.dueDate ?? _dateOnly(initialDueDate ?? DateTime.now());
  var recurrence = existingTask?.recurrence ?? 'none';
  var priority = existingTask?.priority ?? 1;
  var reminderEnabled =
      existingTask?.reminderEnabled ??
      ReminderService.instance.supportsScheduledReminders;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => DialogControllerOwner(
      controllers: [title, subject, notes],
      child: StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Edit Assignment / Task' : 'Add to Planner'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: title,
                    autofocus: !isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Task or assignment',
                      hintText: 'e.g. Physics Problem Set 4',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter a title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subject,
                    decoration: const InputDecoration(
                      labelText: 'Subject or project (optional)',
                      hintText: 'e.g. Physics, Work, Personal',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notes,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes or details (optional)',
                      hintText: 'e.g. Chapters 4-6, review formulas',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Due Date Tile
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.iceBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Due Date',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_longDate(dueDate)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setLocalState(() => dueDate = _dateOnly(picked));
                      }
                    },
                  ),
                  const SizedBox(height: 6),

                  DropdownButtonFormField<String>(
                    initialValue: recurrence,
                    decoration: const InputDecoration(
                      labelText: 'Repeat task',
                      prefixIcon: Icon(Icons.repeat_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'none',
                        child: Text('Does not repeat'),
                      ),
                      DropdownMenuItem(
                        value: 'daily',
                        child: Text('Every day'),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('Every week'),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Every month'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null)
                        setLocalState(() => recurrence = value);
                    },
                  ),
                  const SizedBox(height: 6),

                  // Reminder Tile
                  if (ReminderService.instance.supportsScheduledReminders)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: reminderEnabled,
                      title: const Text(
                        'Reminder notification',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        '9:00 AM on the due date',
                        style: TextStyle(fontSize: 12),
                      ),
                      onChanged: (val) =>
                          setLocalState(() => reminderEnabled = val),
                    ),
                  const SizedBox(height: 10),

                  // Priority Selector
                  const Text(
                    'Priority',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Low')),
                      ButtonSegment(value: 1, label: Text('Normal')),
                      ButtonSegment(value: 2, label: Text('High')),
                    ],
                    selected: {priority},
                    onSelectionChanged: (set) =>
                        setLocalState(() => priority = set.first),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(isEditing ? 'Save Changes' : 'Create Task'),
          ),
        ],
      ),
      ),
    ),
  );

  if (saved == true) {
    bool wasEnabled;
    if (isEditing) {
      wasEnabled = await state.updateTask(
        existingTask.copyWith(
          title: title.text.trim(),
          subject: subject.text.trim(),
          notes: notes.text.trim(),
          dueDate: dueDate,
          priority: priority,
          reminderEnabled: reminderEnabled,
          recurrence: recurrence,
        ),
      );
    } else {
      wasEnabled = await state.addTask(
        title: title.text.trim(),
        subject: subject.text.trim(),
        notes: notes.text.trim(),
        dueDate: dueDate,
        priority: priority,
        reminderEnabled: reminderEnabled,
        recurrence: recurrence,
      );
    }
    if (reminderEnabled && !wasEnabled && context.mounted) {
      _showReminderPermissionMessage(context, 'Task');
    }
  }

}

Future<void> showExpenseDialog(
  BuildContext context,
  HubState state, {
  ExpenseEntry? existingExpense,
}) async {
  final isEditing = existingExpense != null;
  final title = TextEditingController(text: existingExpense?.title ?? '');
  final amount = TextEditingController(
    text: existingExpense != null ? existingExpense.amount.toString() : '',
  );
  final notes = TextEditingController(text: existingExpense?.notes ?? '');
  final formKey = GlobalKey<FormState>();

  var category = existingExpense?.category ?? 'Food';
  var date = existingExpense?.date ?? DateTime.now();

  const categories = [
    'Food',
    'Transport',
    'Study',
    'Groceries',
    'Home',
    'Entertainment',
    'Shopping',
    'Health',
    'Other',
  ];

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => DialogControllerOwner(
      controllers: [title, amount, notes],
      child: StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Edit Expense' : 'Log an Expense'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: title,
                    autofocus: !isEditing,
                    decoration: const InputDecoration(
                      labelText: 'What was this expense for?',
                      hintText: 'e.g. Lunch with friends, Subway pass',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter a description'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${state.currency} ',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                    validator: (val) {
                      final p = double.tryParse(
                        (val ?? '').replaceAll(',', '.'),
                      );
                      return p == null || p <= 0
                          ? 'Enter an amount greater than 0'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setLocalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notes,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'e.g. Paid cash, shared with Sam',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.event_outlined,
                      color: AppTheme.primary,
                    ),
                    title: const Text('Date'),
                    subtitle: Text(_longDate(date)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setLocalState(() => date = picked);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(isEditing ? 'Save Changes' : 'Log Expense'),
          ),
        ],
      ),
      ),
    ),
  );

  if (saved == true) {
    final parsedAmount = double.parse(amount.text.replaceAll(',', '.'));
    if (isEditing) {
      await state.updateExpense(
        existingExpense.copyWith(
          title: title.text.trim(),
          amount: parsedAmount,
          category: category,
          notes: notes.text.trim(),
          date: date,
        ),
      );
    } else {
      await state.addExpense(
        title: title.text.trim(),
        amount: parsedAmount,
        category: category,
        notes: notes.text.trim(),
        date: date,
      );
    }
  }

}

Future<void> showPantryDialog(
  BuildContext context,
  HubState state, {
  PantryEntry? existingPantry,
}) async {
  final isEditing = existingPantry != null;
  final name = TextEditingController(text: existingPantry?.name ?? '');
  final quantity = TextEditingController(text: existingPantry?.quantity ?? '');
  final formKey = GlobalKey<FormState>();

  var expiry =
      existingPantry?.expiryDate ??
      _dateOnly(DateTime.now().add(const Duration(days: 7)));
  var category = existingPantry?.category ?? 'Pantry';
  var reminderEnabled =
      existingPantry?.reminderEnabled ??
      ReminderService.instance.supportsScheduledReminders;

  const categories = [
    'Pantry',
    'Fridge',
    'Freezer',
    'Snacks',
    'Spices',
    'Drinks',
  ];

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => DialogControllerOwner(
      controllers: [name, quantity],
      child: StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Edit Pantry Item' : 'Add Pantry Item'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    autofocus: !isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Item name',
                      hintText: 'e.g. Greek Yogurt, Oatmeal, Milk',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter item name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantity,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            hintText: 'e.g. 2 packs, 500g',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                          ),
                          items: categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setLocalState(() => category = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.event_outlined,
                      color: AppTheme.primary,
                    ),
                    title: const Text('Expiry date'),
                    subtitle: Text(_longDate(expiry)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: expiry,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setLocalState(() => expiry = _dateOnly(picked));
                      }
                    },
                  ),
                  if (ReminderService.instance.supportsScheduledReminders)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: reminderEnabled,
                      title: const Text(
                        'Expiry warning reminder',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Alert 3 days before it expires',
                        style: TextStyle(fontSize: 12),
                      ),
                      onChanged: (val) =>
                          setLocalState(() => reminderEnabled = val),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(isEditing ? 'Save Changes' : 'Save Item'),
          ),
        ],
      ),
      ),
    ),
  );

  if (saved == true) {
    bool wasEnabled;
    if (isEditing) {
      wasEnabled = await state.updatePantryItem(
        existingPantry.copyWith(
          name: name.text.trim(),
          quantity: quantity.text.trim(),
          expiryDate: expiry,
          reminderEnabled: reminderEnabled,
          category: category,
        ),
      );
    } else {
      wasEnabled = await state.addPantryItem(
        name: name.text.trim(),
        quantity: quantity.text.trim(),
        expiryDate: expiry,
        reminderEnabled: reminderEnabled,
        category: category,
      );
    }
    if (reminderEnabled && !wasEnabled && context.mounted) {
      _showReminderPermissionMessage(context, 'Pantry item');
    }
  }

}

Future<void> showBudgetDialog(BuildContext context, HubState state) async {
  final controller = TextEditingController(
    text: state.monthlyBudget.toStringAsFixed(0),
  );
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => DialogControllerOwner(
      controllers: [controller],
      child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Monthly Budget'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set a target spending limit for each month. The progress bar will warn you if you reach 80% or exceed it.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Target Budget',
                prefixText: '${state.currency} ',
              ),
              validator: (val) {
                final p = double.tryParse((val ?? '').replaceAll(',', '.'));
                return p == null || p <= 0
                    ? 'Enter a valid budget amount'
                    : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
          },
          child: const Text('Save Budget'),
        ),
      ],
    ),
    ),
  );

  if (saved == true) {
    final amount = double.parse(controller.text.replaceAll(',', '.'));
    await state.setMonthlyBudget(amount);
  }
}

Future<void> showShoppingItemDialog(
  BuildContext context,
  HubState state, {
  ShoppingItem? existingItem,
}) async {
  final name = TextEditingController(text: existingItem?.name ?? '');
  final quantity = TextEditingController(text: existingItem?.quantity ?? '');
  final category = TextEditingController(
    text: existingItem?.category ?? 'General',
  );
  final formKey = GlobalKey<FormState>();
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => DialogControllerOwner(
      controllers: [name, quantity, category],
      child: AlertDialog(
      title: Text(existingItem == null ? 'Add to Shopping List' : 'Edit Item'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: existingItem == null,
                decoration: const InputDecoration(labelText: 'Item name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter an item name'
                    : null,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantity,
                decoration: const InputDecoration(
                  labelText: 'Quantity (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(dialogContext, true);
            }
          },
          child: Text(existingItem == null ? 'Add Item' : 'Save'),
        ),
      ],
    ),
    ),
  );
  if (saved == true) {
    if (existingItem == null) {
      await state.addShoppingItem(
        name: name.text,
        quantity: quantity.text,
        category: category.text,
      );
    } else {
      await state.updateShoppingItem(
        existingItem.copyWith(
          name: name.text.trim(),
          quantity: quantity.text.trim(),
          category: category.text.trim().isEmpty
              ? 'General'
              : category.text.trim(),
        ),
      );
    }
  }
}

Future<void> showCurrencyConverterDialog(
  BuildContext context,
  HubState state,
) async {
  final rateController = TextEditingController(
    text: state.settings.usdToInrRate.toStringAsFixed(4),
  );
  final amountController = TextEditingController(text: '1');
  var usdToInr = true;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => DialogControllerOwner(
      controllers: [rateController, amountController],
      child: StatefulBuilder(
      builder: (context, setLocalState) {
        final rate = double.tryParse(rateController.text) ?? 0;
        final amount = double.tryParse(amountController.text) ?? 0;
        final converted = usdToInr
            ? amount * rate
            : (rate == 0 ? 0 : amount / rate);
        return AlertDialog(
          title: const Text('USD ⇄ INR Converter'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: usdToInr ? 'Amount in USD' : 'Amount in INR',
                  ),
                  onChanged: (_) => setLocalState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'INR for 1 USD'),
                  onChanged: (_) => setLocalState(() {}),
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: true, label: Text('USD → INR')),
                    ButtonSegment(value: false, label: Text('INR → USD')),
                  ],
                  selected: {usdToInr},
                  onSelectionChanged: (value) =>
                      setLocalState(() => usdToInr = value.first),
                ),
                const SizedBox(height: 14),
                Text(
                  'Result: ${usdToInr ? '₹' : '\$'}${converted.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Default reference estimate dated 23 Oct 2026. Exchange rates change, and your bank or payment provider may use a different rate.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: rate.isFinite && rate > 0
                  ? () async {
                      await state.setUsdToInrRate(rate);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    }
                  : null,
              child: const Text('Save Rate'),
            ),
          ],
        );
      },
      ),
    ),
  );
}

Future<void> showWeeklyGoalsDialog(BuildContext context, HubState state) async {
  final tasks = TextEditingController(text: '${state.settings.weeklyTaskGoal}');
  final focus = TextEditingController(
    text: '${state.settings.weeklyFocusGoalMinutes}',
  );
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => DialogControllerOwner(
      controllers: [tasks, focus],
      child: AlertDialog(
      title: const Text('Weekly Goals'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: tasks,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Tasks to complete per week',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: focus,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Focus minutes per week',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Save Goals'),
        ),
      ],
    ),
    ),
  );
  if (saved == true) {
    await state.setWeeklyGoals(
      taskGoal: int.tryParse(tasks.text) ?? state.settings.weeklyTaskGoal,
      focusGoal:
          int.tryParse(focus.text) ?? state.settings.weeklyFocusGoalMinutes,
    );
  }
}

void showQuickAddSheet(
  BuildContext context,
  HubState state, {
  VoidCallback? onOpenTimer,
  VoidCallback? onOpenHabits,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Action',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.iceBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: AppTheme.primary,
                ),
              ),
              title: const Text(
                'Track a Habit or Routine',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Build a repeatable daily or weekly rhythm'),
              onTap: () {
                Navigator.pop(ctx);
                onOpenHabits?.call();
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.iceBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_add,
                  color: AppTheme.primary,
                ),
              ),
              title: const Text(
                'New Assignment or Task',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Plan deadlines, projects, and reminders'),
              onTap: () {
                Navigator.pop(ctx);
                showTaskDialog(context, state);
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.amberSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.amber,
                ),
              ),
              title: const Text(
                'Log an Expense',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Record purchases and monitor your budget'),
              onTap: () {
                Navigator.pop(ctx);
                showExpenseDialog(context, state);
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.violetSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.kitchen_outlined,
                  color: AppTheme.violet,
                ),
              ),
              title: const Text(
                'Add Pantry Item',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Track expiry dates and avoid waste'),
              onTap: () {
                Navigator.pop(ctx);
                showPantryDialog(context, state);
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.emeraldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppTheme.emerald,
                ),
              ),
              title: const Text(
                'Add Shopping Item',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Keep a quick list of what to buy'),
              onTap: () {
                Navigator.pop(ctx);
                showShoppingItemDialog(context, state);
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.skyGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.white),
              ),
              title: const Text(
                'Open Focus Timer',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Go to your Pomodoro timer and progress'),
              onTap: () {
                Navigator.pop(ctx);
                onOpenTimer?.call();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void showSettingsSheet(BuildContext context, HubState state) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (sheetContext, setModalState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Settings & Preferences',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Theme Mode
                const Text(
                  'Appearance',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: 'system',
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto_rounded),
                    ),
                    ButtonSegment(
                      value: 'light',
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_rounded),
                    ),
                    ButtonSegment(
                      value: 'dark',
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_rounded),
                    ),
                  ],
                  selected: {state.settings.themeMode},
                  onSelectionChanged: (val) {
                    state.setThemeMode(val.first);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 20),

                // Currency selector and converter
                const Text(
                  'Currency',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [('\$', 'USD'), ('₹', 'INR')].map((option) {
                    final sym = option.$1;
                    final isSel = state.currency == sym;
                    return ChoiceChip(
                      label: Text(
                        '${option.$2} ($sym)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      selected: isSel,
                      onSelected: (s) {
                        if (s) {
                          state.setCurrency(sym);
                          setModalState(() {});
                        }
                      },
                    );
                  }).toList(),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.currency_exchange_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text(
                    'Currency converter',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '1 USD ≈ ₹${state.settings.usdToInrRate.toStringAsFixed(4)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await showCurrencyConverterDialog(context, state);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 10),

                // Monthly Budget
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Monthly Budget Target',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${state.currency}${state.monthlyBudget.toStringAsFixed(0)}',
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      showBudgetDialog(context, state);
                    },
                    child: const Text('Change'),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Weekly goals',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${state.settings.weeklyTaskGoal} tasks · ${state.settings.weeklyFocusGoalMinutes} focus minutes',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await showWeeklyGoalsDialog(context, state);
                      setModalState(() {});
                    },
                    child: const Text('Change'),
                  ),
                ),
                const Divider(),

                // Backup & Restore
                const Text(
                  'Data Management',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.upload_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Export Hub Data (Backup)'),
                  subtitle: const Text('Copy full JSON backup to clipboard'),
                  onTap: () async {
                    final jsonStr = state.exportToJson();
                    try {
                      await Clipboard.setData(ClipboardData(text: jsonStr));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup copied to clipboard.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not copy the backup. Try again.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.download_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Import Hub Data (Restore)'),
                  subtitle: const Text('Restore from a pasted JSON backup'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showImportDialog(context, state);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: AppTheme.rose,
                  ),
                  title: const Text(
                    'Clear All Data',
                    style: TextStyle(color: AppTheme.rose),
                  ),
                  subtitle: const Text(
                    'Reset all tasks, expenses, and pantry items',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showClearConfirmDialog(context, state);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _showImportDialog(BuildContext context, HubState state) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) => DialogControllerOwner(
      controllers: [controller],
      child: AlertDialog(
      title: const Text('Restore from Backup'),
      content: SizedBox(
        width: 440,
        child: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste backup JSON here...',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final ok = await state.importFromJson(controller.text.trim());
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Data restored successfully!'
                        : 'Backup is invalid or unsupported. No data was changed.',
                  ),
                ),
              );
            }
          },
          child: const Text('Restore'),
        ),
      ],
    ),
    ),
  );
}

void _showClearConfirmDialog(BuildContext context, HubState state) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Clear All Data?'),
      content: const Text(
        'This will erase your tasks, expenses, pantry items, focus history, settings, and saved timer. This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppTheme.rose),
          onPressed: () async {
            await state.clearAllData();
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data has been cleared.')),
              );
            }
          },
          child: const Text('Delete Everything'),
        ),
      ],
    ),
  );
}
