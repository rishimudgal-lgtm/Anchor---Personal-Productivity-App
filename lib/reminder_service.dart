import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'models.dart';

class ReminderService {
  ReminderService._();

  static final instance = ReminderService._();

  static const _channelId = 'hub_reminders';
  static const _reminderHour = 9;
  static const _settingsChannel = MethodChannel('anchor/notifications');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initialization;

  bool get supportsScheduledReminders =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    if (!supportsScheduledReminders) {
      _initialized = true;
      return Future<void>.value();
    }
    return _initialization ??= _initializePlatform();
  }

  Future<void> _initializePlatform() async {
    try {
      timezone_data.initializeTimeZones();
      try {
        final localTimezone = await FlutterTimezone.getLocalTimezone();
        timezone.setLocalLocation(
          timezone.getLocation(localTimezone.identifier),
        );
      } catch (error) {
        // A timezone plugin failure should not disable reminders. Use the
        // device's current UTC offset as a fixed-offset fallback for this run.
        final now = DateTime.now();
        final abbreviation = now.timeZoneName.isEmpty
            ? 'Local'
            : now.timeZoneName;
        timezone.setLocalLocation(
          timezone.Location('Local/$abbreviation', const [], const [], [
            timezone.TimeZone(
              now.timeZoneOffset,
              isDst: false,
              abbreviation: abbreviation,
            ),
          ]),
        );
        debugPrint(
          'Could not read the device timezone; using its current UTC offset: $error',
        );
      }

      final initialized = await _notifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat_anchor'),
        ),
      );
      if (initialized != true) {
        throw StateError('Android notification plugin did not initialize.');
      }
      _initialized = true;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<bool> requestPermission() async {
    if (!supportsScheduledReminders) return false;
    try {
      await initialize();
    } catch (error) {
      debugPrint(
        'Could not initialize reminders before requesting permission: $error',
      );
      return false;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      return await android?.requestNotificationsPermission() ?? false;
    } catch (error) {
      debugPrint('Could not request notification permission: $error');
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (!supportsScheduledReminders || !_initialized) return false;
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      return await android?.areNotificationsEnabled() ?? false;
    } catch (error) {
      debugPrint('Could not read notification permission status: $error');
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    if (!supportsScheduledReminders) return;
    try {
      await _settingsChannel.invokeMethod<void>('openNotificationSettings');
    } catch (error) {
      debugPrint('Could not open notification settings: $error');
    }
  }

  Future<void> scheduleTask(HubTask task) async {
    if (!supportsScheduledReminders || !_initialized) return;
    final id = _notificationId(task.id, pantry: false);
    if (!task.reminderEnabled || task.isDone) {
      await _notifications.cancel(id: id);
      return;
    }

    final dueDay = _dateOnly(task.dueDate);
    await _schedule(
      id: id,
      title: 'Task due today',
      body: '${task.title} is due today.',
      reminderDay: dueDay,
      payload: 'task:${task.id}',
      remindImmediatelyIfPast: true,
    );
  }

  Future<void> schedulePantryItem(PantryEntry item) async {
    if (!supportsScheduledReminders || !_initialized) return;
    final id = _notificationId(item.id, pantry: true);
    if (!item.reminderEnabled) {
      await _notifications.cancel(id: id);
      return;
    }

    final today = _dateOnly(DateTime.now());
    final expiryDay = _dateOnly(item.expiryDate);
    if (expiryDay.isBefore(today)) {
      await _notifications.cancel(id: id);
      return;
    }
    var reminderDay = expiryDay.subtract(const Duration(days: 3));
    if (reminderDay.isBefore(today)) reminderDay = today;

    final reminderTime = DateTime(
      reminderDay.year,
      reminderDay.month,
      reminderDay.day,
      _reminderHour,
    );
    if (!reminderTime.isAfter(DateTime.now()) && expiryDay.isAfter(today)) {
      reminderDay = today.add(const Duration(days: 1));
    }

    await _schedule(
      id: id,
      title: 'Pantry item expiring soon',
      body: '${item.name} expires on ${_formatDate(expiryDay)}.',
      reminderDay: reminderDay,
      payload: 'pantry:${item.id}',
      remindImmediatelyIfPast: expiryDay == today,
    );
  }

  Future<void> cancelTask(String id) async {
    if (!supportsScheduledReminders || !_initialized) return;
    await _notifications.cancel(id: _notificationId(id, pantry: false));
  }

  Future<void> cancelPantryItem(String id) async {
    if (!supportsScheduledReminders || !_initialized) return;
    await _notifications.cancel(id: _notificationId(id, pantry: true));
  }

  Future<void> cancelAll() async {
    if (!supportsScheduledReminders || !_initialized) return;
    await _notifications.cancelAll();
  }

  Future<void> replaceSchedules(
    List<HubTask> tasks,
    List<PantryEntry> pantry,
  ) async {
    if (!supportsScheduledReminders || !_initialized) return;
    await cancelAll();
    for (final task in tasks) {
      await scheduleTask(task);
    }
    for (final item in pantry) {
      await schedulePantryItem(item);
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime reminderDay,
    required String payload,
    bool remindImmediatelyIfPast = false,
  }) async {
    var scheduledDate = timezone.TZDateTime(
      timezone.local,
      reminderDay.year,
      reminderDay.month,
      reminderDay.day,
      _reminderHour,
    );
    final now = timezone.TZDateTime.now(timezone.local);
    if (!scheduledDate.isAfter(now)) {
      final today = _dateOnly(DateTime.now());
      if (remindImmediatelyIfPast && _dateOnly(reminderDay) == today) {
        scheduledDate = now.add(const Duration(minutes: 1));
      } else {
        await _notifications.cancel(id: id);
        return;
      }
    }

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Task and pantry reminders',
          channelDescription: 'Reminders for task deadlines and pantry expiry',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  int _notificationId(String value, {required bool pantry}) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    final id = (hash & 0x3fffffff) * 2 + (pantry ? 1 : 0);
    return id == 0 ? (pantry ? 1 : 2) : id;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
