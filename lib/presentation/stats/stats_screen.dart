import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/constants/prayer_phase.dart';
import 'package:al_ribat/domain/entities/stats_snapshot.dart';
import 'package:al_ribat/features/home/presentation/widgets/home_prayer_hero_card.dart';
import 'package:al_ribat/features/projects/presentation/widgets/anchored_popover.dart';
import 'package:al_ribat/features/reflections/presentation/widgets/apple_morph_route.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  /// Opens [StatsScreen] with an Apple spatial morph from [sourceContext].
  static Future<void> open(
    BuildContext context, {
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
        builder: (_) => const StatsScreen(),
      ),
    );
  }

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final _helpKey = GlobalKey();

  void _showHelpPopover(BuildContext anchorContext) {
    HapticFeedback.selectionClick();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);

    showAnchoredPopover(
      anchorContext,
      width: 310,
      preferAbove: false,
      anchorRadius: 11,
      builder: (popCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    size: 17,
                    color: Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'دليل قراءة الإحصائيات',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0.6, thickness: 0.6, color: dividerColor),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpItem(
                  icon: Icons.donut_large_rounded,
                  color: Color(0xFF1F6F4A),
                  title: 'حلقة الالتزام الأسبوعي',
                  desc:
                      'تقيس نسبة ما أنجزته مقارنةً بكل المهام المستحقة من السبت حتى اليوم — لتعكس التزامك الحقيقي.',
                ),
                SizedBox(height: 10),
                _HelpItem(
                  icon: Icons.local_fire_department_rounded,
                  color: Color(0xFFFF9500),
                  title: 'سلسلة الثبات (Streak)',
                  desc:
                      'عدد الأيام المتتالية التي أنجزت فيها؛ المداومة على القليل تصنع أثراً عظيماً.',
                ),
                SizedBox(height: 10),
                _HelpItem(
                  icon: Icons.bar_chart_rounded,
                  color: Color(0xFF007AFF),
                  title: 'نبض الأسبوع وخريطة الصلوات',
                  desc:
                      'تكشف لك أيام نشاطك وفتورك، وأي صلاة تحقق عندها أعلى إنتاجية لتستثمر وقتك فيها.',
                ),
                SizedBox(height: 10),
                _HelpItem(
                  icon: Icons.warning_amber_rounded,
                  color: Color(0xFFFF3B30),
                  title: 'النشاط الأكثر تخطياً',
                  desc:
                      'إشارة لتبسيط هذا النشاط أو نقله لصلاة أنسب بدلاً من تراكم تخطيه.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final streak = ref.watch(streakProvider).valueOrNull ?? 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'الإحصائيات',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: GestureDetector(
                key: _helpKey,
                onTap: () =>
                    _showHelpPopover(_helpKey.currentContext ?? context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    size: 19,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.6),
            child: Container(height: 0.6, color: dividerColor),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            // 1. Hero Commitment Ring + Streak Card
            _HeroStatsCard(
              stats: stats,
              streak: streak,
              cardColor: cardColor,
              dividerColor: dividerColor,
            ),
            const SizedBox(height: 14),

            // 2. Smart Insights Card
            _SmartInsightsCard(
              stats: stats,
              cardColor: cardColor,
              dividerColor: dividerColor,
            ),
            const SizedBox(height: 14),

            // 3. Weekly Pulse Bar Chart (7 days)
            _WeeklyPulseCard(
              dailyCounts: stats.weeklyDailyCounts,
              cardColor: cardColor,
              dividerColor: dividerColor,
            ),
            const SizedBox(height: 14),

            // 4. 2x2 Pillars Grid
            _PillarsGrid(
              stats: stats,
              cardColor: cardColor,
              dividerColor: dividerColor,
            ),
            const SizedBox(height: 14),

            // 5. Prayer Distribution Map
            _PrayerDistributionCard(
              byPhase: stats.byPhase,
              cardColor: cardColor,
              dividerColor: dividerColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({
    required this.stats,
    required this.streak,
    required this.cardColor,
    required this.dividerColor,
  });

  final StatsSnapshot stats;
  final int streak;
  final Color cardColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rate = stats.completionRateThisWeek.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dividerColor, width: 0.7),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: rate),
            duration: const Duration(milliseconds: 780),
            curve: Curves.easeOutCubic,
            builder: (context, animVal, _) {
              final pct = (animVal * 100).round();
              return SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: animVal,
                    activeColor: colorScheme.primary,
                    trackColor: colorScheme.primary.withValues(alpha: 0.14),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          'التزامك',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معدل الالتزام الأسبوعي',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stats.totalDueThisWeek == 0
                      ? 'لا توجد مهام مجدولة هذا الأسبوع بعد'
                      : 'أنجزت ${stats.totalDoneThisWeek} من أصل ${stats.totalDueThisWeek} مهمة مستحقة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: Color(0xFFFF9500),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'سلسلة الثبات: $streak يوم',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.activeColor != activeColor;
}

class _SmartInsightsCard extends StatelessWidget {
  const _SmartInsightsCard({
    required this.stats,
    required this.cardColor,
    required this.dividerColor,
  });

  final StatsSnapshot stats;
  final Color cardColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor, width: 0.7),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SquircleBadge(
                icon: Icons.auto_awesome_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'نظرة ذكية',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stats.feedbackLine,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (stats.mostProductivePhase != null ||
              stats.mostSkippedActivity != null) ...[
            const SizedBox(height: 12),
            Divider(height: 0.6, thickness: 0.6, color: dividerColor),
            const SizedBox(height: 10),
          ],
          if (stats.mostProductivePhase != null) ...[
            Builder(
              builder: (context) {
                final v = prayerPhaseVisual(stats.mostProductivePhase!);
                return Row(
                  children: [
                    Icon(v.icon, size: 18, color: v.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'أكثر الأوقات بركة وإنتاجية: ${stats.mostProductivePhase!.arabicName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          if (stats.mostSkippedActivity != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Color(0xFFFF3B30),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الأكثر تخطياً: «${stats.mostSkippedActivity}» — جرّب تقليص هدفه أو تغيير وقته',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFFF3B30),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyPulseCard extends StatelessWidget {
  const _WeeklyPulseCard({
    required this.dailyCounts,
    required this.cardColor,
    required this.dividerColor,
  });

  final List<int> dailyCounts;
  final Color cardColor;
  final Color dividerColor;

  static const _dayLabels = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    // Saturday = 0 .. Friday = 6
    final todayIndex = (now.weekday + 1) % 7;
    final maxCount = dailyCounts.fold<int>(1, (m, v) => v > m ? v : m);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor, width: 0.7),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SquircleBadge(
                icon: Icons.bar_chart_rounded,
                color: Color(0xFF007AFF),
              ),
              const SizedBox(width: 10),
              Text(
                'نبض الأسبوع',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final count = i < dailyCounts.length ? dailyCounts[i] : 0;
                final isToday = i == todayIndex;
                final targetFraction =
                    count == 0 ? 0.08 : (count / maxCount).clamp(0.16, 1.0);
                final barColor = isToday
                    ? colorScheme.primary
                    : (count > 0
                        ? const Color(0xFF007AFF).withValues(alpha: 0.72)
                        : colorScheme.onSurface.withValues(alpha: 0.1));

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        count > 0 ? '$count' : '',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.08, end: targetFraction),
                        duration: Duration(milliseconds: 420 + i * 55),
                        curve: Curves.easeOutCubic,
                        builder: (context, frac, _) => Container(
                          width: 18,
                          height: 62 * frac,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _dayLabels[i],
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isToday
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarsGrid extends StatelessWidget {
  const _PillarsGrid({
    required this.stats,
    required this.cardColor,
    required this.dividerColor,
  });

  final StatsSnapshot stats;
  final Color cardColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PillarTile(
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF1F6F4A),
                title: 'أنشطة الأسبوع',
                value: stats.weeklyCompleted,
                subtitle: 'الشهر: ${stats.monthlyCompleted}',
                cardColor: cardColor,
                dividerColor: dividerColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PillarTile(
                icon: Icons.timer_rounded,
                color: const Color(0xFF007AFF),
                title: 'دقائق التركيز',
                value: stats.focusMinutesThisWeek,
                subtitle: '${stats.workSessionsThisWeek} جلسات مكتملة',
                cardColor: cardColor,
                dividerColor: dividerColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PillarTile(
                icon: Icons.auto_stories_rounded,
                color: const Color(0xFF7C3AED),
                title: 'تأملات الشهر',
                value: stats.reflectionsThisMonth,
                subtitle: 'تدوين ومراجعة',
                cardColor: cardColor,
                dividerColor: dividerColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PillarTile(
                icon: Icons.bolt_rounded,
                color: const Color(0xFFFF9500),
                title: 'الأنشطة الحرة',
                value: stats.independentCompleted,
                subtitle: 'مهام خارج الصلوات',
                cardColor: cardColor,
                dividerColor: dividerColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PillarTile extends StatelessWidget {
  const _PillarTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.cardColor,
    required this.dividerColor,
  });

  final IconData icon;
  final Color color;
  final String title;
  final int value;
  final String subtitle;
  final Color cardColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor, width: 0.7),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SquircleBadge(icon: icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeOutCubic,
            builder: (context, animVal, _) => Text(
              '$animVal',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.52),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerDistributionCard extends StatelessWidget {
  const _PrayerDistributionCard({
    required this.byPhase,
    required this.cardColor,
    required this.dividerColor,
  });

  final Map<PrayerPhase, int> byPhase;
  final Color cardColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = byPhase.values.fold<int>(0, (a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor, width: 0.7),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SquircleBadge(
                icon: Icons.mosque_rounded,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 10),
              Text(
                'توزيع الإنجاز حسب الصلوات',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...PrayerPhase.values.map((phase) {
            final count = byPhase[phase] ?? 0;
            final ratio = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
            final visual = prayerPhaseVisual(phase);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(visual.icon, size: 17, color: visual.color),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          phase.arabicName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        total == 0
                            ? '$count'
                            : '$count (${(ratio * 100).round()}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: ratio),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) => LinearProgressIndicator(
                        value: val,
                        minHeight: 7,
                        backgroundColor: visual.color.withValues(alpha: 0.13),
                        valueColor: AlwaysStoppedAnimation<Color>(visual.color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SquircleBadge extends StatelessWidget {
  const _SquircleBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
