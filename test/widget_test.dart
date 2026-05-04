import 'dart:io';

import 'package:al_ribat/app/app.dart';
import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/constants/prayer_phase.dart';
import 'package:al_ribat/domain/entities/prayer_schedule.dart';
import 'package:al_ribat/domain/entities/prayer_time.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('al_ribat_widget_');
    Hive.init(dir.path);
    await Hive.openBox<String>('tasks_box');
    await Hive.openBox<String>('meta_box');
    await Hive.openBox<String>('reflections_box');
    await Hive.openBox<String>('habits_box');
    await Hive.openBox<String>('work_sessions_box');
    await initializeDateFormatting('ar');
  });

  testWidgets('App shell renders', (WidgetTester tester) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerScheduleProvider.overrideWith((ref) async {
            final d = DateTime.now();
            final base = DateTime(d.year, d.month, d.day);
            final today = [
              PrayerTime(phase: PrayerPhase.fajr, time: base.add(const Duration(hours: 5))),
              PrayerTime(phase: PrayerPhase.dhuhr, time: base.add(const Duration(hours: 12))),
              PrayerTime(phase: PrayerPhase.asr, time: base.add(const Duration(hours: 15))),
              PrayerTime(phase: PrayerPhase.maghrib, time: base.add(const Duration(hours: 18))),
              PrayerTime(phase: PrayerPhase.isha, time: base.add(const Duration(hours: 20))),
            ];
            final fajrNext = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5, 10);
            return PrayerSchedule(
              today: today,
              tomorrowFajr: PrayerTime(phase: PrayerPhase.fajr, time: fajrNext),
              todaySunrise: base.add(const Duration(hours: 6, minutes: 20)),
            );
          }),
        ],
        child: const AlRibatApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('الرباط'), findsWidgets);
  });
}
