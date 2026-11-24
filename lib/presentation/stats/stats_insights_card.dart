part of 'stats_screen.dart';

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.stats});

  final StatsSnapshot stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'نظرة ذكية',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stats.feedbackLine,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            if (stats.mostProductivePhase != null)
              Row(
                children: [
                  Icon(Icons.wb_sunny_outlined,
                      size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(
                          'أكثر الأوقات إنتاجية: ${stats.mostProductivePhase!.arabicName}')),
                ],
              ),
            if (stats.mostSkippedActivity != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 18, color: scheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(
                          'النشاط الأكثر تخطيًا: ${stats.mostSkippedActivity}')),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.trending_up, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'نسبة الالتزام هذا الأسبوع: ${(stats.completionRateThisWeek * 100).toStringAsFixed(1)}%',
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
