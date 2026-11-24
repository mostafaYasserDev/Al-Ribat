part of '../templates_sheet.dart';

const List<ActivityTemplate> _selfDevelopmentB = [
  ActivityTemplate(
      title: 'مراجعة الأهداف',
      type: ActivityType.independent,
      iconName: 'flag',
      colorHex: '#F44336'),
  ActivityTemplate(
      title: 'التخطيط لليوم التالي',
      type: ActivityType.independent,
      iconName: 'event',
      colorHex: '#795548',
      isMeasurable: true,
      targetGoal: 5,
      goalUnit: 'دقيقة'),
  ActivityTemplate(
      title: 'مشاهدة فيديو تعليمي',
      type: ActivityType.independent,
      iconName: 'play_circle',
      colorHex: '#F44336',
      isMeasurable: true,
      targetGoal: 1,
      goalUnit: 'فيديو'),
  ActivityTemplate(
      title: 'حل ألغاز ذهنية',
      type: ActivityType.independent,
      iconName: 'extension',
      colorHex: '#CDDC39'),
  ActivityTemplate(
      title: 'جلسة تفكير إبداعي',
      type: ActivityType.independent,
      iconName: 'lightbulb',
      colorHex: '#FFC107',
      isMeasurable: true,
      targetGoal: 15,
      goalUnit: 'دقيقة'),
];
