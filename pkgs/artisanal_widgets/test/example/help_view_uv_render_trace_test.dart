import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:artisanal/style.dart' show Layout;
import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import '../../example/help_view/main.dart';

const _traceEnv = 'TRACE_HELP_VIEW_UV_RENDER';

Future<void> _waitForRender(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
  String? reason,
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail(reason ?? 'Timed out waiting for render');
}

void _dumpLines(String label, List<String> lines, {int maxLines = 16}) {
  final limit = math.min(lines.length, maxLines);
  print('=== $label ===');
  for (var i = 0; i < limit; i++) {
    final lineNo = i.toString().padLeft(2, '0');
    print('$lineNo| ${lines[i]}');
  }
}

final class _TermGrid {
  _TermGrid(this.width, this.height)
    : _rows = List<List<String>>.generate(
        height,
        (_) => List<String>.filled(width, ' ', growable: false),
        growable: false,
      );

  final int width;
  final int height;
  final List<List<String>> _rows;

  int _x = 0;
  int _y = 0;
  bool _autowrap = true;
  bool _atPhantom = false;

  void apply(String s) {
    var i = 0;
    while (i < s.length) {
      final ch = s.codeUnitAt(i);
      if (ch == 0x1b) {
        i = _consumeEscape(s, i);
        continue;
      }
      if (ch == 0x0d) {
        _x = 0;
        _atPhantom = false;
        i++;
        continue;
      }
      if (ch == 0x0a) {
        _atPhantom = false;
        if (_y >= height - 1) {
          _scrollUp(1);
          _y = height - 1;
        } else {
          _y++;
        }
        i++;
        continue;
      }
      _putChar(String.fromCharCode(ch));
      i++;
    }
  }

  int _consumeEscape(String s, int i) {
    if (i + 1 >= s.length) return s.length;
    final next = s.codeUnitAt(i + 1);

    if (next == 0x5b) {
      final end = _findCsiEnd(s, i + 2);
      if (end == -1) return s.length;
      final cmd = s.codeUnitAt(end);
      final paramsRaw = s.substring(i + 2, end);
      final params = _parseParams(paramsRaw);
      _applyCsi(cmd, paramsRaw, params);
      return end + 1;
    }

    if (next == 0x5d) {
      final bel = s.indexOf('\x07', i + 2);
      final st = s.indexOf('\x1b\\', i + 2);
      if (bel != -1 && (st == -1 || bel < st)) return bel + 1;
      if (st != -1) return st + 2;
      return s.length;
    }

    if (next == 0x4d) {
      if (_y <= 0) {
        _scrollDown(1, top: 0);
        _y = 0;
      } else {
        _y--;
      }
      return i + 2;
    }

    return i + 2;
  }

  int _findCsiEnd(String s, int start) {
    for (var j = start; j < s.length; j++) {
      final c = s.codeUnitAt(j);
      if (c >= 0x40 && c <= 0x7e) return j;
    }
    return -1;
  }

  List<int> _parseParams(String raw) {
    if (raw.isEmpty) return const [];
    final cleaned = raw.replaceAll(RegExp(r'[^0-9;]'), '');
    if (cleaned.isEmpty) return const [];
    return cleaned.split(';').map((p) => int.tryParse(p) ?? 0).toList();
  }

  void _applyCsi(int cmd, String rawParams, List<int> params) {
    _atPhantom = false;
    if (cmd == 0x48 || cmd == 0x66) {
      final row = (params.isEmpty ? 1 : params[0]).clamp(1, height);
      final col = (params.length < 2 ? 1 : params[1]).clamp(1, width);
      _y = row - 1;
      _x = col - 1;
      return;
    }
    if (cmd == 0x47) {
      final col = (params.isEmpty ? 1 : params[0]).clamp(1, width);
      _x = col - 1;
      return;
    }
    if (cmd == 0x64) {
      final row = (params.isEmpty ? 1 : params[0]).clamp(1, height);
      _y = row - 1;
      return;
    }

    final n = (params.isEmpty ? 1 : params[0]).clamp(1, 1000000);
    switch (cmd) {
      case 0x41:
        _y = (_y - n).clamp(0, height - 1);
        return;
      case 0x42:
        _y = (_y + n).clamp(0, height - 1);
        return;
      case 0x43:
        _x = (_x + n).clamp(0, width - 1);
        return;
      case 0x44:
        _x = (_x - n).clamp(0, width - 1);
        return;
      case 0x4b:
        _eraseLineRight();
        return;
      case 0x4a:
        _eraseScreenBelow();
        return;
      case 0x53:
        _scrollUp(n);
        return;
      case 0x54:
        _scrollDown(n, top: 0);
        return;
      case 0x4c:
        _scrollDown(n, top: _y);
        return;
      case 0x4d:
        _scrollUp(n, top: _y);
        return;
      case 0x68:
        if (rawParams.contains('?7')) _autowrap = true;
        return;
      case 0x6c:
        if (rawParams.contains('?7')) _autowrap = false;
        return;
      default:
        return;
    }
  }

