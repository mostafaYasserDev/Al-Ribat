import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../application/providers.dart';
import '../../core/activity_schedule.dart';
import '../../core/arabic_duration.dart';
import '../../core/constants/prayer_phase.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/day_state.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/prayer_time.dart';
import '../../services/motivation_quotes.dart';
import '../stats/stats_screen.dart';
import '../widgets/activity_action_tile.dart';
import '../widgets/add_activity_sheet.dart';

part 'sections/home_chrome.dart';
part 'sections/home_content.dart';
part 'sections/home_date_header.dart';
part 'sections/home_helpers.dart';
part 'sections/home_unified_header.dart';
part 'sections/home_selected_activities.dart';
part 'sections/home_state_mixin.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, _HomeScreenStateMixin {}
