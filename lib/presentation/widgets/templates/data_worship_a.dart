part of '../templates_sheet.dart';

const List<ActivityTemplate> _worshipA = [
  ActivityTemplate(
      title: 'أذكار الصباح',
      type: ActivityType.afterPrayer,
      linkedPrayer: PrayerPhase.fajr,
      iconName: 'wb_sunny',
      colorHex: '#FFB74D'),
  ActivityTemplate(
      title: 'أذكار المساء',
      type: ActivityType.afterPrayer,
      linkedPrayer: PrayerPhase.asr,
      iconName: 'nights_stay',
      colorHex: '#5C6BC0'),
  ActivityTemplate(
      title: 'أذكار النوم',
      type: ActivityType.independent,
      iconName: 'bedtime',
      colorHex: '#3949AB'),
  ActivityTemplate(
      title: 'صلاة الضحى',
      type: ActivityType.independent,
      iconName: 'light_mode',
      colorHex: '#FDD835',
      isMeasurable: true,
      targetGoal: 2,
      goalUnit: 'ركعة'),
  ActivityTemplate(
      title: 'صلاة الوتر',
      type: ActivityType.afterPrayer,
      linkedPrayer: PrayerPhase.isha,
      iconName: 'star',
      colorHex: '#1E88E5',
      isMeasurable: true,
      targetGoal: 1,
      goalUnit: 'ركعة'),
];

const Map<String, dynamic> _worship = {
  'name': 'العبادات والأذكار',
  'templates': [..._worshipA, ..._worshipB],
};
