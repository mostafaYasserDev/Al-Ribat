part of '../templates_sheet.dart';

const List<ActivityTemplate> _digitalWellnessTemplates = [
  ActivityTemplate(
    title: 'صباح بلا تصفح عشوائي',
    description: 'عدم فتح مواقع التواصل أول 45 دقيقة بعد الاستيقاظ',
    type: ActivityType.afterPrayer,
    linkedPrayer: PrayerPhase.fajr,
    iconName: 'phonelink_off',
    colorHex: '#6366F1',
    isMeasurable: true,
    targetGoal: 45,
    goalUnit: 'دقيقة',
  ),
  ActivityTemplate(
    title: 'ترك الشاشات قبل النوم',
    description: 'إبعاد الهاتف قبل النوم بـ 30 دقيقة لنوم أعمق',
    type: ActivityType.afterPrayer,
    linkedPrayer: PrayerPhase.isha,
    iconName: 'bedtime',
    colorHex: '#3B82F6',
    isMeasurable: true,
    targetGoal: 30,
    goalUnit: 'دقيقة',
  ),
  ActivityTemplate(
    title: 'قيلولة السُّنّة',
    description: 'راحة خفيفة 20 دقيقة لتجديد النشاط بعد الظهر',
    type: ActivityType.afterPrayer,
    linkedPrayer: PrayerPhase.dhuhr,
    iconName: 'snooze',
    colorHex: '#0EA5E9',
    isMeasurable: true,
    targetGoal: 20,
    goalUnit: 'دقيقة',
  ),
  ActivityTemplate(
    title: 'نوم مبكر منتظم',
    description: 'الاستعداد للنوم قبل الساعة 11 مساءً للاستيقاظ للفجر',
    type: ActivityType.independent,
    iconName: 'nights_stay',
    colorHex: '#4F46E5',
  ),
  ActivityTemplate(
    title: 'تنظيف الإشعارات والتطبيقات',
    description: 'إلغاء الإشعارات المشتتة ومتابعة الحسابات المفيدة فقط',
    type: ActivityType.independent,
    iconName: 'notifications_off',
    colorHex: '#EC4899',
    repetition: ActivityRepetition.weekly,
  ),
  ActivityTemplate(
    title: 'خلوة أسبوعية بلا إنترنت',
    description: 'ساعتان للطبيعة أو العائلة أو القراءة الورقية',
    type: ActivityType.independent,
    iconName: 'nature_people',
    colorHex: '#10B981',
    repetition: ActivityRepetition.weekly,
    isMeasurable: true,
    targetGoal: 120,
    goalUnit: 'دقيقة',
  ),
];

const Map<String, dynamic> _digitalWellness = {
  'name': 'الهدوء الرقمي والنوم',
  'templates': _digitalWellnessTemplates,
};
