import 'dart:async';

import 'remote_surface_host_connection.dart';
import 'remote_surface_protocol.dart';

typedef RemotePluginUrlOpener = FutureOr<void> Function(Uri uri);

/// Host-side URL opener for one remote plugin connection.
///
/// This binds to [RemotePluginHostConnection.otherMessages] and answers typed
/// URL-open requests so plugins can ask the host to launch external links.
final class RemotePluginOpenUrlHostService {
  RemotePluginOpenUrlHostService.bind(this.connection, {this.openUrl}) {
    _subscription = connection.otherMessages.listen(
      (message) {
        switch (message) {
          case RemotePluginOpenUrlRequest():
            unawaited(_handleOpen(message));
          default:
            return;
        }
      },
      cancelOnError: false,
    );
  }

  final RemotePluginHostConnection connection;
  final RemotePluginUrlOpener? openUrl;

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;

  Future<void> _handleOpen(RemotePluginOpenUrlRequest request) async {
    if (_disposed) {
      return;
    }

    if (openUrl == null) {
      await _send(
        RemotePluginOpenUrlResponse(
          requestId: request.requestId,
          accepted: false,
          error: 'URL opening is not available.',
        ),
      );
      return;
    }

    try {
      await openUrl!(Uri.parse(request.url));
      await _send(RemotePluginOpenUrlResponse(requestId: request.requestId));
    } catch (error) {
      await _send(
        RemotePluginOpenUrlResponse(
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
