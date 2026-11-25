import 'dart:io';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/constants/prayer_phase.dart';
import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/core/theme/app_theme.dart';
import 'package:al_ribat/core/widgets/arabic_time_picker.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';
import 'package:al_ribat/domain/entities/prayer_schedule.dart';
import 'package:al_ribat/domain/entities/prayer_time.dart';
import 'package:al_ribat/domain/repositories/activity_repository.dart';
import 'package:al_ribat/features/home/presentation/home_screen.dart';
import 'package:al_ribat/features/home/presentation/widgets/home_date_pill.dart';
import 'package:al_ribat/features/home/presentation/widgets/home_prayer_hero_card.dart';
import 'package:al_ribat/presentation/stats/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeActivityRepository implements ActivityRepository {
  _FakeActivityRepository([List<ActivityItem>? initial])
      : _items = List<ActivityItem>.from(initial ?? const []);

  final List<ActivityItem> _items;

  @override
  Future<List<ActivityItem>> loadAll() async => List.unmodifiable(_items);

  @override
  Future<void> save(ActivityItem activity) async {
    final idx = _items.indexWhere((e) => e.id == activity.id);
    if (idx >= 0) {
      _items[idx] = activity;
    } else {
      _items.add(activity);
    }
  }

  @override
  Future<void> reorder(List<ActivityItem> activities) async {
    _items
      ..clear()
      ..addAll(activities);
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

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

  Widget buildTestApp({List<ActivityItem> initialActivities = const []}) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final fakeRepo = _FakeActivityRepository(initialActivities);
    return ProviderScope(
      overrides: [
        activityRepositoryProvider.overrideWithValue(fakeRepo),
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

  testWidgets(
      'AddActivitySheet opens from FAB and 3-dots opens anchored popover & delete options',
      (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      buildTestApp(
        initialActivities: [
          ActivityItem(
            id: 'a_test_1',
            title: 'ورد التلاوة اليومي',
            createdAt: DateTime(now.year, now.month, now.day, 12),
            repetition: ActivityRepetition.daily,
            type: ActivityType.afterPrayer,
            linkedPrayer: PrayerPhase.fajr,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Open AddActivitySheet from the FAB and verify Telegram x Apple fields
    await tester.tap(find.text('إضافة نشاط'));
    await tester.pumpAndSettle();

    expect(find.text('نشاط جديد'), findsOneWidget);
    expect(find.text('حفظ'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'أذكار الصباح');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Switch to Fajr in HomePrayerHeroCard
    await tester.tap(
      find.descendant(
        of: find.byType(HomePrayerHeroCard),
        matching: find.text('الفجر'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ورد التلاوة اليومي'), findsOneWidget);

    // Open anchored 3-dots popover on ActivityActionTile
    final moreBtn = find.byIcon(Icons.more_horiz_rounded).first;
    await tester.ensureVisible(moreBtn);
    await tester.tap(moreBtn);
    await tester.pumpAndSettle();

    expect(find.text('تخطي اليوم'), findsOneWidget);
    expect(find.text('تعديل النشاط'), findsOneWidget);
    expect(find.text('حذف النشاط'), findsOneWidget);

    // Tap حذف النشاط to open 3-option delete dialog
    await tester.tap(find.text('حذف النشاط'));
    await tester.pumpAndSettle();

    expect(find.text('تخطي لليوم فقط'), findsOneWidget);
    expect(find.text('إيقاف من اليوم والمستقبل'), findsOneWidget);
    expect(find.text('حذف نهائي'), findsOneWidget);
  });

  test(
      'AppIcons has no duplicate icons, supports Arabic search, and Arabic time formats cleanly',
      () {
    final catalog = AppIcons.catalog;
    expect(catalog.length, greaterThanOrEqualTo(60));
    final uniqueCodePoints = catalog.map((e) => e.icon.codePoint).toSet();
    expect(uniqueCodePoints.length, catalog.length);

    final quranResults = AppIcons.search('قرآن');
    expect(quranResults.any((e) => e.key == 'menu_book'), isTrue);

    expect(formatArabicTime(const TimeOfDay(hour: 0, minute: 47)), '12:47 ص');
    expect(formatArabicTime(const TimeOfDay(hour: 20, minute: 30)), '8:30 م');
  });

  testWidgets(
      'StatsScreen opens via AppleMorphRoute and ? button opens help popover',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.insights_rounded));
    await tester.pumpAndSettle();

    expect(find.text('الإحصائيات'), findsOneWidget);
    expect(find.text('معدل الالتزام الأسبوعي'), findsOneWidget);
    expect(find.text('نبض الأسبوع'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('دليل قراءة الإحصائيات'), findsOneWidget);
    expect(find.text('حلقة الالتزام الأسبوعي'), findsOneWidget);

    // Close help popover and scroll down to Prayer Distribution
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('توزيع الإنجاز حسب الصلوات'),
      200,
      scrollable: find.descendant(
        of: find.byType(StatsScreen),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('توزيع الإنجاز حسب الصلوات'), findsOneWidget);
  });
}
