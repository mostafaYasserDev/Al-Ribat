import 'package:flutter/material.dart';

import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/activity_item.dart';

class ActivityTemplate {
  final String title;
  final String? description;
  final ActivityType type;
  final PrayerPhase? linkedPrayer;
  final String iconName;
  final String colorHex;
  final ActivityRepetition repetition;
  final bool isMeasurable;
  final double? targetGoal;
  final String? goalUnit;

  const ActivityTemplate({
    required this.title,
    this.description,
    required this.type,
    this.linkedPrayer,
    required this.iconName,
    required this.colorHex,
    this.repetition = ActivityRepetition.daily,
    this.isMeasurable = false,
    this.targetGoal,
    this.goalUnit,
  });
}

class TemplatesSheet extends StatelessWidget {
  const TemplatesSheet({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'العبادات والأذكار',
      'templates': [
        ActivityTemplate(title: 'أذكار الصباح', type: ActivityType.afterPrayer, linkedPrayer: PrayerPhase.fajr, iconName: 'wb_sunny', colorHex: '#FFB74D'),
        ActivityTemplate(title: 'أذكار المساء', type: ActivityType.afterPrayer, linkedPrayer: PrayerPhase.asr, iconName: 'nights_stay', colorHex: '#5C6BC0'),
        ActivityTemplate(title: 'أذكار النوم', type: ActivityType.independent, iconName: 'bedtime', colorHex: '#3949AB'),
        ActivityTemplate(title: 'صلاة الضحى', type: ActivityType.independent, iconName: 'light_mode', colorHex: '#FDD835', isMeasurable: true, targetGoal: 2, goalUnit: 'ركعة'),
        ActivityTemplate(title: 'صلاة الوتر', type: ActivityType.afterPrayer, linkedPrayer: PrayerPhase.isha, iconName: 'star', colorHex: '#1E88E5', isMeasurable: true, targetGoal: 1, goalUnit: 'ركعة'),
        ActivityTemplate(title: 'سورة الكهف', type: ActivityType.independent, iconName: 'menu_book', colorHex: '#8D6E63', repetition: ActivityRepetition.weekly, isMeasurable: true, targetGoal: 1, goalUnit: 'سورة'),
        ActivityTemplate(title: 'ورد القرآن', description: 'قراءة جزء يوميًا', type: ActivityType.independent, iconName: 'menu_book', colorHex: '#4CAF50', isMeasurable: true, targetGoal: 1, goalUnit: 'جزء'),
        ActivityTemplate(title: 'صلاة قيام الليل', type: ActivityType.independent, iconName: 'nights_stay', colorHex: '#1A237E', isMeasurable: true, targetGoal: 2, goalUnit: 'ركعة'),
        ActivityTemplate(title: 'الاستغفار 100 مرة', type: ActivityType.independent, iconName: 'water_drop', colorHex: '#00BCD4', isMeasurable: true, targetGoal: 100, goalUnit: 'مرة'),
        ActivityTemplate(title: 'الصلاة على النبي', type: ActivityType.independent, iconName: 'favorite', colorHex: '#E91E63', isMeasurable: true, targetGoal: 100, goalUnit: 'مرة'),
      ]
    },
    {
      'name': 'تطوير الذات',
      'templates': [
        ActivityTemplate(title: 'قراءة كتاب', description: 'قراءة 10 صفحات', type: ActivityType.independent, iconName: 'book', colorHex: '#6D4C41', isMeasurable: true, targetGoal: 10, goalUnit: 'صفحة'),
        ActivityTemplate(title: 'تعلم لغة جديدة', description: '15 دقيقة', type: ActivityType.independent, iconName: 'translate', colorHex: '#00897B', isMeasurable: true, targetGoal: 15, goalUnit: 'دقيقة'),
        ActivityTemplate(title: 'كتابة اليوميات', type: ActivityType.independent, iconName: 'edit', colorHex: '#FF9800'),
        ActivityTemplate(title: 'الاستماع لبودكاست', type: ActivityType.independent, iconName: 'headphones', colorHex: '#9C27B0'),
        ActivityTemplate(title: 'تعلم مهارة تقنية', type: ActivityType.independent, iconName: 'computer', colorHex: '#607D8B', isMeasurable: true, targetGoal: 1, goalUnit: 'درس'),
        ActivityTemplate(title: 'مراجعة الأهداف', type: ActivityType.independent, iconName: 'flag', colorHex: '#F44336'),
        ActivityTemplate(title: 'التخطيط لليوم التالي', type: ActivityType.independent, iconName: 'event', colorHex: '#795548', isMeasurable: true, targetGoal: 5, goalUnit: 'دقيقة'),
        ActivityTemplate(title: 'مشاهدة فيديو تعليمي', type: ActivityType.independent, iconName: 'play_circle', colorHex: '#F44336', isMeasurable: true, targetGoal: 1, goalUnit: 'فيديو'),
        ActivityTemplate(title: 'حل ألغاز ذهنية', type: ActivityType.independent, iconName: 'extension', colorHex: '#CDDC39'),
        ActivityTemplate(title: 'جلسة تفكير إبداعي', type: ActivityType.independent, iconName: 'lightbulb', colorHex: '#FFC107', isMeasurable: true, targetGoal: 15, goalUnit: 'دقيقة'),
      ]
    },
    {
      'name': 'الصحة والرياضة',
      'templates': [
        ActivityTemplate(title: 'الذهاب للصالة الرياضية', type: ActivityType.independent, iconName: 'fitness_center', colorHex: '#E53935'),
        ActivityTemplate(title: 'المشي 30 دقيقة', type: ActivityType.independent, iconName: 'directions_walk', colorHex: '#43A047', isMeasurable: true, targetGoal: 30, goalUnit: 'دقيقة'),
        ActivityTemplate(title: 'تمارين الإطالة', type: ActivityType.independent, iconName: 'accessibility', colorHex: '#FF9800', isMeasurable: true, targetGoal: 10, goalUnit: 'دقيقة'),
        ActivityTemplate(title: 'الجري 15 دقيقة', type: ActivityType.independent, iconName: 'directions_run', colorHex: '#D32F2F', isMeasurable: true, targetGoal: 15, goalUnit: 'دقيقة'),
        ActivityTemplate(title: 'تمارين منزلية بوزن الجسم', type: ActivityType.independent, iconName: 'sports_gymnastics', colorHex: '#FF5722'),
        ActivityTemplate(title: 'ركوب الدراجة', type: ActivityType.independent, iconName: 'directions_bike', colorHex: '#009688', isMeasurable: true, targetGoal: 20, goalUnit: 'دقيقة'),
        ActivityTemplate(title: 'السباحة', type: ActivityType.independent, iconName: 'pool', colorHex: '#03A9F4'),
        ActivityTemplate(title: 'تمارين استرخاء', type: ActivityType.independent, iconName: 'accessibility', colorHex: '#9C27B0', isMeasurable: true, targetGoal: 15, goalUnit: 'دقيقة'),
        ActivityTemplate(title: 'تمارين التنفس', type: ActivityType.independent, iconName: 'air', colorHex: '#8BC34A', isMeasurable: true, targetGoal: 5, goalUnit: 'دقيقة'),
        ActivityTemplate(title: 'صعود السلم', type: ActivityType.independent, iconName: 'stairs', colorHex: '#795548', isMeasurable: true, targetGoal: 5, goalUnit: 'طابق'),
      ]
    },
    {
      'name': 'حمية غذائية ونظام غذائي',
      'templates': [
        ActivityTemplate(title: 'شرب 8 أكواب ماء', type: ActivityType.independent, iconName: 'water_drop', colorHex: '#039BE5', isMeasurable: true, targetGoal: 8, goalUnit: 'كوب'),
        ActivityTemplate(title: 'تناول حصة خضروات', type: ActivityType.independent, iconName: 'eco', colorHex: '#4CAF50', isMeasurable: true, targetGoal: 1, goalUnit: 'حصة'),
        ActivityTemplate(title: 'تناول حصة فواكه', type: ActivityType.independent, iconName: 'apple', colorHex: '#F44336', isMeasurable: true, targetGoal: 1, goalUnit: 'حصة'),
        ActivityTemplate(title: 'تجنب السكر المضاف', type: ActivityType.independent, iconName: 'no_food', colorHex: '#9E9E9E'),
        ActivityTemplate(title: 'تجنب الوجبات السريعة', type: ActivityType.independent, iconName: 'fastfood', colorHex: '#FF5722'),
        ActivityTemplate(title: 'تناول وجبة إفطار صحية', type: ActivityType.independent, iconName: 'breakfast_dining', colorHex: '#FF9800'),
        ActivityTemplate(title: 'صيام متقطع (16 ساعة)', type: ActivityType.independent, iconName: 'timer', colorHex: '#607D8B', isMeasurable: true, targetGoal: 16, goalUnit: 'ساعة'),
        ActivityTemplate(title: 'شرب شاي أخضر', type: ActivityType.independent, iconName: 'emoji_food_beverage', colorHex: '#8BC34A', isMeasurable: true, targetGoal: 1, goalUnit: 'كوب'),
        ActivityTemplate(title: 'تناول مكسرات نيئة', type: ActivityType.independent, iconName: 'grass', colorHex: '#795548', isMeasurable: true, targetGoal: 1, goalUnit: 'حفنة'),
        ActivityTemplate(title: 'الطبخ في المنزل', type: ActivityType.independent, iconName: 'restaurant', colorHex: '#E91E63'),
      ]
    },
    {
      'name': 'العلاقات',
      'templates': [
        ActivityTemplate(title: 'الاطمئنان على الوالدين', type: ActivityType.independent, iconName: 'family_restroom', colorHex: '#D81B60'),
        ActivityTemplate(title: 'التواصل مع صديق', type: ActivityType.independent, iconName: 'group', colorHex: '#F4511E'),
        ActivityTemplate(title: 'صلة الرحم', type: ActivityType.independent, iconName: 'diversity_1', colorHex: '#4CAF50'),
        ActivityTemplate(title: 'وقت جودة مع العائلة', type: ActivityType.independent, iconName: 'home', colorHex: '#8BC34A'),
        ActivityTemplate(title: 'مساعدة شخص', type: ActivityType.independent, iconName: 'volunteer_activism', colorHex: '#E91E63'),
        ActivityTemplate(title: 'لعب مع الأطفال', type: ActivityType.independent, iconName: 'child_care', colorHex: '#FF9800'),
        ActivityTemplate(title: 'هدية بسيطة', type: ActivityType.independent, iconName: 'card_giftcard', colorHex: '#F44336'),
        ActivityTemplate(title: 'الكلمة الطيبة', type: ActivityType.independent, iconName: 'forum', colorHex: '#2196F3'),
        ActivityTemplate(title: 'الاستماع بإنصات', type: ActivityType.independent, iconName: 'hearing', colorHex: '#9C27B0'),
        ActivityTemplate(title: 'زيارة مريض', type: ActivityType.independent, iconName: 'local_hospital', colorHex: '#F44336'),
      ]
    },
    {
      'name': 'العناية بالصحة والجسد',
      'templates': [
        ActivityTemplate(title: 'النوم 7 ساعات', type: ActivityType.independent, iconName: 'hotel', colorHex: '#3F51B5'),
        ActivityTemplate(title: 'تنظيف الأسنان', type: ActivityType.independent, iconName: 'clean_hands', colorHex: '#00BCD4'),
        ActivityTemplate(title: 'العناية بالبشرة', type: ActivityType.independent, iconName: 'face', colorHex: '#FFC107'),
        ActivityTemplate(title: 'الاستحمام', type: ActivityType.independent, iconName: 'shower', colorHex: '#03A9F4'),
        ActivityTemplate(title: 'راحة للعين من الشاشات', type: ActivityType.independent, iconName: 'visibility_off', colorHex: '#607D8B'),
        ActivityTemplate(title: 'الجلوس بوضعية صحيحة', type: ActivityType.independent, iconName: 'airline_seat_recline_normal', colorHex: '#4CAF50'),
        ActivityTemplate(title: 'فحص طبي دوري', type: ActivityType.independent, iconName: 'medical_services', colorHex: '#E53935'),
        ActivityTemplate(title: 'استخدام خيط الأسنان', type: ActivityType.independent, iconName: 'sanitizer', colorHex: '#009688'),
        ActivityTemplate(title: 'غسل اليدين جيدًا', type: ActivityType.independent, iconName: 'wash', colorHex: '#2196F3'),
        ActivityTemplate(title: 'التعرض للشمس', type: ActivityType.independent, iconName: 'wb_sunny', colorHex: '#FFEB3B'),
      ]
    },
    {
      'name': 'ترك عادات سيئة',
      'templates': [
        ActivityTemplate(title: 'يوم بدون تدخين', type: ActivityType.independent, iconName: 'smoke_free', colorHex: '#4CAF50'),
        ActivityTemplate(title: 'تقليل الكافيين', type: ActivityType.independent, iconName: 'local_cafe', colorHex: '#795548'),
        ActivityTemplate(title: 'عدم تصفح الهاتف قبل النوم', type: ActivityType.independent, iconName: 'phonelink_erase', colorHex: '#9C27B0'),
        ActivityTemplate(title: 'الامتناع عن الغيبة', type: ActivityType.independent, iconName: 'record_voice_over', colorHex: '#F44336'),
        ActivityTemplate(title: 'لا للسهر', type: ActivityType.independent, iconName: 'alarm_off', colorHex: '#607D8B'),
        ActivityTemplate(title: 'تقييد وسائل التواصل', type: ActivityType.independent, iconName: 'app_blocking', colorHex: '#E91E63'),
        ActivityTemplate(title: 'تجنب الغضب', type: ActivityType.independent, iconName: 'mood_bad', colorHex: '#FF9800'),
        ActivityTemplate(title: 'عدم قضم الأظافر', type: ActivityType.independent, iconName: 'do_not_touch', colorHex: '#9E9E9E'),
        ActivityTemplate(title: 'لا للشراء الاندفاعي', type: ActivityType.independent, iconName: 'money_off', colorHex: '#4CAF50'),
        ActivityTemplate(title: 'تجنب الشكوى', type: ActivityType.independent, iconName: 'sentiment_satisfied', colorHex: '#2196F3'),
      ]
    },
    {
      'name': 'المنزل',
      'templates': [
        ActivityTemplate(title: 'ترتيب السرير', type: ActivityType.independent, iconName: 'bed', colorHex: '#8BC34A'),
        ActivityTemplate(title: 'غسيل الأطباق', type: ActivityType.independent, iconName: 'countertops', colorHex: '#00BCD4'),
        ActivityTemplate(title: 'تنظيف الغرفة 10 دقائق', type: ActivityType.independent, iconName: 'cleaning_services', colorHex: '#FF9800'),
        ActivityTemplate(title: 'إخراج القمامة', type: ActivityType.independent, iconName: 'delete', colorHex: '#607D8B'),
        ActivityTemplate(title: 'سقي النباتات', type: ActivityType.independent, iconName: 'local_florist', colorHex: '#4CAF50'),
        ActivityTemplate(title: 'تهوية المنزل', type: ActivityType.independent, iconName: 'air', colorHex: '#03A9F4'),
        ActivityTemplate(title: 'تجهيز الملابس لغد', type: ActivityType.independent, iconName: 'checkroom', colorHex: '#9C27B0'),
        ActivityTemplate(title: 'تنظيم المكتب', type: ActivityType.independent, iconName: 'desk', colorHex: '#795548'),
        ActivityTemplate(title: 'دفع الفواتير', type: ActivityType.independent, iconName: 'receipt', colorHex: '#E53935'),
        ActivityTemplate(title: 'شراء حاجيات المنزل', type: ActivityType.independent, iconName: 'shopping_cart', colorHex: '#FF5722'),
      ]
    },
    {
      'name': 'نمط حياة',
      'templates': [
        ActivityTemplate(title: 'الاستيقاظ مبكرًا', type: ActivityType.independent, iconName: 'alarm', colorHex: '#FF9800'),
        ActivityTemplate(title: 'الامتنان لثلاثة أشياء', type: ActivityType.independent, iconName: 'favorite_border', colorHex: '#E91E63'),
        ActivityTemplate(title: 'ترشيد الاستهلاك', type: ActivityType.independent, iconName: 'savings', colorHex: '#4CAF50'),
        ActivityTemplate(title: 'التعلم من خطأ', type: ActivityType.independent, iconName: 'psychology', colorHex: '#9C27B0'),
        ActivityTemplate(title: 'تخصيص وقت هواية', type: ActivityType.independent, iconName: 'palette', colorHex: '#F44336'),
        ActivityTemplate(title: 'الابتعاد عن الأخبار السلبية', type: ActivityType.independent, iconName: 'tv_off', colorHex: '#607D8B'),
        ActivityTemplate(title: 'متابعة المصروفات', type: ActivityType.independent, iconName: 'account_balance_wallet', colorHex: '#009688'),
        ActivityTemplate(title: 'التنزه في الطبيعة', type: ActivityType.independent, iconName: 'park', colorHex: '#8BC34A'),
        ActivityTemplate(title: 'التبرع بشيء لا تحتاجه', type: ActivityType.independent, iconName: 'redeem', colorHex: '#03A9F4'),
        ActivityTemplate(title: 'الابتسامة', type: ActivityType.independent, iconName: 'sentiment_very_satisfied', colorHex: '#FFC107'),
      ]
    },
  ];

