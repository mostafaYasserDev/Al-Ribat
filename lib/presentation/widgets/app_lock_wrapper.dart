import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

class AppLockWrapper extends StatefulWidget {
  const AppLockWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> {
  bool _isLocked = false;
  String? _expectedPin;
  final TextEditingController _pinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  void _checkLock() async {
    final box = Hive.box<String>('meta_box');
    _expectedPin = box.get('app_pin');
    
    _canCheckBiometrics = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    
    if (_expectedPin != null && _expectedPin!.isNotEmpty) {
      setState(() {
        _isLocked = true;
      });
      if (_canCheckBiometrics) {
        _authenticateBiometric();
      }
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'قم بالتحقق لفتح تطبيق الرباط',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated) {
        setState(() {
          _isLocked = false;
        });
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
    }
  }

  void _verifyPin() {
    if (_pinController.text == _expectedPin) {
      setState(() {
        _isLocked = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرمز غير صحيح')),
      );
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) {
      return widget.child;
    }
    
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.teal),
              const SizedBox(height: 16),
              Text(
                'التطبيق مقفل',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('أدخل رمز المرور للوصول إلى التطبيق'),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(letterSpacing: 8, fontSize: 24),
                maxLength: 4,
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  if (val.length == 4) {
                    _verifyPin();
                  }
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _verifyPin,
                child: const Text('دخول'),
              ),
              if (_canCheckBiometrics) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _authenticateBiometric,
                  icon: const Icon(Icons.fingerprint, size: 32),
                  label: const Text('استخدام البصمة'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
