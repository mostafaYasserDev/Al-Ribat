import 'dart:io';

import 'package:al_ribat/app/app.dart';
import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/constants/prayer_phase.dart';
import 'package:al_ribat/domain/entities/prayer_schedule.dart';
import 'package:al_ribat/domain/entities/prayer_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('al_ribat_smoke_');
    Hive.init(dir.path);
    await Hive.openBox<String>('meta_box');
    await Hive.openBox<String>('activities_box');
    await Hive.openBox<String>('reflections_box');
    await Hive.openBox<String>('work_sessions_box');
    await initializeDateFormatting('ar');
  });

  Future<void> pumpApp(WidgetTester tester) async {
    Hive.box<String>('meta_box').put('location_pref_v1', '1');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prayerScheduleProvider.overrideWith((ref) async {
            final d = DateTime.now();
            final base = DateTime(d.year, d.month, d.day);
            return PrayerSchedule(
              today: [
                PrayerTime(
                    phase: PrayerPhase.fajr,
                    time: base.add(const Duration(hours: 5))),
                PrayerTime(
                    phase: PrayerPhase.dhuhr,
                    time: base.add(const Duration(hours: 12))),
                PrayerTime(
                    phase: PrayerPhase.asr,
                    time: base.add(const Duration(hours: 15))),
                PrayerTime(
                    phase: PrayerPhase.maghrib,
                    time: base.add(const Duration(hours: 18))),
                PrayerTime(
                    phase: PrayerPhase.isha,
                    time: base.add(const Duration(hours: 20))),
              ],
              tomorrowFajr: PrayerTime(
                phase: PrayerPhase.fajr,
                time: base.add(const Duration(days: 1, hours: 5)),
              ),
              todaySunrise: base.add(const Duration(hours: 6)),
            );
          }),
        ],
        child: const AlRibatApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  for (final entry in {
    'اليوم': 'إضافة نشاط',
    'المشاريع': 'المشاريع والمجموعات',
    'التركيز': 'جلسات التركيز',
    'التأملات': 'التأملات',
    'الإعدادات': 'الإعدادات',
  }.entries) {
    testWidgets('tab ${entry.key} renders without errors', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text(entry.key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsWidgets);
    });
  }

  testWidgets('stats screen opens from app bar without errors', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
