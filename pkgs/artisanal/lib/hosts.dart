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
export 'src/terminal/backend_io_stub.dart'
    if (dart.library.io) 'src/terminal/backend_io_impl.dart'
    show StdioTerminalBackend, SocketTerminalBackend;
export 'src/terminal/bridge_protocol_stub.dart'
    if (dart.library.io) 'src/terminal/bridge_protocol.dart'
    show
        TerminalBridgeMessageType,
        TerminalBridgeMessage,
        TerminalBridgeJsonChannel,
        JsonTerminalBackend,
        WebSocketTerminalBackend;
export 'src/terminal/browser_host_stub.dart'
    if (dart.library.io) 'src/terminal/browser_host.dart'
    show BrowserTerminalSessionHandler, BrowserTerminalHostServer;
export 'src/terminal/socket_host_stub.dart'
    if (dart.library.io) 'src/terminal/socket_host.dart'
    show SocketTerminalSessionHandler, SocketTerminalHostServer;
