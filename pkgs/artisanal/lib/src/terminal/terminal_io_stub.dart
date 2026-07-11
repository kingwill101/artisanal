/// Stub for `terminal_io_impl.dart` when `dart:io` is not available.
library;

import 'terminal_base.dart';

/// Web-safe API stub for the native stdio terminal implementation.
class StdioTerminal extends StringTerminal {
  /// Creates a stub terminal on platforms without `dart:io`.
  StdioTerminal({Object? stdout, Object? stdin});
}
