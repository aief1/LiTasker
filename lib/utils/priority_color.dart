import 'package:flutter/material.dart';
import '../models/task.dart';
import 'neo_brutalism.dart';

Color getPriorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return NeoBrutalism.pink;
    case TaskPriority.medium:
      return NeoBrutalism.yellow;
    case TaskPriority.low:
      return NeoBrutalism.cyan;
    case TaskPriority.none:
      return NeoBrutalism.muted;
  }
}
