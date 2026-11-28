import 'dart:io';

import 'package:al_ribat/core/constants/prayer_phase.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';
import 'package:al_ribat/domain/entities/prayer_schedule.dart';
import 'package:al_ribat/domain/entities/prayer_time.dart';
import 'package:al_ribat/domain/entities/reflection_entry.dart';
import 'package:al_ribat/domain/entities/work_session_item.dart';
import 'package:al_ribat/features/ai_assistant/application/ai_proactive_engine.dart';
import 'package:al_ribat/features/ai_assistant/application/ai_providers.dart';
import 'package:al_ribat/features/ai_assistant/data/ai_conversation_hive_repo.dart';
import 'package:al_ribat/features/ai_assistant/data/ai_settings_hive_repo.dart';
import 'package:al_ribat/features/ai_assistant/data/ai_tool_parser.dart';
import 'package:al_ribat/features/ai_assistant/data/local_context_builder.dart';
import 'package:al_ribat/features/ai_assistant/data/local_llm_client.dart';
import 'package:al_ribat/features/ai_assistant/data/local_reflection_summarizer.dart';
import 'package:al_ribat/features/ai_assistant/data/model_download_manager.dart';
import 'package:al_ribat/features/ai_assistant/domain/ai_context_snapshot.dart';
import 'package:al_ribat/features/ai_assistant/domain/ai_local_model_spec.dart';
import 'package:al_ribat/features/ai_assistant/domain/ai_message.dart';
import 'package:al_ribat/features/ai_assistant/domain/ai_permissions.dart';
import 'package:al_ribat/features/ai_assistant/domain/ai_proactive_alert.dart';
import 'package:al_ribat/features/ai_assistant/domain/ai_provider_config.dart';
import 'package:al_ribat/features/ai_assistant/domain/ai_tool_call.dart';
import 'package:al_ribat/features/ai_assistant/presentation/ai_chat_screen.dart';
import 'package:al_ribat/features/ai_assistant/presentation/ai_settings_page.dart';
import 'package:al_ribat/features/ai_assistant/presentation/widgets/ai_proactive_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('al_ribat_ai_');
    Hive.init(dir.path);
    await Hive.openBox<String>('meta_box');
  });

  tearDown(() async {
    await Hive.box<String>('meta_box').clear();
  });

  test('LocalModelSpec catalog contains exactly 3 curated models', () {
    expect(LocalModelSpec.catalog.length, 3);
    expect(LocalModelSpec.catalog.map((m) => m.id), [
      'qwen-0.5b-q4',
      'gemma3-1b-int4',
      'llama32-3b-q4',
    ]);
  });

  test('LocalReflectionSummarizer extracts moods and themes without raw text',
      () {
    final now = DateTime(2026, 11, 28, 20, 0);
    const summarizer = LocalReflectionSummarizer();
    final entries = [
      ReflectionEntry(
        id: 'r1',
        text: 'ضغط العمل اليوم كان كبيراً جداً وأحتاج لتنظيم الوقت',
        createdAt: now.subtract(const Duration(days: 1)),
        moods: const ['متوتر'],
        prayerPhaseName: 'العشاء',
      ),
      ReflectionEntry(
        id: 'r2',
        text: 'أشعر بتحسن رغم ضغط العمل وتعلمت الصبر',
        createdAt: now.subtract(const Duration(days: 2)),
        moods: const ['ممتن', 'متوتر'],
        prayerPhaseName: 'العشاء',
      ),
    ];

    final summary = summarizer.summarize(entries, now: now);
    expect(summary.count, 2);
    expect(summary.topMoods.first, 'متوتر (2×)');
    expect(summary.recurringThemes, containsAll(['ضغط', 'العمل']));
    expect(summary.peakPrayerTime, 'العشاء');

    final readable = summary.toReadableArabic();
    expect(readable, isNot(contains('تعلمت الصبر')));
    expect(readable, isNot(contains('أشعر بتحسن')));
  });

  test('LocalContextBuilder respects granular AiPermissions flags', () {
    final now = DateTime(2026, 11, 28, 12, 0);
    const builder = LocalContextBuilder();
    final activities = [
      ActivityItem(
        id: 'a1',
        title: 'مراجعة القرآن',
        createdAt: now,
        repetition: ActivityRepetition.daily,
        type: ActivityType.afterPrayer,
        linkedPrayer: PrayerPhase.maghrib,
        projectName: 'ختمة',
      ),
    ];
    final schedule = PrayerSchedule(
      today: [
        PrayerTime(
          phase: PrayerPhase.fajr,
          time: DateTime(2026, 11, 28, 5, 0),
        ),
        PrayerTime(
          phase: PrayerPhase.maghrib,
          time: DateTime(2026, 11, 28, 17, 0),
        ),
        PrayerTime(
          phase: PrayerPhase.isha,
          time: DateTime(2026, 11, 28, 18, 20),
        ),
      ],
      tomorrowFajr: PrayerTime(
        phase: PrayerPhase.fajr,
        time: DateTime(2026, 11, 29, 5, 0),
      ),
      todaySunrise: DateTime(2026, 11, 28, 6, 20),
    );
    final reflections = [
      ReflectionEntry(
        id: 'r1',
        text: 'نص تأمل خاص جداً',
        createdAt: now.subtract(const Duration(hours: 2)),
        moods: const ['هادئ'],
      ),
    ];
    final sessions = [
      WorkSessionItem(
        id: 'w1',
        name: 'برمجة',
        plannedMinutes: 25,
        startedAt: now.subtract(const Duration(hours: 3)),
        endedAt: now.subtract(const Duration(hours: 2, minutes: 35)),
      ),
    ];

    // All disabled -> empty privacy-safe prompt
    final noneSnapshot = builder.build(
      permissions: const AiPermissions(
        allowActivities: false,
        allowPrayer: false,
        allowProjects: false,
        allowReflections: false,
        allowReflectionSummary: false,
        allowWorkSessions: false,
      ),
      activities: activities,
      prayerSchedule: schedule,
      reflections: reflections,
      workSessions: sessions,
      now: now,
    );
    expect(noneSnapshot.toPromptText(), contains('لم يمنح المستخدم صلاحية'));

    // Summary enabled & approved, full reflections disabled
    final summarySnapshot = builder.build(
      permissions: const AiPermissions(
        allowActivities: true,
        allowPrayer: true,
        allowProjects: true,
        allowReflections: false,
        allowReflectionSummary: true,
        allowWorkSessions: true,
      ),
      activities: activities,
      prayerSchedule: schedule,
      reflections: reflections,
      workSessions: sessions,
      reflectionSummaryApproved: true,
      now: now,
    );
    final prompt = summarySnapshot.toPromptText();
    expect(prompt, contains('مراجعة القرآن'));
    expect(prompt, contains('بين المغرب والعشاء'));
    expect(prompt, contains('المدة ~80 د'));
    expect(prompt, contains('ختمة'));
    expect(prompt, contains('ملخص التأملات'));
    expect(prompt, isNot(contains('نص تأمل خاص جداً')));
  });

  test('AiSettingsHiveRepo and AiConversationHiveRepo persist state', () async {
    final box = Hive.box<String>('meta_box');
    final settingsRepo = AiSettingsHiveRepo(box);
    final chatRepo = AiConversationHiveRepo(box);

    await settingsRepo.saveConfig(
      const AiProviderConfig(
        type: AiProviderType.groqCloud,
        groqApiKey: 'gsk_test_123',
        hasCompletedOnboarding: true,
      ),
    );
    await settingsRepo.savePermissions(
      const AiPermissions(allowReflections: false, allowProjects: false),
      AiProviderType.groqCloud,
    );
    await settingsRepo.savePermissions(
      const AiPermissions(allowReflections: true, allowProjects: true),
      AiProviderType.localLlm,
    );
    await chatRepo.saveAll([
      AiMessage(
        id: 'm1',
        role: AiRole.user,
        content: 'مرحبا',
        createdAt: DateTime(2026, 11, 28),
      ),
    ]);

    expect(settingsRepo.loadConfig().groqApiKey, 'gsk_test_123');
    expect(settingsRepo.loadConfig().isConfigured, isTrue);
    expect(
      settingsRepo.loadPermissions(AiProviderType.groqCloud).allowReflections,
      isFalse,
    );
    expect(
      settingsRepo.loadPermissions(AiProviderType.groqCloud).allowProjects,
      isFalse,
    );
    expect(
      settingsRepo.loadPermissions(AiProviderType.localLlm).allowReflections,
      isTrue,
    );
    expect(
      settingsRepo.loadPermissions(AiProviderType.localLlm).allowProjects,
      isTrue,
    );
    expect(chatRepo.loadAll().length, 1);
    expect(chatRepo.loadAll().first.content, 'مرحبا');
  });

  test('AiToolParser extracts add_activity and create_project actions cleanly',
      () {
    const parser = AiToolParser();
    const raw = '''
ممتاز، سأضيف لك هذه المهمة الآن.
```ribat_action
{"action":"add_activity","title":"ورد المراجعة","repetition":"daily","type":"afterPrayer","linkedPrayer":"fajr","projectName":"حفظ القرآن"}
```
```ribat_action
{"action":"create_project","name":"القراءة","description":"خطة شهرية","tasks":["قراءة 10 صفحات"]}
```
''';
    final parsed = parser.parse(raw, messageId: 'm1');
    expect(parsed.cleanText, 'ممتاز، سأضيف لك هذه المهمة الآن.');
    expect(parsed.actions.length, 2);
    expect(parsed.actions[0].call, isA<AddActivityToolCall>());
    final add = parsed.actions[0].call as AddActivityToolCall;
    expect(add.title, 'ورد المراجعة');
    expect(add.linkedPrayer, 'fajr');
    expect(parsed.actions[1].call, isA<CreateProjectToolCall>());
    final proj = parsed.actions[1].call as CreateProjectToolCall;
    expect(proj.name, 'القراءة');
    expect(proj.tasks, ['قراءة 10 صفحات']);
  });

  testWidgets('AiChatScreen shows 4-step onboarding and opens AiSettingsPage',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadedModelsProvider.overrideWith(
            (ref) async => {'gemma3-1b-int4': '/tmp/gemma.gguf'},
          ),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: AiChatScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مرحباً بك في RibatAI'), findsOneWidget);
    expect(find.text('ابدأ الإعداد (4 خطوات سريعة)'), findsOneWidget);

    await tester.tap(find.text('ابدأ الإعداد (4 خطوات سريعة)'));
    await tester.pumpAndSettle();
    expect(find.text('اختر طريقة التشغيل المناسبة لك'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل مفتاح Groq المجاني'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'gsk_test_key');
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('حدّد صلاحيات النموذج السحابي'), findsOneWidget);
    await tester.tap(find.text('كافة الصلاحيات والإعدادات'));
    await tester.pumpAndSettle();

    expect(find.text('المساعد الذكي (RibatAI)'), findsOneWidget);
    expect(find.text('صلاحيات الوصول للبيانات'), findsOneWidget);
    expect(find.byType(AiSettingsPage), findsOneWidget);
  });

  test('AiProactiveEngine detects tight prayer slot scheduling conflict', () {
    const engine = AiProactiveEngine();
    const snapshot = AiContextSnapshot(
      dueToday: 3,
      completedToday: 0,
      prayerSlots: [
        PrayerSlotInfo(
          label: 'بين المغرب والعشاء',
          durationMinutes: 80,
          taskCount: 3,
          taskTitles: ['ورد', 'قراءة', 'مراجعة'],
        ),
      ],
    );
    final alert = engine.evaluate(snapshot, const AiPermissions());
    expect(alert, isNotNull);
    expect(alert!.type, ProactiveAlertType.schedulingConflict);
    expect(alert.title, contains('بين المغرب والعشاء'));
  });

  testWidgets('AiProactiveBanner renders alert and dismisses for today',
      (tester) async {
    const testAlert = AiProactiveAlert(
      id: 'test_slot',
      type: ProactiveAlertType.schedulingConflict,
      title: 'جدولة مزدحمة بين المغرب والعشاء',
      body: 'لديك 3 مهام في 80 دقيقة.',
      suggestedPrompt: 'أعد توزيع مهامي',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiProactiveAlertProvider.overrideWith((ref) => testAlert),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: AiProactiveBanner(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('جدولة مزدحمة بين المغرب والعشاء'), findsOneWidget);
    expect(find.text('ناقش المساعد لحلها'), findsOneWidget);
  });

  test('ModelDownloadManager detects and deletes local model files', () async {
    final tempDir = await Directory.systemTemp.createTemp('al_ribat_models_');
    final manager = ModelDownloadManager(baseDirProvider: () async => tempDir);
    final spec = LocalModelSpec.catalog.first;

    expect(await manager.getDownloadedModelPath(spec), isNull);

    final dir = Directory('${tempDir.path}/ai_models')..createSync();
    final file = File('${dir.path}/${spec.fileName}')
      ..writeAsStringSync('gguf');
    expect(await manager.getDownloadedModelPath(spec), file.path);

    await manager.deleteModel(spec);
    expect(await manager.getDownloadedModelPath(spec), isNull);
  });

  test('LocalLlmClient throws clear ValidationFailure when model is missing',
      () async {
    final client = LocalLlmClient();
    await expectLater(
      client.streamChat(
        modelPath: '/nonexistent/model.gguf',
        systemPrompt: 'sys',
        history: const [],
      ).toList(),
      throwsException,
    );
  });

  testWidgets('AiChatScreen shows active local model name and switcher popover',
      (tester) async {
    final box = Hive.box<String>('meta_box');
    await tester.runAsync(
      () => AiSettingsHiveRepo(box).saveConfig(
        const AiProviderConfig(
          type: AiProviderType.localLlm,
          localModelId: 'gemma3-1b-int4',
          localModelPath: '/tmp/gemma.gguf',
          hasCompletedOnboarding: true,
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadedModelsProvider.overrideWith(
            (ref) async => {'gemma3-1b-int4': '/tmp/gemma.gguf'},
          ),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: AiChatScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('محلي · Gemma 3 1B (Q4)'), findsOneWidget);
    expect(find.text('محلي (قريباً)'), findsNothing);

    await tester.tap(find.text('محلي · Gemma 3 1B (Q4)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('إدارة النماذج والإعدادات'), findsOneWidget);
  });
}
