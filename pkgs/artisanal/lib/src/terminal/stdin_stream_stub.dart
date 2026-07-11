/// Stub for `stdin_stream.dart` when `dart:io` is not available.
library;

Stream<List<int>>? get sharedStdinStream => null;
bool get isSharedStdinStreamStarted => false;
void shutdownSharedStdinStream() {}
