import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/features/focus/focus.dart';

class _FakeWorkSessionRepo implements WorkSessionRepository {
  final List<WorkSessionItem> items = [];

  @override
  Future<List<WorkSessionItem>> loadAll() async => List.unmodifiable(items);

  @override
  Future<void> save(WorkSessionItem session) async => items.add(session);
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('FocusSessionMode and ActiveFocusState Tests', () {
    test('FocusSessionMode labels match expected Arabic text', () {
      expect(FocusSessionMode.untilPrayer.arabicLabel, 'الرباط حتى الأذان');
      expect(FocusSessionMode.pomodoro.arabicLabel, 'بومودورو ذكي');
      expect(FocusSessionMode.customTimer.arabicLabel, 'مؤقت مخصص');
      expect(FocusSessionMode.openStopwatch.arabicLabel, 'تركيز مفتوح');
    });

    test('ActiveFocusState supports mode and linked activity', () {
      final now = DateTime.now();
      final state = ActiveFocusState(
        title: 'قراءة الورد',
        plannedMinutes: 30,
        startedAt: now,
        remainingSeconds: 1800,
        mode: FocusSessionMode.untilPrayer,
        linkedActivityId: 'act_1',
        linkedActivityTitle: 'تلاوة سورة الكهف',
      );

      expect(state.mode, FocusSessionMode.untilPrayer);
      expect(state.linkedActivityId, 'act_1');
      expect(state.linkedActivityTitle, 'تلاوة سورة الكهف');
      expect(state.isBreak, isFalse);

      final breakState = state.copyWith(isBreak: true, title: 'استراحة');
      expect(breakState.isBreak, isTrue);
      expect(breakState.title, 'استراحة');
    });

    test('WorkSessionItem preserves new metadata', () {
      final now = DateTime.now();
      final session = WorkSessionItem(
        id: '1',
        name: 'كتابة التقرير',
        plannedMinutes: 25,
        startedAt: now.subtract(const Duration(minutes: 25)),
        endedAt: now,
        linkedActivityTitle: 'مهمة العمل',
        sessionMode: 'pomodoro',
      );

      expect(session.actualMinutes, 25);
      expect(session.linkedActivityTitle, 'مهمة العمل');
      expect(session.sessionMode, 'pomodoro');
    });
  });

  group('FocusTimeFormatter Tests', () {
    test('formatCountdown formats sub-hour as MM:SS and >=1h as HH:MM:SS', () {
      expect(FocusTimeFormatter.formatCountdown(0), '00:00');
      expect(FocusTimeFormatter.formatCountdown(59), '00:59');
      expect(FocusTimeFormatter.formatCountdown(25 * 60), '25:00');
      expect(FocusTimeFormatter.formatCountdown(3599), '59:59');
      expect(FocusTimeFormatter.formatCountdown(3600), '01:00:00');
      expect(FocusTimeFormatter.formatCountdown(3665), '01:01:05');
      expect(FocusTimeFormatter.formatCountdown(649 * 60), '10:49:00');
      expect(FocusTimeFormatter.formatCountdown(-10), '00:00');
    });

    test('formatDurationReadable formats minutes and hours cleanly in Arabic',
        () {
      expect(FocusTimeFormatter.formatDurationReadable(0), '0د');
      expect(FocusTimeFormatter.formatDurationReadable(25), '25د');
      expect(FocusTimeFormatter.formatDurationReadable(60), '1س');
      expect(FocusTimeFormatter.formatDurationReadable(90), '1س 30د');
      expect(FocusTimeFormatter.formatDurationReadable(649), '10س 49د');
      expect(FocusTimeFormatter.formatDurationReadable(-5), '0د');
    });
  });

  group('ActiveFocusNotifier Multi-Mode Tests', () {
    test('startPomodoro configures 25-minute pomodoro mode', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeFocusProvider.notifier);
      await notifier.startPomodoro(
        title: 'جلسة برمجة',
        linkedActivityId: 'act_dev',
        linkedActivityTitle: 'تطوير التطبيق',
      );

      final state = container.read(activeFocusProvider);
      expect(state, isNotNull);
      expect(state!.mode, FocusSessionMode.pomodoro);
      expect(state.plannedMinutes, 25);
      expect(state.remainingSeconds, 25 * 60);
      expect(state.linkedActivityId, 'act_dev');
    });

    test('startOpenStopwatch initializes zero remaining and counts up',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeFocusProvider.notifier);
      await notifier.startOpenStopwatch(title: 'بحث حر');

      final state = container.read(activeFocusProvider);
      expect(state, isNotNull);
      expect(state!.mode, FocusSessionMode.openStopwatch);
      expect(state.elapsedSeconds, 0);
    });

    test('startSession supports exact plannedSeconds', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeFocusProvider.notifier);
      await notifier.startSession(
        title: 'جلسة دقيقة بالثواني',
        plannedMinutes: 2,
        plannedSeconds: 95,
      );

      final state = container.read(activeFocusProvider);
      expect(state, isNotNull);
      expect(state!.plannedSeconds, 95);
      expect(state.remainingSeconds, 95);
    });

    test('linkActivity and clearLinkedActivity update active session',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activeFocusProvider.notifier);
      await notifier.startSession(title: 'قراءة', plannedMinutes: 25);

      notifier.linkActivity('act_99', 'مراجعة القرآن');
      expect(container.read(activeFocusProvider)?.linkedActivityId, 'act_99');
      expect(container.read(activeFocusProvider)?.linkedActivityTitle,
          'مراجعة القرآن');

      notifier.clearLinkedActivity();
      expect(container.read(activeFocusProvider)?.linkedActivityId, isNull);
      expect(container.read(activeFocusProvider)?.linkedActivityTitle, isNull);
    });

    test('savePartial ends and saves session immediately without 10m gate',
        () async {
      final fakeRepo = _FakeWorkSessionRepo();
      final container = ProviderContainer(
        overrides: [
          workSessionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(activeFocusProvider.notifier);
      await notifier.startSession(title: 'جلسة قصيرة', plannedMinutes: 25);
      expect(container.read(activeFocusProvider), isNotNull);

      final saved = await notifier.savePartial();
      expect(saved, isTrue);
      expect(container.read(activeFocusProvider), isNull);
      expect(fakeRepo.items.length, 1);
      expect(fakeRepo.items.first.name, 'جلسة قصيرة');
      expect(container.read(lastCompletedSessionProvider)?.name, 'جلسة قصيرة');
    });
  });
}
