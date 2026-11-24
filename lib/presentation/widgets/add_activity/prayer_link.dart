part of '../add_activity_sheet.dart';

mixin _PrayerLink on _SheetStateCore {
  List<Widget> _buildPrayerLink(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return [
      Text(
        'الصلاة أو الوقت المرتبط:',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ...PrayerPhase.values.map((phase) {
            final isSelected =
                _type != ActivityType.independent && _linkedPrayer == phase;
            return ChoiceChip(
              label: Text(phase.arabicName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _type = ActivityType.afterPrayer;
                    _linkedPrayer = phase;
                  });
                }
              },
            );
          }),
          ChoiceChip(
            label: const Text('مهمة حرة'),
            avatar: const Icon(Icons.star_outline_rounded, size: 16),
            selected: _type == ActivityType.independent,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _type = ActivityType.independent;
                  _linkedPrayer = null;
                });
              }
            },
          ),
        ],
      ),
      if (_type != ActivityType.independent) ...[
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'التوقيت:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('بعد الصلاة'),
              selected: _type == ActivityType.afterPrayer,
              visualDensity: VisualDensity.compact,
              onSelected: (s) {
                if (s) setState(() => _type = ActivityType.afterPrayer);
              },
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('قبل الصلاة'),
              selected: _type == ActivityType.beforePrayer,
              visualDensity: VisualDensity.compact,
              onSelected: (s) {
                if (s) setState(() => _type = ActivityType.beforePrayer);
              },
            ),
          ],
        ),
      ],
    ];
  }
}
