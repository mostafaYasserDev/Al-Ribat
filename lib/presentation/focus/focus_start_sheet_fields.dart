part of 'focus_sessions_screen.dart';

List<Widget> _buildFocusStartFields({
  required BuildContext context,
  required BuildContext sheetContext,
  required WidgetRef ref,
  required TextEditingController nameController,
  required StateSetter setModal,
  required int Function() getMinutes,
  required ValueChanged<int> setMinutes,
}) {
  return [
    Text(
      'بدء جلسة تركيز جديدة',
      style: Theme.of(sheetContext).textTheme.titleLarge,
    ),
    const SizedBox(height: 12),
    TextField(
      controller: nameController,
      decoration: const InputDecoration(
        labelText: 'اسم الجلسة أو الهدف',
        hintText: 'مثال: قراءة ورد، مراجعة درس، برمجة...',
      ),
    ),
    const SizedBox(height: 14),
    Text('مدة الجلسة', style: Theme.of(sheetContext).textTheme.labelLarge),
    const SizedBox(height: 6),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [15, 25, 45, 60].map((m) {
        return ChoiceChip(
          label: Text('$m دقيقة'),
          selected: getMinutes() == m,
          onSelected: (sel) {
            if (sel) setModal(() => setMinutes(m));
          },
        );
      }).toList(),
    ),
    const SizedBox(height: 8),
    TextField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'أو حدد مدة مخصصة (بالدقائق)',
        hintText: 'مثال: 90',
      ),
      onChanged: (val) {
        final m = int.tryParse(val);
        if (m != null && m > 0) {
          setModal(() => setMinutes(m));
        }
      },
    ),
    const SizedBox(height: 20),
    _buildFocusStartButton(
      context: context,
      sheetContext: sheetContext,
      ref: ref,
      nameController: nameController,
      getMinutes: getMinutes,
    ),
  ];
}

Widget _buildFocusStartButton({
  required BuildContext context,
  required BuildContext sheetContext,
  required WidgetRef ref,
  required TextEditingController nameController,
  required int Function() getMinutes,
}) {
  return FilledButton.icon(
    onPressed: () async {
      final title = nameController.text.trim().isEmpty
          ? 'جلسة تركيز'
          : nameController.text.trim();
      Navigator.pop(sheetContext);
      await ref.read(activeFocusProvider.notifier).startSession(
            title: title,
            plannedMinutes: getMinutes(),
          );
      lightSuccessHaptic();
      if (context.mounted) {
        appSnack(context, 'بدأت الجلسة — توكل على الله وركز.');
      }
    },
    icon: const Icon(Icons.play_arrow_rounded),
    label: const Text('بدء الجلسة'),
  );
}
