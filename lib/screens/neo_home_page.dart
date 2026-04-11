import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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
  static const _focusCurrentSubjectKey = 'focus_current_subject';
  static const _settingFocusDurationKey = 'setting_focus_duration_minutes';
  static const _settingShortBreakKey = 'setting_short_break_minutes';
  static const _settingLongBreakKey = 'setting_long_break_minutes';
  static const _settingLongBreakAfterKey = 'setting_long_break_after_sessions';
  static const _settingSoundEffectsKey = 'setting_sound_effects';
  static const _settingAutoStartBreakKey = 'setting_auto_start_break';
  static const _settingDailyGoalMinutesKey = 'setting_daily_goal_minutes';
  static const _settingDefaultStartPageKey = 'setting_default_start_page';
  static const _settingDefaultTaskDateTodayKey =
      'setting_default_task_date_today';
  static const _settingBackupReminderKey = 'setting_backup_reminder';
  static const _settingReduceMotionKey = 'setting_reduce_motion';
  static const _lastBackupAtKey = 'backup_last_exported_at';

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
  ViewMode _settingsReturnView = ViewMode.focus;
  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _calendarViewMode = CalendarViewMode.month;
  bool _fabPressed = false;
  Duration _focusElapsed = Duration.zero;
  Duration _pomodoroRemaining = const Duration(minutes: 25);
  bool _focusRunning = false;
  bool _usePomodoro = false;
  FocusTab _focusTab = FocusTab.time;
  FocusStatsRange _focusStatsRange = FocusStatsRange.week;
  DateTime _focusStatsAnchorDate = DateTime.now();
  String _focusSubject = '专注';
  int _focusDurationMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _longBreakAfterSessions = 4;
  bool _soundEffects = true;
  bool _autoStartBreak = false;
  int _dailyGoalMinutes = 120;
  DefaultStartPage _defaultStartPage = DefaultStartPage.focus;
  bool _defaultTaskDateToday = true;
  bool _backupReminder = true;
  bool _reduceMotion = false;
  String _taskSearchQuery = '';
  TaskSortMode _taskSortMode = TaskSortMode.date;
  String? _focusStatsSubjectFilter;
  int _completedFocusSessions = 0;
  Timer? _focusTimer;

  Duration get _pomodoroDuration => Duration(minutes: _focusDurationMinutes);

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
          name: '工作',
          icon: Icons.work_outline,
          color: NeoBrutalism.cyan,
        ),
        TaskList.withIcon(
          id: 'study',
          name: '学习',
          icon: Icons.school_outlined,
          color: NeoBrutalism.yellow,
        ),
        TaskList.withIcon(
          id: 'life',
          name: '生活',
          icon: Icons.home_outlined,
          color: NeoBrutalism.pink,
        ),
      ];
      for (final list in _taskLists) {
        _listBox.put(list.id, list);
      }
    }
    _completedFocusSessions = _readSettingInt(_focusCompletedSessionsKey);
    final savedSubject = _settingsBox.get(_focusCurrentSubjectKey);
    if (savedSubject is String && savedSubject.trim().isNotEmpty) {
      _focusSubject = savedSubject.trim();
    }
    _focusDurationMinutes = _readSettingInt(
      _settingFocusDurationKey,
      fallback: 25,
    );
    _shortBreakMinutes = _readSettingInt(_settingShortBreakKey, fallback: 5);
    _longBreakMinutes = _readSettingInt(_settingLongBreakKey, fallback: 15);
    _longBreakAfterSessions =
        _readSettingInt(_settingLongBreakAfterKey, fallback: 4);
    _soundEffects = _readSettingBool(_settingSoundEffectsKey, fallback: true);
    _autoStartBreak =
        _readSettingBool(_settingAutoStartBreakKey, fallback: false);
    _dailyGoalMinutes =
        _readSettingInt(_settingDailyGoalMinutesKey, fallback: 120);
    _defaultStartPage = _readSettingInt(_settingDefaultStartPageKey) == 1
        ? DefaultStartPage.tasks
        : DefaultStartPage.focus;
    _defaultTaskDateToday =
        _readSettingBool(_settingDefaultTaskDateTodayKey, fallback: true);
    _backupReminder =
        _readSettingBool(_settingBackupReminderKey, fallback: true);
    _reduceMotion = _readSettingBool(_settingReduceMotionKey, fallback: false);
    _viewMode = _defaultStartPage == DefaultStartPage.focus
        ? ViewMode.focus
        : ViewMode.list;
    _settingsReturnView = _viewMode;
    _pomodoroRemaining = _pomodoroDuration;
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

  String _focusSubjectKey(String subject) {
    return 'focus_subject_${Uri.encodeComponent(subject.trim())}';
  }

  String _focusSubjectDayKey(DateTime value, String subject) {
    return '${_focusDayKey(value)}_subject_${Uri.encodeComponent(subject.trim())}';
  }

  int _readSettingInt(String key, {int fallback = 0}) {
    final value = _settingsBox.get(key, defaultValue: fallback);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  bool _readSettingBool(String key, {required bool fallback}) {
    final value = _settingsBox.get(key, defaultValue: fallback);
    if (value is bool) return value;
    return fallback;
  }

  void _writeSettingInt(String key, int value) {
    unawaited(_settingsBox.put(key, value));
  }

  void _recordFocusSecond() {
    final todayKey = _focusDayKey(DateTime.now());
    final subject = _focusSubject.trim().isEmpty ? '专注' : _focusSubject.trim();
    final taskListId = _selectedTask?.listId ?? _selectedListId;
    _writeSettingInt(
      _focusTotalSecondsKey,
      _readSettingInt(_focusTotalSecondsKey) + 1,
    );
    _writeSettingInt(todayKey, _readSettingInt(todayKey) + 1);
    final subjectKey = _focusSubjectKey(subject);
    _writeSettingInt(subjectKey, _readSettingInt(subjectKey) + 1);
    final subjectDayKey = _focusSubjectDayKey(DateTime.now(), subject);
    _writeSettingInt(subjectDayKey, _readSettingInt(subjectDayKey) + 1);
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

  String get _focusStatsRangeLabel {
    final dates = _focusStatsDates;
    if (dates.isEmpty) return '暂无数据';
    final first = _formatDate(dates.first);
    final last = _formatDate(dates.last);
    if (_focusStatsRange == FocusStatsRange.day) return first;
    if (_focusStatsRange == FocusStatsRange.month) {
      final month = dates.last.month.toString().padLeft(2, '0');
      return '${dates.last.year}-$month';
    }
    return '$first ~ $last';
  }

  List<_FocusDistributionItem> get _focusDistributionItems {
    const palette = [
      NeoBrutalism.yellow,
      NeoBrutalism.cyan,
      NeoBrutalism.pink,
      NeoBrutalism.green,
      NeoBrutalism.muted,
    ];
    final dates = _focusStatsDates;
    final selectedSubject = _focusStatsSubjectFilter;
    if (selectedSubject != null) {
      final seconds = dates.fold<int>(
          0, (total, date) => total + _focusSecondsForDate(date));
      if (seconds == 0) return [];
      return [
        _FocusDistributionItem(
          label: selectedSubject,
          seconds: seconds,
          color: NeoBrutalism.yellow,
        ),
      ];
    }
    final totalsBySubject = <String, int>{};
    for (final entry in _settingsBox.toMap().entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String ||
          !key.contains('_subject_') ||
          value is! num ||
          !_statsRangeContainsSubjectKey(key, dates)) {
        continue;
      }
      final subject = Uri.decodeComponent(key.split('_subject_').last);
      totalsBySubject[subject] =
          (totalsBySubject[subject] ?? 0) + value.toInt();
    }
    final entries = totalsBySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final items = List.generate(entries.length, (index) {
      final entry = entries[index];
      return _FocusDistributionItem(
        label: entry.key,
        seconds: entry.value,
        color: palette[index % palette.length],
      );
    });

    final assignedSeconds = items.fold<int>(
      0,
      (total, item) => total + item.seconds,
    );
    final rangeTotalSeconds = _focusStatsChartSeconds.fold<int>(
      0,
      (total, seconds) => total + seconds,
    );
    final unknownSeconds = (rangeTotalSeconds - assignedSeconds)
        .clamp(0, rangeTotalSeconds)
        .toInt();
    if (unknownSeconds > 0) {
      items.add(
        const _FocusDistributionItem(
          label: '专注',
          seconds: 0,
          color: NeoBrutalism.muted,
        ).copyWith(seconds: unknownSeconds),
      );
    }

    return items.where((item) => item.seconds > 0).toList();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<DateTime> get _focusStatsDates {
    final anchor = _dateOnly(_focusStatsAnchorDate);
    switch (_focusStatsRange) {
      case FocusStatsRange.day:
        return [anchor];
      case FocusStatsRange.week:
        final weekStart = anchor.subtract(Duration(days: anchor.weekday - 1));
        return List.generate(7, (index) {
          return weekStart.add(Duration(days: index));
        });
      case FocusStatsRange.month:
        final daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day;
        return List.generate(daysInMonth, (index) {
          return DateTime(anchor.year, anchor.month, index + 1);
        });
    }
  }

  List<int> get _focusStatsChartSeconds {
    return _focusStatsDates.map((date) {
      return _focusSecondsForDate(date);
    }).toList();
  }

  bool _statsRangeContainsSubjectKey(String key, List<DateTime> dates) {
    return dates
        .any((date) => key.startsWith('${_focusDayKey(date)}_subject_'));
  }

  int get _focusTodaySeconds => _readSettingInt(_focusDayKey(DateTime.now()));

  int get _focusTotalSeconds => _readSettingInt(_focusTotalSecondsKey);

  int _focusSecondsForDate(DateTime date) {
    final subject = _focusStatsSubjectFilter;
    if (subject == null) return _readSettingInt(_focusDayKey(date));
    return _readSettingInt(_focusSubjectDayKey(date, subject));
  }

  int get _filteredFocusTotalSeconds {
    final subject = _focusStatsSubjectFilter;
    if (subject == null) return _focusTotalSeconds;
    return _readSettingInt(_focusSubjectKey(subject));
  }

  int get _filteredFocusTodaySeconds {
    final subject = _focusStatsSubjectFilter;
    if (subject == null) return _focusTodaySeconds;
    return _readSettingInt(_focusSubjectDayKey(DateTime.now(), subject));
  }

  List<String> get _focusSubjects {
    final subjects = <String>{};
    for (final key in _settingsBox.keys) {
      if (key is String && key.startsWith('focus_subject_')) {
        subjects
            .add(Uri.decodeComponent(key.substring('focus_subject_'.length)));
      }
    }
    final current = _focusSubject.trim();
    if (current.isNotEmpty) subjects.add(current);
    return subjects.toList()..sort();
  }

  int get _focusStreakDays {
    var streak = 0;
    var cursor = _dateOnly(DateTime.now());
    while (_focusSecondsForDate(cursor) > 0) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String get _backupHint {
    if (!_backupReminder) return '备份提醒已关闭';
    final raw = _settingsBox.get(_lastBackupAtKey);
    if (raw is! String) return '还没有备份，建议先导出一次';
    final date = DateTime.tryParse(raw);
    if (date == null) return '备份记录异常，建议重新导出';
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return '今天已备份';
    if (days >= 7) return '距离上次备份 $days 天，建议导出';
    return '上次备份 $days 天前';
  }

  void _updateFocusSubject(String value) {
    setState(() => _focusSubject = value);
    unawaited(_settingsBox.put(_focusCurrentSubjectKey, value));
  }

  void _changeFocusStatsRange(FocusStatsRange range) {
    setState(() {
      _focusStatsRange = range;
      _focusStatsAnchorDate = DateTime.now();
    });
  }

  void _changeFocusStatsSubject(String? subject) {
    setState(() => _focusStatsSubjectFilter = subject);
  }

  bool get _canGoNextFocusStatsRange {
    final today = _dateOnly(DateTime.now());
    final dates = _focusStatsDates;
    if (dates.isEmpty) return false;
    return dates.last.isBefore(today);
  }

  void _shiftFocusStatsRange(int direction) {
    if (direction > 0 && !_canGoNextFocusStatsRange) return;
    setState(() {
      _focusStatsAnchorDate = switch (_focusStatsRange) {
        FocusStatsRange.day =>
          _focusStatsAnchorDate.add(Duration(days: direction)),
        FocusStatsRange.week =>
          _focusStatsAnchorDate.add(Duration(days: direction * 7)),
        FocusStatsRange.month => DateTime(
            _focusStatsAnchorDate.year,
            _focusStatsAnchorDate.month + direction,
            1,
          ),
      };
    });
  }

  void _updateFocusDuration(int value) {
    final minutes = value.clamp(5, 120);
    setState(() {
      _focusDurationMinutes = minutes;
      if (!_focusRunning) _pomodoroRemaining = _pomodoroDuration;
    });
    _writeSettingInt(_settingFocusDurationKey, minutes);
  }

  void _updateShortBreak(int value) {
    final minutes = value.clamp(1, 60);
    setState(() => _shortBreakMinutes = minutes);
    _writeSettingInt(_settingShortBreakKey, minutes);
  }

  void _updateLongBreak(int value) {
    final minutes = value.clamp(1, 120);
    setState(() => _longBreakMinutes = minutes);
    _writeSettingInt(_settingLongBreakKey, minutes);
  }

  void _updateLongBreakAfter(int value) {
    final sessions = value.clamp(1, 12);
    setState(() => _longBreakAfterSessions = sessions);
    _writeSettingInt(_settingLongBreakAfterKey, sessions);
  }

  void _updateSoundEffects(bool value) {
    setState(() => _soundEffects = value);
    unawaited(_settingsBox.put(_settingSoundEffectsKey, value));
  }

  void _updateAutoStartBreak(bool value) {
    setState(() => _autoStartBreak = value);
    unawaited(_settingsBox.put(_settingAutoStartBreakKey, value));
  }

  void _updateDailyGoal(int value) {
    final minutes = value.clamp(15, 480);
    setState(() => _dailyGoalMinutes = minutes);
    _writeSettingInt(_settingDailyGoalMinutesKey, minutes);
  }

  void _updateDefaultStartPage(DefaultStartPage value) {
    setState(() => _defaultStartPage = value);
    _writeSettingInt(_settingDefaultStartPageKey, value.index);
  }

  void _updateDefaultTaskDateToday(bool value) {
    setState(() => _defaultTaskDateToday = value);
    unawaited(_settingsBox.put(_settingDefaultTaskDateTodayKey, value));
  }

  void _updateBackupReminder(bool value) {
    setState(() => _backupReminder = value);
    unawaited(_settingsBox.put(_settingBackupReminderKey, value));
  }

  void _updateReduceMotion(bool value) {
    setState(() => _reduceMotion = value);
    unawaited(_settingsBox.put(_settingReduceMotionKey, value));
  }

  void _openSettings() {
    if (_viewMode != ViewMode.settings) _settingsReturnView = _viewMode;
    setState(() => _viewMode = ViewMode.settings);
  }

  void _closeSettings() {
    setState(() => _viewMode = _settingsReturnView);
  }

  List<Task> get _filteredTasks {
    final now = _dateOnly(DateTime.now());
    final end = now.add(const Duration(days: 7));
    final query = _taskSearchQuery.trim().toLowerCase();
    final items = _tasks.where((task) {
      if (_showCompleted != task.isDone) return false;
      if (query.isNotEmpty &&
          !task.title.toLowerCase().contains(query) &&
          !task.description.toLowerCase().contains(query)) {
        return false;
      }

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
      return switch (_taskSortMode) {
        TaskSortMode.date => _compareTaskDate(a, b),
        TaskSortMode.priority => _compareTaskPriority(a, b),
        TaskSortMode.title =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
    });
    return items;
  }

  int _compareTaskDate(Task a, Task b) {
    if (a.date == null && b.date == null) return _compareTaskPriority(a, b);
    if (a.date == null) return 1;
    if (b.date == null) return -1;
    final dateCompare = a.date!.compareTo(b.date!);
    return dateCompare == 0 ? _compareTaskPriority(a, b) : dateCompare;
  }

  int _compareTaskPriority(Task a, Task b) {
    final priorityCompare =
        _priorityRank(b.priority).compareTo(_priorityRank(a.priority));
    if (priorityCompare != 0) return priorityCompare;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  int _priorityRank(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.none => 0,
      TaskPriority.low => 1,
      TaskPriority.medium => 2,
      TaskPriority.high => 3,
    };
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

  void _updateTaskSearch(String value) {
    setState(() => _taskSearchQuery = value);
  }

  void _updateTaskSort(TaskSortMode value) {
    setState(() => _taskSortMode = value);
  }

  void _addTask(String title, DateTime? date, TaskPriority priority,
      DateTime? endDate, String? listId, RepeatPreset repeatPreset) {
    final firstDate =
        date ?? (_defaultTaskDateToday ? _dateOnly(DateTime.now()) : null);
    final repeatCount = switch (repeatPreset) {
      RepeatPreset.none => 1,
      RepeatPreset.daily => 7,
      RepeatPreset.weekly => 4,
    };
    final createdTasks = List.generate(repeatCount, (index) {
      final taskDate = firstDate == null
          ? null
          : switch (repeatPreset) {
              RepeatPreset.none => firstDate,
              RepeatPreset.daily => firstDate.add(Duration(days: index)),
              RepeatPreset.weekly => firstDate.add(Duration(days: index * 7)),
            };
      return Task(
        id: '${DateTime.now().microsecondsSinceEpoch}-$index',
        title: title,
        date: taskDate,
        endDate: endDate,
        priority: priority,
        listId: listId,
      );
    });

    for (final task in createdTasks) {
      _taskBox.put(task.id, task);
    }
    setState(() => _tasks = [..._tasks, ...createdTasks]);
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
            _pomodoroRemaining = _pomodoroDuration;
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
        _pomodoroRemaining = _pomodoroDuration;
      }
    });
  }

  void _endFocusSession() {
    final hadProgress = _usePomodoro
        ? _pomodoroRemaining < _pomodoroDuration
        : _focusElapsed > Duration.zero;
    _focusTimer?.cancel();
    setState(() {
      if (hadProgress) _recordFocusSession();
      _focusRunning = false;
      _focusElapsed = Duration.zero;
      _pomodoroRemaining = _pomodoroDuration;
    });
  }

  Future<void> _exportData() async {
    final file = await FilePicker.platform.saveFile(
      dialogTitle: '导出备份',
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
      'settings': Map<String, dynamic>.fromEntries(
        _settingsBox.toMap().entries.where((entry) {
          return entry.key is String &&
              (entry.key as String).startsWith('setting_') &&
              (entry.value is num || entry.value is bool);
        }).map((entry) {
          return MapEntry(entry.key as String, entry.value);
        }),
      ),
    };

    await File(file).writeAsString(jsonEncode(payload));
    await _settingsBox.put(_lastBackupAtKey, DateTime.now().toIso8601String());
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('备份已导出')));
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

    late final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份文件无法解析')),
      );
      return;
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['tasks'] is! List ||
        decoded['lists'] is! List) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份文件格式不正确')),
      );
      return;
    }
    final data = decoded;
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

    final settings = data['settings'];
    if (settings is Map<String, dynamic>) {
      final settingKeys = _settingsBox.keys
          .where((key) => key is String && key.startsWith('setting_'))
          .toList();
      for (final key in settingKeys) {
        await _settingsBox.delete(key);
      }
      for (final entry in settings.entries) {
        final value = entry.value;
        if (value is num || value is bool) {
          await _settingsBox.put(entry.key, value);
        }
      }
    }

    _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('备份已导入并校验通过')));
  }

  Future<void> _clearAllLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: NeoBrutalism.paper,
          title: const Text('清空所有本地数据？'),
          content: const Text(
            '这会删除此设备上的任务、清单、专注统计和设置。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    _focusTimer?.cancel();
    await _taskBox.clear();
    await _listBox.clear();
    await _settingsBox.clear();
    setState(() {
      _tasks = [];
      _taskLists = [];
      _selectedTaskId = null;
      _selectedSmartView = SmartView.today;
      _selectedListId = null;
      _showCompleted = false;
      _viewMode = ViewMode.focus;
      _settingsReturnView = ViewMode.focus;
      _focusElapsed = Duration.zero;
      _pomodoroRemaining = const Duration(minutes: 25);
      _focusRunning = false;
      _usePomodoro = false;
      _focusTab = FocusTab.time;
      _focusStatsRange = FocusStatsRange.week;
      _focusStatsAnchorDate = DateTime.now();
      _focusSubject = '专注';
      _focusDurationMinutes = 25;
      _shortBreakMinutes = 5;
      _longBreakMinutes = 15;
      _longBreakAfterSessions = 4;
      _soundEffects = true;
      _autoStartBreak = false;
      _dailyGoalMinutes = 120;
      _defaultStartPage = DefaultStartPage.focus;
      _defaultTaskDateToday = true;
      _backupReminder = true;
      _reduceMotion = false;
      _taskSearchQuery = '';
      _taskSortMode = TaskSortMode.date;
      _focusStatsSubjectFilter = null;
      _completedFocusSessions = 0;
    });
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
    if (_viewMode == ViewMode.settings) return '系统设置';
    if (_viewMode == ViewMode.focus) return '专注';
    if (_viewMode == ViewMode.calendar) return '日历';
    if (_showCompleted) return '已完成';
    if (_selectedListId != null) {
      return _taskLists.firstWhere((list) => list.id == _selectedListId).name;
    }
    switch (_selectedSmartView) {
      case SmartView.inbox:
        return '收件箱';
      case SmartView.today:
        return '今天';
      case SmartView.next7Days:
        return '未来 7 天';
      case null:
        return '任务';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 720;
    final isDesktop = width > 1100;
    final title = _headerTitle();
    final focusLast7DaySeconds = _focusLast7DaySeconds;
    final focusWeekSeconds = focusLast7DaySeconds.fold<int>(
      0,
      (total, seconds) => total + seconds,
    );
    final filteredFocusChartSeconds = _focusStatsChartSeconds;
    final filteredFocusWeekSeconds = _focusStatsSubjectFilter == null
        ? focusWeekSeconds
        : List.generate(7, (index) {
            final today = _dateOnly(DateTime.now());
            final date = today.subtract(Duration(days: 6 - index));
            return _focusSecondsForDate(date);
          }).fold<int>(0, (total, seconds) => total + seconds);
    final headerActionLabel = switch (_viewMode) {
      ViewMode.focus => '任务',
      ViewMode.list => '日历',
      ViewMode.calendar => '列表',
      ViewMode.settings => '返回',
    };
    final mainContentKey = ValueKey((
      _viewMode,
      _viewMode == ViewMode.focus ? _focusTab : null,
      _viewMode == ViewMode.list ? _selectedSmartView : null,
      _viewMode == ViewMode.list ? _selectedListId : null,
      _viewMode == ViewMode.list ? _showCompleted : null,
      _viewMode == ViewMode.calendar ? _calendarViewMode : null,
    ));
    final mainContent = switch (_viewMode) {
      ViewMode.focus => _FocusPanel(
          displayTime: _usePomodoro ? _pomodoroRemaining : _focusElapsed,
          isRunning: _focusRunning,
          usePomodoro: _usePomodoro,
          selectedTab: _focusTab,
          focusSubject: _focusSubject,
          statsRange: _focusStatsRange,
          focusDurationMinutes: _focusDurationMinutes,
          completedSessions: _completedFocusSessions,
          totalFocusSeconds: _filteredFocusTotalSeconds,
          todayFocusSeconds: _filteredFocusTodaySeconds,
          weekFocusSeconds: filteredFocusWeekSeconds,
          chartSeconds: filteredFocusChartSeconds,
          dailyGoalMinutes: _dailyGoalMinutes,
          streakDays: _focusStreakDays,
          statsRangeLabel: _focusStatsRangeLabel,
          distributionItems: _focusDistributionItems,
          subjects: _focusSubjects,
          selectedSubject: _focusStatsSubjectFilter,
          onToggleTimer: _toggleFocusTimer,
          onEndSession: _endFocusSession,
          onTabChanged: _changeFocusTab,
          onSubjectChanged: _updateFocusSubject,
          onStatsSubjectChanged: _changeFocusStatsSubject,
          onStatsRangeChanged: _changeFocusStatsRange,
          onPreviousStatsRange: () => _shiftFocusStatsRange(-1),
          onNextStatsRange:
              _canGoNextFocusStatsRange ? () => _shiftFocusStatsRange(1) : null,
        ),
      ViewMode.settings => _SettingsPanel(
          focusDurationMinutes: _focusDurationMinutes,
          shortBreakMinutes: _shortBreakMinutes,
          longBreakMinutes: _longBreakMinutes,
          longBreakAfterSessions: _longBreakAfterSessions,
          soundEffects: _soundEffects,
          autoStartBreak: _autoStartBreak,
          dailyGoalMinutes: _dailyGoalMinutes,
          defaultStartPage: _defaultStartPage,
          defaultTaskDateToday: _defaultTaskDateToday,
          backupReminder: _backupReminder,
          reduceMotion: _reduceMotion,
          backupHint: _backupHint,
          onFocusDurationChanged: _updateFocusDuration,
          onShortBreakChanged: _updateShortBreak,
          onLongBreakChanged: _updateLongBreak,
          onLongBreakAfterChanged: _updateLongBreakAfter,
          onSoundEffectsChanged: _updateSoundEffects,
          onAutoStartBreakChanged: _updateAutoStartBreak,
          onDailyGoalChanged: _updateDailyGoal,
          onDefaultStartPageChanged: _updateDefaultStartPage,
          onDefaultTaskDateTodayChanged: _updateDefaultTaskDateToday,
          onBackupReminderChanged: _updateBackupReminder,
          onReduceMotionChanged: _updateReduceMotion,
          onExport: _exportData,
          onImport: _importData,
          onClearData: _clearAllLocalData,
        ),
      ViewMode.list => _TaskColumn(
          title: title,
          tasks: _filteredTasks,
          taskLists: _taskLists,
          selectedTaskId: _selectedTaskId,
          isMobile: isMobile,
          searchQuery: _taskSearchQuery,
          sortMode: _taskSortMode,
          onSearchChanged: _updateTaskSearch,
          onSortChanged: _updateTaskSort,
          onSelectTask: (id) {
            final task = _tasks.firstWhere((item) => item.id == id);
            _openTaskDetails(task, isMobile: isMobile);
          },
          onToggleDone: _toggleDone,
          onMoveTask: _moveTaskTo,
          onDeleteTask: _deleteTask,
        ),
      ViewMode.calendar => _CalendarPanel(
          selectedDate: _selectedDate,
          tasks: _tasks,
          mode: _calendarViewMode,
          isMobile: isMobile,
          onModeChanged: (mode) => setState(() => _calendarViewMode = mode),
          onDateSelected: (date) => setState(() => _selectedDate = date),
          onTaskSelected: (id) {
            final task = _tasks.firstWhere((item) => item.id == id);
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
                  if (_viewMode == ViewMode.settings) {
                    _closeSettings();
                    return;
                  }
                  setState(() {
                    _viewMode = switch (_viewMode) {
                      ViewMode.focus => ViewMode.list,
                      ViewMode.list => ViewMode.calendar,
                      ViewMode.calendar => ViewMode.list,
                      ViewMode.settings => _settingsReturnView,
                    };
                  });
                },
                isCalendar: _viewMode == ViewMode.calendar,
                actionLabel: headerActionLabel,
                onSettingsPressed: _openSettings,
                isSettings: _viewMode == ViewMode.settings,
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile && _viewMode != ViewMode.settings)
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
                  if (!isMobile && _viewMode != ViewMode.settings)
                    Container(width: 2, color: NeoBrutalism.ink),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: _reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 260),
                      reverseDuration: _reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0.035, 0),
                          end: Offset.zero,
                        ).animate(animation);

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: mainContentKey,
                        child: mainContent,
                      ),
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
      floatingActionButton: AnimatedSwitcher(
        duration:
            _reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        reverseDuration:
            _reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: _viewMode == ViewMode.list
            ? GestureDetector(
                key: const ValueKey('quick-add-fab'),
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
                  child:
                      const Icon(Icons.add, size: 36, color: NeoBrutalism.ink),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('quick-add-fab-empty')),
      ),
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
