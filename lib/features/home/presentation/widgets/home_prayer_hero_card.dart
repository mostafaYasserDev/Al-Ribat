import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/arabic_duration.dart';
import '../../../../core/constants/prayer_phase.dart';
import '../../../../domain/entities/activity_item.dart';
import '../../../../domain/entities/prayer_schedule.dart';
import '../../../../domain/entities/prayer_time.dart';

/// Distinct icon & signature color for each prayer phase.
({IconData icon, Color color}) prayerPhaseVisual(PrayerPhase phase) {
  switch (phase) {
    case PrayerPhase.fajr:
      return (icon: Icons.wb_twilight_rounded, color: const Color(0xFF3B82F6));
    case PrayerPhase.dhuhr:
      return (icon: Icons.light_mode_rounded, color: const Color(0xFFF59E0B));
    case PrayerPhase.asr:
      return (icon: Icons.brightness_6_rounded, color: const Color(0xFFFF9500));
    case PrayerPhase.maghrib:
      return (icon: Icons.nights_stay_rounded, color: const Color(0xFFF43F5E));
    case PrayerPhase.isha:
      return (icon: Icons.dark_mode_rounded, color: const Color(0xFF7C3AED));
  }
}

String formatPrayerInterval(DateTime start, DateTime end) {
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

class HomePrayerHeroCard extends StatelessWidget {
  const HomePrayerHeroCard({
    super.key,
    required this.schedule,
    required this.currentPrayer,
    required this.nextPrayer,
    required this.currentPhase,
    required this.selectedPhase,
    required this.activities,
    required this.selectedDate,
    required this.todayStr,
    required this.onSelectPhase,
  });

  final PrayerSchedule schedule;
  final PrayerTime currentPrayer;
  final PrayerTime nextPrayer;
  final PrayerPhase currentPhase;
  final PrayerPhase selectedPhase;
  final List<ActivityItem> activities;
  final DateTime selectedDate;
  final String todayStr;
  final ValueChanged<PrayerPhase> onSelectPhase;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final remaining = nextPrayer.time.difference(now);
    final totalSpan = nextPrayer.time.difference(currentPrayer.time);
    final elapsed = now.difference(currentPrayer.time);
    final double progress = (isToday && totalSpan.inSeconds > 0)
        ? (elapsed.inSeconds / totalSpan.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final colorScheme = theme.colorScheme;
    final remainingFormatted = ArabicTimeFormatter.formatRemaining(remaining);

    final gradientColors = light
        ? currentPrayer.phase.lightGradient
        : currentPrayer.phase.gradient;
    final currentVisual = prayerPhaseVisual(currentPrayer.phase);

    final todayPrayers = schedule.today;
    final activePrayer = todayPrayers.firstWhere(
      (p) => p.phase == selectedPhase,
      orElse: () => currentPrayer,
    );
    final activeIdx = todayPrayers.indexWhere((p) => p.phase == selectedPhase);
    final PrayerTime nextOfActive =
        (activeIdx >= 0 && activeIdx < todayPrayers.length - 1)
            ? todayPrayers[activeIdx + 1]
            : schedule.tomorrowFajr;
    final intervalStr =
        formatPrayerInterval(activePrayer.time, nextOfActive.time);

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          border: Border.all(
            color: light
                ? colorScheme.primary.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.1),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (light ? Colors.blueGrey.shade200 : Colors.black)
                  .withValues(alpha: light ? 0.25 : 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: light
                        ? currentVisual.color.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    currentVisual.icon,
                    size: 21,
                    color: light ? currentVisual.color : Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رباط ما بعد ${currentPrayer.phase.arabicName}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: light ? colorScheme.onSurface : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isToday
                            ? '$remainingFormatted حتى أذان ${nextPrayer.phase.arabicName}'
                            : 'مواقيت ${DateFormat('EEEE d MMMM', 'ar').format(selectedDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: light
                              ? colorScheme.primary
                              : Colors.amber.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => LinearProgressIndicator(
                  value: val,
                  minHeight: 4.5,
                  backgroundColor: light
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    light ? colorScheme.primary : colorScheme.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SlidingPrayerDock(
              prayers: todayPrayers,
              selectedPhase: selectedPhase,
              currentPhase: currentPhase,
              light: light,
              onSelectPhase: onSelectPhase,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: light
                    ? Colors.white.withValues(alpha: 0.78)
                    : Colors.black.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: (light ? colorScheme.outlineVariant : Colors.white12)
                      .withValues(alpha: 0.4),
                  width: 0.6,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Row(
                  key: ValueKey(selectedPhase),
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: light ? colorScheme.primary : Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  'من ${activePrayer.phase.arabicName} إلى ${nextOfActive.phase.arabicName}: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: light
                                    ? colorScheme.onSurface
                                    : Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: intervalStr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: light
                                    ? colorScheme.primary
                                    : Colors.amber.shade200,
                              ),
                            ),
                            TextSpan(
                              text: selectedPhase == currentPhase
                                  ? '  •  متبقي $remainingFormatted'
                                  : '  (حتى ${DateFormat.jm('ar').format(nextOfActive.time)})',
                              style: TextStyle(
                                fontSize: 11,
                                color: light
                                    ? colorScheme.onSurfaceVariant
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidingPrayerDock extends StatelessWidget {
  const _SlidingPrayerDock({
    required this.prayers,
    required this.selectedPhase,
    required this.currentPhase,
    required this.light,
    required this.onSelectPhase,
  });

  final List<PrayerTime> prayers;
  final PrayerPhase selectedPhase;
  final PrayerPhase currentPhase;
  final bool light;
  final ValueChanged<PrayerPhase> onSelectPhase;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedIdx =
        prayers.indexWhere((p) => p.phase == selectedPhase).clamp(0, 4);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.88)
            : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(17),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segWidth = constraints.maxWidth / prayers.length;
          return SizedBox(
            height: 70,
            child: Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  start: selectedIdx * segWidth,
                  top: 0,
                  bottom: 0,
                  width: segWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: prayers.map((prayer) {
                    final isSelected = prayer.phase == selectedPhase;
                    final isNow = prayer.phase == currentPhase;
                    final visual = prayerPhaseVisual(prayer.phase);

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (isSelected) return;
                          HapticFeedback.selectionClick();
                          onSelectPhase(prayer.phase);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              visual.icon,
                              size: 19,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : visual.color,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              prayer.phase.arabicName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected || isNow
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : (light
                                        ? colorScheme.onSurface
                                        : Colors.white),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isNow)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsetsDirectional.only(
                                      end: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : const Color(0xFF34C759),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  DateFormat('h:mm', 'ar').format(prayer.time),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                            .withValues(alpha: 0.9)
                                        : (light
                                            ? colorScheme.onSurfaceVariant
                                            : Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
