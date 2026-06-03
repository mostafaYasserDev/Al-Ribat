import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<void> bootstrap() async {
  await Hive.initFlutter();
  await Hive.openBox<String>('tasks_box');
  await Hive.openBox<String>('meta_box');
  await Hive.openBox<String>('reflections_box');
  await Hive.openBox<String>('habits_box');
  await Hive.openBox<String>('activities_box');
  await Hive.openBox<String>('work_sessions_box');
  await initializeDateFormatting('ar');
  tzDataInit();
  await _configureTimezone();
}

void tzDataInit() {
  tzdata.initializeTimeZones();
}

/// IANA `Etc/GMT` names use inverted signs vs «UTC±N». See `tzdata` `etcetera`.
String? _etcGmtIdForOffset(Duration offset) {
  final totalMinutes = offset.inMinutes;
  if (totalMinutes % 60 != 0) return null;
  final h = totalMinutes ~/ 60;
  if (h == 0) return 'Etc/UTC';
  final sign = h > 0 ? '-' : '+';
  final absH = h.abs();
  return 'Etc/GMT$sign$absH';
}

Future<void> _configureTimezone() async {
  bool tryLocation(String name) {
    try {
      tz.setLocalLocation(tz.getLocation(name));
      return true;
    } catch (_) {
      return false;
    }
  }

  try {
    final name = await FlutterTimezone.getLocalTimezone();
    if (name.isNotEmpty) {
      if (tryLocation(name)) return;
      final normalized = name.replaceAll(' ', '_');
      if (normalized != name && tryLocation(normalized)) return;
    }
  } catch (_) {}

  final etcId = _etcGmtIdForOffset(DateTime.now().timeZoneOffset);
  if (etcId != null && tryLocation(etcId)) return;

  tz.setLocalLocation(tz.UTC);
}
