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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'قوالب مشاريع ملهمة',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...ProjectStarterTemplate.templates.map((t) {
            final color = Color(
                int.parse('FF${t.colorHex.replaceAll('#', '')}', radix: 16));
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                onTap: () {
                  Navigator.pop(context);
                  onSelect(t);
                },
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(Icons.folder_special_rounded,
                      color: color, size: 20),
                ),
                title: Text(t.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text(t.description, style: const TextStyle(fontSize: 11)),
                trailing:
                    const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              ),
            );
          }),
        ],
      ),
    );
  }
}
