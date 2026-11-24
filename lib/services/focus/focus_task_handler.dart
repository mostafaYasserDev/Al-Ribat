part of '../focus_foreground_service.dart';

class FocusCountdownTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onNotificationButtonPressed(String id) => _handleFocusButtonPress(id);

  @override
  void onRepeatEvent(DateTime timestamp) => _handleFocusRepeatEvent(timestamp);

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
