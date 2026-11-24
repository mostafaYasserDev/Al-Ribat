part of 'prayer_card.dart';

extension _PrayerCardView on PrayerCard {
  Widget _buildPrayerCard(BuildContext context) {
    final now = DateTime.now();
    final statusLine = _prayerStatusLine(now);

    final cardGradient = Theme.of(context).brightness == Brightness.light
        ? prayer.phase.lightGradient
        : prayer.phase.gradient;
    final light = Theme.of(context).brightness == Brightness.light;

    final titleMed = light
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF142018),
                  fontWeight: FontWeight.w700,
                ) ??
            const TextStyle(
                color: Color(0xFF142018), fontWeight: FontWeight.w700)
        : Theme.of(context)
                .textTheme
                .titleMedium
                ?.merge(PrayerCard._onGradient) ??
            PrayerCard._onGradient;
    final bodyMed = light
        ? Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF2C3530)) ??
            const TextStyle(color: Color(0xFF2C3530))
        : Theme.of(context)
                .textTheme
                .bodyMedium
                ?.merge(PrayerCard._onGradient) ??
            PrayerCard._onGradient;
    final bodySmall = light
        ? Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFF4A5568)) ??
            const TextStyle(color: Color(0xFF4A5568))
        : Theme.of(context)
                .textTheme
                .bodySmall
                ?.merge(PrayerCard._onGradient) ??
            PrayerCard._onGradient;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: cardGradient),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(prayer.phase.arabicName, style: titleMed),
              const Spacer(),
              Text(DateFormat.jm('ar').format(prayer.time), style: bodyMed),
            ],
          ),
          const SizedBox(height: 6),
          Text(statusLine, style: bodySmall),
          if (footerNote != null) ...[
            const SizedBox(height: 4),
            Text(footerNote!, style: bodySmall),
          ],
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildActivitiesList(context),
          ],
        ],
      ),
    );
  }
}
