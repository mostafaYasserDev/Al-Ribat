import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/core/widgets/arabic_time_picker.dart';
import 'package:al_ribat/core/widgets/icon_color_picker.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/features/home/presentation/widgets/home_prayer_hero_card.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';
import 'package:al_ribat/features/projects/domain/project_aggregate.dart';
import 'package:al_ribat/features/projects/presentation/widgets/anchored_popover.dart';
import 'package:al_ribat/features/projects/presentation/widgets/new_project_dialog.dart';
import 'package:al_ribat/features/reflections/presentation/widgets/apple_morph_route.dart';
import 'package:al_ribat/presentation/widgets/templates_sheet.dart';

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

  /// Opens [AddActivitySheet] with an Apple spatial morph from [sourceContext].
  static Future<ActivityItem?> open(
    BuildContext context, {
    required Future<bool> Function(ActivityItem activity) onSave,
    ActivityItem? initialActivity,
    PrayerPhase? initialPhase,
    bool isIndependentInitial = false,
    String? initialProject,
    String? initialGroup,
    BuildContext? sourceContext,
    Color? sourceColor,
    double sourceRadius = 18,
  }) {
    final sourceRect = captureWidgetRect(sourceContext);
    return Navigator.of(context).push<ActivityItem>(
      AppleMorphRoute<ActivityItem>(
        sourceRect: sourceRect,
        sourceColor: sourceColor,
        sourceRadius: sourceRadius,
        builder: (_) => AddActivitySheet(
          onSave: onSave,
          initialActivity: initialActivity,
          initialPhase: initialPhase,
          isIndependentInitial: isIndependentInitial,
          initialProject: initialProject,
          initialGroup: initialGroup,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends ConsumerState<AddActivitySheet> {
  static const _activityIcons = [
    'task_alt',
    'menu_book',
    'wb_sunny',
    'nights_stay',
    'bedtime',
    'star',
    'fitness_center',
    'directions_walk',
    'water_drop',
    'translate',
    'family_restroom',
    'group',
  ];

  static const _activityColors = [
    '#1F6F4A',
    '#007AFF',
    '#FF9500',
    '#F43F5E',
    '#7C3AED',
    '#00897B',
    '#34C759',
    '#5C6BC0',
    '#E65100',
    '#607D8B',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _projectController;
  late final TextEditingController _groupController;
  late final TextEditingController _targetGoalController;
  late final TextEditingController _goalUnitController;

  late bool _isMeasurable;
  late ActivityRepetition _repetition;
  final Set<int> _repeatDays = {};
  late ActivityType _type;
  PrayerPhase? _linkedPrayer;
  late bool _notificationsEnabled;
  late TimeOfDay _reminderTime;
  String? _selectedIcon;
  String? _selectedColor;
  bool _saving = false;
  bool _showProjectFields = false;
  bool _showAppearanceFields = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialActivity;
    _titleController = TextEditingController(text: initial?.title ?? '')
      ..addListener(() => setState(() {}));
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    _projectController = TextEditingController(
        text: initial?.projectName ?? widget.initialProject ?? '');
    _groupController = TextEditingController(
        text: initial?.groupName ?? widget.initialGroup ?? '');

    _isMeasurable = initial?.isMeasurable ?? false;
    _targetGoalController = TextEditingController(
      text: initial?.targetGoal?.toInt().toString() ?? '',
    );
    _goalUnitController = TextEditingController(text: initial?.goalUnit ?? '');

    _repetition = initial?.repetition ?? ActivityRepetition.daily;
    _repeatDays.addAll(initial?.repeatDays ?? []);

    if (widget.isIndependentInitial) {
      _type = ActivityType.independent;
      _linkedPrayer = null;
    } else if (widget.initialPhase != null) {
      _type = ActivityType.afterPrayer;
      _linkedPrayer = widget.initialPhase;
    } else {
      _type = initial?.type ?? ActivityType.afterPrayer;
      _linkedPrayer = initial?.linkedPrayer ?? PrayerPhase.fajr;
    }

    _notificationsEnabled = initial?.notificationsEnabled ?? false;
    _reminderTime = initial != null &&
            initial.reminderHour != null &&
            initial.reminderMinute != null
        ? TimeOfDay(
            hour: initial.reminderHour!,
            minute: initial.reminderMinute!,
          )
        : TimeOfDay.now();

    _selectedIcon = initial?.iconName;
    _selectedColor = initial?.colorHex;
    _showProjectFields = _projectController.text.isNotEmpty;
    _showAppearanceFields = _selectedIcon != null || _selectedColor != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _projectController.dispose();
    _groupController.dispose();
    _targetGoalController.dispose();
    _goalUnitController.dispose();
    super.dispose();
  }

  void _applyTemplate(ActivityTemplate t) {
    setState(() {
      _titleController.text = t.title;
      if (t.description != null) _descriptionController.text = t.description!;
      _type = t.type;
      _linkedPrayer = t.linkedPrayer ?? _linkedPrayer;
      _selectedIcon = t.iconName;
      _selectedColor = t.colorHex;
      _repetition = t.repetition;
      _isMeasurable = t.isMeasurable;
      if (t.isMeasurable) {
        _targetGoalController.text = t.targetGoal?.toString() ?? '';
        _goalUnitController.text = t.goalUnit ?? '';
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      final selectedDate = ref.read(selectedDateProvider);
      final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final onceTargetDate = _repetition == ActivityRepetition.once
          ? (widget.initialActivity?.targetDate ?? selectedDateStr)
          : null;
      final createdAt = widget.initialActivity?.createdAt ??
          DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            12,
          );

      final act = ActivityItem(
        id: widget.initialActivity?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        repetition: _repetition,
        targetDate: onceTargetDate,
        repeatDays: (_repetition == ActivityRepetition.weekly ||
                _repetition == ActivityRepetition.monthly)
            ? _repeatDays.toList()
            : const [],
        type: _type,
        linkedPrayer: _type != ActivityType.independent ? _linkedPrayer : null,
        notificationsEnabled: _notificationsEnabled,
        reminderHour: _notificationsEnabled ? _reminderTime.hour : null,
        reminderMinute: _notificationsEnabled ? _reminderTime.minute : null,
        createdAt: createdAt,
        history: widget.initialActivity?.history ?? const [],
        orderIndex: widget.initialActivity?.orderIndex ?? 0,
        iconName: _selectedIcon,
        colorHex: _selectedColor,
        projectName: _projectController.text.trim().isEmpty
            ? null
            : _projectController.text.trim(),
        groupName: _groupController.text.trim().isEmpty
            ? null
            : _groupController.text.trim(),
        isMeasurable: _isMeasurable,
        targetGoal: _isMeasurable
            ? double.tryParse(_targetGoalController.text.trim())
            : null,
        goalUnit: _isMeasurable ? _goalUnitController.text.trim() : null,
      );

      final ok = await widget.onSave(act);
      if (ok && mounted) Navigator.pop(context, act);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final canSave = _titleController.text.trim().isNotEmpty;
    final previewColor =
        AppIcons.parseColor(_selectedColor) ?? colorScheme.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'إلغاء',
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.initialActivity == null ? 'نشاط جديد' : 'تعديل النشاط',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            if (widget.initialActivity == null)
              Builder(
                builder: (btnCtx) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final t = await TemplatesSheet.open(
                        context,
                        sourceContext: btnCtx,
                        sourceColor:
                            colorScheme.primary.withValues(alpha: 0.14),
                        sourceRadius: 18,
                      );
                      if (t != null) _applyTemplate(t);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'قوالب',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12, start: 4),
              child: FilledButton(
                onPressed: canSave && !_saving ? _save : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'حفظ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.6),
            child: Container(height: 0.6, color: dividerColor),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            MediaQuery.of(context).viewInsets.bottom + 36,
          ),
          children: [
            // 1. Basic Info Card
            _GroupedCard(
              cardColor: cardColor,
              dividerColor: dividerColor,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: previewColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          AppIcons.getIconData(_selectedIcon),
                          color: previewColor,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          autofocus: widget.initialActivity == null,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: 'اسم النشاط أو المهمة…',
                            hintStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.36),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 0.6, thickness: 0.6, color: dividerColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'ملاحظات إضافية أو نية خاصة (اختياري)',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),

            const _SectionLabel('الصلاة والتوقيت'),
            _GroupedCard(
              cardColor: cardColor,
              dividerColor: dividerColor,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          for (final phase in PrayerPhase.values)
                            Expanded(
                              child: _PrayerOptionChip(
                                phase: phase,
                                isSelected: _type != ActivityType.independent &&
                                    _linkedPrayer == phase,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (_type == ActivityType.independent) {
                                      _type = ActivityType.afterPrayer;
                                    }
                                    _linkedPrayer = phase;
                                  });
                                },
                              ),
                            ),
                          Expanded(
                            child: _FreeTaskChip(
                              isSelected: _type == ActivityType.independent,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _type = ActivityType.independent;
                                  _linkedPrayer = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _type != ActivityType.independent
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _SlidingTwoOptionBar<ActivityType>(
                                  firstValue: ActivityType.afterPrayer,
                                  firstLabel: 'بعد الصلاة',
                                  secondValue: ActivityType.beforePrayer,
                                  secondLabel: 'قبل الصلاة',
                                  selected: _type,
                                  onChanged: (v) => setState(() => _type = v),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _IndependentTimeRow(
                                  enabled: _notificationsEnabled,
                                  time: _reminderTime,
                                  onToggle: (v) async {
                                    HapticFeedback.selectionClick();
                                    setState(() => _notificationsEnabled = v);
                                    if (v && context.mounted) {
                                      final picked = await showArabicTimePicker(
                                        context,
                                        initialTime: _reminderTime,
                                        title: 'وقت النشاط الحر',
                                      );
                                      if (picked != null) {
                                        setState(() => _reminderTime = picked);
                                      }
                                    }
                                  },
                                  onPickTime: () async {
                                    final picked = await showArabicTimePicker(
                                      context,
                                      initialTime: _reminderTime,
                                      title: 'وقت النشاط الحر',
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _notificationsEnabled = true;
                                        _reminderTime = picked;
                                      });
                                    }
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const _SectionLabel('معدل التكرار'),
            _GroupedCard(
              cardColor: cardColor,
              dividerColor: dividerColor,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RepetitionSegmentedBar(
                        selected: _repetition,
                        onChanged: (rep) {
                          HapticFeedback.selectionClick();
                          setState(() => _repetition = rep);
                        },
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _buildRepetitionDetails(theme),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const _SectionLabel('خيارات إضافية'),
            _GroupedCard(
              cardColor: cardColor,
              dividerColor: dividerColor,
              children: [
                // Measurable goal
                SwitchListTile.adaptive(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  secondary: const _SquircleIcon(
                    icon: Icons.track_changes_rounded,
                    color: Color(0xFF007AFF),
                  ),
                  title: const Text(
                    'هدف رقمي قابل للقياس',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  subtitle: const Text(
                    'مثال: 20 صفحة، 15 دقيقة',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isMeasurable,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _isMeasurable = v);
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _isMeasurable
                      ? _MeasurableGoalEditor(
                          targetController: _targetGoalController,
                          unitController: _goalUnitController,
                          onChanged: () => setState(() {}),
                        )
                      : const SizedBox.shrink(),
                ),
                Divider(
                  height: 0.6,
                  thickness: 0.6,
                  indent: 56,
                  color: dividerColor,
                ),

                // Reminder toggle
                SwitchListTile.adaptive(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  secondary: const _SquircleIcon(
                    icon: Icons.notifications_active_rounded,
                    color: Color(0xFFFF3B30),
                  ),
                  title: const Text(
                    'تذكير مخصص',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  subtitle: _notificationsEnabled
                      ? InkWell(
                          onTap: () async {
                            final p = await showArabicTimePicker(
                              context,
                              initialTime: _reminderTime,
                              title: 'وقت التذكير المخصص',
                            );
                            if (p != null) setState(() => _reminderTime = p);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              'الساعة ${formatArabicTime(_reminderTime)}  (تعديل)',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      : null,
                  value: _notificationsEnabled,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    setState(() => _notificationsEnabled = v);
                    if (v) {
                      await ref
                          .read(notificationServiceProvider)
                          .ensureNotificationPermission();
                      if (context.mounted) {
                        final p = await showArabicTimePicker(
                          context,
                          initialTime: _reminderTime,
                          title: 'وقت التذكير المخصص',
                        );
                        if (p != null) setState(() => _reminderTime = p);
                      }
                    }
                  },
                ),
                Divider(
                  height: 0.6,
                  thickness: 0.6,
                  indent: 56,
                  color: dividerColor,
                ),

                // Project & Group
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: const _SquircleIcon(
                    icon: Icons.folder_rounded,
                    color: Color(0xFFFF9500),
                  ),
                  title: const Text(
                    'الربط بمشروع',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  subtitle: _projectController.text.isNotEmpty
                      ? Text(
                          _groupController.text.isNotEmpty
                              ? '${_projectController.text} • ${_groupController.text}'
                              : _projectController.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                  trailing: Icon(
                    _showProjectFields
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                  onTap: () =>
                      setState(() => _showProjectFields = !_showProjectFields),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _showProjectFields
                      ? _ProjectLinkEditor(
                          projectController: _projectController,
                          groupController: _groupController,
                          onChanged: () => setState(() {}),
                        )
                      : const SizedBox.shrink(),
                ),
                Divider(
                  height: 0.6,
                  thickness: 0.6,
                  indent: 56,
                  color: dividerColor,
                ),

                // Appearance
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: _SquircleIcon(
                    icon: Icons.palette_rounded,
                    color: previewColor,
                  ),
                  title: const Text(
                    'الأيقونة واللون',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                  trailing: Icon(
                    _showAppearanceFields
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                  onTap: () => setState(
                      () => _showAppearanceFields = !_showAppearanceFields),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _showAppearanceFields
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                          child: IconColorPickerWidget(
                            selectedIcon: _selectedIcon,
                            selectedColor: _selectedColor,
                            colors: _activityColors,
                            quickIcons: _activityIcons,
                            fallbackColor: previewColor,
                            onIconSelected: (icon) =>
                                setState(() => _selectedIcon = icon),
                            onColorSelected: (hex) =>
                                setState(() => _selectedColor = hex),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepetitionDetails(ThemeData theme) {
    if (_repetition == ActivityRepetition.once) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          'سيظهر في: ${DateFormat('yyyy/MM/dd').format(ref.watch(selectedDateProvider))}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    if (_repetition == ActivityRepetition.weekly) {
      const days = ['إ', 'ث', 'أ', 'خ', 'ج', 'س', 'ح'];
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            for (int i = 1; i <= 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_repeatDays.contains(i)) {
                          _repeatDays.remove(i);
                        } else {
                          _repeatDays.add(i);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _repeatDays.contains(i)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          days[i - 1],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _repeatDays.contains(i)
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    if (_repetition == ActivityRepetition.monthly) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (int i = 1; i <= 31; i++)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (_repeatDays.contains(i)) {
                      _repeatDays.remove(i);
                    } else {
                      _repeatDays.add(i);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _repeatDays.contains(i)
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$i',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _repeatDays.contains(i)
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 18, 6, 8),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
        ),
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({
    required this.cardColor,
    required this.dividerColor,
    required this.children,
  });

  final Color cardColor;
  final Color dividerColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: dividerColor, width: 0.7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SquircleIcon extends StatelessWidget {
  const _SquircleIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8.5),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class _PrayerOptionChip extends StatelessWidget {
  const _PrayerOptionChip({
    required this.phase,
    required this.isSelected,
    required this.onTap,
  });

  final PrayerPhase phase;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = prayerPhaseVisual(phase);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? visual.color.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? visual.color : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              visual.icon,
              size: 18,
              color: isSelected
                  ? visual.color
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
            ),
            const SizedBox(height: 3),
            Text(
              phase.arabicName,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? visual.color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreeTaskChip extends StatelessWidget {
  const _FreeTaskChip({required this.isSelected, required this.onTap});
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 18,
              color: isSelected
                  ? color
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
            ),
            const SizedBox(height: 3),
            Text(
              'حرة',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidingTwoOptionBar<T> extends StatelessWidget {
  const _SlidingTwoOptionBar({
    required this.firstValue,
    required this.firstLabel,
    required this.secondValue,
    required this.secondLabel,
    required this.selected,
    required this.onChanged,
  });

  final T firstValue;
  final String firstLabel;
  final T secondValue;
  final String secondLabel;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF0A101D)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    final pillColor = isDark ? const Color(0xFF1D2C46) : Colors.white;
    final idx = selected == secondValue ? 1 : 0;

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                start: idx * w,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(9.5),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(firstValue);
                      },
                      child: Center(
                        child: Text(
                          firstLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                idx == 0 ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(secondValue);
                      },
                      child: Center(
                        child: Text(
                          secondLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                idx == 1 ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RepetitionSegmentedBar extends StatelessWidget {
  const _RepetitionSegmentedBar({
    required this.selected,
    required this.onChanged,
  });

  final ActivityRepetition selected;
  final ValueChanged<ActivityRepetition> onChanged;

  static const _items = [
    (value: ActivityRepetition.once, label: 'مرة'),
    (value: ActivityRepetition.daily, label: 'يومي'),
    (value: ActivityRepetition.weekly, label: 'أسبوعي'),
    (value: ActivityRepetition.monthly, label: 'شهري'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark
        ? const Color(0xFF0A101D)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    final pillColor = isDark ? const Color(0xFF1D2C46) : Colors.white;
    final idx = _items.indexWhere((e) => e.value == selected).clamp(0, 3);

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth / _items.length;
          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                start: idx * w,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(9.5),
                  ),
                ),
              ),
              Row(
                children: _items.map((item) {
                  final isSelected = item.value == selected;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(item.value),
                      child: Center(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IndependentTimeRow extends StatelessWidget {
  const _IndependentTimeRow({
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 18,
            color: enabled
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تحديد وقت بالساعة',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                if (enabled)
                  GestureDetector(
                    onTap: onPickTime,
                    child: Text(
                      'الساعة ${formatArabicTime(time)}  (تغيير)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(value: enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}

class _MeasurableGoalEditor extends StatelessWidget {
  const _MeasurableGoalEditor({
    required this.targetController,
    required this.unitController,
    required this.onChanged,
  });

  final TextEditingController targetController;
  final TextEditingController unitController;
  final VoidCallback onChanged;

  static const _defaultUnits = ['صفحة', 'دقيقة', 'مرة'];

  void _step(int delta) {
    final current = int.tryParse(targetController.text.trim()) ?? 0;
    final next = (current + delta).clamp(1, 9999);
    targetController.text = next.toString();
    HapticFeedback.selectionClick();
    onChanged();
  }

  void _openCustomUnitPopover(BuildContext anchorContext) {
    HapticFeedback.selectionClick();
    final current = unitController.text.trim();
    final ctrl = TextEditingController(
      text: _defaultUnits.contains(current) ? '' : current,
    );

    showAnchoredPopover(
      anchorContext,
      width: 248,
      preferAbove: true,
      anchorRadius: 10,
      builder: (popCtx) {
        final theme = Theme.of(popCtx);
        final colorScheme = theme.colorScheme;
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'وحدة قياس مخصصة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (val) {
                  final trimmed = val.trim();
                  if (trimmed.isNotEmpty) {
                    unitController.text = trimmed;
                    onChanged();
                  }
                  Navigator.pop(popCtx);
                },
                decoration: InputDecoration(
                  hintText: 'مثال: ركعة، آية، كوب، ساعة…',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.36),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () {
                  final trimmed = ctrl.text.trim();
                  if (trimmed.isNotEmpty) {
                    unitController.text = trimmed;
                    onChanged();
                  }
                  Navigator.pop(popCtx);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'حفظ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final innerBg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);
    final trackColor = isDark
        ? const Color(0xFF0A101D)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    final pillColor = isDark ? const Color(0xFF1D2C46) : Colors.white;
    final currentUnit = unitController.text.trim();
    final isCustomActive =
        currentUnit.isNotEmpty && !_defaultUnits.contains(currentUnit);
    final selectedIdx =
        isCustomActive ? 3 : _defaultUnits.indexOf(currentUnit).clamp(0, 2);
    final customBtnKey = GlobalKey();

    final unitLabels = [
      ..._defaultUnits,
      isCustomActive ? currentUnit : 'مخصصة',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Target stepper row (supports +/- and direct number input)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: innerBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(
                  'الهدف:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(width: 8),
                _StepperBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => _step(-1),
                ),
                Expanded(
                  child: TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (_) => onChanged(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: '1',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.35),
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                _StepperBtn(
                  icon: Icons.add_rounded,
                  onTap: () => _step(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Segmented bar for top 3 units + 4th button launching AnchoredPopover
          Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth / 4;
                return Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      start: selectedIdx * w,
                      top: 0,
                      bottom: 0,
                      width: w,
                      child: Container(
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(9.5),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(4, (i) {
                        final isCustomBtn = i == 3;
                        final isSel = selectedIdx == i;
                        return Expanded(
                          child: GestureDetector(
                            key: isCustomBtn ? customBtnKey : null,
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (isCustomBtn) {
                                _openCustomUnitPopover(
                                  customBtnKey.currentContext ?? context,
                                );
                              } else {
                                HapticFeedback.selectionClick();
                                unitController.text = _defaultUnits[i];
                                onChanged();
                              }
                            },
                            child: Center(
                              child: Text(
                                unitLabels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isCustomBtn && isCustomActive
                                      ? colorScheme.primary
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: colorScheme.primary),
      ),
    );
  }
}

class _ProjectLinkEditor extends ConsumerWidget {
  const _ProjectLinkEditor({
    required this.projectController,
    required this.groupController,
    required this.onChanged,
  });

  final TextEditingController projectController;
  final TextEditingController groupController;
  final VoidCallback onChanged;

  void _openProjectPicker(
    BuildContext anchorContext,
    BuildContext hostContext,
    List<ProjectAggregate> projects,
  ) {
    HapticFeedback.selectionClick();
    final currentProject = projectController.text.trim();

    showAnchoredPopover(
      anchorContext,
      width: 268,
      preferAbove: true,
      anchorRadius: 12,
      builder: (popCtx) {
        final theme = Theme.of(popCtx);
        final colorScheme = theme.colorScheme;
        final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    _PopoverSelectRow(
                      icon: Icons.block_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      label: 'بدون مشروع',
                      selected: currentProject.isEmpty,
                      onTap: () {
                        projectController.clear();
                        groupController.clear();
                        onChanged();
                        Navigator.pop(popCtx);
                      },
                    ),
                    for (final proj in projects) ...[
                      Divider(
                        height: 0.6,
                        thickness: 0.6,
                        indent: 46,
                        color: dividerColor,
                      ),
                      _PopoverSelectRow(
                        icon: proj.icon,
                        color: proj.color,
                        label: proj.name,
                        selected: currentProject == proj.name,
                        onTap: () {
                          projectController.text = proj.name;
                          groupController.clear();
                          onChanged();
                          Navigator.pop(popCtx);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 0.6, thickness: 0.6, color: dividerColor),
              InkWell(
                onTap: () {
                  Navigator.pop(popCtx);
                  NewProjectDialog.open(
                    hostContext,
                    sourceContext: anchorContext,
                    sourceColor: colorScheme.primary.withValues(alpha: 0.14),
                    sourceRadius: 12,
                    onCreate: ({
                      required String projectName,
                      String? description,
                      String? iconName,
                      String? colorHex,
                    }) async {
                      projectController.text = projectName;
                      groupController.clear();
                      onChanged();
                    },
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'إنشاء مشروع جديد',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openGroupPicker(
    BuildContext anchorContext,
    Set<String> groups,
  ) {
    HapticFeedback.selectionClick();
    final currentGroup = groupController.text.trim();
    final newGroupCtrl = TextEditingController();

    showAnchoredPopover(
      anchorContext,
      width: 268,
      preferAbove: true,
      anchorRadius: 12,
      builder: (popCtx) {
        final theme = Theme.of(popCtx);
        final colorScheme = theme.colorScheme;
        final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 330),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    _PopoverSelectRow(
                      icon: Icons.layers_outlined,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                      label: 'عام (بدون جانب محدد)',
                      selected: currentGroup.isEmpty,
                      onTap: () {
                        groupController.clear();
                        onChanged();
                        Navigator.pop(popCtx);
                      },
                    ),
                    for (final g in groups) ...[
                      Divider(
                        height: 0.6,
                        thickness: 0.6,
                        indent: 46,
                        color: dividerColor,
                      ),
                      _PopoverSelectRow(
                        icon: Icons.layers_rounded,
                        color: colorScheme.primary,
                        label: g,
                        selected: currentGroup == g,
                        onTap: () {
                          groupController.text = g;
                          onChanged();
                          Navigator.pop(popCtx);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 0.6, thickness: 0.6, color: dividerColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: newGroupCtrl,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (val) {
                            final t = val.trim();
                            if (t.isNotEmpty) {
                              groupController.text = t;
                              onChanged();
                            }
                            Navigator.pop(popCtx);
                          },
                          style: const TextStyle(fontSize: 12.5),
                          decoration: InputDecoration(
                            hintText: 'إضافة جانب جديد…',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.36),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: () {
                        final t = newGroupCtrl.text.trim();
                        if (t.isNotEmpty) {
                          groupController.text = t;
                          onChanged();
                        }
                        Navigator.pop(popCtx);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final innerBg = colorScheme.surfaceContainerHighest.withValues(alpha: 0.38);
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final activities =
        ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
    final projects = ProjectAggregate.fromActivities(activities, theme);
    final currentProject = projectController.text.trim();
    final currentGroup = groupController.text.trim();

    ProjectAggregate? selectedProj;
    for (final p in projects) {
      if (p.name == currentProject) {
        selectedProj = p;
        break;
      }
    }

    final groupsForSelected = <String>{};
    for (final a in activities) {
      if (a.projectName?.trim() == currentProject) {
        final g = a.groupName?.trim();
        if (g != null && g.isNotEmpty) groupsForSelected.add(g);
      }
    }
    if (currentGroup.isNotEmpty) groupsForSelected.add(currentGroup);

    final projectRowKey = GlobalKey();
    final groupRowKey = GlobalKey();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
      child: Material(
        color: innerBg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              key: projectRowKey,
              onTap: () => _openProjectPicker(
                projectRowKey.currentContext ?? context,
                context,
                projects,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (selectedProj?.color ?? const Color(0xFFFF9500))
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        selectedProj?.icon ?? Icons.folder_outlined,
                        size: 16,
                        color: selectedProj?.color ?? const Color(0xFFFF9500),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'المشروع',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        currentProject.isEmpty ? 'بدون مشروع' : currentProject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: currentProject.isEmpty
                              ? colorScheme.onSurface.withValues(alpha: 0.45)
                              : (selectedProj?.color ?? colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: currentProject.isNotEmpty
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Divider(
                          height: 0.6,
                          thickness: 0.6,
                          indent: 50,
                          color: dividerColor,
                        ),
                        InkWell(
                          key: groupRowKey,
                          onTap: () => _openGroupPicker(
                            groupRowKey.currentContext ?? context,
                            groupsForSelected,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 11),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.layers_rounded,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'الجانب',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.72),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    currentGroup.isEmpty ? 'عام' : currentGroup,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: currentGroup.isEmpty
                                          ? colorScheme.onSurface
                                              .withValues(alpha: 0.45)
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.unfold_more_rounded,
                                  size: 18,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopoverSelectRow extends StatelessWidget {
  const _PopoverSelectRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
