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
import '../utils/priority_color.dart';

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
  ViewMode _viewMode = ViewMode.list;
  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _calendarViewMode = CalendarViewMode.month;
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<Task>('tasks');
    _listBox = Hive.box<TaskList>('taskLists');
    _loadData();
  }

  void _loadData() {
    _tasks = _taskBox.values.toList();
    _taskLists = _listBox.values.toList();
    if (_taskLists.isEmpty) {
      _taskLists = [
        TaskList.withIcon(
          id: 'work',
          name: '宸ヤ綔',
          icon: Icons.work_outline,
          color: NeoBrutalism.cyan,
        ),
        TaskList.withIcon(
          id: 'study',
          name: '瀛︿範',
          icon: Icons.school_outlined,
          color: NeoBrutalism.yellow,
        ),
        TaskList.withIcon(
          id: 'life',
          name: '鐢熸椿',
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
    try {
      return _tasks.firstWhere((task) => task.id == _selectedTaskId);
    } catch (_) {
      return null;
    }
  }

  List<Task> get _filteredTasks {
    return _tasks.where((task) {
      if (!_showCompleted && task.isDone) return false;
      if (_showCompleted && !task.isDone) return false;
      if (_selectedSmartView != null) {
        switch (_selectedSmartView!) {
          case SmartView.inbox:
            return true;
          case SmartView.today:
            return _isSameDate(task.date, DateTime.now());
          case SmartView.next7Days:
            if (task.date == null) return false;
            final now = _normalizeDate(DateTime.now());
            final end = now.add(const Duration(days: 7));
            final date = _normalizeDate(task.date!);
            return (date.isAfter(now) || date.isAtSameMomentAs(now)) &&
                (date.isBefore(end) || date.isAtSameMomentAs(end));
        }
      }
      if (_selectedListId != null) return task.listId == _selectedListId;
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      });
  }

  DateTime _normalizeDate(DateTime value) => DateTime(value.year, value.month, value.day);

  bool _isSameDate(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _countForSmartView(SmartView view) {
    return _tasks.where((task) {
      if (task.isDone) return false;
      switch (view) {
        case SmartView.inbox:
          return true;
        case SmartView.today:
          return _isSameDate(task.date, DateTime.now());
        case SmartView.next7Days:
          if (task.date == null) return false;
          final now = _normalizeDate(DateTime.now());
          final end = now.add(const Duration(days: 7));
          final date = _normalizeDate(task.date!);
          return (date.isAfter(now) || date.isAtSameMomentAs(now)) &&
              (date.isBefore(end) || date.isAtSameMomentAs(end));
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

  void _addTask(String title, DateTime? date, TaskPriority priority, DateTime? endDate, String? listId) {
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
    setState(() {
      final index = _tasks.indexWhere((item) => item.id == task.id);
      if (index != -1) _tasks[index] = task;
    });
  }

  void _toggleDone(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    final updated = _tasks[index].copyWith(isDone: !_tasks[index].isDone);
    _updateTask(updated);
    if (!_showCompleted && updated.isDone && _selectedTaskId == id) {
      setState(() => _selectedTaskId = null);
    }
  }

  void _moveTaskTo(String taskId, String? listId) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    _updateTask(_tasks[index].copyWith(listId: listId));
  }

  void _deleteTask(String taskId) {
    _taskBox.delete(taskId);
    setState(() {
      _tasks.removeWhere((task) => task.id == taskId);
      if (_selectedTaskId == taskId) _selectedTaskId = null;
    });
  }

  Future<void> _exportData() async {
    final export = {
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
    final file = await FilePicker.platform.saveFile(
      dialogTitle: 'Export backup',
      fileName: 'litasker_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return;
    await File(file).writeAsString(jsonEncode(export));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup exported')),
      );
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    String content = '';
    if (picked.path != null) {
      content = await File(picked.path!).readAsString();
    } else if (picked.bytes != null) {
      content = utf8.decode(picked.bytes!);
    }
    if (content.isEmpty) return;
    final data = jsonDecode(content);
    await _taskBox.clear();
    await _listBox.clear();
    for (final rawList in (data['lists'] as List? ?? [])) {
      final list = TaskList(
        rawList['id'],
        rawList['name'],
        rawList['iconCodePoint'],
        rawList['colorValue'],
      );
      _listBox.put(list.id, list);
    }
    for (final rawTask in (data['tasks'] as List? ?? [])) {
      final task = Task.fromJson(rawTask);
      _taskBox.put(task.id, task);
    }
    _loadData();
  }

  Future<void> _showQuickAdd() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickAddSheet(
        currentListId: _selectedListId,
        allLists: _taskLists,
        onAdd: _addTask,
      ),
    );
  }

  Future<void> _openTaskDetails(Task task, {required bool isMobile}) async {
    if (!isMobile) {
      setState(() => _selectedTaskId = task.id);
      return;
    }

    setState(() => _selectedTaskId = task.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
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
                final current = _tasks.firstWhere((item) => item.id == task.id);
                _updateTask(current.copyWith(title: value));
              },
              onDescriptionChanged: (value) {
                final current = _tasks.firstWhere((item) => item.id == task.id);
                _updateTask(current.copyWith(description: value));
              },
              onListChanged: (value) => _moveTaskTo(task.id, value),
            ),
          ),
        ),
      ),
    );
  }

  String _headerTitle() {
    if (_viewMode == ViewMode.calendar) return '??';
    if (_showCompleted) return '???';
    if (_selectedListId != null) {
      return _taskLists.firstWhere((list) => list.id == _selectedListId).name;
    }
    switch (_selectedSmartView) {
      case SmartView.inbox:
        return '???';
      case SmartView.today:
        return '??';
      case SmartView.next7Days:
        return '?? 7 ?';
      case null:
        return '??';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 720;
    final isDesktop = width > 1100;
    final title = _headerTitle();

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
                onSmartViewSelected: (view) {
                  Navigator.pop(context);
                  _selectSmartView(view);
                },
                onListSelected: (id) {
                  Navigator.pop(context);
                  _selectList(id);
                },
                onCompletedSelected: () {
                  Navigator.pop(context);
                  _toggleCompletedView();
                },
                onExport: () {
                  Navigator.pop(context);
                  _exportData();
                },
                onImport: () {
                  Navigator.pop(context);
                  _importData();
                },
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
                onMenuPressed: isMobile ? () => Scaffold.of(context).openDrawer() : null,
                onSwitchView: () {
                  setState(() {
                    _viewMode = _viewMode == ViewMode.list ? ViewMode.calendar : ViewMode.list;
                  });
                },
                isCalendar: _viewMode == ViewMode.calendar,
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
                        completedCount: _tasks.where((task) => task.isDone).length,
                        listCountBuilder: _countForList,
                        onSmartViewSelected: _selectSmartView,
                        onListSelected: _selectList,
                        onCompletedSelected: _toggleCompletedView,
                        onExport: _exportData,
                        onImport: _importData,
                      ),
                    ),
                  if (!isMobile)
                    Container(width: 2, color: NeoBrutalism.ink),
                  Expanded(
                    child: _viewMode == ViewMode.list
                        ? _TaskColumn(
                            title: title,
                            tasks: _filteredTasks,
                            taskLists: _taskLists,
                            selectedTaskId: _selectedTaskId,
                            onSelectTask: (id) {
                              final task = _tasks.firstWhere((item) => item.id == id);
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
                            onModeChanged: (mode) => setState(() => _calendarViewMode = mode),
                            onDateSelected: (date) => setState(() => _selectedDate = date),
                            onTaskSelected: (id) {
                              final task = _tasks.firstWhere((item) => item.id == id);
                              if (isMobile) {
                                _openTaskDetails(task, isMobile: true);
                                return;
                              }
                              setState(() {
                                _selectedTaskId = id;
                                _viewMode = ViewMode.list;
                              });
                            },
                          ),
                  ),
                  if (isDesktop && _viewMode == ViewMode.list && _selectedTask != null) ...[
                    Container(width: 2, color: NeoBrutalism.ink),
                    SizedBox(
                      width: 380,
                      child: _DetailPanel(
                        task: _selectedTask!,
                        taskLists: _taskLists,
                        onTitleChanged: (value) => _updateTask(_selectedTask!.copyWith(title: value)),
                        onDescriptionChanged: (value) =>
                            _updateTask(_selectedTask!.copyWith(description: value)),
                        onListChanged: (value) => _moveTaskTo(_selectedTask!.id, value),
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
            _fabPressed ? 4 : 0,
            _fabPressed ? 4 : 0,
            0,
          ),
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

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.isMobile,
    required this.onMenuPressed,
    required this.onSwitchView,
    required this.isCalendar,
  });

  final String title;
  final bool isMobile;
  final VoidCallback? onMenuPressed;
  final VoidCallback onSwitchView;
  final bool isCalendar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NeoBrutalism.card(color: NeoBrutalism.yellow),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu, color: NeoBrutalism.ink),
            )
          else
            const Icon(Icons.dashboard_customize_outlined, color: NeoBrutalism.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LITASKER', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.4),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSwitchView,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: NeoBrutalism.flatCard(
                color: isCalendar ? NeoBrutalism.cyan : NeoBrutalism.paper,
              ),
              child: Text(
                isCalendar ? '浠诲姟' : '鏃ュ巻',
                style: NeoBrutalism.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarPanel extends StatelessWidget {
  const _SidebarPanel({
    required this.selectedSmartView,
    required this.selectedListId,
    required this.showCompleted,
    required this.taskLists,
    required this.countInbox,
    required this.countToday,
    required this.countNext7,
    required this.completedCount,
    required this.listCountBuilder,
    required this.onSmartViewSelected,
    required this.onListSelected,
    required this.onCompletedSelected,
    required this.onExport,
    required this.onImport,
  });

  final SmartView? selectedSmartView;
  final String? selectedListId;
  final bool showCompleted;
  final List<TaskList> taskLists;
  final int countInbox;
  final int countToday;
  final int countNext7;
  final int completedCount;
  final int Function(String) listCountBuilder;
  final ValueChanged<SmartView> onSmartViewSelected;
  final ValueChanged<String> onListSelected;
  final VoidCallback onCompletedSelected;
  final VoidCallback onExport;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NeoBrutalism.background,
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
                    child: const Text('浠诲姟瀵艰埅', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 22),
                  const Text('鏅鸿兘瑙嗗浘', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                  const SizedBox(height: 12),
                  _NavTile(
                    label: '鏀朵欢绠?,
                    count: countInbox,
                    color: NeoBrutalism.paper,
                    selected: selectedSmartView == SmartView.inbox && !showCompleted,
                    onTap: () => onSmartViewSelected(SmartView.inbox),
                  ),
                  _NavTile(
                    label: '浠婂ぉ',
                    count: countToday,
                    color: NeoBrutalism.cyan,
                    selected: selectedSmartView == SmartView.today && !showCompleted,
                    onTap: () => onSmartViewSelected(SmartView.today),
                  ),
                  _NavTile(
                    label: '鏈潵 7 澶?,
                    count: countNext7,
                    color: NeoBrutalism.yellow,
                    selected: selectedSmartView == SmartView.next7Days && !showCompleted,
                    onTap: () => onSmartViewSelected(SmartView.next7Days),
                  ),
                  const SizedBox(height: 22),
                  const Text('娓呭崟', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                  const SizedBox(height: 12),
                  for (final list in taskLists)
                    _NavTile(
                      label: list.name,
                      count: listCountBuilder(list.id),
                      color: list.color,
                      selected: selectedListId == list.id,
                      leading: Icon(list.icon, size: 18, color: NeoBrutalism.ink),
                      onTap: () => onListSelected(list.id),
                    ),
                  _NavTile(
                    label: '宸插畬鎴?,
                    count: completedCount,
                    color: NeoBrutalism.pink,
                    selected: showCompleted,
                    onTap: onCompletedSelected,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallActionButton(label: '瀵煎叆', onTap: onImport),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SmallActionButton(
                          label: '瀵煎嚭',
                          onTap: onExport,
                          color: NeoBrutalism.yellow,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: selected
            ? NeoBrutalism.card(color: color)
            : NeoBrutalism.flatCard(color: NeoBrutalism.paper),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _TaskColumn extends StatelessWidget {
  const _TaskColumn({
    required this.title,
    required this.tasks,
    required this.taskLists,
    required this.selectedTaskId,
    required this.onSelectTask,
    required this.onToggleDone,
    required this.onMoveTask,
    required this.onDeleteTask,
  });

  final String title;
  final List<Task> tasks;
  final List<TaskList> taskLists;
  final String? selectedTaskId;
  final ValueChanged<String> onSelectTask;
  final ValueChanged<String> onToggleDone;
  final void Function(String, String?) onMoveTask;
  final ValueChanged<String> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const _EmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: NeoBrutalism.hero),
          const SizedBox(height: 8),
          const Text(
            '绮楃嚎鏉★紝楂樺姣旓紝鍏堝仛閲嶈鐨勪簨銆?,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _TaskCard(
                  task: task,
                  selected: selectedTaskId == task.id,
                  taskLists: taskLists,
                  onTap: () => onSelectTask(task.id),
                  onToggleDone: () => onToggleDone(task.id),
                  onMoveTo: (listId) => onMoveTask(task.id, listId),
                  onDelete: () => onDeleteTask(task.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.selected,
    required this.taskLists,
    required this.onTap,
    required this.onToggleDone,
    required this.onMoveTo,
    required this.onDelete,
  });

  final Task task;
  final bool selected;
  final List<TaskList> taskLists;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final ValueChanged<String?> onMoveTo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final list = task.listId == null
        ? null
        : taskLists.where((item) => item.id == task.listId).cast<TaskList?>().firstOrNull;
    final accent = task.isDone ? NeoBrutalism.green : getPriorityColor(task.priority);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: selected
            ? NeoBrutalism.card(color: accent.withValues(alpha: 0.22))
            : NeoBrutalism.card(color: NeoBrutalism.paper),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onToggleDone,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: NeoBrutalism.flatCard(
                        color: task.isDone ? NeoBrutalism.green : NeoBrutalism.paper,
                      ),
                      child: task.isDone
                          ? const Icon(Icons.close, size: 18, color: NeoBrutalism.ink)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: NeoBrutalism.paper,
                    shape: const RoundedRectangleBorder(side: BorderSide(color: NeoBrutalism.ink, width: 2)),
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                      if (value == 'clear') onMoveTo(null);
                      if (value.startsWith('list:')) onMoveTo(value.substring(5));
                    },
                    itemBuilder: (context) => [
                        const PopupMenuItem(value: 'clear', child: Text('绉诲埌鏀朵欢绠?)),
                        for (final list in taskLists) PopupMenuItem(value: 'list:${list.id}', child: Text('绉诲埌 ${list.name}')),
                        const PopupMenuItem(value: 'delete', child: Text('鍒犻櫎')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Tag(label: _priorityLabel(task.priority), color: accent),
                  if (list != null) _Tag(label: list.name.toUpperCase(), color: list.color),
                  _Tag(label: _dateLabel(task.date), color: NeoBrutalism.muted),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
class _DetailPanel extends StatefulWidget {
  const _DetailPanel({
    required this.task,
    required this.taskLists,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onListChanged,
  });

  final Task task;
  final List<TaskList> taskLists;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<String?> onListChanged;

  @override
  State<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends State<_DetailPanel> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
  }

  @override
  void didUpdateWidget(covariant _DetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id || oldWidget.task.title != widget.task.title) {
      _syncController(_titleController, widget.task.title);
    }
    if (oldWidget.task.id != widget.task.id || oldWidget.task.description != widget.task.description) {
      _syncController(_descController, widget.task.description);
    }
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('????', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  onChanged: widget.onTitleChanged,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: NeoBrutalism.card(color: NeoBrutalism.cyan.withValues(alpha: 0.28)),
            padding: const EdgeInsets.all(18),
            child: DropdownButtonFormField<String?>(
              initialValue: widget.task.listId,
              decoration: const InputDecoration(
                border: InputBorder.none,
                labelText: '????',
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('???')),

                ...widget.taskLists.map((list) => DropdownMenuItem<String?>(value: list.id, child: Text(list.name))),
              ],
              onChanged: widget.onListChanged,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('??', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                const SizedBox(height: 12),
class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.selectedDate,
    required this.tasks,
    required this.mode,
    required this.isMobile,
    required this.onModeChanged,
    required this.onDateSelected,
    required this.onTaskSelected,
  });

  final DateTime selectedDate;
  final List<Task> tasks;
  final CalendarViewMode mode;
  final bool isMobile;
  final ValueChanged<CalendarViewMode> onModeChanged;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<String> onTaskSelected;

  @override
  Widget build(BuildContext context) {
    final month = DateTime(selectedDate.year, selectedDate.month, 1);
    final startOffset = month.weekday - 1;
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final selectedTasks = _tasksForDate(selectedDate);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ' ? ',
                  style: TextStyle(
                    fontSize: isMobile ? 32 : 54,
                    fontWeight: FontWeight.w900,
                    height: 0.92,
                    color: NeoBrutalism.ink,
                  ),
                ),
              ),
              _MonthSwitchButton(
                icon: Icons.chevron_left,
                onTap: () => onDateSelected(DateTime(selectedDate.year, selectedDate.month - 1, 1)),
              ),
              const SizedBox(width: 10),
              _MonthSwitchButton(
                icon: Icons.chevron_right,
                onTap: () => onDateSelected(DateTime(selectedDate.year, selectedDate.month + 1, 1)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in CalendarViewMode.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => onModeChanged(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: item == mode
                            ? NeoBrutalism.card(color: NeoBrutalism.yellow)
                            : NeoBrutalism.flatCard(color: NeoBrutalism.paper),
                        child: Text(_calendarModeLabel(item), style: NeoBrutalism.label),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: mode == CalendarViewMode.month
                ? (isMobile ? _buildMobileMonthView(startOffset, daysInMonth, selectedTasks) : _buildDesktopMonthView(startOffset, daysInMonth, selectedTasks))
                : _CalendarAgenda(
                    selectedDate: selectedDate,
                    tasks: tasks,
                    mode: mode,
                    onDateSelected: onDateSelected,
                    onTaskSelected: onTaskSelected,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMonthView(int startOffset, int daysInMonth, List<Task> selectedTasks) {
    return ListView(
      children: [
        _buildMonthGrid(startOffset, daysInMonth),
        const SizedBox(height: 20),
        _buildSummaryCard(selectedTasks),
        const SizedBox(height: 20),
        _buildStatusCard(),
      ],
    );
  }

  Widget _buildDesktopMonthView(int startOffset, int daysInMonth, List<Task> selectedTasks) {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildMonthGrid(startOffset, daysInMonth)),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: ListView(
            children: [
              _buildSummaryCard(selectedTasks),
              const SizedBox(height: 20),
              _buildStatusCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(int startOffset, int daysInMonth) {
    return Container(
      decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              _WeekdayLabel('MON'),
              _WeekdayLabel('TUE'),
              _WeekdayLabel('WED'),
              _WeekdayLabel('THU'),
              _WeekdayLabel('FRI'),
              _WeekdayLabel('SAT'),
              _WeekdayLabel('SUN'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: isMobile ? 0.72 : 0.92,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox.shrink();
              final day = index - startOffset + 1;
              final cellDate = DateTime(selectedDate.year, selectedDate.month, day);
              final isSelected = _sameDate(cellDate, selectedDate);
              final dayTasks = _tasksForDate(cellDate);
              return GestureDetector(
                onTap: () => onDateSelected(cellDate),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: isSelected
                      ? NeoBrutalism.card(color: NeoBrutalism.yellow)
                      : NeoBrutalism.flatCard(color: NeoBrutalism.background),
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('', style: TextStyle(fontWeight: FontWeight.w900, fontSize: isMobile ? 15 : 20)),
                      const Spacer(),
                      for (final task in dayTasks.take(isMobile ? 1 : 2))
                        Container(
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          color: getPriorityColor(task.priority),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Task> selectedTasks) {
    return Container(
      width: double.infinity,
      decoration: NeoBrutalism.card(color: NeoBrutalism.cyan),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(' ?   ?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          if (selectedTasks.isEmpty)
            const Text('????????', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (selectedTasks.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = selectedTasks[index];
                return GestureDetector(
                  onTap: () => onTaskSelected(task.id),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
                    child: Row(
                      children: [
                        Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w900))),
                        Container(width: 12, height: 12, color: getPriorityColor(task.priority)),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
      padding: const EdgeInsets.all(18),
      child: const Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StatusChip(label: '??', color: NeoBrutalism.pink),
          _StatusChip(label: '???', color: NeoBrutalism.cyan),
          _StatusChip(label: '???', color: NeoBrutalism.yellow),
        ],
      ),
    );
  }

  List<Task> _tasksForDate(DateTime date) {
    return tasks.where((task) {
      final value = task.date;
      return value != null && _sameDate(value, date);
    }).toList();
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _monthName(int month) {
    const names = ['1?', '2?', '3?', '4?', '5?', '6?', '7?', '8?', '9?', '10?', '11?', '12?'];
    return names[month - 1];
  }

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentView, required this.onChange});

  final ViewMode currentView;
  final ValueChanged<ViewMode> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: NeoBrutalism.paper,
        border: Border(top: BorderSide(color: NeoBrutalism.ink, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: _BottomNavItem(
              label: '??',
              selected: currentView == ViewMode.list,
              onTap: () => onChange(ViewMode.list),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BottomNavItem(
              label: '??',
              selected: currentView == ViewMode.calendar,
              onTap: () => onChange(ViewMode.calendar),
            ),
          ),
        ],
      ),
    );
  }
}
    return ListView(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dates.map((date) {
              final isSelected = _sameDate(date, selectedDate);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: Container(
                    width: 96,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: isSelected
                        ? NeoBrutalism.card(color: NeoBrutalism.yellow)
                        : NeoBrutalism.flatCard(color: NeoBrutalism.paper),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_weekdayCn(date.weekday), style: NeoBrutalism.label),
                        const SizedBox(height: 6),
                        Text('/', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        ...dates.map((date) {
          final dayTasks = tasks.where((task) {
            final taskDate = task.date;
            return taskDate != null && _sameDate(taskDate, date);
          }).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Container(
              decoration: NeoBrutalism.card(
                color: _sameDate(date, selectedDate)
                    ? NeoBrutalism.yellow.withValues(alpha: 0.45)
                    : NeoBrutalism.paper,
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('?? ', style: NeoBrutalism.title),
                  const SizedBox(height: 14),
                  if (dayTasks.isEmpty)
                    const Text('???????', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ...dayTasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => onTaskSelected(task.id),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: NeoBrutalism.flatCard(color: NeoBrutalism.background),
                          child: Row(
                            children: [
                              Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w900))),
                              Container(width: 12, height: 12, color: getPriorityColor(task.priority)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayCn(int weekday) {
    const labels = ['?', '?', '?', '?', '?', '?', '?'];
    return '?';
  }
}

class _MonthSwitchButton extends StatelessWidget {
  const _MonthSwitchButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
        child: Icon(icon, color: NeoBrutalism.ink),
      ),
    );
  }
}
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: NeoBrutalism.card(color: NeoBrutalism.cyan),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('褰撳ぉ姒傝', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 18),
                              Expanded(
                                child: ListView(
                                  children: [
                                    if (selectedTasks.isEmpty)
                                      const Text('杩欎竴澶╂病鏈変换鍔°€?, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    for (final task in selectedTasks)
                                      GestureDetector(
                                        onTap: () => onTaskSelected(task.id),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                                              ),
                                              Container(width: 12, height: 12, color: getPriorityColor(task.priority)),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
                        padding: const EdgeInsets.all(18),
                        child: const Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _StatusChip(label: '绱ф€?, color: NeoBrutalism.pink),
                            _StatusChip(label: '璁″垝涓?, color: NeoBrutalism.cyan),
                            _StatusChip(label: '杩涜涓?, color: NeoBrutalism.yellow),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '1鏈?,
      '2鏈?,
      '3鏈?,
      '4鏈?,
      '5鏈?,
      '6鏈?,
      '7鏈?,
      '8鏈?,
      '9鏈?,
      '10鏈?,
      '11鏈?,
      '12鏈?,
    ];
    return names[month - 1];
  }

  String _calendarModeLabel(CalendarViewMode mode) {
    switch (mode) {
      case CalendarViewMode.month:
        return '鏈?;
      case CalendarViewMode.week:
        return '鍛?;
      case CalendarViewMode.day:
        return '鏃?;
    }
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: NeoBrutalism.flatCard(color: color),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentView, required this.onChange});

  final ViewMode currentView;
  final ValueChanged<ViewMode> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeoBrutalism.paper,
        border: Border(top: BorderSide(color: NeoBrutalism.ink, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: _BottomNavItem(
              label: '浠诲姟',
              selected: currentView == ViewMode.list,
              onTap: () => onChange(ViewMode.list),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BottomNavItem(
              label: '鏃ュ巻',
              selected: currentView == ViewMode.calendar,
              onTap: () => onChange(ViewMode.calendar),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: selected
            ? NeoBrutalism.card(color: NeoBrutalism.yellow)
            : NeoBrutalism.flatCard(color: NeoBrutalism.paper),
        child: Center(child: Text(label, style: NeoBrutalism.label)),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.onTap,
    this.color = NeoBrutalism.paper,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: NeoBrutalism.flatCard(color: color),
        child: Center(child: Text(label, style: NeoBrutalism.label)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 24,
                    top: 24,
                    child: Container(width: 110, height: 110, color: NeoBrutalism.pink),
                  ),
                  Positioned(
                    right: 34,
                    top: 38,
                    child: Transform.rotate(
                      angle: 0.7,
                      child: Container(width: 42, height: 42, color: NeoBrutalism.cyan),
                    ),
                  ),
                  Container(
                    width: 94,
                    height: 116,
                    decoration: NeoBrutalism.flatCard(color: NeoBrutalism.yellow),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '鏆傛棤浠诲姟',
              style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, height: 0.95),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(width: 3, height: 96, color: NeoBrutalism.ink),
            const SizedBox(height: 20),
            const Text(
              '褰撳墠寰堟竻鐖斤紝鍙互寮€濮嬩笅涓€浠堕噸瑕佺殑浜嬨€?,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddSheet extends StatefulWidget {
  const _QuickAddSheet({
    required this.currentListId,
    required this.allLists,
    required this.onAdd,
  });

  final String? currentListId;
  final List<TaskList> allLists;
  final void Function(String, DateTime?, TaskPriority, DateTime?, String?) onAdd;

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  final TextEditingController _controller = TextEditingController();
  TaskPriority _priority = TaskPriority.none;
  DateTime? _date;
  String? _listId;

  @override
  void initState() {
    super.initState();
    _listId = widget.currentListId;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
        margin: const EdgeInsets.all(12),
        decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('鏂板缓浠诲姟', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Container(
              decoration: NeoBrutalism.flatCard(color: NeoBrutalism.background),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '浣犲噯澶囧仛浠€涔堬紵',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: TaskPriority.values.map((priority) {
                final selected = _priority == priority;
                return GestureDetector(
                  onTap: () => setState(() => _priority = priority),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: selected
                        ? NeoBrutalism.card(color: getPriorityColor(priority))
                        : NeoBrutalism.flatCard(color: getPriorityColor(priority)),
                    child: Text(priority.name.toUpperCase(), style: NeoBrutalism.label),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 220,
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: NeoBrutalism.flatCard(color: NeoBrutalism.background),
                      child: Text(
                        _date == null ? '閫夋嫨鏃ユ湡' : '${_date!.year}/${_date!.month}/${_date!.day}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: NeoBrutalism.flatCard(color: NeoBrutalism.background),
                    child: DropdownButton<String?>(
                      value: _listId,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      hint: const Text('鏀朵欢绠?),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('鏀朵欢绠?)),
                        ...widget.allLists.map((list) => DropdownMenuItem<String?>(value: list.id, child: Text(list.name))),
                      ],
                      onChanged: (value) => setState(() => _listId = value),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SmallActionButton(
                    label: '鍙栨秷',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallActionButton(
                    label: '娣诲姞浠诲姟',
                    color: NeoBrutalism.yellow,
                    onTap: () {
                      if (_controller.text.trim().isEmpty) return;
                      widget.onAdd(_controller.text.trim(), _date, _priority, null, _listId);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
