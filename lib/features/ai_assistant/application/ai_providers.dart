import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../application/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../data/ai_conversation_hive_repo.dart';
import '../data/ai_settings_hive_repo.dart';
import '../data/ai_tool_parser.dart';
import '../data/groq_client.dart';
import '../data/local_context_builder.dart';
import '../data/local_llm_client.dart';
import '../data/local_reflection_summarizer.dart';
import '../data/model_download_manager.dart';
import '../domain/ai_chat_session.dart';
import '../domain/ai_context_snapshot.dart';
import '../domain/ai_local_model_spec.dart';
import '../domain/ai_message.dart';
import '../domain/ai_permissions.dart';
import '../domain/ai_provider_config.dart';
import '../domain/ai_tool_call.dart';
import 'ai_tool_executor.dart';

final aiSettingsRepoProvider = Provider<AiSettingsHiveRepo>((ref) {
  return AiSettingsHiveRepo(Hive.box<String>('meta_box'));
});

final aiConversationRepoProvider = Provider<AiConversationHiveRepo>((ref) {
  return AiConversationHiveRepo(Hive.box<String>('meta_box'));
});

final groqClientProvider = Provider<GroqClient>((ref) => GroqClient());

final localLlmClientProvider = Provider<LocalLlmClient>((ref) {
  final client = LocalLlmClient();
  ref.onDispose(client.dispose);
  return client;
});

final modelDownloadManagerProvider =
    Provider<ModelDownloadManager>((ref) => ModelDownloadManager());

final downloadedModelsProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final manager = ref.read(modelDownloadManagerProvider);
  final result = <String, String>{};
  for (final spec in LocalModelSpec.catalog) {
    final path = await manager.getDownloadedModelPath(spec);
    if (path != null) {
      result[spec.id] = path;
    }
  }
  return result;
});

class AiModelDownloadState {
  const AiModelDownloadState({
    this.activeSpec,
    this.progress =
        const ModelDownloadProgress(status: ModelDownloadStatus.idle),
  });

  final LocalModelSpec? activeSpec;
  final ModelDownloadProgress progress;

  bool get isDownloading => progress.status == ModelDownloadStatus.downloading;
}

final aiModelDownloadProvider =
    NotifierProvider<AiModelDownloadNotifier, AiModelDownloadState>(
  AiModelDownloadNotifier.new,
);

class AiModelDownloadNotifier extends Notifier<AiModelDownloadState> {
  StreamSubscription<ModelDownloadProgress>? _sub;
  bool _cancelled = false;

  @override
  AiModelDownloadState build() {
    ref.onDispose(() {
      _cancelled = true;
      _sub?.cancel();
    });
    return const AiModelDownloadState();
  }

  void startDownload(LocalModelSpec spec) {
    if (state.isDownloading) return;
    _cancelled = false;
    _sub?.cancel();

    state = AiModelDownloadState(
      activeSpec: spec,
      progress: const ModelDownloadProgress(
        status: ModelDownloadStatus.downloading,
      ),
    );

    final manager = ref.read(modelDownloadManagerProvider);
    _sub = manager
        .downloadModel(spec, isCancelled: () => _cancelled)
        .listen((p) async {
      state = AiModelDownloadState(activeSpec: spec, progress: p);
      if (p.status == ModelDownloadStatus.completed && p.filePath != null) {
        final current = ref.read(aiConfigProvider);
        await ref.read(aiConfigProvider.notifier).updateConfig(
              current.copyWith(
                type: AiProviderType.localLlm,
                localModelId: spec.id,
                localModelPath: p.filePath,
                hasCompletedOnboarding: true,
              ),
            );
        ref.invalidate(downloadedModelsProvider);
        Future.delayed(const Duration(seconds: 4), () {
          if (state.progress.status == ModelDownloadStatus.completed &&
              state.activeSpec?.id == spec.id) {
            state = const AiModelDownloadState();
          }
        });
      }
    });
  }

  void cancelDownload() {
    _cancelled = true;
    _sub?.cancel();
    state = const AiModelDownloadState();
  }

  void clearStatus() {
    if (!state.isDownloading) {
      state = const AiModelDownloadState();
    }
  }
}

