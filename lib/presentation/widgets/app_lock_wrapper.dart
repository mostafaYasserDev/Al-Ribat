import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../application/providers.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/security/app_security.dart';
import '../../domain/entities/app_settings.dart';

part 'app_lock_wrapper_state.dart';
part 'app_lock_wrapper_auth.dart';
part 'app_lock_wrapper_view.dart';

class AppLockWrapper extends ConsumerStatefulWidget {
  const AppLockWrapper({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}
