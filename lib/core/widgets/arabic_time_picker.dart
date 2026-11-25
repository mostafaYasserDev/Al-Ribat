import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formats a [TimeOfDay] in 12-hour Arabic format with `ص` / `م`.
String formatArabicTime(TimeOfDay time, {bool showPeriodWord = false}) {
  final isPm = time.hour >= 12;
  final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minStr = time.minute.toString().padLeft(2, '0');
  final period =
      showPeriodWord ? (isPm ? 'مساءً' : 'صباحاً') : (isPm ? 'م' : 'ص');
  return '$hour12:$minStr $period';
}

/// Opens a clean Apple-inspired 12-hour wheel time picker with Arabic `ص | م`
/// switcher, smooth mouse/touch wheel scrolling, and step arrows.
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
  late int _hour12; // 1..12
  late int _minute; // 0..59
  late bool _isPm;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _isPm = widget.initialTime.hour >= 12;
    _hour12 = widget.initialTime.hourOfPeriod == 0
        ? 12
        : widget.initialTime.hourOfPeriod;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  TimeOfDay get _currentTimeOfDay {
    var h24 = _hour12 % 12;
    if (_isPm) h24 += 12;
    return TimeOfDay(hour: h24, minute: _minute);
  }

  void _stepHour(int delta) {
    final nextIdx = ((_hour12 - 1 + delta) % 12 + 12) % 12;
    _hourController.animateToItem(
      nextIdx,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _stepMinute(int delta) {
    final nextIdx = ((_minute + delta) % 60 + 60) % 60;
    _minuteController.animateToItem(
      nextIdx,
      duration: const Duration(milliseconds: 180),
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
    final selectedTime = _currentTimeOfDay;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
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
                                formatArabicTime(
                                  selectedTime,
                                  showPeriodWord: true,
                                ),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Sliding AM / PM (ص / م) toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: innerBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _PeriodTab(
                            label: 'صباحاً (ص)',
                            selected: !_isPm,
                            activeBg: cardBg,
                            activeColor: colorScheme.primary,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isPm = false);
                            },
                          ),
                          _PeriodTab(
                            label: 'مساءً (م)',
                            selected: _isPm,
                            activeBg: cardBg,
                            activeColor: colorScheme.primary,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isPm = true);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 12-hour Wheel Picker with mouse/touch support + step arrows
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: innerBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.onSurface.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: const {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.trackpad,
                              PointerDeviceKind.stylus,
                            },
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _WheelColumn(
                                  controller: _hourController,
                                  count: 12,
                                  selectedIdx: _hour12 - 1,
                                  labelBuilder: (i) =>
                                      (i + 1).toString().padLeft(2, '0'),
                                  onChanged: (i) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _hour12 = i + 1);
                                  },
                                  onStepUp: () => _stepHour(-1),
                                  onStepDown: () => _stepHour(1),
                                ),
                              ),
                              Text(
                                ':',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Expanded(
                                child: _WheelColumn(
                                  controller: _minuteController,
                                  count: 60,
                                  selectedIdx: _minute,
                                  labelBuilder: (i) =>
                                      i.toString().padLeft(2, '0'),
                                  onChanged: (i) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _minute = i);
                                  },
                                  onStepUp: () => _stepMinute(-1),
                                  onStepDown: () => _stepMinute(1),
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.activeBg,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeBg;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? activeColor
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.controller,
    required this.count,
    required this.selectedIdx,
    required this.labelBuilder,
    required this.onChanged,
    required this.onStepUp,
    required this.onStepDown,
  });

  final FixedExtentScrollController controller;
  final int count;
  final int selectedIdx;
  final String Function(int) labelBuilder;
  final ValueChanged<int> onChanged;
  final VoidCallback onStepUp;
  final VoidCallback onStepDown;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onStepUp,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        SizedBox(
          height: 124,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 40,
                perspective: 0.0025,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: count,
                  builder: (context, index) {
                    final isSel = index == selectedIdx;
                    return Center(
                      child: Text(
                        labelBuilder(index),
                        style: TextStyle(
                          fontSize: isSel ? 21 : 15,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          color: isSel
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onStepDown,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
