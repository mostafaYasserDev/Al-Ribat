import 'package:flutter/material.dart';

import '../../domain/entities/activity_item.dart';

class ActivityAddProgressSheet extends StatefulWidget {
  const ActivityAddProgressSheet({
    super.key,
    required this.activity,
    required this.dateStr,
    required this.onAdd,
  });

  final ActivityItem activity;
  final String dateStr;
  final Future<void> Function(double addedValue) onAdd;

  static void show(
    BuildContext context, {
    required ActivityItem activity,
    required String dateStr,
    required Future<void> Function(double addedValue) onAdd,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ActivityAddProgressSheet(
        activity: activity,
        dateStr: dateStr,
        onAdd: onAdd,
      ),
    );
  }

  @override
  State<ActivityAddProgressSheet> createState() =>
      _ActivityAddProgressSheetState();
}

class _ActivityAddProgressSheetState extends State<ActivityAddProgressSheet> {
  final _ctrl = TextEditingController(text: '10');
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final val = double.tryParse(_ctrl.text.trim()) ?? 0.0;
    if (val <= 0) return;
    setState(() => _loading = true);
    await widget.onAdd(val);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final act = widget.activity;
    final cur = act.getProgressOn(widget.dateStr);
    final tgt = act.targetGoal ?? 1.0;
    final u = act.goalUnit ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إضافة تقدم: ${act.title}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('المسجل حالياً: ${cur.toInt()} من ${tgt.toInt()} $u',
                style: TextStyle(
                    fontSize: 12.5, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'المقدار المراد إضافته ($u)',
                hintText: 'مثال: 10',
                prefixIcon: const Icon(Icons.add_task_rounded),
                suffixText: u,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [5.0, 10.0, 15.0, 20.0, 30.0].map((q) {
                return ActionChip(
                  label: Text('+${q.toInt()} $u'),
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                  side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.25)),
                  onPressed: () =>
                      setState(() => _ctrl.text = q.toInt().toString()),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('تسجيل التقدم'),
            ),
          ],
        ),
      ),
    );
  }
}
