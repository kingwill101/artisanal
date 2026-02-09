// Conditional export for StdioBackend.
// Uses stub on web platforms, real implementation on native.

export 'stdio_backend_stub.dart' if (dart.library.io) 'stdio_backend.dart';
