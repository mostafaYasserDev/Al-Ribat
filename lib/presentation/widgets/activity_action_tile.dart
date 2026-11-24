import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../core/theme/app_icons.dart';
import '../../core/ui_confirm.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/activity_item.dart';
import 'activity_add_progress_sheet.dart';
import 'activity_details_sheet.dart';
import 'add_activity_sheet.dart';

part 'activity_action_tile_dialogs.dart';
part 'activity_action_tile_view.dart';
part 'activity_action_tile_tile.dart';

class ActivityActionTile extends StatelessWidget {
  const ActivityActionTile({
    super.key,
    required this.activity,
    required this.dateStr,
    required this.onToggleDone,
    required this.onToggleSkip,
    required this.onDelete,
    required this.onUpdate,
    required this.onAddProgress,
    this.isInsideGradientCard = false,
  });

  final ActivityItem activity;
  final String dateStr;
  final Future<void> Function(ActivityItem, String) onToggleDone;
  final Future<void> Function(ActivityItem, String) onToggleSkip;
  final Future<void> Function(ActivityItem) onDelete;
  final Future<void> Function(ActivityItem) onUpdate;
  final Future<void> Function(ActivityItem, String, double) onAddProgress;
  final bool isInsideGradientCard;

  static String formatProgress(double p) {
    return p == p.toInt() ? p.toInt().toString() : p.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) => _buildActivityTile(context);
}
