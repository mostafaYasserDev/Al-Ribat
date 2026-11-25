import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../domain/active_focus_state.dart';
import '../../domain/focus_time_formatter.dart';

class FocusModeSelector extends StatelessWidget {
  const FocusModeSelector({
    super.key,
    required this.selectedMode,
    required this.onSelect,
    this.nextPrayerName,
    this.nextPrayerTime,
    this.remainingPrayerMinutes,
  });

  final FocusSessionMode selectedMode;
  final ValueChanged<FocusSessionMode> onSelect;
  final String? nextPrayerName;
  final DateTime? nextPrayerTime;
  final int? remainingPrayerMinutes;

  IconData _modeIcon(FocusSessionMode mode) {
    switch (mode) {
      case FocusSessionMode.untilPrayer:
        return Icons.mosque_rounded;
      case FocusSessionMode.pomodoro:
      case FocusSessionMode.customTimer:
        return Icons.timer_outlined;
      case FocusSessionMode.openStopwatch:
        return Icons.all_inclusive_rounded;
    }
  }

  String _modeTitle(FocusSessionMode mode) {
    switch (mode) {
      case FocusSessionMode.untilPrayer:
        return nextPrayerName != null
            ? 'الرباط حتى صلاة ${nextPrayerName!}'
            : 'الرباط حتى الأذان';
      case FocusSessionMode.pomodoro:
      case FocusSessionMode.customTimer:
        return 'مؤقت مخصص';
      case FocusSessionMode.openStopwatch:
        return 'ساعة إيقاف مفتوحة';
    }
  }

  String _modeSubtitle(FocusSessionMode mode) {
    switch (mode) {
      case FocusSessionMode.untilPrayer:
        if (nextPrayerTime != null && remainingPrayerMinutes != null) {
          final formatted = DateFormat('hh:mm a', 'ar').format(nextPrayerTime!);
          final readable = FocusTimeFormatter.formatDurationReadable(
              remainingPrayerMinutes!);
          return 'الأذان $formatted · متبقي $readable';
        }
        return 'يضبط المؤقت تلقائياً حتى موعد الصلاة القادمة';
      case FocusSessionMode.pomodoro:
      case FocusSessionMode.customTimer:
        return 'حدد الساعات والدقائق والثواني بدقة أو اختر مدة جاهزة';
      case FocusSessionMode.openStopwatch:
        return 'عدّ تصاعدي حر بدون حد زمني';
    }
  }

  void _openModePicker(BuildContext context) {
    final effective = selectedMode == FocusSessionMode.pomodoro
        ? FocusSessionMode.customTimer
        : selectedMode;

    const modes = [
      FocusSessionMode.untilPrayer,
      FocusSessionMode.customTimer,
      FocusSessionMode.openStopwatch,
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اختر أسلوب الجلسة',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...modes.map((mode) {
                  final isSelected = effective == mode;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelect(mode);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                                  .withValues(alpha: 0.45)
                              : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              child: Icon(
                                _modeIcon(mode),
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _modeTitle(mode),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _modeSubtitle(mode),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded,
                                  color: colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          _openModePicker(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(_modeIcon(selectedMode),
                  color: colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _modeTitle(selectedMode),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _modeSubtitle(selectedMode),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تغيير',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: colorScheme.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
