import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/theme/app_moods.dart';
import 'package:al_ribat/core/ui_feedback.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';
import '../domain/reflection_colors.dart';
import '../domain/reflection_entry.dart';
import 'widgets/reflection_dialogs.dart';

enum _ToolbarPanel { none, colors, projects, moods }

class ReflectionEditorScreen extends ConsumerStatefulWidget {
  const ReflectionEditorScreen({super.key, this.entry});

  final ReflectionEntry? entry;

  static Future<void> open(BuildContext context, {ReflectionEntry? entry}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReflectionEditorScreen(entry: entry),
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
  String? _colorKey;
  String? _mood;
  String? _linkedContextTitle;
  _ToolbarPanel _activePanel = _ToolbarPanel.none;
  bool _isSaving = false;
  bool _didExit = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleController = TextEditingController(text: e?.title ?? '');
    _bodyController = TextEditingController(text: e?.text ?? '');
    _isPinned = e?.isPinned ?? false;
    _colorKey = e?.colorKey;
    _mood = e?.mood;
    _linkedContextTitle = e?.linkedContextTitle;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _hasContent {
    return _titleController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty ||
        _mood != null;
  }

  bool get _hasChanges {
    final e = widget.entry;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (e == null) return _hasContent;
    return (e.title ?? '') != title ||
        e.text != body ||
        e.isPinned != _isPinned ||
        e.colorKey != _colorKey ||
        e.mood != _mood ||
        e.linkedContextTitle != _linkedContextTitle;
  }

  Future<void> _saveAndExit() async {
    if (_didExit || _isSaving) return;
    _didExit = true;

    if (!_hasChanges) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (!_hasContent) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

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
          colorKey: _colorKey,
          mood: _mood,
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
          colorKey: _colorKey,
          clearColor: _colorKey == null,
          newMood: _mood,
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

  void _togglePanel(_ToolbarPanel panel) {
    HapticFeedback.selectionClick();
    setState(() {
      _activePanel = _activePanel == panel ? _ToolbarPanel.none : panel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor =
        ReflectionColors.resolveBackground(_colorKey, theme.brightness) ??
            colorScheme.surface;
    final existing = widget.entry;

    final activities = ref.watch(activitiesProvider).valueOrNull ?? const [];
    final projectNames = activities
        .map((a) => a.projectName?.trim() ?? '')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'رجوع وحفظ',
              onPressed: _saveAndExit,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  color: _isPinned ? colorScheme.primary : null,
                ),
                tooltip: _isPinned ? 'إلغاء التثبيت' : 'تثبيت في الأعلى',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isPinned = !_isPinned);
                },
              ),
              if (existing != null && existing.editHistory.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  tooltip: 'سجل التعديلات',
                  onPressed: () =>
                      ReflectionDialogs.showEditHistory(context, existing),
                ),
              if (existing != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'حذف',
                  onPressed: _deleteAndExit,
                ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextButton(
                  onPressed: _isSaving ? null : _saveAndExit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'حفظ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Optional Title Field (Keep-style borderless)
                      TextField(
                        controller: _titleController,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'عنوان الخاطرة (اختياري)',
                          hintStyle: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.55),
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

                      // Active context badges (if any)
                      if (_mood != null ||
                          _linkedContextTitle != null ||
                          existing?.prayerPhaseName != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (existing?.prayerPhaseName != null)
                              _EditorBadge(
                                icon: Icons.mosque_rounded,
                                label: 'رباط ${existing!.prayerPhaseName!}',
                                color: colorScheme.primary,
                              ),
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
                            if (_mood != null)
                              MoodDisplayChip(mood: _mood!, dense: true),
                          ],
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Main Writing Area
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
                                .withValues(alpha: 0.55),
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

              // Expandable Bottom Sub-panel (Colors / Projects / Moods)
              if (_activePanel != _ToolbarPanel.none)
                _buildSubPanel(context, projectNames, colorScheme),

              // Keep-style Bottom Toolbar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.palette_outlined,
                          color: _activePanel == _ToolbarPanel.colors
                              ? colorScheme.primary
                              : null,
                        ),
                        tooltip: 'لون الخاطرة',
                        onPressed: () => _togglePanel(_ToolbarPanel.colors),
                      ),
                      if (projectNames.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.folder_outlined,
                            color: (_activePanel == _ToolbarPanel.projects ||
                                    _linkedContextTitle != null)
                                ? colorScheme.primary
                                : null,
                          ),
                          tooltip: 'ربط بمشروع',
                          onPressed: () => _togglePanel(_ToolbarPanel.projects),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.mood_outlined,
                          color: (_activePanel == _ToolbarPanel.moods ||
                                  _mood != null)
                              ? colorScheme.primary
                              : null,
                        ),
                        tooltip: 'إضافة شعور (اختياري)',
                        onPressed: () => _togglePanel(_ToolbarPanel.moods),
                      ),
                      const Spacer(),
                      Text(
                        existing != null
                            ? DateFormat('h:mm a · d MMM', 'ar')
                                .format(existing.createdAt)
                            : 'جديد',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubPanel(
    BuildContext context,
    List<String> projectNames,
    ColorScheme colorScheme,
  ) {
    final brightness = Theme.of(context).brightness;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.7),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_activePanel == _ToolbarPanel.colors) ...[
              _ColorDot(
                color: colorScheme.surface,
                isSelected: _colorKey == null,
                isDefault: true,
                onTap: () => setState(() => _colorKey = null),
              ),
              const SizedBox(width: 10),
              ...ReflectionColors.palette.map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: _ColorDot(
                    color: opt.resolve(brightness),
                    isSelected: _colorKey == opt.key,
                    onTap: () => setState(() => _colorKey = opt.key),
                  ),
                );
              }),
            ] else if (_activePanel == _ToolbarPanel.projects) ...[
              ...projectNames.map((proj) {
                final tag = 'مشروع: $proj';
                final isSelected = _linkedContextTitle == tag;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    avatar: const Icon(Icons.folder_outlined, size: 15),
                    label: Text(proj, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (sel) => setState(() {
                      _linkedContextTitle = sel ? tag : null;
                      _activePanel = _ToolbarPanel.none;
                    }),
                  ),
                );
              }),
            ] else if (_activePanel == _ToolbarPanel.moods) ...[
              ...AppMoods.options.map((opt) {
                final isSelected = _mood == opt.label;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      opt.icon,
                      size: 16,
                      color: isSelected ? null : opt.color,
                    ),
                    label:
                        Text(opt.label, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (sel) => setState(() {
                      _mood = sel ? opt.label : null;
                      _activePanel = _ToolbarPanel.none;
                    }),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.isDefault = false,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2.5 : 1.2,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check_rounded, size: 18, color: colorScheme.primary)
            : (isDefault
                ? Icon(Icons.format_color_reset_outlined,
                    size: 16, color: colorScheme.onSurfaceVariant)
                : null),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
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
              child: Icon(Icons.close, size: 13, color: color),
            ),
          ],
        ],
      ),
    );
  }
}
