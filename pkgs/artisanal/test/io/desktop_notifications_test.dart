import 'dart:io';
import 'dart:isolate';

import 'package:artisanal/src/io/desktop_notifications.dart';
import 'package:test/test.dart';

void main() {
  test(
    'missing, relative-path and unsupported hosts do not launch tools',
    () async {
      for (final platform in DesktopNotificationPlatform.values) {
        final notifications = DesktopNotifications(
          searchPath: '.:relative',
          platform: platform,
        );
        expect(await notifications.send('title'), isFalse);
      }
    },
  );

  group('isolated native commands', () {
    late Directory directory;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('artisanal-notify-');
    });
    tearDown(() => directory.delete(recursive: true));

    Future<File> install(String name) async {
      final library = await Isolate.resolvePackageUri(
        Uri.parse('package:artisanal/artisanal.dart'),
      );
      final fixture = File.fromUri(
        library!.resolve('../test/io/fixtures/notification_tool.sh'),
      );
      final tool = await fixture.copy('${directory.path}/$name');
      expect((await Process.run('chmod', ['700', tool.path])).exitCode, 0);
      return tool;
    }

    test(
      'Linux text is separated from options and exact discovered path is run',
      () async {
        final tool = await install('notify-send');
        final notifications = DesktopNotifications(
          searchPath: directory.path,
          platform: DesktopNotificationPlatform.linux,
        );
        expect(
          await notifications.send(
            '--help',
            body: '--version',
            icon: 'icon with spaces',
          ),
          isTrue,
        );
        expect(await File('${tool.path}.args').readAsLines(), [
          '--icon',
          'icon with spaces',
          '--',
          '--help',
          '--version',
        ]);
      },
    );

    test(
      'silent Linux delivery never falls back to a sounding provider',
      () async {
        final kde = await install('kdialog');
        final notifications = DesktopNotifications(
          searchPath: directory.path,
          platform: DesktopNotificationPlatform.linux,
        );
        expect(await notifications.send('title', silent: true), isFalse);
        expect(await File('${kde.path}.args').exists(), isFalse);
        final tool = await install('notify-send');
        expect(await notifications.send('title', silent: true), isTrue);
        expect(await File('${tool.path}.args').readAsLines(), [
          '--hint=boolean:suppress-sound:true',
          '--',
          'title',
        ]);
      },
    );

    test('KDE values remain attached to their options', () async {
      final tool = await install('kdialog');
      final notifications = DesktopNotifications(
        searchPath: directory.path,
        platform: DesktopNotificationPlatform.linux,
      );
      expect(
        await notifications.send('--title', body: '--passivepopup'),
        isTrue,
      );
      expect(await File('${tool.path}.args').readAsLines(), [
        '--passivepopup=--title: --passivepopup',
        '5',
        '--title=--title',
      ]);
    });

    test(
      'AppleScript remains fixed while all content is passed as arguments',
      () async {
        final tool = await install('osascript');
        final notifications = DesktopNotifications(
          searchPath: directory.path,
          platform: DesktopNotificationPlatform.macOS,
        );
        expect(
          await notifications.send(
            '-e',
            body: '"quoted" \\ body',
            subtitle: 'subtitle',
            sound: 'sound',
          ),
          isTrue,
        );
        final args = await File('${tool.path}.args').readAsLines();
        expect(args, [
          '-e',
          'on run argv',
          'display notification (item 2 of argv) with title (item 1 of argv) subtitle (item 3 of argv) sound name (item 4 of argv)',
          'end run',
          '--',
          '-e',
          '"quoted" \\ body',
          'subtitle',
          'sound',
        ]);
      },
    );

    test('silent macOS delivery overrides an explicit sound', () async {
      final tool = await install('osascript');
      final notifications = DesktopNotifications(
        searchPath: directory.path,
        platform: DesktopNotificationPlatform.macOS,
      );
      expect(
        await notifications.send('title', sound: 'Ping', silent: true),
        isTrue,
      );
      final arguments = await File('${tool.path}.args').readAsString();
      expect(arguments, isNot(contains('sound name')));
      expect(arguments, isNot(contains('Ping')));
      expect(arguments, contains('display notification'));
    });

    test(
      'stalled command is killed and returns false within deadline',
      () async {
        final tool = await install('notify-send');
        await File('${tool.path}.stall').writeAsString('');
        final notifications = DesktopNotifications(
          searchPath: directory.path,
          platform: DesktopNotificationPlatform.linux,
          timeout: const Duration(milliseconds: 200),
        );
        final watch = Stopwatch()..start();
        expect(await notifications.send('title'), isFalse);
        expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
        final pid = int.parse(
          (await File('${tool.path}.pid').readAsString()).trim(),
        );
        if (Platform.isLinux) {
          final deadline = Stopwatch()..start();
          while (await Directory('/proc/$pid').exists() &&
              deadline.elapsed < const Duration(seconds: 1)) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          expect(await Directory('/proc/$pid').exists(), isFalse);
        }
      },
    );
  }, skip: Platform.isWindows);
}
