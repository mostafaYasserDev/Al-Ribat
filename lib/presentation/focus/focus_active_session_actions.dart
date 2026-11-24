part of 'focus_sessions_screen.dart';

Widget _buildActiveFocusActions(
  BuildContext context,
  WidgetRef ref,
  ActiveFocusState activeSession,
) {
  return Row(
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
  );
}
