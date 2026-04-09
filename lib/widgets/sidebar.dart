import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../enums.dart';

class Sidebar extends StatelessWidget {
  final SmartView? selectedSmartView;
  final String? selectedListId;
  final bool showCompleted;
  final int countInbox;
  final int countToday;
  final int countNext7Days;
  final int completedCount;
  final List<TaskList> taskLists;
  final Map<String, int> listTaskCounts;
  final Function(SmartView) onSmartViewSelected;
  final Function(String?) onListSelected;
  final Function() onToggleCompleted;
  final Function() onAddList;
  final Function(TaskList) onEditList;
  final Function(TaskList) onDeleteList;

  const Sidebar({
    Key? key,
    required this.selectedSmartView,
    required this.selectedListId,
    required this.showCompleted,
    required this.countInbox,
    required this.countToday,
    required this.countNext7Days,
    required this.completedCount,
    required this.taskLists,
    required this.listTaskCounts,
    required this.onSmartViewSelected,
    required this.onListSelected,
    required this.onToggleCompleted,
    required this.onAddList,
    required this.onEditList,
    required this.onDeleteList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildSectionTitle('智能视图'),
          const SizedBox(height: 8),
          _buildSmartViewItem(SmartView.inbox, '收集箱', Icons.inbox, countInbox),
          _buildSmartViewItem(SmartView.today, '今天', Icons.today, countToday),
          _buildSmartViewItem(SmartView.next7Days, '最近7天', Icons.date_range, countNext7Days),
          const Divider(height: 32, thickness: 1),
          _buildSectionTitle('清单', action: IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: onAddList,
          )),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: taskLists.length,
              itemBuilder: (context, index) {
                final list = taskLists[index];
                final count = listTaskCounts[list.id] ?? 0;
                return _buildListTile(context, list, count);
              },
            ),
          ),
          const Divider(height: 32, thickness: 1),
          _buildSectionTitle('辅助'),
          _buildAuxiliaryItem(
            Icons.check_circle,
            '已完成',
            onToggleCompleted,
            trailing: completedCount > 0 ? Text('$completedCount') : null,
            selected: showCompleted,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildSmartViewItem(SmartView view, String label, IconData icon, int count) {
    final selected = selectedSmartView == view && !showCompleted;
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.blue : Colors.grey),
      title: Text(label),
      trailing: count > 0 ? Text('$count') : null,
      selected: selected,
      selectedTileColor: Colors.blue.shade50,
      onTap: () => onSmartViewSelected(view),
    );
  }

  Widget _buildListTile(BuildContext context, TaskList list, int count) {
    final selected = selectedListId == list.id;
    return ListTile(
      leading: Icon(list.icon, color: list.color),
      title: Text(list.name),
      trailing: count > 0 ? Text('$count', style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
      selected: selected,
      selectedTileColor: Colors.blue.shade50,
      onTap: () => onListSelected(list.id),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('编辑'),
                    onTap: () {
                      Navigator.pop(context);
                      onEditList(list);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('删除', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      onDeleteList(list);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAuxiliaryItem(IconData icon, String label, VoidCallback onTap,
      {Widget? trailing, bool selected = false}) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.blue : Colors.grey),
      title: Text(label),
      trailing: trailing,
      selected: selected,
      selectedTileColor: Colors.blue.shade50,
      onTap: onTap,
    );
  }
}