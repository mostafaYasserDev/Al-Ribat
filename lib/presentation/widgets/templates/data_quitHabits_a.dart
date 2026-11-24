part of '../templates_sheet.dart';

const List<ActivityTemplate> _quitHabitsA = [
  ActivityTemplate(
      title: 'يوم بدون تدخين',
      type: ActivityType.independent,
      iconName: 'smoke_free',
      colorHex: '#4CAF50'),
  ActivityTemplate(
      title: 'تقليل الكافيين',
      type: ActivityType.independent,
      iconName: 'local_cafe',
      colorHex: '#795548'),
  ActivityTemplate(
      title: 'عدم تصفح الهاتف قبل النوم',
      type: ActivityType.independent,
      iconName: 'phonelink_erase',
      colorHex: '#9C27B0'),
  ActivityTemplate(
      title: 'الامتناع عن الغيبة',
      type: ActivityType.independent,
      iconName: 'record_voice_over',
      colorHex: '#F44336'),
  ActivityTemplate(
      title: 'لا للسهر',
      type: ActivityType.independent,
      iconName: 'alarm_off',
      colorHex: '#607D8B'),
];

const Map<String, dynamic> _quitHabits = {
  'name': 'ترك عادات سيئة',
  'templates': [..._quitHabitsA, ..._quitHabitsB],
};
