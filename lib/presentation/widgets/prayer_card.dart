import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/arabic_duration.dart';
import '../../core/constants/prayer_phase.dart';
import '../../core/prayer_slot_conflict.dart';
import '../../core/ui_confirm.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/habit_item.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/entities/task_item.dart';
import 'add_habit_sheet.dart';

class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.prayer,
    required this.tasks,
    required this.habits,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onEditTask,
    required this.onReorderWithinPhase,
    required this.onMarkHabitDone,
    required this.onClearHabitDone,
    required this.onDeleteHabit,
    required this.onEditHabit,
    this.prayerSchedule,
    this.prayerSlotMinutes,
    this.footerNote,
  });

  final PrayerTime prayer;
  final List<TaskItem> tasks;
  final List<HabitItem> habits;
  final ValueChanged<TaskItem> onToggleTask;
  final Future<void> Function(TaskItem) onDeleteTask;
  final ValueChanged<TaskItem> onEditTask;
  final void Function(TaskItem movedTask, int newIndex) onReorderWithinPhase;
  final Future<void> Function(HabitItem) onMarkHabitDone;
  final Future<void> Function(HabitItem) onClearHabitDone;
  final Future<void> Function(HabitItem) onDeleteHabit;
  final Future<void> Function(HabitItem) onEditHabit;
  final PrayerSchedule? prayerSchedule;
  final int? prayerSlotMinutes;
  final String? footerNote;

  static const _onGradient = TextStyle(
    color: Color(0xFFF2F6FC),
    shadows: [Shadow(offset: Offset(0, 1), blurRadius: 8, color: Colors.black38)],
  );

  String _taskTimeLine(TaskItem task) {
    final base = task.type == TaskType.before ? 'قبل الصلاة' : 'بعد الصلاة';
    if (task.startMinutesFromMidnight == null || task.endMinutesFromMidnight == null) {
      return base;
    }
    final s = task.startMinutesFromMidnight!;
    final e = task.endMinutesFromMidnight!;
    final ds = DateTime(2000, 1, 1, s ~/ 60, s % 60);
    final de = DateTime(2000, 1, 1, e ~/ 60, e % 60);
    return '$base · ${DateFormat.jm('ar').format(ds)} — ${DateFormat.jm('ar').format(de)}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final statusLine = _prayerStatusLine(now);
    final cardGradient = Theme.of(context).brightness == Brightness.light
        ? prayer.phase.lightGradient
        : prayer.phase.gradient;
    final light = Theme.of(context).brightness == Brightness.light;
    final titleMed = light
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF142018),
              fontWeight: FontWeight.w700,
            ) ??
            const TextStyle(color: Color(0xFF142018), fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.titleMedium?.merge(_onGradient) ?? _onGradient;
    final bodyMed = light
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF2C3530)) ??
            const TextStyle(color: Color(0xFF2C3530))
        : Theme.of(context).textTheme.bodyMedium?.merge(_onGradient) ?? _onGradient;
    final bodySmall = light
        ? Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF4A5568)) ??
            const TextStyle(color: Color(0xFF4A5568))
        : Theme.of(context).textTheme.bodySmall?.merge(_onGradient) ?? _onGradient;
    final taskTitleDone = light ? const Color(0xFF8A9590) : const Color(0xFFB8C4D4);
    final taskTitleActive = light ? const Color(0xFF142018) : const Color(0xFFF2F6FC);
    final taskSubDone = light ? const Color(0xFF9AA8A0) : const Color(0xFF9AA8B8);
    final taskSubActive = light ? const Color(0xFF5C6560) : const Color(0xFFD0DAE8);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: cardGradient),
      ),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      prayer.phase.arabicName,
                      style: titleMed,
                    ),
                  ),
                  Text(
                    DateFormat.jm('ar').format(prayer.time),
                    style: bodyMed.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(statusLine, style: bodySmall),
              if (habits.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('عادات في هذه الفترة', style: bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ...habits.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: Colors.black.withValues(alpha: light ? 0.06 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Opacity(
                                opacity: h.isDoneToday ? 0.55 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.title,
                                      style: bodyMed.copyWith(
                                        decoration:
                                            h.isDoneToday ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    Text(
                                      '${TimeOfDay(hour: h.reminderHour, minute: h.reminderMinute).format(context)}'
                                      '${h.description == null ? '' : ' · ${h.description}'}',
                                      style: bodySmall.copyWith(
                                        decoration:
                                            h.isDoneToday ? TextDecoration.lineThrough : null,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'تعديل العادة',
                              icon: Icon(
                                Icons.edit_outlined,
                                color: light ? const Color(0xFF1565C0) : const Color(0xFFE3F2FD),
                              ),
                              onPressed: () async {
                                final updated = await showModalBottomSheet<HabitItem>(
                                  context: context,
                                  isScrollControlled: true,
                                  showDragHandle: true,
                                  builder: (ctx) => AddHabitSheet(
                                    initialHabit: h,
                                    onSave: (habit) async {
                                      Navigator.of(ctx).pop(habit);
                                      return true;
                                    },
                                  ),
                                );
                                if (updated != null) {
                                  await onEditHabit(updated);
                                }
                              },
                            ),
                            if (!h.isDoneToday)
                              IconButton(
                                tooltip: 'تم اليوم',
                                icon: Icon(
                                  Icons.done_outline,
                                  color: light ? const Color(0xFF1F6F4A) : const Color(0xFFE8F5E9),
                                ),
                                onPressed: () => onMarkHabitDone(h),
                              )
                            else
                              IconButton(
                                tooltip: 'إلغاء الإتمام',
                                icon: Icon(
                                  Icons.undo,
                                  color: light ? const Color(0xFF1565C0) : const Color(0xFFE3F2FD),
                                ),
                                onPressed: () => onClearHabitDone(h),
                              ),
                            IconButton(
                              tooltip: 'حذف العادة',
                              icon: Icon(
                                Icons.delete_outline,
                                color: light ? const Color(0xFFC62828) : const Color(0xFFFFE0E0),
                              ),
                              onPressed: () => onDeleteHabit(h),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (tasks.isEmpty)
                Text('لا توجد مهام في هذه المرحلة', style: bodySmall)
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  onReorder: (oldIndex, newIndex) {
                    HapticFeedback.selectionClick();
                    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
                    onReorderWithinPhase(tasks[oldIndex], adjusted);
                  },
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final done = task.isCompleted;
                    return ListTile(
                      key: ValueKey(task.id),
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) {
                          HapticFeedback.selectionClick();
                          onToggleTask(task);
                        },
                      ),
                      title: Text(
                        task.title,
                        style: bodyMed.copyWith(
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? taskTitleDone : taskTitleActive,
                        ),
                      ),
                      subtitle: Text(
                        _taskTimeLine(task),
                        style: bodySmall.copyWith(
                          color: done ? taskSubDone : taskSubActive,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => _onAction(value, task, context),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('تعديل')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                    );
                  },
                ),
              if (footerNote != null && footerNote!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  footerNote!,
                  style: bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _prayerStatusLine(DateTime now) {
    if (prayerSchedule == null) {
      final remaining = prayer.time.difference(now);
      return formatArabicPrayerRemaining(remaining);
    }
    final start = prayer.time;
    DateTime end = prayerSchedule!.tomorrowFajr.time;
    if (prayer.phase == PrayerPhase.fajr) {
      end = prayerSchedule!.todaySunrise;
    } else {
      final idx = prayerSchedule!.today.indexWhere((p) => p.phase == prayer.phase);
      if (idx >= 0 && idx < prayerSchedule!.today.length - 1) {
        end = prayerSchedule!.today[idx + 1].time;
      }
    }

    if (now.isBefore(start)) {
      return 'متبقي ${_formatCompact(start.difference(now))} حتى الأذان';
    }
    if (now.isBefore(end)) {
      return 'دخل وقت الصلاة — ينتهي ${DateFormat.jm('ar').format(end)}';
    }
    return 'انقضى وقت هذه الصلاة';
  }

  String _formatCompact(Duration d) {
    final min = d.inMinutes;
    if (min < 1) return 'أقل من دقيقة';
    final h = min ~/ 60;
    final m = min % 60;
    if (h == 0) return '$m د';
    if (m == 0) return '$h س';
    return '$h س $m د';
  }

  Future<void> _onAction(String value, TaskItem task, BuildContext context) async {
    if (value == 'delete') {
      HapticFeedback.mediumImpact();
      final ok = await confirmDestructiveAction(
        context,
        title: 'حذف المهمة؟',
        message: 'لن يمكن استرجاع «${task.title}».',
      );
      if (ok && context.mounted) {
        await onDeleteTask(task);
      }
      return;
    }

    final updated = await showDialog<TaskItem>(
      context: context,
      builder: (context) => _EditTaskDialog(
        task: task,
        schedule: prayerSchedule,
        slotMinutes: prayerSlotMinutes,
      ),
    );
    if (updated != null) {
      HapticFeedback.lightImpact();
      onEditTask(updated);
    }
  }
}

class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({
    required this.task,
    this.schedule,
    this.slotMinutes,
  });

  final TaskItem task;
  final PrayerSchedule? schedule;
  final int? slotMinutes;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late PrayerPhase _prayer;
  late TaskType _type;
  late bool _useWindow;
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t.title);
    _descriptionController = TextEditingController(text: t.description ?? '');
    _prayer = t.linkedPrayer;
    _type = t.type;
    final sm = t.startMinutesFromMidnight;
    final em = t.endMinutesFromMidnight;
    _useWindow = sm != null && em != null;
    if (_useWindow) {
      _start = TimeOfDay(hour: sm! ~/ 60, minute: sm % 60);
      _end = TimeOfDay(hour: em! ~/ 60, minute: em % 60);
    } else {
      _start = const TimeOfDay(hour: 9, minute: 0);
      _end = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _toM(TimeOfDay td) => td.hour * 60 + td.minute;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل المهمة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'العنوان'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'الوصف'),
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'الصلاة المرتبطة'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PrayerPhase>(
                  isExpanded: true,
                  value: _prayer,
                  items: PrayerPhase.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.arabicName)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _prayer = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TaskType>(
              segments: const [
                ButtonSegment(value: TaskType.before, label: Text('قبل')),
                ButtonSegment(value: TaskType.after, label: Text('بعد')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('نافذة زمنية'),
              value: _useWindow,
              onChanged: (v) => setState(() => _useWindow = v),
            ),
            if (_useWindow) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('بدء'),
                trailing: Text(_start.format(context)),
                onTap: () async {
                  final p = await showTimePicker(context: context, initialTime: _start);
                  if (p != null) setState(() => _start = p);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('انتهاء'),
                trailing: Text(_end.format(context)),
                onTap: () async {
                  final p = await showTimePicker(context: context, initialTime: _end);
                  if (p != null) setState(() => _end = p);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            final sm = _useWindow ? _toM(_start) : null;
            final em = _useWindow ? _toM(_end) : null;
            if (_useWindow && em != null && sm != null && em <= sm) {
              appSnack(context, 'وقت الانتهاء بعد البدء');
              return;
            }
            if (widget.schedule != null &&
                widget.slotMinutes != null &&
                sm != null &&
                em != null) {
              final day = DateTime.now();
              final start = DateTime(day.year, day.month, day.day).add(Duration(minutes: sm));
              final end = DateTime(day.year, day.month, day.day).add(Duration(minutes: em));
              if (prayerSlotOverlaps(
                schedule: widget.schedule!,
                slotMinutes: widget.slotMinutes!,
                rangeStart: start,
                rangeEnd: end,
              )) {
                appSnack(
                  context,
                  'لا يمكن جدولة المهمة داخل وقت الصلاة (${widget.slotMinutes} د بعد الأذان).',
                );
                return;
              }
            }
            Navigator.pop(
              context,
              widget.task.copyWith(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                linkedPrayer: _prayer,
                type: _type,
                startMinutesFromMidnight: sm,
                endMinutesFromMidnight: em,
                clearTimeWindow: !_useWindow,
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
