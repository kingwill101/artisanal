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
        StdioTerminalBackend,
        EmbeddedTerminalBackend,
        TerminalBridge,
        SocketTerminalBackend,
        TerminalBridgeMessageType,
        TerminalBridgeMessage,
        TerminalBridgeJsonChannel,
        JsonTerminalBackend,
        WebSocketTerminalBackend,
        BrowserTerminalSessionHandler,
        BrowserTerminalHostServer,
        SocketTerminalSessionHandler,
        SocketTerminalHostServer;
