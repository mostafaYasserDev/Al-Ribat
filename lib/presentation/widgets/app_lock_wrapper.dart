import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/errors/error_reporter.dart';
import '../../core/security/app_security.dart';

part 'app_lock_wrapper_state.dart';
part 'app_lock_wrapper_auth.dart';
part 'app_lock_wrapper_view.dart';

class AppLockWrapper extends StatefulWidget {
  const AppLockWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}
