import 'package:al_ribat/core/theme/app_theme.dart';
import 'package:al_ribat/features/projects/presentation/widgets/project_templates_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'ProjectTemplatesSheet has 10 templates, supports expand, edit, and empty creation',
      (tester) async {
    expect(ProjectStarterTemplate.templates.length, 10);

    ProjectTemplateSelection? created;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  ProjectTemplatesSheet.open(
                    ctx,
                    onSelect: (sel) => created = sel,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('قوالب مشاريع ملهمة'), findsOneWidget);
    expect(find.text('إيماني وعلمي'), findsOneWidget);
    expect(find.text('تقني ومهني'), findsOneWidget);
    expect(find.text('حياة وعافية'), findsOneWidget);

    await tester.tap(find.text('ختمة وتدبر القرآن'));
    await tester.pumpAndSettle();

    expect(find.text('تضمين المجموعات والمهام الجاهزة'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).last,
      'ختمة رمضان',
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('إنشاء مشروع فارغ'), findsOneWidget);
    await tester.tap(find.text('إنشاء مشروع فارغ'));
    await tester.pumpAndSettle();

    expect(created?.title, 'ختمة رمضان');
    expect(created?.groups, isEmpty);
  });
}
