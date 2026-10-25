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
  });

  final String id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final int priority;
  final bool isDone;
  final DateTime? completedAt;
  final bool reminderEnabled;

  HubTask copyWith({
    bool? isDone,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? reminderEnabled,
  }) {
    return HubTask(
      id: id,
      title: title,
      subject: subject,
      dueDate: dueDate,
      priority: priority,
      isDone: isDone ?? this.isDone,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
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
  );
}

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'date': _day(date),
  };

  factory ExpenseEntry.fromJson(Map<String, Object?> json) => ExpenseEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String? ?? 'Other',
    date: DateTime.parse(json['date'] as String),
  );
}

class PantryEntry {
  const PantryEntry({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiryDate,
    this.reminderEnabled = false,
  });

  final String id;
  final String name;
  final String quantity;
  final DateTime expiryDate;
  final bool reminderEnabled;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'expiryDate': _day(expiryDate),
    'reminderEnabled': reminderEnabled,
  };

  factory PantryEntry.fromJson(Map<String, Object?> json) => PantryEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] as String? ?? '',
    expiryDate: DateTime.parse(json['expiryDate'] as String),
    reminderEnabled: json['reminderEnabled'] as bool? ?? false,
  );
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.minutes,
    required this.date,
  });

  final String id;
  final int minutes;
  final DateTime date;

  Map<String, Object?> toJson() => {
    'id': id,
    'minutes': minutes,
    'date': _day(date),
  };

  factory FocusSession.fromJson(Map<String, Object?> json) => FocusSession(
    id: json['id'] as String,
    minutes: json['minutes'] as int,
    date: DateTime.parse(json['date'] as String),
  );
}

String _day(DateTime date) =>
    DateTime(date.year, date.month, date.day).toIso8601String();
