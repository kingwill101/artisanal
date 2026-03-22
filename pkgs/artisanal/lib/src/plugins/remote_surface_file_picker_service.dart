import 'dart:async';

import 'remote_surface_host_connection.dart';
import 'remote_surface_protocol.dart';

typedef RemotePluginFilePickerHandler =
    FutureOr<List<String>?> Function(RemotePluginFilePickerRequest request);

/// Host-side file picker responder for one remote plugin connection.
///
/// This binds to [RemotePluginHostConnection.otherMessages] and lets plugins
/// ask the host to open a file or directory picker using host-owned UI.
final class RemotePluginFilePickerHostService {
  RemotePluginFilePickerHostService.bind(this.connection, {this.pickPaths}) {
    _subscription = connection.otherMessages.listen((message) {
      switch (message) {
        case RemotePluginFilePickerRequest():
          unawaited(_handlePick(message));
        default:
          return;
      }
    }, cancelOnError: false);
  }

  final RemotePluginHostConnection connection;
  final RemotePluginFilePickerHandler? pickPaths;

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;

  Future<void> _handlePick(RemotePluginFilePickerRequest request) async {
    if (_disposed) {
      return;
    }

    if (pickPaths == null) {
      await _send(
        RemotePluginFilePickerResponse(
          requestId: request.requestId,
          error: 'File picker is not available.',
        ),
      );
      return;
    }

    try {
      final paths = await pickPaths!(request);
      await _send(
        RemotePluginFilePickerResponse(
          requestId: request.requestId,
          paths: paths ?? const <String>[],
          canceled: paths == null,
        ),
      );
    } catch (error) {
      await _send(
        RemotePluginFilePickerResponse(
          requestId: request.requestId,
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
