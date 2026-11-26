part of '../templates_sheet.dart';

const List<ActivityTemplate> _worshipA = [
  ActivityTemplate(
    title: 'أذكار الصباح',
    description: 'حصن المسلم بعد صلاة الفجر حتى الشروق',
    type: ActivityType.afterPrayer,
    linkedPrayer: PrayerPhase.fajr,
    iconName: 'wb_sunny',
    colorHex: '#FFB74D',
  ),
  ActivityTemplate(
    title: 'أذكار المساء',
    description: 'حصن المسلم بعد صلاة العصر حتى المغرب',
    type: ActivityType.afterPrayer,
    linkedPrayer: PrayerPhase.asr,
    iconName: 'nights_stay',
    colorHex: '#5C6BC0',
  ),
  ActivityTemplate(
    title: 'أذكار النوم وسورة الملك',
    description: 'الوضوء وقراءة سورة الملك وأذكار النوم',
    type: ActivityType.afterPrayer,
    linkedPrayer: PrayerPhase.isha,
    iconName: 'bedtime',
    colorHex: '#3949AB',
  ),
  ActivityTemplate(
    title: 'صلاة الضحى',
    description: 'صلاة الأوابين من ارتفاع الشمس حتى قبل الظهر',
    type: ActivityType.afterPrayer,
    linkedPrayer: PrayerPhase.fajr,
    iconName: 'light_mode',
    colorHex: '#FDD835',
    isMeasurable: true,
    targetGoal: 2,
    goalUnit: 'ركعة',
  ),
  ActivityTemplate(
    title: 'السنن الرواتب (12 ركعة)',
    description: 'بناء بيت في الجنة بالمحافظة على السنن القبلية والبعدية',
    type: ActivityType.independent,
    iconName: 'mosque',
    colorHex: '#10B981',
    isMeasurable: true,
    targetGoal: 12,
    goalUnit: 'ركعة',
  ),
  ActivityTemplate(
    title: 'صلاة الوتر',
    description: 'ختام صلاة الليل ولو بركعة واحدة',
    type: ActivityType.afterPrayer,
    linkedPrayer: PrayerPhase.isha,
    iconName: 'star',
    colorHex: '#1E88E5',
    isMeasurable: true,
    targetGoal: 3,
    goalUnit: 'ركعة',
  ),
];

const Map<String, dynamic> _worship = {
  'name': 'العبادات والأذكار',
  'templates': [..._worshipA, ..._worshipB],
};
