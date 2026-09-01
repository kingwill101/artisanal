/// Common lifecycle contract for terminal servers that host programs.
abstract interface class TerminalHostServer {
  /// Closes the server and releases its resources.
  ///
  /// When [force] is `true`, active sessions are terminated immediately.
  Future<void> close({bool force = false});
}
