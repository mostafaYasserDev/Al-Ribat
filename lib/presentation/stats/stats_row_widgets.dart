part of 'stats_screen.dart';

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}

class _PhaseProgress extends StatelessWidget {
  const _PhaseProgress({required this.name, required this.value});

  final String name;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track = scheme.surfaceContainerHighest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(name)),
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (value / 12).clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: track,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('$value', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
