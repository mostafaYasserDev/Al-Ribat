part of '../settings_screen.dart';

extension _SettingsPrayerCards on _SettingsScreenState {
  Widget _buildPrayerMethodCard(BuildContext context, AppSettings settings) {
    return Card(
      child: ListTile(
        title: const Text('طريقة الحساب الفقهي'),
        subtitle: Text(_labelMethod(settings.prayerMethod)),
        trailing: DropdownButton<PrayerCalculationMethod>(
          value: settings.prayerMethod,
          onChanged: (value) async {
            if (value == null) return;
            await ref.read(settingsProvider.notifier).updateSettings(
                  settings.copyWith(prayerMethod: value),
                );
          },
          items: PrayerCalculationMethod.values
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(_labelMethod(e)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context, AppSettings settings) {
    return Card(
      child: ListTile(
        title: const Text('المظهر'),
        trailing: DropdownButton<AppThemeMode>(
          value: settings.themeMode,
          onChanged: (value) async {
            if (value == null) return;
            await ref.read(settingsProvider.notifier).updateSettings(
                  settings.copyWith(themeMode: value),
                );
          },
          items: const [
            DropdownMenuItem(value: AppThemeMode.dark, child: Text('داكن')),
            DropdownMenuItem(value: AppThemeMode.light, child: Text('فاتح')),
            DropdownMenuItem(value: AppThemeMode.system, child: Text('تلقائي')),
          ],
        ),
      ),
    );
  }

  String _labelMethod(PrayerCalculationMethod method) {
    switch (method) {
      case PrayerCalculationMethod.muslimWorldLeague:
        return 'رابطة العالم الإسلامي';
      case PrayerCalculationMethod.egyptian:
        return 'الهيئة المصرية';
      case PrayerCalculationMethod.karachi:
        return 'كراتشي';
      case PrayerCalculationMethod.ummAlQura:
        return 'أم القرى';
      case PrayerCalculationMethod.dubai:
        return 'دبي';
    }
  }
}
