import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:al_ribat/features/focus/focus.dart';

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

  group('AmbientSoundNotifier Tests', () {
    test('Changing soundscape updates isPlaying state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(ambientSoundProvider.notifier);
      expect(container.read(ambientSoundProvider).soundscape,
          AmbientSoundscape.silent);
      expect(container.read(ambientSoundProvider).isPlaying, isFalse);

      notifier.setSoundscape(AmbientSoundscape.rain);
      expect(container.read(ambientSoundProvider).soundscape,
          AmbientSoundscape.rain);
      expect(container.read(ambientSoundProvider).isPlaying, isTrue);

      notifier.setVolume(0.5);
      expect(container.read(ambientSoundProvider).volume, 0.5);
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
  });
}
