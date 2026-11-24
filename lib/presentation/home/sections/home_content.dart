part of '../home_screen.dart';

Widget _buildHomeContent({
  required BuildContext context,
  required WidgetRef ref,
  required PrayerSchedule schedule,
  required List<ActivityItem> activities,
  required DayState dayState,
  required DateTime selectedDate,
  required String todayStr,
  required PrayerPhase? selectedPhase,
  required ValueChanged<PrayerPhase> onSelectPhase,
  required ValueChanged<PrayerPhase> onAddForPhase,
  required VoidCallback onAddIndependent,
}) {
  final prayers = schedule.today;
  if (prayers.isEmpty) {
    return const Center(child: Text('لا تتوفر بيانات للصلاة اليوم.'));
  }

  final currentPrayer = _currentPrayerFor(prayers, dayState.currentPrayerPhase);
  final nextPrayer = _nextPrayerFor(schedule, dayState.currentPrayerPhase);

  final light = Theme.of(context).brightness == Brightness.light;
  final bgColors = light
      ? const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)]
      : const [Color(0xFF071320), Color(0xFF0A1B2A)];

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: bgColors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final maxContentWidth =
            constraints.maxWidth > 650 ? 650.0 : constraints.maxWidth;
        return Center(
          child: SizedBox(
            width: maxContentWidth,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _buildDateHeader(context, ref, selectedDate),
                const SizedBox(height: 12),
                _HomeUnifiedPrayerHeader(
                  schedule: schedule,
                  currentPrayer: currentPrayer,
                  nextPrayer: nextPrayer,
                  currentPhase: dayState.currentPrayerPhase,
                  selectedPhase: selectedPhase,
                  activities: activities,
                  selectedDate: selectedDate,
                  onSelectPhase: onSelectPhase,
                  light: light,
                ),
                const SizedBox(height: 16),
                _HomeSelectedActivitiesSection(
                  ref: ref,
                  activities: activities,
                  selectedDate: selectedDate,
                  todayStr: todayStr,
                  selectedPhase: selectedPhase,
                  onAddForPhase: onAddForPhase,
                ),
                _HomeIndependentActivitiesSection(
                  ref: ref,
                  activities: activities,
                  selectedDate: selectedDate,
                  todayStr: todayStr,
                  onAddIndependent: onAddIndependent,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
