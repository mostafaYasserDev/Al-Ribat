import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formats a [TimeOfDay] in Arabic using 12-hour display with `ص` / `م`
/// or optional 24-hour clarity, never showing English AM/PM.
String formatArabicTime(TimeOfDay time, {bool showPeriodWord = false}) {
  final isPm = time.hour >= 12;
  final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minStr = time.minute.toString().padLeft(2, '0');
  final period =
      showPeriodWord ? (isPm ? 'مساءً' : 'صباحاً') : (isPm ? 'م' : 'ص');
  return '$hour12:$minStr $period';
}

/// Formats a 24-hour string like `20:30` alongside Arabic `ص`/`م`.
String formatArabic24WithPeriod(TimeOfDay time) {
  final h24 = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'م' : 'ص';
  return '$h24:$m ($period)';
}

/// Opens an Apple-inspired wheel time picker supporting 24-hour selection
/// with Arabic `ص` (صباحاً) / `م` (مساءً) indicators and quick presets.
Future<TimeOfDay?> showArabicTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  String title = 'تحديد الوقت',
}) {
  return showGeneralDialog<TimeOfDay>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'إغلاق',
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => _ArabicTimePickerDialog(
      initialTime: initialTime,
      title: title,
    ),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _TimePreset {
  const _TimePreset(this.label, this.hour, this.minute);
  final String label;
  final int hour;
  final int minute;
}

class _ArabicTimePickerDialog extends StatefulWidget {
  const _ArabicTimePickerDialog({
    required this.initialTime,
    required this.title,
  });

  final TimeOfDay initialTime;
  final String title;

  @override
  State<_ArabicTimePickerDialog> createState() =>
      _ArabicTimePickerDialogState();
}

class _ArabicTimePickerDialogState extends State<_ArabicTimePickerDialog> {
  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  static const _presets = [
    _TimePreset('فجراً', 5, 0),
    _TimePreset('صباحاً', 9, 0),
    _TimePreset('ظهراً', 13, 0),
    _TimePreset('عصراً', 16, 0),
    _TimePreset('مساءً', 20, 0),
    _TimePreset('ليلاً', 22, 0),
  ];

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _jumpTo(int hour, int minute) {
    HapticFeedback.selectionClick();
    setState(() {
      _hour = hour;
      _minute = minute;
    });
    _hourController.animateToItem(
      hour,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    _minuteController.animateToItem(
      minute,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardBg = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final innerBg = isDark
        ? const Color(0xFF0A101D)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final selectedTime = TimeOfDay(hour: _hour, minute: _minute);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              elevation: 18,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.schedule_rounded,
                            size: 19,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${formatArabicTime(selectedTime, showPeriodWord: true)}  •  نظام 24 ساعة',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Quick presets
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _presets.map((p) {
                        final isSel = _hour == p.hour && _minute == p.minute;
                        return InkWell(
                          onTap: () => _jumpTo(p.hour, p.minute),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSel ? colorScheme.primary : innerBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${p.label} ${p.hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSel
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.78),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    // Wheel picker (24h + Arabic period)
                    Container(
                      height: 168,
                      decoration: BoxDecoration(
                        color: innerBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.onSurface.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 44,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                          // RTL: Minutes on start (right), Hours on end (left) or natural digital order LTR
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _TimeWheel(
                                    controller: _hourController,
                                    count: 24,
                                    selected: _hour,
                                    labelBuilder: (v) {
                                      final p = v >= 12 ? 'م' : 'ص';
                                      return '${v.toString().padLeft(2, '0')} $p';
                                    },
                                    onChanged: (v) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _hour = v);
                                    },
                                  ),
                                ),
                                Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                Expanded(
                                  child: _TimeWheel(
                                    controller: _minuteController,
                                    count: 60,
                                    selected: _minute,
                                    labelBuilder: (v) =>
                                        v.toString().padLeft(2, '0'),
                                    onChanged: (v) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _minute = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(context, selectedTime);
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'تأكيد الوقت',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeWheel extends StatelessWidget {
  const _TimeWheel({
    required this.controller,
    required this.count,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int count;
  final int selected;
  final String Function(int) labelBuilder;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 42,
      perspective: 0.003,
      diameterRatio: 1.4,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          final isSel = index == selected;
          return Center(
            child: Text(
              labelBuilder(index),
              style: TextStyle(
                fontSize: isSel ? 19 : 15,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                color: isSel
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.42),
              ),
            ),
          );
        },
      ),
    );
  }
}
