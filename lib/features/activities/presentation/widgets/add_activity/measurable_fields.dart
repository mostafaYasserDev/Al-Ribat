part of '../add_activity_sheet.dart';

mixin _MeasurableFields on _SheetStateCore {
  List<Widget> _buildMeasurableFields() {
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _targetGoalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'العدد المستهدف (مثال: 20)',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: _goalUnitController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                const predefinedUnits = [
                  'مرة',
                  'دقيقة',
                  'ساعة',
                  'صفحة',
                  'جزء',
                  'سورة',
                  'آية',
                  'كوب',
                  'تمرين',
                  'خطوة',
                  'ركعة',
                  'حصة',
                  'طابق',
                ];
                if (textEditingValue.text.isEmpty) {
                  return predefinedUnits;
                }
                return predefinedUnits
                    .where((u) => u.contains(textEditingValue.text))
                    .toList();
              },
              onSelected: (String selection) {
                _goalUnitController.text = selection;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                controller.addListener(() {
                  _goalUnitController.text = controller.text;
                });
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'النوع (مثال: صفحة)',
                    hintText: 'اختر أو اكتب نوعًا...',
                  ),
                );
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
    ];
  }
}
