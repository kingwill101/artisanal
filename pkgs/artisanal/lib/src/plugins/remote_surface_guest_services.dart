import 'dart:async';

import 'remote_surface_guest_session.dart';
import 'remote_surface_protocol.dart';

/// Thrown when a host-side remote plugin service request fails.
final class RemotePluginServiceException implements Exception {
  const RemotePluginServiceException(this.message);

  final String message;

  @override
  String toString() => 'RemotePluginServiceException: $message';
}

/// Guest-side helper for host-owned remote plugin services.
///
/// This wraps the typed request/response messages already supported by the
/// protocol and gives guest plugins a simple awaitable API.
final class RemotePluginGuestServices {
  RemotePluginGuestServices(this.session);

  final RemotePluginGuestSession session;
  int _nextRequestId = 0;

  String _requestId(String prefix) => '$prefix-${++_nextRequestId}';

  Future<String> readClipboard({
    String selection = 'c',
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final requestId = _requestId('clipboard-read');
    final future = session.messages
        .where(
          (message) =>
              message is RemotePluginClipboardReadResponse &&
              message.requestId == requestId,
        )
        .cast<RemotePluginClipboardReadResponse>()
        .first
        .timeout(timeout);
    await session.send(
      RemotePluginClipboardReadRequest(
        requestId: requestId,
        selection: selection,
      ),
    );
    final response = await future;
    if (response.error != null) {
      throw RemotePluginServiceException(response.error!);
    }
    return response.text ?? '';
  }

  Future<void> writeClipboard(
    String text, {
    String selection = 'c',
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final requestId = _requestId('clipboard-write');
    final future = session.messages
        .where(
          (message) =>
              message is RemotePluginClipboardWriteResponse &&
              message.requestId == requestId,
        )
        .cast<RemotePluginClipboardWriteResponse>()
        .first
        .timeout(timeout);
    await session.send(
      RemotePluginClipboardWriteRequest(
        requestId: requestId,
        text: text,
        selection: selection,
      ),
    );
    final response = await future;
    if (!response.accepted || response.error != null) {
      throw RemotePluginServiceException(
        response.error ?? 'Clipboard write was rejected.',
      );
    }
  }

  Future<void> openUrl(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final requestId = _requestId('open-url');
    final future = session.messages
        .where(
          (message) =>
              message is RemotePluginOpenUrlResponse &&
              message.requestId == requestId,
        )
        .cast<RemotePluginOpenUrlResponse>()
        .first
        .timeout(timeout);
    await session.send(
      RemotePluginOpenUrlRequest(requestId: requestId, url: url),
    );
    final response = await future;
    if (!response.accepted || response.error != null) {
      throw RemotePluginServiceException(
        response.error ?? 'URL open request was rejected.',
      );
    }
  }

  Future<void> notify(
    String message, {
    String? title,
    RemotePluginNotificationLevel level = RemotePluginNotificationLevel.info,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final requestId = _requestId('notify');
    final future = session.messages
        .where(
          (message) =>
              message is RemotePluginNotificationResponse &&
              message.requestId == requestId,
        )
        .cast<RemotePluginNotificationResponse>()
        .first
        .timeout(timeout);
    await session.send(
      RemotePluginNotificationRequest(
        requestId: requestId,
        title: title,
        message: message,
        level: level,
      ),
    );
    final response = await future;
    if (!response.accepted || response.error != null) {
      throw RemotePluginServiceException(
        response.error ?? 'Notification request was rejected.',
      );
    }
  }
}
