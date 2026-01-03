/// TUI keyboard input parsing.
///
/// This module provides keyboard input parsing for the TUI runtime.
/// Key types and constants are imported from the shared terminal module.
///
/// ## Migration
///
/// The `Key`, `KeyType`, and `Keys` types are now defined in the shared
/// terminal module. This file re-exports them for backward compatibility.
///
/// New code should import from the terminal module:
/// ```dart
/// import 'package:artisanal/src/terminal/terminal.dart';
/// ```
library;

import 'dart:convert';

import '../terminal/keys.dart';
import 'msg.dart';
import '../unicode/grapheme.dart' as uni;

// Re-export key types from the shared terminal module
export '../terminal/keys.dart' show Key, KeyType, Keys;

/// Result of parsing input bytes.
sealed class ParseResult {}

/// A key was parsed.
class KeyResult extends ParseResult {
  KeyResult(this.key);
  final Key key;
}

/// A message was parsed (e.g., mouse event, focus event).
class MsgResult extends ParseResult {
  MsgResult(this.msg);
  final Msg msg;
}

/// Parses raw terminal input bytes into [Key] objects and [Msg] objects.
///
/// This class handles the complexity of ANSI escape sequences,
/// control characters, multi-byte UTF-8 characters, and mouse events.
class KeyParser {
  /// Buffer for incomplete escape sequences.
  final List<int> _buffer = [];

  /// Timeout duration for escape sequences.
  static const escapeTimeout = Duration(milliseconds: 50);

  /// Whether we're currently in a bracketed paste.
  bool _inBracketedPaste = false;

  /// Buffer for bracketed paste content.
  final StringBuffer _pasteBuffer = StringBuffer();

  /// Parses a list of input bytes into Key objects.
  ///
  /// Returns a list of parsed keys. May return an empty list if
  /// the input is an incomplete escape sequence.
  List<Key> parse(List<int> bytes) {
    final results = parseAll(bytes);
    return results.whereType<KeyResult>().map((r) => r.key).toList();
  }

  /// Parses input bytes and returns all results (keys and messages).
  List<ParseResult> parseAll(List<int> bytes) {
    _buffer.addAll(bytes);
    final results = <ParseResult>[];

    while (_buffer.isNotEmpty) {
      // If we're in a bracketed paste, handle that specially
      if (_inBracketedPaste) {
        final result = _parseBracketedPaste();
        if (result == null) {
          // Need more data for paste
          break;
        }
        results.add(result);
        continue;
      }

      final result = _parseNext();
      if (result == null) {
        // Incomplete sequence, wait for more input
        break;
      }
      results.add(result);
    }

    return results;
  }

  /// Clears any buffered input.
  void clear() {
    _buffer.clear();
    _inBracketedPaste = false;
    _pasteBuffer.clear();
  }

  /// Parses the next item from the buffer.
  ///
  /// Returns null if the buffer contains an incomplete sequence.
  ParseResult? _parseNext() {
    if (_buffer.isEmpty) return null;

    final firstByte = _buffer[0];

    // Check for escape sequence
    if (firstByte == 0x1b) {
      return _parseEscapeSequence();
    }

    // Control characters (0x00-0x1f, except 0x1b which is escape)
    if (firstByte < 0x20) {
      _buffer.removeAt(0);
      return KeyResult(_parseControlChar(firstByte));
    }

    // DEL character (0x7f) - usually backspace
    if (firstByte == 0x7f) {
      _buffer.removeAt(0);
      return KeyResult(const Key(KeyType.backspace));
    }

    // Regular character or UTF-8 sequence
    final key = _parseUtf8Cluster(0);
    if (key == null) return null;
    return KeyResult(key);
  }

