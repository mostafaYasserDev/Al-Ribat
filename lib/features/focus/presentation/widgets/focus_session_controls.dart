import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum FinishSessionAction { saveAndFinish, cancelWithoutSaving }

/// Telegram x Apple-style bottom sheet for finishing or cancelling a focus session.
Future<FinishSessionAction?> showFinishSessionSheet(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final sheetBg = theme.cardTheme.color ??
      (isDark ? const Color(0xFF111B2E) : Colors.white);

  return showModalBottomSheet<FinishSessionAction>(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: sheetBg,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إنهاء الجلسة',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'هل ترغب في حفظ الدقائق المنجزة حتى الآن أم إلغاء الجلسة؟',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 0.6,
                thickness: 0.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.done_all_rounded,
                    color: Color(0xFF34C759),
                    size: 18,
                  ),
                ),
                title: const Text(
                  'حفظ واكتمال',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'توثيق الوقت المنجز في سجل الجلسات',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx, FinishSessionAction.saveAndFinish);
                },
              ),
              Divider(
                height: 0.6,
                thickness: 0.6,
                indent: 58,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
              ),
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                    size: 18,
                  ),
                ),
                title: Text(
                  'إلغاء دون حفظ',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx, FinishSessionAction.cancelWithoutSaving);
                },
              ),
              Divider(
                height: 0.6,
                thickness: 0.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              ListTile(
                title: Text(
                  'متابعة التركيز',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Tactile Apple/Telegram-style Pause/Resume + Finish controls for active sessions.
class FocusActiveControls extends StatefulWidget {
  const FocusActiveControls({
    super.key,
    required this.isPaused,
    required this.onTogglePause,
    required this.onFinish,
  });

  final bool isPaused;
  final VoidCallback onTogglePause;
  final VoidCallback onFinish;

  @override
  State<FocusActiveControls> createState() => _FocusActiveControlsState();
}

class _FocusActiveControlsState extends State<FocusActiveControls> {
  bool _pausePressed = false;
  bool _finishPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pauseBg =
        widget.isPaused ? const Color(0xFF34C759) : const Color(0xFFFF9500);
    final finishBg = isDark
        ? const Color(0xFF152036)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pausePressed = true),
            onTapUp: (_) => setState(() => _pausePressed = false),
            onTapCancel: () => setState(() => _pausePressed = false),
            child: AnimatedScale(
              scale: _pausePressed ? 0.965 : 1.0,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOutCubic,
              child: Material(
                color: pauseBg,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onTogglePause();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Row(
                        key: ValueKey(widget.isPaused),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            widget.isPaused ? 'استئناف' : 'إيقاف مؤقت',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _finishPressed = true),
            onTapUp: (_) => setState(() => _finishPressed = false),
            onTapCancel: () => setState(() => _finishPressed = false),
            child: AnimatedScale(
              scale: _finishPressed ? 0.965 : 1.0,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOutCubic,
              child: Material(
                color: finishBg,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onFinish();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stop_circle_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'إنهاء',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.88),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