final aiConfigProvider =
    NotifierProvider<AiConfigNotifier, AiProviderConfig>(AiConfigNotifier.new);

class AiConfigNotifier extends Notifier<AiProviderConfig> {
  @override
  AiProviderConfig build() {
    return ref.read(aiSettingsRepoProvider).loadConfig();
  }

  Future<void> updateConfig(AiProviderConfig next) async {
    state = next;
    await ref.read(aiSettingsRepoProvider).saveConfig(next);
  }
}

final aiCloudPermissionsProvider =
    NotifierProvider<AiCloudPermissionsNotifier, AiPermissions>(
  AiCloudPermissionsNotifier.new,
);

class AiCloudPermissionsNotifier extends Notifier<AiPermissions> {
  @override
  AiPermissions build() {
    return ref
        .read(aiSettingsRepoProvider)
        .loadPermissions(AiProviderType.groqCloud);
  }

  Future<void> updatePermissions(AiPermissions next) async {
    state = next;
    await ref
        .read(aiSettingsRepoProvider)
        .savePermissions(next, AiProviderType.groqCloud);
  }
}

final aiLocalPermissionsProvider =
    NotifierProvider<AiLocalPermissionsNotifier, AiPermissions>(
  AiLocalPermissionsNotifier.new,
);

class AiLocalPermissionsNotifier extends Notifier<AiPermissions> {
  @override
  AiPermissions build() {
    return ref
        .read(aiSettingsRepoProvider)
        .loadPermissions(AiProviderType.localLlm);
  }

  Future<void> updatePermissions(AiPermissions next) async {
    state = next;
    await ref
        .read(aiSettingsRepoProvider)
        .savePermissions(next, AiProviderType.localLlm);
  }
}

/// Active permissions matching the currently selected provider.
final aiPermissionsProvider = Provider<AiPermissions>((ref) {
  final type = ref.watch(aiConfigProvider.select((c) => c.type));
  return type == AiProviderType.localLlm
      ? ref.watch(aiLocalPermissionsProvider)
      : ref.watch(aiCloudPermissionsProvider);
});

final aiReflectionSummaryApprovedProvider = StateProvider<bool>((ref) => false);

final aiIsStreamingProvider = StateProvider<bool>((ref) => false);

final aiSessionsProvider = StateProvider<List<AiChatSession>>((ref) {
  return ref.read(aiConversationRepoProvider).loadSessions();
});

final aiActiveSessionIdProvider = StateProvider<String?>((ref) {
  final repo = ref.read(aiConversationRepoProvider);
  final sessions = ref.read(aiSessionsProvider);
  final savedId = repo.getActiveSessionId();
  if (savedId != null && sessions.any((s) => s.id == savedId)) {
    return savedId;
  }
  return sessions.firstOrNull?.id;
});

final aiChatProvider =
    AsyncNotifierProvider<AiChatNotifier, List<AiMessage>>(AiChatNotifier.new);

class AiChatNotifier extends AsyncNotifier<List<AiMessage>> {
  static const _contextBuilder = LocalContextBuilder();
  static const _summarizer = LocalReflectionSummarizer();
  static const _toolParser = AiToolParser();
  static const _toolExecutor = AiToolExecutor();

  bool _cancelRequested = false;

  @override
  Future<List<AiMessage>> build() async {
    final sessions = ref.read(aiSessionsProvider);
    final activeId = ref.read(aiActiveSessionIdProvider);
    final active = sessions.where((s) => s.id == activeId).firstOrNull;
    return active?.messages ?? const [];
  }

  void stopGeneration() {
    _cancelRequested = true;
  }

  Future<void> startNewSession() async {
    if (ref.read(aiIsStreamingProvider)) return;
    final id = 's_${DateTime.now().microsecondsSinceEpoch}';
    final session = AiChatSession(
      id: id,
      title: 'محادثة جديدة',
      updatedAt: DateTime.now(),
    );
    final next = [session, ...ref.read(aiSessionsProvider)];
    ref.read(aiSessionsProvider.notifier).state = next;
    ref.read(aiActiveSessionIdProvider.notifier).state = id;
    await ref.read(aiConversationRepoProvider).saveSessions(next);
    await ref.read(aiConversationRepoProvider).setActiveSessionId(id);
    state = const AsyncData([]);
  }

