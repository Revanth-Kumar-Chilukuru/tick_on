import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  static const String _boxName = 'tasks';
  Box<Task>? _taskBox;
  List<Task> _tasks = [];

  Box<Task> get _box {
    final box = _taskBox;
    if (box == null) {
      throw StateError('TaskProvider must be initialized before use.');
    }
    return box;
  }

  List<Task> get tasks =>
      List.unmodifiable(_tasks.where((task) => !task.isDeleted));
  List<Task> get completedTasks =>
      _tasks.where((task) => !task.isDeleted && task.isCompleted && !task.isActiveRoutine).toList();
  List<Task> get deletedTasks => _tasks.where((task) => task.isDeleted).toList()
    ..sort((a, b) {
      final left = a.deletedAt ?? a.timestamp;
      final right = b.deletedAt ?? b.timestamp;
      return right.compareTo(left);
    });
  List<Task> get pendingTasks =>
      _tasks.where((task) => task.isPending).toList();
  List<Task> get routineTasks =>
      _tasks.where((task) => task.isActiveRoutine).toList();

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    _taskBox = await Hive.openBox<Task>(_boxName);
    _tasks = _box.values.toList();
    await _resetExpiredRoutines();
    _loadTasks();
  }

  void _loadTasks() {
    _tasks = _box.values.toList();
    _sortTasks();
    notifyListeners();
  }

  void _sortTasks() {
    _tasks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addTask(Task task) async {
    await _box.add(task);
    _tasks.insert(0, task);
    _sortTasks();
    if (task.reminderTime != null) {
      await NotificationService().scheduleTaskReminder(task);
    }
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final key = _tasks[index].key;
      if (key != null) {
        await _box.put(key, task);
      } else {
        await _box.add(task);
      }
      _tasks[index] = task;
      
      if (task.isCompleted || task.isDeleted) {
        await NotificationService().cancelTaskReminder(task.id);
      } else if (task.reminderTime != null) {
        await NotificationService().scheduleTaskReminder(task);
      }

      _sortTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      await updateTask(task);
    }
  }

  Future<void> toggleTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final currentTask = _tasks[index];
      if (currentTask.isDeleted) {
        return;
      }

      final willComplete = !currentTask.isCompleted;
      final newCompletionDates = List<DateTime>.from(currentTask.completionDates);
      
      if (currentTask.isActiveRoutine) {
        if (willComplete) {
          newCompletionDates.add(DateTime.now());
        } else if (newCompletionDates.isNotEmpty) {
          newCompletionDates.removeLast();
        }
      }

      final task = currentTask.copyWith(
        isCompleted: willComplete,
        completedAt: willComplete ? DateTime.now() : null,
        clearCompletedAt: !willComplete,
        completionDates: newCompletionDates,
      );
      await updateTask(task);
    }
  }

  Future<void> clearCompletedTasks() async {
    final completedTasksList =
        _tasks.where((task) => !task.isDeleted && task.isCompleted && !task.isActiveRoutine).toList();
    for (final task in completedTasksList) {
      await permanentlyDeleteTask(task.id);
    }
  }

  Future<void> restoreTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index].copyWith(
        isDeleted: false,
        clearDeletedAt: true,
      );
      await updateTask(task);
    }
  }

  Future<void> permanentlyDeleteTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final key = _tasks[index].key;
      if (key != null) {
        await _box.delete(key);
      }
      _tasks.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> clearDeletedTasks() async {
    final deletedTasks = _tasks.where((task) => task.isDeleted).toList();
    for (final task in deletedTasks) {
      await permanentlyDeleteTask(task.id);
    }
  }

  Future<void> _resetExpiredRoutines() async {
    var changed = false;
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final dayStartsAtHour = prefs.getInt('day_starts_at_hour') ?? 0;

    for (var index = 0; index < _tasks.length; index++) {
      final task = _tasks[index];
      final completedAt = task.completedAt;
      if (!task.isActiveRoutine || !task.isCompleted) {
        continue;
      }

      if (completedAt == null || !_isSameLogicalDay(completedAt, now, dayStartsAtHour)) {
        final resetTask = task.copyWith(
          isCompleted: false,
          clearCompletedAt: true,
        );
        final key = task.key;
        if (key != null) {
          await _box.put(key, resetTask);
        }
        _tasks[index] = resetTask;
        changed = true;
      }
    }

    if (changed) {
      _sortTasks();
    }
  }

  DateTime _getLogicalDate(DateTime dt, int dayStartsAtHour) {
    if (dt.hour < dayStartsAtHour) {
      return dt.subtract(const Duration(days: 1));
    }
    return dt;
  }

  bool _isSameLogicalDay(DateTime left, DateTime right, int dayStartsAtHour) {
    final l = _getLogicalDate(left, dayStartsAtHour);
    final r = _getLogicalDate(right, dayStartsAtHour);
    return l.year == r.year &&
        l.month == r.month &&
        l.day == r.day;
  }

  @override
  void dispose() {
    _taskBox?.close();
    _taskBox = null;
    super.dispose();
  }
}
