import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/task.dart';
import 'storage.dart';

class TaskService extends ChangeNotifier {
  TaskService(this._storage);
  final StorageService _storage;
  List<Task> _fixedTasks = [];
  List<Task> _temporaryTasks = [];
  AppSettings _settings = const AppSettings();
  bool isLoading = true;

  List<Task> get fixedTasks => List.unmodifiable(_fixedTasks);
  List<Task> get temporaryTasks => List.unmodifiable(_temporaryTasks);
  AppSettings get settings => _settings;
  int get fixedCompleted => _fixedTasks.where((task) => task.completed).length;

  Future<void> load() async {
    final data = await _storage.load();
    _fixedTasks = _tasksFrom(data['fixedTasks']);
    _temporaryTasks = _tasksFrom(data['temporaryTasks']);
    _settings = AppSettings.fromJson(data['settings'] as Map<String, dynamic>?);
    _refreshFixedStatus();
    isLoading = false;
    await _save();
    notifyListeners();
  }

  List<Task> _tasksFrom(Object? raw) => raw is List
      ? raw
            .whereType<Map>()
            .map((item) => Task.fromJson(Map<String, dynamic>.from(item)))
            .toList()
      : [];

  Future<void> addFixed(String title, Recurrence recurrence) async {
    _fixedTasks.add(
      Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.trim(),
        kind: TaskKind.fixed,
        recurrence: recurrence,
        periodKey: recurrence.periodKey(DateTime.now()),
        createdAt: DateTime.now(),
      ),
    );
    await _changed();
  }

  Future<void> addTemporary(String title, DateTime deadline) async {
    _temporaryTasks.add(
      Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.trim(),
        kind: TaskKind.temporary,
        deadline: deadline,
        createdAt: DateTime.now(),
      ),
    );
    await _changed();
  }

  Future<void> toggleFixed(Task task) async {
    final index = _fixedTasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    final checked = !_fixedTasks[index].completed;
    _fixedTasks[index] = _fixedTasks[index].copyWith(
      completed: checked,
      completedAt: checked ? DateTime.now() : null,
      periodKey: task.recurrence?.periodKey(DateTime.now()),
    );
    await _changed();
  }

  Future<void> completeTemporary(Task task) async {
    _temporaryTasks.removeWhere((item) => item.id == task.id);
    await _changed();
  }

  Future<void> deleteTask(Task task) async {
    (task.kind == TaskKind.fixed ? _fixedTasks : _temporaryTasks).removeWhere(
      (item) => item.id == task.id,
    );
    await _changed();
  }

  Future<void> updateSettings(AppSettings value) async {
    _settings = value;
    await _changed();
  }

  void _refreshFixedStatus() {
    final now = DateTime.now();
    _fixedTasks = _fixedTasks.map((task) {
      final currentKey = task.recurrence?.periodKey(now);
      return currentKey != null && task.periodKey != currentKey
          ? task.copyWith(
              completed: false,
              completedAt: null,
              periodKey: currentKey,
            )
          : task;
    }).toList();
  }

  Future<void> _changed() async {
    await _save();
    notifyListeners();
  }

  Future<void> _save() => _storage.save({
    'version': 1,
    'fixedTasks': _fixedTasks.map((task) => task.toJson()).toList(),
    'temporaryTasks': _temporaryTasks.map((task) => task.toJson()).toList(),
    'settings': _settings.toJson(),
  });
}
