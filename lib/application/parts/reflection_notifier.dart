part of '../providers.dart';

final reflectionsProvider =
    AsyncNotifierProvider<ReflectionNotifier, List<ReflectionEntry>>(
  ReflectionNotifier.new,
);

class ReflectionNotifier extends AsyncNotifier<List<ReflectionEntry>> {
  ReflectionRepository get _repo => ref.read(reflectionRepositoryProvider);

  @override
  Future<List<ReflectionEntry>> build() async {
    return ref.watch(reflectionRepositoryProvider).loadAll();
  }

  Future<void> add(
    String text, {
    String? mood,
    String? prayerPhaseName,
    String? linkedContextTitle,
    DateTime? createdAt,
  }) async {
    final at = createdAt ?? DateTime.now();
    final entry = ReflectionEntry(
      id: at.microsecondsSinceEpoch.toString(),
      text: text.trim(),
      createdAt: at,
      mood: mood,
      prayerPhaseName: prayerPhaseName,
      linkedContextTitle: linkedContextTitle,
    );
    await _repo.add(entry);
    state = AsyncData(await _repo.loadAll());
  }

  Future<void> updateReflection(
    ReflectionEntry oldEntry,
    String newText, {
    String? newMood,
    String? linkedContextTitle,
    bool clearLinkedContext = false,
  }) async {
    final editRecord = ReflectionEditRecord(
      editedAt: DateTime.now(),
      oldText: oldEntry.text,
      oldMood: oldEntry.mood,
    );

    final updatedEntry = oldEntry.copyWith(
      text: newText.trim(),
      mood: newMood,
      clearMood: newMood == null,
      linkedContextTitle: linkedContextTitle,
      clearLinkedContext: clearLinkedContext,
      editHistory: [...oldEntry.editHistory, editRecord],
    );

    await _repo.update(updatedEntry);
    state = AsyncData(await _repo.loadAll());
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.loadAll());
  }
}
