import 'dart:async';
import 'dart:typed_data';

import 'pty_spawn_request.dart';

/// Process and terminal operations required by [PtyHarness].
///
/// Implementations may use a native PTY, ConPTY, a remote transport, or a
/// deterministic fake. The output stream must preserve the bytes and ordering
/// observed from the terminal master side.
abstract interface class PtyBackend {
  /// Raw bytes emitted by the child through the PTY master.
  Stream<Uint8List> get output;

  /// Completes with the child process exit code.
  Future<int> get exitCode;

  /// Writes all [bytes] to the PTY master input side.
  Future<void> write(Uint8List bytes);

  /// Changes the terminal size and notifies the attached child as appropriate
  /// for the platform.
  Future<void> resize({required int columns, required int rows});

  /// Requests termination of the attached child process.
  Future<void> kill();

  /// Releases backend resources.
  ///
  /// Implementations should make this method idempotent and should eventually
  /// close [output].
  Future<void> close();
}

/// Creates a backend for a validated [PtySpawnRequest].
typedef PtyBackendFactory = FutureOr<PtyBackend> Function(
  PtySpawnRequest request,
);
