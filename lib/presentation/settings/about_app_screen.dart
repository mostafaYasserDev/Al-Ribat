import 'package:flutter/material.dart';

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
              'نحن نؤمن بأن بياناتك الشخصية ملك لك وحدك. جميع البيانات التي تدخلها في التطبيق (كالأنشطة، والحالات المزاجية، والإعدادات) يتم حفظها محلياً على جهازك فقط (Offline). لا توجد خوادم خارجية تخزن أو تعالج هذه البيانات.\n\n'
              '2. الأذونات المطلوبة\n'
              '• الموقع الجغرافي: يُستخدم فقط لحساب أوقات الصلاة بدقة بناءً على موقعك، ولا يتم إرسال موقعك لأي جهة خارجية.\n'
              '• الإشعارات: تُستخدم لتنبيهك بأوقات الصلاة والأنشطة.\n\n'
              '3. طرف ثالث\n'
              'نحن لا نستخدم أي أدوات تتبع (Trackers) أو إعلانات لجمع معلومات عنك. التطبيق يركز بالكامل على توفير بيئة آمنة ومركزة.\n\n'
              '4. التعديلات على سياسة الخصوصية\n'
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
