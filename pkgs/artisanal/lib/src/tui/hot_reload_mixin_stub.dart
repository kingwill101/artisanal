import 'msg.dart' show HotReloadStatus;

/// Web stub for hot reload — no-op.
mixin HotReloadMixin {
  void onHotReloadStatus(HotReloadStatus status, {String? detail}) {}

  Future<bool> canInitializeHotReload() async => false;

  Future<void> initializeHotReload({
    Duration debounceInterval = const Duration(milliseconds: 500),
  }) async {}

  Future<void> stopHotReload() async {}

  Future<void> performReassemble();
}
