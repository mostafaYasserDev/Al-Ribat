import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../application/providers.dart';
import '../../domain/entities/activity_item.dart';
import '../../core/constants/prayer_phase.dart';
import '../../core/theme/app_icons.dart';
import 'templates_sheet.dart';

part 'add_activity/palette.dart';
part 'add_activity/state_core.dart';
part 'add_activity/template_apply.dart';
part 'add_activity/basic_fields.dart';
part 'add_activity/measurable_fields.dart';
part 'add_activity/project_field.dart';
part 'add_activity/group_field.dart';
part 'add_activity/appearance_fields.dart';
part 'add_activity/repetition.dart';
part 'add_activity/repeat_days.dart';
part 'add_activity/prayer_link.dart';
part 'add_activity/notifications.dart';
part 'add_activity/save_action.dart';

class AddActivitySheet extends ConsumerStatefulWidget {
  const AddActivitySheet({
    super.key,
    required this.onSave,
    this.initialActivity,
    this.initialPhase,
    this.isIndependentInitial = false,
    this.initialProject,
    this.initialGroup,
  });

  final Future<bool> Function(ActivityItem activity) onSave;
  final ActivityItem? initialActivity;
  final PrayerPhase? initialPhase;
  final bool isIndependentInitial;
  final String? initialProject;
  final String? initialGroup;

  @override
  ConsumerState<AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends ConsumerState<AddActivitySheet>
    with
        _SheetStateCore,
        _TemplateApplier,
        _BasicFields,
        _MeasurableFields,
        _ProjectField,
        _GroupField,
        _AppearanceFields,
        _RepetitionFields,
        _RepeatDays,
        _PrayerLink,
        _Notifications,
        _SaveAction {
  @override
  Widget build(BuildContext context) {
    final hasAdvancedSettings = widget.initialActivity != null &&
        (widget.initialActivity!.isMeasurable ||
            (widget.initialActivity!.projectName != null &&
                widget.initialActivity!.projectName!.isNotEmpty) ||
            widget.initialActivity!.notificationsEnabled);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._buildHeader(context),
              ..._buildBasicFields(),
              const SizedBox(height: 12),
              ..._buildPrayerLink(context),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: hasAdvancedSettings,
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    title: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'خيارات إضافية (أهداف، تكرار، مشروع، تنبيهات)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMeasurableToggle(),
                            if (_isMeasurable) ..._buildMeasurableFields(),
                            const Divider(height: 20),
                            ..._buildRepetition(context),
                            ..._buildRepeatDays(),
                            const Divider(height: 20),
                            ..._buildProjectField(),
                            const SizedBox(height: 8),
                            ..._buildGroupField(),
                            const Divider(height: 20),
                            ..._buildAppearance(context),
                            const Divider(height: 20),
                            ..._buildNotifications(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }
}
