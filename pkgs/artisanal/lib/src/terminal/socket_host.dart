import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import '../style/color.dart';
import '../tui/model.dart';
import '../tui/program.dart';
import '../tui/program_host_io.dart' show socketHost;
import 'backend.dart';
import 'host_server.dart' show TerminalHostServer;

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
final class SocketTerminalHostServer implements TerminalHostServer {
  SocketTerminalHostServer._({required this.server, required this.onSession}) {
    _subscription = server.listen((socket) {
      unawaited(_handleSession(socket));
    }, cancelOnError: false);
  }

  /// The underlying TCP server.
  final io.ServerSocket server;

  final SocketTerminalSessionHandler onSession;
  late final StreamSubscription<io.Socket> _subscription;
  final Set<io.Socket> _activeSockets = <io.Socket>{};
  final Set<Future<void>> _activeSessions = <Future<void>>{};
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
          host: socketHost(
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
  Uri get uri =>
      Uri(scheme: 'tcp', host: server.address.address, port: server.port);

  /// Encodes a socket-host resize control sequence.
  ///
  /// Clients should emit this whenever their viewport changes so the runtime
  /// receives [WindowSizeMsg] updates.
  static String resizeControlSequence({
    required int width,
    required int height,
  }) =>
      '\x1b]9999;$width;$height\x07';

  /// Encodes [resizeControlSequence] as bytes for transport over a socket.
  static List<int> resizeControlBytes({
    required int width,
    required int height,
    Encoding encoding = utf8,
  }) =>
      encoding.encode(resizeControlSequence(width: width, height: height));

  Future<void> _handleSession(io.Socket socket) async {
    _activeSockets.add(socket);
    Future<void>? session;
    try {
      session = Future<void>.sync(() => onSession(socket));
      _activeSessions.add(session);
      await session;
    } catch (_) {
      // Keep the host alive when a single session handler fails.
    } finally {
      if (session != null) {
        _activeSessions.remove(session);
      }
      _activeSockets.remove(socket);
      socket.destroy();
    }
  }

  @override
  Future<void> close({bool force = false}) async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    await server.close();

    if (force) {
      await Future.wait(
        _activeSockets
            .toList(growable: false)
            .map((socket) => Future.sync(socket.close)),
        eagerError: false,
      );
      for (final socket in _activeSockets.toList(growable: false)) {
        socket.destroy();
      }
    }

    if (_activeSessions.isNotEmpty) {
      await Future.wait(
        _activeSessions.toList(growable: false),
        eagerError: false,
      );
    }
  }
}
