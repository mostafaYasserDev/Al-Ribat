part of '../templates_sheet.dart';

const List<ActivityTemplate> _healthB = [
  ActivityTemplate(
      title: 'ركوب الدراجة',
      type: ActivityType.independent,
      iconName: 'directions_bike',
      colorHex: '#009688',
      isMeasurable: true,
      targetGoal: 20,
      goalUnit: 'دقيقة'),
  ActivityTemplate(
      title: 'السباحة',
      type: ActivityType.independent,
      iconName: 'pool',
      colorHex: '#03A9F4'),
  ActivityTemplate(
      title: 'تمارين استرخاء',
      type: ActivityType.independent,
      iconName: 'accessibility',
      colorHex: '#9C27B0',
      isMeasurable: true,
      targetGoal: 15,
      goalUnit: 'دقيقة'),
  ActivityTemplate(
      title: 'تمارين التنفس',
      type: ActivityType.independent,
      iconName: 'air',
      colorHex: '#8BC34A',
      isMeasurable: true,
      targetGoal: 5,
      goalUnit: 'دقيقة'),
  ActivityTemplate(
      title: 'صعود السلم',
      type: ActivityType.independent,
      iconName: 'stairs',
      colorHex: '#795548',
      isMeasurable: true,
      targetGoal: 5,
      goalUnit: 'طابق'),
];
