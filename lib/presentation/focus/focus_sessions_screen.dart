import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/work_session_item.dart';
import '../../services/focus_foreground_service.dart';
import '../../services/motivation_quotes.dart';
import '../widgets/focus_session_sheet.dart';

class FocusSessionsScreen extends ConsumerStatefulWidget {
  const FocusSessionsScreen({super.key});

  @override
  ConsumerState<FocusSessionsScreen> createState() => _FocusSessionsScreenState();
}

class _FocusSessionsScreenState extends ConsumerState<FocusSessionsScreen> {
  int? _liveRemainSec;
  bool _isPaused = false;
  bool _canSavePartial = false;
  int? _sessionStartedMs;
  int? _lastHandledDoneMs;

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSessionUi());
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    super.dispose();
  }

  Future<void> _refreshSessionUi() async {
    final remain = await FocusForegroundService.remainingSecondsIfAny();
    final isPaused = await FocusForegroundService.isPausedAsync();
    var canSave = false;
    int? startedMs;
    final active = remain != null && remain > 0;
    if (active) {
      await FocusForegroundService.readSessionMeta(
        onData: (_, __, s) {
          startedMs = s;
          canSave = DateTime.now().millisecondsSinceEpoch - s >= 600000;
        },
      );
    }
    if (!mounted) return;
    setState(() {
      _isPaused = isPaused && active;
      _liveRemainSec = remain;
      _canSavePartial = canSave;
      _sessionStartedMs = active ? startedMs : null;
    });
  }

  void _onTaskData(Object data) {
    if (!mounted) return;
    if (data is! Map) return;
    final type = data['type'] as String?;
    if (type == 'focus_tick') {
      final s = data['remainSec'] as int?;
      setState(() {
        _liveRemainSec = s;
        _isPaused = false;
        if (_sessionStartedMs != null) {
          _canSavePartial =
              DateTime.now().millisecondsSinceEpoch - _sessionStartedMs! >= 600000;
        }
      });
    } else if (type == 'focus_paused_tick') {
      final s = data['remainSec'] as int?;
      setState(() {
        _liveRemainSec = s;
        _isPaused = true;
      });
    } else if (type == 'focus_resumed') {
      _refreshSessionUi();
    } else if (type == 'focus_done') {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_lastHandledDoneMs != null && now - _lastHandledDoneMs! < 2500) return;
      _lastHandledDoneMs = now;
      final title = data['title'] as String? ?? 'جلسة تركيز';
      _handleSessionCompleted(title);
    } else if (type == 'focus_paused') {
      _refreshSessionUi();
    } else if (type == 'focus_cancelled') {
      setState(() {
        _liveRemainSec = null;
        _isPaused = false;
        _sessionStartedMs = null;
        _canSavePartial = false;
      });
    } else if (type == 'focus_save_partial') {
      _handlePartialFromNotify(Map<String, dynamic>.from(data));
    } else if (type == 'focus_save_too_short') {
      appSnack(context, 'الحفظ الجزئي متاح بعد ١٠ دقائق من بدء الجلسة.');
    }
  }

  Future<void> _handlePartialFromNotify(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'جلسة تركيز';
    final plannedRaw = data['plannedMin'];
    final planned = plannedRaw is int
        ? plannedRaw
        : (plannedRaw is num ? plannedRaw.toInt() : 25);
    final startedRaw = data['startedMs'];
    final startedMs = startedRaw is int
        ? startedRaw
        : (startedRaw is num
            ? startedRaw.toInt()
            : DateTime.now().millisecondsSinceEpoch);
    await ref.read(workSessionsProvider.notifier).addSession(
          WorkSessionItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: title,
            plannedMinutes: planned,
            startedAt: DateTime.fromMillisecondsSinceEpoch(startedMs),
            endedAt: DateTime.now(),
            completed: false,
          ),
        );
    if (mounted) {
      setState(() {
        _liveRemainSec = null;
        _isPaused = false;
        _sessionStartedMs = null;
        _canSavePartial = false;
      });
      appSnack(context, 'حُفظت الجلسة كمسودة (أكثر من ١٠ دقائق).');
    }
  }

  Future<void> _handleSessionCompleted(String titleHint) async {
    var plannedTitle = titleHint;
    var plannedMin = 25;
    var startedMs = DateTime.now().millisecondsSinceEpoch;
    await FocusForegroundService.readSessionMeta(
      onData: (t, pm, sm) {
        plannedTitle = t;
        plannedMin = pm;
        startedMs = sm;
      },
    );
    await FocusForegroundService.clearAllSessionPrefs();
    if (!mounted) return;
    setState(() {
      _liveRemainSec = null;
      _isPaused = false;
      _sessionStartedMs = null;
      _canSavePartial = false;
    });

    final session = WorkSessionItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: plannedTitle,
      plannedMinutes: plannedMin,
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedMs),
      endedAt: DateTime.now(),
      completed: true,
    );
    await ref.read(workSessionsProvider.notifier).addSession(session);

    final quote = MotivationQuotes.randomLine();
    await ref.read(notificationServiceProvider).showFocusSessionComplete(
          sessionTitle: plannedTitle,
          body: quote,
        );
    lightSuccessHaptic();
    if (mounted) {
      appSnack(context, 'انتهت الجلسة — $quote');
    }
  }

  Future<void> _pauseSession() async {
    await FocusForegroundService.pauseFromApp();
    await _refreshSessionUi();
    mediumHaptic();
    if (mounted) appSnack(context, 'أوقفت الجلسة مؤقتاً — استخدم «استئناف» أو الأزرار في الإشعار.');
  }

  Future<void> _resumeSession() async {
    final ok = await FocusForegroundService.resumePaused();
    if (!ok && mounted) {
      appSnack(context, 'تعذر الاستئناف.');
      return;
    }
    await _refreshSessionUi();
    lightSuccessHaptic();
    if (mounted) appSnack(context, 'استُؤنفت الجلسة.');
  }

  Future<void> _cancelSession() async {
    await FocusForegroundService.cancelCompletely();
    setState(() {
      _liveRemainSec = null;
      _isPaused = false;
      _sessionStartedMs = null;
      _canSavePartial = false;
    });
    mediumHaptic();
    if (mounted) appSnack(context, 'أُلغيت الجلسة.');
  }

  Future<void> _savePartialFromApp() async {
    var title = 'جلسة تركيز';
    var planned = 25;
    var startedMs = DateTime.now().millisecondsSinceEpoch;
    await FocusForegroundService.readSessionMeta(
      onData: (t, p, s) {
        title = t;
        planned = p;
        startedMs = s;
      },
    );
    if (!mounted) return;
    final elapsed = DateTime.now().millisecondsSinceEpoch - startedMs;
    if (elapsed < 600000) {
      appSnack(context, 'الحفظ الجزئي يظهر بعد مرور ١٠ دقائق على بدء الجلسة.');
      return;
    }
    await FocusForegroundService.cancelCompletely();
    await ref.read(workSessionsProvider.notifier).addSession(
          WorkSessionItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: title,
            plannedMinutes: planned,
            startedAt: DateTime.fromMillisecondsSinceEpoch(startedMs),
            endedAt: DateTime.now(),
            completed: false,
          ),
        );
    setState(() {
      _liveRemainSec = null;
      _isPaused = false;
      _sessionStartedMs = null;
      _canSavePartial = false;
    });
    lightSuccessHaptic();
    if (mounted) appSnack(context, 'حُفظت الجلسة بالوقت المنقضي.');
  }

  Future<void> _openStartFlow() async {
    if (await FocusForegroundService.hasBlockingSession()) {
      if (mounted) {
        appSnack(
          context,
          'هناك جلسة نشطة أو موقوفة. أكملها أو ألغِها قبل بدء جلسة جديدة.',
        );
      }
      return;
    }

    await FocusForegroundService.requestNotificationIfNeeded();
    if (!mounted) return;

    final nameController = TextEditingController(text: 'جلسة تركيز');
    var minutes = 25;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('بدء جلسة تركيز', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم الجلسة'),
                  ),
                  const SizedBox(height: 12),
                  Text('المدة', style: Theme.of(ctx).textTheme.labelLarge),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [15, 25, 45, 50].map((m) {
                      return ChoiceChip(
                        label: Text('$m د'),
                        selected: minutes == m,
                        onSelected: (sel) {
                          if (sel) setModal(() => minutes = m);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'أو مدة مخصصة (دقائق)',
                      hintText: 'مثال: 60',
                    ),
                    onChanged: (val) {
                      final m = int.tryParse(val);
                      if (m != null && m > 0) {
                        setModal(() => minutes = m);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (Platform.isAndroid)
                    Text(
                      'الإشعار: إيقاف مؤقت ثم «استئناف»، أو إلغاء، أو حفظ بعد ١٠ د.',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    )
                  else
                    Text(
                      'على هذا الجهاز تُفتح جلسة داخل التطبيق.',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final title = nameController.text.trim().isEmpty
                          ? 'جلسة تركيز'
                          : nameController.text.trim();
                      final started = await FocusForegroundService.startCountdown(
                        title: title,
                        plannedMinutes: minutes,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!started) {
                        if (await FocusForegroundService.hasBlockingSession() && mounted) {
                          appSnack(
                            context,
                            'أنهِ الجلسة الحالية قبل بدء أخرى.',
                          );
                        } else if (mounted) {
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (c2) => FocusSessionSheet(
                              initialName: title,
                              initialMinutes: minutes,
                              onComplete: (s) {
                                ref.read(workSessionsProvider.notifier).addSession(s);
                                if (mounted) {
                                  appSnack(
                                    context,
                                    s.completed
                                        ? 'تم تسجيل الجلسة — أحسنت!'
                                        : 'سُجّلت الجلسة كمتوقفة مبكراً.',
                                  );
                                }
                              },
                            ),
                          );
                        }
                        return;
                      }
                      if (!mounted) return;
                      setState(() {
                        _liveRemainSec = minutes * 60;
                        _isPaused = false;
                        _sessionStartedMs = DateTime.now().millisecondsSinceEpoch;
                        _canSavePartial = false;
                      });
                      appSnack(context, 'المؤقت يعمل — راقب الإشعار والاختصارات.');
                    },
                    child: const Text('بدء'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    await _refreshSessionUi();
  }

  String _formatRemain(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(workSessionsProvider);
    final hasSession = _liveRemainSec != null && _liveRemainSec! > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('جلسات التركيز')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _openStartFlow();
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('جلسة جديدة'),
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          final sorted = [...sessions]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
          return Column(
            children: [
              if (hasSession || _isPaused)
                Card(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isPaused
                                  ? Icons.play_circle_filled_rounded
                                  : Icons.timer_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 36,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isPaused
                                        ? 'موقوف مؤقتاً — ${_formatRemain(_liveRemainSec!)}'
                                        : 'جلسة نشطة — ${_formatRemain(_liveRemainSec!)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isPaused
                                        ? 'في الإشعار: استئناف · إلغاء · حفظ (بعد ١٠د)'
                                        : 'في الإشعار: إيقاف مؤقت · إلغاء · حفظ',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 360;
                            final cancelStyle = OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 1.5,
                              ),
                              backgroundColor: Theme.of(context).colorScheme.surface,
                            );
                            if (narrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!_isPaused && hasSession) ...[
                                    FilledButton.tonal(
                                      onPressed: _pauseSession,
                                      child: const Text('إيقاف مؤقت'),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton(
                                      style: cancelStyle,
                                      onPressed: _cancelSession,
                                      child: const Text('إلغاء الجلسة'),
                                    ),
                                    const SizedBox(height: 8),
                                    FilledButton(
                                      onPressed: _canSavePartial ? _savePartialFromApp : null,
                                      child: const Text('حفظ جزئي'),
                                    ),
                                  ],
                                  if (_isPaused) ...[
                                    FilledButton(
                                      onPressed: _resumeSession,
                                      child: const Text('استئناف'),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton(
                                      style: cancelStyle,
                                      onPressed: _cancelSession,
                                      child: const Text('إلغاء الجلسة'),
                                    ),
                                    const SizedBox(height: 8),
                                    FilledButton.tonal(
                                      onPressed: _canSavePartial ? _savePartialFromApp : null,
                                      child: const Text('حفظ جزئي'),
                                    ),
                                  ],
                                ],
                              );
                            }
                            return Row(
                              children: [
                                if (!_isPaused && hasSession) ...[
                                  Expanded(
                                    child: FilledButton.tonal(
                                      onPressed: _pauseSession,
                                      child: const Text('إيقاف مؤقت'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: cancelStyle,
                                      onPressed: _cancelSession,
                                      child: const Text('إلغاء'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _canSavePartial ? _savePartialFromApp : null,
                                      child: const Text('حفظ جزئي'),
                                    ),
                                  ),
                                ],
                                if (_isPaused) ...[
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _resumeSession,
                                      child: const Text('استئناف'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: cancelStyle,
                                      onPressed: _cancelSession,
                                      child: const Text('إلغاء'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.tonal(
                                      onPressed: _canSavePartial ? _savePartialFromApp : null,
                                      child: const Text('حفظ جزئي'),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: sorted.isEmpty && !hasSession && !_isPaused
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.center_focus_strong,
                                size: 56,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ابدأ جلسة تركيزٍ عميقة.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                MotivationQuotes.randomLine(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final s = sorted[i];
                          return Card(
                            child: ListTile(
                              title: Text(s.name),
                              subtitle: Text(
                                '${DateFormat('EEEE d MMM · HH:mm', 'ar').format(s.startedAt)} — '
                                '${s.plannedMinutes} دقيقة مخططة — ${s.completed ? 'مكتملة' : 'متوقفة'}',
                              ),
                              trailing: s.completed
                                  ? Icon(Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary)
                                  : Icon(Icons.pause_circle_outline,
                                      color: Theme.of(context).colorScheme.outline),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذر التحميل: $e')),
      ),
    );
  }
}
