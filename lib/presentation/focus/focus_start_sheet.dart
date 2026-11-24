part of 'focus_sessions_screen.dart';

Future<void> _openFocusStartSheet(BuildContext context, WidgetRef ref) async {
  final active = ref.read(activeFocusProvider);
  if (active != null) {
    appSnack(
      context,
      'هناك جلسة نشطة بالفعل. أكملها أو أوقفها قبل بدء جلسة جديدة.',
    );
    return;
  }

  final nameController = TextEditingController(text: 'جلسة تركيز');
  var minutes = 25;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildFocusStartFields(
            context: context,
            sheetContext: ctx,
            ref: ref,
            nameController: nameController,
            setModal: setModal,
            getMinutes: () => minutes,
            setMinutes: (value) => minutes = value,
          ),
        ),
      ),
    ),
  );
  nameController.dispose();
}