  /// Parses an escape sequence.
  ParseResult? _parseEscapeSequence() {
    if (_buffer.length < 2) {
      // Just a lone ESC - return it as the Escape key
      _buffer.removeAt(0);
      return KeyResult(const Key(KeyType.escape));
    }

    final secondByte = _buffer[1];

    // CSI sequence: ESC [
    if (secondByte == 0x5b) {
      // '['
      return _parseCsiSequence();
    }

    // SS3 sequence: ESC O (function keys on some terminals)
    if (secondByte == 0x4f) {
      // 'O'
      return _parseSs3Sequence();
    }

    // Alt+key: ESC followed by a regular character
    if (secondByte >= 0x20 && secondByte < 0x7f) {
      _buffer.removeRange(0, 2);
      return KeyResult(Key(KeyType.runes, runes: [secondByte], alt: true));
    }

    // Alt+UTF-8 sequence: ESC followed by a UTF-8 character/grapheme cluster.
    if (secondByte >= 0x80) {
      final key = _parseUtf8Cluster(1);
      if (key == null) return null;
      final text = key.char ?? String.fromCharCodes(key.runes);
      _buffer.removeRange(0, 1 + utf8.encode(text).length);
      return KeyResult(key.copyWith(alt: true));
    }

    // Unknown escape sequence - just return the ESC key
    _buffer.removeAt(0);
    return KeyResult(const Key(KeyType.escape));
  }

  /// Parses a CSI (Control Sequence Introducer) sequence.
  ///
  /// CSI sequences start with ESC [ and are used for cursor keys,
  /// function keys, mouse events, etc.
  ParseResult? _parseCsiSequence() {
    // Find the end of the sequence
    // CSI sequences end with a byte in range 0x40-0x7e
    int? endIndex;
    for (var i = 2; i < _buffer.length; i++) {
      final b = _buffer[i];
      if (b >= 0x40 && b <= 0x7e) {
        endIndex = i;
        break;
      }
    }

    if (endIndex == null) {
      // Incomplete sequence
      return null;
    }

    // Extract the sequence
    final sequence = _buffer.sublist(0, endIndex + 1);
    _buffer.removeRange(0, endIndex + 1);

    // Check for mouse events
    // X10 mouse: ESC [ M ...
    if (sequence.length >= 6 && sequence[2] == 0x4d) {
      // 'M'
      return _parseX10Mouse(sequence);
    }

    // SGR mouse: ESC [ < ... m or ESC [ < ... M
    if (sequence.length >= 4 && sequence[2] == 0x3c) {
      // '<'
      return _parseSgrMouse(sequence);
    }

    // Bracketed paste start: ESC [ 200 ~
    if (_matchSequence(sequence, [0x1b, 0x5b, 0x32, 0x30, 0x30, 0x7e])) {
      _inBracketedPaste = true;
      _pasteBuffer.clear();
      return _parseBracketedPaste();
    }

    // Focus events: ESC [ I (focus in) or ESC [ O (focus out)
    if (sequence.length == 3) {
      if (sequence[2] == 0x49) {
        // 'I' - focus in
        return MsgResult(const FocusMsg(true));
      }
      if (sequence[2] == 0x4f) {
        // 'O' - focus out
        return MsgResult(const FocusMsg(false));
      }
    }

    // Parse the sequence for key information
    return KeyResult(_interpretCsiSequence(sequence));
  }

  /// Parses X10 mouse protocol: ESC [ M Cb Cx Cy
  ParseResult _parseX10Mouse(List<int> sequence) {
    if (sequence.length < 6) {
      return KeyResult(const Key(KeyType.unknown));
    }

    final cb = sequence[3] - 32;
    final cx = sequence[4] - 33;
    final cy = sequence[5] - 33;

    final (button, action) = _decodeX10Button(cb);

    return MsgResult(
      MouseMsg(
        x: cx,
        y: cy,
        button: button,
        action: action,
        ctrl: (cb & 0x10) != 0,
        alt: (cb & 0x08) != 0,
        shift: (cb & 0x04) != 0,
      ),
    );
  }

  /// Decodes X10 mouse button byte.
  (MouseButton, MouseAction) _decodeX10Button(int cb) {
    final buttonBits = cb & 0x03;
    final motion = (cb & 0x20) != 0;
    final wheel = (cb & 0x40) != 0;

    if (wheel) {
      return (
        buttonBits == 0 ? MouseButton.wheelUp : MouseButton.wheelDown,
        MouseAction.press,
      );
    }

    final button = switch (buttonBits) {
      0 => MouseButton.left,
      1 => MouseButton.middle,
      2 => MouseButton.right,
      3 => MouseButton.none,
      _ => MouseButton.none,
    };

    final action = motion
        ? MouseAction.motion
        : (buttonBits == 3 ? MouseAction.release : MouseAction.press);

    return (button, action);
  }

