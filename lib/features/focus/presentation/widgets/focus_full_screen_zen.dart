import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/services/motivation_quotes.dart';
import '../../application/active_focus_notifier.dart';
import '../../domain/active_focus_state.dart';
import '../../domain/focus_time_formatter.dart';

class FocusFullScreenZen extends ConsumerStatefulWidget {
  const FocusFullScreenZen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const FocusFullScreenZen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
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

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeFocusProvider);
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;

    if (active == null) {
      return Scaffold(
        backgroundColor:
            light ? const Color(0xFFF8FAFC) : const Color(0xFF071320),
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

    final bgGradient = light
        ? const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)]
        : const [Color(0xFF06111C), Color(0xFF0F2236)];
    final accentColor =
        active.isPaused ? Colors.orange : theme.colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.fullscreen_exit_rounded),
                  tooltip: 'إنهاء وضع الشاشة الكاملة',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          active.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (active.linkedActivityTitle != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'مرتبط بـ: ${active.linkedActivityTitle!}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 36),

                        // Wide Digital Readout + Linear Progress
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            displayTime,
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: accentColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: active.mode == FocusSessionMode.openStopwatch
                                ? null
                                : progress,
                            minHeight: 8,
                            color: accentColor,
                            backgroundColor: theme
                                .colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                        ),

                        const SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                if (active.isPaused) {
                                  ref
                                      .read(activeFocusProvider.notifier)
                                      .resumeSession();
                                } else {
                                  ref
                                      .read(activeFocusProvider.notifier)
                                      .pauseSession();
                                }
                              },
                              icon: Icon(active.isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded),
                              label: Text(
                                  active.isPaused ? 'استئناف' : 'إيقاف مؤقت'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('إنهاء الجلسة'),
                                    content: const Text(
                                        'هل ترغب في حفظ الدقائق المنجزة حتى الآن أم إلغاء الجلسة؟'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx, false);
                                          ref
                                              .read(
                                                  activeFocusProvider.notifier)
                                              .cancelSession();
                                        },
                                        child: const Text('إلغاء دون حفظ',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(ctx, true);
                                          ref
                                              .read(
                                                  activeFocusProvider.notifier)
                                              .savePartial();
                                        },
                                        child: const Text('حفظ واكتمال'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != null && mounted) {
                                  Navigator.pop(this.context);
                                }
                              },
                              icon:
                                  const Icon(Icons.done_all_rounded, size: 18),
                              label: const Text('إنهاء'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        Text(
                          _quote,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
