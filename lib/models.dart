class HubTask {
  const HubTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.priority,
    this.isDone = false,
    this.completedAt,
    this.reminderEnabled = false,
    this.notes = '',
    this.recurrence = 'none',
    this.seriesId,
    this.generatedFromId,
  });

  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final int priority;
  final bool isDone;
  final DateTime? completedAt;
  final bool reminderEnabled;
  final String notes;
  final String recurrence;
  final String? seriesId;
  final String? generatedFromId;

  HubTask copyWith({
    String? title,
    String? subject,
    DateTime? dueDate,
    int? priority,
    bool? isDone,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? reminderEnabled,
    String? notes,
    String? recurrence,
    String? seriesId,
    bool clearSeriesId = false,
    String? generatedFromId,
  }) {
    return HubTask(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      notes: notes ?? this.notes,
      recurrence: recurrence ?? this.recurrence,
      seriesId: clearSeriesId ? null : seriesId ?? this.seriesId,
      generatedFromId: generatedFromId ?? this.generatedFromId,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'dueDate': _day(dueDate),
    'priority': priority,
    'isDone': isDone,
    'completedAt': completedAt?.toIso8601String(),
    'reminderEnabled': reminderEnabled,
    'notes': notes,
    'recurrence': recurrence,
    'seriesId': seriesId,
    'generatedFromId': generatedFromId,
  };

  factory HubTask.fromJson(Map<String, Object?> json) => HubTask(
    id: json['id'] as String,
    title: json['title'] as String,
    subject: json['subject'] as String? ?? '',
    dueDate: DateTime.parse(json['dueDate'] as String),
    priority: json['priority'] as int? ?? 1,
    isDone: json['isDone'] as bool? ?? false,
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
    reminderEnabled: json['reminderEnabled'] as bool? ?? false,
    notes: json['notes'] as String? ?? '',
    recurrence: json['recurrence'] as String? ?? 'none',
    seriesId: json['seriesId'] as String?,
    generatedFromId: json['generatedFromId'] as String?,
  );
}

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes = '',
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String notes;

  ExpenseEntry copyWith({
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
  }) {
    return ExpenseEntry(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'date': _day(date),
    'notes': notes,
  };

  factory ExpenseEntry.fromJson(Map<String, Object?> json) => ExpenseEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String? ?? 'Other',
    date: DateTime.parse(json['date'] as String),
    notes: json['notes'] as String? ?? '',
  );
}

class PantryEntry {
  const PantryEntry({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiryDate,
    this.reminderEnabled = false,
    this.category = 'Pantry',
  });

  final String id;
  final String name;
  final String quantity;
  final DateTime expiryDate;
  final bool reminderEnabled;
  final String category;

  PantryEntry copyWith({
    String? name,
    String? quantity,
    DateTime? expiryDate,
    bool? reminderEnabled,
    String? category,
  }) {
    return PantryEntry(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      category: category ?? this.category,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'expiryDate': _day(expiryDate),
    'reminderEnabled': reminderEnabled,
    'category': category,
  };

  factory PantryEntry.fromJson(Map<String, Object?> json) => PantryEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] as String? ?? '',
    expiryDate: DateTime.parse(json['expiryDate'] as String),
    reminderEnabled: json['reminderEnabled'] as bool? ?? false,
    category: json['category'] as String? ?? 'Pantry',
  );
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.minutes,
    required this.date,
    this.label = 'Focus',
  });

  final String id;
  final int minutes;
  final DateTime date;
  final String label;

  FocusSession copyWith({int? minutes, DateTime? date, String? label}) {
    return FocusSession(
      id: id,
      minutes: minutes ?? this.minutes,
      date: date ?? this.date,
      label: label ?? this.label,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'minutes': minutes,
    'date': _day(date),
    'label': label,
  };

  factory FocusSession.fromJson(Map<String, Object?> json) => FocusSession(
    id: json['id'] as String,
    minutes: json['minutes'] as int,
    date: DateTime.parse(json['date'] as String),
    label: json['label'] as String? ?? 'Focus',
  );
}

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = '',
    this.category = 'General',
    this.isChecked = false,
    this.sourcePantryId,
  });

  final String id;
  final String name;
  final String quantity;
  final String category;
  final bool isChecked;
  final String? sourcePantryId;

  ShoppingItem copyWith({
    String? name,
    String? quantity,
    String? category,
    bool? isChecked,
    String? sourcePantryId,
  }) => ShoppingItem(
    id: id,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    category: category ?? this.category,
    isChecked: isChecked ?? this.isChecked,
    sourcePantryId: sourcePantryId ?? this.sourcePantryId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'category': category,
    'isChecked': isChecked,
    'sourcePantryId': sourcePantryId,
  };

  factory ShoppingItem.fromJson(Map<String, Object?> json) => ShoppingItem(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] as String? ?? '',
    category: json['category'] as String? ?? 'General',
    isChecked: json['isChecked'] as bool? ?? false,
    sourcePantryId: json['sourcePantryId'] as String?,
  );
}

/// A daily habit or a routine made up of steps. Completion history is stored
/// with the definition so it survives app restarts and JSON backup/restore.
class HabitEntry {
  const HabitEntry({
    required this.id,
    required this.title,
    this.category = 'Personal',
    this.scheduleDays = const [],
    this.steps = const [],
    this.completedDates = const [],
    this.completedStepsByDate = const {},
  });

  final String id;
  final String title;
  final String category;

