part of '../settings_screen.dart';
// ignore_for_file: deprecated_member_use

extension _SettingsLocationPermission on _SettingsScreenState {
  Future<void> _onAutomaticLocationChanged(
    BuildContext context,
    AppSettings settings,
    PrayerLocationMode? v,
  ) async {
    if (v == null) return;
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (isMobile) {
      try {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) {
          if (context.mounted) {
            appSnack(
              context,
              'خدمة الموقع (GPS) مغلقة في الجهاز. فعّلها أو اختر الوضع اليدوي.',
            );
          }
          return;
        }
      } catch (e) {
        reportError('Settings location service check', e);
      }
    }

    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (e) {
      reportError('Settings location permission', e);
      if (!isMobile) {
        // On Linux/Desktop, automatic mode uses IP geolocation fallback cleanly.
        await ref.read(settingsProvider.notifier).updateSettings(
              settings.copyWith(prayerLocationMode: v),
            );
        if (context.mounted) {
          appSnack(context, 'تم تفعيل التحديد التلقائي التقريبي لسطح المكتب.');
        }
        return;
      }
      if (context.mounted) {
        appSnack(context, 'خدمة الموقع غير متاحة هنا، استخدم الوضع اليدوي.');
      }
      return;
    }

    if (isMobile && permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        appSnack(
          context,
          'صلاحية الموقع مرفوضة دائماً. افتح إعدادات التطبيق لتفعيلها.',
        );
      }
      return;
    }
    if (isMobile && permission == LocationPermission.denied) {
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
