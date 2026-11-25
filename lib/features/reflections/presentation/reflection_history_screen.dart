import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/ui/error_view.dart';
import '../../../core/ui_feedback.dart';
import '../domain/reflection_entry.dart';
import '../domain/reflection_search.dart';
import 'reflection_editor_screen.dart';
import 'widgets/reflection_dialogs.dart';
import 'widgets/reflection_entry_card.dart';
import 'widgets/reflection_quick_compose_card.dart';

class ReflectionHistoryScreen extends ConsumerStatefulWidget {
  const ReflectionHistoryScreen({super.key});

  @override
  ConsumerState<ReflectionHistoryScreen> createState() =>
      _ReflectionHistoryScreenState();
}

class _ReflectionHistoryScreenState
    extends ConsumerState<ReflectionHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = true;

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

  Future<void> _handleDelete(String id) async {
    final confirmed = await ReflectionDialogs.confirmDelete(context);
    if (!confirmed || !mounted) return;
    await ref.read(reflectionsProvider.notifier).delete(id);
    lightSuccessHaptic();
    if (mounted) {
      appSnack(context, 'تم حذف الخاطرة.');
    }
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
    final filtered = _searchQuery.isEmpty
        ? entries
        : entries
            .where((e) => ReflectionSearch.matches(e, _searchQuery))
            .toList();

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
          backgroundColor: theme.scaffoldBackgroundColor,
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: _ViewModePill(
                isGridView: _isGridView,
                onToggle: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isGridView = !_isGridView);
                },
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
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
              const SizedBox(height: 12),
              if (_searchQuery.isEmpty) ...[
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey('pinned_$_isGridView'),
                      child: _buildNotesLayout(pinned),
                    ),
                  ),
                  if (others.isNotEmpty) const SizedBox(height: 18),
                ],
                if (others.isNotEmpty) ...[
                  if (pinned.isNotEmpty) ...[
                    _sectionLabel(context, 'أخرى', others.length),
                    const SizedBox(height: 8),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey('others_$_isGridView'),
                      child: _buildNotesLayout(others),
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

  Widget _buildNotesLayout(List<ReflectionEntry> items) {
    if (!_isGridView) {
      return Column(
        children: [
          for (final entry in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReflectionEntryCard(
                entry: entry,
                isGrid: false,
                onTap: (ctx, bg) => _openEditEditor(entry, ctx, bg),
                onTogglePin: () =>
                    ref.read(reflectionsProvider.notifier).togglePin(entry),
                onDelete: () => _handleDelete(entry.id),
              ),
            ),
        ],
      );
    }

    final rightCol = <ReflectionEntry>[];
    final leftCol = <ReflectionEntry>[];
    for (var i = 0; i < items.length; i++) {
      if (i.isEven) {
        rightCol.add(items[i]);
      } else {
        leftCol.add(items[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (final entry in rightCol)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReflectionEntryCard(
                    entry: entry,
                    isGrid: true,
                    onTap: (ctx, bg) => _openEditEditor(entry, ctx, bg),
                    onTogglePin: () =>
                        ref.read(reflectionsProvider.notifier).togglePin(entry),
                    onDelete: () => _handleDelete(entry.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              for (final entry in leftCol)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReflectionEntryCard(
                    entry: entry,
                    isGrid: true,
                    onTap: (ctx, bg) => _openEditEditor(entry, ctx, bg),
                    onTogglePin: () =>
                        ref.read(reflectionsProvider.notifier).togglePin(entry),
                    onDelete: () => _handleDelete(entry.id),
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
    required this.isGridView,
    required this.onToggle,
  });

  final bool isGridView;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark
          ? const Color(0xFF152036)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              key: ValueKey(isGridView),
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
