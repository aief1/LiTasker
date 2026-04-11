part of 'neo_home_page.dart';

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: NeoBrutalism.flatCard(color: color),
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({
    required this.now,
    required this.remaining,
    required this.isRunning,
    required this.isBreakSession,
    required this.completedSessions,
    required this.currentTask,
    required this.onToggleTimer,
    required this.onEndSession,
    required this.onOpenTasks,
  });

  final DateTime now;
  final Duration remaining;
  final bool isRunning;
  final bool isBreakSession;
  final int completedSessions;
  final Task? currentTask;
  final VoidCallback onToggleTimer;
  final VoidCallback onEndSession;
  final VoidCallback onOpenTasks;

  String _timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _durationLabel(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = (isBreakSession ? 5 : 25) * 60;
    final elapsed = totalSeconds - remaining.inSeconds;
    final progress = (elapsed / totalSeconds).clamp(0.0, 1.0);
    final status = isBreakSession ? 'BREAK' : 'FOCUS';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _FocusInfoBlock(
                  label: 'STATUS',
                  value: isRunning ? status : 'PAUSED',
                ),
              ),
              const SizedBox(width: 20),
              _FocusInfoBlock(
                label: 'LOCAL TIME',
                value: _timeLabel(now),
                alignRight: true,
              ),
            ],
          ),
          const SizedBox(height: 34),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 42),
            decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
            child: Column(
              children: [
                Text(
                  _timeLabel(now),
                  style: const TextStyle(
                    fontSize: 68,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _durationLabel(remaining),
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(status, style: NeoBrutalism.label),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 18,
            width: double.infinity,
            decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(color: NeoBrutalism.yellow),
            ),
          ),
          const SizedBox(height: 28),
          _CurrentObjectiveCard(
            task: currentTask,
            onOpenTasks: onOpenTasks,
          ),
          const SizedBox(height: 38),
          SizedBox(
            width: 300,
            child: Column(
              children: [
                _FocusActionButton(
                  label: isRunning ? 'PAUSE' : 'START',
                  icon: isRunning ? Icons.pause : Icons.play_arrow,
                  color: NeoBrutalism.paper,
                  onTap: onToggleTimer,
                ),
                const SizedBox(height: 20),
                _FocusActionButton(
                  label: 'END\nSESSION',
                  icon: Icons.stop,
                  color: NeoBrutalism.yellow,
                  onTap: onEndSession,
                  isTall: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child:
                    _FocusStat(label: 'SESSION', value: '#$completedSessions'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FocusStat(
                  label: 'MODE',
                  value: isBreakSession ? 'REST' : 'WORK',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusInfoBlock extends StatelessWidget {
  const _FocusInfoBlock({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: NeoBrutalism.label),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _CurrentObjectiveCard extends StatelessWidget {
  const _CurrentObjectiveCard({
    required this.task,
    required this.onOpenTasks,
  });

  final Task? task;
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: NeoBrutalism.flatCard(color: NeoBrutalism.yellow),
            child: const Icon(Icons.format_list_bulleted,
                size: 19, color: NeoBrutalism.ink),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURRENT OBJECTIVE', style: NeoBrutalism.label),
                const SizedBox(height: 6),
                Text(
                  task?.title ?? 'No task selected',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOpenTasks,
            icon: const Icon(Icons.edit, color: NeoBrutalism.ink),
          ),
        ],
      ),
    );
  }
}

class _FocusActionButton extends StatelessWidget {
  const _FocusActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isTall = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isTall;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isTall ? 78 : 58,
        width: double.infinity,
        decoration: NeoBrutalism.card(color: color),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: NeoBrutalism.ink),
            const SizedBox(width: 20),
            Text(
              label,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.8,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusStat extends StatelessWidget {
  const _FocusStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: NeoBrutalism.label),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentView, required this.onChange});

  final ViewMode currentView;
  final ValueChanged<ViewMode> onChange;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 82 + bottomInset,
      decoration: const BoxDecoration(
        color: NeoBrutalism.paper,
        border: Border(top: BorderSide(color: NeoBrutalism.ink, width: 2)),
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: _BottomNavItem(
              label: 'FOCUS',
              selected: currentView == ViewMode.focus,
              onTap: () => onChange(ViewMode.focus),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BottomNavItem(
              label: 'TASKS',
              selected: currentView == ViewMode.list,
              onTap: () => onChange(ViewMode.list),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BottomNavItem(
              label: 'CALENDAR',
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
        height: 48,
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
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 132),
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
                      child: Container(
                          width: 110, height: 110, color: NeoBrutalism.pink)),
                  Positioned(
                    right: 34,
                    top: 38,
                    child: Transform.rotate(
                      angle: 0.7,
                      child: Container(
                          width: 42, height: 42, color: NeoBrutalism.cyan),
                    ),
                  ),
                  Container(
                      width: 94,
                      height: 116,
                      decoration:
                          NeoBrutalism.flatCard(color: NeoBrutalism.yellow)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('EMPTY',
                style: TextStyle(
                    fontSize: 48, fontWeight: FontWeight.w900, height: 0.95)),
            const SizedBox(height: 20),
            Container(width: 3, height: 96, color: NeoBrutalism.ink),
            const SizedBox(height: 20),
            const Text(
              'Tap the plus button to create your first task.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
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
  final void Function(String, DateTime?, TaskPriority, DateTime?, String?)
      onAdd;

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
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                const Text('Quick Add',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Container(
                  decoration:
                      NeoBrutalism.flatCard(color: NeoBrutalism.background),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900),
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'What needs to be done?'),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: selected
                            ? NeoBrutalism.card(color: _priorityColor(priority))
                            : NeoBrutalism.flatCard(
                                color: _priorityColor(priority)),
                        child: Text(priority.name.toUpperCase(),
                            style: NeoBrutalism.label),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: NeoBrutalism.flatCard(
                              color: NeoBrutalism.background),
                          child: Text(
                            _date == null
                                ? 'Select date'
                                : '${_date!.year}/${_date!.month}/${_date!.day}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: NeoBrutalism.flatCard(
                            color: NeoBrutalism.background),
                        child: DropdownButton<String?>(
                          value: _listId,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          hint: const Text('Choose list'),
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null, child: Text('Inbox')),
                            ...widget.allLists.map((list) {
                              return DropdownMenuItem<String?>(
                                  value: list.id, child: Text(list.name));
                            }),
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
                            label: 'Cancel',
                            onTap: () => Navigator.pop(context))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SmallActionButton(
                        label: 'Add Task',
                        color: NeoBrutalism.yellow,
                        onTap: () {
                          final title = _controller.text.trim();
                          if (title.isEmpty) return;
                          widget.onAdd(title, _date, _priority, null, _listId);
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
