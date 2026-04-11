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
    required this.displayTime,
    required this.isRunning,
    required this.usePomodoro,
    required this.completedSessions,
    required this.totalFocusSeconds,
    required this.todayFocusSeconds,
    required this.weekFocusSeconds,
    required this.last7DaySeconds,
    required this.onToggleTimer,
    required this.onEndSession,
    required this.onToggleMode,
  });

  final Duration displayTime;
  final bool isRunning;
  final bool usePomodoro;
  final int completedSessions;
  final int totalFocusSeconds;
  final int todayFocusSeconds;
  final int weekFocusSeconds;
  final List<int> last7DaySeconds;
  final VoidCallback onToggleTimer;
  final VoidCallback onEndSession;
  final VoidCallback onToggleMode;

  String _durationLabel(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    const totalSeconds = 25 * 60;
    final mode = usePomodoro ? 'POMODORO' : 'TIMER';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _FocusModeToggle(
              usePomodoro: usePomodoro,
              enabled: !isRunning,
              onTap: onToggleMode,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 50),
            decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
            child: Column(
              children: [
                Text(
                  _durationLabel(displayTime),
                  style: const TextStyle(
                    fontSize: 82,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(isRunning ? 'RUNNING / $mode' : 'READY / $mode',
                    style: NeoBrutalism.label),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _FocusProgressBar(
            displayTime: displayTime,
            usePomodoro: usePomodoro,
            totalPomodoroSeconds: totalSeconds,
          ),
          const SizedBox(height: 34),
          SizedBox(
            width: 300,
            child: Column(
              children: [
                _FocusActionButton(
                  label: 'START',
                  icon: isRunning ? Icons.timer : Icons.play_arrow,
                  onTap: onToggleTimer,
                  isActive: isRunning,
                ),
                const SizedBox(height: 20),
                _FocusActionButton(
                  label: 'END\nSESSION',
                  icon: isRunning ? Icons.stop_outlined : Icons.stop,
                  onTap: onEndSession,
                  isActive: !isRunning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _FocusStatsPanel(
            totalSeconds: totalFocusSeconds,
            todaySeconds: todayFocusSeconds,
            weekSeconds: weekFocusSeconds,
            sessions: completedSessions,
            mode: usePomodoro ? 'POMO' : 'TIME',
            last7DaySeconds: last7DaySeconds,
          ),
        ],
      ),
    );
  }
}

class _FocusProgressBar extends StatelessWidget {
  const _FocusProgressBar({
    required this.displayTime,
    required this.usePomodoro,
    required this.totalPomodoroSeconds,
  });

  final Duration displayTime;
  final bool usePomodoro;
  final int totalPomodoroSeconds;

  String _durationLabel(Duration value) {
    final safeValue = value.isNegative ? Duration.zero : value;
    final hours = safeValue.inHours;
    final minutes = (safeValue.inMinutes % 60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes';
    final seconds = (safeValue.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayElapsed = Duration(
      hours: now.hour,
      minutes: now.minute,
      seconds: now.second,
    );
    const dayTotal = Duration(hours: 24);
    final pomodoroElapsed =
        Duration(seconds: totalPomodoroSeconds) - displayTime;
    final elapsed = usePomodoro ? pomodoroElapsed : dayElapsed;
    final remaining = usePomodoro ? displayTime : dayTotal - dayElapsed;
    final totalSeconds =
        usePomodoro ? totalPomodoroSeconds : dayTotal.inSeconds;
    final progress = (elapsed.inSeconds / totalSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        Container(
          height: 24,
          width: double.infinity,
          decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
          alignment: Alignment.centerLeft,
          child: ClipRect(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value,
                  heightFactor: 1,
                  alignment: Alignment.centerLeft,
                  child: child,
                );
              },
              child: Container(color: NeoBrutalism.yellow),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ELAPSED: ${_durationLabel(elapsed)}',
                style: NeoBrutalism.label),
            Text('REMAINING: ${_durationLabel(remaining)}',
                style: NeoBrutalism.label),
          ],
        ),
      ],
    );
  }
}

class _FocusModeToggle extends StatelessWidget {
  const _FocusModeToggle({
    required this.usePomodoro,
    required this.enabled,
    required this.onTap,
  });

  final bool usePomodoro;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 118,
          height: 38,
          decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: double.infinity,
                  color: usePomodoro ? NeoBrutalism.paper : NeoBrutalism.yellow,
                  child: Center(
                    child: Text('TIME', style: NeoBrutalism.label),
                  ),
                ),
              ),
              Container(width: 2, color: NeoBrutalism.ink),
              Expanded(
                child: Container(
                  height: double.infinity,
                  color: usePomodoro ? NeoBrutalism.yellow : NeoBrutalism.paper,
                  child: Center(
                    child: Text('POMO', style: NeoBrutalism.label),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusActionButton extends StatelessWidget {
  const _FocusActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isActive,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? NeoBrutalism.yellow : NeoBrutalism.paper;
    final decoration = isActive
        ? NeoBrutalism.card(color: color)
        : NeoBrutalism.flatCard(color: color);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: isActive ? 84 : 56,
        width: double.infinity,
        decoration: decoration,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontSize: isActive ? 16 : 13,
            fontWeight: FontWeight.w900,
            letterSpacing: isActive ? 2.7 : 2.0,
            height: 1.22,
            color: NeoBrutalism.ink,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  icon,
                  key: ValueKey<IconData>(icon),
                  size: isActive ? 24 : 18,
                  color: NeoBrutalism.ink,
                ),
              ),
              SizedBox(width: isActive ? 20 : 16),
              Text(label, textAlign: TextAlign.left),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusStatsPanel extends StatelessWidget {
  const _FocusStatsPanel({
    required this.totalSeconds,
    required this.todaySeconds,
    required this.weekSeconds,
    required this.sessions,
    required this.mode,
    required this.last7DaySeconds,
  });

  final int totalSeconds;
  final int todaySeconds;
  final int weekSeconds;
  final int sessions;
  final String mode;
  final List<int> last7DaySeconds;

  String _studyTimeLabel(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours == 0) return '${minutes}M';
    return '${hours}H ${minutes.toString().padLeft(2, '0')}M';
  }

  @override
  Widget build(BuildContext context) {
    final maxSeconds = last7DaySeconds.fold<int>(
      1,
      (maxValue, seconds) => seconds > maxValue ? seconds : maxValue,
    );

    return Container(
      width: double.infinity,
      decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('STUDY STATS', style: NeoBrutalism.label)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: NeoBrutalism.flatCard(color: NeoBrutalism.yellow),
                child: Text(mode, style: NeoBrutalism.label),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: NeoBrutalism.flatCard(color: NeoBrutalism.yellow),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL FOCUS TIME', style: NeoBrutalism.label),
                const SizedBox(height: 8),
                Text(
                  _studyTimeLabel(totalSeconds),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.4,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FocusStat(
                  label: 'TODAY',
                  value: _studyTimeLabel(todaySeconds),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FocusStat(
                  label: '7 DAYS',
                  value: _studyTimeLabel(weekSeconds),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FocusStat(label: 'SESSIONS', value: '#$sessions'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('LAST 7 DAYS', style: NeoBrutalism.label),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(last7DaySeconds.length, (index) {
                final seconds = last7DaySeconds[index];
                final heightFactor = (seconds / maxSeconds).clamp(0.08, 1.0);
                final isToday = index == last7DaySeconds.length - 1;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == last7DaySeconds.length - 1 ? 0 : 4,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: heightFactor,
                              widthFactor: 1,
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                decoration: NeoBrutalism.flatCard(
                                  color: isToday
                                      ? NeoBrutalism.yellow
                                      : NeoBrutalism.cyan,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(isToday ? 'TOD' : '${index + 1}',
                            style: NeoBrutalism.label),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: selected ? 58 : 44,
        margin: EdgeInsets.only(top: selected ? 0 : 7),
        decoration: selected
            ? NeoBrutalism.card(color: NeoBrutalism.yellow)
            : NeoBrutalism.flatCard(color: NeoBrutalism.paper),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: selected ? 12 : 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: NeoBrutalism.ink,
            ),
          ),
        ),
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
