part of '../templates_sheet.dart';

const List<ActivityTemplate> _healthA = [
  ActivityTemplate(
    title: '8000 خطوة يومياً',
    description: 'نزهة مشي يومية لتنشيط الدورة الدموية وصفاء الذهن',
    type: ActivityType.independent,
    iconName: 'directions_walk',
    colorHex: '#10B981',
    isMeasurable: true,
    targetGoal: 8000,
    goalUnit: 'خطوة',
  ),
  ActivityTemplate(
    title: 'الذهاب للصالة الرياضية',
    description: 'تمرين مقاومة ولياقة لبناء القوة البدنية',
    type: ActivityType.independent,
    iconName: 'fitness_center',
    colorHex: '#E53935',
    isMeasurable: true,
    targetGoal: 45,
    goalUnit: 'دقيقة',
  ),
  ActivityTemplate(
    title: 'المشي 30 دقيقة',
    description: 'مشي منتظم في الهواء الطلق',
    type: ActivityType.independent,
    iconName: 'directions_walk',
    colorHex: '#43A047',
    isMeasurable: true,
    targetGoal: 30,
    goalUnit: 'دقيقة',
  ),
  ActivityTemplate(
    title: 'تمارين الإطالة والمرونة',
    description: 'فك تيبس الظهر والرقبة بعد الجلوس الطويل',
    type: ActivityType.independent,
    iconName: 'accessibility',
    colorHex: '#FF9800',
    isMeasurable: true,
    targetGoal: 10,
    goalUnit: 'دقيقة',
  ),
  ActivityTemplate(
    title: 'الجري 15 دقيقة',
    description: 'رفع اللياقة القلبية والتنفسية',
    type: ActivityType.independent,
    iconName: 'directions_run',
    colorHex: '#D32F2F',
    isMeasurable: true,
    targetGoal: 15,
    goalUnit: 'دقيقة',
  ),
  ActivityTemplate(
    title: 'تمارين منزلية بوزن الجسم',
    description: 'ضغط وعقلة وتمارين وسط في المنزل',
    type: ActivityType.independent,
    iconName: 'sports_gymnastics',
    colorHex: '#FF5722',
    isMeasurable: true,
    targetGoal: 20,
    goalUnit: 'دقيقة',
  ),
];

const Map<String, dynamic> _health = {
  'name': 'الصحة والرياضة',
  'templates': [..._healthA, ..._healthB],
};
