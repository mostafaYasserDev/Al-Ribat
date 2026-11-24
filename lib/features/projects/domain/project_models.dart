class ProjectGroupInfo {
  final String name;
  final String? description;

  const ProjectGroupInfo({required this.name, this.description});

  Map<String, dynamic> toJson() => {'name': name, 'description': description};

  factory ProjectGroupInfo.fromJson(Map<String, dynamic> json) =>
      ProjectGroupInfo(
        name: json['name'] as String,
        description: json['description'] as String?,
      );
}

class ProjectDetailsInfo {
  final String? description;
  final String? iconName;
  final String? colorHex;

  const ProjectDetailsInfo({this.description, this.iconName, this.colorHex});

  Map<String, dynamic> toJson() => {
        'description': description,
        'iconName': iconName,
        'colorHex': colorHex,
      };

  factory ProjectDetailsInfo.fromJson(Map<String, dynamic> json) =>
      ProjectDetailsInfo(
        description: json['description'] as String?,
        iconName: json['iconName'] as String?,
        colorHex: json['colorHex'] as String?,
      );
}