  /// Parses SGR mouse protocol: ESC [ < Pb ; Px ; Py m/M
  ParseResult _parseSgrMouse(List<int> sequence) {
    // Skip ESC [ <
    final params = String.fromCharCodes(
      sequence.sublist(3, sequence.length - 1),
    );
    final parts = params.split(';');

    if (parts.length < 3) {
      return KeyResult(const Key(KeyType.unknown));
    }

    final cb = int.tryParse(parts[0]) ?? 0;
    final cx = (int.tryParse(parts[1]) ?? 1) - 1;
    final cy = (int.tryParse(parts[2]) ?? 1) - 1;

    final isRelease = sequence.last == 0x6d; // 'm' for release, 'M' for press

    final (button, action) = _decodeSgrButton(cb, isRelease);

    return MsgResult(
      MouseMsg(
        x: cx,
        y: cy,
        button: button,
        action: action,
        ctrl: (cb & 0x10) != 0,
        alt: (cb & 0x08) != 0,
        shift: (cb & 0x04) != 0,
      ),
    );
  }

  /// Decodes SGR mouse button byte.
  (MouseButton, MouseAction) _decodeSgrButton(int cb, bool isRelease) {
    final buttonBits = cb & 0x03;
    final motion = (cb & 0x20) != 0;
    final wheel = (cb & 0x40) != 0;

    if (wheel) {
      return (
        buttonBits == 0 ? MouseButton.wheelUp : MouseButton.wheelDown,
        MouseAction.press,
      );
    }

    final button = switch (buttonBits) {
      0 => MouseButton.left,
      1 => MouseButton.middle,
      2 => MouseButton.right,
      _ => MouseButton.none,
    };

    final action = isRelease
        ? MouseAction.release
        : (motion ? MouseAction.motion : MouseAction.press);

    return (button, action);
  }

  /// Parses bracketed paste content.
  ParseResult? _parseBracketedPaste() {
    // Look for the end sequence: ESC [ 201 ~
    const endSeq = [0x1b, 0x5b, 0x32, 0x30, 0x31, 0x7e];

    while (_buffer.isNotEmpty) {
      // Check if buffer starts with end sequence
      if (_buffer.length >= endSeq.length) {
        var isEnd = true;
        for (var i = 0; i < endSeq.length; i++) {
          if (_buffer[i] != endSeq[i]) {
            isEnd = false;
            break;
          }
        }
        if (isEnd) {
          _buffer.removeRange(0, endSeq.length);
          _inBracketedPaste = false;
          final content = _pasteBuffer.toString();
          _pasteBuffer.clear();
          return MsgResult(PasteMsg(content));
        }
      }

      // Check if we might have a partial end sequence
      if (_buffer.length < endSeq.length && _buffer[0] == 0x1b) {
        // Might be start of end sequence, need more data
        return null;
      }

      // Add byte to paste buffer
      _pasteBuffer.writeCharCode(_buffer.removeAt(0));
    }

    return null;
  }

  /// Checks if a sequence matches an expected pattern.
  bool _matchSequence(List<int> sequence, List<int> expected) {
    if (sequence.length != expected.length) return false;
    for (var i = 0; i < sequence.length; i++) {
      if (sequence[i] != expected[i]) return false;
    }
    return true;
  }

