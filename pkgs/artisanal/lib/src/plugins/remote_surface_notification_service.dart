import 'dart:async';

import 'remote_surface_host_connection.dart';
import 'remote_surface_protocol.dart';

typedef RemotePluginNotifier = FutureOr<void> Function(
  RemotePluginNotificationRequest request,
);

/// Host-side notification responder for one remote plugin connection.
///
/// This binds to [RemotePluginHostConnection.otherMessages] and lets plugins
/// ask the host to surface notifications using host-owned UI or logging.
final class RemotePluginNotificationHostService {
  RemotePluginNotificationHostService.bind(
    this.connection, {
    this.notify,
  }) {
    _subscription = connection.otherMessages.listen(
      (message) {
        switch (message) {
          case RemotePluginNotificationRequest():
            unawaited(_handleNotify(message));
          default:
            return;
        }
      },
      cancelOnError: false,
    );
  }

  final RemotePluginHostConnection connection;
  final RemotePluginNotifier? notify;

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;

  Future<void> _handleNotify(RemotePluginNotificationRequest request) async {
    if (_disposed) {
      return;
    }

    if (notify == null) {
      await _send(
        RemotePluginNotificationResponse(
          requestId: request.requestId,
          accepted: false,
          error: 'Notifications are not available.',
        ),
      );
      return;
    }

    try {
      await notify!(request);
      await _send(
        RemotePluginNotificationResponse(requestId: request.requestId),
      );
    } catch (error) {
      await _send(
        RemotePluginNotificationResponse(
          requestId: request.requestId,
          accepted: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _send(RemotePluginMessage message) async {
    if (_disposed) {
      return;
    }
    try {
      await connection.send(message);
    } catch (_) {
      // Ignore late send races after the plugin has already exited.
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _subscription?.cancel();
  }
}
