import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskPriority {
  @HiveField(0)
  none,
  @HiveField(1)
  low,
  @HiveField(2)
  medium,
  @HiveField(3)
  high
}

@HiveType(typeId: 1)
class Task {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime? date;

  @HiveField(4)
  final DateTime? endDate;

  @HiveField(5)
  final bool isDone;

  @HiveField(6)
  final TaskPriority priority;

  @HiveField(7)
  final String? listId;

  @HiveField(8)
  final String? groupId;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.date,
    this.endDate,
    this.isDone = false,
    this.priority = TaskPriority.none,
    this.listId,
    this.groupId,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // 用于 Hive 的构造（位置参数）
  Task._internal(
      this.id,
      this.title,
      this.description,
      this.date,
      this.endDate,
      this.isDone,
      this.priority,
      this.listId,
      this.groupId,
      );

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task._internal(
      json['id'],
      json['title'],
      json['description'] ?? '',
      json['date'] != null ? DateTime.parse(json['date']) : null,
      json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      json['isDone'] ?? false,
      TaskPriority.values[json['priority'] ?? 0],
      json['listId'],
      json['groupId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'isDone': isDone,
    'priority': priority.index,
    'listId': listId,
    'groupId': groupId,
  };

  Task copyWith({
    String? title,
    String? description,
    DateTime? date,
    DateTime? endDate,
    bool? isDone,
    TaskPriority? priority,
    String? listId,
    String? groupId,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      listId: listId ?? this.listId,
      groupId: groupId ?? this.groupId,
    );
  }
}