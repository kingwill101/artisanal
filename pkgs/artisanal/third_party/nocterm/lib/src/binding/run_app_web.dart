import 'dart:async';

import 'package:nocterm/nocterm.dart'
    hide StdioBackend, SocketBackend, WebBackend;
import 'package:nocterm/src/backend/web_backend.dart';
import 'package:nocterm/src/backend/terminal.dart' as term;

/// Run a TUI application on web platform.
Future<void> runAppImpl(
  Component app, {
  bool enableHotReload = true,
  TerminalBackend? backend,
}) async {
  // Wrap the user's app with DebugOverlay so Ctrl+G toggle works out of the box
  final wrappedApp = DebugOverlay(child: app);

  final effectiveBackend = backend ?? WebBackend();
  final terminal = term.Terminal(effectiveBackend);
  // TerminalBinding is exported from package:nocterm/nocterm.dart
  final binding = TerminalBinding(terminal);

  binding.initialize();
  binding.attachRootComponent(wrappedApp);

  // Hot reload not supported on web
  // No log server on web

  await binding.runEventLoop();
}
