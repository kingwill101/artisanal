import 'dart:async';

final StreamController<List<int>> _controller =
    StreamController<List<int>>.broadcast();

Stream<List<int>> get sharedStdinStream => _controller.stream;

bool get isSharedStdinStreamStarted => false;

Future<void> shutdownSharedStdinStream() async {
  await _controller.close();
}
