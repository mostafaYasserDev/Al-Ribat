part of '../templates_sheet.dart';

const List<ActivityTemplate> _healthA = [
  ActivityTemplate(
      title: 'الذهاب للصالة الرياضية',
      type: ActivityType.independent,
      iconName: 'fitness_center',
      colorHex: '#E53935'),
  ActivityTemplate(
      title: 'المشي 30 دقيقة',
      type: ActivityType.independent,
      iconName: 'directions_walk',
      colorHex: '#43A047',
      isMeasurable: true,
      targetGoal: 30,
      goalUnit: 'دقيقة'),
  ActivityTemplate(
      title: 'تمارين الإطالة',
      type: ActivityType.independent,
      iconName: 'accessibility',
      colorHex: '#FF9800',
      isMeasurable: true,
      targetGoal: 10,
      goalUnit: 'دقيقة'),
  ActivityTemplate(
      title: 'الجري 15 دقيقة',
      type: ActivityType.independent,
      iconName: 'directions_run',
      colorHex: '#D32F2F',
      isMeasurable: true,
      targetGoal: 15,
      goalUnit: 'دقيقة'),
  ActivityTemplate(
      title: 'تمارين منزلية بوزن الجسم',
      type: ActivityType.independent,
      iconName: 'sports_gymnastics',
      colorHex: '#FF5722'),
];

const Map<String, dynamic> _health = {
  'name': 'الصحة والرياضة',
  'templates': [..._healthA, ..._healthB],
};
