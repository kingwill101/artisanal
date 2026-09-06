import 'dart:convert';

import 'package:artisanal/style.dart';
import 'package:characters/characters.dart';

final class _Cell {
  _Cell();
  String text = ' ';
  String sgr = '';
}

/// A small, transport-independent ANSI/VT screen model.
///
/// Feed bytes from a local PTY, SSH connection, or fixture to [write]. The
/// model intentionally owns no process so it remains deterministic in tests.
final class VirtualTerminal {
  /// Creates a terminal with [width] columns and [height] rows.
  VirtualTerminal({this.width = 80, this.height = 24})
    : assert(width > 0),
      assert(height > 0),
      _rows = List.generate(
        height,
        (_) => List.generate(width, (_) => _Cell()),
      );

  int width;
  int height;
  List<List<_Cell>> _rows;
  int cursorX = 0;
  int cursorY = 0;
  String _sgr = '';
  String _pending = '';
  final List<int> _pendingBytes = [];
  final List<void Function()> _listeners = [];

  /// Whether the emulated cursor is visible.
  bool cursorVisible = true;

  /// Adds a callback invoked after writes and resizes.
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Removes a callback.
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Releases listeners held by this model.
  void dispose() => _listeners.clear();

  /// Changes the screen dimensions while retaining the top-left contents.
  void resize(int newWidth, int newHeight) {
    if (newWidth <= 0 || newHeight <= 0) {
      throw ArgumentError('Terminal dimensions must be positive.');
    }
    if (newWidth == width && newHeight == height) return;
    final next = List.generate(
      newHeight,
      (y) => List.generate(
        newWidth,
        (x) => y < height && x < width ? _rows[y][x] : _Cell(),
      ),
    );
    width = newWidth;
    height = newHeight;
    _rows = next;
    cursorX = cursorX.clamp(0, width - 1);
    cursorY = cursorY.clamp(0, height - 1);
    _notify();
  }

  /// Processes a chunk of UTF-8 terminal output.
  void write(List<int> bytes) {
    _pendingBytes.addAll(bytes);
    for (
      var suffix = 0;
      suffix <= 3 && suffix <= _pendingBytes.length;
      suffix++
    ) {
      final completeLength = _pendingBytes.length - suffix;
      try {
        final text = utf8.decode(
          _pendingBytes.sublist(0, completeLength),
          allowMalformed: false,
        );
        _pendingBytes.removeRange(0, completeLength);
        if (text.isNotEmpty) writeText(text);
        return;
      } on FormatException {
        // A trailing UTF-8 sequence may be completed by the next chunk.
      }
    }
    if (_pendingBytes.length > 4) {
      final text = utf8.decode(_pendingBytes, allowMalformed: true);
      _pendingBytes.clear();
      writeText(text);
    }
  }

  /// Processes terminal output already decoded as text.
  void writeText(String value) {
    final input = '$_pending$value';
    _pending = '';
    for (var i = 0; i < input.length;) {
      if (input.codeUnitAt(i) == 0x1b) {
        if (i + 1 >= input.length) {
          _pending = input.substring(i);
          break;
        }
        if (input[i + 1] == '[') {
          final end = _csiEnd(input, i + 2);
          if (end < 0) {
            _pending = input.substring(i);
            break;
          }
          _handleCsi(input.substring(i + 2, end), input[end]);
          i = end + 1;
          continue;
        }
        if (input[i + 1] == ']') {
          final end = _oscEnd(input, i + 2);
          if (end < 0) {
            _pending = input.substring(i);
            break;
          }
          i = input.codeUnitAt(end) == 0x07 ? end + 1 : end + 2;
          continue;
        }
        i += 2;
        continue;
      }
      final codeUnit = input.codeUnitAt(i);
      if (codeUnit == 8 || codeUnit == 9 || codeUnit == 10 || codeUnit == 13) {
        _print(String.fromCharCode(codeUnit));
        i++;
        continue;
      }
      final character = input.substring(i).characters.first;
      _print(character);
      i += character.length;
    }
    _notify();
  }

  int _csiEnd(String input, int start) {
    for (var i = start; i < input.length; i++) {
      final c = input.codeUnitAt(i);
      if (c >= 0x40 && c <= 0x7e) return i;
    }
    return -1;
  }

