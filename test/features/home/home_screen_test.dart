import 'dart:io';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/constants/prayer_phase.dart';
import 'package:al_ribat/core/theme/app_theme.dart';
import 'package:al_ribat/domain/entities/prayer_schedule.dart';
import 'package:al_ribat/domain/entities/prayer_time.dart';
import 'package:al_ribat/features/home/presentation/home_screen.dart';
import 'package:al_ribat/features/home/presentation/widgets/home_date_pill.dart';
import 'package:al_ribat/features/home/presentation/widgets/home_prayer_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('al_ribat_home_test_');
    Hive.init(dir.path);
    await Hive.openBox<String>('meta_box');
    await Hive.openBox<String>('activities_box');
    await Hive.openBox<String>('reflections_box');
    await Hive.openBox<String>('work_sessions_box');
    await initializeDateFormatting('ar');
  });

  Widget buildTestApp() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    return ProviderScope(
      overrides: [
        prayerScheduleProvider.overrideWith((ref) async {
          return PrayerSchedule(
            today: [
              PrayerTime(
                phase: PrayerPhase.fajr,
                time: base.add(const Duration(hours: 5)),
              ),
              PrayerTime(
                phase: PrayerPhase.dhuhr,
                time: base.add(const Duration(hours: 12)),
              ),
              PrayerTime(
                phase: PrayerPhase.asr,
                time: base.add(const Duration(hours: 15)),
              ),
              PrayerTime(
                phase: PrayerPhase.maghrib,
                time: base.add(const Duration(hours: 18)),
              ),
              PrayerTime(
                phase: PrayerPhase.isha,
                time: base.add(const Duration(hours: 20)),
              ),
            ],
            tomorrowFajr: PrayerTime(
              phase: PrayerPhase.fajr,
              time: base.add(const Duration(days: 1, hours: 5)),
            ),
            todaySunrise: base.add(const Duration(hours: 6)),
          );
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }

  testWidgets('HomeScreen renders hero card, sliding dock, and switches phase',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('الرباط'), findsOneWidget);
    expect(find.byType(HomeDatePill), findsOneWidget);
    expect(find.byType(HomePrayerHeroCard), findsOneWidget);
    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('الظهر'), findsOneWidget);
    expect(find.text('العصر'), findsOneWidget);
    expect(find.text('المغرب'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);

    await tester.tap(find.text('العصر'));
    await tester.pumpAndSettle();

    expect(find.text('مهام صلاة العصر'), findsOneWidget);
  });

  testWidgets('Date pill navigates days and shows Return to Today button',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.today_rounded), findsOneWidget);
  });
}