  /// DateTime weekday values (Monday = 1 … Sunday = 7); empty means every day.
  final List<int> scheduleDays;
  final List<String> steps;

  /// Date keys for completed single-step habits.
  final List<String> completedDates;

  /// Date key to completed routine step indexes.
  final Map<String, List<int>> completedStepsByDate;

  bool isScheduledOn(DateTime date) =>
      scheduleDays.isEmpty || scheduleDays.contains(date.weekday);

  int completedStepCountOn(DateTime date) =>
      (completedStepsByDate[habitDateKey(date)] ?? const <int>[])
          .where((index) => index >= 0 && index < steps.length)
          .toSet()
          .length;

  bool isCompleteOn(DateTime date) {
    final key = habitDateKey(date);
    if (steps.isEmpty) return completedDates.contains(key);
    final completed = completedStepsByDate[key] ?? const <int>[];
    return steps.isNotEmpty &&
        List<int>.generate(
          steps.length,
          (index) => index,
        ).every(completed.contains);
  }

  HabitEntry copyWith({
    String? title,
    String? category,
    List<int>? scheduleDays,
    List<String>? steps,
    List<String>? completedDates,
    Map<String, List<int>>? completedStepsByDate,
  }) => HabitEntry(
    id: id,
    title: title ?? this.title,
    category: category ?? this.category,
    scheduleDays: scheduleDays ?? this.scheduleDays,
    steps: steps ?? this.steps,
    completedDates: completedDates ?? this.completedDates,
    completedStepsByDate: completedStepsByDate ?? this.completedStepsByDate,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'scheduleDays': scheduleDays,
    'steps': steps,
    'completedDates': completedDates,
    'completedStepsByDate': completedStepsByDate,
  };

  factory HabitEntry.fromJson(Map<String, Object?> json) {
    final rawStepDates = json['completedStepsByDate'];
    final stepDates = rawStepDates is Map
        ? rawStepDates.map(
            (key, value) => MapEntry(
              key.toString(),
              (value as List).map((index) => (index as num).toInt()).toList(),
            ),
          )
        : <String, List<int>>{};
    return HabitEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'Personal',
      scheduleDays: (json['scheduleDays'] as List? ?? const [])
          .map((day) => (day as num).toInt())
          .toList(),
      steps: (json['steps'] as List? ?? const []).cast<String>(),
      completedDates: (json['completedDates'] as List? ?? const [])
          .cast<String>(),
      completedStepsByDate: stepDates,
    );
  }
}

String habitDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class AppSettings {
  const AppSettings({
    this.currency = '₹',
    this.monthlyBudget = 500.0,
    this.themeMode = 'system',
    this.usdToInrRate = 94.9432,
    this.weeklyTaskGoal = 10,
    this.weeklyFocusGoalMinutes = 300,
    this.currencyMigrationVersion = 1,
    this.hasCompletedOnboarding = false,
  });

  final String currency;
  final double monthlyBudget;
  final String themeMode; // 'system', 'light', 'dark'
  final double usdToInrRate;
  final int weeklyTaskGoal;
  final int weeklyFocusGoalMinutes;
  final int currencyMigrationVersion;
  final bool hasCompletedOnboarding;

  AppSettings copyWith({
    String? currency,
    double? monthlyBudget,
    String? themeMode,
    double? usdToInrRate,
    int? weeklyTaskGoal,
    int? weeklyFocusGoalMinutes,
    int? currencyMigrationVersion,
    bool? hasCompletedOnboarding,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      themeMode: themeMode ?? this.themeMode,
      usdToInrRate: usdToInrRate ?? this.usdToInrRate,
      weeklyTaskGoal: weeklyTaskGoal ?? this.weeklyTaskGoal,
      weeklyFocusGoalMinutes:
          weeklyFocusGoalMinutes ?? this.weeklyFocusGoalMinutes,
      currencyMigrationVersion:
          currencyMigrationVersion ?? this.currencyMigrationVersion,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  Map<String, Object?> toJson() => {
    'currency': currency,
    'monthlyBudget': monthlyBudget,
    'themeMode': themeMode,
    'usdToInrRate': usdToInrRate,
    'weeklyTaskGoal': weeklyTaskGoal,
    'weeklyFocusGoalMinutes': weeklyFocusGoalMinutes,
    'currencyMigrationVersion': currencyMigrationVersion,
    'hasCompletedOnboarding': hasCompletedOnboarding,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final storedCurrency = json['currency'] as String?;
    return AppSettings(
      currency: storedCurrency ?? '₹',
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ?? 500.0,
      themeMode: json['themeMode'] as String? ?? 'system',
      usdToInrRate: (json['usdToInrRate'] as num?)?.toDouble() ?? 94.9432,
      weeklyTaskGoal: (json['weeklyTaskGoal'] as num?)?.toInt() ?? 10,
      weeklyFocusGoalMinutes:
          (json['weeklyFocusGoalMinutes'] as num?)?.toInt() ?? 300,
      currencyMigrationVersion:
          (json['currencyMigrationVersion'] as num?)?.toInt() ??
          (storedCurrency == '\$' ? 0 : 1),
      // Existing installs have settings but no onboarding flag; mark them as
      // onboarded so an app update does not interrupt their normal workflow.
      hasCompletedOnboarding: json.containsKey('hasCompletedOnboarding')
          ? json['hasCompletedOnboarding'] as bool? ?? false
          : true,
    );
  }
}

String _day(DateTime date) =>
    DateTime(date.year, date.month, date.day).toIso8601String();
