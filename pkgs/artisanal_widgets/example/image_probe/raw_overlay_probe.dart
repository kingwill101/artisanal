#!/usr/bin/env dart

import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:artisanal/artisanal.dart' as artisanal;
import 'package:artisanal/uv.dart' as uv;
import 'package:image/image.dart' as img;

const _esc = '\x1b';
const _imageCols = 32;
const _imageRows = 11;

late _RawTerminal _terminal;

Future<void> main(List<String> args) async {
  final config = _RawOverlayConfig.parse(args);
  if (config.help) {
    io.stdout.writeln(_RawOverlayConfig.usage());
    return;
  }
  if (config.error != null) {
    io.stderr.writeln(config.error);
    io.stderr.writeln('');
    io.stderr.writeln(_RawOverlayConfig.usage());
    io.exitCode = 64;
    return;
  }

  final image = img.decodeImage(_generateProbeImage(96, 64))!;
  final stages = config.stage == null
      ? _RawStage.values
      : <_RawStage>[config.stage!];

  if (config.dump) {
    final buffer = StringBuffer();
    _terminal = _RawTerminal.capture(buffer);
    _writeEnterScreen(config);
    for (final stage in stages) {
      await _drawStage(image, stage, hold: Duration.zero);
    }
    _writeExitScreen(config);
    io.stdout.write(_describeRaw(buffer.toString()));
    return;
  }

  _terminal = _RawTerminal.stdout();
  _writeEnterScreen(config);
  try {
    for (final stage in stages) {
      await _drawStage(image, stage, hold: config.hold);
    }
  } finally {
    _writeExitScreen(config);
    await _terminal.flush();
  }
}

final class _RawOverlayConfig {
  const _RawOverlayConfig({
    required this.help,
    required this.dump,
    required this.altScreen,
    required this.hideCursor,
    required this.stage,
    required this.hold,
    required this.error,
  });

  final bool help;
  final bool dump;
  final bool altScreen;
  final bool hideCursor;
  final _RawStage? stage;
  final Duration hold;
  final String? error;

  static _RawOverlayConfig parse(List<String> args) {
    var help = false;
    var dump = false;
    var altScreen = true;
    var hideCursor = true;
    _RawStage? stage;
    var hold = const Duration(seconds: 4);
    String? error;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      String? readValue(String name) {
        if (i + 1 >= args.length) {
          error = 'Missing value for $name.';
          return null;
        }
        return args[++i];
      }

      if (arg == '-h' || arg == '--help') {
        help = true;
      } else if (arg == '--dump') {
        dump = true;
      } else if (arg == '--no-alt-screen') {
        altScreen = false;
      } else if (arg == '--show-cursor') {
        hideCursor = false;
      } else if (arg == '--stage') {
        final value = readValue(arg);
        if (value == null) continue;
        stage = _parseStage(value);
        if (stage == null) error = 'Unknown stage "$value".';
      } else if (arg == '--hold') {
        final value = readValue(arg);
        final seconds = value == null ? null : int.tryParse(value);
        if (seconds == null || seconds < 1) {
          error = 'Hold must be a positive number of seconds.';
        } else {
          hold = Duration(seconds: seconds);
        }
      } else if (arg.startsWith('--stage=')) {
        final value = arg.substring('--stage='.length);
        stage = _parseStage(value);
        if (stage == null) error = 'Unknown stage "$value".';
      } else if (arg.startsWith('--hold=')) {
        final value = arg.substring('--hold='.length);
        final seconds = int.tryParse(value);
        if (seconds == null || seconds < 1) {
          error = 'Hold must be a positive number of seconds.';
        } else {
          hold = Duration(seconds: seconds);
        }
      } else {
        error = 'Unknown argument "$arg".';
      }
    }

    return _RawOverlayConfig(
      help: help,
      dump: dump,
      altScreen: altScreen,
      hideCursor: hideCursor,
      stage: stage,
      hold: hold,
      error: error,
    );
  }

  static String usage() {
    return '''
Raw Image Overlay Probe

Usage:
  dart run pkgs/artisanal_widgets/example/image_probe/raw_overlay_probe.dart
  dart run pkgs/artisanal_widgets/example/image_probe/raw_overlay_probe.dart --stage unicode-only
  dart run pkgs/artisanal_widgets/example/image_probe/raw_overlay_probe.dart --stage kitty-bottom --hold 10
  dart run pkgs/artisanal_widgets/example/image_probe/raw_overlay_probe.dart --stage kitty-cursor --dump

Stages:
  unicode-only     Draw only the Unicode image and park cursor on its row.
  kitty-cursor     Draw Kitty + Unicode and leave cursor on the image row.
  kitty-bottom     Draw Kitty + Unicode and move cursor below the images.
  kitty-c1-bottom  Draw Kitty C=1 + Unicode and move cursor below the images.

If the horizontal bar appears in unicode-only, the issue is not Kitty APC.
If it only appears in kitty-cursor, the final cursor row is the trigger.
If it appears in kitty-bottom or kitty-c1-bottom, capture that stage output.

Options:
  --dump           Print an ASCII token transcript instead of drawing.
  --no-alt-screen  Draw in the current screen instead of the alternate screen.
  --show-cursor    Leave the cursor visible while holding the frame.
''';
  }
}

