import 'dart:async';
import 'dart:io';

import 'package:al_ribat/core/errors/error_reporter.dart';
import 'package:al_ribat/features/settings/data/app_settings_model.dart';
import 'package:al_ribat/features/settings/domain/app_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../backup_export_service.dart';

class LocalAutoBackupState {
  const LocalAutoBackupState({
    this.enabled = false,
    this.filePath,
    this.lastSavedAt,
    this.isWriting = false,
    this.lastError,
  });

  final bool enabled;
  final String? filePath;
  final DateTime? lastSavedAt;
  final bool isWriting;
  final String? lastError;

  LocalAutoBackupState copyWith({
    bool? enabled,
    String? filePath,
    DateTime? lastSavedAt,
    bool? isWriting,
    String? lastError,
    bool clearError = false,
  }) {
    return LocalAutoBackupState(
      enabled: enabled ?? this.enabled,
      filePath: filePath ?? this.filePath,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      isWriting: isWriting ?? this.isWriting,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Keeps a live, atomically updated local JSON backup file synchronized whenever
/// any Hive data changes.
abstract final class LocalAutoBackupService {
  static const fileName = 'al_ribat_auto_backup.json';
  static const _lastSavedMetaKey = 'auto_backup_last_at';

  static final ValueNotifier<LocalAutoBackupState> statusNotifier =
      ValueNotifier(const LocalAutoBackupState());

  static final List<StreamSubscription<BoxEvent>> _subscriptions = [];
  static Timer? _debounce;
  static bool _writing = false;
  static bool _pendingWrite = false;
  static String? _customPath;

  @visibleForTesting
  static Directory? overrideDirectoryForTesting;

  static Future<String> resolveTargetPath([String? customPath]) async {
    final trimmed = (customPath ?? _customPath)?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      if (trimmed.toLowerCase().endsWith('.json')) return trimmed;
      final sep = Platform.pathSeparator;
      return trimmed.endsWith(sep)
          ? '$trimmed$fileName'
          : '$trimmed$sep$fileName';
    }
    return defaultFilePath();
  }

  static Future<String> defaultFilePath() async {
    if (overrideDirectoryForTesting != null) {
      return '${overrideDirectoryForTesting!.path}${Platform.pathSeparator}$fileName';
    }
    Directory? dir;
    if (!kIsWeb && Platform.isAndroid) {
      dir = await getExternalStorageDirectory();
    }
    dir ??= await getApplicationDocumentsDirectory();
    final sep = Platform.pathSeparator;
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      return '${dir.path}${sep}Al-Ribat$sep$fileName';
    }
    return '${dir.path}$sep$fileName';
  }

  static AppSettings _readCurrentSettings() {
    if (!Hive.isBoxOpen('meta_box')) return AppSettings.defaults;
    final raw = Hive.box<String>('meta_box').get('settings');
    if (raw == null) return AppSettings.defaults;
    try {
      return AppSettingsModel.fromJson(raw);
    } catch (_) {
      return AppSettings.defaults;
    }
  }

  static DateTime? _readLastSavedAt() {
    if (!Hive.isBoxOpen('meta_box')) return null;
    final raw = Hive.box<String>('meta_box').get(_lastSavedMetaKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> initFromSettings() async {
    final settings = _readCurrentSettings();
    _customPath = settings.autoLocalBackupPath;
    final path = await resolveTargetPath();
    statusNotifier.value = LocalAutoBackupState(
      enabled: settings.autoLocalBackupEnabled,
      filePath: path,
      lastSavedAt: _readLastSavedAt(),
    );
    if (settings.autoLocalBackupEnabled) {
      _startWatching();
      await writeNow();
    } else {
      await _stopWatching();
    }
  }

  static Future<void> applySettings(AppSettings settings) async {
    _customPath = settings.autoLocalBackupPath;
    final path = await resolveTargetPath();
    statusNotifier.value = statusNotifier.value.copyWith(
      enabled: settings.autoLocalBackupEnabled,
      filePath: path,
      clearError: true,
    );
    if (settings.autoLocalBackupEnabled) {
      _startWatching();
      await writeNow();
    } else {
      await _stopWatching();
    }
  }

  static void _startWatching() {
    if (_subscriptions.isNotEmpty) return;
    const boxNames = [
      'activities_box',
      'reflections_box',
      'work_sessions_box',
      'meta_box',
    ];
    for (final name in boxNames) {
      if (!Hive.isBoxOpen(name)) continue;
      final box = Hive.box<String>(name);
      _subscriptions.add(
        box.watch().listen((event) {
          if (name == 'meta_box') {
            final k = event.key?.toString() ?? '';
            if (k == _lastSavedMetaKey ||
                k == 'cached_gps_lat' ||
                k == 'cached_gps_lng') {
              return;
            }
          }
          _scheduleDebouncedWrite();
        }),
      );
    }
  }

  static Future<void> _stopWatching() async {
    _debounce?.cancel();
    _debounce = null;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  static void _scheduleDebouncedWrite() {
    if (!statusNotifier.value.enabled) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(writeNow());
    });
  }

  static Future<String> writeNow() async {
    if (_writing) {
      _pendingWrite = true;
      return statusNotifier.value.filePath ?? await resolveTargetPath();
    }
    _writing = true;
    statusNotifier.value = statusNotifier.value.copyWith(
      isWriting: true,
      clearError: true,
    );

    try {
      final path = await resolveTargetPath();
      final json = await BackupExportService.buildJsonString();
      await _atomicWrite(path, json);
      final now = DateTime.now();
      if (Hive.isBoxOpen('meta_box')) {
        await Hive.box<String>('meta_box')
            .put(_lastSavedMetaKey, now.toIso8601String());
      }
      statusNotifier.value = statusNotifier.value.copyWith(
        filePath: path,
        lastSavedAt: now,
        isWriting: false,
        clearError: true,
      );
      return path;
    } catch (e, st) {
      reportError('LocalAutoBackupService', e, st);
      statusNotifier.value = statusNotifier.value.copyWith(
        isWriting: false,
        lastError: e.toString(),
      );
      rethrow;
    } finally {
      _writing = false;
      if (_pendingWrite) {
        _pendingWrite = false;
        unawaited(writeNow());
      }
    }
  }

  static Future<void> _atomicWrite(String path, String contents) async {
    final target = File(path);
    await target.parent.create(recursive: true);
    final tmp = File('$path.tmp');
    await tmp.writeAsString(contents, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await tmp.rename(path);
  }

  static Future<bool> shareAutoBackupFile() async {
    final path = await writeNow();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Share.shareXFiles([XFile(path)], subject: fileName);
      return true;
    }

    final parentDir = File(path).parent.path;
    final dest = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ نسخة من الملف التلقائي',
      fileName: fileName,
      initialDirectory: await Directory(parentDir).exists() ? parentDir : null,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (dest == null) return false;
    final outPath = dest.toLowerCase().endsWith('.json') ? dest : '$dest.json';
    await File(path).copy(outPath);
    return true;
  }

  static Future<void> openContainingFolder() async {
    final path = statusNotifier.value.filePath ?? await resolveTargetPath();
    final dir = File(path).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [dir.path]);
    } else if (Platform.isMacOS) {
      await Process.start('open', [dir.path]);
    } else if (Platform.isWindows) {
      await Process.start('explorer', [dir.path]);
    }
  }

  static Future<void> restoreFromAutoBackup({
    required BackupRestoreMode mode,
  }) async {
    final path = statusNotifier.value.filePath ?? await resolveTargetPath();
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('لا يوجد ملف حفظ تلقائي بعد.');
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      throw const FormatException('ملف الحفظ التلقائي فارغ.');
    }
    await BackupExportService.restoreFromJsonString(raw, mode: mode);
  }

  @visibleForTesting
  static Future<void> resetForTesting() async {
    await _stopWatching();
    _customPath = null;
    overrideDirectoryForTesting = null;
    statusNotifier.value = const LocalAutoBackupState();
  }
}
