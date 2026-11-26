part of '../templates_sheet.dart';

const List<ActivityTemplate> _financeTemplates = [
  ActivityTemplate(
    title: 'صدقة يومية يسيرة',
    description: 'ولو بشق تمرة أو تحويل يسير لصدقة جارية',
    type: ActivityType.independent,
    iconName: 'volunteer_activism',
    colorHex: '#10B981',
  ),
  ActivityTemplate(
    title: 'تتبع المصروفات اليومية',
    description: 'تسجيل كل مصروف لرفع الوعي المالي',
    type: ActivityType.independent,
    iconName: 'receipt_long',
    colorHex: '#0EA5E9',
  ),
  ActivityTemplate(
    title: 'يوم بلا إنفاق كمالي',
    description: 'الاكتفاء بالضروريات فقط وتجنب المشتريات العشوائية',
    type: ActivityType.independent,
    iconName: 'savings',
    colorHex: '#8B5CF6',
  ),
  ActivityTemplate(
    title: 'ادخار أسبوعي منظم',
    description: 'تخصيص مبلغ ثابت للطوارئ أو الاستثمار',
    type: ActivityType.independent,
    iconName: 'account_balance_wallet',
    colorHex: '#14B8A6',
    repetition: ActivityRepetition.weekly,
  ),
  ActivityTemplate(
    title: 'مراجعة الميزانية الشهرية',
    description: 'تقييم الدخل والمصروفات والالتزامات والصدقات',
    type: ActivityType.independent,
    iconName: 'analytics',
    colorHex: '#3B82F6',
    repetition: ActivityRepetition.monthly,
  ),
  ActivityTemplate(
    title: 'تعلم مهارة مالية أو استثمارية',
    description: 'قراءة مقال أو درس حول الإدارة المالية الحلال',
    type: ActivityType.independent,
    iconName: 'trending_up',
    colorHex: '#F59E0B',
    repetition: ActivityRepetition.weekly,
    isMeasurable: true,
    targetGoal: 20,
    goalUnit: 'دقيقة',
  ),
];

const Map<String, dynamic> _finance = {
  'name': 'المال والصدقة',
  'templates': _financeTemplates,
};
