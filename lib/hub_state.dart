import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'reminder_service.dart';

class HubState extends ChangeNotifier {
  HubState({ReminderService? reminders})
    : _reminders = reminders ?? ReminderService.instance;

  final ReminderService _reminders;

  static const _tasksKey = 'hub.tasks.v1';
  static const _expensesKey = 'hub.expenses.v1';
  static const _pantryKey = 'hub.pantry.v1';
  static const _shoppingKey = 'hub.shopping.v1';
  static const _sessionsKey = 'hub.sessions.v1';
  static const _habitsKey = 'hub.habits.v1';
  static const _settingsKey = 'hub.settings.v1';
  static const timerStateKey = 'hub.timer.v1';

  List<HubTask> tasks = [];
  List<ExpenseEntry> expenses = [];
  List<PantryEntry> pantry = [];
  List<ShoppingItem> shopping = [];
  List<FocusSession> sessions = [];
  List<HabitEntry> habits = [];
  AppSettings settings = const AppSettings();

  ThemeMode get themeMode {
    switch (settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String get currency => settings.currency;
  double get monthlyBudget => settings.monthlyBudget;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    tasks = _readList(prefs.getString(_tasksKey), HubTask.fromJson);
    expenses = _readList(prefs.getString(_expensesKey), ExpenseEntry.fromJson);
    pantry = _readList(prefs.getString(_pantryKey), PantryEntry.fromJson);
    shopping = _readList(prefs.getString(_shoppingKey), ShoppingItem.fromJson);
    sessions = _readList(prefs.getString(_sessionsKey), FocusSession.fromJson);
    habits = _readList(prefs.getString(_habitsKey), HabitEntry.fromJson);

    final rawSettings = prefs.getString(_settingsKey);
    if (rawSettings != null && rawSettings.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSettings) as Map<String, Object?>;
        settings = AppSettings.fromJson(decoded);
      } catch (_) {
        settings = const AppSettings();
      }
    } else if (tasks.isNotEmpty ||
        expenses.isNotEmpty ||
        pantry.isNotEmpty ||
        shopping.isNotEmpty ||
        sessions.isNotEmpty ||
        habits.isNotEmpty) {
      // Older app sessions may have saved content without ever saving settings.
      settings = settings.copyWith(hasCompletedOnboarding: true);
      await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    }
    if (settings.currencyMigrationVersion < 1) {
      final shouldConvert = settings.currency == '\$';
      final rate = settings.usdToInrRate;
      if (shouldConvert) {
        expenses = [
          for (final entry in expenses)
            entry.copyWith(amount: entry.amount * rate),
        ];
        settings = settings.copyWith(
          currency: '₹',
          monthlyBudget: settings.monthlyBudget * rate,
          currencyMigrationVersion: 1,
        );
        await prefs.setString(
          _expensesKey,
          jsonEncode(expenses.map((entry) => entry.toJson()).toList()),
        );
      } else {
        settings = settings.copyWith(currencyMigrationVersion: 1);
      }
      await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    }
    notifyListeners();
  }

  List<T> _readList<T>(String? raw, T Function(Map<String, Object?>) decode) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final values = jsonDecode(raw) as List<Object?>;
      return values
          .map((value) => decode(Map<String, Object?>.from(value! as Map)))
          .toList();
    } on Object {
      return [];
    }
  }

  Future<void> _saveList(
    String key,
    List<Object> values,
    Map<String, Object?> Function(Object) encode,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(values.map(encode).toList()));
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  // Task methods
  Future<bool> addTask({
    required String title,
    required String subject,
    required DateTime dueDate,
    required int priority,
    required bool reminderEnabled,
    String notes = '',
    String recurrence = 'none',
  }) async {
    final enableReminder =
        reminderEnabled && await _reminders.requestPermission();
    final id = _id();
    final task = HubTask(
      id: id,
      title: title,
      subject: subject,
      dueDate: dueDate,
      priority: priority,
      reminderEnabled: enableReminder,
      notes: notes,
      recurrence: recurrence,
      seriesId: recurrence == 'none' ? null : id,
    );
    tasks = [...tasks, task];
    await _persistTasks();
    await _reminders.scheduleTask(task);
    return enableReminder;
  }

  Future<bool> updateTask(HubTask updatedTask) async {
    var reminderEnabled = updatedTask.reminderEnabled;
    if (reminderEnabled) {
      final hasPerm = await _reminders.requestPermission();
      if (!hasPerm) {
        reminderEnabled = false;
      }
    }
    final finalTask = updatedTask.copyWith(
      reminderEnabled: reminderEnabled,
      seriesId: updatedTask.recurrence == 'none'
          ? null
          : updatedTask.seriesId ?? updatedTask.id,
      clearSeriesId: updatedTask.recurrence == 'none',
    );
    tasks = [
      for (final current in tasks)
        if (current.id == finalTask.id) finalTask else current,
    ];
    await _persistTasks();
    await _reminders.scheduleTask(finalTask);
    return reminderEnabled;
  }

  Future<void> toggleTask(HubTask task) async {
    final done = !task.isDone;
    tasks = [
      for (final current in tasks)
        if (current.id == task.id)
          current.copyWith(
            isDone: done,
            completedAt: done ? DateTime.now() : null,
            clearCompletedAt: !done,
          )
        else
          current,
    ];
    HubTask? nextOccurrence;
    String? removedOccurrenceId;
    if (task.recurrence != 'none') {
      if (done) {
        final seriesId = task.seriesId ?? task.id;
        final hasOpenOccurrence = tasks.any(
          (current) =>
              current.seriesId == seriesId &&
              !current.isDone &&
              current.dueDate.isAfter(task.dueDate),
        );
        if (!hasOpenOccurrence) {
          final id = _id();
          nextOccurrence = HubTask(
            id: id,
            title: task.title,
            subject: task.subject,
            dueDate: _nextRecurringDate(task.dueDate, task.recurrence),
            priority: task.priority,
            reminderEnabled: task.reminderEnabled,
            notes: task.notes,
            recurrence: task.recurrence,
            seriesId: seriesId,
            generatedFromId: task.id,
          );
          tasks = [...tasks, nextOccurrence];
        }
      } else {
        final generated = tasks.where(
          (current) => current.generatedFromId == task.id && !current.isDone,
        );
        if (generated.isNotEmpty) {
          removedOccurrenceId = generated.first.id;
          tasks = tasks
              .where((current) => current.id != removedOccurrenceId)
              .toList();
        }
      }
    }
    await _persistTasks();
    final updatedTask = tasks.firstWhere((current) => current.id == task.id);
    await _reminders.scheduleTask(updatedTask);
    if (removedOccurrenceId != null) {
      await _reminders.cancelTask(removedOccurrenceId);
    }
    if (nextOccurrence != null) {
      await _reminders.scheduleTask(nextOccurrence);
    }
  }

  DateTime _nextRecurringDate(DateTime date, String recurrence) {
    switch (recurrence) {
      case 'daily':
        return date.add(const Duration(days: 1));
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'monthly':
        final monthStart = DateTime(date.year, date.month + 1);
        final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
        return DateTime(
          monthStart.year,
          monthStart.month,
          date.day > lastDay ? lastDay : date.day,
        );
      default:
        return date;
    }
  }

  Future<bool> toggleTaskReminder(HubTask task) async {
    final enableReminder = !task.reminderEnabled;
    if (enableReminder && !await _reminders.requestPermission()) return false;

    tasks = [
      for (final current in tasks)
        if (current.id == task.id)
          current.copyWith(reminderEnabled: enableReminder)
        else
          current,
    ];
    await _persistTasks();
    final updatedTask = tasks.firstWhere((current) => current.id == task.id);
    await _reminders.scheduleTask(updatedTask);
    return true;
  }

  Future<void> deleteTask(String id) async {
    tasks = tasks.where((task) => task.id != id).toList();
    await _persistTasks();
    await _reminders.cancelTask(id);
  }

  Future<void> restoreTask(HubTask task) async {
    if (tasks.any((current) => current.id == task.id)) return;
    tasks = [...tasks, task];
    await _persistTasks();
    await _reminders.scheduleTask(task);
  }

  // Expense methods
  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    String notes = '',
    DateTime? date,
  }) async {
    expenses = [
      ...expenses,
      ExpenseEntry(
        id: _id(),
        title: title,
        amount: amount,
        category: category,
        date: date ?? DateTime.now(),
        notes: notes,
      ),
    ];
    await _persistExpenses();
  }

  Future<void> updateExpense(ExpenseEntry updated) async {
    expenses = [
      for (final current in expenses)
        if (current.id == updated.id) updated else current,
    ];
    await _persistExpenses();
  }

  Future<void> deleteExpense(String id) async {
    expenses = expenses.where((entry) => entry.id != id).toList();
    await _persistExpenses();
  }

  Future<void> restoreExpense(ExpenseEntry entry) async {
    if (expenses.any((current) => current.id == entry.id)) return;
    expenses = [...expenses, entry];
    await _persistExpenses();
  }

  // Pantry methods
  Future<bool> addPantryItem({
    required String name,
    required String quantity,
    required DateTime expiryDate,
    required bool reminderEnabled,
    String category = 'Pantry',
  }) async {
    final enableReminder =
        reminderEnabled && await _reminders.requestPermission();
    final item = PantryEntry(
      id: _id(),
      name: name,
      quantity: quantity,
      expiryDate: expiryDate,
      reminderEnabled: enableReminder,
      category: category,
    );
    pantry = [...pantry, item];
    await _persistPantry();
    await _reminders.schedulePantryItem(item);
    return enableReminder;
  }

  Future<bool> updatePantryItem(PantryEntry updated) async {
    var reminderEnabled = updated.reminderEnabled;
    if (reminderEnabled) {
      final hasPerm = await _reminders.requestPermission();
      if (!hasPerm) {
        reminderEnabled = false;
      }
    }
    final finalItem = updated.copyWith(reminderEnabled: reminderEnabled);
    pantry = [
      for (final current in pantry)
        if (current.id == finalItem.id) finalItem else current,
    ];
    await _persistPantry();
    await _reminders.schedulePantryItem(finalItem);
    return reminderEnabled;
  }

  Future<void> deletePantryItem(String id) async {
    pantry = pantry.where((entry) => entry.id != id).toList();
    await _persistPantry();
    await _reminders.cancelPantryItem(id);
  }

  Future<void> restorePantryItem(PantryEntry item) async {
    if (pantry.any((current) => current.id == item.id)) return;
    pantry = [...pantry, item];
    await _persistPantry();
    await _reminders.schedulePantryItem(item);
  }

  // Shopping list methods
  Future<bool> addShoppingItem({
    required String name,
    String quantity = '',
    String category = 'General',
    String? sourcePantryId,
  }) async {
    if (sourcePantryId != null &&
        shopping.any((item) => item.sourcePantryId == sourcePantryId)) {
      return false;
    }
    shopping = [
      ...shopping,
      ShoppingItem(
        id: _id(),
        name: name.trim(),
        quantity: quantity.trim(),
        category: category.trim().isEmpty ? 'General' : category.trim(),
        sourcePantryId: sourcePantryId,
      ),
    ];
    await _persistShopping();
    return true;
  }

  Future<void> updateShoppingItem(ShoppingItem updated) async {
    shopping = [
      for (final item in shopping)
        if (item.id == updated.id) updated else item,
    ];
    await _persistShopping();
  }

  Future<void> toggleShoppingItem(ShoppingItem item) async {
    await updateShoppingItem(item.copyWith(isChecked: !item.isChecked));
  }

  Future<void> deleteShoppingItem(String id) async {
    shopping = shopping.where((item) => item.id != id).toList();
    await _persistShopping();
  }

  Future<void> restoreShoppingItem(ShoppingItem item) async {
    if (shopping.any((current) => current.id == item.id)) return;
    shopping = [...shopping, item];
    await _persistShopping();
  }

  Future<bool> addPantryItemToShopping(PantryEntry pantryItem) =>
      addShoppingItem(
        name: pantryItem.name,
        quantity: pantryItem.quantity,
        category: pantryItem.category,
        sourcePantryId: pantryItem.id,
      );

  // Habit and routine methods
  Future<bool> addHabit({
    required String title,
    required String category,
    required List<int> scheduleDays,
    required List<String> steps,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return false;
    habits = [
      ...habits,
      HabitEntry(
        id: _id(),
        title: cleanTitle,
        category: category.trim().isEmpty ? 'Personal' : category.trim(),
        scheduleDays: scheduleDays.toSet().toList()..sort(),
        steps: steps
            .map((step) => step.trim())
            .where((step) => step.isNotEmpty)
            .toList(),
      ),
    ];
    await _persistHabits();
    return true;
  }

  Future<void> updateHabit(HabitEntry updated) async {
    final safeStepDates = <String, List<int>>{
      for (final entry in updated.completedStepsByDate.entries)
        entry.key:
            entry.value
                .where((index) => index >= 0 && index < updated.steps.length)
                .toSet()
                .toList()
              ..sort(),
    };
    final safeUpdated = updated.copyWith(completedStepsByDate: safeStepDates);
    habits = [
      for (final habit in habits)
        if (habit.id == safeUpdated.id) safeUpdated else habit,
    ];
    await _persistHabits();
  }

  Future<void> deleteHabit(String id) async {
    habits = habits.where((habit) => habit.id != id).toList();
    await _persistHabits();
  }

  Future<void> toggleHabitCompletion(HabitEntry habit, DateTime date) async {
    final key = habitDateKey(date);
    final wasComplete = habit.isCompleteOn(date);
    HabitEntry updated;
    if (habit.steps.isEmpty) {
      final dates = habit.completedDates.toSet();
      wasComplete ? dates.remove(key) : dates.add(key);
      updated = habit.copyWith(completedDates: dates.toList()..sort());
    } else {
      final byDate = Map<String, List<int>>.from(habit.completedStepsByDate);
      byDate[key] = wasComplete
          ? <int>[]
          : List<int>.generate(habit.steps.length, (index) => index);
      updated = habit.copyWith(completedStepsByDate: byDate);
    }
    await updateHabit(updated);
  }

  Future<void> toggleRoutineStep(
    HabitEntry habit,
    DateTime date,
    int stepIndex,
  ) async {
    if (stepIndex < 0 || stepIndex >= habit.steps.length) return;
    final key = habitDateKey(date);
    final byDate = Map<String, List<int>>.from(habit.completedStepsByDate);
    final completed = (byDate[key] ?? const <int>[]).toSet();
    completed.contains(stepIndex)
        ? completed.remove(stepIndex)
        : completed.add(stepIndex);
    byDate[key] = completed.toList()..sort();
    await updateHabit(habit.copyWith(completedStepsByDate: byDate));
  }

  Future<void> adjustPantryQuantity(PantryEntry item, int delta) async {
    final match = RegExp(r'^(\s*)(\d+)(.*)$').firstMatch(item.quantity);
    if (match == null || delta == 0) return;
    final current = int.tryParse(match.group(2)!);
    if (current == null) return;
    final adjusted = current + delta < 0 ? 0 : current + delta;
    final quantity = '${match.group(1)}$adjusted${match.group(3)}';
    pantry = [
      for (final existing in pantry)
        if (existing.id == item.id)
          existing.copyWith(quantity: quantity)
        else
          existing,
    ];
    await _persistPantry();
  }

  Future<bool> togglePantryReminder(PantryEntry item) async {
    final enableReminder = !item.reminderEnabled;
    if (enableReminder && !await _reminders.requestPermission()) return false;

    pantry = [
      for (final current in pantry)
        if (current.id == item.id)
          current.copyWith(reminderEnabled: enableReminder)
        else
          current,
    ];
    await _persistPantry();
    final updatedItem = pantry.firstWhere((current) => current.id == item.id);
    await _reminders.schedulePantryItem(updatedItem);
    return true;
  }

  // Focus Session methods
  Future<void> addFocusSession(int minutes, {String label = 'Focus'}) async {
    sessions = [
      ...sessions,
      FocusSession(
        id: _id(),
        minutes: minutes,
        date: DateTime.now(),
        label: label,
      ),
    ];
    await _persistSessions();
  }

  Future<void> deleteFocusSession(String id) async {
    sessions = sessions.where((s) => s.id != id).toList();
    await _persistSessions();
  }

  // Settings methods
  Future<void> setCurrency(String newCurrency) async {
    if (newCurrency == settings.currency) return;
    final rate = settings.usdToInrRate;
    if (rate <= 0 || !rate.isFinite) return;
    double convert(double value) {
      if (settings.currency == '\$' && newCurrency == '₹') {
        return value * rate;
      }
      if (settings.currency == '₹' && newCurrency == '\$') {
        return value / rate;
      }
      return value;
    }

    expenses = [
      for (final entry in expenses)
        entry.copyWith(amount: convert(entry.amount)),
    ];
    await _persistExpenses();
    settings = settings.copyWith(
      currency: newCurrency,
      monthlyBudget: convert(settings.monthlyBudget),
    );
    await _persistSettings();
  }

  Future<void> setUsdToInrRate(double rate) async {
    if (!rate.isFinite || rate <= 0) return;
    settings = settings.copyWith(usdToInrRate: rate);
    await _persistSettings();
  }

  Future<void> setWeeklyGoals({
    required int taskGoal,
    required int focusGoal,
  }) async {
    settings = settings.copyWith(
      weeklyTaskGoal: taskGoal.clamp(1, 100),
      weeklyFocusGoalMinutes: focusGoal.clamp(5, 10000),
    );
    await _persistSettings();
  }

  int get currentStreak {
    final activeDays = <DateTime>{
      for (final task in tasks)
        if (task.isDone && task.completedAt != null)
          DateTime(
            task.completedAt!.year,
            task.completedAt!.month,
            task.completedAt!.day,
          ),
      for (final session in sessions)
        DateTime(session.date.year, session.date.month, session.date.day),
      for (final habit in habits)
        for (final key in {
          ...habit.completedDates,
          ...habit.completedStepsByDate.keys,
        })
          if (DateTime.tryParse(key) case final date?)
            if (habit.isCompleteOn(date))
              DateTime(date.year, date.month, date.day),
    };
    final today = DateTime.now();
    var day = DateTime(today.year, today.month, today.day);
    if (!activeDays.contains(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (activeDays.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> setMonthlyBudget(double newBudget) async {
    settings = settings.copyWith(monthlyBudget: newBudget);
    await _persistSettings();
  }

  Future<void> setThemeMode(String mode) async {
    settings = settings.copyWith(themeMode: mode);
    await _persistSettings();
  }

  // Backup & Restore
  String exportToJson() {
    final map = {
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'pantry': pantry.map((p) => p.toJson()).toList(),
      'shopping': shopping.map((item) => item.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'habits': habits.map((habit) => habit.toJson()).toList(),
      'settings': settings.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<bool> importFromJson(String rawJson) async {
    final List<HubTask> importedTasks;
    final List<ExpenseEntry> importedExpenses;
    final List<PantryEntry> importedPantry;
    final List<ShoppingItem> importedShopping;
    final List<FocusSession> importedSessions;
    final List<HabitEntry> importedHabits;
    final AppSettings importedSettings;

    try {
      final backup = _objectMap(jsonDecode(rawJson));
      final version = backup['version'];
      if (version is! int || !{1, 2, 3}.contains(version)) return false;
      importedTasks = _decodeList(
        backup['tasks'],
        HubTask.fromJson,
        (task) => task.id,
        (task) =>
            task.id.trim().isNotEmpty &&
            task.title.trim().isNotEmpty &&
            task.priority >= 0 &&
            task.priority <= 2 &&
            {'none', 'daily', 'weekly', 'monthly'}.contains(task.recurrence),
      );
      importedExpenses = _decodeList(
        backup['expenses'],
        ExpenseEntry.fromJson,
        (entry) => entry.id,
        (entry) =>
            entry.id.trim().isNotEmpty &&
            entry.title.trim().isNotEmpty &&
            entry.amount.isFinite &&
            entry.amount >= 0,
      );
      importedPantry = _decodeList(
        backup['pantry'],
        PantryEntry.fromJson,
        (item) => item.id,
        (item) => item.id.trim().isNotEmpty && item.name.trim().isNotEmpty,
      );
      importedShopping = version == 1
          ? <ShoppingItem>[]
          : _decodeList(
              backup['shopping'],
              ShoppingItem.fromJson,
              (item) => item.id,
              (item) =>
                  item.id.trim().isNotEmpty && item.name.trim().isNotEmpty,
            );
      importedSessions = _decodeList(
        backup['sessions'],
        FocusSession.fromJson,
        (session) => session.id,
        (session) => session.id.trim().isNotEmpty && session.minutes > 0,
      );
      importedHabits = version < 3
          ? <HabitEntry>[]
          : _decodeList(
              backup['habits'],
              HabitEntry.fromJson,
              (habit) => habit.id,
              (habit) =>
                  habit.id.trim().isNotEmpty &&
                  habit.title.trim().isNotEmpty &&
                  habit.scheduleDays.every((day) => day >= 1 && day <= 7) &&
                  habit.scheduleDays.toSet().length ==
                      habit.scheduleDays.length &&
                  habit.steps.every((step) => step.trim().isNotEmpty) &&
                  habit.completedDates.every(
                    (date) => DateTime.tryParse(date) != null,
                  ) &&
                  habit.completedStepsByDate.entries.every(
                    (entry) =>
                        DateTime.tryParse(entry.key) != null &&
                        entry.value.toSet().length == entry.value.length &&
                        entry.value.every(
                          (index) => index >= 0 && index < habit.steps.length,
                        ),
                  ),
            );
      importedSettings = AppSettings.fromJson(_objectMap(backup['settings']));
      if (importedSettings.currency.trim().isEmpty ||
          !importedSettings.monthlyBudget.isFinite ||
          importedSettings.monthlyBudget < 0 ||
          !importedSettings.usdToInrRate.isFinite ||
          importedSettings.usdToInrRate <= 0 ||
          importedSettings.weeklyTaskGoal < 1 ||
          importedSettings.weeklyFocusGoalMinutes < 1 ||
          !{'system', 'light', 'dark'}.contains(importedSettings.themeMode)) {
        return false;
      }
    } catch (_) {
      return false;
    }

    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return false;
    }
    const keys = [
      _tasksKey,
      _expensesKey,
      _pantryKey,
      _shoppingKey,
      _sessionsKey,
      _habitsKey,
      _settingsKey,
    ];
    final previous = {for (final key in keys) key: prefs.getString(key)};
    final encodedData = <String, String>{
      _tasksKey: jsonEncode(
        importedTasks.map((task) => task.toJson()).toList(),
      ),
      _expensesKey: jsonEncode(
        importedExpenses.map((entry) => entry.toJson()).toList(),
      ),
      _pantryKey: jsonEncode(
        importedPantry.map((item) => item.toJson()).toList(),
      ),
      _shoppingKey: jsonEncode(
        importedShopping.map((item) => item.toJson()).toList(),
      ),
      _sessionsKey: jsonEncode(
        importedSessions.map((session) => session.toJson()).toList(),
      ),
      _habitsKey: jsonEncode(
        importedHabits.map((habit) => habit.toJson()).toList(),
      ),
      _settingsKey: jsonEncode(
        importedSettings.copyWith(hasCompletedOnboarding: true).toJson(),
      ),
    };
    try {
      for (final entry in encodedData.entries) {
        if (!await prefs.setString(entry.key, entry.value)) {
          throw StateError('Could not save backup data.');
        }
      }
    } catch (_) {
      try {
        for (final key in keys) {
          final value = previous[key];
          if (value == null) {
            await prefs.remove(key);
          } else {
            await prefs.setString(key, value);
          }
        }
      } catch (_) {
        // Preserve the existing in-memory state if rollback storage also fails.
      }
      return false;
    }

    tasks = importedTasks;
    expenses = importedExpenses;
    pantry = importedPantry;
    shopping = importedShopping;
    sessions = importedSessions;
    habits = importedHabits;
    settings = importedSettings.copyWith(hasCompletedOnboarding: true);
    if (settings.currencyMigrationVersion < 1) {
      if (settings.currency == '\$') {
        expenses = [
          for (final entry in expenses)
            entry.copyWith(amount: entry.amount * settings.usdToInrRate),
        ];
        settings = settings.copyWith(
          currency: '₹',
          monthlyBudget: settings.monthlyBudget * settings.usdToInrRate,
          currencyMigrationVersion: 1,
        );
      } else {
        settings = settings.copyWith(currencyMigrationVersion: 1);
      }
      await _persistExpenses();
      await _persistSettings();
    }
    try {
      await _reminders.replaceSchedules(tasks, pantry);
    } catch (_) {
      // Imported data remains available even if the OS rejects a reminder.
    }
    notifyListeners();
    return true;
  }

  Future<void> clearAllData() async {
    tasks = [];
    expenses = [];
    pantry = [];
    shopping = [];
    sessions = [];
    habits = [];
    settings = const AppSettings();
    try {
      await _reminders.cancelAll();
    } catch (_) {
      // Clear the local data even if the notification plugin is unavailable.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    await prefs.remove(_expensesKey);
    await prefs.remove(_pantryKey);
    await prefs.remove(_shoppingKey);
    await prefs.remove(_sessionsKey);
    await prefs.remove(_habitsKey);
    await prefs.remove(_settingsKey);
    await prefs.remove(timerStateKey);
    notifyListeners();
  }

  Map<String, Object?> _objectMap(Object? value) {
    if (value is! Map) throw const FormatException('Expected a JSON object.');
    return Map<String, Object?>.from(value);
  }

  List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, Object?>) decode,
    String Function(T) idOf,
    bool Function(T) isValid,
  ) {
    if (value is! List) throw const FormatException('Expected a JSON list.');
    final result = value.map((entry) => decode(_objectMap(entry))).toList();
    final ids = result.map(idOf).toSet();
    if (ids.length != result.length || result.any((entry) => !isValid(entry))) {
      throw const FormatException('Backup contains invalid or duplicate data.');
    }
    return result;
  }

  Future<void> _persistTasks() async {
    await _saveList(_tasksKey, tasks, (value) => (value as HubTask).toJson());
    notifyListeners();
  }

  Future<void> _persistExpenses() async {
    await _saveList(
      _expensesKey,
      expenses,
      (value) => (value as ExpenseEntry).toJson(),
    );
    notifyListeners();
  }

  Future<void> _persistPantry() async {
    await _saveList(
      _pantryKey,
      pantry,
      (value) => (value as PantryEntry).toJson(),
    );
    notifyListeners();
  }

  Future<void> _persistShopping() async {
    await _saveList(
      _shoppingKey,
      shopping,
      (value) => (value as ShoppingItem).toJson(),
    );
    notifyListeners();
  }

  Future<void> _persistSessions() async {
    await _saveList(
      _sessionsKey,
      sessions,
      (value) => (value as FocusSession).toJson(),
    );
    notifyListeners();
  }

  Future<void> _persistHabits() async {
    await _saveList(
      _habitsKey,
      habits,
      (value) => (value as HabitEntry).toJson(),
    );
    notifyListeners();
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (settings.hasCompletedOnboarding) return;
    settings = settings.copyWith(hasCompletedOnboarding: true);
    await _persistSettings();
  }
}
