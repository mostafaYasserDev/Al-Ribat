part of '../templates_sheet.dart';

const List<ActivityTemplate> _selfDevelopmentA = [
  ActivityTemplate(
      title: 'قراءة كتاب',
      description: 'قراءة 10 صفحات',
      type: ActivityType.independent,
      iconName: 'book',
      colorHex: '#6D4C41',
      isMeasurable: true,
      targetGoal: 10,
      goalUnit: 'صفحة'),
  ActivityTemplate(
      title: 'تعلم لغة جديدة',
      description: '15 دقيقة',
      type: ActivityType.independent,
      iconName: 'translate',
      colorHex: '#00897B',
      isMeasurable: true,
      targetGoal: 15,
      goalUnit: 'دقيقة'),
  ActivityTemplate(
      title: 'كتابة اليوميات',
      type: ActivityType.independent,
      iconName: 'edit',
      colorHex: '#FF9800'),
  ActivityTemplate(
      title: 'الاستماع لبودكاست',
      type: ActivityType.independent,
      iconName: 'headphones',
      colorHex: '#9C27B0'),
  ActivityTemplate(
      title: 'تعلم مهارة تقنية',
      type: ActivityType.independent,
      iconName: 'computer',
      colorHex: '#607D8B',
      isMeasurable: true,
      targetGoal: 1,
      goalUnit: 'درس'),
];

const Map<String, dynamic> _selfDevelopment = {
  'name': 'تطوير الذات',
  'templates': [..._selfDevelopmentA, ..._selfDevelopmentB],
};
