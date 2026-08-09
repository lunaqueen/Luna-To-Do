import 'package:flutter_test/flutter_test.dart';
import 'package:luna_todo/models/app_settings.dart';
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

  test(
    'appearance settings preserve independent text color and transparency',
    () {
      const settings = AppSettings(
        opacity: 0.2,
        textColor: 0xff111827,
        transparentBackground: true,
      );
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.opacity, 0.2);
      expect(restored.textColor, 0xff111827);
      expect(restored.transparentBackground, isTrue);
    },
  );
}
