import 'dart:async';

import 'remote_surface_protocol.dart';
import 'remote_surface_session.dart';
import 'remote_surface_state.dart';

/// Host-side controller that binds a session to a surface store.
///
/// Surface lifecycle and frame messages are applied to [surfaces]
/// automatically. Non-surface plugin messages are forwarded through
/// [otherMessages] so hosts can handle custom plugin traffic separately.
final class RemotePluginSurfaceController {
  RemotePluginSurfaceController.bind(
    this.session, {
    RemotePluginSurfaceStore? surfaces,
  }) : surfaces = surfaces ?? RemotePluginSurfaceStore() {
    _subscription = session.messages.listen(
      (message) {
        if (_isSurfaceMessage(message)) {
          this.surfaces.apply(message);
          if (!_disposed) {
            _surfaceMessages.add(message);
          }
          return;
        }

        if (!_disposed) {
          _otherMessages.add(message);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_disposed) {
          _surfaceMessages.addError(error, stackTrace);
          _otherMessages.addError(error, stackTrace);
        }
      },
      onDone: () {
        if (!_disposed) {
          _surfaceMessages.close();
          _otherMessages.close();
        }
      },
      cancelOnError: false,
    );
  }

  final RemotePluginSession session;
  final RemotePluginSurfaceStore surfaces;
  final StreamController<RemotePluginMessage> _surfaceMessages =
      StreamController<RemotePluginMessage>.broadcast();
  final StreamController<RemotePluginMessage> _otherMessages =
      StreamController<RemotePluginMessage>.broadcast();

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;

  /// Surface lifecycle and frame messages after they have been applied.
  Stream<RemotePluginMessage> get surfaceMessages => _surfaceMessages.stream;

  /// Non-surface plugin messages that the host may want to handle separately.
  Stream<RemotePluginMessage> get otherMessages => _otherMessages.stream;

  /// Disposes the controller subscription without closing the underlying session.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _subscription?.cancel();
    await _surfaceMessages.close();
    await _otherMessages.close();
  }
}

bool _isSurfaceMessage(RemotePluginMessage message) {
  return switch (message) {
    RemotePluginSurfaceOpen() ||
    RemotePluginSurfaceResize() ||
    RemotePluginFrame() ||
    RemotePluginSurfaceClose() => true,
    _ => false,
  };
}
