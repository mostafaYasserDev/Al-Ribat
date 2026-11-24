part of '../add_activity_sheet.dart';

mixin _BasicFields on _TemplateApplier {
  List<Widget> _buildHeader(BuildContext context) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.initialActivity == null
                ? 'إضافة نشاط / عادة'
                : 'تعديل النشاط',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('قوالب مقترحة'),
            ),
        ],
      ),
    ];
  }

  List<Widget> _buildBasicFields() {
    return [
      const SizedBox(height: 12),
      TextField(
        controller: _titleController,
        autofocus: widget.initialActivity == null,
        decoration: const InputDecoration(
          labelText: 'اسم النشاط أو المهمة',
          hintText: 'مثال: قراءة صفحتين، أذكار الصباح، ركعتي الضحى...',
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'ملاحظات إضافية (اختياري)',
          hintText: 'تفاصيل مساعدة أو نية خاصة...',
        ),
      ),
    ];
  }

  Widget _buildMeasurableToggle() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('هدف رقمي قابل للقياس'),
      subtitle: const Text('مثل: قراءة 20 صفحة، 15 دقيقة رياضة'),
      value: _isMeasurable,
      onChanged: (v) => setState(() => _isMeasurable = v),
    );
  }
}
