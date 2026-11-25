import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:al_ribat/application/active_focus_provider.dart';
import 'package:al_ribat/core/theme/app_moods.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('AppMoods Tests', () {
    test('contains all expected Arabic moods', () {
      expect(AppMoods.options.length, 7);
      expect(AppMoods.find('سعيد')?.label, 'سعيد');
      expect(AppMoods.find('هادئ')?.label, 'هادئ');
      expect(AppMoods.find('ممتن')?.label, 'ممتن');
      expect(AppMoods.find('غير موجود'), isNull);
    });
  });

  group('ActiveFocusNotifier Tests', () {
    test('initial state is null (no active session)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(activeFocusProvider);
      expect(state, isNull);
    });

    test('startSession creates valid active session state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(activeFocusProvider.notifier).startSession(
            title: 'قراءة القرآن',
            plannedMinutes: 25,
          );

      final state = container.read(activeFocusProvider);
      expect(state, isNotNull);
      expect(state!.title, 'قراءة القرآن');
      expect(state.plannedMinutes, 25);
      expect(state.remainingSeconds, 25 * 60);
      expect(state.isPaused, isFalse);
      expect(state.canSavePartial, isTrue);
    });

    test('pauseSession and resumeSession toggle isPaused', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(activeFocusProvider.notifier).startSession(
            title: 'مراجعة',
            plannedMinutes: 15,
          );

      await container.read(activeFocusProvider.notifier).pauseSession();
      expect(container.read(activeFocusProvider)?.isPaused, isTrue);

      await container.read(activeFocusProvider.notifier).resumeSession();
      expect(container.read(activeFocusProvider)?.isPaused, isFalse);
    });

    test('cancelSession resets state to null', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(activeFocusProvider.notifier).startSession(
            title: 'مهمة',
            plannedMinutes: 20,
          );
      expect(container.read(activeFocusProvider), isNotNull);

      await container.read(activeFocusProvider.notifier).cancelSession();
      expect(container.read(activeFocusProvider), isNull);
    });
  });
}
