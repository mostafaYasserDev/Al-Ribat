// ═══════════════════════════════════════════════════════════════════════════
// تخصيص «دعم المطوّر»: عدّل القيم التالية ثم أضف صورتك تحت assets/developer/
// ═══════════════════════════════════════════════════════════════════════════

/// بياناتك الظاهرة في شاشة «دعم المطوّر».
abstract final class DeveloperProfile {
  /// **اسمك** كما تريد أن يظهر للمستخدمين.
  static const String displayName = 'مصطفى ياسر (LapNight)';

  /// نبذة قصيرة (سطر أو سطران).
  static const String shortBio =
      'انا مصطفى، مطور سوفتوير وصانع محتوى.. تقدر تتابعني على وسائل التواصل من الروابط اللي تحت.. قناة التليجرام هي قناة شخصية ملهاش علاقة بالمحتوى اللي بنشره على باقي المنصات ف مش مهم تشترتك فيها بس خد لفة لو عجبتك تنورني';

  /// مسار الصورة داخل المشروع (ضع الملف في `assets/developer/`).
  static const String photoAsset = 'assets/developer/photo.jpg';

  /// رابط الدفع (يفتح في المتصفح إذا بدأ بـ http/https، وإلا يُنسَخ كنص).
  static const String vodafoneCashHint = 'رابط الدعم عبر فودافون كاش';
  static const String vodafoneCashValue = 'http://vf.eg/vfcash?id=mt&qrId=DBsLLW';

  static const String instapayHint = 'رابط أو معرف إنستا باي';
  static const String instapayUrl = 'https://ipn.eg/S/mostafayasserdev/instapay/0TMgfK';

  static const String paypalHint = 'رابط الدعم عبر PayPal';
  static const String paypalUrl = 'https://paypal.me/mostafayasserdev';

  static const String instagramUrl = 'https://www.instagram.com/lapnight.tech/';
  static const String youtubeUrl = 'https://www.youtube.com/@LapNight';
  static const String tiktokUrl = 'https://www.tiktok.com/@lapnight.tech';
  static const String facebookUrl = 'https://www.facebook.com/LapNight.eg/';

  /// قناة أو حساب تيليجرام (رابط https://t.me/...).
  static const String telegramUrl = 'https://t.me/mostafaYasserDev';
}
