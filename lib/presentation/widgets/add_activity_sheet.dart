import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers.dart';
import '../../domain/entities/activity_item.dart';
import '../../core/constants/prayer_phase.dart';
import 'templates_sheet.dart';

class AddActivitySheet extends ConsumerStatefulWidget {
  const AddActivitySheet({super.key, required this.onSave, this.initialActivity});

  final Future<bool> Function(ActivityItem activity) onSave;
  final ActivityItem? initialActivity;

  @override
  ConsumerState<AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends ConsumerState<AddActivitySheet> {
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

  final List<String> _icons = [
    'task_alt', 'wb_sunny', 'nights_stay', 'bedtime', 'light_mode', 'star',
    'menu_book', 'book', 'translate', 'self_improvement', 'fitness_center',
    'directions_walk', 'water_drop', 'family_restroom', 'group'
  ];
  
  final List<String> _colors = [
    '#FFB74D', '#5C6BC0', '#3949AB', '#FDD835', '#1E88E5', '#8D6E63',
    '#6D4C41', '#00897B', '#8E24AA', '#E53935', '#43A047', '#039BE5',
    '#D81B60', '#F4511E', '#607D8B'
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialActivity;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController = TextEditingController(text: initial?.description ?? '');
    _projectController = TextEditingController(text: initial?.projectName ?? '');
    _groupController = TextEditingController(text: initial?.groupName ?? '');
    
    _isMeasurable = initial?.isMeasurable ?? false;
    _targetGoalController = TextEditingController(text: initial?.targetGoal?.toString() ?? '');
    _goalUnitController = TextEditingController(text: initial?.goalUnit ?? '');
    
    _repetition = initial?.repetition ?? ActivityRepetition.daily;
    _repeatDays.addAll(initial?.repeatDays ?? []);
    
    _type = initial?.type ?? ActivityType.independent;
    _linkedPrayer = initial?.linkedPrayer ?? PrayerPhase.fajr;
    
    _notificationsEnabled = initial?.notificationsEnabled ?? false;
    _reminderTime = initial != null && initial.reminderHour != null && initial.reminderMinute != null
        ? TimeOfDay(hour: initial.reminderHour!, minute: initial.reminderMinute!)
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
  
  IconData _getIconData(String name) {
    switch (name) {
      case 'wb_sunny': return Icons.wb_sunny;
      case 'nights_stay': return Icons.nights_stay;
      case 'bedtime': return Icons.bedtime;
      case 'light_mode': return Icons.light_mode;
      case 'star': return Icons.star;
      case 'menu_book': return Icons.menu_book;
      case 'book': return Icons.book;
      case 'translate': return Icons.translate;
      case 'self_improvement': return Icons.self_improvement;
      case 'fitness_center': return Icons.fitness_center;
      case 'directions_walk': return Icons.directions_walk;
      case 'water_drop': return Icons.water_drop;
      case 'family_restroom': return Icons.family_restroom;
      case 'group': return Icons.group;
      default: return Icons.task_alt;
    }
  }

  Color _getColorData(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialActivity == null ? 'إضافة نشاط / عادة' : 'تعديل',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (widget.initialActivity == null)
                    TextButton.icon(
                      onPressed: () async {
                        final t = await showModalBottomSheet<ActivityTemplate>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => const TemplatesSheet(),
                        );
                        if (t != null) _applyTemplate(t);
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('قوالب جاهزة'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'الاسم (مثل: قراءة الورد، المشي، إلخ)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('هدف قابل للقياس (مثال: قراءة 20 صفحة)'),
                value: _isMeasurable,
                onChanged: (v) => setState(() => _isMeasurable = v),
              ),
              if (_isMeasurable) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _targetGoalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'العدد المستهدف (مثال: 20)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Autocomplete<String>(
                        initialValue: TextEditingValue(text: _goalUnitController.text),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          const predefinedUnits = ['مرة', 'دقيقة', 'ساعة', 'صفحة', 'جزء', 'سورة', 'آية', 'كوب', 'تمرين', 'خطوة', 'ركعة', 'حصة', 'طابق'];
                          if (textEditingValue.text.isEmpty) {
                            return predefinedUnits;
                          }
                          return predefinedUnits.where((u) => u.contains(textEditingValue.text)).toList();
                        },
                        onSelected: (String selection) {
                          _goalUnitController.text = selection;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          controller.addListener(() {
                            _goalUnitController.text = controller.text;
                          });
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'النوع (مثال: صفحة)',
                              hintText: 'اختر أو اكتب نوعاً...',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _projectController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final activities = ref.read(activitiesProvider).valueOrNull ?? [];
                  final projects = activities.map((e) => e.projectName).where((e) => e != null && e.isNotEmpty).toSet().cast<String>();
                  if (textEditingValue.text.isEmpty) return projects.toList();
                  return projects.where((p) => p.contains(textEditingValue.text)).toList();
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
              const SizedBox(height: 10),
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
                  return groups.where((g) => g.contains(textEditingValue.text)).toList();
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
              const SizedBox(height: 12),
              
              // Customization (Icon and Color)
              Text('الشكل (أيقونة ولون)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final iconName = _icons[index];
                    final isSelected = _selectedIcon == iconName;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = iconName),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : null,
                          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                        ),
                        child: Icon(_getIconData(iconName), color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final colorHex = _colors[index];
                    final isSelected = _selectedColor == colorHex;
                    final c = _getColorData(colorHex);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              // Repetition
              Text('معدل التكرار', style: Theme.of(context).textTheme.labelLarge),
              SegmentedButton<ActivityRepetition>(
                segments: const [
                  ButtonSegment(value: ActivityRepetition.once, label: Text('مرة واحدة')),
                  ButtonSegment(value: ActivityRepetition.daily, label: Text('يومياً')),
                  ButtonSegment(value: ActivityRepetition.weekly, label: Text('أسبوعياً')),
                  ButtonSegment(value: ActivityRepetition.monthly, label: Text('شهرياً')),
                ],
                selected: {_repetition},
                onSelectionChanged: (v) => setState(() => _repetition = v.first),
              ),

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
                      )
                  ],
                ),
              ],

