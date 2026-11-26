part of '../templates_sheet.dart';

enum _TemplateFilter {
  all('الكل', Icons.apps_rounded),
  afterPrayer('مرتبط بالصلاة', Icons.mosque_rounded),
  measurable('بهدف كمي', Icons.track_changes_rounded),
  periodic('أسبوعي وشهري', Icons.event_repeat_rounded);

  const _TemplateFilter(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _TemplatesSheetState extends State<TemplatesSheet> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  _TemplateFilter _activeFilter = _TemplateFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'العبادات والأذكار':
        return Icons.mosque_rounded;
      case 'تطوير الذات':
        return Icons.auto_stories_rounded;
      case 'الهدوء الرقمي والنوم':
        return Icons.bedtime_rounded;
      case 'الصحة والرياضة':
        return Icons.fitness_center_rounded;
      case 'المال والصدقة':
        return Icons.volunteer_activism_rounded;
      case 'حمية غذائية ونظام غذائي':
        return Icons.restaurant_rounded;
      case 'العلاقات':
        return Icons.diversity_1_rounded;
      case 'العناية بالصحة والجسد':
        return Icons.spa_rounded;
      case 'ترك عادات سيئة':
        return Icons.do_not_disturb_on_rounded;
      case 'المنزل':
        return Icons.cottage_rounded;
      case 'نمط حياة':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String name) {
    switch (name) {
      case 'العبادات والأذكار':
        return const Color(0xFF10B981);
      case 'تطوير الذات':
        return const Color(0xFF6366F1);
      case 'الهدوء الرقمي والنوم':
        return const Color(0xFF4F46E5);
      case 'الصحة والرياضة':
        return const Color(0xFFF59E0B);
      case 'المال والصدقة':
        return const Color(0xFF059669);
      case 'حمية غذائية ونظام غذائي':
        return const Color(0xFF84CC16);
      case 'العلاقات':
        return const Color(0xFFEC4899);
      case 'العناية بالصحة والجسد':
        return const Color(0xFF06B6D4);
      case 'ترك عادات سيئة':
        return const Color(0xFFEF4444);
      case 'المنزل':
        return const Color(0xFF8B5CF6);
      case 'نمط حياة':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF64748B);
    }
  }

  bool _matchesFilter(ActivityTemplate t) {
    switch (_activeFilter) {
      case _TemplateFilter.all:
        return true;
      case _TemplateFilter.afterPrayer:
        return t.linkedPrayer != null;
      case _TemplateFilter.measurable:
        return t.isMeasurable;
      case _TemplateFilter.periodic:
        return t.repetition == ActivityRepetition.weekly ||
            t.repetition == ActivityRepetition.monthly;
    }
  }

  List<ActivityTemplate> _getFilteredTemplates() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      final results = <ActivityTemplate>[];
      for (final cat in TemplatesSheet._categories) {
        final catName = (cat['name'] as String).toLowerCase();
        final list = cat['templates'] as List<ActivityTemplate>;
        for (final t in list) {
          final matchTitle = t.title.toLowerCase().contains(query);
          final matchDesc =
              t.description?.toLowerCase().contains(query) ?? false;
          final matchCat = catName.contains(query);
          if ((matchTitle || matchDesc || matchCat) && _matchesFilter(t)) {
            results.add(t);
          }
        }
      }
      return results;
    }

    if (_activeFilter != _TemplateFilter.all) {
      final category = TemplatesSheet._categories[_selectedCategoryIndex];
      final list = category['templates'] as List<ActivityTemplate>;
      final inCat = list.where(_matchesFilter).toList();
      if (inCat.isNotEmpty) return inCat;
      // Fallback across all categories if current category has none for this filter
      return [
        for (final cat in TemplatesSheet._categories)
          ...(cat['templates'] as List<ActivityTemplate>).where(_matchesFilter),
      ];
    }

    final category = TemplatesSheet._categories[_selectedCategoryIndex];
    return category['templates'] as List<ActivityTemplate>;
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryBadge(ActivityTemplate t, ColorScheme colorScheme) {
    if (t.linkedPrayer != null) {
      return _buildBadge(
        'بعد ${t.linkedPrayer!.arabicName}',
        Icons.mosque_rounded,
        colorScheme.primary,
      );
    }
    if (t.repetition == ActivityRepetition.weekly) {
      return _buildBadge(
        'أسبوعي',
        Icons.event_repeat_rounded,
        const Color(0xFF8B5CF6),
      );
    }
    if (t.repetition == ActivityRepetition.monthly) {
      return _buildBadge(
        'شهري',
        Icons.calendar_month_rounded,
        const Color(0xFF0EA5E9),
      );
    }
    if (t.isMeasurable && t.targetGoal != null) {
      return _buildBadge(
        '${t.targetGoal!.toInt()} ${t.goalUnit ?? ''}',
        Icons.track_changes_rounded,
        Colors.amber.shade700,
      );
    }
    return _buildBadge(
      'مهمة حرة',
      Icons.star_outline_rounded,
      colorScheme.secondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isSearching = _searchController.text.trim().isNotEmpty;
    final templates = _getFilteredTemplates();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'قوالب الأنشطة الجاهزة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'اختر قالباً لبدء رحلتك بسهولة أو عدّل عليه',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن ورد، سنة، عمل عميق، صدقة، نوم...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Smart Filter Pills
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _TemplateFilter.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (context, idx) {
                    final filter = _TemplateFilter.values[idx];
                    final selected = _activeFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _activeFilter = filter);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? colorScheme.primary.withValues(alpha: 0.14)
                              : colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? colorScheme.primary.withValues(alpha: 0.45)
                                : Colors.transparent,
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              filter.icon,
                              size: 14,
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              filter.label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Horizontal Category Chips (when not searching)
              if (!isSearching)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: List.generate(
                        TemplatesSheet._categories.length,
                        (index) {
                          final cat = TemplatesSheet._categories[index];
                          final name = cat['name'] as String;
                          final list =
                              cat['templates'] as List<ActivityTemplate>;
                          final isSelected = _selectedCategoryIndex == index;
                          final catColor = _getCategoryColor(name);

                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedCategoryIndex = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getCategoryIcon(name),
                                      size: 16,
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : catColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                                .withValues(alpha: 0.25)
                                            : colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${list.length}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              const Divider(height: 1),

              // Templates Grid
              Expanded(
                child: templates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'لا توجد قوالب مطابقة للبحث',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 162,
                        ),
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final t = templates[index];
                          final iconColor = _getColor(t.colorHex);
                          final cardBg = theme.cardTheme.color ??
                              (isDark ? const Color(0xFF111B2E) : Colors.white);

                          return Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: colorScheme.onSurface
                                    .withValues(alpha: isDark ? 0.08 : 0.07),
                                width: 0.8,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.025),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                            ),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context, t);
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color:
                                            iconColor.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getIcon(t.iconName),
                                        color: iconColor,
                                        size: 20,
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          t.title,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (t.description != null &&
                                            t.description!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            t.description!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.56),
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                    _buildPrimaryBadge(t, colorScheme),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_rounded,
                                            size: 14,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'إضافة',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
