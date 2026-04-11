part of 'neo_home_page.dart';

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
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 18,
        vertical: 16,
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu, color: NeoBrutalism.ink))
          else
            const Icon(Icons.dashboard_customize_outlined,
                color: NeoBrutalism.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LITASKER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSwitchView,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 14,
                vertical: 10,
              ),
              decoration: NeoBrutalism.flatCard(
                  color: isCalendar ? NeoBrutalism.cyan : NeoBrutalism.paper),
              child: Text(isCalendar ? 'LIST' : 'CALENDAR',
                  style: NeoBrutalism.label),
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
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeoBrutalism.card(color: NeoBrutalism.paper),
            child: const Text('Navigation',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 22),
          const Text('SMART VIEWS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0)),
          const SizedBox(height: 12),
          _NavTile(
            label: 'Inbox',
            count: countInbox,
            color: NeoBrutalism.paper,
            selected: selectedSmartView == SmartView.inbox && !showCompleted,
            onTap: () => onSmartViewSelected(SmartView.inbox),
          ),
          _NavTile(
            label: 'Today',
            count: countToday,
            color: NeoBrutalism.cyan,
            selected: selectedSmartView == SmartView.today && !showCompleted,
            onTap: () => onSmartViewSelected(SmartView.today),
          ),
          _NavTile(
            label: 'Next 7 Days',
            count: countNext7,
            color: NeoBrutalism.yellow,
            selected:
                selectedSmartView == SmartView.next7Days && !showCompleted,
            onTap: () => onSmartViewSelected(SmartView.next7Days),
          ),
          const SizedBox(height: 22),
          const Text('LISTS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0)),
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
            label: 'Completed',
            count: completedCount,
            color: NeoBrutalism.pink,
            selected: showCompleted,
            onTap: onCompletedSelected,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _SmallActionButton(label: 'Import', onTap: onImport)),
              const SizedBox(width: 10),
              Expanded(
                  child: _SmallActionButton(
                      label: 'Export',
                      onTap: onExport,
                      color: NeoBrutalism.yellow)),
            ],
          ),
        ],
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
                child: Text(label.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15))),
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
    required this.isMobile,
    required this.onSelectTask,
    required this.onToggleDone,
    required this.onMoveTask,
    required this.onDeleteTask,
  });

  final String title;
  final List<Task> tasks;
  final List<TaskList> taskLists;
  final String? selectedTaskId;
  final bool isMobile;
  final ValueChanged<String> onSelectTask;
  final ValueChanged<String> onToggleDone;
  final void Function(String, String?) onMoveTask;
  final ValueChanged<String> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const _EmptyState();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: isMobile
                ? const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    color: NeoBrutalism.ink,
                  )
                : NeoBrutalism.hero,
          ),
          const SizedBox(height: 8),
          Text(
            'Build momentum with small wins and clear priorities.',
            maxLines: isMobile ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0),
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
