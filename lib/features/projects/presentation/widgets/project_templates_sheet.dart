import 'package:flutter/material.dart';

class ProjectStarterTemplate {
  final String title;
  final String description;
  final String colorHex;
  final String iconName;
  final Map<String, List<String>> groups;

  const ProjectStarterTemplate({
    required this.title,
    required this.description,
    required this.colorHex,
    required this.iconName,
    required this.groups,
  });

  static const List<ProjectStarterTemplate> templates = [
    ProjectStarterTemplate(
      title: 'ختمة وتدبر القرآن',
      description: 'محطات إنجاز لحفظ ومراجعة وتدبر أجزاء من القرآن',
      colorHex: '#2E7D32',
      iconName: 'menu_book',
      groups: {
        'الحفظ والمراجعة': [
          'حفظ أول 5 أجزاء',
          'مراجعة وتثبيت الجزء السادس',
          'تسميع ربع حزب يومياً',
        ],
        'التفسير والتدبر': [
          'قراءة تفسير سورة النور',
          'تدوين فوائد وتأملات سورة الكهف',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'بناء وتطوير تطبيق',
      description: 'مراحل بناء التطبيق من الجانب التقني والتصميم والتسويق',
      colorHex: '#3F51B5',
      iconName: 'code',
      groups: {
        'الجانب التقني': [
          'تحديد متطلبات وهيكل البيانات',
          'بناء شاشات واجهة المستخدم',
          'ربط خوارزميات العمل وقاعدة البيانات',
        ],
        'التصميم والتسويق': [
          'تصميم هوية التطبيق والأيقونة',
          'إعداد فيديو وخطة الإطلاق',
        ],
      },
    ),
    ProjectStarterTemplate(
      title: 'مشروع القراءة والثقافة',
      description: 'محطات إنجاز لقراءة كتب نافعة وتلخيص الفوائد',
      colorHex: '#E65100',
      iconName: 'auto_stories',
      groups: {
        'قراءة الكتب': [
          'إنهاء كتاب في السيرة النبوية',
          'إنهاء كتاب في تطوير الذات وإدارة الوقت',
        ],
        'التلخيص والتطبيق': [
          'تلخيص أهم 10 مبادئ من الكتاب',
          'تطبيق أسبوعي لعادة مستفادة',
        ],
      },
    ),
  ];
}

class ProjectTemplatesSheet extends StatelessWidget {
  const ProjectTemplatesSheet({super.key, required this.onSelect});
  final ValueChanged<ProjectStarterTemplate> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: sheetBg,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: Text(
                  'قوالب مشاريع ملهمة',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Divider(
                height: 0.6,
                thickness: 0.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              for (var i = 0;
                  i < ProjectStarterTemplate.templates.length;
                  i++) ...[
                () {
                  final t = ProjectStarterTemplate.templates[i];
                  final color = Color(int.parse(
                      'FF${t.colorHex.replaceAll('#', '')}',
                      radix: 16));
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(t);
                    },
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.folder_special_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      t.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      t.description,
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  );
                }(),
                if (i < ProjectStarterTemplate.templates.length - 1)
                  Divider(
                    height: 0.6,
                    thickness: 0.6,
                    indent: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                  ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
