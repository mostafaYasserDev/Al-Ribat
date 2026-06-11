import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
          Text('المميزات الأساسية', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('• إدارة الأنشطة وربطها بالصلوات\n• أوقات الصلاة الدقيقة وتنبيهات مخصصة\n• إحصائيات ذكية لمتابعة الأداء\n• متتبع الحالات المزاجية والتأملات'),
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
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('شروط الاستخدام'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsOfUseScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سياسة الخصوصية')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('سياسة الخصوصية لتطبيق الرباط', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text(
              '1. حماية البيانات المحلية\n'
              'نحن نؤمن بأن بياناتك الشخصية ملك لك وحدك. جميع البيانات التي تدخلها في التطبيق (الأنشطة، الحالات المزاجية، والإعدادات) تُحفظ محليًا على جهازك بشكل افتراضي.\n\n'
              '2. المزامنة السحابية الاختيارية\n'
              'يمكنك اختيار تسجيل الدخول بحساب Google لمزامنة نسخة احتياطية من بياناتك عبر Firebase. هذه الميزة اختيارية بالكامل؛ ويمكنك دائمًا الاعتماد على التصدير اليدوي بصيغة JSON من الإعدادات.\n'
              'عند تفعيل المزامنة، تُرفع بياناتك إلى حسابك الخاص في Firebase ولا يصل إليها مستخدم آخر.\n\n'
              '3. الأذونات المطلوبة\n'
              '• الموقع الجغرافي: يُستخدم فقط لحساب أوقات الصلاة بدقة بناءً على موقعك.\n'
              '• الإشعارات: تُستخدم لتنبيهك بأوقات الصلاة والأنشطة.\n\n'
              '4. طرف ثالث\n'
              'نستخدم Firebase (Google) فقط عند اختيارك للمزامنة السحابية. لا نستخدم أدوات تتبع أو إعلانات.\n\n'
              '5. التعديلات على سياسة الخصوصية\n'
              'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر لإضافة توضيحات أكثر بناءً على الميزات الجديدة، وسيتم إشعارك بذلك.'
            ),
          ],
        ),
      ),
    );
  }
}

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('شروط الاستخدام')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('شروط الاستخدام', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text(
              '1. قبول الشروط\n'
              'باستخدامك لتطبيق "الرباط"، فإنك توافق على الالتزام بهذه الشروط.\n\n'
              '2. الاستخدام العادل\n'
              'التطبيق مُصمم للاستخدام الشخصي غير التجاري. نرجو عدم استخدام الهندسة العكسية أو محاولة اختراق أو تعطيل التطبيق.\n\n'
              '3. المسؤولية\n'
              'رغم أننا نسعى دائماً لتوفير أوقات صلاة وتنبيهات دقيقة، إلا أن التطبيق يُقدم "كما هو". لا يتحمل المطورون أي مسؤولية قانونية عن أي تفويت لموعد أو خطأ ناتج عن حساب الأوقات، حيث أن تحديد المواقيت يعتمد على معادلات حسابية قد تختلف قليلاً من دولة لأخرى.\n\n'
              '4. الملكية الفكرية\n'
              'جميع حقوق التصميم والفكرة محفوظة لمطوري تطبيق الرباط.\n\n'
              '5. التواصل والدعم\n'
              'لأي استفسار أو مشكلة، يمكنك استخدام وسائل التواصل المتاحة في صفحة دعم المطور داخل التطبيق.'
            ),
          ],
        ),
      ),
    );
  }
}
