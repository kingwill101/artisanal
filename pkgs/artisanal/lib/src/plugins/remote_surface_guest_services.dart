import 'dart:async';

import 'package:json_schema_builder/json_schema_builder.dart';

import 'remote_surface_guest_session.dart';
import 'remote_surface_protocol.dart';

/// Thrown when a host-side remote plugin service request fails.
final class RemotePluginServiceException implements Exception {
  const RemotePluginServiceException(this.message);

  final String message;

  @override
  String toString() => 'RemotePluginServiceException: $message';
}

final Schema _emptyObjectSchema = S.object(additionalProperties: false);
final Schema _clipboardReadParamsSchema = S.object(
  properties: <String, Schema>{'selection': S.string(minLength: 1)},
  additionalProperties: false,
);
final Schema _clipboardReadResultSchema = S.object(
  required: const <String>['text'],
  properties: <String, Schema>{'text': S.string()},
  additionalProperties: false,
);
final Schema _clipboardWriteParamsSchema = S.object(
  required: const <String>['text'],
  properties: <String, Schema>{
    'selection': S.string(minLength: 1),
    'text': S.string(),
  },
  additionalProperties: false,
);
final Schema _urlOpenParamsSchema = S.object(
  required: const <String>['url'],
  properties: <String, Schema>{'url': S.string(minLength: 1)},
  additionalProperties: false,
);
final Schema _notificationParamsSchema = S.object(
  required: const <String>['message'],
  properties: <String, Schema>{
    'title': S.string(),
    'message': S.string(minLength: 1),
    'level': _enumString(
      RemotePluginNotificationLevel.values.map((level) => level.wireName),
    ),
  },
  additionalProperties: false,
);
final Schema _filePickerParamsSchema = S.object(
  properties: <String, Schema>{
    'kind': _enumString(
      RemotePluginFilePickerKind.values.map((kind) => kind.wireName),
    ),
    'allowMultiple': S.boolean(),
    'title': S.string(),
    'initialPath': S.string(),
  },
  additionalProperties: false,
);
final Schema _filePickerResultSchema = S.object(
  required: const <String>['paths', 'canceled'],
  properties: <String, Schema>{
    'paths': S.list(items: S.string()),
    'canceled': S.boolean(),
  },
  additionalProperties: false,
);

/// Guest-side helper for host-owned remote plugin services.
///
/// This wraps the typed request/response messages already supported by the
/// protocol and gives guest plugins a simple awaitable API.
final class RemotePluginGuestServices {
  RemotePluginGuestServices(this.session);

  final RemotePluginGuestSession session;
  int _nextRequestId = 0;

  bool get supportsGenericServices =>
      session.hostHello.capabilities.contains('services');

  List<RemotePluginServiceDescriptor> get availableServices =>
      session.hostHello.services;

  RemotePluginServiceDescriptor? descriptorFor(String service, String method) {
    for (final descriptor in availableServices) {
      if (descriptor.service == service && descriptor.method == method) {
        return descriptor;
      }
    }
    return null;
  }

  bool supports(String service, String method) {
    if (!supportsGenericServices) {
      return false;
    }
    if (availableServices.isEmpty) {
      return true;
    }
    return descriptorFor(service, method) != null;
  }

  String _requestId(String prefix) => '$prefix-${++_nextRequestId}';

  Future<JsonObject> call(
    String service,
    String method, {
    JsonObject params = const <String, Object?>{},
    Duration timeout = const Duration(seconds: 5),
    Schema? paramsSchema,
    Schema? resultSchema,
  }) async {
    if (paramsSchema != null) {
      final errors = await paramsSchema.validate(params);
      if (errors.isNotEmpty) {
        throw RemotePluginServiceException(
          _validationErrorMessage(
            'Invalid params for $service.$method',
            errors,
          ),
        );
      }
    }

    final requestId = _requestId('$service-$method');
    final future = session.messages
        .where(
          (message) =>
              message is RemotePluginServiceResponse &&
              message.requestId == requestId,
        )
        .cast<RemotePluginServiceResponse>()
        .first
        .timeout(timeout);
    await session.send(
      RemotePluginServiceRequest(
        requestId: requestId,
        service: service,
        method: method,
        params: params,
      ),
    );
    final response = await future;
    if (response.error != null) {
      throw RemotePluginServiceException(response.error!);
    }
    if (resultSchema != null) {
      final errors = await resultSchema.validate(response.result);
      if (errors.isNotEmpty) {
        throw RemotePluginServiceException(
          _validationErrorMessage(
            'Invalid result for $service.$method',
            errors,
          ),
        );
      }
    }
    return response.result;
  }

  Future<String> readClipboard({
    String selection = 'c',
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (supports('clipboard', 'read')) {
      final result = await call(
        'clipboard',
        'read',
        params: <String, Object?>{'selection': selection},
        timeout: timeout,
        paramsSchema: _clipboardReadParamsSchema,
        resultSchema: _clipboardReadResultSchema,
      );
      return result['text']! as String;
    }

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
    if (supports('clipboard', 'write')) {
      await call(
        'clipboard',
        'write',
        params: <String, Object?>{'selection': selection, 'text': text},
        timeout: timeout,
        paramsSchema: _clipboardWriteParamsSchema,
        resultSchema: _emptyObjectSchema,
      );
      return;
    }

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
    if (supports('url', 'open')) {
      await call(
        'url',
        'open',
        params: <String, Object?>{'url': url},
        timeout: timeout,
        paramsSchema: _urlOpenParamsSchema,
        resultSchema: _emptyObjectSchema,
      );
      return;
    }

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
    if (supports('notify', 'show')) {
      await call(
        'notify',
        'show',
        params: <String, Object?>{
          'message': message,
          'title': ?title,
          'level': level.wireName,
        },
        timeout: timeout,
        paramsSchema: _notificationParamsSchema,
        resultSchema: _emptyObjectSchema,
      );
      return;
    }

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

  Future<List<String>> pickPaths({
    RemotePluginFilePickerKind kind = RemotePluginFilePickerKind.file,
    bool allowMultiple = false,
    String? title,
    String? initialPath,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (supports('filePicker', 'open')) {
      final result = await call(
        'filePicker',
        'open',
        params: <String, Object?>{
          'kind': kind.wireName,
          'allowMultiple': allowMultiple,
          'title': ?title,
          'initialPath': ?initialPath,
        },
        timeout: timeout,
        paramsSchema: _filePickerParamsSchema,
        resultSchema: _filePickerResultSchema,
      );
      final pathsValue = result['paths'];
      final canceledValue = result['canceled'];
      final paths = <String>[
        for (final path in pathsValue as List<Object?>) path! as String,
      ];
      final canceled = canceledValue as bool? ?? false;
      return canceled ? const <String>[] : paths;
    }

    final requestId = _requestId('file-picker');
    final future = session.messages
        .where(
          (message) =>
              message is RemotePluginFilePickerResponse &&
              message.requestId == requestId,
        )
        .cast<RemotePluginFilePickerResponse>()
        .first
        .timeout(timeout);
    await session.send(
      RemotePluginFilePickerRequest(
        requestId: requestId,
        kind: kind,
        allowMultiple: allowMultiple,
        title: title,
        initialPath: initialPath,
      ),
    );
    final response = await future;
    if (response.error != null) {
      throw RemotePluginServiceException(response.error!);
    }
    if (response.canceled) {
      return const <String>[];
    }
    return response.paths;
  }
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

Schema _enumString(Iterable<String> values) {
  return S.string(enumValues: values.cast<Object?>().toList(growable: false));
}
