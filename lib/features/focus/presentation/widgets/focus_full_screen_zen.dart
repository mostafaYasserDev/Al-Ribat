import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/services/motivation_quotes.dart';
import '../../application/active_focus_notifier.dart';
import '../../domain/active_focus_state.dart';
import '../../domain/focus_time_formatter.dart';
import 'focus_session_controls.dart';

class FocusFullScreenZen extends ConsumerStatefulWidget {
  const FocusFullScreenZen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => const FocusFullScreenZen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  ConsumerState<FocusFullScreenZen> createState() => _FocusFullScreenZenState();
}

class _FocusFullScreenZenState extends ConsumerState<FocusFullScreenZen> {
  late final String _quote;

  @override
  void initState() {
    super.initState();
    _quote = MotivationQuotes.randomLine();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _handleFinish() async {
    final action = await showFinishSessionSheet(context);
    if (action == null || !mounted) return;
    final notifier = ref.read(activeFocusProvider.notifier);
    if (action == FinishSessionAction.saveAndFinish) {
      notifier.savePartial();
    } else {
      notifier.cancelSession();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeFocusProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (active == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF08101C) : const Color(0xFFF3F6F4),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('لا توجد جلسة نشطة'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('العودة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalSec = active.plannedSeconds.clamp(1, double.infinity);
    final progress = active.mode == FocusSessionMode.openStopwatch
        ? 1.0
        : (active.elapsedSeconds / totalSec).clamp(0.0, 1.0);

    final secondsToDisplay = active.mode == FocusSessionMode.openStopwatch
        ? active.elapsedSeconds
        : active.remainingSeconds;
    final displayTime = FocusTimeFormatter.formatCountdown(secondsToDisplay);

    final accentColor =
        active.isPaused ? const Color(0xFFFF9500) : theme.colorScheme.primary;
    final bgTop = isDark ? const Color(0xFF070E1A) : const Color(0xFFF2F5F3);
    final bgBottom = isDark ? const Color(0xFF0F1D32) : const Color(0xFFE7ECE9);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgTop, bgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              active.isPaused
                                  ? Icons.pause_circle_outline_rounded
                                  : Icons.bolt_rounded,
                              size: 16,
                              color: accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              active.isPaused ? 'موقوفة مؤقتاً' : 'وضع التركيز',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: isDark
                            ? const Color(0xFF152036)
                            : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(9),
                            child: Icon(
                              Icons.fullscreen_exit_rounded,
                              size: 22,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              active.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (active.linkedActivityTitle != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'مرتبط بـ: ${active.linkedActivityTitle!}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 36),
                            RepaintBoundary(
                              child: Column(
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      displayTime,
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(
                                        fontSize: 68,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 3,
                                        color: accentColor,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: active.mode ==
                                              FocusSessionMode.openStopwatch
                                          ? null
                                          : progress,
                                      minHeight: 7,
                                      color: accentColor,
                                      backgroundColor: theme
                                          .colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 44),
                            FocusActiveControls(
                              isPaused: active.isPaused,
                              onTogglePause: () {
                                final notifier =
                                    ref.read(activeFocusProvider.notifier);
                                if (active.isPaused) {
                                  notifier.resumeSession();
                                } else {
                                  notifier.pauseSession();
                                }
                              },
                              onFinish: _handleFinish,
                            ),
                            const SizedBox(height: 36),
                            Text(
                              _quote,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12.5,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
