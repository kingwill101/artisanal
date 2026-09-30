import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Native notification command family, including an explicitly unsupported host.
enum DesktopNotificationPlatform { linux, macOS, unsupported }

/// Platform integration for best-effort desktop notifications.
final class DesktopNotifications {
  const DesktopNotifications({
    this.timeout = const Duration(seconds: 10),
    this.searchPath,
    this.platform,
  });

  /// Maximum time for a spawned notification command to exit.
  final Duration timeout;

  /// Explicit executable search path; relative entries are never searched.
  final String? searchPath;

  /// Host override for isolated native-command tests; defaults to this process.
  final DesktopNotificationPlatform? platform;

  /// Sends a notification through the current platform's native command.
  Future<bool> send(
    String title, {
    String body = '',
    String subtitle = '',
    String sound = '',
    String icon = '',
    bool silent = false,
  }) {
    if (timeout <= Duration.zero) return Future<bool>.value(false);
    final host =
        platform ??
        (Platform.isMacOS
            ? DesktopNotificationPlatform.macOS
            : Platform.isLinux
            ? DesktopNotificationPlatform.linux
            : DesktopNotificationPlatform.unsupported);
    if (host == DesktopNotificationPlatform.macOS) {
      return _sendMacOS(
        title,
        body: body,
        subtitle: subtitle,
        sound: silent ? '' : sound,
      );
    }
    if (host == DesktopNotificationPlatform.linux) {
      return _sendLinux(title, body: body, icon: icon, silent: silent);
    }
    return Future<bool>.value(false);
  }

  Future<bool> _sendMacOS(
    String title, {
    required String body,
    required String subtitle,
    required String sound,
  }) async {
    final executable = await _findExecutable('osascript');
    if (executable == null) return false;
    final script = StringBuffer('on run argv\n')
      ..write(
        'display notification (item 2 of argv) with title (item 1 of argv)',
      );
    if (subtitle.isNotEmpty) {
      script.write(' subtitle (item 3 of argv)');
    }
    if (sound.isNotEmpty) {
      script.write(' sound name (item 4 of argv)');
    }
    script.write('\nend run');
    return _run(executable, [
      '-e',
      script.toString(),
      '--',
      title,
      body,
      subtitle,
      sound,
    ]);
  }

  Future<bool> _sendLinux(
    String title, {
    required String body,
    required String icon,
    required bool silent,
  }) async {
    final notifySend = await _findExecutable('notify-send');
    if (notifySend != null) {
      final arguments = <String>[];
      if (icon.isNotEmpty) arguments.addAll(['--icon', icon]);
      if (silent) arguments.add('--hint=boolean:suppress-sound:true');
      arguments.add('--');
      arguments.add(title);
      if (body.isNotEmpty) arguments.add(body);
      return _run(notifySend, arguments);
    }

    if (silent) return false;
    final kdialog = await _findExecutable('kdialog');
    if (kdialog != null) {
      final message = body.isNotEmpty ? '$title: $body' : title;
      return _run(kdialog, ['--passivepopup=$message', '5', '--title=$title']);
    }

    return false;
  }

  Future<String?> _findExecutable(String executable) async {
    try {
      for (final directory
          in (searchPath ?? Platform.environment['PATH'] ?? '').split(':')) {
        if (!path.isAbsolute(directory)) continue;
        final candidate = path.join(directory, executable);
        final stat = await File(candidate).stat();
        if (stat.type == FileSystemEntityType.file && stat.mode & 0x49 != 0) {
          return candidate;
        }
      }
    } catch (_) {
      // Notifications are optional and must not disrupt the CLI.
    }
    return null;
  }

  Future<bool> _run(String executable, List<String> arguments) async {
    Process? process;
    StreamSubscription<List<int>>? output;
    StreamSubscription<List<int>>? errors;
    var exited = false;
    try {
      process = await Process.start(executable, arguments);
      output = process.stdout.listen((_) {}, onError: (Object _) {});
      errors = process.stderr.listen((_) {}, onError: (Object _) {});
      final code = await process.exitCode.timeout(timeout);
      exited = true;
      return code == 0;
    } catch (_) {
      return false;
    } finally {
      if (!exited) process?.kill(ProcessSignal.sigkill);
      await output?.cancel();
      await errors?.cancel();
    }
  }
}
