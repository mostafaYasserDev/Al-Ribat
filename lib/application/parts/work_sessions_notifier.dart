part of '../providers.dart';

final workSessionsProvider =
    AsyncNotifierProvider<WorkSessionsNotifier, List<WorkSessionItem>>(
  WorkSessionsNotifier.new,
);

class WorkSessionsNotifier extends AsyncNotifier<List<WorkSessionItem>> {
  WorkSessionRepository get _repo => ref.read(workSessionRepositoryProvider);

  @override
  Future<List<WorkSessionItem>> build() async {
    return ref.watch(workSessionRepositoryProvider).loadAll();
  }

  Future<void> addSession(WorkSessionItem session) async {
    await _repo.save(session);
    state = AsyncData(await _repo.loadAll());
  }
}