  Future<void> switchSession(String sessionId) async {
    if (ref.read(aiIsStreamingProvider)) return;
    final sessions = ref.read(aiSessionsProvider);
    final target = sessions.where((s) => s.id == sessionId).firstOrNull;
    if (target == null) return;
    ref.read(aiActiveSessionIdProvider.notifier).state = sessionId;
    await ref.read(aiConversationRepoProvider).setActiveSessionId(sessionId);
    state = AsyncData(target.messages);
  }

  Future<void> _persistMessages(List<AiMessage> messages) async {
    final repo = ref.read(aiConversationRepoProvider);
    var sessions = ref.read(aiSessionsProvider);
    var activeId = ref.read(aiActiveSessionIdProvider);

    if (activeId == null || !sessions.any((s) => s.id == activeId)) {
      activeId = 's_${DateTime.now().microsecondsSinceEpoch}';
      final firstUser =
          messages.where((m) => m.role == AiRole.user).firstOrNull?.content ??
              'محادثة جديدة';
      final title =
          firstUser.length > 34 ? '${firstUser.substring(0, 34)}…' : firstUser;
      sessions = [
        AiChatSession(
          id: activeId,
          title: title,
          updatedAt: DateTime.now(),
          messages: messages,
        ),
        ...sessions,
      ];
      ref.read(aiActiveSessionIdProvider.notifier).state = activeId;
      await repo.setActiveSessionId(activeId);
    } else {
      final firstUser =
          messages.where((m) => m.role == AiRole.user).firstOrNull?.content;
      sessions = [
        for (final s in sessions)
          if (s.id == activeId)
            s.copyWith(
              title: (s.title == 'محادثة جديدة' && firstUser != null)
                  ? (firstUser.length > 34
                      ? '${firstUser.substring(0, 34)}…'
                      : firstUser)
                  : s.title,
              updatedAt: DateTime.now(),
              messages: messages,
            )
          else
            s,
      ];
    }

    ref.read(aiSessionsProvider.notifier).state = sessions;
    await repo.saveSessions(sessions);
  }

  Future<void> executeProposedAction(String messageId, String actionId) async {
    final currentList = state.valueOrNull ?? const <AiMessage>[];
    AiToolCall? targetCall;
    for (final msg in currentList) {
      if (msg.id != messageId) continue;
      final found =
          msg.proposedActions.where((a) => a.id == actionId).firstOrNull;
      if (found != null && found.status == ToolActionStatus.pending) {
        targetCall = found.call;
      }
    }
    if (targetCall == null) return;
    await _toolExecutor.execute(ref, targetCall);
    await _updateActionStatus(messageId, actionId, ToolActionStatus.executed);
  }

  Future<void> dismissProposedAction(String messageId, String actionId) async {
    await _updateActionStatus(messageId, actionId, ToolActionStatus.dismissed);
  }

  Future<void> _updateActionStatus(
    String messageId,
    String actionId,
    ToolActionStatus status,
  ) async {
    final currentList = state.valueOrNull ?? const <AiMessage>[];
    final next = [
      for (final msg in currentList)
        if (msg.id == messageId)
          msg.copyWith(
            proposedActions: [
              for (final a in msg.proposedActions)
                if (a.id == actionId) a.copyWith(status: status) else a,
            ],
          )
        else
          msg,
    ];
    state = AsyncData(next);
    await _persistMessages(next);
  }

  ReflectionSummary previewReflectionSummary() {
    final reflections = ref.read(reflectionsProvider).valueOrNull ?? const [];
    return _summarizer.summarize(reflections);
  }

  Future<void> clearHistory() async {
    final activeId = ref.read(aiActiveSessionIdProvider);
    final nextSessions =
        ref.read(aiSessionsProvider).where((s) => s.id != activeId).toList();
    ref.read(aiSessionsProvider.notifier).state = nextSessions;
    ref.read(aiActiveSessionIdProvider.notifier).state =
        nextSessions.firstOrNull?.id;
    await ref.read(aiConversationRepoProvider).saveSessions(nextSessions);
    await ref.read(aiConversationRepoProvider).clear();
    state = AsyncData(nextSessions.firstOrNull?.messages ?? const []);
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || ref.read(aiIsStreamingProvider)) return;

