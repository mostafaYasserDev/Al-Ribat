import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../application/providers.dart';
import '../../core/app_startup.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/security/app_security.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/app_settings.dart';
import '../../services/app_permissions.dart';
import '../../services/backup_export_service.dart';
import '../../services/cloud_sync_service.dart';
import 'about_app_screen.dart';

// RadioListTile: استخدام groupValue/onChanged ما زال الأساس في القنوات المستقرة؛ التحذير من RadioGroup قيد التطور.
// ignore_for_file: deprecated_member_use

part 'settings/settings_state.dart';
part 'settings/settings_about_section.dart';
part 'settings/settings_backup_section.dart';
part 'settings/settings_notifications_section.dart';
part 'settings/settings_prayer_timing_section.dart';
part 'settings/settings_location_section.dart';
part 'settings/settings_location_permission.dart';
part 'settings/settings_location_search_widgets.dart';
part 'settings/settings_location_logic.dart';
part 'settings/settings_prayer_section.dart';
part 'settings/settings_lock_dialog.dart';
part 'settings/settings_lock_dialog_content.dart';
part 'settings/settings_lock_dialog_actions.dart';
part 'settings/cloud_sync_card.dart';
part 'settings/cloud_sync_content.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.openManualLocationCard = false});

  /// بعد اختيار «يدوي» في أول تشغيل: التمرير إلى بطاقة البحث اليدوي.
  final bool openManualLocationCard;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}
