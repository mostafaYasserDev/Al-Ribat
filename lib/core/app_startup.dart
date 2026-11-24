/// حالة تهيئة الخدمات عند بدء التطبيق.
///
/// تُستخدم لإخبار المستخدم مبكراً أن المزامنة السحابية غير متاحة،
/// بدلاً من إخفاء سبب الفشل حتى يحاول تسجيل الدخول.
class AppStartup {
  static String? firebaseErrorMessage;

  static bool get isFirebaseReady => firebaseErrorMessage == null;

  static void recordFirebaseFailure(Object error) {
    firebaseErrorMessage = error.toString();
  }
}
