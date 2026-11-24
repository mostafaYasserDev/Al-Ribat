part of '../add_activity_sheet.dart';

mixin _ProjectField on _SheetStateCore {
  List<Widget> _buildProjectField() {
    return [
      Autocomplete<String>(
        initialValue: TextEditingValue(text: _projectController.text),
        optionsBuilder: (TextEditingValue textEditingValue) {
          final activities = ref.read(activitiesProvider).valueOrNull ?? [];
          final projects = activities
              .map((e) => e.projectName)
              .where((e) => e != null && e.isNotEmpty)
              .toSet()
              .cast<String>();
          if (textEditingValue.text.isEmpty) return projects.toList();
          return projects
              .where((p) => p.contains(textEditingValue.text))
              .toList();
        },
        onSelected: (String selection) {
          _projectController.text = selection;
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          // Link internal controller with outer controller so we capture text if not selected
          controller.addListener(() {
            _projectController.text = controller.text;
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: 'المشروع (اختياري)',
              hintText: 'مثال: صحة، صلاة، تطوير ذاتي...',
            ),
          );
        },
      ),
    ];
  }
}
