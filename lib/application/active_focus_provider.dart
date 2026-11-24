import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/work_session_item.dart';
import '../services/focus_foreground_service.dart';
import '../services/motivation_quotes.dart';
import 'providers.dart';

part 'parts/active_focus_foreground.dart';
part 'parts/active_focus_session.dart';
part 'parts/active_focus_lifecycle.dart';
part 'parts/active_focus_completion.dart';

class ActiveFocusState {
  final String title;
  final int plannedMinutes;
  final DateTime startedAt;
  final int remainingSeconds;
  final bool isPaused;

  bool get canSavePartial {
    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    return elapsedMs >= 600000; // 10 minutes
  }

  const ActiveFocusState({
    required this.title,
    required this.plannedMinutes,
    required this.startedAt,
    required this.remainingSeconds,
    this.isPaused = false,
  });

  ActiveFocusState copyWith({
    String? title,
    int? plannedMinutes,
    DateTime? startedAt,
    int? remainingSeconds,
    bool? isPaused,
  }) {
    return ActiveFocusState(
      title: title ?? this.title,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      startedAt: startedAt ?? this.startedAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

final activeFocusProvider =
    NotifierProvider<ActiveFocusNotifier, ActiveFocusState?>(
        ActiveFocusNotifier.new);

abstract class _ActiveFocusNotifierBase extends Notifier<ActiveFocusState?> {
  Timer? _ticker;

  void _startInternalTicker();
  Future<void> _completeSession(String titleHint);
  Future<void> _saveSessionRecord({
    required String title,
    required int plannedMinutes,
    required DateTime startedAt,
    required bool completed,
  });
}

class ActiveFocusNotifier extends _ActiveFocusNotifierBase
    with
        _ActiveFocusForeground,
        _ActiveFocusSession,
        _ActiveFocusLifecycle,
        _ActiveFocusCompletion {
  @override
  ActiveFocusState? build() {
    ref.onDispose(() {
      _ticker?.cancel();
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
      }
    });

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
      _checkExistingForegroundSession();
    }

    return null;
  }
}
