import 'dart:io' as io;

import 'package:artisanal/plugins.dart' as plugins;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'host connection starts a plugin process and forwards other messages',
    () async {
      final scriptPath = p.join(
        io.Directory.current.path,
        'pkgs',
        'artisanal',
        'test',
        'plugins',
        'fixtures',
        'echo_plugin.dart',
      );

      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[scriptPath],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
        ),
        timeout: const Duration(seconds: 10),
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
    final scriptPath = p.join(
      io.Directory.current.path,
      'pkgs',
      'artisanal',
      'test',
      'plugins',
      'fixtures',
      'clipboard_plugin.dart',
    );

    var clipboard = 'host clipboard';
    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[scriptPath],
      hostHello: const plugins.RemotePluginHostHello(
        hostName: 'artisanal',
        hostVersion: '0.2.0',
        capabilities: <String>['clipboard'],
      ),
      timeout: const Duration(seconds: 10),
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
    'host connection can answer clipboard requests through the generic service registry',
    () async {
      final scriptPath = p.join(
        io.Directory.current.path,
        'pkgs',
        'artisanal',
        'test',
        'plugins',
        'fixtures',
        'clipboard_plugin.dart',
      );

      var clipboard = 'host clipboard';
      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[scriptPath],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
          capabilities: <String>['services'],
        ),
        timeout: const Duration(seconds: 10),
      );
      addTearDown(() => connection.dispose(kill: true));

      final genericService = connection.bindGenericService();
      genericService.registerClipboard(
        readClipboard: (_) => clipboard,
        writeClipboard: (_, text) {
          clipboard = text;
        },
      );
      addTearDown(genericService.dispose);

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

  test('host connection can answer open-url requests', () async {
    final scriptPath = p.join(
      io.Directory.current.path,
      'pkgs',
      'artisanal',
      'test',
      'plugins',
      'fixtures',
      'open_url_plugin.dart',
    );

    Uri? openedUrl;
    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[scriptPath],
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
    'host connection can answer open-url requests through the generic service registry',
    () async {
      final scriptPath = p.join(
        io.Directory.current.path,
        'pkgs',
        'artisanal',
        'test',
        'plugins',
        'fixtures',
        'open_url_plugin.dart',
      );

      Uri? openedUrl;
      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[scriptPath],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
          capabilities: <String>['services'],
        ),
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => connection.dispose(kill: true));

      final genericService = connection.bindGenericService();
      genericService.registerOpenUrl(
        openUrl: (uri) {
          openedUrl = uri;
        },
      );
      addTearDown(genericService.dispose);

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
    final scriptPath = p.join(
      io.Directory.current.path,
      'pkgs',
      'artisanal',
      'test',
      'plugins',
      'fixtures',
      'notification_plugin.dart',
    );

    plugins.RemotePluginNotificationRequest? notification;
    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[scriptPath],
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
    'host connection can answer notification requests through the generic service registry',
    () async {
      final scriptPath = p.join(
        io.Directory.current.path,
        'pkgs',
        'artisanal',
        'test',
        'plugins',
        'fixtures',
        'notification_plugin.dart',
      );

      plugins.RemotePluginNotificationRequest? notification;
      final connection = await plugins.RemotePluginHostConnection.startProcess(
        io.Platform.resolvedExecutable,
        <String>[scriptPath],
        hostHello: const plugins.RemotePluginHostHello(
          hostName: 'artisanal',
          hostVersion: '0.2.0',
          capabilities: <String>['services'],
        ),
        timeout: const Duration(seconds: 20),
      );
      addTearDown(() => connection.dispose(kill: true));

      final genericService = connection.bindGenericService();
      genericService.registerNotification(
        notify: (request) {
          notification = request;
        },
      );
      addTearDown(genericService.dispose);

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
    final scriptPath = p.join(
      io.Directory.current.path,
      'pkgs',
      'artisanal',
      'test',
      'plugins',
      'fixtures',
      'file_picker_plugin.dart',
    );

    plugins.RemotePluginFilePickerRequest? pickerRequest;
    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[scriptPath],
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

  test('host connection can answer generic service requests', () async {
    final scriptPath = p.join(
      io.Directory.current.path,
      'pkgs',
      'artisanal',
      'test',
      'plugins',
      'fixtures',
      'generic_service_plugin.dart',
    );

    plugins.RemotePluginServiceRequest? serviceRequest;
    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[scriptPath],
      hostHello: const plugins.RemotePluginHostHello(
        hostName: 'artisanal',
        hostVersion: '0.2.0',
        capabilities: <String>['services'],
      ),
      timeout: const Duration(seconds: 20),
    );
    addTearDown(() => connection.dispose(kill: true));

    final genericService = connection.bindGenericService(
      handlers:
          <String, Map<String, plugins.RemotePluginGenericServiceHandler>>{
            'host': <String, plugins.RemotePluginGenericServiceHandler>{
              'ping': (request) {
                serviceRequest = request;
                return <String, Object?>{
                  'reply': 'pong ${request.params['value']}',
                };
              },
            },
          },
    );
    addTearDown(genericService.dispose);

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
