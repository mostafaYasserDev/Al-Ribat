part of '../settings_screen.dart';

extension _SettingsPrayerTimingCards on _SettingsScreenState {
  Widget _buildFocusLeadCard(BuildContext context, AppSettings settings) {
    return Card(
      child: ListTile(
        title: const Text('دقائق التنبيه قبل الصلاة'),
        subtitle: Slider(
          value: settings.focusLeadMinutes.toDouble(),
          min: 5,
          max: 25,
          divisions: 4,
          label: '${settings.focusLeadMinutes}',
          onChanged: (value) async {
            await ref.read(settingsProvider.notifier).updateSettings(
                  settings.copyWith(focusLeadMinutes: value.round()),
                );
          },
        ),
      ),
    );
  }

  Widget _buildPrayerSlotInfoCard(BuildContext context, AppSettings settings) {
    return Card(
      child: ListTile(
        title: const Text('الوقت الافتراضي لمرحلة الصلاة'),
        subtitle: Text(
          'يُستخدم لتنبيه «بعد الصلاة» الافتراضي (${settings.prayerSlotDurationMinutes} دقيقة — ثلث ساعة ≈ ٢٠ دقيقة كبداية).',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildPrayerSlotDurationCard(
      BuildContext context, AppSettings settings) {
    return Card(
      child: ListTile(
        title: const Text('تعديل مدة الصلاة (بالدقائق)'),
        subtitle: Slider(
          value: settings.prayerSlotDurationMinutes.toDouble(),
          min: 10,
          max: 45,
          divisions: 35,
          label: '${settings.prayerSlotDurationMinutes}',
          onChanged: (value) async {
            await ref.read(settingsProvider.notifier).updateSettings(
                  settings.copyWith(prayerSlotDurationMinutes: value.round()),
                );
          },
        ),
      ),
    );
  }
}
