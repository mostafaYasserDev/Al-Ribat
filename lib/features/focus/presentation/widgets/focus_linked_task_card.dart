import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import '../../application/active_focus_notifier.dart';

class FocusLinkedTaskCard extends ConsumerWidget {
  const FocusLinkedTaskCard({
    super.key,
    required this.selectedActivity,
    required this.onSelectActivity,
    required this.onClearActivity,
    this.disabled = false,
    this.buttonLabel = 'ربط جلسة التركيز بمهمة من اليوم',
  });

  final ActivityItem? selectedActivity;
  final ValueChanged<ActivityItem> onSelectActivity;
  final VoidCallback onClearActivity;
  final bool disabled;
  final String buttonLabel;

  void _showTaskPicker(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.read(activitiesProvider);
    final raw = activitiesAsync.valueOrNull ?? [];
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Sort pending tasks first, completed tasks after
    final activities = List<ActivityItem>.from(raw)
      ..sort((a, b) {
        final aDone = a.isDoneOn(todayStr) ? 1 : 0;
        final bDone = b.isDoneOn(todayStr) ? 1 : 0;
        return aDone.compareTo(bDone);
      });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ربط الجلسة بمهمة من اليوم',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'المهام اليومية تُنجز تلقائياً، والمهام الزمنية يُضاف إليها وقت التركيز الفعلي.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                if (activities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('لا توجد مهام مسجلة لهذا اليوم')),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 340),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: activities.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final act = activities[i];
                        final isDone = act.isDoneOn(todayStr);
                        final String subtitleText;
                        if (act.isMeasurable) {
                          final isTime =
                              ActiveFocusNotifier.isTimeMeasuredActivity(act);
                          final unit = act.goalUnit ?? '';
                          subtitleText =
                              'هدف: ${act.targetGoal?.toInt() ?? 0} $unit'
                              '${isTime ? ' (تحديث زمني تلقائي)' : ' (توثيق في السجل)'}';
                        } else {
                          subtitleText = act.projectName ?? 'مهمة يومية';
                        }

                        return ListTile(
                          title: Text(
                            act.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                              color: isDone
                                  ? Theme.of(ctx).colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                          subtitle: Text(subtitleText,
                              style: const TextStyle(fontSize: 12)),
                          leading: Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : (act.isMeasurable
                                    ? Icons.track_changes_rounded
                                    : Icons.radio_button_unchecked_rounded),
                            color: isDone
                                ? Colors.green
                                : Theme.of(ctx).colorScheme.primary,
                          ),
                          onTap: () {
                            onSelectActivity(act);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (selectedActivity != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.link_rounded, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'مهمة مرتبطة بالتركيز',
                    style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    selectedActivity!.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!disabled) ...[
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                onPressed: () => _showTaskPicker(context, ref),
                tooltip: 'تغيير المهمة',
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClearActivity,
                tooltip: 'إلغاء الربط',
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: disabled ? null : () => _showTaskPicker(context, ref),
        icon: const Icon(Icons.add_link_rounded, size: 18),
        label: Text(buttonLabel, style: const TextStyle(fontSize: 12.5)),
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        ),
      ),
    );
  }
}
