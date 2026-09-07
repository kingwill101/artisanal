import 'dart:io';

/// Platform integration for best-effort desktop notifications.
final class DesktopNotifications {
  const DesktopNotifications();

  /// Sends a notification through the current platform's native command.
  Future<bool> send(
    String title, {
    String body = '',
    String subtitle = '',
    String sound = '',
    String icon = '',
  }) {
    if (Platform.isMacOS) {
      return _sendMacOS(title, body: body, subtitle: subtitle, sound: sound);
    }
    if (Platform.isLinux) {
      return _sendLinux(title, body: body, icon: icon);
    }
    return Future<bool>.value(false);
  }

  Future<bool> _sendMacOS(
    String title, {
    required String body,
    required String subtitle,
    required String sound,
  }) {
    String escape(String value) =>
        '"${value.replaceAll(r'\', r'\\').replaceAll('"', '\\"')}"';

    final script = StringBuffer('display notification ${escape(body)}')
      ..write(' with title ${escape(title)}');
    if (subtitle.isNotEmpty) {
      script.write(' subtitle ${escape(subtitle)}');
    }
    if (sound.isNotEmpty) {
      script.write(' sound name ${escape(sound)}');
    }
    return _run('osascript', ['-e', script.toString()]);
  }

  Future<bool> _sendLinux(
    String title, {
    required String body,
    required String icon,
  }) async {
    if (await _findExecutable('notify-send') != null) {
      final arguments = <String>[];
      if (icon.isNotEmpty) arguments.addAll(['--icon', icon]);
      arguments.add(title);
      if (body.isNotEmpty) arguments.add(body);
      return _run('notify-send', arguments);
    }

    if (await _findExecutable('kdialog') != null) {
      final message = body.isNotEmpty ? '$title: $body' : title;
      return _run('kdialog', [
        '--passivepopup',
        message,
        '5',
        '--title',
        title,
      ]);
    }

    return false;
  }

  Future<String?> _findExecutable(String executable) async {
    try {
      final result = await Process.run('which', [executable]);
      if (result.exitCode == 0) return (result.stdout as String).trim();
    } catch (_) {
      // Notifications are optional and must not disrupt the CLI.
    }
    return null;
  }

  Future<bool> _run(String executable, List<String> arguments) async {
    try {
      final result = await Process.run(executable, arguments);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
