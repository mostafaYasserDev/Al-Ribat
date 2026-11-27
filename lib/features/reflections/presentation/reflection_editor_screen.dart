import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/core/theme/app_moods.dart';
import 'package:al_ribat/core/ui_feedback.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';
import '../../projects/data/project_metadata_service.dart';
import '../../settings/presentation/widgets/settings_action_sheet.dart';
import '../../settings/presentation/widgets/settings_ui_components.dart';
import '../domain/reflection_entry.dart';
import 'widgets/apple_morph_route.dart';
import 'widgets/reflection_dialogs.dart';
import 'widgets/reflection_picker_sheets.dart';

class ReflectionEditorScreen extends ConsumerStatefulWidget {
  const ReflectionEditorScreen({super.key, this.entry, this.initialMood});

  final ReflectionEntry? entry;
  final String? initialMood;

  static Future<void> open(
    BuildContext context, {
    ReflectionEntry? entry,
    String? initialMood,
    BuildContext? sourceContext,
    Color? sourceColor,
    double sourceRadius = 16,
  }) {
    final sourceRect = captureWidgetRect(sourceContext);
    return Navigator.of(context).push(
      AppleMorphRoute<void>(
        sourceRect: sourceRect,
        sourceColor: sourceColor,
        sourceRadius: sourceRadius,
        builder: (_) => ReflectionEditorScreen(
          entry: entry,
          initialMood: initialMood,
        ),
      ),
    );
  }

  @override
  ConsumerState<ReflectionEditorScreen> createState() =>
      _ReflectionEditorScreenState();
}