              if (_repetition == ActivityRepetition.monthly) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
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
                      )
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              // Linking to prayer
              Text('الارتباط بالصلاة', style: Theme.of(context).textTheme.labelLarge),
              SegmentedButton<ActivityType>(
                segments: const [
                  ButtonSegment(value: ActivityType.beforePrayer, label: Text('قبل الصلاة')),
                  ButtonSegment(value: ActivityType.afterPrayer, label: Text('بعد الصلاة')),
                  ButtonSegment(value: ActivityType.independent, label: Text('حر')),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              
              if (_type != ActivityType.independent) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<PrayerPhase>(
                  value: _linkedPrayer,
                  decoration: const InputDecoration(labelText: 'اختر الصلاة'),
                  items: PrayerPhase.values.map((p) => DropdownMenuItem(value: p, child: Text(p.arabicName))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _linkedPrayer = v);
                  },
                ),
              ],
              
              const SizedBox(height: 12),
              // Notifications
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تفعيل التذكير'),
                value: _notificationsEnabled,
                onChanged: (v) async {
                  setState(() => _notificationsEnabled = v);
                  if (v) {
                    await ref.read(notificationServiceProvider).ensureNotificationPermission();
                  }
                },
              ),
              
              if (_notificationsEnabled)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('وقت التذكير'),
                  trailing: Text(_reminderTime.format(context)),
                  onTap: () async {
                    final p = await showTimePicker(context: context, initialTime: _reminderTime);
                    if (p != null) setState(() => _reminderTime = p);
                  },
                ),
                
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (_titleController.text.trim().isEmpty) return;
                  
                  final act = ActivityItem(
                    id: widget.initialActivity?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                    repetition: _repetition,
                    repeatDays: _repetition == ActivityRepetition.weekly ? _repeatDays.toList() : const [],
                    type: _type,
                    linkedPrayer: _type != ActivityType.independent ? _linkedPrayer : null,
                    notificationsEnabled: _notificationsEnabled,
                    reminderHour: _notificationsEnabled ? _reminderTime.hour : null,
                    reminderMinute: _notificationsEnabled ? _reminderTime.minute : null,
                    createdAt: widget.initialActivity?.createdAt ?? DateTime.now(),
                    history: widget.initialActivity?.history ?? const [],
                    orderIndex: widget.initialActivity?.orderIndex ?? 0,
                    iconName: _selectedIcon,
                    colorHex: _selectedColor,
                    projectName: _projectController.text.trim().isEmpty ? null : _projectController.text.trim(),
                    groupName: _groupController.text.trim().isEmpty ? null : _groupController.text.trim(),
                    isMeasurable: _isMeasurable,
                    targetGoal: _isMeasurable ? double.tryParse(_targetGoalController.text.trim()) : null,
                    goalUnit: _isMeasurable ? _goalUnitController.text.trim() : null,
                  );
                  
                  final ok = await widget.onSave(act);
                  if (ok && context.mounted) Navigator.pop(context);
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
