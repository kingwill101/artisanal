import 'dart:io' as io;

import 'dart:async';

import '../terminal/backend_io_impl.dart' show SocketTerminalBackend;
import '../terminal/bridge_protocol.dart'
    show JsonTerminalBackend, WebSocketTerminalBackend;
import '../terminal/backend.dart' show TerminalDimensions;
import '../style/color.dart' show ColorProfile;
import 'program.dart' show ProgramHost;

/// Creates a [ProgramHost] backed by a JSON message channel.
ProgramHost jsonChannelHost({
  required void Function(String message) sendMessage,
  required Stream<Object?> inboundMessages,
  Future<void> Function()? flushMessages,
  Future<void> Function()? closeTransport,
  TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  bool isTerminal = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  ({bool useTabs, bool useBackspace}) movementCaps = const (
    useTabs: false,
    useBackspace: true,
  ),
}) => ProgramHost.backend(
  JsonTerminalBackend(
    sendMessage: sendMessage,
    inboundMessages: inboundMessages,
    flushMessages: flushMessages,
    closeTransport: closeTransport,
    initialSize: initialSize,
    supportsAnsi: supportsAnsi,
    isTerminal: isTerminal,
    colorProfile: colorProfile,
    movementCaps: movementCaps,
  ),
);

/// Creates a [ProgramHost] backed by a WebSocket using the JSON bridge protocol.
ProgramHost webSocketHost(
  io.WebSocket socket, {
  TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  bool isTerminal = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  ({bool useTabs, bool useBackspace}) movementCaps = const (
    useTabs: false,
    useBackspace: true,
  ),
  bool closeSocketOnDispose = true,
}) => ProgramHost.backend(
  WebSocketTerminalBackend(
    socket,
    initialSize: initialSize,
    supportsAnsi: supportsAnsi,
    isTerminal: isTerminal,
    colorProfile: colorProfile,
    movementCaps: movementCaps,
    closeSocketOnDispose: closeSocketOnDispose,
  ),
);

/// Creates a [ProgramHost] backed by a raw Socket for remote or shell-mode terminals.
ProgramHost socketHost(
  io.Socket socket, {
  TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  bool closeSocketOnDispose = true,
}) => ProgramHost.backend(
  SocketTerminalBackend(
    socket,
    initialSize: initialSize,
    supportsAnsi: supportsAnsi,
    colorProfile: colorProfile,
    closeSocketOnDispose: closeSocketOnDispose,
  ),
);