enum _RawStage { unicodeOnly, kittyCursor, kittyBottom, kittyC1Bottom }

_RawStage? _parseStage(String value) {
  return switch (value.toLowerCase()) {
    'unicode-only' || 'unicode' => _RawStage.unicodeOnly,
    'kitty-cursor' || 'cursor' => _RawStage.kittyCursor,
    'kitty-bottom' || 'bottom' => _RawStage.kittyBottom,
    'kitty-c1-bottom' || 'c1' => _RawStage.kittyC1Bottom,
    _ => null,
  };
}

Future<void> _drawStage(
  img.Image image,
  _RawStage stage, {
  required Duration hold,
}) async {
  _terminal.write(artisanal.KittyImage.deleteAll());
  _terminal.write('$_esc[2J$_esc[H');

  final title = switch (stage) {
    _RawStage.unicodeOnly => 'unicode-only',
    _RawStage.kittyCursor => 'kitty-cursor',
    _RawStage.kittyBottom => 'kitty-bottom',
    _RawStage.kittyC1Bottom => 'kitty-c1-bottom',
  };
  final description = switch (stage) {
    _RawStage.unicodeOnly =>
      'No Kitty APC. Cursor is intentionally parked on the image row.',
    _RawStage.kittyCursor =>
      'Kitty + Unicode. Cursor is intentionally parked on the image row.',
    _RawStage.kittyBottom =>
      'Kitty + Unicode. Cursor is moved below both images.',
    _RawStage.kittyC1Bottom =>
      'Kitty C=1 + Unicode. Cursor is moved below both images.',
  };

  _writeAt(2, 3, 'Raw Image Overlay Probe');
  _writeAt(4, 3, 'stage: $title');
  _writeAt(5, 3, description);
  _writeAt(7, 3, 'Watch for the horizontal bar. Hold: ${hold.inSeconds}s.');

  _drawCard(row: 9, col: 3, width: 36, height: 16, title: 'kitty area');
  _drawCard(row: 9, col: 43, width: 36, height: 16, title: 'unicode control');

  if (stage != _RawStage.unicodeOnly) {
    final useC1 = stage == _RawStage.kittyC1Bottom;
    _writeKittyImage(image, row: 12, col: 5, useC1: useC1);
  }

  _writeUnicodeImage(image, row: 12, col: 45);

  switch (stage) {
    case _RawStage.unicodeOnly || _RawStage.kittyCursor:
      _move(15, 1);
    case _RawStage.kittyBottom || _RawStage.kittyC1Bottom:
      _move(28, 1);
  }

  await _terminal.flush();
  if (hold > Duration.zero) await Future<void>.delayed(hold);
}

void _writeKittyImage(
  img.Image image, {
  required int row,
  required int col,
  required bool useC1,
}) {
  _move(row, col);
  var sequence = artisanal.KittyImage.encode(
    image,
    id: useC1 ? 202 : 201,
    columns: _imageCols,
    rows: _imageRows,
  );
  if (useC1) {
    sequence = sequence.replaceFirst(',q=2', ',C=1,q=2');
  }
  _terminal.write(sequence);
  if (useC1) _terminal.write('$_esc[${_imageCols}C');
}

void _writeUnicodeImage(img.Image image, {required int row, required int col}) {
  final canvas = uv.Canvas(_imageCols, _imageRows);
  uv.HalfBlockImageDrawable(
    image,
    columns: _imageCols,
    rows: _imageRows,
  ).draw(canvas, canvas.bounds());

  final lines = canvas.render().split('\n');
  for (var i = 0; i < lines.length && i < _imageRows; i++) {
    _writeAt(row + i, col, lines[i]);
  }
}

void _drawCard({
  required int row,
  required int col,
  required int width,
  required int height,
  required String title,
}) {
  _writeAt(row, col, '+${'-' * (width - 2)}+');
  for (var y = row + 1; y < row + height - 1; y++) {
    _writeAt(y, col, '|${' ' * (width - 2)}|');
  }
  _writeAt(row + height - 1, col, '+${'-' * (width - 2)}+');
  _writeAt(row + 1, col + 2, title);
}

void _writeAt(int row, int col, String text) {
  _move(row, col);
  _terminal.write(text);
}

