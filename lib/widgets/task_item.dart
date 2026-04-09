import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../utils/priority_color.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final Function(String?) onMoveTo;
  final List<TaskList> taskLists;

  const TaskItem({
    super.key,
    required this.task,
    required this.selected,
    required this.onTap,
    required this.onToggleDone,
    required this.onMoveTo,
    required this.taskLists,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: widget.selected
              ? Colors.transparent
              : _isHovered
              ? Colors.grey.shade100
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: widget.selected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ]
              : null,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isMobile ? 12 : 8,
          ),
          leading: GestureDetector(
            onTap: widget.onToggleDone,
            child: _buildTickBox(),
          ),
          title: Text(
            widget.task.title,
            style: TextStyle(
              fontSize: 15,
              decoration: widget.task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
              color: widget.task.isDone ? Colors.grey : const Color(0xFF333333),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: widget.task.date != null
              ? Text(
            _formatDate(widget.task.date!),
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            overflow: TextOverflow.ellipsis,
          )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.task.listId != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _buildListIcon(),
                ),
              // 更多操作菜单（包含编辑、删除、移动）
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                tooltip: '更多操作',
                onSelected: (value) {
                  if (value == 'edit') {
                    widget.onTap();
                  } else if (value == 'delete') {
                    // 删除逻辑
                  } else if (value == 'move') {
                    _showMoveMenu(context);
                  } else if (value.startsWith('move_')) {
                    final listId = value.substring(5);
                    widget.onMoveTo(listId == 'null' ? null : listId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'move',
                    child: Row(
                      children: [
                        Icon(Icons.drive_file_move, size: 18),
                        SizedBox(width: 8),
                        Text('移动到'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }

  void _showMoveMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('未分类'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onMoveTo(null);
                },
              ),
              ...widget.taskLists.map((list) {
                return ListTile(
                  leading: Icon(list.icon, color: list.color),
                  title: Text(list.name),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onMoveTo(list.id);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTickBox() {
    final color = getPriorityColor(widget.task.priority);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(6),
        color: widget.task.isDone ? color : Colors.transparent,
      ),
      child: widget.task.isDone
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _buildListIcon() {
    final list = widget.taskLists.firstWhere(
          (l) => l.id == widget.task.listId,
      orElse: () => TaskList.withIcon(
        id: '',
        name: '',
        icon: Icons.label,
        color: Colors.grey,
      ),
    );
    return Icon(list.icon, size: 14, color: list.color);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(today).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    return '${date.month}月${date.day}日';
  }
}