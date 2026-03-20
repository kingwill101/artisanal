import 'dart:async';

import 'remote_surface_clipboard_service.dart';
import 'remote_surface_host_connection.dart';
import 'remote_surface_protocol.dart';

typedef RemotePluginGenericServiceHandler =
    FutureOr<JsonObject> Function(RemotePluginServiceRequest request);

/// Host-side responder for generic remote plugin service envelopes.
///
/// This binds to [RemotePluginHostConnection.otherMessages] and dispatches
/// `plugin.service.request` messages by `service + method`, replying through
/// the matching `host.service.response` envelope.
final class RemotePluginGenericHostService {
  RemotePluginGenericHostService.bind(
    this.connection, {
    Map<String, Map<String, RemotePluginGenericServiceHandler>> handlers =
        const <String, Map<String, RemotePluginGenericServiceHandler>>{},
  }) {
    for (final serviceEntry in handlers.entries) {
      for (final methodEntry in serviceEntry.value.entries) {
        register(serviceEntry.key, methodEntry.key, methodEntry.value);
      }
    }

    _subscription = connection.otherMessages.listen((message) {
      if (message case RemotePluginServiceRequest()) {
        unawaited(_handle(message));
      }
    }, cancelOnError: false);
  }

  final RemotePluginHostConnection connection;
  final Map<String, Map<String, RemotePluginGenericServiceHandler>> _handlers =
      <String, Map<String, RemotePluginGenericServiceHandler>>{};

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;

  void register(
    String service,
    String method,
    RemotePluginGenericServiceHandler handler,
  ) {
    (_handlers[service] ??=
            <String, RemotePluginGenericServiceHandler>{})[method] =
        handler;
  }

  void unregister(String service, String method) {
    final methods = _handlers[service];
    if (methods == null) {
      return;
    }
    methods.remove(method);
    if (methods.isEmpty) {
      _handlers.remove(service);
    }
  }

  void registerClipboard({
    RemotePluginClipboardReader? readClipboard,
    RemotePluginClipboardWriter? writeClipboard,
  }) {
    if (readClipboard != null) {
      register('clipboard', 'read', (request) async {
        final selection = _stringParam(request.params, 'selection') ?? 'c';
        final text = await readClipboard(selection);
        return <String, Object?>{'text': text ?? ''};
      });
    }

    if (writeClipboard != null) {
      register('clipboard', 'write', (request) async {
        final selection = _stringParam(request.params, 'selection') ?? 'c';
        final text =
            _stringParam(request.params, 'text') ??
            (throw FormatException(
              'clipboard.write requires a string "text" param.',
            ));
        await writeClipboard(selection, text);
        return const <String, Object?>{};
      });
    }
  }

  Future<void> _handle(RemotePluginServiceRequest request) async {
    if (_disposed) {
      return;
    }

    final handler = _handlers[request.service]?[request.method];
    if (handler == null) {
      await _send(
        RemotePluginServiceResponse(
          requestId: request.requestId,
          service: request.service,
          method: request.method,
          error:
              'Unsupported service method: ${request.service}.${request.method}',
        ),
      );
      return;
    }

    try {
      final result = await handler(request);
      await _send(
        RemotePluginServiceResponse(
          requestId: request.requestId,
          service: request.service,
          method: request.method,
          result: result,
        ),
      );
    } catch (error) {
      await _send(
        RemotePluginServiceResponse(
          requestId: request.requestId,
          service: request.service,
          method: request.method,
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

String? _stringParam(JsonObject params, String key) {
  final value = params[key];
  return value is String ? value : null;
}