void _move(int row, int col) {
  _terminal.write('$_esc[$row;${col}H');
}

void _writeEnterScreen(_RawOverlayConfig config) {
  if (config.altScreen) _terminal.write('$_esc[?1049h');
  if (config.hideCursor) _terminal.write('$_esc[?25l');
}

void _writeExitScreen(_RawOverlayConfig config) {
  _terminal.write(artisanal.KittyImage.deleteAll());
  if (config.hideCursor) _terminal.write('$_esc[?25h');
  if (config.altScreen) _terminal.write('$_esc[?1049l');
}

String _describeRaw(String raw) {
  final kittyDisplays = _count(raw, '${_esc}_Ga=T');
  final kittyDeletes = _count(raw, '${_esc}_Ga=d,d=a');
  final csiMoves = RegExp('\x1b\\[([0-9]*);([0-9]*)H').allMatches(raw).length;
  final buffer = StringBuffer()
    ..writeln('raw_overlay_probe dump')
    ..writeln('bytes: ${raw.codeUnits.length}')
    ..writeln('kitty displays: $kittyDisplays')
    ..writeln('kitty delete-all: $kittyDeletes')
    ..writeln('cursor position moves: $csiMoves')
    ..writeln('')
    ..writeln('tokens:');

  for (final token in _tokenizeRaw(raw)) {
    buffer.writeln(token);
  }
  return buffer.toString();
}

int _count(String value, String needle) {
  var count = 0;
  var index = 0;
  while (true) {
    index = value.indexOf(needle, index);
    if (index == -1) return count;
    count++;
    index += needle.length;
  }
}

Iterable<String> _tokenizeRaw(String raw) sync* {
  var index = 0;
  while (index < raw.length) {
    final unit = raw.codeUnitAt(index);
    if (unit == 0x1b) {
      if (index + 1 < raw.length && raw.codeUnitAt(index + 1) == 0x5b) {
        final end = _findCsiEnd(raw, index + 2);
        if (end != -1) {
          yield _token(index, 'CSI ${raw.substring(index + 2, end + 1)}');
          index = end + 1;
          continue;
        }
      }
      if (index + 2 < raw.length &&
          raw.codeUnitAt(index + 1) == 0x5f &&
          raw.codeUnitAt(index + 2) == 0x47) {
        final end = raw.indexOf('$_esc\\', index + 3);
        if (end != -1) {
          final body = raw.substring(index + 3, end);
          final semicolon = body.indexOf(';');
          final header = semicolon == -1 ? body : body.substring(0, semicolon);
          final payloadChars = semicolon == -1
              ? 0
              : body.length - semicolon - 1;
          yield _token(
            index,
            'KITTY header="${_ascii(header)}" payloadChars=$payloadChars',
          );
          index = end + 2;
          continue;
        }
      }
      yield _token(index, 'ESC 0x${unit.toRadixString(16)}');
      index++;
      continue;
    }

    final nextEscape = raw.indexOf(_esc, index);
    final end = nextEscape == -1 ? raw.length : nextEscape;
    final text = raw.substring(index, end);
    if (text.isNotEmpty) {
      yield _token(index, 'TEXT len=${text.length} "${_ascii(text)}"');
    }
    index = end;
  }
}

int _findCsiEnd(String raw, int start) {
  for (var i = start; i < raw.length; i++) {
    final unit = raw.codeUnitAt(i);
    if (unit >= 0x40 && unit <= 0x7e) return i;
  }
  return -1;
}

String _token(int offset, String value) {
  return '${offset.toString().padLeft(6, '0')} $value';
}

String _ascii(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (rune >= 0x20 && rune <= 0x7e) {
      final char = String.fromCharCode(rune);
      if (char == r'\' || char == '"') {
        buffer.write(r'\');
      }
      buffer.write(char);
    } else {
      buffer.write(
        '<U+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}>',
      );
    }
  }
  return buffer.toString();
}

final class _RawTerminal {
  _RawTerminal.stdout() : _buffer = null;

  _RawTerminal.capture(StringBuffer buffer) : _buffer = buffer;

  final StringBuffer? _buffer;

  void write(String value) {
    final buffer = _buffer;
    if (buffer != null) {
      buffer.write(value);
    } else {
      io.stdout.write(value);
    }
  }

  Future<void> flush() async {
    if (_buffer == null) await io.stdout.flush();
  }
}

Uint8List _generateProbeImage(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final checker = ((x ~/ 8) + (y ~/ 8)).isEven;
      final r = checker ? 30 + (x * 180 ~/ width) : 240;
      final g = checker ? 80 + (y * 150 ~/ height) : 90;
      final b = checker ? 230 : 40 + (x * 120 ~/ width);
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
