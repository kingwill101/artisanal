/// Stub for `backend_io_impl.dart` when `dart:io` is not available.
library;

import 'backend.dart' show TerminalBackend;

/// Stub for [StdioTerminalBackend] on web/WASM.
abstract final class StdioTerminalBackend implements TerminalBackend {
  StdioTerminalBackend._();
}

/// Stub for [SocketTerminalBackend] on web/WASM.
abstract final class SocketTerminalBackend implements TerminalBackend {
  SocketTerminalBackend._();
}
