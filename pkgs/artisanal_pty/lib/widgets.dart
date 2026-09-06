/// PTY widgets for `package:artisanal_widgets`.
///
/// Also exports the transport-independent terminal model and input encoder so
/// widget applications normally need only this import.
library;

export 'artisanal_pty.dart';
export 'src/pseudo_terminal_view_stub.dart'
    if (dart.library.io) 'src/pseudo_terminal_view_io.dart';
export 'src/terminal_view.dart';
