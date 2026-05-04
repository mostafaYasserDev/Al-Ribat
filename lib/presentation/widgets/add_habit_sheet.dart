import 'package:flutter/material.dart';

import '../../domain/entities/habit_item.dart';

const _kDayShort = <int, String>{
  DateTime.monday: 'إ',
  DateTime.tuesday: 'ث',
  DateTime.wednesday: 'أ',
  DateTime.thursday: 'خ',
  DateTime.friday: 'ج',
  DateTime.saturday: 'س',
  DateTime.sunday: 'ح',
};

class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({
    super.key,
    required this.onSave,
    this.initialHabit,
  });

  final Future<bool> Function(HabitItem habit) onSave;
  final HabitItem? initialHabit;

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TimeOfDay _reminder;
  late bool _notify;
  late bool _everyDay;
  final Set<int> _days = <int>{};

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHabit;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController = TextEditingController(text: initial?.description ?? '');
    _reminder = TimeOfDay(hour: initial?.reminderHour ?? 7, minute: initial?.reminderMinute ?? 30);
    _notify = initial?.notificationsEnabled ?? true;
    final d = initial?.repeatWeekdays ?? const <int>[];
    _everyDay = d.isEmpty;
    _days.addAll(d);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<int> _repeatWeekdaysForSave() {
    if (_everyDay) return const [];
    if (_days.isEmpty) return const [DateTime.friday];
    final list = _days.toList()..sort();
    return list;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialHabit == null ? 'عادة متكررة' : 'تعديل العادة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'اختر الأيام أو «كل الأيام»، ووقت التذكير.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'اسم العادة'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'تفاصيل العادة (اختياري)',
                hintText: 'مثال: قراءة صفحة بعد الصلاة مباشرة',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('كل الأيام'),
              subtitle: const Text('تذكير يومي في نفس الساعة'),
              value: _everyDay,
              onChanged: (v) => setState(() {
                _everyDay = v;
                if (v) _days.clear();
              }),
            ),
            if (!_everyDay) ...[
              const SizedBox(height: 4),
              Text('أيام التذكير', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _kDayShort.entries.map((e) {
                  final sel = _days.contains(e.key);
                  return FilterChip(
                    label: Text(e.value),
                    selected: sel,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _days.add(e.key);
                      } else {
                        _days.remove(e.key);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('إشعار'),
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('وقت التذكير'),
              trailing: Text(_reminder.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _reminder,
                );
                if (picked != null) setState(() => _reminder = picked);
              },
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                if (_titleController.text.trim().isEmpty) return;
                if (!_everyDay && _days.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اختر يوماً واحداً على الأقل')),
                  );
                  return;
                }
                final habit = HabitItem(
                  id: widget.initialHabit?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                  title: _titleController.text.trim(),
                  description: _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
                  reminderHour: _reminder.hour,
                  reminderMinute: _reminder.minute,
                  notificationsEnabled: _notify,
                  createdAt: widget.initialHabit?.createdAt ?? DateTime.now(),
                  repeatWeekdays: _repeatWeekdaysForSave(),
                  lastMarkedDoneDate: widget.initialHabit?.lastMarkedDoneDate,
                );
                final ok = await widget.onSave(habit);
                if (ok && context.mounted) Navigator.of(context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
