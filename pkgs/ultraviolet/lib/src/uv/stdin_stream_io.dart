import 'dart:io';

import 'stdin_stream_shared.dart';

final SharedInputStream _sharedStdin = SharedInputStream(stdin);

Stream<List<int>> get sharedStdinStream => _sharedStdin.stream;

bool get isSharedStdinStreamStarted => _sharedStdin.isStarted;

Future<void> shutdownSharedStdinStream() => _sharedStdin.shutdown();
