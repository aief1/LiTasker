import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../utils/priority_color.dart';

class DetailPane extends StatefulWidget {
  final Task task;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;
  final List<TaskList> taskLists;
  final Function(String? listId) onListChanged;

  const DetailPane({
    super.key,
    required this.task,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.taskLists,
    required this.onListChanged,
  });

  @override
  State<DetailPane> createState() => _DetailPaneState();
}

class _DetailPaneState extends State<DetailPane> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  bool _isPreview = false; // 预览模式开关

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
  }

  @override
  void didUpdateWidget(covariant DetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.id != oldWidget.task.id) {
      _titleController.text = widget.task.title;
      _descController.text = widget.task.description;
    } else {
      if (widget.task.title != _titleController.text) {
        _titleController.text = widget.task.title;
      }
      if (widget.task.description != _descController.text) {
        _descController.text = widget.task.description;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _insertMarkdown(String left, String right) {
    final text = _descController.text;
    final selection = _descController.selection;
    String newText;
    TextSelection newSelection;

    if (selection.isCollapsed) {
      final cursorPos = selection.start;
      newText = text.substring(0, cursorPos) + left + right + text.substring(cursorPos);
      newSelection = TextSelection.collapsed(offset: cursorPos + left.length);
    } else {
      final selected = text.substring(selection.start, selection.end);
      newText = text.substring(0, selection.start) +
          left + selected + right +
          text.substring(selection.end);
      newSelection = TextSelection.collapsed(offset: selection.end + left.length + right.length);
    }

    _descController.text = newText;
    _descController.selection = newSelection;
    widget.onDescriptionChanged(newText);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          TextField(
            controller: _titleController,
            onChanged: widget.onTitleChanged,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
          const SizedBox(height: 16),
          // 清单选择
          DropdownButton<String>(
            value: widget.task.listId,
            hint: const Text('未分类'),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('未分类'),
              ),
              ...widget.taskLists.map((list) {
                return DropdownMenuItem<String>(
                  value: list.id,
                  child: Row(
                    children: [
                      Icon(list.icon, size: 16, color: list.color),
                      const SizedBox(width: 8),
                      Text(list.name),
                    ],
                  ),
                );
              }).toList(),
            ],
            onChanged: widget.onListChanged,
          ),
          const SizedBox(height: 16),
          // 备注区域
          Expanded(
            child: isMobile
                ? _buildMobileNoteArea()
                : _buildDesktopNoteArea(),
          ),
          const SizedBox(height: 16),
          // 日期和优先级
          Text(
            widget.task.date != null
                ? '日期：${widget.task.date!.month}月${widget.task.date!.day}日'
                : '日期：无',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('优先级：'),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: getPriorityColor(widget.task.priority),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 桌面端：编辑器和预览并排
  Widget _buildDesktopNoteArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildEditor()),
        const SizedBox(width: 16),
        Expanded(child: _buildPreview()),
      ],
    );
  }

  // 移动端：编辑器和预览切换
  Widget _buildMobileNoteArea() {
    return Column(
      children: [
        Expanded(
          child: _isPreview ? _buildPreview() : _buildEditor(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
              label: Text(_isPreview ? '编辑' : '预览'),
              onPressed: () => setState(() => _isPreview = !_isPreview),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('备注', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.format_bold, size: 20),
              onPressed: () => _insertMarkdown('**', '**'),
              tooltip: '加粗',
            ),
            IconButton(
              icon: const Icon(Icons.format_italic, size: 20),
              onPressed: () => _insertMarkdown('*', '*'),
              tooltip: '斜体',
            ),
            IconButton(
              icon: const Icon(Icons.looks_one, size: 20),
              onPressed: () => _insertMarkdown('# ', ''),
              tooltip: '一级标题',
            ),
            IconButton(
              icon: const Icon(Icons.looks_two, size: 20),
              onPressed: () => _insertMarkdown('## ', ''),
              tooltip: '二级标题',
            ),
            IconButton(
              icon: const Icon(Icons.list, size: 20),
              onPressed: () => _insertMarkdown('- ', ''),
              tooltip: '无序列表',
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '输入 Markdown 语法',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TextField(
            controller: _descController,
            onChanged: widget.onDescriptionChanged,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: '添加备注...',
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _descController.text.isEmpty
          ? const Center(
        child: Text(
          '暂无备注',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : Markdown(
        data: _descController.text,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          strong: const TextStyle(fontWeight: FontWeight.bold),
          em: const TextStyle(fontStyle: FontStyle.italic),
          listBullet: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}