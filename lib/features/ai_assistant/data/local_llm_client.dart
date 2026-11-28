import 'dart:async';
import 'dart:io';

import 'package:flutter_local_llm/flutter_local_llm.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/ai_message.dart';

class LocalLlmClient {
  LocalLlmEngine? _engine;
  String? _loadedModelPath;

  Stream<String> streamChat({
    required String modelPath,
    required String systemPrompt,
    required List<AiMessage> history,
  }) async* {
    final file = File(modelPath);
    if (!await file.exists()) {
      throw const ValidationFailure(
        'ملف النموذج المحلي غير موجود. أعد تنزيله من الإعدادات.',
      );
    }

    try {
      if (_engine == null ||
          _engine!.isDisposed ||
          _loadedModelPath != modelPath) {
        _engine?.dispose();
        _engine = await LocalLlmEngine.loadModel(
          modelPath: modelPath,
          params: const ModelParams(contextSize: 2048),
        );
        _loadedModelPath = modelPath;
      }

      final session = _engine!.createSession();
      try {
        final messages = <ChatMessage>[
          ChatMessage.system(systemPrompt),
          for (final m in history.where((m) => !m.isError).take(12))
            if (m.role == AiRole.user)
              ChatMessage.user(m.content)
            else if (m.role == AiRole.assistant)
              ChatMessage.assistant(m.content),
        ];

        await for (final token in session.chat(messages)) {
          if (token.isNotEmpty) yield token;
        }
      } finally {
        session.dispose();
      }
    } on LlmException catch (e) {
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

  void dispose() {
    _engine?.dispose();
    _engine = null;
    _loadedModelPath = null;
  }
}
