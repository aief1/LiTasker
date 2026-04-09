import 'package:flutter/material.dart';
import '../models/task.dart';
import '../enums.dart';
import '../utils/priority_color.dart';

class CalendarView extends StatelessWidget {
  final CalendarViewMode viewMode;
  final DateTime selectedDate;
  final List<Task> tasks;
  final Function(DateTime) onDateSelected;
  final Function(String) onTaskSelected;
  final Function(CalendarViewMode) onViewModeChanged; // 新增

  const CalendarView({
    Key? key,
    required this.viewMode,
    required this.selectedDate,
    required this.tasks,
    required this.onDateSelected,
    required this.onTaskSelected,
    required this.onViewModeChanged, // 新增
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: SegmentedButton<CalendarViewMode>(
                  segments: const [
                    ButtonSegment(value: CalendarViewMode.month, label: Text('月'), icon: Icon(Icons.calendar_view_month)),
                    ButtonSegment(value: CalendarViewMode.week, label: Text('周'), icon: Icon(Icons.calendar_view_week)),
                    ButtonSegment(value: CalendarViewMode.day, label: Text('日'), icon: Icon(Icons.calendar_view_day)),
                  ],
                  selected: {viewMode},
                  onSelectionChanged: (Set<CalendarViewMode> newSelection) {
                    onViewModeChanged(newSelection.first); // 调用回调
                  },
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        Expanded(
          child: _buildView(),
        ),
      ],
    );
  }

  Widget _buildView() {
    switch (viewMode) {
      case CalendarViewMode.month:
        return MonthView(
          selectedDate: selectedDate,
          tasks: tasks,
          onDateSelected: onDateSelected,
          onTaskSelected: onTaskSelected,
        );
      case CalendarViewMode.week:
        return WeekView(
          selectedDate: selectedDate,
          tasks: tasks,
          onTaskSelected: onTaskSelected,
        );
      case CalendarViewMode.day:
        return DayView(
          selectedDate: selectedDate,
          tasks: tasks,
          onTaskSelected: onTaskSelected,
        );
    }
  }
}

class MonthView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Task> tasks;
  final Function(DateTime) onDateSelected;
  final Function(String) onTaskSelected;

  const MonthView({
    Key? key,
    required this.selectedDate,
    required this.tasks,
    required this.onDateSelected,
    required this.onTaskSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = selectedDate;
    final first = DateTime(now.year, now.month, 1);
    final startWeekday = first.weekday % 7; // 周一为0
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${now.year}年 ${now.month}月',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: isMobile ? 0.8 : 1.0, // 移动端稍高一点
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox();
              final day = index - startWeekday + 1;
              final cellDate = DateTime(now.year, now.month, day);

              final dayTasks = tasks.where((t) =>
              t.date != null &&
                  t.date!.year == cellDate.year &&
                  t.date!.month == cellDate.month &&
                  t.date!.day == cellDate.day).toList();

              // 限制显示任务数量，避免溢出
              final displayTasks = dayTasks.take(3).toList();
              final hasMore = dayTasks.length > 3;

              return GestureDetector(
                onTap: () => onDateSelected(cellDate),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$day',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      ...displayTasks.map((task) => GestureDetector(
                        onTap: () => onTaskSelected(task.id),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: getPriorityColor(task.priority).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.title,
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )),
                      if (hasMore)
                        const Text(
                          '...',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class WeekView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Task> tasks;
  final Function(String) onTaskSelected;

  const WeekView({
    Key? key,
    required this.selectedDate,
    required this.tasks,
    required this.onTaskSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = selectedDate;
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    final weekDates = List.generate(7, (index) => monday.add(Duration(days: index)));

    return TimeGrid(
      dates: weekDates,
      title: '${weekDates.first.month}月${weekDates.first.day}日 - ${weekDates.last.month}月${weekDates.last.day}日',
      tasks: tasks,
      onTaskSelected: onTaskSelected,
    );
  }
}

class DayView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Task> tasks;
  final Function(String) onTaskSelected;

  const DayView({
    Key? key,
    required this.selectedDate,
    required this.tasks,
    required this.onTaskSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TimeGrid(
      dates: [selectedDate],
      title: '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日',
      tasks: tasks,
      onTaskSelected: onTaskSelected,
    );
  }
}

class TimeGrid extends StatelessWidget {
  final List<DateTime> dates;
  final String title;
  final List<Task> tasks;
  final Function(String) onTaskSelected;

  const TimeGrid({
    Key? key,
    required this.dates,
    required this.title,
    required this.tasks,
    required this.onTaskSelected,
  }) : super(key: key);

  List<Task> getTasksForDate(DateTime date) {
    return tasks.where((task) {
      if (task.date == null) return false;
      return task.date!.year == date.year &&
          task.date!.month == date.month &&
          task.date!.day == date.day;
    }).toList();
  }

  int getTaskDurationMinutes(Task task) {
    if (task.endDate != null) {
      return task.endDate!.difference(task.date!).inMinutes;
    }
    return 30;
  }

  @override
  Widget build(BuildContext context) {
    const hourHeight = 60.0;
    const totalHeight = 24 * hourHeight;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧时间轴标签
                SizedBox(
                  width: 50,
                  child: Column(
                    children: List.generate(24, (hour) {
                      return SizedBox(
                        height: hourHeight,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4, top: 2),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // 右侧日期列
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dates.map((date) {
                      final dayTasks = getTasksForDate(date);
                      return Expanded(
                        child: Container(
                          height: totalHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade300),
                              right: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // 背景网格线
                              ...List.generate(24, (hour) {
                                return Positioned(
                                  top: hour * hourHeight,
                                  left: 0,
                                  right: 0,
                                  child: Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                );
                              }),
                              // 任务卡片
                              ...dayTasks.map((task) {
                                final taskDate = task.date!;
                                final startMinutes = taskDate.hour * 60 + taskDate.minute;
                                // 计算top，限制在0到totalHeight之间
                                double top = startMinutes * (hourHeight / 60);
                                top = top.clamp(0.0, totalHeight - 2.0);
                                final durationMinutes = getTaskDurationMinutes(task);
                                double taskHeight = durationMinutes * (hourHeight / 60);
                                taskHeight = taskHeight < 10.0 ? 10.0 : taskHeight; // 最小高度10px

                                return Positioned(
                                  top: top,
                                  left: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      // 调试输出，确保点击被捕获
                                      print('Task tapped: ${task.title} (id: ${task.id})');
                                      onTaskSelected(task.id);
                                    },
                                    child: Container(
                                      height: taskHeight,
                                      decoration: BoxDecoration(
                                        color: getPriorityColor(task.priority).withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}