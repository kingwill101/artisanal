import 'dart:async';

final StreamController<List<int>> _controller =
    StreamController<List<int>>.broadcast();
bool _shutdown = false;

Stream<List<int>> get sharedStdinStream => _controller.stream;

bool get isSharedStdinStreamStarted => !_shutdown;

Future<void> shutdownSharedStdinStream() async {
  if (_shutdown) return;
  _shutdown = true;
  await _controller.close();
}
