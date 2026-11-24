import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/active_focus_state.dart';

class FocusModeSelector extends StatelessWidget {
  const FocusModeSelector({
    super.key,
    required this.selectedMode,
    required this.onSelect,
    this.remainingUntilPrayerMinutes,
    this.nextPrayerName,
  });

  final FocusSessionMode selectedMode;
  final ValueChanged<FocusSessionMode> onSelect;
  final int? remainingUntilPrayerMinutes;
  final String? nextPrayerName;

  @override
  Widget build(BuildContext context) {
    final untilPrayerText =
        nextPrayerName != null && remainingUntilPrayerMinutes != null
            ? 'الرباط حتى ${nextPrayerName!} (${remainingUntilPrayerMinutes!}د)'
            : 'الرباط حتى الأذان';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(
            context,
            mode: FocusSessionMode.untilPrayer,
            icon: Icons.mosque_rounded,
            label: untilPrayerText,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            mode: FocusSessionMode.pomodoro,
            icon: Icons.timer_outlined,
            label: 'بومودورو (25د)',
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            mode: FocusSessionMode.customTimer,
            icon: Icons.tune_rounded,
            label: 'مؤقت مخصص',
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            mode: FocusSessionMode.openStopwatch,
            icon: Icons.all_inclusive_rounded,
            label: 'تركيز مفتوح',
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required FocusSessionMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedMode == mode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? Colors.white : colorScheme.onSurface,
        ),
      ),
      backgroundColor: isSelected
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      side: BorderSide(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(alpha: 0.35),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        HapticFeedback.selectionClick();
        onSelect(mode);
      },
    );
  }
}
