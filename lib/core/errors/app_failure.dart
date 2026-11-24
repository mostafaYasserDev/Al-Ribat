/// نموذج أخطاء موحّد لكل طبقات التطبيق.
///
/// الهدف: ألا تظهر رسائل Dart الخام للمستخدم، وأن تكون لكل حالة
/// رسالة عربية واضحة توضّح ما يمكنه فعله بعدها.
sealed class AppFailure implements Exception {
  const AppFailure(this.userMessage, {this.debugMessage});

  /// الرسالة التي تُعرض للمستخدم.
  final String userMessage;

  /// تفاصيل تقنية للتطوير فقط، لا تُعرض في الواجهة.
  final String? debugMessage;

  factory AppFailure.from(Object error, {String? fallback}) {
    if (error is AppFailure) return error;
    final text = error.toString().toLowerCase();

    if (text.contains('location') ||
        text.contains('geolocat') ||
        text.contains('موقع') ||
        text.contains('geocode')) {
      return LocationFailure(debugMessage: error.toString());
    }
    if (text.contains('permission') ||
        text.contains('إذن') ||
        text.contains('صلاحية')) {
      return PermissionFailure(debugMessage: error.toString());
    }
    if (text.contains('notification') || text.contains('إشعار')) {
      return NotificationFailure(debugMessage: error.toString());
    }
    if (text.contains('firebase') ||
        text.contains('firestore') ||
        text.contains('sync') ||
        text.contains('مزامنة') ||
        text.contains('sign_in') ||
        text.contains('تسجيل الدخول')) {
      return SyncFailure(debugMessage: error.toString());
    }
    if (error is FormatException ||
        text.contains('format') ||
        text.contains('صيغة')) {
      return ValidationFailure(
          'البيانات غير صالحة. تأكد من الملف وحاول مرة أخرى.',
          debugMessage: error.toString());
    }

    return UnknownFailure(fallback: fallback, debugMessage: error.toString());
  }
}

final class StorageFailure extends AppFailure {
  const StorageFailure({super.debugMessage})
      : super('تعذر حفظ البيانات. حاول مرة أخرى.');
}

final class LocationFailure extends AppFailure {
  const LocationFailure({super.debugMessage})
      : super('تعذر تحديد الموقع. يمكنك إدخال المدينة يدوياً من الإعدادات.');
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure({super.debugMessage})
      : super('الصلاحية مرفوضة. فعّلها من إعدادات التطبيق ثم حاول مرة أخرى.');
}

final class NotificationFailure extends AppFailure {
  const NotificationFailure({super.debugMessage})
      : super('تعذر ضبط الإشعارات. تأكد من تفعيل الإشعارات للتطبيق.');
}

final class SyncFailure extends AppFailure {
  const SyncFailure({super.debugMessage})
      : super('تعذرت المزامنة الآن. بياناتك محفوظة محلياً، حاول لاحقاً.');
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.userMessage, {super.debugMessage});
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({String? fallback, super.debugMessage})
      : super(fallback ?? 'حدث خطأ غير متوقع. حاول مرة أخرى.');
}
