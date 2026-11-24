part of '../templates_sheet.dart';

const List<ActivityTemplate> _lifestyleA = [
  ActivityTemplate(
      title: 'الاستيقاظ مبكرًا',
      type: ActivityType.independent,
      iconName: 'alarm',
      colorHex: '#FF9800'),
  ActivityTemplate(
      title: 'الامتنان لثلاثة أشياء',
      type: ActivityType.independent,
      iconName: 'favorite_border',
      colorHex: '#E91E63'),
  ActivityTemplate(
      title: 'ترشيد الاستهلاك',
      type: ActivityType.independent,
      iconName: 'savings',
      colorHex: '#4CAF50'),
  ActivityTemplate(
      title: 'التعلم من خطأ',
      type: ActivityType.independent,
      iconName: 'psychology',
      colorHex: '#9C27B0'),
  ActivityTemplate(
      title: 'تخصيص وقت هواية',
      type: ActivityType.independent,
      iconName: 'palette',
      colorHex: '#F44336'),
];

const Map<String, dynamic> _lifestyle = {
  'name': 'نمط حياة',
  'templates': [..._lifestyleA, ..._lifestyleB],
};
