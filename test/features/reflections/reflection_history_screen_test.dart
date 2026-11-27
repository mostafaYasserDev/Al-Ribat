import 'dart:io';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/theme/app_theme.dart';
import 'package:al_ribat/domain/entities/reflection_entry.dart';
import 'package:al_ribat/domain/repositories/reflection_repository.dart';
import 'package:al_ribat/features/reflections/presentation/reflection_editor_screen.dart';
import 'package:al_ribat/features/reflections/presentation/reflection_history_screen.dart';
import 'package:al_ribat/features/reflections/presentation/widgets/reflection_quick_compose_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeReflectionRepository implements ReflectionRepository {
  final List<ReflectionEntry> _items = [
    ReflectionEntry(
      id: 'r1',
      title: 'خاطرة الفجر',
      text: 'الحمد لله على هدوء الصباح',
      createdAt: DateTime(2026, 11, 25, 5, 30),
      isPinned: true,
      mood: 'هادئ',
      prayerPhaseName: 'الفجر',
    ),
    ReflectionEntry(
      id: 'r2',
      text: 'إنجاز مشروع مهم بفضل الله',
      createdAt: DateTime(2026, 11, 25, 14, 0),
      mood: 'ممتن',
    ),
  ];

  @override
  Future<List<ReflectionEntry>> loadAll() async => List.unmodifiable(_items);

  @override
  Future<void> add(ReflectionEntry entry) async => _items.insert(0, entry);

  @override
  Future<void> update(ReflectionEntry entry) async {
    final idx = _items.indexWhere((e) => e.id == entry.id);
    if (idx != -1) _items[idx] = entry;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir =
        await Directory.systemTemp.createTemp('al_ribat_reflections_test_');
    Hive.init(dir.path);
    await Hive.openBox<String>('meta_box');
    await Hive.openBox<String>('activities_box');
    await Hive.openBox<String>('reflections_box');
    await Hive.openBox<String>('work_sessions_box');
    await initializeDateFormatting('ar');
  });

  Widget buildTestApp() {
    final repo = _FakeReflectionRepository();
    return ProviderScope(
      overrides: [
        reflectionRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ReflectionHistoryScreen(),
      ),
    );
  }

  testWidgets('Renders header, quick compose card, pinned & other reflections',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('التأملات والخواطر'), findsOneWidget);
    expect(find.byType(ReflectionQuickComposeCard), findsOneWidget);
    expect(find.text('مثبتة'), findsNWidgets(2));
    expect(find.text('أخرى'), findsOneWidget);
    expect(find.text('خاطرة الفجر'), findsOneWidget);
    expect(find.text('إنجاز مشروع مهم بفضل الله'), findsOneWidget);
  });

  testWidgets(
      'Search filters entries and switches between view modes via anchored menu',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'الفجر');
    await tester.pumpAndSettle();

    expect(find.text('خاطرة الفجر'), findsOneWidget);
    expect(find.text('إنجاز مشروع مهم بفضل الله'), findsNothing);
    expect(find.text('نتائج البحث: 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('إنجاز مشروع مهم بفضل الله'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();

    expect(find.text('طريقة عرض التأملات'), findsOneWidget);
    await tester.tap(find.text('الخط الزمني'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.timeline_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.timeline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مضغوط'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
  });

  testWidgets('Long press opens Telegram/Apple bottom action sheet',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('خاطرة الفجر'));
    await tester.pumpAndSettle();

    expect(find.text('إلغاء التثبيت'), findsOneWidget);
    expect(find.text('نسخ النص'), findsOneWidget);
    expect(find.text('مشاركة الخاطرة'), findsOneWidget);
    expect(find.text('حذف'), findsOneWidget);
  });

  testWidgets('Quick filter bar filters pinned reflections', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('الكل'), findsOneWidget);
    await tester.tap(find.text('مثبتة').first);
    await tester.pumpAndSettle();

    expect(find.text('خاطرة الفجر'), findsOneWidget);
    expect(find.text('إنجاز مشروع مهم بفضل الله'), findsNothing);

    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();
    expect(find.text('إنجاز مشروع مهم بفضل الله'), findsOneWidget);
  });

  testWidgets('Editor has no color picker and supports multiple moods',
      (tester) async {
    final repo = _FakeReflectionRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reflectionRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReflectionEditorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لون'), findsNothing);
    expect(find.text('إضافة شعور'), findsOneWidget);

    await tester.tap(find.text('إضافة شعور'));
    await tester.pumpAndSettle();

    expect(find.text('اختر مشاعرك'), findsOneWidget);
    await tester.tap(find.text('هادئ'));
    await tester.tap(find.text('مطمئن'));
    await tester.pumpAndSettle();

    expect(find.text('تم اختيار 2 من 12'), findsOneWidget);

    await tester.tap(find.text('تم').last);
    await tester.pumpAndSettle();

    expect(find.text('المشاعر (2)'), findsOneWidget);
    expect(find.text('هادئ'), findsOneWidget);
    expect(find.text('مطمئن'), findsOneWidget);
  });
}