  /// Interprets a CSI sequence and returns the corresponding key.
  Key _interpretCsiSequence(List<int> sequence) {
    // Extract parameters and final byte
    final finalByte = sequence.last;
    final paramsBytes = sequence.sublist(2, sequence.length - 1);
    final paramsStr = String.fromCharCodes(paramsBytes);

    // Parse modifiers from parameters
    var ctrl = false;
    var alt = false;
    var shift = false;

    final parts = paramsStr.split(';');
    if (parts.length >= 2) {
      final modNum = int.tryParse(parts.last) ?? 1;
      // Modifier encoding: 1 + (shift ? 1 : 0) + (alt ? 2 : 0) + (ctrl ? 4 : 0)
      shift = (modNum - 1) & 1 != 0;
      alt = (modNum - 1) & 2 != 0;
      ctrl = (modNum - 1) & 4 != 0;
    }

    // Arrow keys: ESC [ A/B/C/D
    switch (finalByte) {
      case 0x41: // 'A' - Up
        return Key(KeyType.up, ctrl: ctrl, alt: alt, shift: shift);
      case 0x42: // 'B' - Down
        return Key(KeyType.down, ctrl: ctrl, alt: alt, shift: shift);
      case 0x43: // 'C' - Right
        return Key(KeyType.right, ctrl: ctrl, alt: alt, shift: shift);
      case 0x44: // 'D' - Left
        return Key(KeyType.left, ctrl: ctrl, alt: alt, shift: shift);
      case 0x48: // 'H' - Home
        return Key(KeyType.home, ctrl: ctrl, alt: alt, shift: shift);
      case 0x46: // 'F' - End
        return Key(KeyType.end, ctrl: ctrl, alt: alt, shift: shift);
      case 0x5a: // 'Z' - Shift+Tab (reverse tab)
        return const Key(KeyType.tab, shift: true);
      case 0x50: // 'P' - F1 (some terminals)
        return Key(KeyType.f1, ctrl: ctrl, alt: alt, shift: shift);
      case 0x51: // 'Q' - F2 (some terminals)
        return Key(KeyType.f2, ctrl: ctrl, alt: alt, shift: shift);
      case 0x52: // 'R' - F3 (some terminals)
        return Key(KeyType.f3, ctrl: ctrl, alt: alt, shift: shift);
      case 0x53: // 'S' - F4 (some terminals)
        return Key(KeyType.f4, ctrl: ctrl, alt: alt, shift: shift);
    }

    // Tilde sequences: ESC [ n ~
    if (finalByte == 0x7e) {
      // '~'
      final num = int.tryParse(parts.first) ?? 0;
      return switch (num) {
        1 => Key(KeyType.home, ctrl: ctrl, alt: alt, shift: shift),
        2 => Key(KeyType.insert, ctrl: ctrl, alt: alt, shift: shift),
        3 => Key(KeyType.delete, ctrl: ctrl, alt: alt, shift: shift),
        4 => Key(KeyType.end, ctrl: ctrl, alt: alt, shift: shift),
        5 => Key(KeyType.pageUp, ctrl: ctrl, alt: alt, shift: shift),
        6 => Key(KeyType.pageDown, ctrl: ctrl, alt: alt, shift: shift),
        7 => Key(KeyType.home, ctrl: ctrl, alt: alt, shift: shift),
        8 => Key(KeyType.end, ctrl: ctrl, alt: alt, shift: shift),
        // Function keys
        11 => Key(KeyType.f1, ctrl: ctrl, alt: alt, shift: shift),
        12 => Key(KeyType.f2, ctrl: ctrl, alt: alt, shift: shift),
        13 => Key(KeyType.f3, ctrl: ctrl, alt: alt, shift: shift),
        14 => Key(KeyType.f4, ctrl: ctrl, alt: alt, shift: shift),
        15 => Key(KeyType.f5, ctrl: ctrl, alt: alt, shift: shift),
        17 => Key(KeyType.f6, ctrl: ctrl, alt: alt, shift: shift),
        18 => Key(KeyType.f7, ctrl: ctrl, alt: alt, shift: shift),
        19 => Key(KeyType.f8, ctrl: ctrl, alt: alt, shift: shift),
        20 => Key(KeyType.f9, ctrl: ctrl, alt: alt, shift: shift),
        21 => Key(KeyType.f10, ctrl: ctrl, alt: alt, shift: shift),
        23 => Key(KeyType.f11, ctrl: ctrl, alt: alt, shift: shift),
        24 => Key(KeyType.f12, ctrl: ctrl, alt: alt, shift: shift),
        // Extended function keys F13-F20
        25 => Key(KeyType.f13, ctrl: ctrl, alt: alt, shift: shift),
        26 => Key(KeyType.f14, ctrl: ctrl, alt: alt, shift: shift),
        28 => Key(KeyType.f15, ctrl: ctrl, alt: alt, shift: shift),
        29 => Key(KeyType.f16, ctrl: ctrl, alt: alt, shift: shift),
        31 => Key(KeyType.f17, ctrl: ctrl, alt: alt, shift: shift),
        32 => Key(KeyType.f18, ctrl: ctrl, alt: alt, shift: shift),
        33 => Key(KeyType.f19, ctrl: ctrl, alt: alt, shift: shift),
        34 => Key(KeyType.f20, ctrl: ctrl, alt: alt, shift: shift),
        _ => const Key(KeyType.unknown),
      };
    }

    return const Key(KeyType.unknown);
  }

