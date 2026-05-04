import 'package:flutter/material.dart';

import '../../core/constants/prayer_phase.dart';
import '../../core/habit_anchor_phase.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/task_item.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({
    super.key,
    required this.onSave,
    this.schedule,
    this.prayerSlotMinutes = 20,
  });

  /// يُرجع `false` لعدم إغلاق الورقة (مثلاً تعارض مع وقت الصلاة).
  final Future<bool> Function(
    String title,
    String description,
    PrayerPhase prayer,
    TaskType type,
    int? startMinutesFromMidnight,
    int? endMinutesFromMidnight,
    int? reminderMinutesFromMidnight,
  ) onSave;
  final PrayerSchedule? schedule;
  final int prayerSlotMinutes;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  PrayerPhase _selectedPrayer = PrayerPhase.asr;
  TaskType _selectedType = TaskType.after;
  bool _useTimeWindow = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _enableReminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  String? _autoLinkedHint;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now().add(const Duration(minutes: 10));
    _reminderTime = TimeOfDay(hour: n.hour, minute: n.minute);
    _startTime = TimeOfDay(hour: n.hour, minute: n.minute);
    final e = n.add(const Duration(minutes: 45));
    _endTime = TimeOfDay(hour: e.hour, minute: e.minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  void _autoInferPrayerFromMinute(int minuteOfDay) {
    final schedule = widget.schedule;
    if (schedule == null) return;
    final n = DateTime.now();
    final point = DateTime(n.year, n.month, n.day).add(Duration(minutes: minuteOfDay));
    final anchor = anchorPrayerPhaseForPointInDay(schedule, point);
    final prayers = schedule.today;
    final idx = prayers.indexWhere((p) => p.phase == anchor);
    final nextPrayer = (idx >= 0 && idx < prayers.length - 1) ? prayers[idx + 1] : schedule.tomorrowFajr;
    final prevPrayer = idx >= 0 ? prayers[idx] : prayers.first;
    final dPrev = point.difference(prevPrayer.time).abs();
    final dNext = nextPrayer.time.difference(point).abs();
    setState(() {
      if (dNext < dPrev) {
        _selectedPrayer = nextPrayer.phase;
        _selectedType = TaskType.before;
      } else {
        _selectedPrayer = prevPrayer.phase;
        _selectedType = TaskType.after;
      }
      _autoLinkedHint = 'تم الربط تلقائيًا: ${_selectedType == TaskType.before ? 'قبل' : 'بعد'} ${_selectedPrayer.arabicName}';
    });
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
      _autoInferPrayerFromMinute(_toMinutes(picked));
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      _autoInferPrayerFromMinute(_toMinutes(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إضافة مهمة', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'عنوان المهمة'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'وصف (اختياري)'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'بعد / حول أي صلاة'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PrayerPhase>(
                  isExpanded: true,
                  value: _selectedPrayer,
                  items: PrayerPhase.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.arabicName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedPrayer = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<TaskType>(
              segments: const [
                ButtonSegment(value: TaskType.before, label: Text('قبل')),
                ButtonSegment(value: TaskType.after, label: Text('بعد')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (value) => setState(() => _selectedType = value.first),
            ),
            const SizedBox(height: 8),
            if (_autoLinkedHint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _autoLinkedHint!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تفعيل تذكير للمهمة'),
              value: _enableReminder,
              onChanged: (v) => setState(() => _enableReminder = v),
            ),
            if (_enableReminder)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('وقت تذكير المهمة'),
                trailing: Text(_reminderTime.format(context)),
                onTap: _pickReminder,
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('نافذة زمنية للمهمة'),
              subtitle: const Text('حدد وقت البدء والانتهاء في هذا اليوم'),
              value: _useTimeWindow,
              onChanged: (v) => setState(() => _useTimeWindow = v),
            ),
            if (_useTimeWindow) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('وقت البدء'),
                trailing: Text(_startTime.format(context)),
                onTap: _pickStart,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('وقت الانتهاء'),
                trailing: Text(_endTime.format(context)),
                onTap: _pickEnd,
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (_titleController.text.trim().isEmpty) return;
                  final sm = _useTimeWindow ? _toMinutes(_startTime) : null;
                  final em = _useTimeWindow ? _toMinutes(_endTime) : null;
                  final reminderM = _enableReminder ? _toMinutes(_reminderTime) : null;
                  if (_useTimeWindow && sm != null && em != null && em <= sm) {
                    appSnackTop(
                      context,
                      'وقت الانتهاء يجب أن يكون بعد وقت البدء',
                    );
                    return;
                  }
                  final ok = await widget.onSave(
                    _titleController.text.trim(),
                    _descriptionController.text.trim(),
                    _selectedPrayer,
                    _selectedType,
                    sm,
                    em,
                    reminderM,
                  );
                  if (ok && context.mounted) Navigator.of(context).pop();
                },
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
