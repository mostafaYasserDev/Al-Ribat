part of '../home_screen.dart';

class _HomeUnifiedPrayerHeader extends StatelessWidget {
  const _HomeUnifiedPrayerHeader({
    required this.schedule,
    required this.currentPrayer,
    required this.nextPrayer,
    required this.currentPhase,
    required this.selectedPhase,
    required this.activities,
    required this.selectedDate,
    required this.onSelectPhase,
    required this.light,
  });

  final PrayerSchedule schedule;
  final PrayerTime currentPrayer;
  final PrayerTime nextPrayer;
  final PrayerPhase currentPhase;
  final PrayerPhase? selectedPhase;
  final List<ActivityItem> activities;
  final DateTime selectedDate;
  final ValueChanged<PrayerPhase> onSelectPhase;
  final bool light;

  IconData _iconForPhase(PrayerPhase phase) {
    switch (phase) {
      case PrayerPhase.fajr:
        return Icons.wb_twilight_rounded;
      case PrayerPhase.dhuhr:
        return Icons.wb_sunny_rounded;
      case PrayerPhase.asr:
        return Icons.filter_drama_rounded;
      case PrayerPhase.maghrib:
        return Icons.wb_twilight_rounded;
      case PrayerPhase.isha:
        return Icons.bedtime_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = nextPrayer.time.difference(now);
    final totalSpan = nextPrayer.time.difference(currentPrayer.time);
    final elapsed = now.difference(currentPrayer.time);

    final double progress = totalSpan.inSeconds > 0
        ? (elapsed.inSeconds / totalSpan.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remainingFormatted = ArabicTimeFormatter.formatRemaining(remaining);

    final gradientColors = light
        ? currentPrayer.phase.lightGradient
        : currentPrayer.phase.gradient;

    final todayPrayers = schedule.today;
    final activePhase = selectedPhase ?? currentPhase;

    final activePrayer = todayPrayers.firstWhere(
      (p) => p.phase == activePhase,
      orElse: () => currentPrayer,
    );

    final activeIdx = todayPrayers.indexWhere((p) => p.phase == activePhase);
    final PrayerTime nextOfActive =
        (activeIdx >= 0 && activeIdx < todayPrayers.length - 1)
            ? todayPrayers[activeIdx + 1]
            : schedule.tomorrowFajr;

    final intervalStr =
        _formatPrayerInterval(activePrayer.time, nextOfActive.time);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: (light ? Colors.blueGrey.shade200 : Colors.black)
                .withValues(alpha: light ? 0.3 : 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top live prayer status row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: light
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForPhase(currentPrayer.phase),
                  size: 20,
                  color: light ? colorScheme.primary : Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رباط ما بعد ${currentPrayer.phase.arabicName}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: light ? colorScheme.onSurface : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$remainingFormatted حتى أذان ${nextPrayer.phase.arabicName}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            light ? colorScheme.primary : Colors.amber.shade200,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mini progress bar for elapsed prayer time
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: light
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                light ? colorScheme.primary : colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Level 1: 5 Prayer Buttons (100% Width, Spacious & Comfortable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: light
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                for (final prayer in todayPrayers)
                  Expanded(
                    child: _buildPrayerButton(
                      context,
                      prayer,
                      selectedPhase == prayer.phase,
                      currentPhase == prayer.phase,
                      colorScheme,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Level 2: Dedicated Interval & Duration Bar for the Selected Prayer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: light
                  ? Colors.white.withValues(alpha: 0.75)
                  : Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (light ? colorScheme.outlineVariant : Colors.white12)
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timelapse_rounded,
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
                            color: light ? colorScheme.onSurface : Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: intervalStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: light
                                ? colorScheme.primary
                                : Colors.amber.shade200,
                          ),
                        ),
                        TextSpan(
                          text: activePhase == currentPhase
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
        ],
      ),
    );
  }

  Widget _buildPrayerButton(
    BuildContext context,
    PrayerTime prayer,
    bool isSelected,
    bool isNow,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelectPhase(prayer.phase);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : (isNow
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : (isNow
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.7),
                      width: 1.2,
                    )
                  : null),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForPhase(prayer.phase),
              size: 20,
              color: isSelected
                  ? colorScheme.onPrimary
                  : (isNow
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              prayer.phase.arabicName,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected || isNow ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimary
                    : (isNow ? colorScheme.primary : colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('h:mm', 'ar').format(prayer.time),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimary.withValues(alpha: 0.9)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
