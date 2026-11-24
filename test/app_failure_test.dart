import 'package:al_ribat/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFailure.from', () {
    test('passes an existing AppFailure through unchanged', () {
      const failure = StorageFailure();
      expect(AppFailure.from(failure), same(failure));
    });

    test('maps location errors to a helpful Arabic message', () {
      final failure =
          AppFailure.from(Exception('Geolocator permission denied'));
      expect(failure, isA<LocationFailure>());
      expect(failure.userMessage, contains('المدينة يدوياً'));
    });

    test('maps permission errors to a guidance message', () {
      final failure = AppFailure.from(Exception('permission denied'));
      expect(failure, isA<PermissionFailure>());
      expect(failure.userMessage, contains('إعدادات التطبيق'));
    });

    test('maps sync errors without leaking raw exception text', () {
      final failure = AppFailure.from(Exception('Firestore unavailable'));
      expect(failure, isA<SyncFailure>());
      expect(failure.userMessage, isNot(contains('Firestore')));
    });

    test('uses a custom fallback for unknown errors', () {
      final failure = AppFailure.from(
        Object(),
        fallback: 'تعذر حفظ التغييرات.',
      );
      expect(failure, isA<UnknownFailure>());
      expect(failure.userMessage, 'تعذر حفظ التغييرات.');
    });

    test('keeps technical details out of the user message', () {
      final failure = AppFailure.from(const FormatException('bad json'));
      expect(failure.userMessage, isNot(contains('bad json')));
      expect(failure.debugMessage, contains('bad json'));
    });
  });
}
