class ReflectionEntry {
  const ReflectionEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.mood,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String? mood;
}
