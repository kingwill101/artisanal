import 'dart:io' as io;

import 'package:artisanal/plugins.dart' as plugins;
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fixture_compiler.dart';

void main() {
  late CompiledPluginFixtures fixtures;

  setUpAll(() async {
    fixtures = await compilePluginFixtures(<String>[
      'echo_plugin.dart',
      'clipboard_plugin.dart',
      'open_url_plugin.dart',
      'notification_plugin.dart',
      'file_picker_plugin.dart',
      'generic_service_plugin.dart',
    ]);
  });

  tearDownAll(() async {
    await fixtures.dispose();
  });

  test(
    'host connection starts a plugin process and forwards other messages',
    () async {
      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[fixtures.path('echo_plugin.dart')],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => connection.dispose(kill: true));

      expect(connection.pluginHello.pluginId, 'echo-plugin');
      expect(connection.surfaces.surfaces, isEmpty);

      await connection.send(
        const plugins.RemotePluginFocusInput(surfaceId: 'side'),
      );

      final echoed = await connection.otherMessages
          .firstWhere((message) => message is plugins.RemotePluginFocusInput)
          .timeout(const Duration(seconds: 2));
      expect(echoed, isA<plugins.RemotePluginFocusInput>());
    },
  );

  test('host connection can answer clipboard requests', () async {
    var clipboard = 'host clipboard';
    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[fixtures.path('clipboard_plugin.dart')],
      hostHello: const plugins.RemotePluginHostHello(
        hostName: 'artisanal',
        hostVersion: '0.2.0',
        capabilities: <String>['clipboard'],
      ),
      timeout: const Duration(seconds: 20),
    );
    addTearDown(() => connection.dispose(kill: true));

    final clipboardService = connection.bindClipboardService(
      readClipboard: (_) => clipboard,
      writeClipboard: (_, text) {
        clipboard = text;
      },
    );
    addTearDown(clipboardService.dispose);

    await connection.surfaceMessages
        .where((message) => message is plugins.RemotePluginFrame)
        .cast<plugins.RemotePluginFrame>()
        .firstWhere((_) {
          final surface = connection.surfaces['clipboard.panel'];
          if (surface == null) {
            return false;
          }
          final text = _surfaceText(surface);
          return text.contains('read:host clipboard') &&
              text.contains('write:ok');
        })
        .timeout(const Duration(seconds: 5));

    expect(clipboard, 'plugin-copy');
  });

  test(
    'host connection can auto-bind clipboard requests through the generic service registry',
    () async {
      var clipboard = 'host clipboard';
      final genericCatalog = plugins.RemotePluginGenericServiceCatalog()
        ..registerClipboard(
          readClipboard: (_) => clipboard,
          writeClipboard: (_, text) {
            clipboard = text;
          },
        );
      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[fixtures.path('clipboard_plugin.dart')],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
        genericServices: genericCatalog,
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => connection.dispose(kill: true));

      await connection.surfaceMessages
          .where((message) => message is plugins.RemotePluginFrame)
          .cast<plugins.RemotePluginFrame>()
          .firstWhere((_) {
            final surface = connection.surfaces['clipboard.panel'];
            if (surface == null) {
              return false;
            }
            final text = _surfaceText(surface);
            return text.contains('read:host clipboard') &&
                text.contains('write:ok');
          })
          .timeout(const Duration(seconds: 5));

      expect(clipboard, 'plugin-copy');
    },
  );

  test(
    'one generic service catalog can be reused across multiple host connections',
    () async {
      var clipboard = 'host clipboard';
      final genericCatalog = plugins.RemotePluginGenericServiceCatalog.builtIns(
        readClipboard: (_) => clipboard,
        writeClipboard: (_, text) {
          clipboard = text;
        },
      );

      final first = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[fixtures.path('clipboard_plugin.dart')],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
        genericServices: genericCatalog,
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => first.dispose(kill: true));

      await first.surfaceMessages
          .where((message) => message is plugins.RemotePluginFrame)
          .cast<plugins.RemotePluginFrame>()
          .firstWhere((_) {
            final surface = first.surfaces['clipboard.panel'];
            if (surface == null) {
              return false;
            }
            final text = _surfaceText(surface);
            return text.contains('read:host clipboard') &&
                text.contains('write:ok');
          })
          .timeout(const Duration(seconds: 5));

      expect(clipboard, 'plugin-copy');

      clipboard = 'host clipboard again';

      final second = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[fixtures.path('clipboard_plugin.dart')],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
        genericServices: genericCatalog,
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => second.dispose(kill: true));

      await second.surfaceMessages
          .where((message) => message is plugins.RemotePluginFrame)
          .cast<plugins.RemotePluginFrame>()
          .firstWhere((_) {
            final surface = second.surfaces['clipboard.panel'];
            if (surface == null) {
              return false;
            }
            final text = _surfaceText(surface);
            return text.contains('read:host clipboard again') &&
                text.contains('write:ok');
          })
          .timeout(const Duration(seconds: 5));

      expect(clipboard, 'plugin-copy');
    },
  );

  test(
    'host connection can start a manifest-backed plugin with auto-bound generic services',
    () async {
      var clipboard = 'host clipboard';
      final compiledPath = fixtures.path('clipboard_plugin.dart');
      final manifestPath = p.join(
        io.File(compiledPath).parent.path,
        'clipboard_manifest.plugin.json',
      );
      addTearDown(() async {
        final file = io.File(manifestPath);
        if (await file.exists()) {
          await file.delete();
        }
      });

      final manifest = plugins.RemotePluginManifest(
        id: 'clipboard',
        entrypoint: p.basename(compiledPath),
        primarySurfaceId: 'clipboard.panel',
        surfaceIds: const <String>['clipboard.panel'],
        placement: const plugins.RemotePluginManifestPlacement(
          surfaceId: 'clipboard.panel',
          x: 0,
          y: 0,
        ),
        manifestPath: manifestPath,
      );

      await io.File(manifestPath).writeAsString(manifest.encodeJson());

      final genericCatalog = plugins.RemotePluginGenericServiceCatalog()
        ..registerClipboard(
          readClipboard: (_) => clipboard,
          writeClipboard: (_, text) {
            clipboard = text;
          },
        );
      final connection = await plugins.RemotePluginHostConnection.startManifest(
        manifest,
        executable: io.Platform.resolvedExecutable,
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
        genericServices: genericCatalog,
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => connection.dispose(kill: true));

      await connection.surfaceMessages
          .where((message) => message is plugins.RemotePluginFrame)
          .cast<plugins.RemotePluginFrame>()
          .firstWhere((_) {
            final surface = connection.surfaces['clipboard.panel'];
            if (surface == null) {
              return false;
            }
            final text = _surfaceText(surface);
            return text.contains('read:host clipboard') &&
                text.contains('write:ok');
          })
          .timeout(const Duration(seconds: 5));

      expect(connection.pluginHello.pluginId, 'clipboard-plugin');
      expect(clipboard, 'plugin-copy');
    },
  );

  test(
    'host connection can start from a manifest file with auto-bound generic services',
    () async {
      var clipboard = 'host clipboard';
      final compiledPath = fixtures.path('clipboard_plugin.dart');
      final manifestPath = p.join(
        io.File(compiledPath).parent.path,
        'clipboard_manifest_file.plugin.json',
      );
      addTearDown(() async {
        final file = io.File(manifestPath);
        if (await file.exists()) {
          await file.delete();
        }
      });

      final manifest = plugins.RemotePluginManifest(
        id: 'clipboard',
        entrypoint: p.basename(compiledPath),
        primarySurfaceId: 'clipboard.panel',
        surfaceIds: const <String>['clipboard.panel'],
        placement: const plugins.RemotePluginManifestPlacement(
          surfaceId: 'clipboard.panel',
          x: 0,
          y: 0,
        ),
        manifestPath: manifestPath,
      );

      await io.File(manifestPath).writeAsString(manifest.encodeJson());

      final genericCatalog = plugins.RemotePluginGenericServiceCatalog()
        ..registerClipboard(
          readClipboard: (_) => clipboard,
          writeClipboard: (_, text) {
            clipboard = text;
          },
        );
      final connection =
          await plugins.RemotePluginHostConnection.startManifestFile(
            manifestPath,
            executable: io.Platform.resolvedExecutable,
            hostHello: const plugins.RemotePluginHostHello(
              hostName: 'artisanal',
              hostVersion: '0.2.0',
            ),
            genericServices: genericCatalog,
            timeout: const Duration(seconds: 20),
          );
      addTearDown(() => connection.dispose(kill: true));

      await connection.surfaceMessages
          .where((message) => message is plugins.RemotePluginFrame)
          .cast<plugins.RemotePluginFrame>()
          .firstWhere((_) {
            final surface = connection.surfaces['clipboard.panel'];
            if (surface == null) {
              return false;
            }
            final text = _surfaceText(surface);
            return text.contains('read:host clipboard') &&
                text.contains('write:ok');
          })
          .timeout(const Duration(seconds: 5));

      expect(connection.pluginHello.pluginId, 'clipboard-plugin');
      expect(clipboard, 'plugin-copy');
    },
  );

  test('host connection can answer open-url requests', () async {
    Uri? openedUrl;
    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[fixtures.path('open_url_plugin.dart')],
      hostHello: const plugins.RemotePluginHostHello(
        hostName: 'artisanal',
        hostVersion: '0.2.0',
        capabilities: <String>['open-url'],
      ),
      timeout: const Duration(seconds: 20),
    );
    addTearDown(() => connection.dispose(kill: true));

    final urlService = connection.bindOpenUrlService(
      openUrl: (uri) {
        openedUrl = uri;
      },
    );
    addTearDown(urlService.dispose);

    await connection.surfaceMessages
        .where((message) => message is plugins.RemotePluginFrame)
        .cast<plugins.RemotePluginFrame>()
        .firstWhere((_) {
          final surface = connection.surfaces['url.panel'];
          if (surface == null) {
            return false;
          }
          final text = _surfaceText(surface);
          return text.contains('url:ok');
        })
        .timeout(const Duration(seconds: 5));

    expect(openedUrl, Uri.parse('https://example.com/plugin'));
  });

  test(
    'host connection can auto-bind open-url requests through the generic service registry',
    () async {
      Uri? openedUrl;
      final genericCatalog = plugins.RemotePluginGenericServiceCatalog()
        ..registerOpenUrl(
          openUrl: (uri) {
            openedUrl = uri;
          },
        );
      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[fixtures.path('open_url_plugin.dart')],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
        genericServices: genericCatalog,
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => connection.dispose(kill: true));

      await connection.surfaceMessages
          .where((message) => message is plugins.RemotePluginFrame)
          .cast<plugins.RemotePluginFrame>()
          .firstWhere((_) {
            final surface = connection.surfaces['url.panel'];
            if (surface == null) {
              return false;
            }
            final text = _surfaceText(surface);
            return text.contains('url:ok');
          })
          .timeout(const Duration(seconds: 5));

      expect(openedUrl, Uri.parse('https://example.com/plugin'));
    },
  );

  test('host connection can answer notification requests', () async {
    plugins.RemotePluginNotificationRequest? notification;
    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[fixtures.path('notification_plugin.dart')],
      hostHello: const plugins.RemotePluginHostHello(
        hostName: 'artisanal',
        hostVersion: '0.2.0',
        capabilities: <String>['notify'],
      ),
      timeout: const Duration(seconds: 20),
    );
    addTearDown(() => connection.dispose(kill: true));

    final notificationService = connection.bindNotificationService(
      notify: (request) {
        notification = request;
      },
    );
    addTearDown(notificationService.dispose);

    await connection.surfaceMessages
        .where((message) => message is plugins.RemotePluginFrame)
        .cast<plugins.RemotePluginFrame>()
        .firstWhere((_) {
          final surface = connection.surfaces['notification.panel'];
          if (surface == null) {
            return false;
          }
          final text = _surfaceText(surface);
          return text.contains('notify:ok');
        })
        .timeout(const Duration(seconds: 5));

    expect(notification, isNotNull);
    expect(notification!.title, 'Plugin demo');
    expect(notification!.message, 'Background task finished');
    expect(notification!.level, plugins.RemotePluginNotificationLevel.success);
  });

  test(
    'host connection can auto-bind notification requests through the generic service registry',
    () async {
      plugins.RemotePluginNotificationRequest? notification;
      final genericCatalog = plugins.RemotePluginGenericServiceCatalog()
        ..registerNotification(
          notify: (request) {
            notification = request;
          },
        );
      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[fixtures.path('notification_plugin.dart')],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
        genericServices: genericCatalog,
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => connection.dispose(kill: true));

      await connection.surfaceMessages
          .where((message) => message is plugins.RemotePluginFrame)
          .cast<plugins.RemotePluginFrame>()
          .firstWhere((_) {
            final surface = connection.surfaces['notification.panel'];
            if (surface == null) {
              return false;
            }
            final text = _surfaceText(surface);
            return text.contains('notify:ok');
          })
          .timeout(const Duration(seconds: 5));

      expect(notification, isNotNull);
      expect(notification!.title, 'Plugin demo');
      expect(notification!.message, 'Background task finished');
      expect(
        notification!.level,
        plugins.RemotePluginNotificationLevel.success,
      );
    },
  );

  test('host connection can answer file-picker requests', () async {
    plugins.RemotePluginFilePickerRequest? pickerRequest;
    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[fixtures.path('file_picker_plugin.dart')],
      hostHello: const plugins.RemotePluginHostHello(
        hostName: 'artisanal',
        hostVersion: '0.2.0',
        capabilities: <String>['file-picker'],
      ),
      timeout: const Duration(seconds: 20),
    );
    addTearDown(() => connection.dispose(kill: true));

    final pickerService = connection.bindFilePickerService(
      pickPaths: (request) {
        pickerRequest = request;
        return const <String>['/tmp/demo.txt'];
      },
    );
    addTearDown(pickerService.dispose);

    await connection.surfaceMessages
        .where((message) => message is plugins.RemotePluginFrame)
        .cast<plugins.RemotePluginFrame>()
        .firstWhere((_) {
          final surface = connection.surfaces['picker.panel'];
          if (surface == null) {
            return false;
          }
          final text = _surfaceText(surface);
          return text.contains('pick:/tmp/demo.txt');
        })
        .timeout(const Duration(seconds: 5));

    expect(pickerRequest, isNotNull);
    expect(pickerRequest!.title, 'Select a demo file');
    expect(pickerRequest!.initialPath, '/tmp');
    expect(pickerRequest!.kind, plugins.RemotePluginFilePickerKind.file);
  });

  test(
    'host connection can auto-bind file-picker requests through the generic service registry',
    () async {
      plugins.RemotePluginFilePickerRequest? pickerRequest;
      final genericCatalog = plugins.RemotePluginGenericServiceCatalog()
        ..registerFilePicker(
          pickPaths: (request) {
            pickerRequest = request;
            return const <String>['/tmp/demo.txt'];
          },
        );
      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[fixtures.path('file_picker_plugin.dart')],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
        genericServices: genericCatalog,
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => connection.dispose(kill: true));

      await connection.surfaceMessages
          .where((message) => message is plugins.RemotePluginFrame)
          .cast<plugins.RemotePluginFrame>()
          .firstWhere((_) {
            final surface = connection.surfaces['picker.panel'];
            if (surface == null) {
              return false;
            }
            final text = _surfaceText(surface);
            return text.contains('pick:/tmp/demo.txt');
          })
          .timeout(const Duration(seconds: 5));

      expect(pickerRequest, isNotNull);
      expect(pickerRequest!.title, 'Select a demo file');
      expect(pickerRequest!.initialPath, '/tmp');
      expect(pickerRequest!.kind, plugins.RemotePluginFilePickerKind.file);
    },
  );

  test('host connection can answer generic service requests', () async {
    plugins.RemotePluginServiceRequest? serviceRequest;
    final genericCatalog = plugins.RemotePluginGenericServiceCatalog()
      ..register('host', 'ping', (request) {
        serviceRequest = request;
        return <String, Object?>{'reply': 'pong ${request.params['value']}'};
      }, description: 'Ping the host test service.');
    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[fixtures.path('generic_service_plugin.dart')],
      hostHello: plugins.RemotePluginHostHello(
        hostName: 'artisanal',
        hostVersion: '0.2.0',
      ),
      genericServices: genericCatalog,
      timeout: const Duration(seconds: 20),
    );
    addTearDown(() => connection.dispose(kill: true));

    await connection.surfaceMessages
        .where((message) => message is plugins.RemotePluginFrame)
        .cast<plugins.RemotePluginFrame>()
        .firstWhere((_) {
          final surface = connection.surfaces['generic.panel'];
          if (surface == null) {
            return false;
          }
          final text = _surfaceText(surface);
          return text.contains('generic:pong demo');
        })
        .timeout(const Duration(seconds: 5));

    expect(serviceRequest, isNotNull);
    expect(serviceRequest!.service, 'host');
    expect(serviceRequest!.method, 'ping');
    expect(serviceRequest!.params, <String, Object?>{'value': 'demo'});
  });

  test(
    'host connection validates auto-bound generic service params before calling the handler',
    () async {
      var callCount = 0;
      final genericCatalog = plugins.RemotePluginGenericServiceCatalog()
        ..register(
          'host',
          'ping',
          (_) {
            callCount++;
            return <String, Object?>{'reply': 'pong'};
          },
          paramsSchema: jsb.S.object(
            required: const <String>['value'],
            properties: <String, jsb.Schema>{'value': jsb.S.integer()},
            additionalProperties: false,
          ),
        );
      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[fixtures.path('generic_service_plugin.dart')],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
        genericServices: genericCatalog,
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => connection.dispose(kill: true));

      await connection.surfaceMessages
          .where((message) => message is plugins.RemotePluginFrame)
          .cast<plugins.RemotePluginFrame>()
          .firstWhere((_) {
            final surface = connection.surfaces['generic.panel'];
            if (surface == null) {
              return false;
            }
            final text = _surfaceText(surface);
            return text.contains('generic:error:');
          })
          .timeout(const Duration(seconds: 5));

      expect(callCount, 0);
    },
  );
}

String _surfaceText(plugins.RemotePluginSurfaceState surface) {
  final lines = <String>[];
  for (var row = 0; row < surface.height; row++) {
    final buffer = StringBuffer();
    for (var column = 0; column < surface.width; column++) {
      buffer.write(surface.cellAt(column, row).symbol);
    }
    lines.add(buffer.toString().trimRight());
  }
  return lines.join('\n');
}
