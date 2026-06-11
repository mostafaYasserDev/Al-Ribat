import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../application/providers.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/app_settings.dart';
import '../../services/cloud_sync_service.dart';
import '../focus/focus_sessions_screen.dart';
import '../history/reflection_history_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    ReflectionHistoryScreen(),
    FocusSessionsScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybeAskLocationMode();
      await _maybeShowSyncWelcome();
    });
  }

  Future<void> _maybeShowSyncWelcome() async {
    if (!mounted) return;
    final box = Hive.box<String>('meta_box');
    if (box.get('sync_welcome_v1') == '1') return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حفظ بياناتك ومزامنتها'),
        content: const Text(
          'يمكنك تسجيل الدخول بحساب Google (اختياري) لمزامنة بياناتك سحابيًا عبر Firebase.\n\n'
          'أو يمكنك حفظ نسخة احتياطية بصيغة JSON من الإعدادات في أي وقت — دون الحاجة لتسجيل الدخول.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await box.put('sync_welcome_v1', '1');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('لاحقًا'),
          ),
          FilledButton(
            onPressed: () async {
              await box.put('sync_welcome_v1', '1');
              if (ctx.mounted) Navigator.pop(ctx);
              try {
                await CloudSyncService.signInWithGoogle();
                if (mounted) {
                  appSnack(context, 'تم تسجيل الدخول. يمكنك المزامنة من الإعدادات.');
                }
              } catch (e) {
                if (mounted) {
                  appSnack(context, 'تعذر تسجيل الدخول: $e');
                }
              }
            },
            child: const Text('تسجيل الدخول بـ Google'),
          ),
        ],
      ),
    );
  }

  Future<void> _maybeAskLocationMode() async {
    if (!mounted) return;
    final box = Hive.box<String>('meta_box');
    if (box.get('location_pref_v1') == '1') return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('ضبط الموقع لأوقات الصلاة'),
        content: const Text(
          'هل تريد ضبط الموقع تلقائيًا (GPS) أم يدويًا بالبحث عن مدينتك أو حيّك؟',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final cur = ref.read(settingsProvider).valueOrNull ?? AppSettings.defaults;
              var permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }
              if (permission == LocationPermission.denied ||
                  permission == LocationPermission.deniedForever) {
                if (ctx.mounted) {
                  appSnack(
                    ctx,
                    'يلزم منح صلاحية الموقع لاختيار الوضع التلقائي.',
                  );
                }
                return;
              }
              await ref.read(settingsProvider.notifier).updateSettings(
                    cur.copyWith(prayerLocationMode: PrayerLocationMode.automatic),
                  );
              await box.put('location_pref_v1', '1');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('تلقائي'),
          ),
          FilledButton(
            onPressed: () async {
              if (ctx.mounted) Navigator.pop(ctx);
              final picked = await _pickManualLocationDialog();
              if (picked == null) return;
              final cur = ref.read(settingsProvider).valueOrNull ?? AppSettings.defaults;
              await ref.read(settingsProvider.notifier).updateSettings(
                    cur.copyWith(
                      prayerLocationMode: PrayerLocationMode.manual,
                      manualLatitude: picked.$1.latitude,
                      manualLongitude: picked.$1.longitude,
                      manualLocationLabel: picked.$2,
                    ),
                  );
              await box.put('location_pref_v1', '1');
              if (mounted) {
                appSnack(context, 'تم ضبط الموقع يدويًا: ${picked.$2}');
              }
            },
            child: const Text('يدوي'),
          ),
        ],
      ),
    );
  }

  Future<(Location, String)?> _pickManualLocationDialog() async {
    final controller = TextEditingController();
    final picked = await showDialog<(Location, String)>(
      context: context,
      builder: (ctx) {
        var loading = false;
        List<Location> results = const [];
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('اختيار يدوي للموقع'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'مثال: الرباط، المغرب',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                                final q = controller.text.trim();
                                if (q.isEmpty) return;
                                setLocal(() => loading = true);
                                try {
                                  final found = await locationFromAddress(q);
                                  setLocal(() => results = found.take(5).toList());
                                } catch (_) {
                                  setLocal(() => results = const []);
                                } finally {
                                  setLocal(() => loading = false);
                                }
                              },
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: const Text('بحث'),
                      ),
                    ),
                    if (results.isNotEmpty) const SizedBox(height: 10),
                    ...results.asMap().entries.map(
                      (e) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.place_outlined),
                        title: Text(
                          '${e.value.latitude.toStringAsFixed(4)}, ${e.value.longitude.toStringAsFixed(4)}',
                        ),
                        subtitle: Text('نتيجة ${e.key + 1}'),
                        onTap: () async {
                          String label = controller.text.trim();
                          try {
                            final marks =
                                await placemarkFromCoordinates(e.value.latitude, e.value.longitude);
                            if (marks.isNotEmpty) {
                              final p = marks.first;
                              final parts = <String>[
                                if ((p.locality ?? '').trim().isNotEmpty) p.locality!,
                                if ((p.country ?? '').trim().isNotEmpty) p.country!,
                              ];
                              if (parts.isNotEmpty) label = parts.join('، ');
                            }
                          } catch (_) {}
                          if (ctx.mounted) Navigator.pop(ctx, (e.value, label));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'اليوم'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'الحالات المزاجية'),
          NavigationDestination(
            icon: Icon(Icons.center_focus_strong_outlined),
            label: 'التركيز',
          ),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'الإحصائيات'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
        onDestinationSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}
