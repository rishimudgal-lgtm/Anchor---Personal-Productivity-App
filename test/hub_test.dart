import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_management_hub/hub_state.dart';
import 'package:my_management_hub/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Model Serialization & Logic Tests', () {
    test('HubTask copyWith & JSON round-trip', () {
      final now = DateTime(2026, 10, 26);
      final task = HubTask(
        id: 'task_1',
        title: 'Math Assignment',
        subject: 'Math',
        dueDate: now,
        priority: 2,
        notes: 'Chapter 5',
      );

      final json = task.toJson();
      final revived = HubTask.fromJson(json);

      expect(revived.id, 'task_1');
      expect(revived.title, 'Math Assignment');
      expect(revived.priority, 2);
      expect(revived.notes, 'Chapter 5');
      expect(revived.isDone, false);

      final done = revived.copyWith(isDone: true);
      expect(done.isDone, true);
    });

    test('ExpenseEntry JSON round-trip & calculation', () {
      final now = DateTime(2026, 10, 26);
      final expense = ExpenseEntry(
        id: 'exp_1',
        title: 'Lunch',
        amount: 14.50,
        category: 'Food',
        date: now,
        notes: 'With team',
      );

      final json = expense.toJson();
      final revived = ExpenseEntry.fromJson(json);

      expect(revived.title, 'Lunch');
      expect(revived.amount, 14.50);
      expect(revived.category, 'Food');
      expect(revived.notes, 'With team');
    });

    test('PantryEntry JSON round-trip & category', () {
      final expiry = DateTime(2026, 10, 30);
      final item = PantryEntry(
        id: 'pantry_1',
        name: 'Oat Milk',
        quantity: '2 cartons',
        expiryDate: expiry,
        category: 'Fridge',
      );

      final json = item.toJson();
      final revived = PantryEntry.fromJson(json);

      expect(revived.name, 'Oat Milk');
      expect(revived.quantity, '2 cartons');
      expect(revived.category, 'Fridge');
    });

    test('AppSettings JSON round-trip & defaults', () {
      const settings = AppSettings();
      expect(settings.currency, '₹');
      expect(settings.monthlyBudget, 500.0);
      expect(settings.themeMode, 'system');

      final customized = settings.copyWith(
        currency: '€',
        monthlyBudget: 750.0,
        themeMode: 'dark',
      );

      final json = customized.toJson();
      final revived = AppSettings.fromJson(json);
      expect(revived.currency, '€');
      expect(revived.monthlyBudget, 750.0);
      expect(revived.themeMode, 'dark');
    });
  });

  group('HubState Functionality Tests', () {
    test('State management operations', () async {
      final state = HubState();
      await state.load();

      expect(state.tasks, isEmpty);
      expect(state.expenses, isEmpty);
      expect(state.pantry, isEmpty);
      expect(state.sessions, isEmpty);

      // Add task
      await state.addTask(
        title: 'Complete Project',
        subject: 'Computer Science',
        dueDate: DateTime.now(),
        priority: 2,
        reminderEnabled: false,
      );
      expect(state.tasks.length, 1);
      expect(state.tasks.first.title, 'Complete Project');

      // Toggle task
      await state.toggleTask(state.tasks.first);
      expect(state.tasks.first.isDone, true);

      // Add expense
      await state.addExpense(title: 'Coffee', amount: 4.5, category: 'Food');
      expect(state.expenses.length, 1);

      // Add pantry
      await state.addPantryItem(
        name: 'Apples',
        quantity: '1 bag',
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        reminderEnabled: false,
        category: 'Pantry',
      );
      expect(state.pantry.length, 1);

      // Add focus session
      await state.addFocusSession(25, label: 'Pomodoro');
      expect(state.sessions.length, 1);
      expect(state.sessions.first.minutes, 25);
      expect(state.sessions.first.label, 'Pomodoro');

      // Export data
      final exportedJson = state.exportToJson();
      expect(exportedJson.contains('Complete Project'), true);
      expect(exportedJson.contains('Coffee'), true);

      // Clear all
      await state.clearAllData();
      expect(state.tasks, isEmpty);
      expect(state.expenses, isEmpty);

      // Import data
      final success = await state.importFromJson(exportedJson);
      expect(success, true);
      expect(state.tasks.length, 1);
      expect(state.expenses.length, 1);
    });

    test('invalid backup leaves all current data unchanged', () async {
      final state = HubState();
      await state.load();
      await state.addTask(
        title: 'Keep this task',
        subject: 'Work',
        dueDate: DateTime(2026, 10, 27),
        priority: 1,
        reminderEnabled: false,
      );
      final prefs = await SharedPreferences.getInstance();
      final storedTasksBefore = prefs.getString('hub.tasks.v1');
      final invalidBackup = jsonEncode({
        'version': 1,
        'tasks': <Object?>[
          <String, Object?>{
            'id': 'replacement',
            'title': 'Would replace current data',
            'subject': '',
            'dueDate': '2026-10-28T00:00:00.000',
            'priority': 1,
            'isDone': false,
          },
        ],
        'expenses': <Object?>[
          <String, Object?>{'id': 'broken entry'},
        ],
        'pantry': <Object?>[],
        'sessions': <Object?>[],
        'settings': const AppSettings().toJson(),
      });

      expect(await state.importFromJson(invalidBackup), isFalse);
      expect(state.tasks.single.title, 'Keep this task');
      expect(prefs.getString('hub.tasks.v1'), storedTasksBefore);
    });

    test('rejects unsupported backup versions', () async {
      final state = HubState();
      await state.load();
      final backup = jsonDecode(state.exportToJson()) as Map<String, Object?>;
      backup['version'] = 3;

      expect(await state.importFromJson(jsonEncode(backup)), isFalse);
      expect(state.tasks, isEmpty);
    });

    test('clear all resets settings and persisted timer state', () async {
      final state = HubState();
      await state.load();
      await state.setCurrency('€');
      await state.setMonthlyBudget(900);
      await state.setThemeMode('dark');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(HubState.timerStateKey, '{"isRunning":true}');

      await state.clearAllData();

      expect(state.settings.currency, '₹');
      expect(state.settings.monthlyBudget, 500);
      expect(state.settings.themeMode, 'system');
      expect(prefs.getString('hub.settings.v1'), isNull);
      expect(prefs.getString(HubState.timerStateKey), isNull);
      final reloaded = HubState();
      await reloaded.load();
      expect(reloaded.settings.currency, '₹');
      expect(reloaded.settings.themeMode, 'system');
    });

    test(
      'pantry quantity controls preserve units and never go negative',
      () async {
        final state = HubState();
        await state.load();
        await state.addPantryItem(
          name: 'Oat milk',
          quantity: '2 cartons',
          expiryDate: DateTime(2026, 11, 2),
          reminderEnabled: false,
        );

        await state.adjustPantryQuantity(state.pantry.single, -1);
        expect(state.pantry.single.quantity, '1 cartons');
        await state.adjustPantryQuantity(state.pantry.single, -5);
        expect(state.pantry.single.quantity, '0 cartons');
        await state.adjustPantryQuantity(state.pantry.single, -1);
        expect(state.pantry.single.quantity, '0 cartons');
      },
    );
  });
}