  IconData _getIcon(String name) {
    switch (name) {
      case 'wb_sunny': return Icons.wb_sunny;
      case 'nights_stay': return Icons.nights_stay;
      case 'bedtime': return Icons.bedtime;
      case 'light_mode': return Icons.light_mode;
      case 'star': return Icons.star;
      case 'menu_book': return Icons.menu_book;
      case 'book': return Icons.book;
      case 'translate': return Icons.translate;
      case 'fitness_center': return Icons.fitness_center;
      case 'directions_walk': return Icons.directions_walk;
      case 'water_drop': return Icons.water_drop;
      case 'family_restroom': return Icons.family_restroom;
      case 'group': return Icons.group;
      case 'favorite': return Icons.favorite;
      case 'edit': return Icons.edit;
      case 'headphones': return Icons.headphones;
      case 'computer': return Icons.computer;
      case 'flag': return Icons.flag;
      case 'event': return Icons.event;
      case 'play_circle': return Icons.play_circle;
      case 'extension': return Icons.extension;
      case 'lightbulb': return Icons.lightbulb;
      case 'accessibility': return Icons.accessibility;
      case 'directions_run': return Icons.directions_run;
      case 'sports_gymnastics': return Icons.sports_gymnastics;
      case 'directions_bike': return Icons.directions_bike;
      case 'pool': return Icons.pool;
      case 'air': return Icons.air;
      case 'stairs': return Icons.stairs;
      case 'eco': return Icons.eco;
      case 'apple': return Icons.apple;
      case 'no_food': return Icons.no_food;
      case 'fastfood': return Icons.fastfood;
      case 'breakfast_dining': return Icons.breakfast_dining;
      case 'timer': return Icons.timer;
      case 'emoji_food_beverage': return Icons.emoji_food_beverage;
      case 'grass': return Icons.grass;
      case 'restaurant': return Icons.restaurant;
      case 'diversity_1': return Icons.diversity_1;
      case 'home': return Icons.home;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'child_care': return Icons.child_care;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'forum': return Icons.forum;
      case 'hearing': return Icons.hearing;
      case 'local_hospital': return Icons.local_hospital;
      case 'hotel': return Icons.hotel;
      case 'clean_hands': return Icons.clean_hands;
      case 'face': return Icons.face;
      case 'shower': return Icons.shower;
      case 'visibility_off': return Icons.visibility_off;
      case 'airline_seat_recline_normal': return Icons.airline_seat_recline_normal;
      case 'medical_services': return Icons.medical_services;
      case 'sanitizer': return Icons.sanitizer;
      case 'wash': return Icons.wash;
      case 'smoke_free': return Icons.smoke_free;
      case 'local_cafe': return Icons.local_cafe;
      case 'phonelink_erase': return Icons.phonelink_erase;
      case 'record_voice_over': return Icons.record_voice_over;
      case 'alarm_off': return Icons.alarm_off;
      case 'app_blocking': return Icons.app_blocking;
      case 'mood_bad': return Icons.mood_bad;
      case 'do_not_touch': return Icons.do_not_touch;
      case 'money_off': return Icons.money_off;
      case 'sentiment_satisfied': return Icons.sentiment_satisfied;
      case 'bed': return Icons.bed;
      case 'countertops': return Icons.countertops;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'delete': return Icons.delete;
      case 'local_florist': return Icons.local_florist;
      case 'checkroom': return Icons.checkroom;
      case 'desk': return Icons.desk;
      case 'receipt': return Icons.receipt;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'alarm': return Icons.alarm;
      case 'favorite_border': return Icons.favorite_border;
      case 'savings': return Icons.savings;
      case 'psychology': return Icons.psychology;
      case 'palette': return Icons.palette;
      case 'tv_off': return Icons.tv_off;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'park': return Icons.park;
      case 'redeem': return Icons.redeem;
      case 'sentiment_very_satisfied': return Icons.sentiment_very_satisfied;
      default: return Icons.task_alt;
    }
  }

  Color _getColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'قوالب الأنشطة الجاهزة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final templates = category['templates'] as List<ActivityTemplate>;
                    
                    return ExpansionTile(
                      title: Text(
                        category['name'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: templates.map((t) => Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColor(t.colorHex).withValues(alpha: 0.2),
                            child: Icon(_getIcon(t.iconName), color: _getColor(t.colorHex)),
                          ),
                          title: Text(t.title),
                          subtitle: t.description != null ? Text(t.description!) : null,
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            Navigator.pop(context, t);
                          },
                        ),
                      )).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
