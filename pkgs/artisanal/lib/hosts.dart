/// Stable backend and host entrypoint for interactive terminal apps.
///
/// Prefer this library when you want the supported embedding and transport
/// surface without importing the broader `package:artisanal/tui.dart` barrel.
///
/// This entrypoint includes:
///
/// - `ProgramHost` for stdio, embedded, bridge, websocket, and socket runs
/// - backend terminals such as `EmbeddedTerminalBackend` and `SocketTerminalBackend`
/// - `TerminalBridge` and the JSON bridge protocol types
/// - reusable browser and raw TCP host servers
library;

export 'src/tui/tui.dart'
    show ProgramHostResolver, ProgramHostBinding, ProgramHost, ProgramOptions;
export 'src/terminal/terminal.dart'
    show
        TerminalDimensions,
        TerminalBackend,
        BackendTerminal,
        EmbeddedTerminalBackend,
        TerminalBridge;
export 'src/terminal/backend_io_impl.dart'
    if (dart.library.html) 'src/terminal/backend_io_stub.dart'
    show StdioTerminalBackend, SocketTerminalBackend;
export 'src/terminal/bridge_protocol.dart'
    if (dart.library.html) 'src/terminal/bridge_protocol_stub.dart'
    show
        TerminalBridgeMessageType,
        TerminalBridgeMessage,
        TerminalBridgeJsonChannel,
        JsonTerminalBackend,
        WebSocketTerminalBackend;
export 'src/terminal/browser_host.dart'
    if (dart.library.html) 'src/terminal/browser_host_stub.dart'
    show BrowserTerminalSessionHandler, BrowserTerminalHostServer;
export 'src/terminal/socket_host.dart'
    if (dart.library.html) 'src/terminal/socket_host_stub.dart'
    show SocketTerminalSessionHandler, SocketTerminalHostServer;
