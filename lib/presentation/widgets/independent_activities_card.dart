import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/ui_confirm.dart';
import '../../domain/entities/activity_item.dart';
import 'add_activity_sheet.dart';

class IndependentActivitiesCard extends StatelessWidget {
  const IndependentActivitiesCard({
    super.key,
    required this.activities,
    required this.onToggleActivity,
    required this.onSkipActivity,
    required this.onDeleteActivity,
    required this.onEditActivity,
    required this.onAddProgressActivity,
    required this.onReorder,
    required this.dateStr,
  });

  final List<ActivityItem> activities;
  final Future<void> Function(ActivityItem, String date) onToggleActivity;
  final Future<void> Function(ActivityItem, String date) onSkipActivity;
  final Future<void> Function(ActivityItem) onDeleteActivity;
  final Future<void> Function(ActivityItem) onEditActivity;
  final Future<void> Function(ActivityItem, String, double) onAddProgressActivity;
  final void Function(ActivityItem movedActivity, int newIndex) onReorder;
  final String dateStr;

  static const _onGradient = TextStyle(
    color: Color(0xFFF2F6FC),
    shadows: [Shadow(offset: Offset(0, 1), blurRadius: 8, color: Colors.black38)],
  );

  String _activitySubtitle(ActivityItem activity, BuildContext context) {
    final List<String> parts = [];
    if (activity.projectName != null && activity.projectName!.isNotEmpty) {
      parts.add('[${activity.projectName}]');
    }
    if (activity.reminderHour != null && activity.reminderMinute != null) {
      parts.add(TimeOfDay(hour: activity.reminderHour!, minute: activity.reminderMinute!).format(context));
    }
    if (activity.description != null && activity.description!.isNotEmpty) {
      parts.add(activity.description!);
    }
    return parts.isEmpty ? 'نشاط حر' : parts.join(' · ');
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'wb_sunny': return Icons.wb_sunny;
      case 'nights_stay': return Icons.nights_stay;
      case 'bedtime': return Icons.bedtime;
      case 'light_mode': return Icons.light_mode;
      case 'star': return Icons.star;
      case 'menu_book': return Icons.menu_book;
      case 'book': return Icons.book;
      case 'translate': return Icons.translate;
      case 'fitness_center': return Icons.fitness_center;
      case 'directions_walk': return Icons.directions_walk;
      case 'water_drop': return Icons.water_drop;
      case 'family_restroom': return Icons.family_restroom;
      case 'group': return Icons.group;
      default: return Icons.task_alt;
    }
  }

  Color _getColorData(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final cardGradient = Theme.of(context).brightness == Brightness.light
        ? const [Color(0xFF80CBC4), Color(0xFF4DB6AC)]
        : const [Color(0xFF004D40), Color(0xFF00695C)];
    final light = Theme.of(context).brightness == Brightness.light;
    
    final titleMed = light
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF142018),
              fontWeight: FontWeight.w700,
            ) ?? const TextStyle(color: Color(0xFF142018), fontWeight: FontWeight.w700)
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
                    child: Text('أنشطة حرة (اليوم)', style: titleMed),
                  ),
                  Icon(Icons.dashboard_customize, color: light ? Colors.black54 : Colors.white70),
                ],
              ),
              const SizedBox(height: 6),
              Text('أنشطة غير مرتبطة بوقت صلاة محدد', style: bodySmall),
              const SizedBox(height: 10),
              
              if (activities.isEmpty)
                Text('لا توجد أنشطة حرة لهذا اليوم', style: bodySmall)
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length,
                  onReorder: (oldIndex, newIndex) {
                    HapticFeedback.selectionClick();
                    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
                    onReorder(activities[oldIndex], adjusted);
                  },
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final isDone = activity.isDoneOn(dateStr);
                    final isSkipped = activity.isSkippedOn(dateStr);
                    
                    return Slidable(
                      key: ValueKey(activity.id),
                      startActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) {
                              HapticFeedback.selectionClick();
                              onToggleActivity(activity, dateStr);
                            },
                            backgroundColor: isDone ? Colors.grey : Colors.green,
                            foregroundColor: Colors.white,
                            icon: isDone ? Icons.undo : Icons.done,
                            label: isDone ? 'تراجع' : 'إنجاز',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          if (!isDone)
                            SlidableAction(
                              onPressed: (_) {
                                HapticFeedback.selectionClick();
                                onSkipActivity(activity, dateStr);
                              },
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              icon: isSkipped ? Icons.undo : Icons.skip_next,
                              label: isSkipped ? 'تراجع عن التخطي' : 'تخطي',
                            ),
                          SlidableAction(
                            onPressed: (_) async {
                              final option = await showActivityDeleteOptions(context, activity.title);
                              if (option == null || !context.mounted) return;
                              switch (option) {
                                case ActivityDeleteOption.skipToday:
                                  onSkipActivity(activity, dateStr);
                                  break;
                                case ActivityDeleteOption.endFuture:
                                  // Archive: we set the endDate to today, but wait: 
                                  // if we set endDate to today, it will not appear tomorrow.
                                  // If the user is on today's view, we might also want to skip it for today? 
                                  // Usually "end future" implies keeping it today or skipping it today.
                                  // Actually, if we set `endDate` to yesterday's date, it won't appear today.
                                  // Let's set it to dateStr (so it doesn't appear after dateStr). But wait, we want it removed TODAY as well?
                                  // The user says "حذف لليوم والمستقبل" (Delete for today and future).
                                  // So the `endDate` should be yesterday (or before dateStr).
                                  final previousDate = DateTime.parse(dateStr).subtract(const Duration(days: 1));
                                  // Format it back to string
                                  final prevStr = "${previousDate.year.toString().padLeft(4, '0')}-${previousDate.month.toString().padLeft(2, '0')}-${previousDate.day.toString().padLeft(2, '0')}";
                                  onEditActivity(activity.copyWith(endDate: prevStr));
                                  break;
                                case ActivityDeleteOption.deleteCompletely:
                                  await onDeleteActivity(activity);
                                  break;
                              }
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'حذف',
                          ),
                          SlidableAction(
                            onPressed: (_) async {
                              final updated = await showModalBottomSheet<ActivityItem>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (ctx) => AddActivitySheet(
                                  initialActivity: activity,
                                  onSave: (act) async {
                                    Navigator.of(ctx).pop(act);
                                    return true;
                                  },
                                ),
                              );
                              if (updated != null) {
                                HapticFeedback.lightImpact();
                                onEditActivity(updated);
                              }
                            },
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label: 'تعديل',
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isDone ? Icons.check_circle : (isSkipped ? Icons.next_plan : Icons.circle_outlined),
                          color: isDone ? Colors.green : (isSkipped ? Colors.orange : null),
                        ),
                        title: Row(
                          children: [
                            if (activity.iconName != null) ...[
                              Icon(
                                _getIconData(activity.iconName!),
                                size: 18,
                                color: activity.colorHex != null ? _getColorData(activity.colorHex!) : null,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                activity.title,
                                style: bodyMed.copyWith(
                                  decoration: (isDone || isSkipped) ? TextDecoration.lineThrough : null,
                                  color: isDone ? taskTitleDone : (isSkipped ? Colors.orange : taskTitleActive),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          _activitySubtitle(activity, context),
                          style: bodySmall.copyWith(
                            color: isDone ? taskSubDone : taskSubActive,
                            decoration: (isDone || isSkipped) ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: activity.isMeasurable
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_formatProgress(activity.getProgressOn(dateStr))} / ${_formatProgress(activity.targetGoal ?? 1)} ${activity.goalUnit ?? ""}',
                                    style: bodySmall,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => _showAddProgressDialog(context, activity, dateStr),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }


  String _formatProgress(double p) {
    return p == p.toInt() ? p.toInt().toString() : p.toStringAsFixed(1);
  }

  Future<void> _showAddProgressDialog(BuildContext context, ActivityItem activity, String date) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة إنجاز: ${activity.title}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'أدخل المقدار (مثال: 5)',
            suffixText: activity.goalUnit,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim()) ?? 0.0;
              if (val > 0) {
                onAddProgressActivity(activity, date, val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
