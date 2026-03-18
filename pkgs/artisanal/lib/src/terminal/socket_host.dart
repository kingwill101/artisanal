import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import '../style/color.dart';
import '../tui/model.dart';
import '../tui/program.dart';
import 'backend.dart';

/// Session handler invoked for each accepted raw socket terminal connection.
typedef SocketTerminalSessionHandler = Future<void> Function(io.Socket socket);

/// Reusable raw socket host server for remote TUI sessions.
///
/// This helper accepts TCP socket connections and can either hand each socket
/// to [onSession] or run a fresh [Model] instance per connection through
/// [serveProgram].
///
/// Resize events are reported out-of-band using
/// `OSC 9999;<cols>;<rows>` terminated by `BEL`.
final class SocketTerminalHostServer {
  SocketTerminalHostServer._({
    required this.server,
    required this.onSession,
  }) {
    _subscription = server.listen(
      (socket) {
        unawaited(_handleSession(socket));
      },
      cancelOnError: false,
    );
  }

  /// The underlying TCP server.
  final io.ServerSocket server;

  final SocketTerminalSessionHandler onSession;
  late final StreamSubscription<io.Socket> _subscription;
  bool _closed = false;

  /// Binds a socket host server.
  static Future<SocketTerminalHostServer> bind({
    io.InternetAddress? address,
    int port = 2323,
    bool v6Only = false,
    bool shared = false,
    required SocketTerminalSessionHandler onSession,
  }) async {
    final server = await io.ServerSocket.bind(
      address ?? io.InternetAddress.loopbackIPv4,
      port,
      v6Only: v6Only,
      shared: shared,
    );
    return SocketTerminalHostServer._(server: server, onSession: onSession);
  }

  /// Binds a socket host server that runs a fresh program per connection.
  static Future<SocketTerminalHostServer> serveProgram<M extends Model>({
    io.InternetAddress? address,
    int port = 2323,
    bool v6Only = false,
    bool shared = false,
    TerminalDimensions initialSize = const (width: 80, height: 24),
    bool supportsAnsi = true,
    ColorProfile colorProfile = ColorProfile.trueColor,
    required M Function() modelBuilder,
    ProgramOptions options = const ProgramOptions(
      altScreen: false,
      frameTick: false,
      signalHandlers: false,
    ),
  }) {
    return bind(
      address: address,
      port: port,
      v6Only: v6Only,
      shared: shared,
      onSession: (socket) async {
        await runProgram(
          modelBuilder(),
          options: options,
          host: ProgramHost.socket(
            socket,
            initialSize: initialSize,
            supportsAnsi: supportsAnsi,
            colorProfile: colorProfile,
            closeSocketOnDispose: false,
          ),
        );
      },
    );
  }

  /// URI for connecting remote terminal clients.
  Uri get uri => Uri(
    scheme: 'tcp',
    host: server.address.address,
    port: server.port,
  );

  /// Encodes a socket-host resize control sequence.
  ///
  /// Clients should emit this whenever their viewport changes so the runtime
  /// receives [WindowSizeMsg] updates.
  static String resizeControlSequence({
    required int width,
    required int height,
  }) => '\x1b]9999;$width;$height\x07';

  /// Encodes [resizeControlSequence] as bytes for transport over a socket.
  static List<int> resizeControlBytes({
    required int width,
    required int height,
    Encoding encoding = utf8,
  }) => encoding.encode(
    resizeControlSequence(width: width, height: height),
  );

  Future<void> _handleSession(io.Socket socket) async {
    try {
      await onSession(socket);
    } finally {
      socket.destroy();
    }
  }

  /// Closes the underlying TCP server.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    await server.close();
  }
}
