import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../enums.dart';
import '../widgets/sidebar.dart';
import '../widgets/calendar_view.dart';
import '../widgets/task_item.dart';
import '../widgets/detail_pane.dart';
import '../widgets/quick_add_dialog.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Box<Task> _taskBox;
  late Box<TaskList> _listBox;
  List<Task> _tasks = [];
  List<TaskList> _taskLists = [];

  String? _selectedTaskId;
  SmartView? _selectedSmartView = SmartView.today;
  String? _selectedListId;
  bool _showCompleted = false;

  ViewMode _viewMode = ViewMode.list;
  DateTime _selectedDate = DateTime.now();
  CalendarViewMode _calendarViewMode = CalendarViewMode.month;

  bool _isDesktop = true;
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<Task>('tasks');
    _listBox = Hive.box<TaskList>('taskLists');
    _loadData();
  }

  void _loadData() {
    setState(() {
      _tasks = _taskBox.values.toList();
      _taskLists = _listBox.values.toList();
      if (_taskLists.isEmpty) {
        _taskLists = [
          TaskList.withIcon(id: '1', name: '工作', icon: Icons.work, color: Colors.blue),
          TaskList.withIcon(id: '2', name: '学习', icon: Icons.school, color: Colors.green),
          TaskList.withIcon(id: '3', name: '生活', icon: Icons.home, color: Colors.orange),
        ];
        for (var list in _taskLists) {
          _listBox.put(list.id, list);
        }
      }
    });
  }

  // ---------- 计算属性 ----------
  Task? get _selectedTask {
    try {
      return _tasks.firstWhere((t) => t.id == _selectedTaskId);
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
            if (task.date == null) return false;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final d = DateTime(task.date!.year, task.date!.month, task.date!.day);
            return d.isAtSameMomentAs(today);
          case SmartView.next7Days:
            if (task.date == null) return false;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final next = today.add(const Duration(days: 7));
            final d = DateTime(task.date!.year, task.date!.month, task.date!.day);
            return d.isBefore(next) || d.isAtSameMomentAs(next);
        }
      } else if (_selectedListId != null) {
        return task.listId == _selectedListId;
      }
      return true;
    }).toList();
  }

  int _countForSmartView(SmartView view) {
    return _tasks.where((task) {
      if (task.isDone) return false;
      switch (view) {
        case SmartView.inbox:
          return true;
        case SmartView.today:
          if (task.date == null) return false;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final d = DateTime(task.date!.year, task.date!.month, task.date!.day);
          return d.isAtSameMomentAs(today);
        case SmartView.next7Days:
          if (task.date == null) return false;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final next = today.add(const Duration(days: 7));
          final d = DateTime(task.date!.year, task.date!.month, task.date!.day);
          return d.isBefore(next) || d.isAtSameMomentAs(next);
      }
    }).length;
  }

  int get _completedCount {
    return _tasks.where((task) => task.isDone).length;
  }

  Map<String, int> _getListTaskCounts() {
    final Map<String, int> counts = {};
    for (final list in _taskLists) {
      counts[list.id] = _tasks.where((task) => task.listId == list.id && !task.isDone).length;
    }
    return counts;
  }

  // ---------- 任务操作 ----------
  void _addTask(String title, DateTime? date, TaskPriority priority, DateTime? endDate, String? listId) {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date,
      endDate: endDate,
      priority: priority,
      listId: listId,
    );
    _taskBox.put(newTask.id, newTask);
    setState(() => _tasks.add(newTask));
  }

  void _updateTaskTitle(String id, String newTitle) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updated = _tasks[index].copyWith(title: newTitle);
      _taskBox.put(id, updated);
      setState(() => _tasks[index] = updated);
    }
  }

  void _updateTaskDescription(String id, String newDesc) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updated = _tasks[index].copyWith(description: newDesc);
      _taskBox.put(id, updated);
      setState(() => _tasks[index] = updated);
    }
  }

  void _toggleTaskDone(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updated = _tasks[index].copyWith(isDone: !_tasks[index].isDone);
      _taskBox.put(id, updated);
      setState(() => _tasks[index] = updated);
      if (!_showCompleted && updated.isDone && _selectedTaskId == id) {
        _selectedTaskId = null;
      }
    }
  }

  void _moveTaskTo(String taskId, String? targetListId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updated = _tasks[index].copyWith(listId: targetListId);
      _taskBox.put(taskId, updated);
      setState(() => _tasks[index] = updated);
    }
  }

  void _showQuickAdd() {
    showQuickAddDialog(
      context,
      onAdd: _addTask,
      currentListId: _selectedListId,
      allLists: _taskLists,
    );
  }

  // ---------- 清单操作 ----------
  void _addTaskList() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新建清单'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '清单名称'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  final newList = TaskList.withIcon(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: controller.text.trim(),
                    icon: Icons.list,
                    color: Colors.primaries[_taskLists.length % Colors.primaries.length],
                  );
                  _listBox.put(newList.id, newList);
                  setState(() => _taskLists.add(newList));
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  void _editTaskList(TaskList list) {
    final controller = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑清单'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '清单名称'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  final updated = list.copyWith(name: controller.text.trim());
                  _listBox.put(list.id, updated);
                  setState(() {
                    final index = _taskLists.indexWhere((l) => l.id == list.id);
                    if (index != -1) _taskLists[index] = updated;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTaskList(TaskList list) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除清单'),
          content: Text('确定要删除清单“${list.name}”吗？\n该清单下的任务不会删除，但会变为未分类。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                for (var task in _tasks.where((t) => t.listId == list.id)) {
                  final updated = task.copyWith(listId: null);
                  _taskBox.put(task.id, updated);
                  final index = _tasks.indexWhere((t) => t.id == task.id);
                  if (index != -1) _tasks[index] = updated;
                }
                _listBox.delete(list.id);
                setState(() {
                  _taskLists.removeWhere((l) => l.id == list.id);
                  if (_selectedListId == list.id) {
                    _selectedListId = null;
                    _selectedSmartView = SmartView.inbox;
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // ---------- 导入导出 ----------
  Future<void> _exportData() async {
    try {
      final exportData = {
        'tasks': _tasks.map((task) => task.toJson()).toList(),
        'lists': _taskLists.map((list) => {
          'id': list.id,
          'name': list.name,
          'iconCodePoint': list.iconCodePoint,
          'colorValue': list.colorValue,
        }).toList(),
      };

      final jsonString = jsonEncode(exportData);

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: 'task_manager_backup_$timestamp.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonString);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出成功！')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        // 加上这个参数可以确保在某些设备上更稳定地返回路径
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final fileInfo = result.files.single;
      String jsonString;

      // 修复逻辑：优先通过路径读取，因为 Android 上 bytes 通常为空
      if (fileInfo.path != null) {
        final file = File(fileInfo.path!);
        jsonString = await file.readAsString();
      } else if (fileInfo.bytes != null) {
        jsonString = utf8.decode(fileInfo.bytes!);
      } else {
        throw Exception('无法获取文件内容');
      }

      _processImport(jsonString);

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e')),
        );
      }
    }
  }

  void _processImport(String jsonString) {
    final data = jsonDecode(jsonString);
    // 清空现有数据
    _taskBox.clear();
    _listBox.clear();

    final List listsJson = data['lists'] ?? [];
    for (var listJson in listsJson) {
      final list = TaskList(
        listJson['id'],
        listJson['name'],
        listJson['iconCodePoint'],
        listJson['colorValue'],
      );
      _listBox.put(list.id, list);
    }

    final List tasksJson = data['tasks'] ?? [];
    for (var taskJson in tasksJson) {
      final task = Task.fromJson(taskJson);
      _taskBox.put(task.id, task);
    }

    _loadData();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入成功！')),
      );
    }
  }

  // ---------- UI 构建 ----------
  Widget _buildIconRail() {
    if (_isMobile) {
      return SafeArea(
        child: Container(
          width: 60,
          color: const Color(0xFFF0F0F2),
          child: Column(
            children: [
              const SizedBox(height: 12),
              IconButton(
                icon: const Icon(Icons.menu, size: 28),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              const SizedBox(height: 20),
              IconButton(
                icon: Icon(Icons.check_box,
                    color: _viewMode == ViewMode.list ? Colors.blue : Colors.black45,
                    size: 28),
                onPressed: () => setState(() {
                  _viewMode = ViewMode.list;
                  _selectedTaskId = null;
                }),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              IconButton(
                icon: Icon(Icons.calendar_month,
                    color: _viewMode == ViewMode.calendar ? Colors.blue : Colors.black45,
                    size: 28),
                onPressed: () => setState(() {
                  _viewMode = ViewMode.calendar;
                  _selectedTaskId = null;
                }),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 60,
      color: const Color(0xFFF0F0F2),
      child: Column(
        children: [
          const SizedBox(height: 20),
          IconButton(
            icon: Icon(Icons.check_box,
                color: _viewMode == ViewMode.list ? Colors.blue : Colors.black45),
            onPressed: () => setState(() {
              _viewMode = ViewMode.list;
              _selectedTaskId = null;
            }),
          ),
          IconButton(
            icon: Icon(Icons.calendar_month,
                color: _viewMode == ViewMode.calendar ? Colors.blue : Colors.black45),
            onPressed: () => setState(() {
              _viewMode = ViewMode.calendar;
              _selectedTaskId = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: Sidebar(
              selectedSmartView: _selectedSmartView,
              selectedListId: _selectedListId,
              showCompleted: _showCompleted,
              countInbox: _countForSmartView(SmartView.inbox),
              countToday: _countForSmartView(SmartView.today),
              countNext7Days: _countForSmartView(SmartView.next7Days),
              completedCount: _completedCount,
              taskLists: _taskLists,
              listTaskCounts: _getListTaskCounts(),
              onSmartViewSelected: (view) {
                Navigator.pop(context);
                setState(() {
                  _selectedSmartView = view;
                  _selectedListId = null;
                  _showCompleted = false;
                });
              },
              onListSelected: (id) {
                Navigator.pop(context);
                setState(() {
                  _selectedListId = id;
                  _selectedSmartView = null;
                  _showCompleted = false;
                });
              },
              onToggleCompleted: () {
                Navigator.pop(context);
                setState(() {
                  _showCompleted = !_showCompleted;
                  if (_showCompleted) {
                    _selectedSmartView = null;
                    _selectedListId = null;
                  }
                });
              },
              onAddList: _addTaskList,
              onEditList: _editTaskList,
              onDeleteList: _deleteTaskList,
            ),
          ),
          // 导入导出按钮（移动端抽屉底部）
          SafeArea(
            child: Column(
              children: [
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('导入数据'),
                  onTap: () {
                    Navigator.pop(context);
                    _importData();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('导出数据'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportData();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Column(
      children: [
        Expanded(
          child: Sidebar(
            selectedSmartView: _selectedSmartView,
            selectedListId: _selectedListId,
            showCompleted: _showCompleted,
            countInbox: _countForSmartView(SmartView.inbox),
            countToday: _countForSmartView(SmartView.today),
            countNext7Days: _countForSmartView(SmartView.next7Days),
            completedCount: _completedCount,
            taskLists: _taskLists,
            listTaskCounts: _getListTaskCounts(),
            onSmartViewSelected: (view) => setState(() {
              _selectedSmartView = view;
              _selectedListId = null;
              _showCompleted = false;
            }),
            onListSelected: (id) => setState(() {
              _selectedListId = id;
              _selectedSmartView = null;
              _showCompleted = false;
            }),
            onToggleCompleted: () => setState(() {
              _showCompleted = !_showCompleted;
              if (_showCompleted) {
                _selectedSmartView = null;
                _selectedListId = null;
              }
            }),
            onAddList: _addTaskList,
            onEditList: _editTaskList,
            onDeleteList: _deleteTaskList,
          ),
        ),
        // 导入导出按钮（桌面端侧边栏底部）
        Column(
          children: [
            const Divider(),
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('导入数据'),
              onTap: _importData,
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('导出数据'),
              onTap: _exportData,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    if (_isMobile && _selectedTask != null) {
      return Column(
        children: [
          SafeArea(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _selectedTaskId = null),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                  const SizedBox(width: 16),
                  const Text('任务详情', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          Expanded(
            child: DetailPane(
              task: _selectedTask!,
              onTitleChanged: (value) => _updateTaskTitle(_selectedTask!.id, value),
              onDescriptionChanged: (value) => _updateTaskDescription(_selectedTask!.id, value),
              taskLists: _taskLists,
              onListChanged: (newListId) => _moveTaskTo(_selectedTask!.id, newListId),
            ),
          ),
        ],
      );
    }

    if (_filteredTasks.isEmpty) {
      return const Center(child: Text('暂无任务'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return TaskItem(
          task: task,
          selected: task.id == _selectedTaskId,
          onTap: () => setState(() => _selectedTaskId = task.id),
          onToggleDone: () => _toggleTaskDone(task.id),
          onMoveTo: (targetListId) => _moveTaskTo(task.id, targetListId),
          taskLists: _taskLists,
        );
      },
    );
  }

  Widget _buildCalendarView() {
    return CalendarView(
      viewMode: _calendarViewMode,
      selectedDate: _selectedDate,
      tasks: _tasks,
      onDateSelected: (date) => setState(() => _selectedDate = date),
      onTaskSelected: (id) => setState(() {
        _selectedTaskId = id;
        _viewMode = ViewMode.list;
      }),
      onViewModeChanged: (mode) => setState(() => _calendarViewMode = mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _isDesktop = screenWidth > 900;
    _isMobile = screenWidth < 600;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _isMobile ? _buildMobileDrawer() : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconRail(),
              if (!_isMobile) const VerticalDivider(width: 1, thickness: 1),
              if (!_isMobile && _viewMode == ViewMode.list)
                SizedBox(
                  width: 260,
                  child: _buildDesktopSidebar(),
                ),
              if (!_isMobile && _viewMode == ViewMode.list)
                const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: _viewMode == ViewMode.list
                    ? _buildTaskList()
                    : _buildCalendarView(),
              ),
              if (_isDesktop && _viewMode == ViewMode.list && _selectedTask != null) ...[
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  flex: 1,
                  child: DetailPane(
                    task: _selectedTask!,
                    onTitleChanged: (value) => _updateTaskTitle(_selectedTask!.id, value),
                    onDescriptionChanged: (value) => _updateTaskDescription(_selectedTask!.id, value),
                    taskLists: _taskLists,
                    onListChanged: (newListId) => _moveTaskTo(_selectedTask!.id, newListId),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: _viewMode == ViewMode.list
          ? FloatingActionButton(onPressed: _showQuickAdd, child: const Icon(Icons.add))
          : null,
    );
  }
}