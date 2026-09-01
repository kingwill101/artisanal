/// Terminal lifecycle, cursor, and native console integration.
///
/// Import this entrypoint when managing a terminal session. Lower-level frame
/// construction, input, and rendering APIs remain available from the focused
/// `core.dart`, `input.dart`, and `rendering.dart` entrypoints.
///
/// {@category Ultraviolet}
library;

export 'src/uv/cursor.dart';
export 'src/uv/terminal.dart';
export 'src/uv/terminal_graphics.dart';
export 'src/uv/terminal_windows_io_stub.dart'
    if (dart.library.io) 'src/uv/terminal_windows_io.dart'
    show enableWindowsVtInput, restoreWindowsVtInput;
