import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';

class FocusLinkedTaskCard extends ConsumerWidget {
  const FocusLinkedTaskCard({
    super.key,
    required this.selectedActivity,
    required this.onSelectActivity,
    required this.onClearActivity,
    this.disabled = false,
  });

  final ActivityItem? selectedActivity;
  final ValueChanged<ActivityItem> onSelectActivity;
  final VoidCallback onClearActivity;
  final bool disabled;

  void _showTaskPicker(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.read(activitiesProvider);
    final activities = activitiesAsync.valueOrNull ?? [];

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
                  'سيتم إضافة دقائق التركيز تلقائياً إلى تقدم المهمة عند انتهائها.',
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
                        return ListTile(
                          title: Text(act.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: act.isMeasurable
                              ? Text(
                                  'هدف قابل للقياس (${act.targetGoal?.toInt() ?? 0} ${act.goalUnit ?? ""})')
                              : Text(act.projectName ?? 'نشاط حر'),
                          leading: Icon(
                            act.isMeasurable
                                ? Icons.track_changes_rounded
                                : Icons.check_circle_outline,
                            color: Theme.of(ctx).colorScheme.primary,
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
            if (!disabled)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClearActivity,
                tooltip: 'إلغاء الربط',
              ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: disabled ? null : () => _showTaskPicker(context, ref),
        icon: const Icon(Icons.add_link_rounded, size: 18),
        label: const Text('ربط جلسة التركيز بمهمة من اليوم',
            style: TextStyle(fontSize: 12.5)),
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
