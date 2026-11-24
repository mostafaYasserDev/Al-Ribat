part of '../add_activity_sheet.dart';

mixin _GroupField on _SheetStateCore {
  List<Widget> _buildGroupField() {
    return [
      Autocomplete<String>(
        initialValue: TextEditingValue(text: _groupController.text),
        optionsBuilder: (TextEditingValue textEditingValue) {
          final activities = ref.read(activitiesProvider).valueOrNull ?? [];
          final groups = activities
              .where((e) => e.projectName == _projectController.text)
              .map((e) => e.groupName)
              .where((e) => e != null && e.isNotEmpty)
              .toSet()
              .cast<String>();
          if (textEditingValue.text.isEmpty) return groups.toList();
          return groups
              .where((g) => g.contains(textEditingValue.text))
              .toList();
        },
        onSelected: (String selection) {
          _groupController.text = selection;
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          controller.addListener(() {
            _groupController.text = controller.text;
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: 'المجموعة داخل المشروع (اختياري)',
              hintText: 'مثال: الرياضة الصباحية...',
            ),
          );
        },
      ),
    ];
  }
}
