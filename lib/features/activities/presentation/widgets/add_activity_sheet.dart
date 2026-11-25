import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/features/home/presentation/widgets/home_prayer_hero_card.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';
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
              TextButton.icon(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final t = await showModalBottomSheet<ActivityTemplate>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const TemplatesSheet(),
                  );
                  if (t != null) _applyTemplate(t);
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                label: const Text('قوالب'),
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
                          decoration: const InputDecoration(
                            hintText: 'اسم النشاط أو المهمة…',
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
                            : const SizedBox.shrink(),
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
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _targetGoalController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'الهدف (مثال: 20)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _goalUnitController,
                                  decoration: const InputDecoration(
                                    labelText: 'الوحدة (صفحة، دقيقة)',
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                      ? Text(
                          'الساعة ${_reminderTime.format(context)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
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
                        final p = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime,
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
                          _projectController.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
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
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _projectController,
                                  decoration: const InputDecoration(
                                    labelText: 'اسم المشروع',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _groupController,
                                  decoration: const InputDecoration(
                                    labelText: 'الجانب / المجموعة',
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 42,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _activityIcons.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) {
                                    final iconName = _activityIcons[i];
                                    final selected = _selectedIcon == iconName;
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(
                                            () => _selectedIcon = iconName);
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        width: 42,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? previewColor.withValues(
                                                  alpha: 0.16)
                                              : colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.45),
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          border: Border.all(
                                            color: selected
                                                ? previewColor
                                                : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          AppIcons.getIconData(iconName),
                                          size: 20,
                                          color: selected
                                              ? previewColor
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 34,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _activityColors.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) {
                                    final hex = _activityColors[i];
                                    final selected = _selectedColor == hex;
                                    final c = AppIcons.parseColor(hex) ??
                                        colorScheme.primary;
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedColor = hex);
                                      },
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: c,
                                          shape: BoxShape.circle,
                                          border: selected
                                              ? Border.all(
                                                  color: colorScheme.onSurface,
                                                  width: 2.5,
                                                )
                                              : null,
                                        ),
                                        child: selected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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