  int _oscEnd(String input, int start) {
    for (var i = start; i < input.length; i++) {
      if (input.codeUnitAt(i) == 0x07) return i;
      if (input.codeUnitAt(i) == 0x1b &&
          i + 1 < input.length &&
          input[i + 1] == r'\') {
        return i;
      }
    }
    return -1;
  }

  void _print(String character) {
    switch (character) {
      case '\r':
        cursorX = 0;
        return;
      case '\n':
        _lineFeed();
        return;
      case '\b':
        cursorX = (cursorX - 1).clamp(0, width - 1);
        return;
      case '\t':
        cursorX = ((cursorX ~/ 8 + 1) * 8).clamp(0, width - 1);
        return;
    }
    if (cursorX >= width) {
      cursorX = 0;
      _lineFeed();
    }
    final displayWidth = Layout.getWidth(character).clamp(1, 2);
    if (displayWidth == 2 && cursorX == width - 1) {
      cursorX = 0;
      _lineFeed();
    }
    _rows[cursorY][cursorX]
      ..text = character
      ..sgr = _sgr;
    if (displayWidth == 2) {
      _rows[cursorY][cursorX + 1]
        ..text = ''
        ..sgr = _sgr;
    }
    cursorX += displayWidth;
  }

  void _lineFeed() {
    cursorY++;
    if (cursorY < height) return;
    _rows.removeAt(0);
    _rows.add(List.generate(width, (_) => _Cell()));
    cursorY = height - 1;
  }

  void _handleCsi(String body, String command) {
    final private = body.startsWith('?');
    final raw = private ? body.substring(1) : body;
    final params = raw.isEmpty
        ? <int>[]
        : raw.split(';').map((v) => int.tryParse(v) ?? 0).toList();
    int param(int index, [int fallback = 1]) =>
        index < params.length && params[index] != 0 ? params[index] : fallback;
    if (private) {
      if (params.contains(25)) cursorVisible = command == 'h';
      return;
    }
    switch (command) {
      case 'A':
        cursorY = (cursorY - param(0)).clamp(0, height - 1);
      case 'B':
        cursorY = (cursorY + param(0)).clamp(0, height - 1);
      case 'C':
        cursorX = (cursorX + param(0)).clamp(0, width - 1);
      case 'D':
        cursorX = (cursorX - param(0)).clamp(0, width - 1);
      case 'H':
      case 'f':
        cursorY = (param(0) - 1).clamp(0, height - 1);
        cursorX = (param(1) - 1).clamp(0, width - 1);
      case 'J':
        if ((params.firstOrNull ?? 0) == 2) _clearScreen();
      case 'K':
        _clearLine(params.firstOrNull ?? 0);
      case 'm':
        final effective = params.isEmpty ? const [0] : params;
        if (effective.contains(0)) _sgr = '';
        final remaining = effective.where((value) => value != 0).toList();
        if (remaining.isNotEmpty) {
          _sgr += '\x1b[${remaining.join(';')}m';
        }
    }
  }

  void _clearScreen() {
    for (final row in _rows) {
      for (final cell in row) {
        cell
          ..text = ' '
          ..sgr = '';
      }
    }
  }

  void _clearLine(int mode) {
    final start = mode == 0 ? cursorX : 0;
    final end = mode == 1 ? cursorX + 1 : width;
    for (var x = start; x < end; x++) {
      _rows[cursorY][x]
        ..text = ' '
        ..sgr = '';
    }
  }

  /// Renders the current screen as ANSI-styled text.
  ///
  /// Set [showCursor] when the host terminal cursor is hidden.
  String render({bool showCursor = false}) {
    final out = StringBuffer();
    for (var y = 0; y < height; y++) {
      var active = '';
      for (var x = 0; x < width; x++) {
        final cell = _rows[y][x];
        if (cell.sgr != active) {
          if (active.isNotEmpty) out.write('\x1b[0m');
          if (cell.sgr.isNotEmpty) out.write(cell.sgr);
          active = cell.sgr;
        }
        final isCursor =
            showCursor &&
            cursorVisible &&
            y == cursorY &&
            x == cursorX.clamp(0, width - 1);
        if (isCursor) out.write('\x1b[7m');
        out.write(cell.text);
        if (isCursor) {
          out.write('\x1b[27m');
          if (active.isNotEmpty) out.write(active);
        }
      }
      if (active.isNotEmpty) out.write('\x1b[0m');
      if (y + 1 < height) out.write('\n');
    }
    return out.toString();
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}
