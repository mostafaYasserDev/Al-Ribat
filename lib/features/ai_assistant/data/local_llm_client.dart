import 'dart:async';
import 'dart:io';

import 'package:llamadart/llamadart.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/ai_message.dart';

class LocalLlmClient {
  LlamaEngine? _engine;
  String? _loadedModelPath;

  Stream<String> streamChat({
    required String modelPath,
    required String systemPrompt,
    required List<AiMessage> history,
    bool Function()? isCancelled,
  }) async* {
    final file = File(modelPath);
    if (!await file.exists()) {
      throw const ValidationFailure(
        'ملف النموذج المحلي غير موجود. أعد تنزيله من الإعدادات.',
      );
    }

    try {
      if (_engine == null || _loadedModelPath != modelPath) {
        await _engine?.dispose();
        _engine = await LlamaEngine.load(
          LlamaModel(ModelSource.path(modelPath)),
          params: const ModelParams(
            contextSize: 1536,
            numberOfThreads: 4,
          ),
        );
        _loadedModelPath = modelPath;
      }

      final validHistory =
          history.where((m) => !m.isError && m.role != AiRole.system).toList();
      final recentHistory = validHistory.length > 4
          ? validHistory.sublist(validHistory.length - 4)
          : validHistory;

      final messages = <LlamaChatMessage>[
        LlamaChatMessage.fromText(
          role: LlamaChatRole.system,
          text: systemPrompt,
        ),
        for (final m in recentHistory)
          if (m.role == AiRole.user)
            LlamaChatMessage.fromText(
              role: LlamaChatRole.user,
              text: m.content,
            )
          else if (m.role == AiRole.assistant)
            LlamaChatMessage.fromText(
              role: LlamaChatRole.assistant,
              text: m.content,
            ),
      ];

      final stream = _engine!
          .create(
            messages,
            params: const GenerationParams(
              maxTokens: 320,
              temp: 0.45,
              topP: 0.85,
              penalty: 1.15,
            ),
          )
          .textDeltas();

      await for (final token in stream) {
        if (isCancelled?.call() == true) {
          _engine?.cancelGeneration();
          break;
        }
        if (token.isNotEmpty) yield token;
      }
    } on LlamaException catch (e) {
      throw UnknownFailure(
        fallback:
            'تعذر تشغيل النموذج المحلي على هذا الجهاز. جرّب نموذجاً أخف أو استخدم السحابي.',
        debugMessage: e.toString(),
      );
    } catch (e) {
      throw AppFailure.from(
        e,
        fallback: 'حدث خطأ أثناء التشغيل المحلي للنموذج.',
      );
    }
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
    _loadedModelPath = null;
  }
}
