import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/errors/app_failure.dart';
import '../domain/ai_message.dart';
import '../domain/ai_provider_config.dart';

class GroqClient {
  GroqClient({HttpClient? httpClient}) : _httpClient = httpClient;

  static final Uri _endpoint =
      Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  final HttpClient? _httpClient;

  Stream<String> streamChat({
    required String apiKey,
    required String systemPrompt,
    required List<AiMessage> history,
    String model = AiProviderConfig.defaultGroqModel,
  }) async* {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const ValidationFailure('يرجى إدخال مفتاح Groq API أولاً.');
    }

    final client = _httpClient ?? HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    final shouldClose = _httpClient == null;

    try {
      final req = await client.postUrl(_endpoint);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $trimmedKey');

      final payload = <String, dynamic>{
        'model': model,
        'stream': true,
        'temperature': 0.7,
        'max_tokens': 1024,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...history
              .where((m) => !m.isError && m.role != AiRole.system)
              .take(16)
              .map(
                (m) => {
                  'role': m.role == AiRole.user ? 'user' : 'assistant',
                  'content': m.content,
                },
              ),
        ],
      };

      req.add(utf8.encode(jsonEncode(payload)));
      final res = await req.close();

      if (res.statusCode == 401 || res.statusCode == 403) {
        throw const ValidationFailure(
          'مفتاح Groq غير صالح أو منتهي الصلاحية. تحقق منه في الإعدادات.',
        );
      }
      if (res.statusCode == 429) {
        throw const ValidationFailure(
          'تم تجاوز حد الطلبات المؤقت على Groq. انتظر قليلاً ثم أعد المحاولة.',
        );
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw UnknownFailure(
          fallback: 'تعذر الاتصال بخدمة Groq (رمز ${res.statusCode}).',
        );
      }

      await for (final line
          in res.transform(utf8.decoder).transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
        final data = trimmed.substring(5).trim();
        if (data == '[DONE]') break;

        try {
          final json = jsonDecode(data);
          if (json is! Map<String, dynamic>) continue;
          final choices = json['choices'];
          if (choices is! List || choices.isEmpty) continue;
          final delta = choices.first['delta'];
          if (delta is Map<String, dynamic>) {
            final token = delta['content'] as String?;
            if (token != null && token.isNotEmpty) {
              yield token;
            }
          }
        } catch (_) {
          // Ignore malformed SSE chunks safely.
        }
      }
    } on AppFailure {
      rethrow;
    } on SocketException {
      throw const UnknownFailure(
        fallback: 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة ثم أعد المحاولة.',
      );
    } on TimeoutException {
      throw const UnknownFailure(
        fallback: 'انتهت مهلة الاتصال بخدمة Groq. حاول مجدداً.',
      );
    } catch (e) {
      throw AppFailure.from(e);
    } finally {
      if (shouldClose) {
        client.close();
      }
    }
  }
}
