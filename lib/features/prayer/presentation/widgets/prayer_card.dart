import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:al_ribat/core/arabic_duration.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';
import 'package:al_ribat/features/prayer/domain/prayer_schedule.dart';
import 'package:al_ribat/features/prayer/domain/prayer_time.dart';
import 'package:al_ribat/presentation/widgets/activity_action_tile.dart';

class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.prayer,
    required this.activities,
    required this.onToggleActivity,
    required this.onSkipActivity,
    required this.onDeleteActivity,
    required this.onEditActivity,
    required this.onAddProgressActivity,
    required this.onReorderWithinPhase,
    required this.dateStr,
    this.prayerSchedule,
    this.footerNote,
  });

  final PrayerTime prayer;
  final List<ActivityItem> activities;
  final Future<void> Function(ActivityItem, String date) onToggleActivity;
  final Future<void> Function(ActivityItem, String date) onSkipActivity;
  final Future<void> Function(ActivityItem) onDeleteActivity;
  final Future<void> Function(ActivityItem) onEditActivity;
  final Future<void> Function(ActivityItem, String, double)
      onAddProgressActivity;
  final void Function(ActivityItem movedActivity, int newIndex)
      onReorderWithinPhase;
  final String dateStr;
  final PrayerSchedule? prayerSchedule;
  final String? footerNote;

  static const _onGradient = TextStyle(
    color: Color(0xFFF2F6FC),
    shadows: [
      Shadow(offset: Offset(0, 1), blurRadius: 8, color: Colors.black38)
    ],
  );

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
            const TextStyle(
                color: Color(0xFF142018), fontWeight: FontWeight.w700)
        : Theme.of(context)
                .textTheme
                .titleMedium
                ?.merge(PrayerCard._onGradient) ??
            PrayerCard._onGradient;
    final bodyMed = light
        ? Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF2C3530)) ??
            const TextStyle(color: Color(0xFF2C3530))
        : Theme.of(context)
                .textTheme
                .bodyMedium
                ?.merge(PrayerCard._onGradient) ??
            PrayerCard._onGradient;
    final bodySmall = light
        ? Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFF4A5568)) ??
            const TextStyle(color: Color(0xFF4A5568))
        : Theme.of(context)
                .textTheme
                .bodySmall
                ?.merge(PrayerCard._onGradient) ??
            PrayerCard._onGradient;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: cardGradient),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(prayer.phase.arabicName, style: titleMed),
              const Spacer(),
              Text(DateFormat.jm('ar').format(prayer.time), style: bodyMed),
            ],
          ),
          const SizedBox(height: 6),
          Text(statusLine, style: bodySmall),
          if (footerNote != null) ...[
            const SizedBox(height: 4),
            Text(footerNote!, style: bodySmall),
          ],
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildActivitiesList(context),
          ],
        ],
      ),
    );
  }
}
