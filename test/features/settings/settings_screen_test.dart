import 'dart:io';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/theme/app_theme.dart';
import 'package:al_ribat/domain/entities/app_settings.dart';
import 'package:al_ribat/domain/repositories/settings_repository.dart';
import 'package:al_ribat/features/settings/presentation/pages/notifications_timing_settings_page.dart';
import 'package:al_ribat/features/settings/presentation/pages/prayer_location_settings_page.dart';
import 'package:al_ribat/features/settings/presentation/settings_screen.dart';
import 'package:al_ribat/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = AppSettings.defaults;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir =
        await Directory.systemTemp.createTemp('al_ribat_settings_test_');
    Hive.init(dir.path);
    await Hive.openBox<String>('meta_box');
    await Hive.openBox<String>('activities_box');
    await Hive.openBox<String>('reflections_box');
    await Hive.openBox<String>('work_sessions_box');
  });

  Widget buildTestApp() {
    final repo = _FakeSettingsRepository();
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final settings =
              ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode == AppThemeMode.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: SettingsScreen(),
            ),
          );
        },
      ),
    );
  }

  testWidgets('SettingsScreen renders grouped sections and switches theme',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('المظهر والواجهة'), findsOneWidget);
    expect(find.text('الموقع وطريقة الحساب'), findsOneWidget);
    expect(find.text('الإشعارات ومواقيت التركيز'), findsOneWidget);
    expect(find.text('المزامنة والنسخ الاحتياطي'), findsOneWidget);
    expect(find.text('قفل التطبيق برمز مرور'), findsOneWidget);
    expect(find.text('عن تطبيق الرباط'), findsOneWidget);
    expect(find.byType(AnimatedSegmentedControl<AppThemeMode>), findsOneWidget);

    await tester.tap(find.text('داكن'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    expect(
      container.read(settingsProvider).valueOrNull?.themeMode,
      AppThemeMode.dark,
    );
  });

  testWidgets('Navigates to PrayerLocationSettingsPage', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('الموقع وطريقة الحساب'));
    await tester.pumpAndSettle();

    expect(find.byType(PrayerLocationSettingsPage), findsOneWidget);
    expect(find.text('طريقة الحساب الفقهي'), findsOneWidget);
    expect(
      find.byType(AnimatedSegmentedControl<PrayerLocationMode>),
      findsOneWidget,
    );
  });

  testWidgets('NotificationsTimingSettingsPage toggles focus lead options',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('الإشعارات ومواقيت التركيز'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsTimingSettingsPage), findsOneWidget);
    expect(find.text('15 د'), findsOneWidget);

    await tester.tap(find.text('وضع الهدوء قبل الصلاة'));
    await tester.pumpAndSettle();

    expect(find.text('15 د'), findsNothing);
  });
}
