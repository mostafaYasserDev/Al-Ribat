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

final aiChatProvider =
    AsyncNotifierProvider<AiChatNotifier, List<AiMessage>>(AiChatNotifier.new);

class AiChatNotifier extends AsyncNotifier<List<AiMessage>> {
  static const _contextBuilder = LocalContextBuilder();
  static const _summarizer = LocalReflectionSummarizer();
  static const _toolParser = AiToolParser();
  static const _toolExecutor = AiToolExecutor();

  @override
  Future<List<AiMessage>> build() async {
    return ref.read(aiConversationRepoProvider).loadAll();
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
    await ref.read(aiConversationRepoProvider).saveAll(next);
  }

  ReflectionSummary previewReflectionSummary() {
    final reflections = ref.read(reflectionsProvider).valueOrNull ?? const [];
    return _summarizer.summarize(reflections);
  }

  Future<void> clearHistory() async {
    await ref.read(aiConversationRepoProvider).clear();
    state = const AsyncData([]);
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
    ref.read(aiIsStreamingProvider.notifier).state = true;

    try {
      final systemPrompt = _buildSystemPrompt();
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
            ),
      };

      await for (final token in tokenStream) {
        buffer.write(token);
        final updated = placeholder.copyWith(content: buffer.toString());
        state = AsyncData([...withUser, updated]);
      }

      final parsed = _toolParser.parse(
        buffer.toString(),
        messageId: assistantId,
      );
      final finalContent = parsed.cleanText.isEmpty && parsed.actions.isEmpty
          ? 'لم يصل رد من المساعد. حاول صياغة طلبك مرة أخرى.'
          : (parsed.cleanText.isEmpty
              ? 'جهّزت لك الإجراء التالي للموافقة:'
              : parsed.cleanText);
      final finalMsg = placeholder.copyWith(
        content: finalContent,
        proposedActions: parsed.actions,
      );
      final saved = [...withUser, finalMsg];
      state = AsyncData(saved);
      await ref.read(aiConversationRepoProvider).saveAll(saved);
    } catch (e) {
      final failure = AppFailure.from(e);
      final errMsg = placeholder.copyWith(
        content: failure.userMessage,
        isError: true,
      );
      final saved = [...withUser, errMsg];
      state = AsyncData(saved);
      await ref.read(aiConversationRepoProvider).saveAll(saved);
    } finally {
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
    await ref.read(aiConversationRepoProvider).saveAll(next);
  }

  String _buildSystemPrompt() {
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

    return '''
أنت "رباط"، مساعد شخصي ذكي مدمج في تطبيق "الرباط" لتنظيم حياة المسلم حول أوقات الصلاة.
قواعدك:
1. تحدث باللغة العربية الفصحى السلسة والدافئة والمحترمة.
2. استند في نصائحك إلى بيانات المستخدم الحقيقية المتاحة أدناه فقط، ولا تخترع بيانات غير موجودة.
3. نبّه المستخدم بلطف إذا لاحظت ضغطاً في جدول المهام (مثلاً تكدس مهام كثيرة بين المغرب والعشاء أو تراجع الإنجاز).
4. قدّم خطوات عملية مختصرة وقابلة للتنفيذ.
5. عندما يطلب المستخدم إضافة مهمة أو إنشاء مشروع، أضف في نهاية ردك كتلة JSON بهذا الشكل الدقيق ليؤكدها المستخدم:
```ribat_action
{"action":"add_activity","title":"اسم المهمة","repetition":"daily|once|open","type":"afterPrayer|beforePrayer|independent","linkedPrayer":"fajr|dhuhr|asr|maghrib|isha","projectName":"اسم المشروع اختياري"}
```
أو لإنشاء مشروع:
```ribat_action
{"action":"create_project","name":"اسم المشروع","description":"وصف قصير","tasks":["مهمة 1","مهمة 2"]}
```

بيانات المستخدم المصرح لك بالاطلاع عليها:
${snapshot.toPromptText()}
''';
  }
}
