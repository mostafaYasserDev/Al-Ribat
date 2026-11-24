part of '../add_activity_sheet.dart';

mixin _RepeatDays on _SheetStateCore {
  List<Widget> _buildRepeatDays() {
    return [
      if (_repetition == ActivityRepetition.weekly) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (int i = 1; i <= 7; i++)
              FilterChip(
                label: Text(['إ', 'ث', 'أ', 'خ', 'ج', 'س', 'ح'][i - 1]),
                selected: _repeatDays.contains(i),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _repeatDays.add(i);
                    } else {
                      _repeatDays.remove(i);
                    }
                  });
                },
              ),
          ],
        ),
      ],
      if (_repetition == ActivityRepetition.monthly) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (int i = 1; i <= 31; i++)
              FilterChip(
                label: Text('$i'),
                selected: _repeatDays.contains(i),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _repeatDays.add(i);
                    } else {
                      _repeatDays.remove(i);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    ];
  }
}
