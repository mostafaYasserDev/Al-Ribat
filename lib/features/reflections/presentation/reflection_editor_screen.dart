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
import 'widgets/apple_morph_route.dart';
import 'widgets/reflection_dialogs.dart';

enum _ToolbarPanel { none, colors, projects, moods }

class ReflectionEditorScreen extends ConsumerStatefulWidget {
  const ReflectionEditorScreen({super.key, this.entry});

  final ReflectionEntry? entry;

  static Future<void> open(
    BuildContext context, {
    ReflectionEntry? entry,
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
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
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
              // Circular Tonal Pin Button
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

              // Overflow menu for Edit History & Delete
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
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text('حذف الخاطرة',
                              style: TextStyle(color: colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),

              // Telegram-style Done / Save Pill
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
                          horizontal: 12, vertical: 6),
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
                          fontSize: 12.5, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Optional Title Field
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

                      // Active context badges (Project & Mood only; Prayer is in header)
                      if (_mood != null || _linkedContextTitle != null) ...[
                        const SizedBox(height: 8),
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
                            if (_mood != null)
                              MoodDisplayChip(mood: _mood!, dense: true),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Pure Writing Area
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

              // Smooth Expandable Sub-Panel
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: _activePanel == _ToolbarPanel.none
                    ? const SizedBox.shrink()
                    : _buildSubPanel(context, projectNames, colorScheme),
              ),

              // Telegram-inspired Floating / Pill Bottom Bar
              SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _BottomToolPill(
                        icon: Icons.palette_outlined,
                        label: 'لون',
                        isActive: _activePanel == _ToolbarPanel.colors ||
                            _colorKey != null,
                        onTap: () => _togglePanel(_ToolbarPanel.colors),
                      ),
                      if (projectNames.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _BottomToolPill(
                          icon: Icons.folder_outlined,
                          label: 'مشروع',
                          isActive: _activePanel == _ToolbarPanel.projects ||
                              _linkedContextTitle != null,
                          onTap: () => _togglePanel(_ToolbarPanel.projects),
                        ),
                      ],
                      const SizedBox(width: 6),
                      _BottomToolPill(
                        icon: Icons.mood_outlined,
                        label: 'شعور',
                        isActive: _activePanel == _ToolbarPanel.moods ||
                            _mood != null,
                        onTap: () => _togglePanel(_ToolbarPanel.moods),
                      ),
                      const Spacer(),
                      Text(
                        _hasChanges ? 'تعديل غير محفوظ' : 'محفوظ تلقائياً',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: _hasChanges
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
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

class _BottomToolPill extends StatelessWidget {
  const _BottomToolPill({
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
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
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
