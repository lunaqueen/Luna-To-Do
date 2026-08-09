enum TaskKind { fixed, temporary }

enum Recurrence { daily, weekly, monthly, yearly }

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.kind,
    this.recurrence,
    this.deadline,
    this.completed = false,
    this.completedAt,
    this.periodKey,
    this.createdAt,
  });

  final String id;
  final String title;
  final TaskKind kind;
  final Recurrence? recurrence;
  final DateTime? deadline;
  final bool completed;
  final DateTime? completedAt;
  final String? periodKey;
  final DateTime? createdAt;

  Task copyWith({bool? completed, DateTime? completedAt, String? periodKey}) =>
      Task(
        id: id,
        title: title,
        kind: kind,
        recurrence: recurrence,
        deadline: deadline,
        completed: completed ?? this.completed,
        completedAt: completedAt ?? this.completedAt,
        periodKey: periodKey ?? this.periodKey,
        createdAt: createdAt,
      );

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    kind:
        (json['kind'] ?? (json['fixed'] == true ? 'fixed' : 'temporary')) ==
            'fixed'
        ? TaskKind.fixed
        : TaskKind.temporary,
    recurrence: _recurrenceFrom(json['recurrence']),
    deadline: _dateFrom(json['deadline']),
    completed: json['completed'] as bool? ?? false,
    completedAt: _dateFrom(json['completedAt']),
    periodKey: json['periodKey'] as String?,
    createdAt: _dateFrom(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'recurrence': recurrence?.name,
    'deadline': deadline?.toIso8601String(),
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
    'periodKey': periodKey,
    'createdAt': createdAt?.toIso8601String(),
  };

  static DateTime? _dateFrom(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Recurrence? _recurrenceFrom(Object? value) {
    if (value is! String) return null;
    return Recurrence.values.where((item) => item.name == value).firstOrNull;
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension RecurrenceLabel on Recurrence {
  String get label => switch (this) {
    Recurrence.daily => '每天',
    Recurrence.weekly => '每周',
    Recurrence.monthly => '每月',
    Recurrence.yearly => '每年',
  };

  String periodKey(DateTime date) {
    final local = date.toLocal();
    return switch (this) {
      Recurrence.daily => '${local.year}-${local.month}-${local.day}',
      Recurrence.weekly => '${local.year}-W${_weekNumber(local)}',
      Recurrence.monthly => '${local.year}-${local.month}',
      Recurrence.yearly => '${local.year}',
    };
  }

  static int _weekNumber(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    return ((date.difference(firstDay).inDays + firstDay.weekday - 1) / 7)
            .floor() +
        1;
  }
}