class _ReflectionEditorScreenState
    extends ConsumerState<ReflectionEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final _moreBtnKey = GlobalKey();
  final _moodBtnKey = GlobalKey();
  final _projectBtnKey = GlobalKey();
  ReflectionEntry? _savedEntry;
  Timer? _autoSaveTimer;
  late bool _isPinned;
  late List<String> _selectedMoods;
  String? _linkedContextTitle;
  bool _isSaving = false;
  bool _didExit = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _savedEntry = e;
    _titleController = TextEditingController(text: e?.title ?? '');
    _bodyController = TextEditingController(text: e?.text ?? '');
    _isPinned = e?.isPinned ?? false;
    _selectedMoods = e != null
        ? List<String>.from(e.moods)
        : (widget.initialMood != null ? [widget.initialMood!] : <String>[]);
    _linkedContextTitle = e?.linkedContextTitle;

    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {});
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    if (!_hasChanges || !_hasContent) return;
    _autoSaveTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && !_didExit) {
        _persistNow();
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.removeListener(_onTextChanged);
    _bodyController.removeListener(_onTextChanged);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _hasContent {
    return _titleController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty ||
        _selectedMoods.isNotEmpty;
  }

  bool get _moodsChanged {
    final original = _savedEntry?.moods ?? const <String>[];
    if (original.length != _selectedMoods.length) return true;
    return !original.every(_selectedMoods.contains);
  }

  bool get _hasChanges {
    final e = _savedEntry;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (e == null) return _hasContent;
    return (e.title ?? '') != title ||
        e.text != body ||
        e.isPinned != _isPinned ||
        _moodsChanged ||
        e.linkedContextTitle != _linkedContextTitle;
  }

  Future<void> _persistNow() async {
    _autoSaveTimer?.cancel();
    if (_isSaving || !_hasChanges || !_hasContent) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (mounted) setState(() => _isSaving = true);
    try {
      final notifier = ref.read(reflectionsProvider.notifier);
      final existing = _savedEntry;
      if (existing == null) {
        final prayerName =
            ref.read(dayStateProvider).currentPrayerPhase.arabicName;
        final created = await notifier.add(
          body,
          title: title,
          isPinned: _isPinned,
          moods: _selectedMoods,
          prayerPhaseName: prayerName,
          linkedContextTitle: _linkedContextTitle,
        );
        _savedEntry = created;
      } else {
        final updated = await notifier.updateReflection(
          existing,
          body,
          title: title,
          clearTitle: title.isEmpty,
          isPinned: _isPinned,
          newMoods: _selectedMoods,
          linkedContextTitle: _linkedContextTitle,
          clearLinkedContext: _linkedContextTitle == null,
        );
        _savedEntry = updated;
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndExit() async {
    if (_didExit) return;
    _didExit = true;
    _autoSaveTimer?.cancel();

    if (_hasChanges && _hasContent) {
      await _persistNow();
      lightSuccessHaptic();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteAndExit() async {
    final existing = widget.entry;
    if (existing == null) return;
    final confirmed = await ReflectionDialogs.confirmDelete(context);
    if (!confirmed || !mounted) return;
    _didExit = true;
    await ref.read(reflectionsProvider.notifier).delete(existing.id);
    lightSuccessHaptic();
    if (mounted) {
      appSnack(context, 'تم حذف الخاطرة.');
      Navigator.of(context).pop();
    }
  }

  Future<void> _openMoodPicker() async {
    HapticFeedback.lightImpact();
    final picked = await showMoodPickerSheet(
      context,
      initialMoods: _selectedMoods,
      anchorKey: _moodBtnKey,
    );
    if (picked != null && mounted) {
      setState(() => _selectedMoods = picked);
      _persistNow();
    }
  }

  Future<void> _openProjectPicker(List<String> projectNames) async {
    HapticFeedback.lightImpact();
    final res = await showProjectPickerSheet(
      context,
      projectNames: projectNames,
      currentProjectTag: _linkedContextTitle,
      anchorKey: _projectBtnKey,
    );
    if (res != null && mounted) {
      setState(() => _linkedContextTitle = res.projectTag);
      _persistNow();
    }
  }

  Future<void> _showMoreMenu(ReflectionEntry existing) async {
    HapticFeedback.lightImpact();
    final action = await showAnchoredSettingsMenu<String>(
      context: context,
      anchorKey: _moreBtnKey,
      title: 'خيارات الخاطرة',
      options: [
        if (existing.editHistory.isNotEmpty)
          const AnchoredMenuOption(
            value: 'history',
            title: 'سجل التعديلات',
            subtitle: 'عرض النسخ السابقة للخاطرة',
            icon: Icons.history_rounded,
            color: Color(0xFF007AFF),
          ),
        const AnchoredMenuOption(
          value: 'delete',
          title: 'حذف الخاطرة',
          subtitle: 'إزالة الخاطرة نهائياً',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
        ),
      ],
    );
    if (action == null || !mounted) return;
    if (action == 'history') {
      ReflectionDialogs.showEditHistory(context, existing);
    } else if (action == 'delete') {
      await _deleteAndExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = theme.scaffoldBackgroundColor;
    final existing = widget.entry;

    final activities = ref.watch(activitiesProvider).valueOrNull ?? const [];
    final projectNames = activities
        .map((a) => a.projectName?.trim() ?? '')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final headerSubtitle = existing != null
        ? [
            if (existing.prayerPhaseName != null)
              'رباط ${existing.prayerPhaseName!}',
            DateFormat('h:mm a · d MMM', 'ar').format(existing.createdAt),
          ].join(' · ')
        : 'خاطرة جديدة · حفظ تلقائي';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _saveAndExit();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.6),
              child: Divider(
                height: 0.6,
                thickness: 0.6,
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'رجوع وحفظ',
              onPressed: _saveAndExit,
            ),
            title: Text(
              headerSubtitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: PressableScale(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isPinned = !_isPinned);
                    _persistNow();
                  },
                  child: Tooltip(
                    message: _isPinned ? 'إلغاء التثبيت' : 'تثبيت في الأعلى',
                    child: Material(
                      color: _isPinned
                          ? colorScheme.primary.withValues(alpha: 0.14)
                          : colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(11),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isPinned = !_isPinned);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            size: 18,
                            color: _isPinned
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (existing != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: KeyedSubtree(
                    key: _moreBtnKey,
                    child: PressableScale(
                      onTap: () => _showMoreMenu(existing),
                      child: Material(
                        color: colorScheme.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(11),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _showMoreMenu(existing),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12, start: 2),
                child: PressableScale(
                  enabled: !_isSaving,
                  onTap: _saveAndExit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: _hasChanges
                          ? colorScheme.primary.withValues(alpha: 0.15)
                          : colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isSaving ? null : _saveAndExit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSaving)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: _hasChanges
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              'تم',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _hasChanges
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _titleController,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'عنوان الخاطرة (اختياري)',
                          hintStyle: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.45),
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textInputAction: TextInputAction.next,
                        maxLines: 2,
                      ),
                      if (_selectedMoods.isNotEmpty ||
                          _linkedContextTitle != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (_linkedContextTitle != null)
                              () {
                                final ctxTitle = _linkedContextTitle!;
                                IconData badgeIcon =
                                    ctxTitle.startsWith('تركيز:')
                                        ? Icons.timer_outlined
                                        : Icons.folder_outlined;
                                Color badgeColor = colorScheme.secondary;
                                if (ctxTitle.startsWith('مشروع: ')) {
                                  final pName =
                                      ctxTitle.substring('مشروع: '.length);
                                  final info =
                                      ProjectGroupsService.getProjectInfo(
                                          pName);
                                  if (info?.iconName != null) {
                                    badgeIcon =
                                        AppIcons.getIconData(info!.iconName);
                                  }
                                  if (info?.colorHex != null) {
                                    badgeColor =
                                        AppIcons.parseColor(info!.colorHex) ??
                                            colorScheme.secondary;
                                  }
                                }
                                return _EditorBadge(
                                  icon: badgeIcon,
                                  label: ctxTitle,
                                  color: badgeColor,
                                  onRemove: () {
                                    setState(() => _linkedContextTitle = null);
                                    _persistNow();
                                  },
                                );
                              }(),
                            for (final mood in _selectedMoods)
                              MoodDisplayChip(
                                mood: mood,
                                dense: true,
                                onRemove: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedMoods.remove(mood));
                                },
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bodyController,
                        autofocus: existing == null,
                        maxLines: null,
                        minLines: 12,
                        keyboardType: TextInputType.multiline,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'دوّن تأملك أو خاطرتك بكل هدوء…',
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.45),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _TelegramBottomComposeBar(
                moodBtnKey: _moodBtnKey,
                projectBtnKey: _projectBtnKey,
                moodCount: _selectedMoods.length,
                hasProject: _linkedContextTitle != null,
                showProjectAction: projectNames.isNotEmpty,
                hasChanges: _hasChanges,
                isSaving: _isSaving,
                onPickMoods: _openMoodPicker,
                onPickProject: () => _openProjectPicker(projectNames),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelegramBottomComposeBar extends StatelessWidget {
  const _TelegramBottomComposeBar({
    required this.moodBtnKey,
    required this.projectBtnKey,
    required this.moodCount,
    required this.hasProject,
    required this.showProjectAction,
    required this.hasChanges,
    required this.isSaving,
    required this.onPickMoods,
    required this.onPickProject,
  });

  final GlobalKey moodBtnKey;
  final GlobalKey projectBtnKey;
  final int moodCount;
  final bool hasProject;
  final bool showProjectAction;
  final bool hasChanges;
  final bool isSaving;
  final VoidCallback onPickMoods;
  final VoidCallback onPickProject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barBg = (theme.cardTheme.color ??
            (isDark ? const Color(0xFF111B2E) : Colors.white))
        .withValues(alpha: 0.88);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: barBg,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: isDark ? 0.09 : 0.07),
                width: 0.6,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  KeyedSubtree(
                    key: moodBtnKey,
                    child: _BottomActionButton(
                      icon: Icons.mood_rounded,
                      label:
                          moodCount > 0 ? 'المشاعر ($moodCount)' : 'إضافة شعور',
                      color: theme.colorScheme.primary,
                      isActive: moodCount > 0,
                      onTap: onPickMoods,
                    ),
                  ),
                  if (showProjectAction) ...[
                    const SizedBox(width: 8),
                    KeyedSubtree(
                      key: projectBtnKey,
                      child: _BottomActionButton(
                        icon: Icons.folder_rounded,
                        label: hasProject ? 'المشروع ✓' : 'ربط بمشروع',
                        color: const Color(0xFF007AFF),
                        isActive: hasProject,
                        onTap: onPickProject,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSaving
                              ? const Color(0xFF007AFF)
                              : hasChanges
                                  ? const Color(0xFFFF9500)
                                  : const Color(0xFF34C759),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSaving
                            ? 'جاري الحفظ…'
                            : hasChanges
                                ? 'تعديل…'
                                : 'محفوظ',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.56),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isActive
        ? color.withValues(alpha: isDark ? 0.22 : 0.12)
        : theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.05);
    final fg =
        isActive ? color : theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return PressableScale(
      onTap: onTap,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          splashColor: color.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorBadge extends StatelessWidget {
  const _EditorBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.onRemove,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              child: Icon(Icons.close_rounded, size: 13, color: color),
            ),
          ],
        ],
      ),
    );
  }
}
