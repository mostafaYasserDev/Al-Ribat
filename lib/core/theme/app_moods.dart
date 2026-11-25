import 'package:flutter/material.dart';

class MoodOption {
  final String label;
  final IconData icon;
  final Color color;

  const MoodOption({
    required this.label,
    required this.icon,
    required this.color,
  });
}

abstract final class AppMoods {
  static const List<MoodOption> options = [
    MoodOption(
        label: 'سعيد',
        icon: Icons.sentiment_very_satisfied_rounded,
        color: Color(0xFF4CAF50)),
    MoodOption(
        label: 'هادئ', icon: Icons.cloud_outlined, color: Color(0xFF0288D1)),
    MoodOption(
        label: 'ممتن',
        icon: Icons.favorite_border_rounded,
        color: Color(0xFFE91E63)),
    MoodOption(
        label: 'متحمس', icon: Icons.bolt_rounded, color: Color(0xFFFF9800)),
    MoodOption(
        label: 'مرهق',
        icon: Icons.battery_alert_rounded,
        color: Color(0xFF78909C)),
    MoodOption(
        label: 'متوتر',
        icon: Icons.sentiment_neutral_rounded,
        color: Color(0xFFFF7043)),
    MoodOption(
        label: 'حزين',
        icon: Icons.sentiment_dissatisfied_rounded,
        color: Color(0xFF5C6BC0)),
    MoodOption(
        label: 'مطمئن', icon: Icons.spa_rounded, color: Color(0xFF009688)),
    MoodOption(
        label: 'خاشع', icon: Icons.mosque_rounded, color: Color(0xFF1F6F4A)),
    MoodOption(
        label: 'متفائل',
        icon: Icons.wb_sunny_rounded,
        color: Color(0xFFFFB300)),
    MoodOption(
        label: 'مشتت', icon: Icons.blur_on_rounded, color: Color(0xFF7E57C2)),
    MoodOption(
        label: 'نادم',
        icon: Icons.water_drop_rounded,
        color: Color(0xFF3F51B5)),
  ];

  static MoodOption? find(String? label) {
    if (label == null || label.isEmpty) return null;
    for (final opt in options) {
      if (opt.label == label) return opt;
    }
    return null;
  }
}

class MoodDisplayChip extends StatelessWidget {
  final String mood;
  final bool dense;
  final VoidCallback? onRemove;

  const MoodDisplayChip({
    super.key,
    required this.mood,
    this.dense = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final opt = AppMoods.find(mood);
    final icon = opt?.icon ?? Icons.sentiment_satisfied_rounded;
    final color = opt?.color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 15 : 18, color: color),
          const SizedBox(width: 5),
          Text(
            mood,
            style: TextStyle(
              fontSize: dense ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded, size: 14, color: color),
            ),
          ],
        ],
      ),
    );
  }
}
