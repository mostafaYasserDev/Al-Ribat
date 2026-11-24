import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

part 'about_app_legal_sections.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عن التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.mosque, size: 80, color: Colors.teal),
          const SizedBox(height: 16),
          Text(
            'تطبيق الرباط',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'تطبيقك الشامل لتنظيم الحياة حول الصلوات.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text('فكرة التطبيق', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'يهدف تطبيق الرباط إلى مساعدة المسلم على تنظيم وقته ومهامه اليومية بناءً على أوقات الصلاة، بدلاً من الاعتماد على ساعات اليوم التقليدية. مما يعزز البركة في الوقت والإنتاجية.',
          ),
          const SizedBox(height: 24),
          Text('المميزات الأساسية',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
              '• إدارة الأنشطة وربطها بالصلوات\n• أوقات الصلاة الدقيقة وتنبيهات مخصصة\n• إحصائيات ذكية لمتابعة الأداء\n• متتبع الحالات المزاجية والتأملات'),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('الشكاوى والاقتراحات'),
            subtitle: const Text('يفتح نموذج خارجي (Google Forms)'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final uri = Uri.parse('https://forms.gle/HSGemvnVdrfsNxWM8');
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('شروط الاستخدام'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TermsOfUseScreen()));
            },
          ),
        ],
      ),
    );
  }
}
