part of '../home_screen.dart';

Widget _buildDateHeader(
  BuildContext context,
  WidgetRef ref,
  DateTime selectedDate,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: () {
          ref.read(selectedDateProvider.notifier).state =
              selectedDate.subtract(const Duration(days: 1));
        },
      ),
      GestureDetector(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (date != null) {
            ref.read(selectedDateProvider.notifier).state = date;
          }
        },
        child: Text(
          DateFormat('EEEE · d MMMM yyyy', 'ar').format(selectedDate),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF142018)
                    : null,
                shadows: Theme.of(context).brightness == Brightness.dark
                    ? const [Shadow(blurRadius: 10, color: Colors.black26)]
                    : null,
              ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: () {
          ref.read(selectedDateProvider.notifier).state =
              selectedDate.add(const Duration(days: 1));
        },
      ),
    ],
  );
}
