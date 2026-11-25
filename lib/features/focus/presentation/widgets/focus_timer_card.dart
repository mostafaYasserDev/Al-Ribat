import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../domain/active_focus_state.dart';
import '../../domain/focus_time_formatter.dart';

class FocusTimerCard extends StatelessWidget {
  const FocusTimerCard({
    super.key,
    required this.selectedMode,
    required this.selectedSeconds,
    required this.isPomodoroPreset,
    required this.displayTime,
    required this.isActive,
    required this.isPaused,
    required this.progress,
    required this.onSelectPreset,
    required this.onDurationSecondsChanged,
    this.activeTitle,
    this.nextPrayerName,
    this.nextPrayerTime,
    this.remainingPrayerMinutes,
  });

  final FocusSessionMode selectedMode;
  final int selectedSeconds;
  final bool isPomodoroPreset;
  final String displayTime;
  final bool isActive;
  final bool isPaused;
  final double progress;
  final void Function(int minutes, {bool isPomodoro}) onSelectPreset;
  final ValueChanged<int> onDurationSecondsChanged;
  final String? activeTitle;
  final String? nextPrayerName;
  final DateTime? nextPrayerTime;
  final int? remainingPrayerMinutes;

  static const _presets = <({int minutes, String label, bool isPomodoro})>[
    (minutes: 15, label: '15د', isPomodoro: false),
    (minutes: 25, label: '25د بومودورو', isPomodoro: true),
    (minutes: 45, label: '45د', isPomodoro: false),
    (minutes: 60, label: '1س', isPomodoro: false),
    (minutes: 90, label: '1س 30د', isPomodoro: false),
    (minutes: 120, label: '2س', isPomodoro: false),
  ];

  void _openDurationPicker(BuildContext context) {
    var hours = selectedSeconds ~/ 3600;
    var minutes = (selectedSeconds % 3600) ~/ 60;
    var seconds = selectedSeconds % 60;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final totalSec =
                ((hours * 3600) + (minutes * 60) + seconds).clamp(1, 28800);
            final theme = Theme.of(ctx);
            final colorScheme = theme.colorScheme;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تحديد مدة الجلسة',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        FocusTimeFormatter.formatCountdown(totalSec),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _UnitStepper(
                            label: 'ساعات',
                            value: hours,
                            min: 0,
                            max: 8,
                            onChanged: (v) => setModalState(() => hours = v),
                          ),
                          _colonSeparator(theme, colorScheme),
                          _UnitStepper(
                            label: 'دقائق',
                            value: minutes,
                            min: 0,
                            max: 59,
                            onChanged: (v) => setModalState(() => minutes = v),
                          ),
                          _colonSeparator(theme, colorScheme),
                          _UnitStepper(
                            label: 'ثوانٍ',
                            value: seconds,
                            min: (hours == 0 && minutes == 0) ? 1 : 0,
                            max: 59,
                            onChanged: (v) => setModalState(() => seconds = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onDurationSecondsChanged(totalSec);
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'اعتماد المدة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _colonSeparator(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accentColor = isPaused ? Colors.orange : colorScheme.primary;
    final showCustomControls = !isActive &&
        (selectedMode == FocusSessionMode.customTimer ||
            selectedMode == FocusSessionMode.pomodoro);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? accentColor.withValues(alpha: 0.45)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeaderBadge(context, accentColor),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              displayTime,
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: isPaused
                    ? Colors.orange
                    : (isActive ? accentColor : colorScheme.onSurface),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _buildSubtitle(),
            style: TextStyle(
              fontSize: 12.5,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (isActive) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: selectedMode == FocusSessionMode.openStopwatch
                    ? null
                    : progress,
                minHeight: 8,
                color: accentColor,
                backgroundColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (showCustomControls) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _presets.map((preset) {
                final isSelected = selectedSeconds == preset.minutes * 60 &&
                    isPomodoroPreset == preset.isPomodoro;
                return ChoiceChip(
                  label: Text(preset.label),
                  selected: isSelected,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    onSelectPreset(preset.minutes,
                        isPomodoro: preset.isPomodoro);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _openDurationPicker(context),
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: const Text('تخصيص الساعات والدقائق والثواني'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(BuildContext context, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    String text;
    IconData icon;

    if (isActive) {
      text = isPaused ? 'موقوفة مؤقتاً' : (activeTitle ?? 'جلسة تركيز جارية');
      icon = isPaused ? Icons.pause_circle_outline : Icons.bolt_rounded;
    } else if (selectedMode == FocusSessionMode.untilPrayer) {
      text = nextPrayerName != null
          ? 'الرباط حتى صلاة ${nextPrayerName!}'
          : 'الرباط حتى الأذان';
      icon = Icons.mosque_rounded;
    } else if (selectedMode == FocusSessionMode.openStopwatch) {
      text = 'ساعة إيقاف حرة';
      icon = Icons.all_inclusive_rounded;
    } else if (isPomodoroPreset) {
      text = 'بومودورو ذكي (25د تركيز + 5د راحة)';
      icon = Icons.local_cafe_outlined;
    } else {
      text = 'مؤقت مخصص';
      icon = Icons.timer_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accentColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? accentColor : colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    if (isActive) {
      if (selectedMode == FocusSessionMode.openStopwatch) {
        return 'وقت مفتوح — استمر بالتركيز حتى تنهي المهمة';
      }
      return isPaused ? 'اضغط استئناف للمتابعة' : 'جلسة نشطة الآن';
    }

    if (selectedMode == FocusSessionMode.untilPrayer) {
      if (nextPrayerTime != null && remainingPrayerMinutes != null) {
        final formattedAdhan =
            DateFormat('hh:mm a', 'ar').format(nextPrayerTime!);
        final readable =
            FocusTimeFormatter.formatDurationReadable(remainingPrayerMinutes!);
        return 'الأذان $formattedAdhan · المدة: $readable';
      }
      return 'يضبط المؤقت تلقائياً حتى موعد الصلاة القادمة';
    }

    if (selectedMode == FocusSessionMode.openStopwatch) {
      return 'يحسب الوقت المنقضي تصاعدياً بدون حد زمني';
    }

    final h = selectedSeconds ~/ 3600;
    final m = (selectedSeconds % 3600) ~/ 60;
    final s = selectedSeconds % 60;
    final parts = <String>[];
    if (h > 0) parts.add('$h س');
    if (m > 0) parts.add('$m د');
    if (s > 0 || parts.isEmpty) parts.add('$s ث');
    return 'المدة المحددة: ${parts.join(' ')}';
  }
}

class _UnitStepper extends StatelessWidget {
  const _UnitStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              IconButton(
                onPressed: value + 1 <= max
                    ? () {
                        HapticFeedback.selectionClick();
                        onChanged(value + 1);
                      }
                    : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              Text(
                value.toString().padLeft(2, '0'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              IconButton(
                onPressed: value - 1 >= min
                    ? () {
                        HapticFeedback.selectionClick();
                        onChanged(value - 1);
                      }
                    : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
