part of '../templates_sheet.dart';

const List<ActivityTemplate> _worshipB = [
  ActivityTemplate(
      title: 'سورة الكهف',
      type: ActivityType.independent,
      iconName: 'menu_book',
      colorHex: '#8D6E63',
      repetition: ActivityRepetition.weekly,
      isMeasurable: true,
      targetGoal: 1,
      goalUnit: 'سورة'),
  ActivityTemplate(
      title: 'ورد القرآن',
      description: 'قراءة جزء يوميًا',
      type: ActivityType.independent,
      iconName: 'menu_book',
      colorHex: '#4CAF50',
      isMeasurable: true,
      targetGoal: 1,
      goalUnit: 'جزء'),
  ActivityTemplate(
      title: 'صلاة قيام الليل',
      type: ActivityType.independent,
      iconName: 'nights_stay',
      colorHex: '#1A237E',
      isMeasurable: true,
      targetGoal: 2,
      goalUnit: 'ركعة'),
  ActivityTemplate(
      title: 'الاستغفار 100 مرة',
      type: ActivityType.independent,
      iconName: 'water_drop',
      colorHex: '#00BCD4',
      isMeasurable: true,
      targetGoal: 100,
      goalUnit: 'مرة'),
  ActivityTemplate(
      title: 'الصلاة على النبي',
      type: ActivityType.independent,
      iconName: 'favorite',
      colorHex: '#E91E63',
      isMeasurable: true,
      targetGoal: 100,
      goalUnit: 'مرة'),
];
