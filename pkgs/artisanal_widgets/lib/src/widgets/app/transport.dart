import 'package:artisanal/runtime.dart'
    show MouseMode, ProgramDiagnosticsOptions, ProgramOptions;

/// Transport selection for [serveWidgetApp].
enum Transport {
  /// Serve via browser websocket.
  browser,

  /// Serve via raw TCP socket.
  socket,
}

/// Default [ProgramOptions] for widget apps.
///
/// Enables alt-screen, passive hover mouse reporting, and disables startup
/// probes so interactive widget UIs do not defer early repaints behind
/// terminal capability probing.
final ProgramOptions defaultWidgetProgramOptions = ProgramOptions(
  altScreen: true,
  mouseMode: MouseMode.allMotion,
  startupProbes: false,
  diagnostics: ProgramDiagnosticsOptions(captureOutput: false),
);
