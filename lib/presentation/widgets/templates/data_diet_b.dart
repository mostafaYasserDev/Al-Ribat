part of '../templates_sheet.dart';

const List<ActivityTemplate> _dietB = [
  ActivityTemplate(
      title: 'تناول وجبة إفطار صحية',
      type: ActivityType.independent,
      iconName: 'breakfast_dining',
      colorHex: '#FF9800'),
  ActivityTemplate(
      title: 'صيام متقطع (16 ساعة)',
      type: ActivityType.independent,
      iconName: 'timer',
      colorHex: '#607D8B',
      isMeasurable: true,
      targetGoal: 16,
      goalUnit: 'ساعة'),
  ActivityTemplate(
      title: 'شرب شاي أخضر',
      type: ActivityType.independent,
      iconName: 'emoji_food_beverage',
      colorHex: '#8BC34A',
      isMeasurable: true,
      targetGoal: 1,
      goalUnit: 'كوب'),
  ActivityTemplate(
      title: 'تناول مكسرات نيئة',
      type: ActivityType.independent,
      iconName: 'grass',
      colorHex: '#795548',
      isMeasurable: true,
      targetGoal: 1,
      goalUnit: 'حفنة'),
  ActivityTemplate(
      title: 'الطبخ في المنزل',
      type: ActivityType.independent,
      iconName: 'restaurant',
      colorHex: '#E91E63'),
];
