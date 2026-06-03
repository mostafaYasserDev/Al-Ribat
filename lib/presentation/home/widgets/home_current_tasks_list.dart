import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/ui_confirm.dart';
import '../../../core/ui_feedback.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/prayer_schedule.dart';
import '../../../domain/entities/task_item.dart';
import '../../widgets/add_task_sheet.dart'; // We'll assume _HomeTaskEditDialog needs to be accessed, actually it's in home_screen.dart!

// We can move _HomeTaskEditDialog to its own file or keep it simple.
// Since _HomeTaskEditDialog is private in home_screen.dart, we might need to expose it or move it here.
