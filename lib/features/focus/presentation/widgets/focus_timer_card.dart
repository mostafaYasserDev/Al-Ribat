import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/features/projects/presentation/widgets/anchored_popover.dart';
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

  void _openDurationPopover(BuildContext anchorContext) {
    HapticFeedback.lightImpact();
    var hours = (selectedSeconds ~/ 3600).clamp(0, 8);
    var minutes = (selectedSeconds % 3600) ~/ 60;
    var seconds = selectedSeconds % 60;

    showAnchoredPopover<void>(
      anchorContext,
      width: 320,
      preferAbove: true,
      anchorRadius: 20,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;

        return StatefulBuilder(
          builder: (ctx, setPopoverState) {
            final totalSec =
                ((hours * 3600) + (minutes * 60) + seconds).clamp(1, 28800);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'تحديد مدة الجلسة',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              FocusTimeFormatter.formatCountdown(totalSec),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: SizedBox(
                        height: 148,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.22),
                                  width: 0.8,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _DraggableUnitWheel(
                                    label: 'ساعات',
                                    value: hours,
                                    min: 0,
                                    max: 8,
                                    onChanged: (v) =>
                                        setPopoverState(() => hours = v),
                                  ),
                                ),
                                _colonSeparator(theme, colorScheme),
                                Expanded(
                                  child: _DraggableUnitWheel(
                                    label: 'دقائق',
                                    value: minutes,
                                    min: 0,
                                    max: 59,
                                    onChanged: (v) =>
                                        setPopoverState(() => minutes = v),
                                  ),
                                ),
                                _colonSeparator(theme, colorScheme),
                                Expanded(
                                  child: _DraggableUnitWheel(
                                    label: 'ثوانٍ',
                                    value: seconds,
                                    min: 0,
                                    max: 59,
                                    onChanged: (v) =>
                                        setPopoverState(() => seconds = v),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onDurationSecondsChanged(totalSec);
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'اعتماد المدة',
                          style: TextStyle(fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.only(top: 16, left: 2, right: 2),
      child: Text(
        ':',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    final accentColor =
        isPaused ? const Color(0xFFFF9500) : colorScheme.primary;
    final showCustomControls = !isActive &&
        (selectedMode == FocusSessionMode.customTimer ||
            selectedMode == FocusSessionMode.pomodoro);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? accentColor.withValues(alpha: 0.45)
              : colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.07),
          width: isActive ? 1.4 : 0.7,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          _buildHeaderBadge(context, accentColor),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.withValues(alpha: isDark ? 0.10 : 0.055),
                    accentColor.withValues(alpha: isDark ? 0.03 : 0.015),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
                  width: 0.7,
                ),
              ),
              child: Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      displayTime,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                        height: 1.05,
                        color: isPaused
                            ? const Color(0xFFFF9500)
                            : (isActive ? accentColor : colorScheme.onSurface),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _buildSubtitle(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.64),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 24,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _FocusHorizonPainter(
                        progress: isActive
                            ? (selectedMode == FocusSessionMode.openStopwatch
                                ? 1.0
                                : progress)
                            : 0.0,
                        isActive: isActive,
                        isOpenStopwatch:
                            selectedMode == FocusSessionMode.openStopwatch,
                        accentColor: accentColor,
                        inactiveColor: colorScheme.onSurface
                            .withValues(alpha: isDark ? 0.16 : 0.12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: showCustomControls
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _presets.map((preset) {
                          final isSelected =
                              selectedSeconds == preset.minutes * 60 &&
                                  isPomodoroPreset == preset.isPomodoro;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onSelectPreset(
                                preset.minutes,
                                isPomodoro: preset.isPomodoro,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                preset.label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (anchorCtx) => OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            side: BorderSide(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          onPressed: () => _openDurationPopover(anchorCtx),
                          icon: const Icon(Icons.tune_rounded, size: 17),
                          label: const Text(
                            'تخصيص الساعات والدقائق والثواني',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
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
        color: accentColor.withValues(alpha: 0.12),
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
                fontWeight: FontWeight.w700,
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

/// Precision 29-tick chronometer horizon bar replacing generic circular rings.
class _FocusHorizonPainter extends CustomPainter {
  const _FocusHorizonPainter({
    required this.progress,
    required this.isActive,
    required this.isOpenStopwatch,
    required this.accentColor,
    required this.inactiveColor,
  });

  final double progress;
  final bool isActive;
  final bool isOpenStopwatch;
  final Color accentColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    const tickCount = 29;
    final step = size.width / (tickCount - 1);
    final activeCutoff = isActive
        ? (isOpenStopwatch
            ? tickCount - 1
            : (progress * (tickCount - 1)).round())
        : -1;

    for (var i = 0; i < tickCount; i++) {
      final isMajor = i % 7 == 0;
      final isFrontier = isActive && !isOpenStopwatch && i == activeCutoff;
      final isFilled = isActive && i <= activeCutoff;

      final tickHeight = isFrontier
          ? size.height
          : (isMajor ? size.height * 0.78 : size.height * 0.48);
      final top = (size.height - tickHeight) / 2;
      final x = i * step;

      final Color color;
      if (isFrontier) {
        color = accentColor;
      } else if (isFilled) {
        color = accentColor.withValues(alpha: 0.72);
      } else if (!isActive && isMajor) {
        color = accentColor.withValues(alpha: 0.38);
      } else {
        color = inactiveColor;
      }

      if (isFrontier) {
        final glowPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 2.4, top - 1, 4.8, tickHeight + 2),
            const Radius.circular(3),
          ),
          glowPaint,
        );
      }

      final paint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 1.5, top, 3.0, tickHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FocusHorizonPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isOpenStopwatch != isOpenStopwatch ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

class _DraggableUnitWheel extends StatefulWidget {
  const _DraggableUnitWheel({
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
  State<_DraggableUnitWheel> createState() => _DraggableUnitWheelState();
}

class _DraggableUnitWheelState extends State<_DraggableUnitWheel> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem:
          (widget.value - widget.min).clamp(0, widget.max - widget.min),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = widget.max - widget.min + 1;

    return Column(
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: const {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: 38,
              diameterRatio: 1.45,
              perspective: 0.003,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (idx) {
                HapticFeedback.selectionClick();
                widget.onChanged(widget.min + idx);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: count,
                builder: (context, idx) {
                  final numVal = widget.min + idx;
                  final isSelected = numVal == widget.value;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _controller.animateToItem(
                        idx,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 140),
                        style: TextStyle(
                          fontSize: isSelected ? 22 : 16,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.42),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        child: Text(numVal.toString().padLeft(2, '0')),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
