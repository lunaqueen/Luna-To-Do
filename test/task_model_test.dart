import 'package:flutter_test/flutter_test.dart';
import 'package:luna_todo/models/task.dart';

void main() {
  test('period key changes for a new daily period', () {
    expect(Recurrence.daily.periodKey(DateTime(2026, 8, 9)), '2026-8-9');
    expect(Recurrence.daily.periodKey(DateTime(2026, 8, 10)), '2026-8-10');
  });

  test('task serializes its desktop todo fields', () {
    final task = Task(
      id: 'a',
      title: '晨间规划',
      kind: TaskKind.fixed,
      recurrence: Recurrence.daily,
    );
    expect(Task.fromJson(task.toJson()).title, '晨间规划');
    expect(Task.fromJson(task.toJson()).recurrence, Recurrence.daily);
  });
}
