import 'dart:io';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/constants/prayer_phase.dart';
import 'package:al_ribat/core/theme/app_theme.dart';
import 'package:al_ribat/domain/entities/prayer_schedule.dart';
import 'package:al_ribat/domain/entities/prayer_time.dart';
import 'package:al_ribat/features/focus/presentation/focus_sessions_screen.dart';
import 'package:al_ribat/features/focus/presentation/widgets/focus_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final dir = await Directory.systemTemp.createTemp('al_ribat_focus_test_');
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
        home: const FocusSessionsScreen(),
      ),
    );
  }

  testWidgets('Renders header, segmented mode selector, and switches to timer',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('التركيز والرباط'), findsOneWidget);
    expect(find.byType(FocusModeSelector), findsOneWidget);
    expect(find.text('حتى الأذان'), findsOneWidget);
    expect(find.text('مؤقت'), findsOneWidget);
    expect(find.text('مفتوح'), findsOneWidget);
    expect(find.text('ابدأ التركيز الآن'), findsOneWidget);

    await tester.tap(find.text('مؤقت'));
    await tester.pumpAndSettle();

    expect(find.text('25د بومودورو'), findsOneWidget);
    expect(find.text('45د'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ابدأ التركيز الآن'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('إيقاف مؤقت'), findsOneWidget);
    expect(find.text('إنهاء'), findsOneWidget);

    await tester.tap(find.text('إيقاف مؤقت'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('استئناف'), findsOneWidget);
    expect(find.text('موقوفة مؤقتاً'), findsOneWidget);

    await tester.tap(find.text('استئناف'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('إيقاف مؤقت'), findsOneWidget);

    await tester.tap(find.text('إنهاء'));
    await tester.pumpAndSettle();
    expect(find.text('حفظ واكتمال'), findsOneWidget);
    expect(find.text('متابعة التركيز'), findsOneWidget);
    await tester.tap(find.text('إلغاء دون حفظ'));
    await tester.pumpAndSettle();
  });

  testWidgets('Opens FocusHistorySheet with grouped layout', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    expect(find.text('سجل جلسات التركيز'), findsOneWidget);
    expect(find.text('لا توجد جلسات مسجلة بعد'), findsOneWidget);
  });

  testWidgets('Opens anchored link popover with Tasks & Projects tabs',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('ربط الجلسة بمهمة أو مشروع'));
    await tester.pumpAndSettle();

    expect(find.textContaining('مهام اليوم'), findsOneWidget);
    expect(find.textContaining('المشاريع'), findsOneWidget);

    await tester.tap(find.textContaining('المشاريع'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد مشاريع مضافة بعد'), findsOneWidget);
  });

  testWidgets('Opens anchored duration wheel popover and applies duration',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('مؤقت'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تخصيص الساعات والدقائق والثواني'));
    await tester.pumpAndSettle();

    expect(find.text('تحديد مدة الجلسة'), findsOneWidget);
    expect(find.text('اعتماد المدة'), findsOneWidget);

    await tester.tap(find.text('اعتماد المدة'));
    await tester.pumpAndSettle();
  });
}
