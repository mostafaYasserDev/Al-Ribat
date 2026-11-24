part of '../templates_sheet.dart';

const List<ActivityTemplate> _homeA = [
  ActivityTemplate(
      title: 'ترتيب السرير',
      type: ActivityType.independent,
      iconName: 'bed',
      colorHex: '#8BC34A'),
  ActivityTemplate(
      title: 'غسيل الأطباق',
      type: ActivityType.independent,
      iconName: 'countertops',
      colorHex: '#00BCD4'),
  ActivityTemplate(
      title: 'تنظيف الغرفة 10 دقائق',
      type: ActivityType.independent,
      iconName: 'cleaning_services',
      colorHex: '#FF9800'),
  ActivityTemplate(
      title: 'إخراج القمامة',
      type: ActivityType.independent,
      iconName: 'delete',
      colorHex: '#607D8B'),
  ActivityTemplate(
      title: 'سقي النباتات',
      type: ActivityType.independent,
      iconName: 'local_florist',
      colorHex: '#4CAF50'),
];

const Map<String, dynamic> _home = {
  'name': 'المنزل',
  'templates': [..._homeA, ..._homeB],
};
