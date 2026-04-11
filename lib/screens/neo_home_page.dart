import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../enums.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../utils/neo_brutalism.dart';

part 'neo_home_page_widgets.dart';
part 'neo_home_page_detail.dart';
part 'neo_home_page_calendar.dart';
part 'neo_home_page_misc.dart';

class NeoHomePage extends StatefulWidget {
  const NeoHomePage({super.key});

  @override
  State<NeoHomePage> createState() => _NeoHomePageState();
}

class _NeoHomePageState extends State<NeoHomePage> {
  late final Box<Task> _taskBox;
  late final Box<TaskList> _listBox;

  List<Task> _tasks = [];
  List<TaskList> _taskLists = [];
  String? _selectedTaskId;
  SmartView? _selectedSmartView = SmartView.today;
  String? _selectedListId;
  bool _showCompleted = false;
  ViewMode _viewMode = ViewMode.focus;
  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _calendarViewMode = CalendarViewMode.month;
  bool _fabPressed = false;
  DateTime _now = DateTime.now();
  Duration _focusRemaining = const Duration(minutes: 25);
  bool _focusRunning = false;
  bool _isBreakSession = false;
  int _completedFocusSessions = 0;
  Timer? _clockTimer;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<Task>('tasks');
    _listBox = Hive.box<TaskList>('taskLists');
    _loadData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _focusTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    _tasks = _taskBox.values.toList();
    _taskLists = _listBox.values.toList();
    if (_taskLists.isEmpty) {
      _taskLists = [
        TaskList.withIcon(
          id: 'work',
          name: 'Work',
          icon: Icons.work_outline,
          color: NeoBrutalism.cyan,
        ),
        TaskList.withIcon(
          id: 'study',
          name: 'Study',
          icon: Icons.school_outlined,
          color: NeoBrutalism.yellow,
        ),
        TaskList.withIcon(
          id: 'life',
          name: 'Life',
          icon: Icons.home_outlined,
          color: NeoBrutalism.pink,
        ),
      ];
      for (final list in _taskLists) {
        _listBox.put(list.id, list);
      }
    }
    setState(() {});
  }

  Task? get _selectedTask {
    for (final task in _tasks) {
      if (task.id == _selectedTaskId) return task;
    }
    return null;
  }

  Task? get _focusTask {
    if (_selectedTask != null && !_selectedTask!.isDone) return _selectedTask;
    final today = _tasks
        .where((task) => !task.isDone && _sameDate(task.date, DateTime.now()))
        .toList();
    if (today.isNotEmpty) return today.first;
    return _tasks.cast<Task?>().firstWhere(
          (task) => task != null && !task.isDone,
          orElse: () => null,
        );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDate(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Task> get _filteredTasks {
    final now = _dateOnly(DateTime.now());
    final end = now.add(const Duration(days: 7));
    final items = _tasks.where((task) {
      if (_showCompleted != task.isDone) return false;

      if (_selectedSmartView != null) {
        switch (_selectedSmartView!) {
          case SmartView.inbox:
            break;
          case SmartView.today:
            return _sameDate(task.date, DateTime.now());
          case SmartView.next7Days:
            if (task.date == null) return false;
            final date = _dateOnly(task.date!);
            return (date.isAtSameMomentAs(now) || date.isAfter(now)) &&
                (date.isAtSameMomentAs(end) || date.isBefore(end));
        }
      }

      if (_selectedListId != null) {
        return task.listId == _selectedListId;
      }
      return true;
    }).toList();

    items.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });
    return items;
  }

  int _countForSmartView(SmartView view) {
    return _tasks.where((task) {
      if (task.isDone) return false;
      switch (view) {
        case SmartView.inbox:
          return true;
        case SmartView.today:
          return _sameDate(task.date, DateTime.now());
        case SmartView.next7Days:
          if (task.date == null) return false;
          final now = _dateOnly(DateTime.now());
          final end = now.add(const Duration(days: 7));
          final date = _dateOnly(task.date!);
          return (date.isAtSameMomentAs(now) || date.isAfter(now)) &&
              (date.isAtSameMomentAs(end) || date.isBefore(end));
      }
    }).length;
  }

  int _countForList(String id) {
    return _tasks.where((task) => task.listId == id && !task.isDone).length;
  }

  void _selectSmartView(SmartView view) {
    setState(() {
      _selectedSmartView = view;
      _selectedListId = null;
      _showCompleted = false;
      _viewMode = ViewMode.list;
    });
  }

  void _selectList(String id) {
    setState(() {
      _selectedListId = id;
      _selectedSmartView = null;
      _showCompleted = false;
      _viewMode = ViewMode.list;
    });
  }

  void _toggleCompletedView() {
    setState(() {
      _showCompleted = !_showCompleted;
      if (_showCompleted) {
        _selectedSmartView = null;
        _selectedListId = null;
      } else {
        _selectedSmartView = SmartView.today;
      }
    });
  }

  void _addTask(String title, DateTime? date, TaskPriority priority,
      DateTime? endDate, String? listId) {
    final task = Task(
      title: title,
      date: date,
      endDate: endDate,
      priority: priority,
      listId: listId,
    );
    _taskBox.put(task.id, task);
    setState(() => _tasks = [..._tasks, task]);
  }

  void _updateTask(Task task) {
    _taskBox.put(task.id, task);
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    setState(() {
      _tasks[index] = task;
    });
  }

  void _toggleDone(String id) {
    final task = _tasks
        .cast<Task?>()
        .firstWhere((item) => item?.id == id, orElse: () => null);
    if (task == null) return;
    _updateTask(task.copyWith(isDone: !task.isDone));
    if (!_showCompleted && !task.isDone && _selectedTaskId == id) {
      setState(() => _selectedTaskId = null);
    }
  }

  void _moveTaskTo(String taskId, String? listId) {
    final task = _tasks
        .cast<Task?>()
        .firstWhere((item) => item?.id == taskId, orElse: () => null);
    if (task == null) return;
    _updateTask(task.copyWith(listId: listId));
  }

  void _deleteTask(String taskId) {
    _taskBox.delete(taskId);
    setState(() {
      _tasks.removeWhere((task) => task.id == taskId);
      if (_selectedTaskId == taskId) _selectedTaskId = null;
    });
  }

  void _toggleFocusTimer() {
    if (_focusRunning) {
      _focusTimer?.cancel();
      setState(() => _focusRunning = false);
      return;
    }

    setState(() => _focusRunning = true);
    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_focusRemaining <= const Duration(seconds: 1)) {
        setState(() {
          if (!_isBreakSession) _completedFocusSessions += 1;
          _isBreakSession = !_isBreakSession;
          _focusRemaining = _isBreakSession
              ? const Duration(minutes: 5)
              : const Duration(minutes: 25);
          _focusRunning = false;
        });
        _focusTimer?.cancel();
        return;
      }
      setState(() => _focusRemaining -= const Duration(seconds: 1));
    });
  }

  void _endFocusSession() {
    _focusTimer?.cancel();
    setState(() {
      _focusRunning = false;
      _isBreakSession = false;
      _focusRemaining = const Duration(minutes: 25);
    });
  }

  Future<void> _exportData() async {
    final file = await FilePicker.platform.saveFile(
      dialogTitle: 'Export backup',
      fileName: 'litasker_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return;

    final payload = {
      'tasks': _tasks.map((task) => task.toJson()).toList(),
      'lists': _taskLists
          .map((list) => {
                'id': list.id,
                'name': list.name,
                'iconCodePoint': list.iconCodePoint,
                'colorValue': list.colorValue,
              })
          .toList(),
    };

    await File(file).writeAsString(jsonEncode(payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Backup exported')));
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    String content = '';
    if (picked.path != null) {
      content = await File(picked.path!).readAsString();
    } else if (picked.bytes != null) {
      content = utf8.decode(picked.bytes!);
    }
    if (content.isEmpty) return;

    final data = jsonDecode(content) as Map<String, dynamic>;
    await _taskBox.clear();
    await _listBox.clear();

    for (final item in (data['lists'] as List? ?? [])) {
      final raw = item as Map<String, dynamic>;
      final list = TaskList(
        raw['id'] as String,
        raw['name'] as String,
        raw['iconCodePoint'] as int,
        raw['colorValue'] as int,
      );
      _listBox.put(list.id, list);
    }

    for (final item in (data['tasks'] as List? ?? [])) {
      final task = Task.fromJson(item as Map<String, dynamic>);
      _taskBox.put(task.id, task);
    }

    _loadData();
  }

  Future<void> _showQuickAdd() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _QuickAddSheet(
          currentListId: _selectedListId,
          allLists: _taskLists,
          onAdd: _addTask,
        );
      },
    );
  }

  Future<void> _openTaskDetails(Task task, {required bool isMobile}) async {
    setState(() => _selectedTaskId = task.id);
    if (!isMobile) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: Container(
              decoration: const BoxDecoration(
                color: NeoBrutalism.background,
                border: Border(
                  top: BorderSide(color: NeoBrutalism.ink, width: 2),
                  left: BorderSide(color: NeoBrutalism.ink, width: 2),
                  right: BorderSide(color: NeoBrutalism.ink, width: 2),
                ),
              ),
              child: _DetailPanel(
                task: _tasks.firstWhere((item) => item.id == task.id),
                taskLists: _taskLists,
                onTitleChanged: (value) {
                  final current =
                      _tasks.firstWhere((item) => item.id == task.id);
                  _updateTask(current.copyWith(title: value));
                },
                onDescriptionChanged: (value) {
                  final current =
                      _tasks.firstWhere((item) => item.id == task.id);
                  _updateTask(current.copyWith(description: value));
                },
                onListChanged: (value) => _moveTaskTo(task.id, value),
              ),
            ),
          ),
        );
      },
    );
  }

  String _headerTitle() {
    if (_viewMode == ViewMode.focus) return 'Focus';
    if (_viewMode == ViewMode.calendar) return 'Calendar';
    if (_showCompleted) return 'Completed';
    if (_selectedListId != null) {
      return _taskLists.firstWhere((list) => list.id == _selectedListId).name;
    }
    switch (_selectedSmartView) {
      case SmartView.inbox:
        return 'Inbox';
      case SmartView.today:
        return 'Today';
      case SmartView.next7Days:
        return 'Next 7 Days';
      case null:
        return 'Tasks';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 720;
    final isDesktop = width > 1100;
    final title = _headerTitle();
    final headerActionLabel = switch (_viewMode) {
      ViewMode.focus => 'TASKS',
      ViewMode.list => 'CALENDAR',
      ViewMode.calendar => 'LIST',
    };

    return Scaffold(
      drawer: isMobile
          ? Drawer(
              backgroundColor: NeoBrutalism.background,
              child: _SidebarPanel(
                selectedSmartView: _selectedSmartView,
                selectedListId: _selectedListId,
                showCompleted: _showCompleted,
                taskLists: _taskLists,
                countInbox: _countForSmartView(SmartView.inbox),
                countToday: _countForSmartView(SmartView.today),
                countNext7: _countForSmartView(SmartView.next7Days),
                completedCount: _tasks.where((task) => task.isDone).length,
                listCountBuilder: _countForList,
                onSmartViewSelected: _selectSmartView,
                onListSelected: _selectList,
                onCompletedSelected: _toggleCompletedView,
                onExport: _exportData,
                onImport: _importData,
              ),
            )
          : null,
      backgroundColor: NeoBrutalism.background,
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (context) => _HeaderBar(
                title: title,
                isMobile: isMobile,
                onMenuPressed:
                    isMobile ? () => Scaffold.of(context).openDrawer() : null,
                onSwitchView: () {
                  setState(() {
                    _viewMode = switch (_viewMode) {
                      ViewMode.focus => ViewMode.list,
                      ViewMode.list => ViewMode.calendar,
                      ViewMode.calendar => ViewMode.list,
                    };
                  });
                },
                isCalendar: _viewMode == ViewMode.calendar,
                actionLabel: headerActionLabel,
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile)
                    SizedBox(
                      width: 284,
                      child: _SidebarPanel(
                        selectedSmartView: _selectedSmartView,
                        selectedListId: _selectedListId,
                        showCompleted: _showCompleted,
                        taskLists: _taskLists,
                        countInbox: _countForSmartView(SmartView.inbox),
                        countToday: _countForSmartView(SmartView.today),
                        countNext7: _countForSmartView(SmartView.next7Days),
                        completedCount:
                            _tasks.where((task) => task.isDone).length,
                        listCountBuilder: _countForList,
                        onSmartViewSelected: _selectSmartView,
                        onListSelected: _selectList,
                        onCompletedSelected: _toggleCompletedView,
                        onExport: _exportData,
                        onImport: _importData,
                      ),
                    ),
                  if (!isMobile) Container(width: 2, color: NeoBrutalism.ink),
                  Expanded(
                    child: _viewMode == ViewMode.focus
                        ? _FocusPanel(
                            now: _now,
                            remaining: _focusRemaining,
                            isRunning: _focusRunning,
                            isBreakSession: _isBreakSession,
                            completedSessions: _completedFocusSessions,
                            currentTask: _focusTask,
                            onToggleTimer: _toggleFocusTimer,
                            onEndSession: _endFocusSession,
                            onOpenTasks: () =>
                                setState(() => _viewMode = ViewMode.list),
                          )
                        : _viewMode == ViewMode.list
                            ? _TaskColumn(
                                title: title,
                                tasks: _filteredTasks,
                                taskLists: _taskLists,
                                selectedTaskId: _selectedTaskId,
                                isMobile: isMobile,
                                onSelectTask: (id) {
                                  final task = _tasks
                                      .firstWhere((item) => item.id == id);
                                  _openTaskDetails(task, isMobile: isMobile);
                                },
                                onToggleDone: _toggleDone,
                                onMoveTask: _moveTaskTo,
                                onDeleteTask: _deleteTask,
                              )
                            : _CalendarPanel(
                                selectedDate: _selectedDate,
                                tasks: _tasks,
                                mode: _calendarViewMode,
                                isMobile: isMobile,
                                onModeChanged: (mode) =>
                                    setState(() => _calendarViewMode = mode),
                                onDateSelected: (date) =>
                                    setState(() => _selectedDate = date),
                                onTaskSelected: (id) {
                                  final task = _tasks
                                      .firstWhere((item) => item.id == id);
                                  if (isMobile) {
                                    _openTaskDetails(task, isMobile: true);
                                  } else {
                                    setState(() {
                                      _selectedTaskId = id;
                                      _viewMode = ViewMode.list;
                                    });
                                  }
                                },
                              ),
                  ),
                  if (isDesktop &&
                      _viewMode == ViewMode.list &&
                      _selectedTask != null) ...[
                    Container(width: 2, color: NeoBrutalism.ink),
                    SizedBox(
                      width: 380,
                      child: _DetailPanel(
                        task: _selectedTask!,
                        taskLists: _taskLists,
                        onTitleChanged: (value) =>
                            _updateTask(_selectedTask!.copyWith(title: value)),
                        onDescriptionChanged: (value) => _updateTask(
                            _selectedTask!.copyWith(description: value)),
                        onListChanged: (value) =>
                            _moveTaskTo(_selectedTask!.id, value),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _viewMode == ViewMode.list
          ? GestureDetector(
              onTapDown: (_) => setState(() => _fabPressed = true),
              onTapCancel: () => setState(() => _fabPressed = false),
              onTapUp: (_) async {
                setState(() => _fabPressed = false);
                await _showQuickAdd();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                transform: Matrix4.translationValues(
                    _fabPressed ? 4 : 0, _fabPressed ? 4 : 0, 0),
                width: 74,
                height: 74,
                decoration: _fabPressed
                    ? NeoBrutalism.flatCard(color: NeoBrutalism.green)
                    : NeoBrutalism.card(color: NeoBrutalism.green),
                child: const Icon(Icons.add, size: 36, color: NeoBrutalism.ink),
              ),
            )
          : null,
      bottomNavigationBar: isMobile
          ? _BottomNav(
              currentView: _viewMode,
              onChange: (mode) => setState(() => _viewMode = mode),
            )
          : null,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
