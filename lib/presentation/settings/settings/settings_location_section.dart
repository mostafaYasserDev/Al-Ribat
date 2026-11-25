part of '../settings_screen.dart';
// ignore_for_file: deprecated_member_use

extension _SettingsLocationCards on _SettingsScreenState {
  Widget _buildLocationCard(BuildContext context, AppSettings settings) {
    return Card(
      key: _manualSectionKey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مصدر الموقع لحساب الأذان',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildAutomaticLocationRadio(context, settings),
            _buildManualLocationRadio(context, settings),
            if (settings.prayerLocationMode == PrayerLocationMode.manual) ...[
              const SizedBox(height: 8),
              _buildLocationSearchField(settings),
              const SizedBox(height: 8),
              _buildLocationSearchButton(settings),
              if (_addressResults.isNotEmpty)
                ..._buildLocationResults(context, settings),
              if (settings.manualLocationLabel != null)
                _buildSelectedLocation(context, settings),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAutomaticLocationRadio(
      BuildContext context, AppSettings settings) {
    return RadioListTile<PrayerLocationMode>(
      value: PrayerLocationMode.automatic,
      groupValue: settings.prayerLocationMode,
      title: const Text('تلقائي (GPS)'),
      subtitle: const Text('يطلب إذن الموقع ويحدّث الأوقات تلقائياً'),
      onChanged: (v) => _onAutomaticLocationChanged(context, settings, v),
    );
  }

  Widget _buildManualLocationRadio(BuildContext context, AppSettings settings) {
    return RadioListTile<PrayerLocationMode>(
      value: PrayerLocationMode.manual,
      groupValue: settings.prayerLocationMode,
      title: const Text('يدوي (بحث عن مكان)'),
      subtitle: const Text('ابحث عن مدينة أو حي لتثبيت الإحداثيات'),
      onChanged: (v) async {
        if (v == null) return;
        await ref.read(settingsProvider.notifier).updateSettings(
              settings.copyWith(prayerLocationMode: v),
            );
      },
    );
  }
}
