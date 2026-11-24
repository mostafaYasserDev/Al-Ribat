part of 'app_icons.dart';

IconData _iconForName(String? name) {
  if (name == null || name.isEmpty) return Icons.task_alt;
  switch (name) {
    // Prayers & Times
    case 'mosque':
      return Icons.mosque;
    case 'wb_sunny':
      return Icons.wb_sunny;
    case 'nights_stay':
      return Icons.nights_stay;
    case 'bedtime':
      return Icons.bedtime;
    case 'light_mode':
      return Icons.light_mode;
    case 'star':
      return Icons.star;
    case 'nightlight_round':
      return Icons.nightlight_round;

    // Knowledge & Reading
    case 'menu_book':
      return Icons.menu_book;
    case 'book':
      return Icons.book;
    case 'translate':
      return Icons.translate;
    case 'edit':
      return Icons.edit;
    case 'computer':
      return Icons.computer;
    case 'extension':
      return Icons.extension;
    case 'lightbulb':
      return Icons.lightbulb;
    case 'headphones':
      return Icons.headphones;
    case 'play_circle':
      return Icons.play_circle;

    // Fitness & Health
    case 'fitness_center':
      return Icons.fitness_center;
    case 'directions_walk':
      return Icons.directions_walk;
    case 'directions_run':
      return Icons.directions_run;
    case 'directions_bike':
      return Icons.directions_bike;
    case 'sports_gymnastics':
      return Icons.sports_gymnastics;
    case 'pool':
      return Icons.pool;
    case 'accessibility':
      return Icons.accessibility;
    case 'air':
      return Icons.air;
    case 'stairs':
      return Icons.stairs;
    case 'water_drop':
      return Icons.water_drop;

    // Social & Work & General
    case 'family_restroom':
      return Icons.family_restroom;
    case 'group':
      return Icons.group;
    case 'work':
      return Icons.work;
    case 'favorite':
      return Icons.favorite;
    case 'flag':
      return Icons.flag;
    case 'event':
      return Icons.event;
    case 'local_dining':
      return Icons.local_dining;
    case 'check_circle':
      return Icons.check_circle;
    default:
      return Icons.task_alt;
  }
}
