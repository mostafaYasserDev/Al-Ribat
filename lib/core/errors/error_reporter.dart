import 'package:flutter/foundation.dart';

/// نقطة واحدة لتسجيل الأخطاء التقنية أثناء التطوير.
///
/// لا تُعرض هذه التفاصيل للمستخدم أبداً؛ الواجهة تستخدم [AppFailure.userMessage].
void reportError(String context, Object error, [StackTrace? stack]) {
  debugPrint('[$context] $error');
  if (stack != null) debugPrint(stack.toString());
}
