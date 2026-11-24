part of '../add_activity_sheet.dart';

mixin _RepetitionFields on _SheetStateCore {
  List<Widget> _buildRepetition(BuildContext context) {
    return [
      Text(
        'معدل التكرار',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      SegmentedButton<ActivityRepetition>(
        segments: const [
          ButtonSegment(
              value: ActivityRepetition.once, label: Text('مرة واحدة')),
          ButtonSegment(value: ActivityRepetition.daily, label: Text('يوميًا')),
          ButtonSegment(
            value: ActivityRepetition.weekly,
            label: Text('أسبوعيًا'),
          ),
          ButtonSegment(
            value: ActivityRepetition.monthly,
            label: Text('شهريًا'),
          ),
        ],
        selected: {_repetition},
        onSelectionChanged: (v) => setState(() => _repetition = v.first),
      ),
      if (_repetition == ActivityRepetition.once) ...[
        const SizedBox(height: 8),
        Text(
          'سيظهر في: ${DateFormat('yyyy/MM/dd').format(ref.watch(selectedDateProvider))}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ];
  }
}
