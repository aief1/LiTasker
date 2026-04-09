import 'package:flutter/material.dart';
import '../models/task.dart';

Color getPriorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return Colors.red;
    case TaskPriority.medium:
      return Colors.orange;
    case TaskPriority.low:
      return Colors.green;
    case TaskPriority.none:
    default:
      return Colors.grey;
  }
}