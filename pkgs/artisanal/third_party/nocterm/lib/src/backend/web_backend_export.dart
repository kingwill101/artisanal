// Conditional export for WebBackend.
// Uses stub on native platforms, real implementation on web.

export 'web_backend_stub.dart' if (dart.library.js_interop) 'web_backend.dart';
