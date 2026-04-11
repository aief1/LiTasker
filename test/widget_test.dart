// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:litasker/main.dart';
import 'package:litasker/models/task.dart';
import 'package:litasker/models/task_list.dart';

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('litasker_test');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskPriorityAdapter());
      Hive.registerAdapter(TaskAdapter());
      Hive.registerAdapter(TaskListAdapter());
    }
    if (!Hive.isBoxOpen('tasks')) {
      await Hive.openBox<Task>('tasks');
    }
    if (!Hive.isBoxOpen('taskLists')) {
      await Hive.openBox<TaskList>('taskLists');
    }
  });

  testWidgets('app shows splash branding', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('LITASKER'), findsOneWidget);
    expect(find.text('认真计划。漂亮完成。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
