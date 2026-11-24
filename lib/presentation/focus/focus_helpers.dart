part of 'focus_sessions_screen.dart';

String _formatRemain(int sec) {
  final m = sec ~/ 60;
  final s = sec % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
