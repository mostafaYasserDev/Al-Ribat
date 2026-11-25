import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import '../../application/active_focus_notifier.dart';

class FocusLinkedTaskCard extends ConsumerStatefulWidget {
  const FocusLinkedTaskCard({
    super.key,
    required this.selectedActivity,
    required this.onSelectActivity,
    required this.onClearActivity,
    this.disabled = false,
    this.buttonLabel = 'ربط الجلسة بمهمة من اليوم',
  });

  final ActivityItem? selectedActivity;
  final ValueChanged<ActivityItem> onSelectActivity;
  final VoidCallback onClearActivity;
  final bool disabled;
  final String buttonLabel;

  @override
  ConsumerState<FocusLinkedTaskCard> createState() =>
      _FocusLinkedTaskCardState();
}

class _FocusLinkedTaskCardState extends ConsumerState<FocusLinkedTaskCard> {
  bool _pressed = false;

  void _showTaskPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    final activitiesAsync = ref.read(activitiesProvider);
    final raw = activitiesAsync.valueOrNull ?? [];
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final activities = List<ActivityItem>.from(raw)
      ..sort((a, b) {
        final aDone = a.isDoneOn(todayStr) ? 1 : 0;
        final bDone = b.isDoneOn(todayStr) ? 1 : 0;
        return aDone.compareTo(bDone);
      });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final sheetBg = theme.cardTheme.color ??
            (isDark ? const Color(0xFF111B2E) : Colors.white);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: Material(
              color: sheetBg,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ربط الجلسة بمهمة من اليوم',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'المهام اليومية تُنجز تلقائياً، والزمنية يُضاف إليها وقت التركيز.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.58),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 0.6,
                    thickness: 0.6,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  if (activities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('لا توجد مهام مسجلة لهذا اليوم'),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: activities.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 0.6,
                          thickness: 0.6,
                          indent: 56,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.07),
                        ),
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
                                    ? theme.colorScheme.onSurfaceVariant
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              subtitleText,
                              style: const TextStyle(fontSize: 12),
                            ),
                            leading: Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : (act.isMeasurable
                                      ? Icons.track_changes_rounded
                                      : Icons.radio_button_unchecked_rounded),
                              color: isDone
                                  ? const Color(0xFF34C759)
                                  : theme.colorScheme.primary,
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onSelectActivity(act);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final selected = widget.selectedActivity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: Material(
          color: selected != null
              ? colorScheme.primary.withValues(alpha: isDark ? 0.14 : 0.08)
              : cardColor,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onHighlightChanged: (v) {
              if (!widget.disabled && _pressed != v) {
                setState(() => _pressed = v);
              }
            },
            onTap: widget.disabled ? null : () => _showTaskPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected != null
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : colorScheme.onSurface
                          .withValues(alpha: isDark ? 0.08 : 0.07),
                  width: 0.7,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (selected != null
                              ? colorScheme.primary
                              : const Color(0xFF007AFF))
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      selected != null
                          ? Icons.link_rounded
                          : Icons.add_link_rounded,
                      size: 18,
                      color: selected != null
                          ? colorScheme.primary
                          : const Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: selected != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'مهمة مرتبطة',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                selected.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : Text(
                            widget.buttonLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                  ),
                  if (!widget.disabled && selected != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        widget.onClearActivity();
                      },
                      tooltip: 'إلغاء الربط',
                      visualDensity: VisualDensity.compact,
                    )
                  else if (!widget.disabled)
                    Icon(
                      Icons.chevron_left_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
