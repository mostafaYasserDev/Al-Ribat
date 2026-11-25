import 'dart:io';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/theme/app_theme.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';
import 'package:al_ribat/domain/repositories/activity_repository.dart';
import 'package:al_ribat/features/projects/presentation/project_details_screen.dart';
import 'package:al_ribat/features/projects/presentation/projects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _FakeActivityRepository implements ActivityRepository {
  final List<ActivityItem> _items = [
    ActivityItem(
      id: 'a1',
      title: 'حفظ سورة الملك',
      createdAt: DateTime(2026, 11, 25),
      repetition: ActivityRepetition.once,
      projectName: 'ختمة القرآن',
      groupName: 'الحفظ',
    ),
    ActivityItem(
      id: 'a2',
      title: 'مهمة عامة يومية',
      createdAt: DateTime(2026, 11, 25),
      repetition: ActivityRepetition.once,
    ),
  ];

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
  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> reorder(List<ActivityItem> activities) async {
    _items
      ..clear()
      ..addAll(activities);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir =
        await Directory.systemTemp.createTemp('al_ribat_projects_test_');
    Hive.init(dir.path);
    await Hive.openBox<String>('meta_box');
    await Hive.openBox<String>('activities_box');
    await Hive.openBox<String>('reflections_box');
    await Hive.openBox<String>('work_sessions_box');
  });

  Widget buildTestApp() {
    final repo = _FakeActivityRepository();
    return ProviderScope(
      overrides: [
        activityRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProjectsScreen(),
      ),
    );
  }

  testWidgets('ProjectsScreen renders overview, grid, general tasks & details',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('المشاريع والأهداف'), findsOneWidget);
    expect(find.text('إنجاز المشاريع والأهداف'), findsOneWidget);
    expect(find.text('ختمة القرآن'), findsOneWidget);
    expect(find.text('مهام عامة (غير مرتبطة بمشروع)'), findsOneWidget);

    await tester.tap(find.text('ختمة القرآن'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    expect(find.text('الحفظ'), findsOneWidget);
    expect(find.text('حفظ سورة الملك'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsNWidgets(2));

    // Open Apple-style task details popup
    await tester.tap(find.text('حفظ سورة الملك'));
    await tester.pumpAndSettle();

    expect(find.text('تم الإنجاز'), findsOneWidget);
    expect(find.text('تعديل'), findsOneWidget);
    expect(find.text('حذف'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Open anchored project menu popover
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('تعديل اسم المشروع'), findsOneWidget);
    expect(find.text('حذف المشروع'), findsOneWidget);
  });

  testWidgets('ProjectsScreen opens templates sheet', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
    await tester.pumpAndSettle();

    expect(find.text('قوالب مشاريع ملهمة'), findsOneWidget);
    expect(find.text('ختمة وتدبر القرآن'), findsOneWidget);
  });
}
