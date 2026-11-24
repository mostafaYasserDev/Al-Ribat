part of 'focus_sessions_screen.dart';

class _FocusEmptyState extends StatelessWidget {
  const _FocusEmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.center_focus_strong,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'ابدأ جلسة تركيزٍ عميقة.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              MotivationQuotes.randomLine(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('بدء جلسة جديدة'),
            ),
          ],
        ),
      ),
    );
  }
}
