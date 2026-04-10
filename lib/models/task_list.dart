import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task_list.g.dart';

@HiveType(typeId: 2)
class TaskList {
  static const Map<int, IconData> _iconByCodePoint = {
    0xe6f4: Icons.work_outline,
    0xf33c: Icons.school_outlined,
    0xf107: Icons.home_outlined,
    0xf091: Icons.folder_outlined,
  };

  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconCodePoint;

  @HiveField(3)
  int colorValue;

  IconData get icon =>
      _iconByCodePoint[iconCodePoint] ?? Icons.folder_outlined;

  Color get color => Color(colorValue);

  TaskList(this.id, this.name, this.iconCodePoint, this.colorValue);

  factory TaskList.withIcon({
    required String id,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return TaskList(
      id,
      name,
      icon.codePoint,
      color.toARGB32(),
    );
  }

  TaskList copyWith({
    String? name,
    IconData? icon,
    Color? color,
  }) {
    return TaskList(
      id,
      name ?? this.name,
      icon?.codePoint ?? iconCodePoint,
      color?.toARGB32() ?? colorValue,
    );
  }
}
