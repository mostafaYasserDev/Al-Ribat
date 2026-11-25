/// Pure Dart utilities for formatting focus durations and countdowns
/// consistently across the timer card, mini-player, mode selector, and history.
abstract final class FocusTimeFormatter {
  /// Formats [totalSeconds] into `HH:MM:SS` when >= 1 hour,
  /// or `MM:SS` when under 1 hour.
  static String formatCountdown(int totalSeconds) {
    final clamped = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = clamped ~/ 3600;
    final minutes = (clamped % 3600) ~/ 60;
    final seconds = clamped % 60;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hh = hours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Formats [totalMinutes] into a readable Arabic duration string,
  /// e.g., `1س 30د`, `2س`, `25د`, or `0د`.
  static String formatDurationReadable(int totalMinutes) {
    final clamped = totalMinutes < 0 ? 0 : totalMinutes;
    final hours = clamped ~/ 60;
    final minutes = clamped % 60;

    if (hours > 0 && minutes > 0) {
      return '$hoursس $minutesد';
    }
    if (hours > 0) {
      return '$hoursس';
    }
    return '$minutesد';
  }
}
