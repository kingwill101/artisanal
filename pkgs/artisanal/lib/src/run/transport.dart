import '../tui/runtime.dart' show MouseMode, ProgramOptions;

/// Transport selection for [serveWidgetApp].
enum Transport {
  /// Serve via browser websocket.
  browser,

  /// Serve via raw TCP socket.
  socket,
}

/// Common interface for widget app host servers.
///
/// Both [BrowserTerminalHostServer] and [SocketTerminalHostServer] implement
/// this interface so [serveWidgetApp] can return a single type regardless of
/// the chosen [Transport].
abstract interface class WidgetAppHostServer {
  /// Closes the server and releases resources.
  ///
  /// When [force] is `true`, active sessions are terminated immediately.
  Future<void> close({bool force = false});
}

/// Default [ProgramOptions] for widget apps.
///
/// Enables alt-screen, passive hover mouse reporting, and disables startup
/// probes so interactive widget UIs do not defer early repaints behind
/// terminal capability probing.
const ProgramOptions defaultWidgetProgramOptions = ProgramOptions(
  altScreen: true,
  mouseMode: MouseMode.allMotion,
  startupProbes: false,
);
