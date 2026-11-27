import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/theme/app_moods.dart';
import '../../../core/ui/error_view.dart';
import '../../../core/ui_feedback.dart';
import '../../settings/presentation/widgets/settings_action_sheet.dart';
import '../../settings/presentation/widgets/settings_ui_components.dart';
import '../domain/reflection_entry.dart';
import '../domain/reflection_search.dart';
import 'reflection_editor_screen.dart';
import 'widgets/reflection_dialogs.dart';
import 'widgets/reflection_entry_card.dart';
import 'widgets/reflection_quick_compose_card.dart';
import 'widgets/reflection_view_modes.dart';

class ReflectionHistoryScreen extends ConsumerStatefulWidget {
  const ReflectionHistoryScreen({super.key});

  @override
  ConsumerState<ReflectionHistoryScreen> createState() =>
      _ReflectionHistoryScreenState();
}

class _ReflectionHistoryScreenState
    extends ConsumerState<ReflectionHistoryScreen> {
  final _searchController = TextEditingController();
  final _viewModeBtnKey = GlobalKey();
  String _searchQuery = '';
  String _activeFilter = 'الكل';
  ReflectionViewMode _viewMode = ReflectionViewMode.grid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewEditor({
    BuildContext? sourceContext,
    Color? sourceColor,
    double sourceRadius = 18,
    String? initialMood,
  }) {
    HapticFeedback.lightImpact();
    ReflectionEditorScreen.open(
      context,
      initialMood: initialMood,
      sourceContext: sourceContext,
      sourceColor: sourceColor,
      sourceRadius: sourceRadius,
    );
  }

  void _openEditEditor(
    ReflectionEntry entry,
    BuildContext cardContext,
    Color bgColor,
  ) {
    HapticFeedback.lightImpact();
    ReflectionEditorScreen.open(
      context,
      entry: entry,
      sourceContext: cardContext,
      sourceColor: bgColor,
      sourceRadius: 17,
    );
  }

  Future<void> _pickViewMode() async {
    HapticFeedback.lightImpact();
    final chosen = await showAnchoredSettingsMenu<ReflectionViewMode>(
      context: context,
      anchorKey: _viewModeBtnKey,
      title: 'طريقة عرض التأملات',
      options: [
        for (final mode in ReflectionViewMode.values)
          AnchoredMenuOption(
            value: mode,
            title: mode.label,
            subtitle: _viewMode == mode ? '${mode.subtitle} ✓' : mode.subtitle,
            icon: mode.icon,
            color: _viewMode == mode
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
          ),
      ],
    );
    if (chosen != null && chosen != _viewMode && mounted) {
      HapticFeedback.selectionClick();
      setState(() => _viewMode = chosen);
    }
  }

  Future<void> _handleDelete(ReflectionEntry entry) async {
    final confirmed = await ReflectionDialogs.confirmDelete(context);
    if (!confirmed || !mounted) return;
    await ref.read(reflectionsProvider.notifier).delete(entry.id);
    lightSuccessHaptic();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('تم حذف الخاطرة.'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () {
            ref.read(reflectionsProvider.notifier).add(
                  entry.text,
                  title: entry.title,
                  isPinned: entry.isPinned,
                  colorKey: entry.colorKey,
                  moods: entry.moods,
                  prayerPhaseName: entry.prayerPhaseName,
                  linkedContextTitle: entry.linkedContextTitle,
                  createdAt: entry.createdAt,
                );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncReflections = ref.watch(reflectionsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        floatingActionButton: Builder(
          builder: (fabCtx) => FloatingActionButton(
            heroTag: 'reflections_fab',
            onPressed: () => _openNewEditor(
              sourceContext: fabCtx,
              sourceColor: theme.colorScheme.primaryContainer,
              sourceRadius: 16,
            ),
            tooltip: 'خاطرة جديدة',
            child: const Icon(Icons.add_rounded),
          ),
        ),
        body: asyncReflections.when(
          data: (entries) => _buildBody(context, entries, theme, isDark),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorView(
            error: e,
            onRetry: () => ref.invalidate(reflectionsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<ReflectionEntry> entries,
    ThemeData theme,
    bool isDark,
  ) {
    final filtered = entries.where((e) {
      if (_searchQuery.isNotEmpty &&
          !ReflectionSearch.matches(e, _searchQuery)) {
        return false;
      }
      if (_activeFilter == 'مثبتة') return e.isPinned;
      if (_activeFilter != 'الكل') {
        return e.moods.contains(_activeFilter);
      }
      return true;
    }).toList();

    final pinned = filtered.where((e) => e.isPinned).toList();
    final others = filtered.where((e) => !e.isPinned).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          pinned: true,
          stretch: true,
          expandedHeight: 96,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor:
              theme.scaffoldBackgroundColor.withValues(alpha: 0.78),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: KeyedSubtree(
                key: _viewModeBtnKey,
                child: _ViewModePill(
                  viewMode: _viewMode,
                  onTap: _pickViewMode,
                ),
              ),
            ),
          ],
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 20,
                  bottom: 14,
                  end: 72,
                ),
                centerTitle: false,
                title: Text(
                  'التأملات والخواطر',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.6),
            child: Container(
              height: 0.6,
              color: theme.colorScheme.onSurface
                  .withValues(alpha: isDark ? 0.08 : 0.06),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSearchBar(theme, isDark, filtered.length),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildFilterBar(theme, isDark, entries),
              ],
              const SizedBox(height: 12),
              if (_searchQuery.isEmpty && _activeFilter == 'الكل') ...[
                ReflectionQuickComposeCard(
                  onCompose: (ctx, color, {initialMood}) => _openNewEditor(
                    sourceContext: ctx,
                    sourceColor: color,
                    sourceRadius: 18,
                    initialMood: initialMood,
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (entries.isEmpty)
                _buildEmptyState(context, theme)
              else if (filtered.isEmpty)
                _buildNoResultsState(theme)
              else ...[
                if (pinned.isNotEmpty) ...[
                  _sectionLabel(context, 'مثبتة', pinned.length),
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 340),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      child: KeyedSubtree(
                        key: ValueKey('pinned_${_viewMode.name}'),
                        child: _buildNotesLayout(pinned),
                      ),
                    ),
                  ),
                  if (others.isNotEmpty) const SizedBox(height: 18),
                ],
                if (others.isNotEmpty) ...[
                  if (pinned.isNotEmpty) ...[
                    _sectionLabel(context, 'أخرى', others.length),
                    const SizedBox(height: 8),
                  ],
                  AnimatedSize(
                    duration: const Duration(milliseconds: 340),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      child: KeyedSubtree(
                        key: ValueKey('others_${_viewMode.name}'),
                        child: _buildNotesLayout(others),
                      ),
                    ),
                  ),
                ],
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark, int matchCount) {
    final fillColor = isDark
        ? const Color(0xFF152036)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'ابحث في الخواطر، العناوين، المشاريع، أو الصلاة…',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value.trim()),
        ),
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 6),
            child: Text(
              'نتائج البحث: $matchCount',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterBar(
    ThemeData theme,
    bool isDark,
    List<ReflectionEntry> entries,
  ) {
    final usedMoods = <String>{};
    for (final e in entries) {
      usedMoods.addAll(e.moods);
    }
    final hasPinned = entries.any((e) => e.isPinned);
    final options = <String>[
      'الكل',
      if (hasPinned) 'مثبتة',
      ...usedMoods,
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final label = options[index];
          final selected = _activeFilter == label;
          final mood = AppMoods.find(label);
          final accent = mood?.color ?? theme.colorScheme.primary;

          return GestureDetector(
            onTap: () {
              if (selected) return;
              HapticFeedback.selectionClick();
              setState(() => _activeFilter = label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: isDark ? 0.24 : 0.14)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? accent.withValues(alpha: 0.45)
                      : Colors.transparent,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mood != null) ...[
                    Icon(mood.icon, size: 14, color: accent),
                    const SizedBox(width: 5),
                  ] else if (label == 'مثبتة') ...[
                    Icon(
                      Icons.push_pin_rounded,
                      size: 13,
                      color: selected
                          ? accent
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? accent
                          : theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesLayout(List<ReflectionEntry> items) {
    if (_viewMode == ReflectionViewMode.timeline) {
      return ReflectionTimelineView(
        entries: items,
        onTap: (entry, ctx, bg) => _openEditEditor(entry, ctx, bg),
        onTogglePin: (entry) =>
            ref.read(reflectionsProvider.notifier).togglePin(entry),
        onDelete: _handleDelete,
      );
    }

    if (_viewMode == ReflectionViewMode.compact) {
      return ReflectionCompactView(
        entries: items,
        onTap: (entry, ctx, bg) => _openEditEditor(entry, ctx, bg),
        onTogglePin: (entry) =>
            ref.read(reflectionsProvider.notifier).togglePin(entry),
        onDelete: _handleDelete,
      );
    }

    if (_viewMode == ReflectionViewMode.list) {
      return Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StaggeredReflectionItem(
                index: i,
                child: ReflectionEntryCard(
                  entry: items[i],
                  isGrid: false,
                  onTap: (ctx, bg) => _openEditEditor(items[i], ctx, bg),
                  onTogglePin: () => ref
                      .read(reflectionsProvider.notifier)
                      .togglePin(items[i]),
                  onDelete: () => _handleDelete(items[i]),
                ),
              ),
            ),
        ],
      );
    }

    final rightCol = <({int index, ReflectionEntry entry})>[];
    final leftCol = <({int index, ReflectionEntry entry})>[];
    for (var i = 0; i < items.length; i++) {
      if (i.isEven) {
        rightCol.add((index: i, entry: items[i]));
      } else {
        leftCol.add((index: i, entry: items[i]));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (final item in rightCol)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StaggeredReflectionItem(
                    index: item.index,
                    child: ReflectionEntryCard(
                      entry: item.entry,
                      isGrid: true,
                      onTap: (ctx, bg) => _openEditEditor(item.entry, ctx, bg),
                      onTogglePin: () => ref
                          .read(reflectionsProvider.notifier)
                          .togglePin(item.entry),
                      onDelete: () => _handleDelete(item.entry),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              for (final item in leftCol)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StaggeredReflectionItem(
                    index: item.index,
                    child: ReflectionEntryCard(
                      entry: item.entry,
                      isGrid: true,
                      onTap: (ctx, bg) => _openEditEditor(item.entry, ctx, bg),
                      onTogglePin: () => ref
                          .read(reflectionsProvider.notifier)
                          .togglePin(item.entry),
                      onDelete: () => _handleDelete(item.entry),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String label, int count) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            'لا توجد نتائج مطابقة للبحث.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            child: const Text('مسح البحث'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              size: 34,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'اضغط على «دوّن خاطرة» بالأعلى لتبدأ',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'مساحة هادئة لخواطرك وتأملاتك اليومية حول الصلوات.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModePill extends StatelessWidget {
  const _ViewModePill({
    required this.viewMode,
    required this.onTap,
  });

  final ReflectionViewMode viewMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return PressableScale(
      onTap: onTap,
      child: Material(
        color: isDark
            ? const Color(0xFF152036)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: Tween(begin: 0.85, end: 1.0).animate(anim),
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Icon(
                    viewMode.icon,
                    key: ValueKey(viewMode),
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 5),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    viewMode.label,
                    key: ValueKey(viewMode.label),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
