import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/errors/app_failure.dart';
import '../domain/ai_message.dart';

class LocalLlmClient {
  const LocalLlmClient();

  /// Streams local inference from a downloaded GGUF file if `llama-cli` is
  /// available on the host; otherwise returns a clear setup guidance error.
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

    final binary = await _findLlamaCli();
    if (binary == null) {
      throw const ValidationFailure(
        'ملف النموذج محمّل وجاهز، لكن محرك التشغيل المحلي (llama-cli) غير مثبّت على هذا الجهاز بعد. يمكنك التبديل إلى Groq السحابي أو تثبيت llama-cli.',
      );
    }

    final prompt = _buildChatPrompt(systemPrompt, history);
    final process = await Process.start(binary, [
      '-m',
      modelPath,
      '-p',
      prompt,
      '-n',
      '512',
      '--temp',
      '0.7',
      '--no-display-prompt',
    ]);

    await for (final chunk in process.stdout.transform(utf8.decoder)) {
      if (chunk.isNotEmpty) yield chunk;
    }

    final code = await process.exitCode;
    if (code != 0) {
      throw UnknownFailure(
        fallback: 'توقف محرك التشغيل المحلي بشكل غير متوقع (رمز $code).',
      );
    }
  }

  Future<String?> _findLlamaCli() async {
    if (!Platform.isLinux && !Platform.isMacOS) return null;
    try {
      final result = await Process.run('which', ['llama-cli']);
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim();
        if (path.isNotEmpty) return path;
      }
    } catch (_) {}
    return null;
  }

  String _buildChatPrompt(String systemPrompt, List<AiMessage> history) {
    final buf = StringBuffer()
      ..writeln('<|system|>')
      ..writeln(systemPrompt);
    for (final msg in history.where((m) => !m.isError).take(8)) {
      final tag = msg.role == AiRole.user ? '<|user|>' : '<|assistant|>';
      buf
        ..writeln(tag)
        ..writeln(msg.content);
    }
    buf.writeln('<|assistant|>');
    return buf.toString();
  }
}
