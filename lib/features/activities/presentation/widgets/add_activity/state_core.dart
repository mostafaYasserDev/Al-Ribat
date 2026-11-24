part of '../add_activity_sheet.dart';

mixin _SheetStateCore on ConsumerState<AddActivitySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _projectController;
  late final TextEditingController _groupController;

  late final TextEditingController _targetGoalController;
  late final TextEditingController _goalUnitController;
  late bool _isMeasurable;

  late ActivityRepetition _repetition;
  final Set<int> _repeatDays = {};

  late ActivityType _type;
  PrayerPhase? _linkedPrayer;

  late bool _notificationsEnabled;
  late TimeOfDay _reminderTime;

  String? _selectedIcon;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialActivity;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    _projectController = TextEditingController(
        text: initial?.projectName ?? widget.initialProject ?? '');
    _groupController = TextEditingController(
        text: initial?.groupName ?? widget.initialGroup ?? '');

    _isMeasurable = initial?.isMeasurable ?? false;
    _targetGoalController = TextEditingController(
      text: initial?.targetGoal?.toString() ?? '',
    );
    _goalUnitController = TextEditingController(text: initial?.goalUnit ?? '');

    _repetition = initial?.repetition ?? ActivityRepetition.daily;
    _repeatDays.addAll(initial?.repeatDays ?? []);

    if (widget.isIndependentInitial) {
      _type = ActivityType.independent;
      _linkedPrayer = null;
    } else if (widget.initialPhase != null) {
      _type = ActivityType.afterPrayer;
      _linkedPrayer = widget.initialPhase;
    } else {
      _type = initial?.type ?? ActivityType.afterPrayer;
      _linkedPrayer = initial?.linkedPrayer ?? PrayerPhase.fajr;
    }

    _notificationsEnabled = initial?.notificationsEnabled ?? false;
    _reminderTime = initial != null &&
            initial.reminderHour != null &&
            initial.reminderMinute != null
        ? TimeOfDay(
            hour: initial.reminderHour!,
            minute: initial.reminderMinute!,
          )
        : TimeOfDay.now();

    _selectedIcon = initial?.iconName;
    _selectedColor = initial?.colorHex;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _projectController.dispose();
    _groupController.dispose();
    _targetGoalController.dispose();
    _goalUnitController.dispose();
    super.dispose();
  }
}
