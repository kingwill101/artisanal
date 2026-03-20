import 'dart:async';

import 'package:json_schema_builder/json_schema_builder.dart';

import 'remote_surface_clipboard_service.dart';
import 'remote_surface_file_picker_service.dart';
import 'remote_surface_host_connection.dart';
import 'remote_surface_notification_service.dart';
import 'remote_surface_protocol.dart';
import 'remote_surface_url_service.dart';

typedef RemotePluginGenericServiceHandler =
    FutureOr<JsonObject> Function(RemotePluginServiceRequest request);

final class _RemotePluginGenericServiceBinding {
  const _RemotePluginGenericServiceBinding(
    this.handler, {
    this.paramsSchema,
    this.resultSchema,
  });

  final RemotePluginGenericServiceHandler handler;
  final Schema? paramsSchema;
  final Schema? resultSchema;
}

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
  final Map<String, Map<String, _RemotePluginGenericServiceBinding>> _handlers =
      <String, Map<String, _RemotePluginGenericServiceBinding>>{};

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;

  void register(
    String service,
    String method,
    RemotePluginGenericServiceHandler handler, {
    Schema? paramsSchema,
    Schema? resultSchema,
  }) {
    (_handlers[service] ??=
            <String, _RemotePluginGenericServiceBinding>{})[method] =
        _RemotePluginGenericServiceBinding(
          handler,
          paramsSchema: paramsSchema,
          resultSchema: resultSchema,
        );
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

  void registerOpenUrl({RemotePluginUrlOpener? openUrl}) {
    if (openUrl == null) {
      return;
    }

    register('url', 'open', (request) async {
      final url =
          _stringParam(request.params, 'url') ??
          (throw FormatException('url.open requires a string "url" param.'));
      await openUrl(Uri.parse(url));
      return const <String, Object?>{};
    });
  }

  void registerNotification({RemotePluginNotifier? notify}) {
    if (notify == null) {
      return;
    }

    register('notify', 'show', (request) async {
      final level =
          _stringParam(request.params, 'level') ??
          RemotePluginNotificationLevel.info.wireName;
      await notify(
        RemotePluginNotificationRequest(
          requestId: request.requestId,
          title: _stringParam(request.params, 'title'),
          message:
              _stringParam(request.params, 'message') ??
              (throw FormatException(
                'notify.show requires a string "message" param.',
              )),
          level: RemotePluginNotificationLevel.parse(level),
        ),
      );
      return const <String, Object?>{};
    });
  }

  void registerFilePicker({RemotePluginFilePickerHandler? pickPaths}) {
    if (pickPaths == null) {
      return;
    }

    register('filePicker', 'open', (request) async {
      final result = await pickPaths(
        RemotePluginFilePickerRequest(
          requestId: request.requestId,
          kind: RemotePluginFilePickerKind.parse(
            _stringParam(request.params, 'kind') ??
                RemotePluginFilePickerKind.file.wireName,
          ),
          allowMultiple: _boolParam(request.params, 'allowMultiple'),
          title: _stringParam(request.params, 'title'),
          initialPath: _stringParam(request.params, 'initialPath'),
        ),
      );
      return <String, Object?>{
        'paths': result ?? const <String>[],
        'canceled': result == null,
      };
    });
  }

  Future<void> _handle(RemotePluginServiceRequest request) async {
    if (_disposed) {
      return;
    }

    final binding = _handlers[request.service]?[request.method];
    if (binding == null) {
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
      final paramsSchema = binding.paramsSchema;
      if (paramsSchema != null) {
        final errors = await paramsSchema.validate(request.params);
        if (errors.isNotEmpty) {
          await _send(
            RemotePluginServiceResponse(
              requestId: request.requestId,
              service: request.service,
              method: request.method,
              error: _validationErrorMessage(
                'Invalid params for ${request.service}.${request.method}',
                errors,
              ),
            ),
          );
          return;
        }
      }

      final result = await binding.handler(request);

      final resultSchema = binding.resultSchema;
      if (resultSchema != null) {
        final errors = await resultSchema.validate(result);
        if (errors.isNotEmpty) {
          await _send(
            RemotePluginServiceResponse(
              requestId: request.requestId,
              service: request.service,
              method: request.method,
              error: _validationErrorMessage(
                'Invalid result for ${request.service}.${request.method}',
                errors,
              ),
            ),
          );
          return;
        }
      }

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

bool _boolParam(JsonObject params, String key) {
  final value = params[key];
  return value is bool ? value : false;
}

String _validationErrorMessage(String prefix, List<ValidationError> errors) {
  final buffer = StringBuffer(prefix);
  for (final error in errors) {
    buffer
      ..write('\n- ')
      ..write(error.toErrorString());
  }
  return buffer.toString();
}
