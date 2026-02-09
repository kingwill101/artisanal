// Conditional export for SocketBackend.
// Uses stub on web platforms, real implementation on native.

export 'socket_backend_stub.dart' if (dart.library.io) 'socket_backend.dart';