  /// Parses an SS3 sequence (ESC O).
  ParseResult? _parseSs3Sequence() {
    if (_buffer.length < 3) {
      return null;
    }

    final thirdByte = _buffer[2];
    _buffer.removeRange(0, 3);

    return KeyResult(switch (thirdByte) {
      0x41 => const Key(KeyType.up), // 'A'
      0x42 => const Key(KeyType.down), // 'B'
      0x43 => const Key(KeyType.right), // 'C'
      0x44 => const Key(KeyType.left), // 'D'
      0x48 => const Key(KeyType.home), // 'H'
      0x46 => const Key(KeyType.end), // 'F'
      0x50 => const Key(KeyType.f1), // 'P'
      0x51 => const Key(KeyType.f2), // 'Q'
      0x52 => const Key(KeyType.f3), // 'R'
      0x53 => const Key(KeyType.f4), // 'S'
      _ => const Key(KeyType.unknown),
    });
  }

  /// Parses a control character.
  Key _parseControlChar(int byte) {
    return switch (byte) {
      0x00 => const Key(KeyType.runes, runes: [0x20], ctrl: true), // Ctrl+Space
      0x01 => const Key(KeyType.runes, runes: [0x61], ctrl: true), // Ctrl+A
      0x02 => const Key(KeyType.runes, runes: [0x62], ctrl: true), // Ctrl+B
      0x03 => const Key(KeyType.runes, runes: [0x63], ctrl: true), // Ctrl+C
      0x04 => const Key(KeyType.runes, runes: [0x64], ctrl: true), // Ctrl+D
      0x05 => const Key(KeyType.runes, runes: [0x65], ctrl: true), // Ctrl+E
      0x06 => const Key(KeyType.runes, runes: [0x66], ctrl: true), // Ctrl+F
      0x07 => const Key(
        KeyType.runes,
        runes: [0x67],
        ctrl: true,
      ), // Ctrl+G (bell)
      0x08 => const Key(KeyType.backspace), // Ctrl+H (backspace)
      0x09 => const Key(KeyType.tab), // Ctrl+I (tab)
      0x0a => const Key(KeyType.enter), // Ctrl+J (newline)
      0x0b => const Key(KeyType.runes, runes: [0x6b], ctrl: true), // Ctrl+K
      0x0c => const Key(KeyType.runes, runes: [0x6c], ctrl: true), // Ctrl+L
      0x0d => const Key(KeyType.enter), // Ctrl+M (carriage return)
      0x0e => const Key(KeyType.runes, runes: [0x6e], ctrl: true), // Ctrl+N
      0x0f => const Key(KeyType.runes, runes: [0x6f], ctrl: true), // Ctrl+O
      0x10 => const Key(KeyType.runes, runes: [0x70], ctrl: true), // Ctrl+P
      0x11 => const Key(KeyType.runes, runes: [0x71], ctrl: true), // Ctrl+Q
      0x12 => const Key(KeyType.runes, runes: [0x72], ctrl: true), // Ctrl+R
      0x13 => const Key(KeyType.runes, runes: [0x73], ctrl: true), // Ctrl+S
      0x14 => const Key(KeyType.runes, runes: [0x74], ctrl: true), // Ctrl+T
      0x15 => const Key(KeyType.runes, runes: [0x75], ctrl: true), // Ctrl+U
      0x16 => const Key(KeyType.runes, runes: [0x76], ctrl: true), // Ctrl+V
      0x17 => const Key(KeyType.runes, runes: [0x77], ctrl: true), // Ctrl+W
      0x18 => const Key(KeyType.runes, runes: [0x78], ctrl: true), // Ctrl+X
      0x19 => const Key(KeyType.runes, runes: [0x79], ctrl: true), // Ctrl+Y
      0x1a => const Key(KeyType.runes, runes: [0x7a], ctrl: true), // Ctrl+Z
      _ => const Key(KeyType.unknown),
    };
  }

