part of 'neo_home_page.dart';

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
    final daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
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
                  '${_monthName(selectedDate.month)} ${selectedDate.year}',
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
                onTap: () => onDateSelected(
                    DateTime(selectedDate.year, selectedDate.month - 1, 1)),
              ),
              const SizedBox(width: 10),
              _MonthSwitchButton(
                icon: Icons.chevron_right,
                onTap: () => onDateSelected(
                    DateTime(selectedDate.year, selectedDate.month + 1, 1)),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: item == mode
                            ? NeoBrutalism.card(color: NeoBrutalism.yellow)
                            : NeoBrutalism.flatCard(color: NeoBrutalism.paper),
                        child: Text(_calendarModeLabel(item),
                            style: NeoBrutalism.label),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: mode == CalendarViewMode.month
                ? (isMobile
                    ? _buildMobileMonthView(
                        startOffset, daysInMonth, selectedTasks)
                    : _buildDesktopMonthView(
                        startOffset, daysInMonth, selectedTasks))
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

  Widget _buildMobileMonthView(
      int startOffset, int daysInMonth, List<Task> selectedTasks) {
    return ListView(
      children: [
        _buildMonthGrid(startOffset, daysInMonth, fillHeight: false),
        const SizedBox(height: 20),
        _buildSummaryCard(selectedTasks),
        const SizedBox(height: 20),
        _buildStatusCard(),
      ],
    );
  }

  Widget _buildDesktopMonthView(
      int startOffset, int daysInMonth, List<Task> selectedTasks) {
    return Row(
      children: [
        Expanded(
            flex: 3,
            child: _buildMonthGrid(startOffset, daysInMonth, fillHeight: true)),
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

  Widget _buildMonthGrid(int startOffset, int daysInMonth,
      {required bool fillHeight}) {
    final grid = GridView.builder(
      shrinkWrap: !fillHeight,
      physics: fillHeight
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
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
                Text('$day',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: isMobile ? 15 : 20)),
                const Spacer(),
                for (final task in dayTasks.take(isMobile ? 1 : 2))
                  Container(
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      color: _priorityColor(task.priority)),
              ],
            ),
          ),
        );
      },
    );

    return Container(
      decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const Row(
            children: [
              _WeekdayLabel('一'),
              _WeekdayLabel('二'),
              _WeekdayLabel('三'),
              _WeekdayLabel('四'),
              _WeekdayLabel('五'),
              _WeekdayLabel('六'),
              _WeekdayLabel('日'),
            ],
          ),
          const SizedBox(height: 8),
          if (fillHeight) Expanded(child: grid) else grid,
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
          Text('${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          if (selectedTasks.isEmpty)
            const Text('这一天没有任务',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                    decoration:
                        NeoBrutalism.flatCard(color: NeoBrutalism.paper),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(task.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900))),
                        Container(
                            width: 12,
                            height: 12,
                            color: _priorityColor(task.priority)),
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
    final completed = tasks.where((task) => task.isDone).length;
    final pending = tasks.where((task) => !task.isDone).length;
    final planned = tasks.where((task) => task.date != null).length;

    return Container(
      width: double.infinity,
      decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StatusChip(label: '已完成 $completed', color: NeoBrutalism.green),
          _StatusChip(label: '待办 $pending', color: NeoBrutalism.cyan),
          _StatusChip(label: '已安排 $planned', color: NeoBrutalism.yellow),
        ],
      ),
    );
  }

  List<Task> _tasksForDate(DateTime date) {
    return tasks
        .where((task) => task.date != null && _sameDate(task.date, date))
        .toList();
  }

  bool _sameDate(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[month - 1];
  }

  String _calendarModeLabel(CalendarViewMode value) {
    switch (value) {
      case CalendarViewMode.month:
        return '月';
      case CalendarViewMode.week:
        return '周';
      case CalendarViewMode.day:
        return '日';
    }
  }
}

class _CalendarAgenda extends StatelessWidget {
  const _CalendarAgenda({
    required this.selectedDate,
    required this.tasks,
    required this.mode,
    required this.onDateSelected,
    required this.onTaskSelected,
  });

  final DateTime selectedDate;
  final List<Task> tasks;
  final CalendarViewMode mode;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<String> onTaskSelected;

  @override
  Widget build(BuildContext context) {
    final dates = mode == CalendarViewMode.week
        ? List.generate(7, (index) {
            final monday =
                selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
            return monday.add(Duration(days: index));
          })
        : [selectedDate];

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: isSelected
                        ? NeoBrutalism.card(color: NeoBrutalism.yellow)
                        : NeoBrutalism.flatCard(color: NeoBrutalism.paper),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_weekday(date.weekday), style: NeoBrutalism.label),
                        const SizedBox(height: 6),
                        Text('${date.month}/${date.day}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900)),
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
          final dayTasks = tasks
              .where((task) => task.date != null && _sameDate(task.date, date))
              .toList();
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
                  Text('${_weekday(date.weekday)} ${date.month}/${date.day}',
                      style: NeoBrutalism.title),
                  const SizedBox(height: 14),
                  if (dayTasks.isEmpty)
                    const Text('没有任务',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ...dayTasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => onTaskSelected(task.id),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: NeoBrutalism.flatCard(
                              color: NeoBrutalism.background),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(task.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900))),
                              Container(
                                  width: 12,
                                  height: 12,
                                  color: _priorityColor(task.priority)),
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

  bool _sameDate(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekday(int weekday) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return labels[weekday - 1];
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

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
