part of '../settings_screen.dart';
// ignore_for_file: deprecated_member_use

extension _SettingsLocationPermission on _SettingsScreenState {
  Future<void> _onAutomaticLocationChanged(
    BuildContext context,
    AppSettings settings,
    PrayerLocationMode? v,
  ) async {
    if (v == null) return;
    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (e) {
      reportError('Settings location permission', e);
      if (context.mounted) {
        appSnack(context, 'خدمة الموقع غير متاحة هنا، استخدم الوضع اليدوي.');
      }
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        appSnack(
          context,
          'صلاحية الموقع مرفوضة دائماً. افتح إعدادات التطبيق لتفعيلها.',
        );
      }
      return;
    }
    if (permission == LocationPermission.denied) {
      if (context.mounted) {
        appSnack(context, 'لم يتم منح صلاحية الموقع.');
      }
      return;
    }
    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(prayerLocationMode: v),
        );
  }
}
