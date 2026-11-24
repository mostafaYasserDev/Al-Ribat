part of '../add_activity_sheet.dart';

mixin _TemplateApplier on _SheetStateCore {
  void _applyTemplate(ActivityTemplate t) {
    setState(() {
      _titleController.text = t.title;
      if (t.description != null) _descriptionController.text = t.description!;
      _type = t.type;
      _linkedPrayer = t.linkedPrayer ?? _linkedPrayer;
      _selectedIcon = t.iconName;
      _selectedColor = t.colorHex;
      _repetition = t.repetition;

      _isMeasurable = t.isMeasurable;
      if (t.isMeasurable) {
        _targetGoalController.text = t.targetGoal?.toString() ?? '';
        _goalUnitController.text = t.goalUnit ?? '';
      }
    });
  }
}
