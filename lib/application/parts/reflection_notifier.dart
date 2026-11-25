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
    String? title,
    bool isPinned = false,
    String? colorKey,
    String? mood,
    List<String>? moods,
    String? prayerPhaseName,
    String? linkedContextTitle,
    DateTime? createdAt,
  }) async {
    final at = createdAt ?? DateTime.now();
    final cleanTitle = title?.trim();
    final entry = ReflectionEntry(
      id: at.microsecondsSinceEpoch.toString(),
      title: (cleanTitle != null && cleanTitle.isNotEmpty) ? cleanTitle : null,
      text: text.trim(),
      createdAt: at,
      isPinned: isPinned,
      colorKey: colorKey,
      mood: mood,
      moods: moods,
      prayerPhaseName: prayerPhaseName,
      linkedContextTitle: linkedContextTitle,
    );
    await _repo.add(entry);
    state = AsyncData(await _repo.loadAll());
  }

  Future<void> updateReflection(
    ReflectionEntry oldEntry,
    String newText, {
    String? title,
    bool clearTitle = false,
    bool? isPinned,
    String? colorKey,
    bool clearColor = false,
    String? newMood,
    List<String>? newMoods,
    String? linkedContextTitle,
    bool clearLinkedContext = false,
  }) async {
    final resolvedMoods =
        newMoods ?? (newMood != null ? [newMood] : const <String>[]);
    final moodsChanged = oldEntry.moods.length != resolvedMoods.length ||
        !oldEntry.moods.every(resolvedMoods.contains);
    final contentChanged = oldEntry.text != newText.trim() || moodsChanged;
    final editRecord = contentChanged
        ? ReflectionEditRecord(
            editedAt: DateTime.now(),
            oldText: oldEntry.text,
            oldMood: oldEntry.moods.isEmpty ? null : oldEntry.moods.join('، '),
          )
        : null;

    final cleanTitle = title?.trim();
    final effectiveClearTitle =
        clearTitle || (title != null && cleanTitle!.isEmpty);

    final updatedEntry = oldEntry.copyWith(
      title: (cleanTitle != null && cleanTitle.isNotEmpty) ? cleanTitle : null,
      clearTitle: effectiveClearTitle,
      text: newText.trim(),
      isPinned: isPinned,
      colorKey: colorKey,
      clearColor: clearColor,
      moods: resolvedMoods,
      clearMood: resolvedMoods.isEmpty,
      linkedContextTitle: linkedContextTitle,
      clearLinkedContext: clearLinkedContext,
      editHistory: editRecord != null
          ? [...oldEntry.editHistory, editRecord]
          : oldEntry.editHistory,
    );

    await _repo.update(updatedEntry);
    state = AsyncData(await _repo.loadAll());
  }

  Future<void> togglePin(ReflectionEntry entry) async {
    final updated = entry.copyWith(isPinned: !entry.isPinned);
    await _repo.update(updated);
    state = AsyncData(await _repo.loadAll());
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.loadAll());
  }
}
