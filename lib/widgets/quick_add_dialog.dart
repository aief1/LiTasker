import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../utils/priority_color.dart';

Future<void> showQuickAddDialog(
    BuildContext context, {
      required void Function(String title, DateTime? date, TaskPriority priority, DateTime? endDate, String? listId) onAdd,
      String? currentListId,
      List<TaskList>? allLists, // 可选，传入所有清单用于选择
    }) async {
  final controller = TextEditingController();
  TaskPriority selectedPriority = TaskPriority.none;
  DateTime? selectedDate; // 初始为 null
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? selectedListId = currentListId; // 默认选中当前清单

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          // 确保日期不为 null（如果为 null 则设为今天）
          void ensureDate() {
            if (selectedDate == null) {
              setModalState(() {
                selectedDate = DateTime.now();
              });
            }
          }

          // 构建开始时间
          DateTime? getStartDateTime() {
            if (selectedDate == null) return null;
            return DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
              startTime?.hour ?? 0,
              startTime?.minute ?? 0,
            );
          }

          // 构建结束时间
          DateTime? getEndDateTime() {
            if (selectedDate == null || endTime == null) return null;
            return DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
              endTime!.hour,
              endTime!.minute,
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '准备做什么？',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 12),
                // 优先级选择
                Row(
                  children: [
                    const Text('优先级：'),
                    const SizedBox(width: 8),
                    ...TaskPriority.values.map((priority) {
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedPriority = priority),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: getPriorityColor(priority),
                            shape: BoxShape.circle,
                            border: selectedPriority == priority
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                          child: selectedPriority == priority
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 12),
                // 清单选择（如果提供了清单列表）
                if (allLists != null && allLists.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text('清单：'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedListId,
                          hint: const Text('未分类'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('未分类'),
                            ),
                            ...allLists.map((list) {
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
                          onChanged: (value) {
                            setModalState(() {
                              selectedListId = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // 日期选择
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) setModalState(() => selectedDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selectedDate == null
                                ? '选择日期'
                                : '${selectedDate!.month}月${selectedDate!.day}日',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selectedDate == null
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 开始时间和结束时间
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          ensureDate(); // 若无日期则设为今天
                          final time = await _showTimePickerDialog(context,
                              initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0));
                          if (time != null) setModalState(() => startTime = time);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            startTime == null ? '开始时间' : startTime!.format(context),
                            style: TextStyle(
                              color: startTime == null ? Colors.grey : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          ensureDate(); // 若无日期则设为今天
                          final time = await _showTimePickerDialog(context,
                              initialTime: endTime ?? startTime ?? const TimeOfDay(hour: 9, minute: 0));
                          if (time != null) setModalState(() => endTime = time);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            endTime == null ? '结束时间' : endTime!.format(context),
                            style: TextStyle(
                              color: endTime == null ? Colors.grey : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isEmpty) return;

                        DateTime? startDateTime;
                        // 如果用户没有选择任何日期和时间，则使用今天日期，时间为00:00
                        if (selectedDate == null && startTime == null && endTime == null) {
                          startDateTime = DateTime.now();
                          startDateTime = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
                        } else {
                          // 至少有一项被选择，确保日期不为 null
                          if (selectedDate == null) {
                            selectedDate = DateTime.now();
                          }
                          startDateTime = getStartDateTime();
                        }

                        final endDateTime = getEndDateTime();

                        onAdd(
                          controller.text.trim(),
                          startDateTime,
                          selectedPriority,
                          endDateTime,
                          selectedListId, // 使用选中的清单ID
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('添加'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<TimeOfDay?> _showTimePickerDialog(BuildContext context, {required TimeOfDay initialTime}) async {
  final initialDuration = Duration(hours: initialTime.hour, minutes: initialTime.minute);
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    builder: (context) {
      Duration selectedDuration = initialDuration;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    minuteInterval: 30,
                    initialTimerDuration: selectedDuration,
                    onTimerDurationChanged: (Duration newDuration) {
                      setSheetState(() {
                        selectedDuration = newDuration;
                      });
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      TimeOfDay(
                        hour: selectedDuration.inHours.remainder(24),
                        minute: selectedDuration.inMinutes.remainder(60),
                      ),
                    );
                  },
                  child: const Text('确认'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}