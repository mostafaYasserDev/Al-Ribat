import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FocusZenDial extends StatefulWidget {
  const FocusZenDial({
    super.key,
    required this.minutes,
    required this.onChanged,
    required this.isActive,
    required this.progress,
    required this.displayTime,
    this.isPaused = false,
  });

  final int minutes;
  final ValueChanged<int> onChanged;
  final bool isActive;
  final double progress; // 0.0 to 1.0
  final String displayTime;
  final bool isPaused;

  @override
  State<FocusZenDial> createState() => _FocusZenDialState();
}

class _FocusZenDialState extends State<FocusZenDial> {
  int _lastHapticMinute = -1;

  void _handlePan(Offset localPosition, Size size) {
    if (widget.isActive) return;

    final center = Offset(size.width / 2, size.height / 2);
    final touch = localPosition - center;
    var angle = atan2(touch.dy, touch.dx) + (pi / 2);
    if (angle < 0) angle += 2 * pi;

    final fraction = angle / (2 * pi);
    final minutes = (fraction * 120).round().clamp(5, 120);

    if (minutes != _lastHapticMinute) {
      _lastHapticMinute = minutes;
      HapticFeedback.selectionClick();
      widget.onChanged(minutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surfaceVariant = theme.colorScheme.surfaceContainerHighest;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dialSize = (constraints.maxWidth * 0.78).clamp(240.0, 320.0);

          return GestureDetector(
            onPanStart: (d) =>
                _handlePan(d.localPosition, Size(dialSize, dialSize)),
            onPanUpdate: (d) =>
                _handlePan(d.localPosition, Size(dialSize, dialSize)),
            child: SizedBox(
              width: dialSize,
              height: dialSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(dialSize, dialSize),
                    painter: _DialPainter(
                      progress: widget.isActive
                          ? widget.progress
                          : (widget.minutes / 120.0).clamp(0.0, 1.0),
                      primaryColor: primary,
                      backgroundColor: surfaceVariant.withValues(alpha: 0.35),
                      isActive: widget.isActive,
                      isPaused: widget.isPaused,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.displayTime,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.isPaused
                              ? Colors.orange
                              : (widget.isActive
                                  ? primary
                                  : theme.colorScheme.onSurface),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isActive
                            ? (widget.isPaused ? 'موقوف مؤقتاً' : 'جلسة جارية')
                            : 'اسحب لتعديل الدقائق',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;
  final bool isActive;
  final bool isPaused;

  _DialPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
    required this.isActive,
    required this.isPaused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 28) / 2;
    const strokeWidth = 14.0;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc
    final sweepAngle = 2 * pi * progress;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: isPaused
            ? const [Colors.amber, Colors.orange]
            : [primaryColor.withValues(alpha: 0.6), primaryColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Thumb / Marker
    final thumbAngle = -pi / 2 + sweepAngle;
    final thumbOffset = Offset(
      center.dx + radius * cos(thumbAngle),
      center.dy + radius * sin(thumbAngle),
    );

    final thumbPaint = Paint()
      ..color =
          isPaused ? Colors.orange : (isActive ? primaryColor : Colors.white)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(thumbOffset, strokeWidth * 0.7, thumbPaint);
    canvas.drawCircle(
      thumbOffset,
      strokeWidth * 0.7,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isPaused != isPaused ||
        oldDelegate.isActive != isActive;
  }
}
