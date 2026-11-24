import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/services/motivation_quotes.dart';
import '../../application/active_focus_notifier.dart';
import '../../domain/active_focus_state.dart';
import 'focus_ambient_sound_sheet.dart';
import 'focus_zen_dial.dart';

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

    final totalSec = (active.plannedMinutes * 60).clamp(1, double.infinity);
    final progress = active.mode == FocusSessionMode.openStopwatch
        ? 1.0
        : (active.elapsedSeconds / totalSec).clamp(0.0, 1.0);

    final m = active.mode == FocusSessionMode.openStopwatch
        ? active.elapsedSeconds ~/ 60
        : active.remainingSeconds ~/ 60;
    final s = active.mode == FocusSessionMode.openStopwatch
        ? active.elapsedSeconds % 60
        : active.remainingSeconds % 60;
    final displayTime =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final bgGradient = light
        ? const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)]
        : const [Color(0xFF06111C), Color(0xFF0F2236)];

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
              // Exit button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.fullscreen_exit_rounded),
                  tooltip: 'إنهاء وضع الشاشة الكاملة',
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Soundscape button
              Positioned(
                top: 16,
                right: 16,
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.spatial_audio_rounded),
                  tooltip: 'الأجواء الصوتية',
                  onPressed: () => FocusAmbientSoundSheet.show(context),
                ),
              ),

              // Main Zen Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Session Title
                      Text(
                        active.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (active.linkedActivityTitle != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'مرتبط بـ: ${active.linkedActivityTitle!}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),

                      // Circular Zen Dial Display
                      FocusZenDial(
                        minutes: active.plannedMinutes,
                        onChanged: (_) {},
                        isActive: true,
                        progress: progress,
                        displayTime: displayTime,
                        isPaused: active.isPaused,
                      ),

                      const SizedBox(height: 36),

                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
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
                                  borderRadius: BorderRadius.circular(20)),
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
                                            .read(activeFocusProvider.notifier)
                                            .cancelSession();
                                        Navigator.pop(context);
                                      },
                                      child: const Text('إلغاء دون حفظ',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(ctx, true);
                                        ref
                                            .read(activeFocusProvider.notifier)
                                            .savePartial();
                                        Navigator.pop(context);
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
                            icon: const Icon(Icons.done_all_rounded, size: 18),
                            label: const Text('إنهاء'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Quote
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _quote,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
