part of '../home_screen.dart';

AppBar _buildHomeAppBar(
  BuildContext context,
  WidgetRef ref,
  String todayStr,
  String nowStr,
  Future<void> Function() onRefresh,
) {
  return AppBar(
    title: GestureDetector(
      onTap: () {
        ref.read(selectedDateProvider.notifier).state = DateTime.now();
      },
      child: const Text('الرباط'),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.bar_chart_rounded),
        tooltip: 'الإحصائيات',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StatsScreen()),
          );
        },
      ),
      if (todayStr != nowStr)
        IconButton(
          icon: const Icon(Icons.today),
          tooltip: 'العودة لليوم',
          onPressed: () {
            ref.read(selectedDateProvider.notifier).state = DateTime.now();
          },
        ),
      IconButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onRefresh();
        },
        icon: const Icon(Icons.refresh),
      ),
    ],
  );
}

Widget _buildHomeFab(
  BuildContext context,
  VoidCallback onPressed,
) {
  return FloatingActionButton.extended(
    heroTag: 'home_fab',
    onPressed: onPressed,
    label: const Text('إضافة نشاط'),
    icon: const Icon(Icons.add),
  );
}

Widget _buildScheduleError(
  BuildContext context,
  Object error, {
  required VoidCallback onRetry,
}) {
  return AppErrorView(
    error: error,
    onRetry: onRetry,
  );
}
