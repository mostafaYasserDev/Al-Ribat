part of '../templates_sheet.dart';

const List<ActivityTemplate> _bodyCareA = [
  ActivityTemplate(
      title: 'النوم 7 ساعات',
      type: ActivityType.independent,
      iconName: 'hotel',
      colorHex: '#3F51B5'),
  ActivityTemplate(
      title: 'تنظيف الأسنان',
      type: ActivityType.independent,
      iconName: 'clean_hands',
      colorHex: '#00BCD4'),
  ActivityTemplate(
      title: 'العناية بالبشرة',
      type: ActivityType.independent,
      iconName: 'face',
      colorHex: '#FFC107'),
  ActivityTemplate(
      title: 'الاستحمام',
      type: ActivityType.independent,
      iconName: 'shower',
      colorHex: '#03A9F4'),
  ActivityTemplate(
      title: 'راحة للعين من الشاشات',
      type: ActivityType.independent,
      iconName: 'visibility_off',
      colorHex: '#607D8B'),
];

const Map<String, dynamic> _bodyCare = {
  'name': 'العناية بالصحة والجسد',
  'templates': [..._bodyCareA, ..._bodyCareB],
};
