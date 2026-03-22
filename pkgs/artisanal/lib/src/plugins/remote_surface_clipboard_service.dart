import 'dart:async';

import 'remote_surface_host_connection.dart';
import 'remote_surface_protocol.dart';

typedef RemotePluginClipboardReader =
    FutureOr<String?> Function(String selection);

typedef RemotePluginClipboardWriter =
    FutureOr<void> Function(String selection, String text);

/// Host-side clipboard responder for one remote plugin connection.
///
/// This binds to [RemotePluginHostConnection.otherMessages] and answers typed
/// clipboard request messages without the host needing to manually loop over
/// plugin traffic.
final class RemotePluginClipboardHostService {
  RemotePluginClipboardHostService.bind(
    this.connection, {
    this.readClipboard,
    this.writeClipboard,
  }) {
    _subscription = connection.otherMessages.listen((message) {
      switch (message) {
        case RemotePluginClipboardReadRequest():
          unawaited(_handleRead(message));
        case RemotePluginClipboardWriteRequest():
          unawaited(_handleWrite(message));
        default:
          return;
      }
    }, cancelOnError: false);
  }

  final RemotePluginHostConnection connection;
  final RemotePluginClipboardReader? readClipboard;
  final RemotePluginClipboardWriter? writeClipboard;

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;

  Future<void> _handleRead(RemotePluginClipboardReadRequest request) async {
    if (_disposed) {
      return;
    }

    if (readClipboard == null) {
      await _send(
        RemotePluginClipboardReadResponse(
          requestId: request.requestId,
          selection: request.selection,
          error: 'Clipboard reads are not available.',
        ),
      );
      return;
    }

    try {
      final text = await readClipboard!(request.selection);
      await _send(
        RemotePluginClipboardReadResponse(
          requestId: request.requestId,
          selection: request.selection,
          text: text ?? '',
        ),
      );
    } catch (error) {
      await _send(
        RemotePluginClipboardReadResponse(
          requestId: request.requestId,
          selection: request.selection,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _handleWrite(RemotePluginClipboardWriteRequest request) async {
    if (_disposed) {
      return;
    }

    if (writeClipboard == null) {
      await _send(
        RemotePluginClipboardWriteResponse(
          requestId: request.requestId,
          selection: request.selection,
          accepted: false,
          error: 'Clipboard writes are not available.',
        ),
      );
      return;
    }

    try {
      await writeClipboard!(request.selection, request.text);
      await _send(
        RemotePluginClipboardWriteResponse(
          requestId: request.requestId,
          selection: request.selection,
        ),
      );
    } catch (error) {
      await _send(
        RemotePluginClipboardWriteResponse(
          requestId: request.requestId,
          selection: request.selection,
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
