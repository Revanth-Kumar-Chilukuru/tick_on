import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5, defaultValue: false)
  bool isDeleted;

  @HiveField(6)
  DateTime? deletedAt;

  @HiveField(7, defaultValue: false)
  bool isRoutine;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  DateTime? reminderTime;

  @HiveField(10)
  List<DateTime> completionDates;

  Task({
    String? id,
    required this.title,
    this.description,
    DateTime? timestamp,
    this.isCompleted = false,
    this.isDeleted = false,
    this.deletedAt,
    this.isRoutine = false,
    this.completedAt,
    this.reminderTime,
    List<DateTime>? completionDates,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        completionDates = completionDates ?? [];

  bool get isPending => !isDeleted && !isCompleted && !isRoutine;
  bool get isActiveRoutine => !isDeleted && isRoutine;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? timestamp,
    bool? isCompleted,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? isRoutine,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? reminderTime,
    bool clearReminderTime = false,
    List<DateTime>? completionDates,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      isRoutine: isRoutine ?? this.isRoutine,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      reminderTime: clearReminderTime ? null : reminderTime ?? this.reminderTime,
      completionDates: completionDates ?? this.completionDates,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, description: $description, timestamp: $timestamp, isCompleted: $isCompleted, isDeleted: $isDeleted, deletedAt: $deletedAt, isRoutine: $isRoutine, completedAt: $completedAt, reminderTime: $reminderTime, completionDates: $completionDates)';
  }
}
