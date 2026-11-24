part of '../home_screen.dart';

PrayerTime _currentPrayerFor(
  List<PrayerTime> prayers,
  PrayerPhase currentPhase,
) {
  for (final prayer in prayers) {
    if (prayer.phase == currentPhase) return prayer;
  }
  return prayers.first;
}

PrayerTime _nextPrayerFor(
  PrayerSchedule schedule,
  PrayerPhase currentPhase,
) {
  final idx = schedule.today.indexWhere((p) => p.phase == currentPhase);
  if (idx >= 0 && idx < schedule.today.length - 1) {
    return schedule.today[idx + 1];
  }
  return schedule.tomorrowFajr;
}

String _formatPrayerInterval(DateTime start, DateTime end) {
  var diff = end.difference(start);
  if (diff.isNegative) {
    diff += const Duration(days: 1);
  }
  final hours = diff.inHours;
  final minutes = diff.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) return '$hoursس $minutesد';
  if (hours > 0) return '$hoursس';
  return '$minutesد';
}

void _showAddActivitySheet(
  BuildContext context,
  WidgetRef ref, {
  PrayerPhase? initialPhase,
  bool isIndependent = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => AddActivitySheet(
      initialPhase: isIndependent ? null : initialPhase,
      isIndependentInitial: isIndependent,
      onSave: (activity) async {
        await ref.read(activitiesProvider.notifier).addActivity(activity);
        lightSuccessHaptic();
        if (context.mounted) {
          appSnack(context, 'أُضِيف النشاط — ${MotivationQuotes.randomLine()}');
        }
        return true;
      },
    ),
  );
}
