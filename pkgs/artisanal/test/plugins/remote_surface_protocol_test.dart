import 'package:artisanal/plugins.dart' as plugins;
import 'package:test/test.dart';

void main() {
  const validator = plugins.RemotePluginProtocolValidator();

  test('host hello round-trips and validates', () async {
    const message = plugins.RemotePluginHostHello(
      hostName: 'artisanal-host',
      hostVersion: '0.2.0',
      capabilities: <String>['surfaces', 'clipboard'],
    );

    final json = message.toJson();
    final parsed = plugins.RemotePluginMessage.fromJson(json);
    final errors = await validator.validateMessage(message);

    expect(parsed, isA<plugins.RemotePluginHostHello>());
    expect(errors, isEmpty);
    expect(json['protocol'], plugins.remotePluginProtocolVersion);
    expect(json['type'], plugins.RemotePluginMessageType.hostHello.wireName);
  });

  test('frame messages validate cursor and cells', () async {
    const frame = plugins.RemotePluginFrame(
      surfaceId: 'sidebar',
      width: 40,
      height: 10,
      cells: <plugins.RemotePluginFrameCell>[
        plugins.RemotePluginFrameCell(
          column: 0,
          row: 0,
          symbol: 'A',
          foreground: '#ffffff',
        ),
      ],
      cursor: plugins.RemotePluginCursor(column: 1, row: 0, blink: true),
    );

    final errors = await validator.validateMessage(frame);

    expect(errors, isEmpty);
  });

  test('surface lifecycle messages use plugin surface wire types', () {
    const open = plugins.RemotePluginSurfaceOpen(
      surfaceId: 'sidebar',
      kind: plugins.RemotePluginSurfaceKind.panel,
      width: 40,
      height: 10,
    );

    final json = open.toJson();

    expect(
      json['type'],
      plugins.RemotePluginMessageType.pluginSurfaceOpen.wireName,
    );
  });

  test(
    'clipboard request and response messages round-trip and validate',
    () async {
      const readRequest = plugins.RemotePluginClipboardReadRequest(
        requestId: 'req-1',
      );
      const writeRequest = plugins.RemotePluginClipboardWriteRequest(
        requestId: 'req-2',
        text: '',
      );
      const readResponse = plugins.RemotePluginClipboardReadResponse(
        requestId: 'req-1',
        text: '',
      );
      const writeResponse = plugins.RemotePluginClipboardWriteResponse(
        requestId: 'req-2',
      );

      final parsedReadRequest = plugins.RemotePluginMessage.fromJson(
        readRequest.toJson(),
      );
      final parsedWriteRequest = plugins.RemotePluginMessage.fromJson(
        writeRequest.toJson(),
      );
      final readErrors = await validator.validateMessage(readResponse);
      final writeErrors = await validator.validateMessage(writeResponse);

      expect(
        parsedReadRequest,
        isA<plugins.RemotePluginClipboardReadRequest>(),
      );
      expect(
        parsedWriteRequest,
        isA<plugins.RemotePluginClipboardWriteRequest>(),
      );
      expect(readErrors, isEmpty);
      expect(writeErrors, isEmpty);
    },
  );

  test(
    'open-url request and response messages round-trip and validate',
    () async {
      const request = plugins.RemotePluginOpenUrlRequest(
        requestId: 'req-3',
        url: 'https://example.com/docs',
      );
      const response = plugins.RemotePluginOpenUrlResponse(requestId: 'req-3');

      final parsedRequest = plugins.RemotePluginMessage.fromJson(
        request.toJson(),
      );
      final responseErrors = await validator.validateMessage(response);

      expect(parsedRequest, isA<plugins.RemotePluginOpenUrlRequest>());
      expect(responseErrors, isEmpty);
    },
  );

  test(
    'notification request and response messages round-trip and validate',
    () async {
      const request = plugins.RemotePluginNotificationRequest(
        requestId: 'req-4',
        title: 'Plugin demo',
        message: 'Task finished',
        level: plugins.RemotePluginNotificationLevel.success,
      );
      const response = plugins.RemotePluginNotificationResponse(
        requestId: 'req-4',
      );

      final parsedRequest = plugins.RemotePluginMessage.fromJson(
        request.toJson(),
      );
      final responseErrors = await validator.validateMessage(response);

      expect(parsedRequest, isA<plugins.RemotePluginNotificationRequest>());
      expect(responseErrors, isEmpty);
    },
  );

  test(
    'file-picker request and response messages round-trip and validate',
    () async {
      const request = plugins.RemotePluginFilePickerRequest(
        requestId: 'req-5',
        title: 'Pick a file',
        initialPath: '/tmp',
      );
      const response = plugins.RemotePluginFilePickerResponse(
        requestId: 'req-5',
        paths: <String>['/tmp/demo.txt'],
      );

      final parsedRequest = plugins.RemotePluginMessage.fromJson(
        request.toJson(),
      );
      final responseErrors = await validator.validateMessage(response);

      expect(parsedRequest, isA<plugins.RemotePluginFilePickerRequest>());
      expect(responseErrors, isEmpty);
    },
  );

  test(
    'generic service request and response messages round-trip and validate',
    () async {
      const request = plugins.RemotePluginServiceRequest(
        requestId: 'req-6',
        service: 'clipboard',
        method: 'read',
        params: <String, Object?>{'selection': 'c'},
      );
      const response = plugins.RemotePluginServiceResponse(
        requestId: 'req-6',
        service: 'clipboard',
        method: 'read',
        result: <String, Object?>{'text': 'copied'},
      );

      final parsedRequest = plugins.RemotePluginMessage.fromJson(
        request.toJson(),
      );
      final responseErrors = await validator.validateMessage(response);

      expect(parsedRequest, isA<plugins.RemotePluginServiceRequest>());
      expect(responseErrors, isEmpty);
    },
  );

  test('validator rejects unsupported message types', () async {
    final errors = await validator.validateJson(<String, Object?>{
      'protocol': plugins.remotePluginProtocolVersion,
      'type': 'plugin.surface.patch',
      'payload': <String, Object?>{},
    });

    expect(errors, isNotEmpty);
  });

  test('validator rejects invalid frame geometry', () async {
    final errors = await validator.validateJson(<String, Object?>{
      'protocol': plugins.remotePluginProtocolVersion,
      'type': plugins.RemotePluginMessageType.pluginSurfaceFrame.wireName,
      'payload': <String, Object?>{
        'surfaceId': 'sidebar',
        'width': 10,
        'height': 5,
        'cells': <Object?>[
          <String, Object?>{'column': -1, 'row': 0, 'symbol': 'X'},
        ],
      },
    });

    expect(errors, isNotEmpty);
  });

  test('stable plugins entrypoint exposes schemas', () async {
    final schema = plugins.RemotePluginProtocolSchemas.schemaForType(
      plugins.RemotePluginMessageType.hostInputMouse,
    );
    final errors = await schema.validate(<String, Object?>{
      'protocol': plugins.remotePluginProtocolVersion,
      'type': plugins.RemotePluginMessageType.hostInputMouse.wireName,
      'payload': <String, Object?>{
        'surfaceId': 'panel',
        'action': plugins.RemotePluginMouseAction.motion.wireName,
        'button': plugins.RemotePluginMouseButton.none.wireName,
        'column': 2,
        'row': 3,
      },
    });

    expect(schema, isA<plugins.Schema>());
    expect(errors, isEmpty);
  });
}
