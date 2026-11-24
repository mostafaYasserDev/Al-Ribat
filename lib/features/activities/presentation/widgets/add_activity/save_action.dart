part of '../add_activity_sheet.dart';

mixin _SaveAction on _SheetStateCore {
  Widget _buildSaveButton() {
    return FilledButton(
      onPressed: () async {
        if (_titleController.text.trim().isEmpty) return;

        final selectedDate = ref.read(selectedDateProvider);
        final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
        final onceTargetDate = _repetition == ActivityRepetition.once
            ? (widget.initialActivity?.targetDate ?? selectedDateStr)
            : null;
        final createdAt = widget.initialActivity?.createdAt ??
            DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              12,
            );

        final act = ActivityItem(
          id: widget.initialActivity?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          repetition: _repetition,
          targetDate: onceTargetDate,
          repeatDays: (_repetition == ActivityRepetition.weekly ||
                  _repetition == ActivityRepetition.monthly)
              ? _repeatDays.toList()
              : const [],
          type: _type,
          linkedPrayer:
              _type != ActivityType.independent ? _linkedPrayer : null,
          notificationsEnabled: _notificationsEnabled,
          reminderHour: _notificationsEnabled ? _reminderTime.hour : null,
          reminderMinute: _notificationsEnabled ? _reminderTime.minute : null,
          createdAt: createdAt,
          history: widget.initialActivity?.history ?? const [],
          orderIndex: widget.initialActivity?.orderIndex ?? 0,
          iconName: _selectedIcon,
          colorHex: _selectedColor,
          projectName: _projectController.text.trim().isEmpty
              ? null
              : _projectController.text.trim(),
          groupName: _groupController.text.trim().isEmpty
              ? null
              : _groupController.text.trim(),
          isMeasurable: _isMeasurable,
          targetGoal: _isMeasurable
              ? double.tryParse(_targetGoalController.text.trim())
              : null,
          goalUnit: _isMeasurable ? _goalUnitController.text.trim() : null,
        );

        final ok = await widget.onSave(act);
        if (ok && mounted) Navigator.pop(context);
      },
      child: const Text('حفظ'),
    );
  }
}
