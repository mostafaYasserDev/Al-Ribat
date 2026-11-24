part of 'app_lock_wrapper.dart';

extension _AppLockWrapperView on _AppLockWrapperState {
  Widget _buildLockedScreen(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
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
                SizedBox(
                  width: 220,
                  child: TextField(
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
      ),
    );
  }
}