  /// Parses a single UTF-8 grapheme cluster starting at [startIndex].
  ///
  /// Returns null if more bytes are required.
  Key? _parseUtf8Cluster(int startIndex) {
    if (_buffer.length <= startIndex) return null;

    final firstByte = _buffer[startIndex] & 0xff;
    if (firstByte < 0x80) {
      // Fast path: single-byte ASCII.
      if (startIndex == 0) _buffer.removeAt(0);
      if (firstByte == 0x20) return const Key(KeyType.space);
      return Key(KeyType.runes, runes: [firstByte]);
    }

    // Decode runes until we can determine the first grapheme cluster boundary.
    var offset = startIndex;
    final sb = StringBuffer();

    while (offset < _buffer.length) {
      final decoded = _decodeOneRuneAt(_buffer, offset);
      if (!decoded.ok) {
        if (decoded.consumed == 0) return null; // incomplete
        if (startIndex == 0) _buffer.removeAt(0);
        return const Key(KeyType.unknown);
      }

      offset += decoded.consumed;
      sb.writeCharCode(decoded.rune);

      final s = sb.toString();
      final it = uni.graphemes(s).iterator;
      if (!it.moveNext()) continue;
      final firstCluster = it.current;
      if (it.moveNext()) {
        final bytesConsumed = utf8.encode(firstCluster).length;
        if (startIndex == 0) _buffer.removeRange(0, bytesConsumed);
        return Key(KeyType.runes, runes: uni.codePoints(firstCluster));
      }
    }

    // Only one grapheme cluster in the available buffer.
    final cluster = sb.toString();
    if (startIndex == 0) _buffer.removeRange(0, offset - startIndex);
    return Key(KeyType.runes, runes: uni.codePoints(cluster));
  }
}

({int consumed, int rune, bool ok}) _decodeOneRuneAt(List<int> buf, int start) {
  if (start >= buf.length) return (consumed: 0, rune: 0, ok: false);
  final b0 = buf[start] & 0xff;
  if (b0 < 0x80) return (consumed: 1, rune: b0, ok: true);

  int need;
  int min;
  int rune;
  if ((b0 & 0xE0) == 0xC0) {
    need = 2;
    min = 0x80;
    rune = b0 & 0x1F;
  } else if ((b0 & 0xF0) == 0xE0) {
    need = 3;
    min = 0x800;
    rune = b0 & 0x0F;
  } else if ((b0 & 0xF8) == 0xF0) {
    need = 4;
    min = 0x10000;
    rune = b0 & 0x07;
  } else {
    return (consumed: 1, rune: b0, ok: false);
  }

  if (start + need > buf.length) return (consumed: 0, rune: 0, ok: false);

  for (var i = 1; i < need; i++) {
    final bx = buf[start + i] & 0xff;
    if ((bx & 0xC0) != 0x80) return (consumed: 1, rune: b0, ok: false);
    rune = (rune << 6) | (bx & 0x3F);
  }

  if (rune < min) return (consumed: 1, rune: b0, ok: false);
  if (rune > 0x10ffff) return (consumed: 1, rune: b0, ok: false);
  if (rune >= 0xD800 && rune <= 0xDFFF) {
    return (consumed: 1, rune: b0, ok: false);
  }

  return (consumed: need, rune: rune, ok: true);
}
