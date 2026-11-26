import 'package:al_ribat/core/theme/app_theme.dart';
import 'package:al_ribat/presentation/widgets/templates_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'TemplatesSheet displays new categories, smart filters, and returns selected template',
      (tester) async {
    ActivityTemplate? picked;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  picked = await TemplatesSheet.open(ctx);
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

    expect(find.text('قوالب الأنشطة الجاهزة'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('مرتبط بالصلاة'), findsOneWidget);
    expect(find.text('بهدف كمي'), findsOneWidget);
    expect(find.text('أسبوعي وشهري'), findsOneWidget);
    expect(find.text('المال والصدقة'), findsOneWidget);
    expect(find.text('الهدوء الرقمي والنوم'), findsOneWidget);

    await tester.tap(find.text('أسبوعي وشهري'));
    await tester.pumpAndSettle();
    expect(find.text('سورة الكهف'), findsOneWidget);

    await tester.ensureVisible(find.text('المال والصدقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المال والصدقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();
    expect(find.text('صدقة يومية يسيرة'), findsOneWidget);

    await tester.tap(find.text('صدقة يومية يسيرة'));
    await tester.pumpAndSettle();
    expect(picked?.title, 'صدقة يومية يسيرة');
  });
}