    final config = ref.read(aiConfigProvider);
    if (!config.isConfigured) {
      await _appendSystemNotice(
        config.type == AiProviderType.localLlm
            ? 'يرجى تنزيل واختيار نموذج محلي من الإعدادات أولاً لبدء المحادثة.'
            : 'يرجى إكمال إعداد مفتاح Groq API أولاً لتتمكن من بدء المحادثة.',
      );
      return;
    }

    final currentList = state.valueOrNull ?? const <AiMessage>[];
    final userMsg = AiMessage(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      role: AiRole.user,
      content: text,
      createdAt: DateTime.now(),
    );
    final assistantId = 'a_${DateTime.now().microsecondsSinceEpoch + 1}';
    final placeholder = AiMessage(
      id: assistantId,
      role: AiRole.assistant,
      content: '',
      createdAt: DateTime.now(),
    );

    final withUser = [...currentList, userMsg];
    state = AsyncData([...withUser, placeholder]);
    _cancelRequested = false;
    ref.read(aiIsStreamingProvider.notifier).state = true;

    try {
      final isLocal = config.type == AiProviderType.localLlm;
      final systemPrompt = _buildSystemPrompt(isLocal: isLocal);
      final buffer = StringBuffer();

      final tokenStream = switch (config.type) {
        AiProviderType.groqCloud => ref.read(groqClientProvider).streamChat(
              apiKey: config.groqApiKey!,
              model: config.groqModel,
              systemPrompt: systemPrompt,
              history: withUser,
            ),
        AiProviderType.localLlm => ref.read(localLlmClientProvider).streamChat(
              modelPath: config.localModelPath!,
              systemPrompt: systemPrompt,
              history: withUser,
              isCancelled: () => _cancelRequested,
            ),
      };

      await for (final token in tokenStream) {
        if (_cancelRequested) break;
        buffer.write(token);
        final updated = placeholder.copyWith(content: buffer.toString());
        state = AsyncData([...withUser, updated]);
      }

      final parsed = _toolParser.parse(
        buffer.toString(),
        messageId: assistantId,
      );
      final finalContent = parsed.cleanText.isEmpty && parsed.actions.isEmpty
          ? (_cancelRequested
              ? 'تم إيقاف التوليد.'
              : 'لم يصل رد من المساعد. حاول صياغة طلبك مرة أخرى.')
          : (parsed.cleanText.isEmpty
              ? 'جهّزت لك الإجراء التالي للموافقة:'
              : parsed.cleanText);
      final finalMsg = placeholder.copyWith(
        content: finalContent,
        proposedActions: parsed.actions,
      );
      final saved = [...withUser, finalMsg];
      state = AsyncData(saved);
      await _persistMessages(saved);
    } catch (e) {
      final failure = AppFailure.from(e);
      final errMsg = placeholder.copyWith(
        content: failure.userMessage,
        isError: true,
      );
      final saved = [...withUser, errMsg];
      state = AsyncData(saved);
      await _persistMessages(saved);
    } finally {
      _cancelRequested = false;
      ref.read(aiIsStreamingProvider.notifier).state = false;
    }
  }

  Future<void> _appendSystemNotice(String message) async {
    final currentList = state.valueOrNull ?? const <AiMessage>[];
    final msg = AiMessage(
      id: 'err_${DateTime.now().microsecondsSinceEpoch}',
      role: AiRole.assistant,
      content: message,
      createdAt: DateTime.now(),
      isError: true,
    );
    final next = [...currentList, msg];
    state = AsyncData(next);
    await _persistMessages(next);
  }

  String _buildSystemPrompt({bool isLocal = false}) {
    final perms = ref.read(aiPermissionsProvider);
    final summaryApproved = ref.read(aiReflectionSummaryApprovedProvider);
    final activities = ref.read(activitiesProvider).valueOrNull ?? const [];
    final prayerSchedule = ref.read(prayerScheduleProvider).valueOrNull;
    final reflections = ref.read(reflectionsProvider).valueOrNull ?? const [];
    final sessions = ref.read(workSessionsProvider).valueOrNull ?? const [];

    final snapshot = _contextBuilder.build(
      permissions: perms,
      activities: activities,
      prayerSchedule: prayerSchedule,
      reflections: reflections,
      workSessions: sessions,
      reflectionSummaryApproved: summaryApproved,
    );

    if (isLocal) {
      return '''
أنت "رباط"، رفيق ذكي ولطيف تساعد المسلم في تنظيم يومه ومشاعره حول الصلوات.
القواعد:
- أجب بعربية واضحة ومباشرة على قدر سؤال المستخدم فقط، بلا حشو ولا تكرار للتعريف بنفسك.
- إذا اشتكى من تعب أو ضغط، واسِهِ بلطف وقدّم خطوة واحدة بسيطة، ولا تسرد كل مهامه إلا إذا طلب ذلك.
- استخدم البيانات التالية كخلفية صامتة عند الحاجة فقط:

${snapshot.toPromptText()}
''';
    }

    return '''
أنت "رباط"، رفيق ذكي ومتزن عاطفياً داخل تطبيق "الرباط" (تطبيق تنظيم الحياة حول أوقات الصلاة).

شخصيتك وأسلوبك:
- إنساني، دافئ، صادق، وذو بصيرة؛ تتكلم بعربية فصحى سلسة قريبة من القلب، بلا تكلف ولا عبارات آلية.
- إذا عبّر المستخدم عن تعب أو ضيق أو فتور أو تشتت، احتوِ شعوره أولاً بتفهم حقيقي ولطيف، ثم اقترح خطوة واحدة خفيفة أو خيارين واقعيين، ولا تُمطرْه بقوائم مهام أو وعظٍ طويل.
- لا تعرّف بنفسك ("أنا رباط مساعدك الشخصي...") في ردودك إلا إذا سُئلت عن ذلك صراحةً.
- التحية تُرد بتحية دافئة ومختصرة فقط؛ ولا تسرد بيانات المستخدم أو تلخص مهامه ومشاريعه إلا إذا طلب ذلك أو كان ذكر معلومة محددة ضرورياً لحل ما يشتكي منه.
- اجعل كل كلمة في ردك مرتبطة مباشرة بسؤال المستخدم وحالته، وتجنب الحشو والمقدمات المكررة.
- استخدم Markdown بهدوء عند الحاجة لتوضيح خطة أو خطوات (نقاط قصيرة أو خط عريض خفيف)، وتجنب الجداول الطويلة ما لم تُطلب.

كيف توظف بيانات المستخدم (خلفية صامتة):
- البيانات المرفقة أدناه هي معرفتك الصامتة بواقعه؛ استعن بها بذكاء عند التخطيط أو التنبيه لمشكلة حقيقية (مثل تكدس مهام بين المغرب والعشاء)، دون استعراضها بلا سبب.
- عندما يطلب المستخدم إضافة أو تعديل أو حذف مهمة أو إنشاء مشروع، أضف في نهاية ردك كتلة JSON بهذا الشكل الدقيق ليؤكدها المستخدم:
```ribat_action
{"action":"add_activity","title":"اسم المهمة","repetition":"daily|once|open","type":"afterPrayer|beforePrayer|independent","linkedPrayer":"fajr|dhuhr|asr|maghrib|isha","projectName":"اسم المشروع اختياري"}
```
أو لتعديل نشاط موجود:
```ribat_action
{"action":"edit_activity","targetTitle":"اسم النشاط الحالي","newTitle":"اختياري","newRepetition":"daily|once|open","newType":"afterPrayer|beforePrayer|independent","newLinkedPrayer":"fajr|dhuhr|asr|maghrib|isha"}
```
أو لحذف نشاط موجود:
```ribat_action
{"action":"delete_activity","targetTitle":"اسم النشاط"}
```
أو لإنشاء مشروع:
```ribat_action
{"action":"create_project","name":"اسم المشروع","description":"وصف قصير","tasks":["مهمة 1","مهمة 2"]}
```

خلفية المستخدم الصامتة (المصرح بها):
${snapshot.toPromptText()}
''';
  }
}
