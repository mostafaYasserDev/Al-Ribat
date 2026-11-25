import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/theme/app_moods.dart';
import 'package:al_ribat/core/ui_feedback.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';
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
  late bool _isPinned;
  late List<String> _selectedMoods;
  String? _linkedContextTitle;
  bool _isSaving = false;
  bool _didExit = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
    final original = widget.entry?.moods ?? const <String>[];
    if (original.length != _selectedMoods.length) return true;
    return !original.every(_selectedMoods.contains);
  }

  bool get _hasChanges {
    final e = widget.entry;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (e == null) return _hasContent;
    return (e.title ?? '') != title ||
        e.text != body ||
        e.isPinned != _isPinned ||
        _moodsChanged ||
        e.linkedContextTitle != _linkedContextTitle;
  }

  Future<void> _saveAndExit() async {
    if (_didExit || _isSaving) return;
    _didExit = true;

    if (!_hasChanges || !_hasContent) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(reflectionsProvider.notifier);
      final existing = widget.entry;
      if (existing == null) {
        final prayerName =
            ref.read(dayStateProvider).currentPrayerPhase.arabicName;
        await notifier.add(
          body,
          title: title,
          isPinned: _isPinned,
          moods: _selectedMoods,
          prayerPhaseName: prayerName,
          linkedContextTitle: _linkedContextTitle,
        );
      } else {
        await notifier.updateReflection(
          existing,
          body,
          title: title,
          clearTitle: title.isEmpty,
          isPinned: _isPinned,
          newMoods: _selectedMoods,
          linkedContextTitle: _linkedContextTitle,
          clearLinkedContext: _linkedContextTitle == null,
        );
      }
      lightSuccessHaptic();
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
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
    );
    if (picked != null && mounted) {
      setState(() => _selectedMoods = picked);
    }
  }

  Future<void> _openProjectPicker(List<String> projectNames) async {
    HapticFeedback.lightImpact();
    final res = await showProjectPickerSheet(
      context,
      projectNames: projectNames,
      currentProjectTag: _linkedContextTitle,
    );
    if (res != null && mounted) {
      setState(() => _linkedContextTitle = res.projectTag);
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
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: _isPinned
                        ? colorScheme.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 20,
                      color: _isPinned
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    tooltip: _isPinned ? 'إلغاء التثبيت' : 'تثبيت في الأعلى',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isPinned = !_isPinned);
                    },
                  ),
                ),
              ),
              if (existing != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (val) {
                    if (val == 'history') {
                      ReflectionDialogs.showEditHistory(context, existing);
                    } else if (val == 'delete') {
                      _deleteAndExit();
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (existing.editHistory.isNotEmpty)
                      const PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('سجل التعديلات'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'حذف الخاطرة',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 2),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: FilledButton.tonalIcon(
                    key: ValueKey(_hasChanges),
                    style: FilledButton.styleFrom(
                      backgroundColor: _hasChanges
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.55),
                      foregroundColor: _hasChanges
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveAndExit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 16),
                    label: const Text(
                      'تم',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
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
                              _EditorBadge(
                                icon: _linkedContextTitle!.startsWith('تركيز:')
                                    ? Icons.timer_outlined
                                    : Icons.folder_outlined,
                                label: _linkedContextTitle!,
                                color: colorScheme.secondary,
                                onRemove: () =>
                                    setState(() => _linkedContextTitle = null),
                              ),
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
                moodCount: _selectedMoods.length,
                hasProject: _linkedContextTitle != null,
                showProjectAction: projectNames.isNotEmpty,
                hasChanges: _hasChanges,
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
    required this.moodCount,
    required this.hasProject,
    required this.showProjectAction,
    required this.hasChanges,
    required this.onPickMoods,
    required this.onPickProject,
  });

  final int moodCount;
  final bool hasProject;
  final bool showProjectAction;
  final bool hasChanges;
  final VoidCallback onPickMoods;
  final VoidCallback onPickProject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barBg = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    return SafeArea(
      top: false,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _BottomActionButton(
              icon: Icons.mood_rounded,
              label: moodCount > 0 ? 'المشاعر ($moodCount)' : 'إضافة شعور',
              isActive: moodCount > 0,
              onTap: onPickMoods,
            ),
            if (showProjectAction) ...[
              const SizedBox(width: 8),
              _BottomActionButton(
                icon: Icons.folder_outlined,
                label: hasProject ? 'المشروع ✓' : 'ربط بمشروع',
                isActive: hasProject,
                onTap: onPickProject,
              ),
            ],
            const Spacer(),
            Text(
              hasChanges ? 'غير محفوظ' : 'محفوظ تلقائياً',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: hasChanges
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: isActive
          ? colorScheme.primary.withValues(alpha: 0.12)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
