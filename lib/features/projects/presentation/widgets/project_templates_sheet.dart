import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/features/reflections/presentation/widgets/apple_morph_route.dart';

enum ProjectTemplateCategory {
  all('الكل', Icons.apps_rounded),
  faithAndKnowledge('إيماني وعلمي', Icons.mosque_rounded),
  techAndWork('تقني ومهني', Icons.work_outline_rounded),
  lifeAndWellness('حياة وعافية', Icons.spa_rounded);

  const ProjectTemplateCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ProjectTemplateSelection {
  const ProjectTemplateSelection({
    required this.title,
    required this.description,
    required this.colorHex,
    required this.iconName,
    required this.groups,
  });

  final String title;
  final String description;
  final String colorHex;
  final String iconName;
  final Map<String, List<String>> groups;
}

class ProjectStarterTemplate {
  final String title;
  final String description;
  final String colorHex;
  final String iconName;
  final ProjectTemplateCategory category;
  final Map<String, List<String>> groups;

  const ProjectStarterTemplate({
    required this.title,
    required this.description,
    required this.colorHex,
    required this.iconName,
    required this.category,
    required this.groups,
  });

  int get totalTasksCount =>
      groups.values.fold<int>(0, (sum, items) => sum + items.length);

  static const List<ProjectStarterTemplate> templates = [
    ProjectStarterTemplate(
      title: 'ختمة وتدبر القرآن',
      description: 'محطات إنجاز لحفظ ومراجعة وتدبر أجزاء من القرآن الكريم',
      colorHex: '#2E7D32',
      iconName: 'menu_book',
      category: ProjectTemplateCategory.faithAndKnowledge,
      groups: {
        'الحفظ والمراجعة': [
          'حفظ أول 5 أجزاء بإتقان',
          'مراجعة وتثبيت المحفوظ يومياً',
          'تسميع ربع حزب يومياً',
        ],
        'التفسير والتدبر': [
          'قراءة تفسير السور المقررة',
          'تدوين فوائد وتأملات أسبوعية',
        ],
        'الورد اليومي': [
          'تلاوة جزء يومياً بترتيل',
          'الاستماع لقارئ متقن لتصحيح التلاوة',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'بناء وتطوير تطبيق',
      description: 'مراحل بناء التطبيق من التخطيط والتصميم حتى الإطلاق',
      colorHex: '#3F51B5',
      iconName: 'code',
      category: ProjectTemplateCategory.techAndWork,
      groups: {
        'التخطيط والهيكلة': [
          'تحديد المتطلبات وهيكل البيانات',
          'تقسيم المهام إلى إصدارات مرحلية',
        ],
        'التصميم وتجربة المستخدم': [
          'تصميم هوية التطبيق والأيقونة',
          'رسم مسارات الشاشات الأساسية',
        ],
        'التطوير والاختبار': [
          'بناء شاشات واجهة المستخدم',
          'ربط المنطق البرمجي وقاعدة البيانات',
          'كتابة الاختبارات ومعالجة الأخطاء',
        ],
        'الإطلاق والتسويق': [
          'تجهيز لقطات الشاشة ووصف المتجر',
          'نشر النسخة الأولى وجمع الملاحظات',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'مشروع القراءة والثقافة',
      description: 'خطة عملية لقراءة كتب نافعة وتلخيصها وتطبيق فوائدها',
      colorHex: '#E65100',
      iconName: 'auto_stories',
      category: ProjectTemplateCategory.faithAndKnowledge,
      groups: {
        'قائمة الكتب': [
          'اختيار 3 كتب في السيرة والفكر والإدارة',
          'تحديد ورد قراءة 15 صفحة يومياً',
        ],
        'القراءة والتلخيص': [
          'تلخيص أهم 10 أفكار من كل كتاب',
          'حفظ الاقتباسات المميزة في التأملات',
        ],
        'التطبيق العملي': [
          'تطبيق عادة واحدة مستفادة كل أسبوع',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'إتقان لغة جديدة',
      description: 'مسار متوازن للمفردات والاستماع والقواعد والمحادثة',
      colorHex: '#00897B',
      iconName: 'translate',
      category: ProjectTemplateCategory.faithAndKnowledge,
      groups: {
        'المفردات والاستماع': [
          'حفظ 15 كلمة جديدة يومياً مع السياق',
          'الاستماع لبودكاست تعليمي 20 دقيقة',
        ],
        'القواعد والممارسة': [
          'إتمام درس قواعد وتطبيق أمثلته',
          'كتابة فقرة قصيرة يومياً باللغة',
        ],
        'المحادثة والقراءة': [
          'قراءة مقال مبسط أسبوعياً',
          'ممارسة التحدث بصوت مرتفع 10 دقائق',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'إطلاق متجر أو مشروع تجاري',
      description: 'خطوات تأسيس مشروع تجاري من دراسة السوق حتى أول مبيعات',
      colorHex: '#7C3AED',
      iconName: 'work',
      category: ProjectTemplateCategory.techAndWork,
      groups: {
        'دراسة السوق والمنتج': [
          'تحديد الفئة المستهدفة والمشكلة',
          'اختيار الموردين وتسعير المنتجات',
        ],
        'الهوية والتجهيز': [
          'تصميم الشعار وتجهيز المتجر الإلكتروني',
          'إعداد طرق الدفع والشحن',
        ],
        'التسويق والمبيعات': [
          'خطة المحتوى والإطلاق الأول',
          'متابعة أول 10 عملاء وتحسين التجربة',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'الاستعداد لموسم طاعة / رمضان',
      description: 'خطة شاملة لتهيئة القلب والقرآن والقيام والصدقات',
      colorHex: '#10B981',
      iconName: 'mosque',
      category: ProjectTemplateCategory.faithAndKnowledge,
      groups: {
        'تهيئة القلب والورد': [
          'تحديد عدد الختمات المستهدفة',
          'ترتيب أذكار الصباح والمساء والسنن',
        ],
        'الصيام والقيام': [
          'صيام الإثنين والخميس للتهيئة',
          'تخصيص ورد ثابت لقيام الليل',
        ],
        'الصدقة والأسرة': [
          'تخصيص ميزانية الصدقات وإفطار الصائمين',
          'جلسة أسرية أسبوعية للتدبر',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'رحلة اللياقة وبناء الجسم',
      description: 'برنامج متكامل للتمارين والتغذية والنوم الصحي',
      colorHex: '#EF4444',
      iconName: 'fitness_center',
      category: ProjectTemplateCategory.lifeAndWellness,
      groups: {
        'خطة التمارين': [
          'أداء 4 حصص تمرين أسبوعياً',
          'تحقيق 8000 خطوة يومياً',
        ],
        'التغذية والماء': [
          'شرب 8 أكواب ماء يومياً',
          'تجهيز وجبات متوازنة وتقليل السكر',
        ],
        'النوم والاستشفاء': [
          'النوم 7 ساعات مبكراً يومياً',
          'تمارين إطالة 10 دقائق بعد التمرين',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'التفوق الدراسي واجتياز اختبار',
      description: 'تنظيم المصادر وجدول المذاكرة وحل النماذج بتركيز',
      colorHex: '#0EA5E9',
      iconName: 'school',
      category: ProjectTemplateCategory.faithAndKnowledge,
      groups: {
        'تجميع المصادر': [
          'حصر المنهج والملخصات المعتمدة',
          'تحديد نقاط القوة والضعف في المواد',
        ],
        'جدول المذاكرة': [
          'جلسات تركيز 45 دقيقة يومياً',
          'تلخيص كل فصل بخريطة ذهنية',
        ],
        'المراجعة والنماذج': [
          'حل 3 نماذج اختبارات سابقة',
          'مراجعة الأخطاء الشائعة قبل الاختبار',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'تنظيم الشؤون المالية والادخار',
      description: 'ضبط الميزانية وسداد الالتزامات وبناء صندوق الطوارئ',
      colorHex: '#059669',
      iconName: 'savings',
      category: ProjectTemplateCategory.lifeAndWellness,
      groups: {
        'حصر الالتزامات': [
          'تسجيل الدخل والمصروفات الثابتة',
          'إلغاء الاشتراكات غير الضرورية',
        ],
        'الميزانية والادخار': [
          'تخصيص نسبة ادخار شهرية ثابتة',
          'بناء صندوق طوارئ يكفي 3 أشهر',
        ],
        'الصدقة وتنمية الدخل': [
          'تخصيص صدقة شهرية منتظمة',
          'تطوير مصدر دخل إضافي أو مهارة',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'ترتيب وتجديد المنزل',
      description: 'خطة عملية للفرز والتخلص من الزوائد وتنظيم الغرف',
      colorHex: '#8B5CF6',
      iconName: 'cottage',
      category: ProjectTemplateCategory.lifeAndWellness,
      groups: {
        'الفرز والتخفيف': [
          'فرز الملابس والتبرع بما لا يُستخدم',
          'التخلص من الأوراق والأدوات التالفة',
        ],
        'التنظيم والتخزين': [
          'ترتيب المكتب ومكان العمل والدراسة',
          'تنظيم الخزائن والمطبخ بصناديق واضحة',
        ],
        'الصيانة والتحسين': [
          'إصلاح الأعطال البسيطة في المنزل',
          'إضافة لمسة جمالية وإضاءة مريحة',
        ],
      },
    ),
  ];
}

class ProjectTemplatesSheet extends StatefulWidget {
  const ProjectTemplatesSheet({super.key, required this.onSelect});
  final ValueChanged<ProjectTemplateSelection> onSelect;

  /// Opens [ProjectTemplatesSheet] with an Apple spatial morph from [sourceContext].
  static Future<void> open(
    BuildContext context, {
    required ValueChanged<ProjectTemplateSelection> onSelect,
    BuildContext? sourceContext,
    Color? sourceColor,
    double sourceRadius = 12,
  }) {
    final sourceRect = captureWidgetRect(sourceContext);
    return Navigator.of(context).push<void>(
      AppleMorphRoute<void>(
        sourceRect: sourceRect,
        sourceColor: sourceColor,
        sourceRadius: sourceRadius,
        builder: (_) => ProjectTemplatesSheet(onSelect: onSelect),
      ),
    );
  }

  @override
  State<ProjectTemplatesSheet> createState() => _ProjectTemplatesSheetState();
}

class _ProjectTemplatesSheetState extends State<ProjectTemplatesSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  ProjectTemplateCategory _selectedCategory = ProjectTemplateCategory.all;
  int? _expandedIndex;
  bool _includeGroupsAndTasks = true;
  Map<String, Set<String>> _selectedTasksByGroup = {};

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  List<ProjectStarterTemplate> get _filteredTemplates {
    final query = _searchController.text.trim().toLowerCase();
    return ProjectStarterTemplate.templates.where((t) {
      if (_selectedCategory != ProjectTemplateCategory.all &&
          t.category != _selectedCategory) {
        return false;
      }
      if (query.isEmpty) return true;
      final inTitle = t.title.toLowerCase().contains(query);
      final inDesc = t.description.toLowerCase().contains(query);
      final inGroups = t.groups.entries.any((e) =>
          e.key.toLowerCase().contains(query) ||
          e.value.any((task) => task.toLowerCase().contains(query)));
      return inTitle || inDesc || inGroups;
    }).toList();
  }

  void _toggleExpand(int index, ProjectStarterTemplate template) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
        _titleController.text = template.title;
        _includeGroupsAndTasks = true;
        _selectedTasksByGroup = {
          for (final entry in template.groups.entries)
            entry.key: Set<String>.from(entry.value),
        };
      }
    });
  }

  void _submitTemplate(ProjectStarterTemplate template) {
    final title = _titleController.text.trim().isEmpty
        ? template.title
        : _titleController.text.trim();
    final Map<String, List<String>> finalGroups;
    if (!_includeGroupsAndTasks) {
      finalGroups = const {};
    } else {
      finalGroups = <String, List<String>>{};
      for (final entry in template.groups.entries) {
        final kept = entry.value
            .where((task) =>
                _selectedTasksByGroup[entry.key]?.contains(task) ?? false)
            .toList();
        if (kept.isNotEmpty) {
          finalGroups[entry.key] = kept;
        }
      }
    }

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    widget.onSelect(
      ProjectTemplateSelection(
        title: title,
        description: template.description,
        colorHex: template.colorHex,
        iconName: template.iconName,
        groups: finalGroups,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final templates = _filteredTemplates;

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
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.7),
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
                            'قوالب مشاريع ملهمة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'اختر قالباً، عاين محطاته، أو أنشئه فارغاً أو معدّلاً',
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

              // Search Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() => _expandedIndex = null),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مشروع: قرآن، تطبيق، لغة، مالية...',
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
                              setState(() => _expandedIndex = null);
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

              // Category Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ProjectTemplateCategory.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = ProjectTemplateCategory.values[idx];
                    final selected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCategory = cat;
                          _expandedIndex = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? Colors.white
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
              const SizedBox(height: 8),
              const Divider(height: 1),

              // Templates List
              Expanded(
                child: templates.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد قوالب مشاريع مطابقة',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        itemCount: templates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final t = templates[index];
                          final color = AppIcons.parseColor(t.colorHex) ??
                              colorScheme.primary;
                          final isExpanded = _expandedIndex == index;
                          final cardBg = theme.cardTheme.color ??
                              (isDark ? const Color(0xFF111B2E) : Colors.white);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isExpanded
                                    ? color.withValues(alpha: 0.5)
                                    : colorScheme.onSurface.withValues(
                                        alpha: isDark ? 0.08 : 0.07),
                                width: isExpanded ? 1.2 : 0.8,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.025),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _toggleExpand(index, t),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color:
                                                color.withValues(alpha: 0.14),
                                            borderRadius:
                                                BorderRadius.circular(13),
                                          ),
                                          child: Icon(
                                            AppIcons.getIconData(t.iconName),
                                            color: color,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.title,
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                t.description,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.62),
                                                ),
                                                maxLines: isExpanded ? 3 : 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  _TemplateStatPill(
                                                    label:
                                                        '${t.groups.length} مجموعات',
                                                    color: color,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  _TemplateStatPill(
                                                    label:
                                                        '${t.totalTasksCount} مهام',
                                                    color: colorScheme.primary,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                  .keyboard_arrow_down_rounded,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: isExpanded
                                      ? _buildExpandedEditor(
                                          theme,
                                          colorScheme,
                                          t,
                                          color,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
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

  Widget _buildExpandedEditor(
    ThemeData theme,
    ColorScheme colorScheme,
    ProjectStarterTemplate t,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 1,
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'اسم المشروع (قابل للتعديل)',
              isDense: true,
              filled: true,
              fillColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'تضمين المجموعات والمهام الجاهزة',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _includeGroupsAndTasks
                    ? 'يمكنك إلغاء تحديد أي مهمة أو مجموعة لا تحتاجها'
                    : 'سيُنشأ المشروع فارغاً بالاسم والأيقونة واللون فقط',
                style: const TextStyle(fontSize: 11.5),
              ),
              value: _includeGroupsAndTasks,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _includeGroupsAndTasks = v);
              },
            ),
          ),
          if (_includeGroupsAndTasks) ...[
            const SizedBox(height: 6),
            for (final entry in t.groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.value.map((task) {
                  final selected =
                      _selectedTasksByGroup[entry.key]?.contains(task) ?? false;
                  return FilterChip(
                    selected: selected,
                    label: Text(
                      task,
                      style: TextStyle(
                        fontSize: 11.5,
                        decoration:
                            selected ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    onSelected: (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        final set = _selectedTasksByGroup.putIfAbsent(
                            entry.key, () => <String>{});
                        if (val) {
                          set.add(task);
                        } else {
                          set.remove(task);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const StadiumBorder(),
            ),
            onPressed: () => _submitTemplate(t),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: Text(
              _includeGroupsAndTasks
                  ? 'إنشاء المشروع بالمحدد'
                  : 'إنشاء مشروع فارغ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateStatPill extends StatelessWidget {
  const _TemplateStatPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
