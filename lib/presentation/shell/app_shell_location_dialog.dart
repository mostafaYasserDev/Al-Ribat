part of 'app_shell.dart';

Future<void> _showLocationModeDialog(
    BuildContext context, WidgetRef ref) async {
  final box = Hive.box<String>('meta_box');
  if (box.get('location_pref_v1') == '1') return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('ضبط الموقع لأوقات الصلاة'),
      content: const Text(
        'هل تريد ضبط الموقع تلقائياً أم يدوياً بالبحث عن مدينتك أو حيّك؟',
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final cur =
                ref.read(settingsProvider).valueOrNull ?? AppSettings.defaults;
            final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

            if (isMobile) {
              try {
                final enabled = await Geolocator.isLocationServiceEnabled();
                if (!enabled) {
                  if (ctx.mounted) {
                    appSnack(
                      ctx,
                      'خدمة الموقع (GPS) مغلقة في الجهاز. فعّلها أو اختر الوضع اليدوي.',
                    );
                  }
                  return;
                }
              } catch (_) {}
            }

            LocationPermission permission;
            try {
              permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }
            } catch (e) {
              reportError('AppShell location permission', e);
              if (!isMobile) {
                await ref.read(settingsProvider.notifier).updateSettings(
                      cur.copyWith(
                          prayerLocationMode: PrayerLocationMode.automatic),
                    );
                await box.put('location_pref_v1', '1');
                if (ctx.mounted) Navigator.pop(ctx);
                return;
              }
              if (ctx.mounted) {
                appSnack(ctx, 'خدمة الموقع غير متاحة هنا، اختر الموقع يدويًا.');
              }
              return;
            }

            if (isMobile &&
                (permission == LocationPermission.denied ||
                    permission == LocationPermission.deniedForever)) {
              if (ctx.mounted) {
                appSnack(
                  ctx,
                  'يلزم منح صلاحية الموقع لاختيار الوضع التلقائي.',
                );
              }
              return;
            }

            await ref.read(settingsProvider.notifier).updateSettings(
                  cur.copyWith(
                      prayerLocationMode: PrayerLocationMode.automatic),
                );
            await box.put('location_pref_v1', '1');
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('تلقائي'),
        ),
        FilledButton(
          onPressed: () async {
            if (ctx.mounted) Navigator.pop(ctx);
            final picked = await showManualLocationPickerDialog(context);
            if (picked == null) return;
            final cur =
                ref.read(settingsProvider).valueOrNull ?? AppSettings.defaults;
            await ref.read(settingsProvider.notifier).updateSettings(
                  cur.copyWith(
                    prayerLocationMode: PrayerLocationMode.manual,
                    manualLatitude: picked.$1.latitude,
                    manualLongitude: picked.$1.longitude,
                    manualLocationLabel: picked.$2,
                  ),
                );
            await box.put('location_pref_v1', '1');
            if (context.mounted) {
              appSnack(context, 'تم ضبط الموقع يدويًا: ${picked.$2}');
            }
          },
          child: const Text('يدوي'),
        ),
      ],
    ),
  );
}
