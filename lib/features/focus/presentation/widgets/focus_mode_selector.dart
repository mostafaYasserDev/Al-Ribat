import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../domain/active_focus_state.dart';
import '../../domain/focus_time_formatter.dart';

/// Instant Apple-style sliding segmented control for switching focus modes.
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

  static const _modes = [
    (
      mode: FocusSessionMode.untilPrayer,
      label: 'حتى الأذان',
      icon: Icons.mosque_rounded,
    ),
    (
      mode: FocusSessionMode.customTimer,
      label: 'مؤقت',
      icon: Icons.timer_outlined,
    ),
    (
      mode: FocusSessionMode.openStopwatch,
      label: 'مفتوح',
      icon: Icons.all_inclusive_rounded,
    ),
  ];

  FocusSessionMode get _effectiveMode =>
      selectedMode == FocusSessionMode.pomodoro
          ? FocusSessionMode.customTimer
          : selectedMode;

  String _subtitle() {
    switch (_effectiveMode) {
      case FocusSessionMode.untilPrayer:
        if (nextPrayerName != null &&
            nextPrayerTime != null &&
            remainingPrayerMinutes != null) {
          final formatted = DateFormat('hh:mm a', 'ar').format(nextPrayerTime!);
          final readable = FocusTimeFormatter.formatDurationReadable(
              remainingPrayerMinutes!);
          return 'الرباط حتى $nextPrayerName ($formatted) · متبقي $readable';
        }
        return 'يضبط المؤقت تلقائياً حتى موعد الصلاة القادمة';
      case FocusSessionMode.pomodoro:
      case FocusSessionMode.customTimer:
        return 'اختر مدة جاهزة أو خصّص الساعات والدقائق';
      case FocusSessionMode.openStopwatch:
        return 'عدّ تصاعدي حر بدون حد زمني';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF0A101D)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72);
    final pillColor = isDark ? const Color(0xFF1D2C46) : Colors.white;
    final selectedIndex = _modes
        .indexWhere((m) => m.mode == _effectiveMode)
        .clamp(0, _modes.length - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 46,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / _modes.length;
                return Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      start: selectedIndex * segmentWidth,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(10.5),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.07),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                      ),
                    ),
                    Row(
                      children: _modes.map((item) {
                        final isSelected = item.mode == _effectiveMode;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (isSelected) return;
                              HapticFeedback.selectionClick();
                              onSelect(item.mode);
                            },
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 16,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? theme.colorScheme.onSurface
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.62),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _subtitle(),
              key: ValueKey(_subtitle()),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
