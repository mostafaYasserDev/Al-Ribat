import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/work_session_item.dart';

class FocusSessionSheet extends StatefulWidget {
  const FocusSessionSheet({
    super.key,
    required this.onComplete,
    this.initialName,
    this.initialMinutes,
  });

  final void Function(WorkSessionItem session) onComplete;
  final String? initialName;
  final int? initialMinutes;

  @override
  State<FocusSessionSheet> createState() => _FocusSessionSheetState();
}

class _FocusSessionSheetState extends State<FocusSessionSheet> {
  late final TextEditingController _nameController;
  late int _minutes;
  Timer? _timer;
  int _remaining = 0;
  bool _running = false;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? 'جلسة تركيز');
    _minutes = widget.initialMinutes ?? 25;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _start() {
    HapticFeedback.lightImpact();
    setState(() {
      _running = true;
      _remaining = _minutes * 60;
      _startedAt = DateTime.now();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        _finish(completed: true);
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _finish({required bool completed}) {
    _timer?.cancel();
    if (_startedAt == null) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final session = WorkSessionItem(
      id: id,
      name: _nameController.text.trim().isEmpty ? 'جلسة' : _nameController.text.trim(),
      plannedMinutes: _minutes,
      startedAt: _startedAt!,
      endedAt: DateTime.now(),
      completed: completed,
    );
    HapticFeedback.mediumImpact();
    widget.onComplete(session);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_remaining % 60).toString().padLeft(2, '0');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('جلسة تركيز', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              enabled: !_running,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'اسم الجلسة'),
            ),
            const SizedBox(height: 10),
            Text('المدة', style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [15, 25, 45, 50].map((m) {
                return ChoiceChip(
                  label: Text('$m د'),
                  selected: _minutes == m && !_running,
                  onSelected: _running
                      ? null
                      : (_) => setState(() {
                            _minutes = m;
                          }),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            if (!_running)
              TextField(
                keyboardType: TextInputType.number,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'أو مدة مخصصة (دقائق)',
                  hintText: 'مثال: 60',
                ),
                onChanged: (val) {
                  final m = int.tryParse(val);
                  if (m != null && m > 0) {
                    setState(() => _minutes = m);
                  }
                },
              ),
            const SizedBox(height: 16),
            if (_running)
              Text(
                '$mm:$ss',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            const SizedBox(height: 12),
            if (!_running)
              FilledButton(
                onPressed: _start,
                child: const Text('بدء'),
              )
            else ...[
              FilledButton(
                onPressed: () => _finish(completed: true),
                child: const Text('إنهاء الجلسة'),
              ),
              TextButton(
                onPressed: () => _finish(completed: false),
                child: const Text('إيقاف مبكر'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
