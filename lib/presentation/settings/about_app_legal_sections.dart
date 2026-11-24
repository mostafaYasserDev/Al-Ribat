part of 'about_app_screen.dart';

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
            Text('سياسة الخصوصية لتطبيق الرباط',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text('1. حماية البيانات المحلية\n'
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
                'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر لإضافة توضيحات أكثر بناءً على الميزات الجديدة، وسيتم إشعارك بذلك.'),
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
            Text('شروط الاستخدام',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text('1. قبول الشروط\n'
                'باستخدامك لتطبيق "الرباط"، فإنك توافق على الالتزام بهذه الشروط.\n\n'
                '2. الاستخدام العادل\n'
                'التطبيق مُصمم للاستخدام الشخصي غير التجاري. نرجو عدم استخدام الهندسة العكسية أو محاولة اختراق أو تعطيل التطبيق.\n\n'
                '3. المسؤولية\n'
                'رغم أننا نسعى دائماً لتوفير أوقات صلاة وتنبيهات دقيقة، إلا أن التطبيق يُقدم "كما هو". لا يتحمل المطورون أي مسؤولية قانونية عن أي تفويت لموعد أو خطأ ناتج عن حساب الأوقات، حيث أن تحديد المواقيت يعتمد على معادلات حسابية قد تختلف قليلاً من دولة لأخرى.\n\n'
                '4. الملكية الفكرية\n'
                'جميع حقوق التصميم والفكرة محفوظة لمطوري تطبيق الرباط.\n\n'
                '5. التواصل والدعم\n'
                'لأي استفسار أو مشكلة، يمكنك استخدام وسائل التواصل المتاحة في صفحة دعم المطور داخل التطبيق.'),
          ],
        ),
      ),
    );
  }
}
