// ignore_for_file: unused_element

import 'msg.dart' show HotReloadStatus;

/// Web stub for hot reload — no-op.
mixin HotReloadMixin {
  bool get _enableHotReload => false;

  void onHotReloadStatus(HotReloadStatus status, {String? detail}) {}

  Future<void> initializeHotReload({
    Duration debounceInterval = const Duration(milliseconds: 500),
  }) async {}

  void stopHotReload() {}

  Future<void> performReassemble();
}
