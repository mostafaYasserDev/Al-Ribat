import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/features/reflections/presentation/widgets/apple_morph_route.dart';
import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/activity_item.dart';

part 'templates/data_worship_a.dart';
part 'templates/data_worship_b.dart';
part 'templates/data_selfDevelopment_a.dart';
part 'templates/data_selfDevelopment_b.dart';
part 'templates/data_health_a.dart';
part 'templates/data_health_b.dart';
part 'templates/data_diet_a.dart';
part 'templates/data_diet_b.dart';
part 'templates/data_relations_a.dart';
part 'templates/data_relations_b.dart';
part 'templates/data_bodyCare_a.dart';
part 'templates/data_bodyCare_b.dart';
part 'templates/data_quitHabits_a.dart';
part 'templates/data_quitHabits_b.dart';
part 'templates/data_home_a.dart';
part 'templates/data_home_b.dart';
part 'templates/data_lifestyle_a.dart';
part 'templates/data_lifestyle_b.dart';
part 'templates/data_finance.dart';
part 'templates/data_digital_wellness.dart';
part 'templates/icons_a.dart';
part 'templates/icons_b.dart';
part 'templates/sheet_helpers.dart';
part 'templates/sheet_ui.dart';

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

class TemplatesSheet extends StatefulWidget {
  const TemplatesSheet({super.key});

  /// Opens [TemplatesSheet] with an Apple spatial morph from [sourceContext].
  static Future<ActivityTemplate?> open(
    BuildContext context, {
    BuildContext? sourceContext,
    Color? sourceColor,
    double sourceRadius = 16,
  }) {
    final sourceRect = captureWidgetRect(sourceContext);
    return Navigator.of(context).push<ActivityTemplate>(
      AppleMorphRoute<ActivityTemplate>(
        sourceRect: sourceRect,
        sourceColor: sourceColor,
        sourceRadius: sourceRadius,
        builder: (_) => const TemplatesSheet(),
      ),
    );
  }

  static const List<Map<String, dynamic>> _categories = [
    _worship,
    _selfDevelopment,
    _digitalWellness,
    _health,
    _finance,
    _diet,
    _relations,
    _bodyCare,
    _quitHabits,
    _home,
    _lifestyle,
  ];

  @override
  State<TemplatesSheet> createState() => _TemplatesSheetState();
}
