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
  static const _focusTotalSecondsKey = 'focus_total_seconds';
  static const _focusCompletedSessionsKey = 'focus_completed_sessions';
  static const _focusUnassignedListKey = 'focus_list_unassigned';

  late final Box<Task> _taskBox;
  late final Box<TaskList> _listBox;
  late final Box _settingsBox;

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
  Duration _focusElapsed = Duration.zero;
  Duration _pomodoroRemaining = const Duration(minutes: 25);
  bool _focusRunning = false;
  bool _usePomodoro = false;
  FocusTab _focusTab = FocusTab.time;
  int _completedFocusSessions = 0;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<Task>('tasks');
    _listBox = Hive.box<TaskList>('taskLists');
    _settingsBox = Hive.box('settings');
    _loadData();
  }

  @override
  void dispose() {
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
    _completedFocusSessions = _readSettingInt(_focusCompletedSessionsKey);
    setState(() {});
  }

  Task? get _selectedTask {
    for (final task in _tasks) {
      if (task.id == _selectedTaskId) return task;
    }
    return null;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDate(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _focusDayKey(DateTime value) {
    final date = _dateOnly(value);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'focus_day_${date.year}-$month-$day';
  }

  String _focusListKey(String? listId) {
    if (listId == null || listId.isEmpty) return _focusUnassignedListKey;
    return 'focus_list_$listId';
  }

  int _readSettingInt(String key) {
    final value = _settingsBox.get(key, defaultValue: 0);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  void _writeSettingInt(String key, int value) {
    unawaited(_settingsBox.put(key, value));
  }

  void _recordFocusSecond() {
    final todayKey = _focusDayKey(DateTime.now());
    final taskListId = _selectedTask?.listId ?? _selectedListId;
    _writeSettingInt(
      _focusTotalSecondsKey,
      _readSettingInt(_focusTotalSecondsKey) + 1,
    );
    _writeSettingInt(todayKey, _readSettingInt(todayKey) + 1);
    final listKey = _focusListKey(taskListId);
    _writeSettingInt(listKey, _readSettingInt(listKey) + 1);
  }

  void _recordFocusSession() {
    _completedFocusSessions += 1;
    _writeSettingInt(_focusCompletedSessionsKey, _completedFocusSessions);
  }

  List<int> get _focusLast7DaySeconds {
    final today = _dateOnly(DateTime.now());
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return _readSettingInt(_focusDayKey(date));
    });
  }

  List<int> get _focusAllDaySeconds {
    final dayEntries = <MapEntry<String, int>>[];
    for (final entry in _settingsBox.toMap().entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || !key.startsWith('focus_day_') || value is! num) {
        continue;
      }
      dayEntries.add(MapEntry(key, value.toInt()));
    }
    dayEntries.sort((a, b) => a.key.compareTo(b.key));
    return dayEntries.map((entry) => entry.value).toList();
  }

  String get _focusStatsRangeLabel {
    final dayKeys = _settingsBox.keys
        .whereType<String>()
        .where((key) => key.startsWith('focus_day_'))
        .toList()
      ..sort();
    if (dayKeys.isEmpty) return 'NO DATA YET';
    return '${dayKeys.first.substring(10)} ~ ${dayKeys.last.substring(10)}';
  }

  List<_FocusDistributionItem> get _focusDistributionItems {
    final items = _taskLists.map((list) {
      return _FocusDistributionItem(
        label: list.name,
        seconds: _readSettingInt(_focusListKey(list.id)),
        color: list.color,
      );
    }).toList();

    final assignedSeconds = items.fold<int>(
      0,
      (total, item) => total + item.seconds,
    );
    final unassignedSeconds = _readSettingInt(_focusUnassignedListKey);
    final unknownSeconds =
        (_focusTotalSeconds - assignedSeconds - unassignedSeconds)
            .clamp(0, _focusTotalSeconds)
            .toInt();
    final otherSeconds = unassignedSeconds + unknownSeconds;
    if (otherSeconds > 0) {
      items.add(
        const _FocusDistributionItem(
          label: 'Focus',
          seconds: 0,
          color: NeoBrutalism.muted,
        ).copyWith(seconds: otherSeconds),
      );
    }

    return items.where((item) => item.seconds > 0).toList();
  }

  int get _focusTodaySeconds => _readSettingInt(_focusDayKey(DateTime.now()));

  int get _focusTotalSeconds => _readSettingInt(_focusTotalSecondsKey);

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
    if (_focusRunning) return;

    setState(() => _focusRunning = true);
    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_usePomodoro) {
        if (_pomodoroRemaining <= const Duration(seconds: 1)) {
          setState(() {
            _recordFocusSecond();
            _recordFocusSession();
            _focusRunning = false;
            _pomodoroRemaining = const Duration(minutes: 25);
          });
          _focusTimer?.cancel();
          return;
        }
        setState(() {
          _recordFocusSecond();
          _pomodoroRemaining -= const Duration(seconds: 1);
        });
        return;
      }

      setState(() {
        _recordFocusSecond();
        _focusElapsed += const Duration(seconds: 1);
      });
    });
  }

  void _changeFocusTab(FocusTab tab) {
    if (_focusRunning && tab != FocusTab.stats && tab != _focusTab) return;
    setState(() {
      _focusTab = tab;
      if (!_focusRunning && tab != FocusTab.stats) {
        _usePomodoro = tab == FocusTab.pomo;
        _focusElapsed = Duration.zero;
        _pomodoroRemaining = const Duration(minutes: 25);
      }
    });
  }

  void _endFocusSession() {
    final hadProgress = _usePomodoro
        ? _pomodoroRemaining < const Duration(minutes: 25)
        : _focusElapsed > Duration.zero;
    _focusTimer?.cancel();
    setState(() {
      if (hadProgress) _recordFocusSession();
      _focusRunning = false;
      _focusElapsed = Duration.zero;
      _pomodoroRemaining = const Duration(minutes: 25);
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
      'focusStats': Map<String, int>.fromEntries(
        _settingsBox.toMap().entries.where((entry) {
          return entry.key is String &&
              (entry.key as String).startsWith('focus_') &&
              entry.value is num;
        }).map((entry) {
          return MapEntry(entry.key as String, (entry.value as num).toInt());
        }),
      ),
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

    final focusStats = data['focusStats'];
    if (focusStats is Map<String, dynamic>) {
      final focusKeys = _settingsBox.keys
          .where((key) => key is String && key.startsWith('focus_'))
          .toList();
      for (final key in focusKeys) {
        await _settingsBox.delete(key);
      }
      for (final entry in focusStats.entries) {
        final value = entry.value;
        if (value is num) await _settingsBox.put(entry.key, value.toInt());
      }
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
    final focusLast7DaySeconds = _focusLast7DaySeconds;
    final focusAllDaySeconds = _focusAllDaySeconds;
    final focusWeekSeconds = focusLast7DaySeconds.fold<int>(
      0,
      (total, seconds) => total + seconds,
    );
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
                            displayTime: _usePomodoro
                                ? _pomodoroRemaining
                                : _focusElapsed,
                            isRunning: _focusRunning,
                            usePomodoro: _usePomodoro,
                            selectedTab: _focusTab,
                            completedSessions: _completedFocusSessions,
                            totalFocusSeconds: _focusTotalSeconds,
                            todayFocusSeconds: _focusTodaySeconds,
                            weekFocusSeconds: focusWeekSeconds,
                            allDaySeconds: focusAllDaySeconds,
                            statsRangeLabel: _focusStatsRangeLabel,
                            distributionItems: _focusDistributionItems,
                            onToggleTimer: _toggleFocusTimer,
                            onEndSession: _endFocusSession,
                            onTabChanged: _changeFocusTab,
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
