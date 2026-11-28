enum ToolActionStatus { pending, executed, dismissed }

sealed class AiToolCall {
  const AiToolCall();

  Map<String, dynamic> toJson();

  static AiToolCall? fromJson(Map<String, dynamic> json) {
    final action = json['action'] as String?;
    return switch (action) {
      'add_activity' => AddActivityToolCall(
          title: (json['title'] as String? ?? '').trim(),
          repetition: json['repetition'] as String? ?? 'daily',
          projectName: (json['projectName'] as String?)?.trim(),
          linkedPrayer: (json['linkedPrayer'] as String?)?.trim(),
          type: json['type'] as String? ?? 'independent',
        ),
      'edit_activity' => EditActivityToolCall(
          targetTitle: (json['targetTitle'] as String? ?? '').trim(),
          newTitle: (json['newTitle'] as String?)?.trim(),
          newRepetition: (json['newRepetition'] as String?)?.trim(),
          newType: (json['newType'] as String?)?.trim(),
          newLinkedPrayer: (json['newLinkedPrayer'] as String?)?.trim(),
        ),
      'delete_activity' => DeleteActivityToolCall(
          targetTitle: (json['targetTitle'] as String? ?? '').trim(),
        ),
      'create_project' => CreateProjectToolCall(
          name: (json['name'] as String? ?? '').trim(),
          description: (json['description'] as String?)?.trim(),
          tasks: (json['tasks'] as List<dynamic>?)
                  ?.map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const [],
        ),
      _ => null,
    };
  }
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

  @override
  Map<String, dynamic> toJson() => {
        'action': 'add_activity',
        'title': title,
        'repetition': repetition,
        'projectName': projectName,
        'linkedPrayer': linkedPrayer,
        'type': type,
      };
}

class EditActivityToolCall extends AiToolCall {
  const EditActivityToolCall({
    required this.targetTitle,
    this.newTitle,
    this.newRepetition,
    this.newType,
    this.newLinkedPrayer,
  });

  final String targetTitle;
  final String? newTitle;
  final String? newRepetition;
  final String? newType;
  final String? newLinkedPrayer;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'edit_activity',
        'targetTitle': targetTitle,
        'newTitle': newTitle,
        'newRepetition': newRepetition,
        'newType': newType,
        'newLinkedPrayer': newLinkedPrayer,
      };
}

class DeleteActivityToolCall extends AiToolCall {
  const DeleteActivityToolCall({required this.targetTitle});

  final String targetTitle;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'delete_activity',
        'targetTitle': targetTitle,
      };
}

class CreateProjectToolCall extends AiToolCall {
  const CreateProjectToolCall({
    required this.name,
    this.description,
    this.tasks = const [],
  });

  final String name;
  final String? description;
  final List<String> tasks;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_project',
        'name': name,
        'description': description,
        'tasks': tasks,
      };
}

class ProposedToolAction {
  const ProposedToolAction({
    required this.id,
    required this.call,
    this.status = ToolActionStatus.pending,
  });

  final String id;
  final AiToolCall call;
  final ToolActionStatus status;

  ProposedToolAction copyWith({ToolActionStatus? status}) {
    return ProposedToolAction(
      id: id,
      call: call,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'call': call.toJson(),
        'status': status.name,
      };

  static ProposedToolAction? fromJson(Map<String, dynamic> json) {
    final callMap = json['call'];
    if (callMap is! Map<String, dynamic>) return null;
    final call = AiToolCall.fromJson(callMap);
    if (call == null) return null;
    final statusName = json['status'] as String?;
    final status = ToolActionStatus.values
            .where((e) => e.name == statusName)
            .firstOrNull ??
        ToolActionStatus.pending;
    return ProposedToolAction(
      id: json['id'] as String? ?? 'act_0',
      call: call,
      status: status,
    );
  }
}
