import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  static const _sessionsKey = 'hub.sessions.v1';

  List<HubTask> tasks = [];
  List<ExpenseEntry> expenses = [];
  List<PantryEntry> pantry = [];
  List<FocusSession> sessions = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    tasks = _readList(prefs.getString(_tasksKey), HubTask.fromJson);
    expenses = _readList(prefs.getString(_expensesKey), ExpenseEntry.fromJson);
    pantry = _readList(prefs.getString(_pantryKey), PantryEntry.fromJson);
    sessions = _readList(prefs.getString(_sessionsKey), FocusSession.fromJson);
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

  Future<bool> addTask({
    required String title,
    required String subject,
    required DateTime dueDate,
    required int priority,
    required bool reminderEnabled,
  }) async {
    final enableReminder =
        reminderEnabled && await _reminders.requestPermission();
    final task = HubTask(
      id: _id(),
      title: title,
      subject: subject,
      dueDate: dueDate,
      priority: priority,
      reminderEnabled: enableReminder,
    );
    tasks = [...tasks, task];
    await _persistTasks();
    await _reminders.scheduleTask(task);
    return enableReminder;
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
    await _persistTasks();
    final updatedTask = tasks.firstWhere((current) => current.id == task.id);
    await _reminders.scheduleTask(updatedTask);
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

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
  }) async {
    expenses = [
      ...expenses,
      ExpenseEntry(
        id: _id(),
        title: title,
        amount: amount,
        category: category,
        date: DateTime.now(),
      ),
    ];
    await _persistExpenses();
  }

  Future<void> deleteExpense(String id) async {
    expenses = expenses.where((entry) => entry.id != id).toList();
    await _persistExpenses();
  }

  Future<bool> addPantryItem({
    required String name,
    required String quantity,
    required DateTime expiryDate,
    required bool reminderEnabled,
  }) async {
    final enableReminder =
        reminderEnabled && await _reminders.requestPermission();
    final item = PantryEntry(
      id: _id(),
      name: name,
      quantity: quantity,
      expiryDate: expiryDate,
      reminderEnabled: enableReminder,
    );
    pantry = [...pantry, item];
    await _persistPantry();
    await _reminders.schedulePantryItem(item);
    return enableReminder;
  }

  Future<void> deletePantryItem(String id) async {
    pantry = pantry.where((entry) => entry.id != id).toList();
    await _persistPantry();
    await _reminders.cancelPantryItem(id);
  }

  Future<bool> togglePantryReminder(PantryEntry item) async {
    final enableReminder = !item.reminderEnabled;
    if (enableReminder && !await _reminders.requestPermission()) return false;

    pantry = [
      for (final current in pantry)
        if (current.id == item.id)
          PantryEntry(
            id: current.id,
            name: current.name,
            quantity: current.quantity,
            expiryDate: current.expiryDate,
            reminderEnabled: enableReminder,
          )
        else
          current,
    ];
    await _persistPantry();
    final updatedItem = pantry.firstWhere((current) => current.id == item.id);
    await _reminders.schedulePantryItem(updatedItem);
    return true;
  }

  Future<void> addFocusSession(int minutes) async {
    sessions = [
      ...sessions,
      FocusSession(id: _id(), minutes: minutes, date: DateTime.now()),
    ];
    await _persistSessions();
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

  Future<void> _persistSessions() async {
    await _saveList(
      _sessionsKey,
      sessions,
      (value) => (value as FocusSession).toJson(),
    );
    notifyListeners();
  }
}
