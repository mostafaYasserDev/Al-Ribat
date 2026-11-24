part of '../templates_sheet.dart';

const List<ActivityTemplate> _relationsA = [
  ActivityTemplate(
      title: 'الاطمئنان على الوالدين',
      type: ActivityType.independent,
      iconName: 'family_restroom',
      colorHex: '#D81B60'),
  ActivityTemplate(
      title: 'التواصل مع صديق',
      type: ActivityType.independent,
      iconName: 'group',
      colorHex: '#F4511E'),
  ActivityTemplate(
      title: 'صلة الرحم',
      type: ActivityType.independent,
      iconName: 'diversity_1',
      colorHex: '#4CAF50'),
  ActivityTemplate(
      title: 'وقت جودة مع العائلة',
      type: ActivityType.independent,
      iconName: 'home',
      colorHex: '#8BC34A'),
  ActivityTemplate(
      title: 'مساعدة شخص',
      type: ActivityType.independent,
      iconName: 'volunteer_activism',
      colorHex: '#E91E63'),
];

const Map<String, dynamic> _relations = {
  'name': 'العلاقات',
  'templates': [..._relationsA, ..._relationsB],
};
