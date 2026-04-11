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
    final meta = [
      if (list != null) list.name.toUpperCase(),
      _dateLabel(task.date),
    ].join('\n');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: selected
            ? NeoBrutalism.card(color: NeoBrutalism.paper)
            : NeoBrutalism.flatCard(color: NeoBrutalism.paper),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 8, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onToggleDone,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          width: 26,
                          height: 26,
                          decoration: NeoBrutalism.flatCard(
                            color: task.isDone
                                ? NeoBrutalism.ink
                                : NeoBrutalism.paper,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 140),
                            child: task.isDone
                                ? const Icon(Icons.check,
                                    key: ValueKey('done'),
                                    size: 17,
                                    color: NeoBrutalism.yellow)
                                : const SizedBox.shrink(key: ValueKey('open')),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                letterSpacing: 0.2,
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isDone
                                    ? NeoBrutalism.ink.withValues(alpha: 0.55)
                                    : NeoBrutalism.ink,
                              ),
                            ),
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      NeoBrutalism.ink.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 76,
                        child: Text(
                          meta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: NeoBrutalism.ink,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: NeoBrutalism.paper,
                        shape: const RoundedRectangleBorder(
                            side:
                                BorderSide(color: NeoBrutalism.ink, width: 2)),
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
                              value: 'clear', child: Text('移到收件箱')),
                          for (final taskList in taskLists)
                            PopupMenuItem(
                                value: 'list:${taskList.id}',
                                child: Text('移到 ${taskList.name}')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('删除')),
                        ],
                      ),
                    ],
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
    _titleController.addListener(_handleTitleChanged);
    _descController.addListener(_handleDescriptionChanged);
  }

  @override
  void didUpdateWidget(covariant _DetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.id != oldWidget.task.id ||
        widget.task.title != oldWidget.task.title) {
      _syncController(_titleController, widget.task.title);
    }
    if (widget.task.id != oldWidget.task.id ||
        widget.task.description != oldWidget.task.description) {
      _syncController(_descController, widget.task.description);
    }
  }

  void _handleTitleChanged() {
    if (_isComposing(_titleController)) return;
    widget.onTitleChanged(_titleController.text);
  }

  void _handleDescriptionChanged() {
    if (_isComposing(_descController)) return;
    widget.onDescriptionChanged(_descController.text);
  }

  bool _isComposing(TextEditingController controller) {
    final composing = controller.value.composing;
    return composing.isValid && !composing.isCollapsed;
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    if (_isComposing(controller)) return;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    _titleController.removeListener(_handleTitleChanged);
    _descController.removeListener(_handleDescriptionChanged);
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, isMobile ? 14 : 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Center(
              child: Container(
                width: 52,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                color: NeoBrutalism.ink,
              ),
            ),
          ],
          Container(
            width: double.infinity,
            decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('标题',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0)),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
            padding: const EdgeInsets.fromLTRB(18, 6, 14, 6),
            child: DropdownButtonFormField<String?>(
              initialValue: widget.task.listId,
              dropdownColor: NeoBrutalism.paper,
              iconEnabledColor: NeoBrutalism.ink,
              style: const TextStyle(
                color: NeoBrutalism.ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                labelText: '清单',
                labelStyle: TextStyle(
                  color: NeoBrutalism.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('收件箱')),
                ...widget.taskLists.map((list) => DropdownMenuItem<String?>(
                    value: list.id, child: Text(list.name))),
              ],
              onChanged: widget.onListChanged,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: NeoBrutalism.flatCard(color: NeoBrutalism.paper),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('备注',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0)),
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
                        child: Text(_preview ? '编辑' : '预览',
                            style: NeoBrutalism.label),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: isMobile ? 220 : 260,
                  child: _preview
                      ? Markdown(data: _descController.text)
                      : TextField(
                          controller: _descController,
                          textAlignVertical: TextAlignVertical.top,
                          expands: true,
                          maxLines: null,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: NeoBrutalism.ink, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: NeoBrutalism.ink, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: NeoBrutalism.ink, width: 2),
                            ),
                            hintText: '用 Markdown 写备注...',
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

String _dateLabel(DateTime? date) {
  if (date == null) return '无日期';
  return '${date.year}/${date.month}/${date.day}';
}
