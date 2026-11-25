import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/active_focus_state.dart';

class FocusModeSelector extends StatelessWidget {
  const FocusModeSelector({
    super.key,
    required this.selectedMode,
    required this.onSelect,
  });

  final FocusSessionMode selectedMode;
  final ValueChanged<FocusSessionMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final effectiveSelection = selectedMode == FocusSessionMode.pomodoro
        ? FocusSessionMode.customTimer
        : selectedMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<FocusSessionMode>(
        segments: const [
          ButtonSegment<FocusSessionMode>(
            value: FocusSessionMode.untilPrayer,
            label: Text('حتى الأذان', overflow: TextOverflow.ellipsis),
            icon: Icon(Icons.mosque_rounded, size: 18),
          ),
          ButtonSegment<FocusSessionMode>(
            value: FocusSessionMode.customTimer,
            label: Text('مؤقت مخصص', overflow: TextOverflow.ellipsis),
            icon: Icon(Icons.timer_outlined, size: 18),
          ),
          ButtonSegment<FocusSessionMode>(
            value: FocusSessionMode.openStopwatch,
            label: Text('ساعة إيقاف', overflow: TextOverflow.ellipsis),
            icon: Icon(Icons.all_inclusive_rounded, size: 18),
          ),
        ],
        selected: {effectiveSelection},
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        onSelectionChanged: (selection) {
          if (selection.isEmpty) return;
          HapticFeedback.selectionClick();
          onSelect(selection.first);
        },
      ),
    );
  }
}
