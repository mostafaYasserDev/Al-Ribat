import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/activity_item.dart';
import 'activity_action_tile.dart';

part 'independent_activities_card_styles.dart';

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
  final Future<void> Function(ActivityItem, String, double)
      onAddProgressActivity;
  final void Function(ActivityItem movedActivity, int newIndex) onReorder;
  final String dateStr;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final cardGradient = light
        ? const [Color(0xFF80CBC4), Color(0xFF4DB6AC)]
        : const [Color(0xFF004D40), Color(0xFF00695C)];
    final titleMed = _cardTitleStyle(context, light);
    final bodySmall = _cardBodyStyle(context, light);

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
                  Icon(Icons.dashboard_customize,
                      color: light ? Colors.black54 : Colors.white70),
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
                  onReorderItem: (oldIndex, newIndex) {
                    HapticFeedback.selectionClick();
                    onReorder(activities[oldIndex], newIndex);
                  },
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ActivityActionTile(
                      key: ValueKey(activity.id),
                      activity: activity,
                      dateStr: dateStr,
                      isInsideGradientCard: true,
                      onToggleDone: onToggleActivity,
                      onToggleSkip: onSkipActivity,
                      onDelete: onDeleteActivity,
                      onUpdate: onEditActivity,
                      onAddProgress: onAddProgressActivity,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
