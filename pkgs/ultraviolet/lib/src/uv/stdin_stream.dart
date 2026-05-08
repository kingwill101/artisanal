export 'stdin_stream_shared.dart' show SharedInputStream;

export 'stdin_stream_stub.dart'
    if (dart.library.io) 'stdin_stream_io.dart'
    if (dart.library.html) 'stdin_stream_web.dart';
