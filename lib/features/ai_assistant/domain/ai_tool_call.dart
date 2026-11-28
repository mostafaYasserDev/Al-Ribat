sealed class AiToolCall {
  const AiToolCall();
}

class AddActivityToolCall extends AiToolCall {
  const AddActivityToolCall({
    required this.title,
    this.repetition = 'daily',
    this.projectName,
    this.linkedPrayer,
    this.type = 'independent',
  });

  final String title;
  final String repetition;
  final String? projectName;
  final String? linkedPrayer;
  final String type;
}

class CreateProjectToolCall extends AiToolCall {
  const CreateProjectToolCall({
    required this.name,
    this.tasks = const [],
  });

  final String name;
  final List<String> tasks;
}
