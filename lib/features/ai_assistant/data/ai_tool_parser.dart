import 'dart:convert';

import '../domain/ai_tool_call.dart';

class ParsedAiResponse {
  const ParsedAiResponse({
    required this.cleanText,
    required this.actions,
  });

  final String cleanText;
  final List<ProposedToolAction> actions;
}

class AiToolParser {
  const AiToolParser();

  static final RegExp _actionBlockRegex = RegExp(
    r'```ribat_action\s*([\s\S]*?)```',
    multiLine: true,
  );

  ParsedAiResponse parse(String rawResponse, {required String messageId}) {
    final actions = <ProposedToolAction>[];
    var idx = 0;

    final clean = rawResponse.replaceAllMapped(_actionBlockRegex, (match) {
      final jsonStr = (match.group(1) ?? '').trim();
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          final call = AiToolCall.fromJson(decoded);
          if (call != null && _isValidCall(call)) {
            actions.add(
              ProposedToolAction(
                id: '${messageId}_act_$idx',
                call: call,
              ),
            );
            idx++;
          }
        }
      } catch (_) {
        // Ignore malformed JSON action blocks safely.
      }
      return '';
    }).trim();

    return ParsedAiResponse(
      cleanText: clean,
      actions: actions,
    );
  }

  bool _isValidCall(AiToolCall call) => switch (call) {
        AddActivityToolCall(:final title) => title.isNotEmpty,
        EditActivityToolCall(:final targetTitle) => targetTitle.isNotEmpty,
        DeleteActivityToolCall(:final targetTitle) => targetTitle.isNotEmpty,
        CreateProjectToolCall(:final name) => name.isNotEmpty,
      };
}
