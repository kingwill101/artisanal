import 'package:artisanal/runtime.dart' show MouseAction, MouseButton, MouseMsg;
import 'package:artisanal/terminal.dart';

import 'virtual_terminal.dart' show TerminalMouseTracking;

/// Encodes Artisanal key events as terminal input.
abstract final class TerminalInputEncoder {
  /// Encodes [key] using conventional xterm sequences.
  static String encode(
    Key key, {
    bool applicationCursorKeys = false,
    int keyboardEnhancementFlags = 0,
  }) {
    if (key.isRelease) return '';
    if (keyboardEnhancementFlags & 8 != 0) {
      return _encodeKittyKey(key);
    }
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
      KeyType.up => applicationCursorKeys ? '\x1bOA' : '\x1b[A',
      KeyType.down => applicationCursorKeys ? '\x1bOB' : '\x1b[B',
      KeyType.right => applicationCursorKeys ? '\x1bOC' : '\x1b[C',
      KeyType.left => applicationCursorKeys ? '\x1bOD' : '\x1b[D',
      KeyType.home => applicationCursorKeys ? '\x1bOH' : '\x1b[H',
      KeyType.end => applicationCursorKeys ? '\x1bOF' : '\x1b[F',
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

  static String _encodeKittyKey(Key key) {
    final modifier = _modifier(key);
    if (key.type == KeyType.runes && key.runes.isNotEmpty) {
      return modifier == 1
          ? '\x1b[${key.runes.first}u'
          : '\x1b[${key.runes.first};${modifier}u';
    }

    final codePoint = switch (key.type) {
      KeyType.enter => 13,
      KeyType.tab => 9,
      KeyType.backspace => 127,
      KeyType.escape => 27,
      KeyType.space => 32,
      _ => null,
    };
    if (codePoint != null) {
      return modifier == 1
          ? '\x1b[${codePoint}u'
          : '\x1b[$codePoint;${modifier}u';
    }

    final finalByte = switch (key.type) {
      KeyType.up => 'A',
      KeyType.down => 'B',
      KeyType.right => 'C',
      KeyType.left => 'D',
      KeyType.home => 'H',
      KeyType.end => 'F',
      KeyType.f1 => 'P',
      KeyType.f2 => 'Q',
      KeyType.f3 => 'R',
      KeyType.f4 => 'S',
      _ => null,
    };
    if (finalByte != null) {
      return modifier == 1 ? '\x1b[$finalByte' : '\x1b[1;$modifier$finalByte';
    }

    final number = switch (key.type) {
      KeyType.insert => 2,
      KeyType.delete => 3,
      KeyType.pageUp => 5,
      KeyType.pageDown => 6,
      KeyType.f5 => 15,
      KeyType.f6 => 17,
      KeyType.f7 => 18,
      KeyType.f8 => 19,
      KeyType.f9 => 20,
      KeyType.f10 => 21,
      KeyType.f11 => 23,
      KeyType.f12 => 24,
      _ => null,
    };
    if (number == null) return '';
    return modifier == 1 ? '\x1b[$number~' : '\x1b[$number;$modifier~';
  }

  static int _modifier(Key key) =>
      1 +
      (key.shift ? 1 : 0) +
      (key.alt ? 2 : 0) +
      (key.ctrl ? 4 : 0) +
      (key.superKey ? 8 : 0);

  /// Encodes a pointer event using the mouse protocol requested by the child.
  static String encodeMouse(
    MouseMsg event, {
    required int x,
    required int y,
    required TerminalMouseTracking tracking,
    required bool sgrCoordinates,
    required bool urxvtCoordinates,
  }) {
    if (tracking == TerminalMouseTracking.none) return '';
    if (event.action == MouseAction.motion) {
      if (tracking == TerminalMouseTracking.button) return '';
      if (tracking == TerminalMouseTracking.drag &&
          event.button == MouseButton.none) {
        return '';
      }
    }

    var button = switch (event.button) {
      MouseButton.left => 0,
      MouseButton.middle => 1,
      MouseButton.right => 2,
      MouseButton.wheelUp => 64,
      MouseButton.wheelDown => 65,
      MouseButton.wheelLeft => 66,
      MouseButton.wheelRight => 67,
      _ => 3,
    };
    if (event.action == MouseAction.motion) button += 32;
    if (event.shift) button += 4;
    if (event.alt) button += 8;
    if (event.ctrl) button += 16;

    final column = x.clamp(0, 9998) + 1;
    final row = y.clamp(0, 9998) + 1;
    if (sgrCoordinates) {
      final finalByte = event.action == MouseAction.release ? 'm' : 'M';
      return '\x1b[<$button;$column;$row$finalByte';
    }
    if (urxvtCoordinates) return '\x1b[$button;$column;${row}M';
    if (column > 223 || row > 223 || button > 223) return '';
    return String.fromCharCodes([
      0x1b,
      0x5b,
      0x4d,
      button + 32,
      column + 32,
      row + 32,
    ]);
  }
}
