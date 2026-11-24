part of '../templates_sheet.dart';

const List<ActivityTemplate> _dietA = [
  ActivityTemplate(
      title: 'شرب 8 أكواب ماء',
      type: ActivityType.independent,
      iconName: 'water_drop',
      colorHex: '#039BE5',
      isMeasurable: true,
      targetGoal: 8,
      goalUnit: 'كوب'),
  ActivityTemplate(
      title: 'تناول حصة خضروات',
      type: ActivityType.independent,
      iconName: 'eco',
      colorHex: '#4CAF50',
      isMeasurable: true,
      targetGoal: 1,
      goalUnit: 'حصة'),
  ActivityTemplate(
      title: 'تناول حصة فواكه',
      type: ActivityType.independent,
      iconName: 'apple',
      colorHex: '#F44336',
      isMeasurable: true,
      targetGoal: 1,
      goalUnit: 'حصة'),
  ActivityTemplate(
      title: 'تجنب السكر المضاف',
      type: ActivityType.independent,
      iconName: 'no_food',
      colorHex: '#9E9E9E'),
  ActivityTemplate(
      title: 'تجنب الوجبات السريعة',
      type: ActivityType.independent,
      iconName: 'fastfood',
      colorHex: '#FF5722'),
];

const Map<String, dynamic> _diet = {
  'name': 'حمية غذائية ونظام غذائي',
  'templates': [..._dietA, ..._dietB],
};
