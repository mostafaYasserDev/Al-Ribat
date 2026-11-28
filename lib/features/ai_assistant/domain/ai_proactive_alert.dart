enum ProactiveAlertType {
  schedulingConflict,
  commitmentNudge,
  focusBalance,
}

class AiProactiveAlert {
  const AiProactiveAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.suggestedPrompt,
  });

  final String id;
  final ProactiveAlertType type;
  final String title;
  final String body;
  final String suggestedPrompt;
}
