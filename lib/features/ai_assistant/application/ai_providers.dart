import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../application/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../data/ai_conversation_hive_repo.dart';
import '../data/ai_settings_hive_repo.dart';
import '../data/groq_client.dart';
import '../data/local_context_builder.dart';
import '../data/local_reflection_summarizer.dart';
import '../domain/ai_context_snapshot.dart';
import '../domain/ai_message.dart';
import '../domain/ai_permissions.dart';
import '../domain/ai_provider_config.dart';

final aiSettingsRepoProvider = Provider<AiSettingsHiveRepo>((ref) {
  return AiSettingsHiveRepo(Hive.box<String>('meta_box'));
});

final aiConversationRepoProvider = Provider<AiConversationHiveRepo>((ref) {
  return AiConversationHiveRepo(Hive.box<String>('meta_box'));
});

final groqClientProvider = Provider<GroqClient>((ref) => GroqClient());

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

final aiPermissionsProvider =
    NotifierProvider<AiPermissionsNotifier, AiPermissions>(
  AiPermissionsNotifier.new,
);

class AiPermissionsNotifier extends Notifier<AiPermissions> {
  @override
  AiPermissions build() {
    return ref.read(aiSettingsRepoProvider).loadPermissions();
  }

  Future<void> updatePermissions(AiPermissions next) async {
    state = next;
    await ref.read(aiSettingsRepoProvider).savePermissions(next);
  }
}

final aiReflectionSummaryApprovedProvider = StateProvider<bool>((ref) => false);

final aiIsStreamingProvider = StateProvider<bool>((ref) => false);

final aiChatProvider =
    AsyncNotifierProvider<AiChatNotifier, List<AiMessage>>(AiChatNotifier.new);

class AiChatNotifier extends AsyncNotifier<List<AiMessage>> {
  static const _contextBuilder = LocalContextBuilder();
  static const _summarizer = LocalReflectionSummarizer();

  @override
  Future<List<AiMessage>> build() async {
    return ref.read(aiConversationRepoProvider).loadAll();
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
    if (config.type == AiProviderType.localLlm) {
      await _appendSystemNotice(
        'الوضع المحلي قيد التجهيز للمرحلة القادمة. يمكنك حالياً التبديل إلى Groq السحابي من الإعدادات.',
      );
      return;
    }
    if (!config.isConfigured) {
      await _appendSystemNotice(
        'يرجى إكمال إعداد مفتاح Groq API أولاً لتتمكن من بدء المحادثة.',
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
      final client = ref.read(groqClientProvider);
      final buffer = StringBuffer();

      await for (final token in client.streamChat(
        apiKey: config.groqApiKey!,
        model: config.groqModel,
        systemPrompt: systemPrompt,
        history: withUser,
      )) {
        buffer.write(token);
        final updated = placeholder.copyWith(content: buffer.toString());
        state = AsyncData([...withUser, updated]);
      }

      final finalContent = buffer.toString().trim();
      final finalMsg = placeholder.copyWith(
        content: finalContent.isEmpty
            ? 'لم يصل رد من المساعد. حاول صياغة طلبك مرة أخرى.'
            : finalContent,
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

بيانات المستخدم المصرح لك بالاطلاع عليها:
${snapshot.toPromptText()}
''';
  }
}
