import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/core/ui_feedback.dart';
import '../../application/active_focus_notifier.dart';
import '../../domain/active_focus_state.dart';

String formatFocusRemaining(int sec) {
  final m = sec ~/ 60;
  final s = sec % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class FocusActiveSessionCard extends ConsumerWidget {
  const FocusActiveSessionCard({super.key, required this.activeSession});

  final ActiveFocusState activeSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalSec =
        (activeSession.plannedMinutes * 60).clamp(1, double.infinity);
    final elapsedSec =
        activeSession.plannedMinutes * 60 - activeSession.remainingSeconds;
    final progress = (elapsedSec / totalSec).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  activeSession.isPaused
                      ? Icons.pause_circle_filled_rounded
                      : Icons.timer_rounded,
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeSession.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeSession.isPaused
                            ? 'موقوفة مؤقتاً · المتبقي: ${formatFocusRemaining(activeSession.remainingSeconds)}'
                            : 'جلسة جارية · المتبقي: ${formatFocusRemaining(activeSession.remainingSeconds)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatFocusRemaining(activeSession.remainingSeconds),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (!activeSession.isPaused)
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        mediumHaptic();
                        ref.read(activeFocusProvider.notifier).pauseSession();
                      },
                      icon: const Icon(Icons.pause, size: 18),
                      label: const Text('إيقاف'),
                    ),
                  )
                else
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        lightSuccessHaptic();
                        ref.read(activeFocusProvider.notifier).resumeSession();
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('استئناف'),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      mediumHaptic();
                      ref.read(activeFocusProvider.notifier).cancelSession();
                      appSnack(context, 'أُلغيت الجلسة.');
                    },
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: activeSession.canSavePartial
                        ? () async {
                            final saved = await ref
                                .read(activeFocusProvider.notifier)
                                .savePartial();
                            if (context.mounted && saved) {
                              lightSuccessHaptic();
                              appSnack(context, 'حُفظت الجلسة بالوقت المنقضي.');
                            }
                          }
                        : null,
                    child: const Text('حفظ جزئي'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
