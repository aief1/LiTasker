part of 'neo_home_page.dart';

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
        : taskLists.where((item) => item.id == task.listId).firstOrNull;
    final accent =
        task.isDone ? NeoBrutalism.green : _priorityColor(task.priority);

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
                        color: task.isDone
                            ? NeoBrutalism.green
                            : NeoBrutalism.paper,
                      ),
                      child: task.isDone
                          ? const Icon(Icons.close,
                              size: 18, color: NeoBrutalism.ink)
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
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: NeoBrutalism.paper,
                    shape: const RoundedRectangleBorder(
                        side: BorderSide(color: NeoBrutalism.ink, width: 2)),
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                      if (value == 'clear') {
                        onMoveTo(null);
                      }
                      if (value.startsWith('list:')) {
                        onMoveTo(value.substring(5));
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'clear', child: Text('Move to Inbox')),
                      for (final taskList in taskLists)
                        PopupMenuItem(
                            value: 'list:${taskList.id}',
                            child: Text('Move to ${taskList.name}')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
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
                  if (list != null)
                    _Tag(label: list.name.toUpperCase(), color: list.color),
                  _Tag(label: _dateLabel(task.date), color: NeoBrutalism.muted),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(task.description,
                    style: NeoBrutalism.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
  }

  @override
  void didUpdateWidget(covariant _DetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.id != oldWidget.task.id ||
        widget.task.title != oldWidget.task.title) {
      _titleController.text = widget.task.title;
    }
    if (widget.task.id != oldWidget.task.id ||
        widget.task.description != oldWidget.task.description) {
      _descController.text = widget.task.description;
    }
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
                const Text('TITLE',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4)),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  onChanged: widget.onTitleChanged,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: NeoBrutalism.card(
                color: NeoBrutalism.cyan.withValues(alpha: 0.28)),
            padding: const EdgeInsets.all(18),
            child: DropdownButtonFormField<String?>(
              initialValue: widget.task.listId,
              decoration: const InputDecoration(
                  border: InputBorder.none, labelText: 'LIST'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Inbox')),
                ...widget.taskLists.map((list) => DropdownMenuItem<String?>(
                    value: list.id, child: Text(list.name))),
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
                Row(
                  children: [
                    const Text('NOTES',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _preview = !_preview),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: NeoBrutalism.flatCard(
                          color: _preview
                              ? NeoBrutalism.yellow
                              : NeoBrutalism.background,
                        ),
                        child: Text(_preview ? 'EDIT' : 'PREVIEW',
                            style: NeoBrutalism.label),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: _preview
                      ? Markdown(data: _descController.text)
                      : TextField(
                          controller: _descController,
                          onChanged: widget.onDescriptionChanged,
                          expands: true,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Write notes in Markdown...',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

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

Color _priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return NeoBrutalism.pink;
    case TaskPriority.medium:
      return NeoBrutalism.yellow;
    case TaskPriority.low:
      return NeoBrutalism.cyan;
    case TaskPriority.none:
      return NeoBrutalism.muted;
  }
}

String _priorityLabel(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'HIGH';
    case TaskPriority.medium:
      return 'MEDIUM';
    case TaskPriority.low:
      return 'LOW';
    case TaskPriority.none:
      return 'NONE';
  }
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'NO DATE';
  return '${date.year}/${date.month}/${date.day}';
}
