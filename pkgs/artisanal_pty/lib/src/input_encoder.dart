import 'package:artisanal/terminal.dart';

/// Encodes Artisanal key events as terminal input.
abstract final class TerminalInputEncoder {
  /// Encodes [key] using conventional xterm sequences.
  static String encode(Key key) {
    if (key.isRelease) return '';
    if (key.type == KeyType.runes) {
      var value = String.fromCharCodes(key.runes);
      if (key.ctrl && value == ' ') {
        value = '\x00';
      } else if (key.ctrl && value.isNotEmpty) {
        final code = value.toUpperCase().codeUnitAt(0);
        if (code >= 64 && code <= 95) value = String.fromCharCode(code - 64);
      }
      return key.alt ? '\x1b$value' : value;
    }
    return switch (key.type) {
      KeyType.enter => '\r',
      KeyType.tab => '\t',
      KeyType.backspace => '\x7f',
      KeyType.escape => '\x1b',
      KeyType.space => ' ',
      KeyType.up => '\x1b[A',
      KeyType.down => '\x1b[B',
      KeyType.right => '\x1b[C',
      KeyType.left => '\x1b[D',
      KeyType.home => '\x1b[H',
      KeyType.end => '\x1b[F',
      KeyType.pageUp => '\x1b[5~',
      KeyType.pageDown => '\x1b[6~',
      KeyType.delete => '\x1b[3~',
      KeyType.insert => '\x1b[2~',
      KeyType.f1 => '\x1bOP',
      KeyType.f2 => '\x1bOQ',
      KeyType.f3 => '\x1bOR',
      KeyType.f4 => '\x1bOS',
      KeyType.f5 => '\x1b[15~',
      KeyType.f6 => '\x1b[17~',
      KeyType.f7 => '\x1b[18~',
      KeyType.f8 => '\x1b[19~',
      KeyType.f9 => '\x1b[20~',
      KeyType.f10 => '\x1b[21~',
      KeyType.f11 => '\x1b[23~',
      KeyType.f12 => '\x1b[24~',
      _ => '',
    };
  }
}
