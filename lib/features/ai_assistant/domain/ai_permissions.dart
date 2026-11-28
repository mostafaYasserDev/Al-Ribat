class AiPermissions {
  const AiPermissions({
    this.allowActivities = true,
    this.allowPrayer = true,
    this.allowProjects = true,
    this.allowReflections = false,
    this.allowReflectionSummary = true,
    this.allowWorkSessions = true,
  });

  final bool allowActivities;
  final bool allowPrayer;
  final bool allowProjects;
  final bool allowReflections;
  final bool allowReflectionSummary;
  final bool allowWorkSessions;

  AiPermissions copyWith({
    bool? allowActivities,
    bool? allowPrayer,
    bool? allowProjects,
    bool? allowReflections,
    bool? allowReflectionSummary,
    bool? allowWorkSessions,
  }) {
    return AiPermissions(
      allowActivities: allowActivities ?? this.allowActivities,
      allowPrayer: allowPrayer ?? this.allowPrayer,
      allowProjects: allowProjects ?? this.allowProjects,
      allowReflections: allowReflections ?? this.allowReflections,
      allowReflectionSummary:
          allowReflectionSummary ?? this.allowReflectionSummary,
      allowWorkSessions: allowWorkSessions ?? this.allowWorkSessions,
    );
  }

  Map<String, dynamic> toJson() => {
        'allowActivities': allowActivities,
        'allowPrayer': allowPrayer,
        'allowProjects': allowProjects,
        'allowReflections': allowReflections,
        'allowReflectionSummary': allowReflectionSummary,
        'allowWorkSessions': allowWorkSessions,
      };

  factory AiPermissions.fromJson(Map<String, dynamic> json) {
    return AiPermissions(
      allowActivities: json['allowActivities'] as bool? ?? true,
      allowPrayer: json['allowPrayer'] as bool? ?? true,
      allowProjects: json['allowProjects'] as bool? ?? true,
      allowReflections: json['allowReflections'] as bool? ?? false,
      allowReflectionSummary: json['allowReflectionSummary'] as bool? ?? true,
      allowWorkSessions: json['allowWorkSessions'] as bool? ?? true,
    );
  }
}
