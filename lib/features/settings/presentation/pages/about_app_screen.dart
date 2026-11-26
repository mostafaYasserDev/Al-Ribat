import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/ui_feedback.dart';
import '../widgets/settings_ui_components.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const _appVersion = '0.1.0';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const FrostedSettingsSliverAppBar(title: 'عن التطبيق'),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.22),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'تطبيق الرباط',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تطبيقك الشامل لتنظيم الحياة حول الصلوات',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: SettingsStatusPill(
                      label: 'الإصدار $_appVersion',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SettingsSectionHeader(title: 'فكرة التطبيق'),
                  SettingsGroupCard(
                    dividerIndent: 16,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'يهدف تطبيق الرباط إلى مساعدة المسلم على تنظيم وقته ومهامه اليومية بناءً على أوقات الصلاة، بدلاً من الاعتماد على ساعات اليوم التقليدية، مما يعزز البركة في الوقت والإنتاجية.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.55,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '• إدارة الأنشطة وربطها بالصلوات\n'
                          '• أوقات الصلاة الدقيقة وتنبيهات مخصصة\n'
                          '• جلسات تركيز وإحصائيات ذكية\n'
                          '• متتبع الحالات المزاجية والتأملات',
                          style: TextStyle(height: 1.65),
                        ),
                      ),
                    ],
                  ),
                  const SettingsSectionHeader(title: 'الدعم والسياسات'),
                  SettingsGroupCard(
                    children: [
                      SettingsNavTile(
                        icon: Icons.feedback_outlined,
                        iconColor: const Color(0xFF007AFF),
                        title: 'الشكاوى والاقتراحات',
                        subtitle: 'يفتح نموذج خارجي (Google Forms)',
                        onTap: () async {
                          final uri =
                              Uri.parse('https://forms.gle/HSGemvnVdrfsNxWM8');
                          try {
                            final launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (!launched && context.mounted) {
                              appSnack(
                                context,
                                'تعذر فتح نموذج الملاحظات على هذا الجهاز.',
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              appSnack(
                                context,
                                'تعذر فتح الرابط. يرجى المحاولة لاحقاً.',
                              );
                            }
                          }
                        },
                      ),
                      SettingsNavTile(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: const Color(0xFF34C759),
                        title: 'سياسة الخصوصية',
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                      SettingsNavTile(
                        icon: Icons.gavel_outlined,
                        iconColor: const Color(0xFF8E8E93),
                        title: 'شروط الاستخدام',
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (_) => const TermsOfUseScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
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
            Text(
              'سياسة الخصوصية لتطبيق الرباط',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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
              'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر لإضافة توضيحات أكثر بناءً على الميزات الجديدة، وسيتم إشعارك بذلك.',
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
            Text(
              'شروط الاستخدام',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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
              'لأي استفسار أو مشكلة، يمكنك استخدام وسائل التواصل المتاحة في صفحة دعم المطور داخل التطبيق.',
            ),
          ],
        ),
      ),
    );
  }
}
