part of 'prayer_card.dart';

extension _PrayerCardDetails on PrayerCard {
  Widget _buildActivitiesList(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: activities.length,
      onReorderItem: (oldIndex, newIndex) {
        final item = activities[oldIndex];
        onReorderWithinPhase(item, newIndex);
      },
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Row(
          key: ValueKey(activity.id),
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_handle, color: Colors.grey, size: 20),
              ),
            ),
            Expanded(
              child: ActivityActionTile(
                activity: activity,
                dateStr: dateStr,
                isInsideGradientCard: true,
                onToggleDone: onToggleActivity,
                onToggleSkip: onSkipActivity,
                onDelete: onDeleteActivity,
                onUpdate: onEditActivity,
                onAddProgress: onAddProgressActivity,
              ),
            ),
          ],
        );
      },
    );
  }

  String _prayerStatusLine(DateTime now) {
    final start = prayer.time;
    DateTime end;
    if (prayerSchedule != null) {
      final list = prayerSchedule!.today;
      final idx = list.indexWhere((p) => p.phase == prayer.phase);
      if (idx >= 0 && idx < list.length - 1) {
        end = list[idx + 1].time;
      } else {
        end = prayerSchedule!.tomorrowFajr.time;
      }
    } else {
      end = start.add(const Duration(hours: 3));
    }

    if (now.isBefore(start)) {
      return 'متبقي ${ArabicTimeFormatter.formatRemaining(start.difference(now))} حتى الأذان';
    }
    if (now.isBefore(end)) {
      return 'دخل وقت الصلاة — ينتهي ${DateFormat.jm('ar').format(end)}';
    }
    return 'انقضى وقت هذه الصلاة';
  }
}