  void _eraseLineRight() {
    for (var x = _x; x < width; x++) {
      _rows[_y][x] = ' ';
    }
  }

  void _eraseScreenBelow() {
    _eraseLineRight();
    for (var y = _y + 1; y < height; y++) {
      for (var x = 0; x < width; x++) {
        _rows[y][x] = ' ';
      }
    }
  }

  void _scrollUp(int count, {int top = 0}) {
    if (count <= 0 || top < 0 || top >= height) return;
    final n = count.clamp(0, height - top);
    for (var y = top; y < height - n; y++) {
      _rows[y] = List<String>.from(_rows[y + n], growable: false);
    }
    for (var y = height - n; y < height; y++) {
      _rows[y] = List<String>.filled(width, ' ', growable: false);
    }
  }

  void _scrollDown(int count, {required int top}) {
    if (count <= 0 || top < 0 || top >= height) return;
    final n = count.clamp(0, height - top);
    for (var y = height - 1; y >= top + n; y--) {
      _rows[y] = List<String>.from(_rows[y - n], growable: false);
    }
    for (var y = top; y < top + n; y++) {
      _rows[y] = List<String>.filled(width, ' ', growable: false);
    }
  }

  void _putChar(String ch) {
    if (_atPhantom) {
      _x = 0;
      if (_y >= height - 1) {
        _scrollUp(1);
        _y = height - 1;
      } else {
        _y++;
      }
      _atPhantom = false;
    }
    if (_x < 0 || _y < 0 || _x >= width || _y >= height) return;
    _rows[_y][_x] = ch;
    if (_x == width - 1) {
      if (_autowrap) _atPhantom = true;
      return;
    }
    _x++;
  }

  List<String> lines() =>
      _rows.map((row) => row.join()).toList(growable: false);
}

void main() {
  test('diagnostic: trace UV terminal rendering while scrolling', () async {
    if (Platform.environment[_traceEnv] != '1') return;

    final initialDarkBackground = hasDarkBackground;
    setHasDarkBackground(false);

    const width = 100;
    const height = 24;
    final terminal = StringTerminal(
      terminalWidth: width,
      terminalHeight: height,
    );
    final grid = _TermGrid(width, height);
    final program = Program<WidgetApp>(
      createHelpViewApp(),
      options: const ProgramOptions(
        useUltravioletRenderer: true,
        altScreen: true,
        mouse: true,
        mouseMode: MouseMode.allMotion,
        signalHandlers: false,
        catchPanics: false,
      ),
      terminal: terminal,
    );
    final runFuture = program.run();

    try {
      await _waitForRender(
        () => terminal.output.isNotEmpty && program.currentModel != null,
        reason: 'Initial UV render did not produce output',
      );

      for (var step = 0; step <= 8; step++) {
        if (step > 0) {
          program.send(
            const MouseMsg(
              action: MouseAction.wheel,
              button: MouseButton.wheelDown,
              x: 10,
              y: 10,
            ),
          );
          await _waitForRender(
            () => terminal.output.isNotEmpty,
            reason: 'Wheel scroll did not produce UV output',
          );
        }

        final chunk = terminal.output;
        grid.apply(chunk);
        final rawLines = chunk.split('\n');
        _dumpLines('uv chunk $step raw', rawLines);
        _dumpLines(
          'uv chunk $step plain',
          rawLines.map(Layout.stripAnsi).toList(growable: false),
        );
        _dumpLines('uv screen $step', grid.lines());

        final currentView = program.currentModel!.view();
        final widgetView = switch (currentView) {
          View(:final content) => content,
          final other => other.toString(),
        };
        _dumpLines('widget view $step', widgetView.split('\n'));

        terminal.clear();
      }
    } finally {
      setHasDarkBackground(initialDarkBackground);
      program.quit();
      try {
        await runFuture.timeout(const Duration(seconds: 2));
      } catch (_) {
        program.kill();
      }
    }
  });
}
