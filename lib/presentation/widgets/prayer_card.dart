import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/arabic_duration.dart';
import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/prayer_time.dart';
import 'activity_action_tile.dart';

part 'prayer_card_view.dart';
part 'prayer_card_details.dart';

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

  @override
  Widget build(BuildContext context) => _buildPrayerCard(context);
}
