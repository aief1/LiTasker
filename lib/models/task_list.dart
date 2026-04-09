import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'task_list.g.dart';

@HiveType(typeId: 2)
class TaskList {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconCodePoint;

  @HiveField(3)
  int colorValue;

  // 在构造函数中初始化的 final 字段，避免动态创建
  late final IconData _icon;

  IconData get icon => _icon;
  Color get color => Color(colorValue);

  // 供 Hive 使用的构造函数（从存储读取后调用）
  TaskList(this.id, this.name, this.iconCodePoint, this.colorValue) {
    _icon = IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  }

  // 便捷构造函数（供应用代码使用）
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
      color.value,
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
      color?.value ?? colorValue,
    );
  }
}