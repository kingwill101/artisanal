import '../terminal/terminal.dart';

/// Whether a console operation should use cursor-driven interactive output.
///
/// The terminal is resolved lazily so non-interactive consoles do not allocate
/// or inspect a terminal merely to select their plain-output fallback.
bool supportsInteractiveConsole(
  bool interactive,
  Terminal Function() terminal,
) => interactive && terminal().supportsAnsi;
