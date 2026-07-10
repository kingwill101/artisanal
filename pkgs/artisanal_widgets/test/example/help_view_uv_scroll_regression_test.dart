import 'dart:async';
import 'dart:io' show Platform;

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

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

String _normalizeView(String view, int width, int height) {
  final lines = view.split('\n');
  final normalized = <String>[];
  for (var i = 0; i < height; i++) {
    final line = i < lines.length ? Layout.stripAnsi(lines[i]) : '';
    if (line.length >= width) {
      normalized.add(line.substring(0, width));
    } else {
      normalized.add(line.padRight(width));
    }
  }
  return normalized.join('\n');
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
      if (_autowrap) {
        _atPhantom = true;
      }
      return;
    }
    _x++;
    if (_x >= width) {
      _x = width - 1;
    }
  }

  String dump() => _rows.map((row) => row.join()).join('\n');
}

class _HelpScrollFixture extends StatelessWidget {
  _HelpScrollFixture();

  final WidgetScrollController _scrollController = WidgetScrollController();
  final KeyMap _keyMap = _FixtureKeyMap();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final contentWidth = (MediaQuery.of(context).size.width.round() - 4).clamp(
      32,
      2000,
    );
    final dividerWidth = (contentWidth - 2).clamp(24, 2000);

    return Container(
      padding: const EdgeInsets.all(1),
      color: theme.background,
      child: Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        child: ScrollView(
          controller: _scrollController,
          child: Column(
            width: contentWidth,
            gap: 1,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('HelpView Showcase', style: theme.titleLarge),
              Text(
                'Scroll downward to move the preview frame off-screen.',
                style: label,
              ),
              Divider(width: dividerWidth),
              Text('Interactive Preview', style: theme.titleMedium),
              Container(
                color: theme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  gap: 1,
                  children: [
                    Text('Compact mode', style: theme.labelSmall),
                    HelpView(keyMap: _keyMap),
                  ],
                ),
              ),
              Divider(width: dividerWidth),
              Text('Compact Footer Style', style: theme.titleMedium),
              HelpView(keyMap: _keyMap),
              Divider(width: dividerWidth),
              Text('Full Grouped Help', style: theme.titleMedium),
              HelpView(keyMap: _keyMap, showAll: true, columnGap: 6),
              Divider(width: dividerWidth),
              Text('Status Bar Pairing', style: theme.titleMedium),
              StatusBar(
                items: [
                  KeyHint(keyLabel: '?', description: 'toggle preview'),
                  KeyHint(keyLabel: 'j/k', description: 'navigate'),
                  KeyHint(keyLabel: 'q', description: 'quit'),
                ],
              ),
              Divider(width: dividerWidth),
              for (var i = 0; i < 8; i++)
                Text('Filler section ${i + 1}', style: theme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _FixtureKeyMap extends KeyMap {
  _FixtureKeyMap() {
    shortHelp = [commands, search, help, quit];
    fullHelp = [
      [previous, next, open],
      [commands, search],
      [help, quit],
    ];
  }

  final previous = KeyBinding.withHelp(['up', 'k'], '↑/k', 'previous item');
  final next = KeyBinding.withHelp(['down', 'j'], '↓/j', 'next item');
  final open = KeyBinding.withHelp(['enter'], '↵', 'open item');
  final commands = KeyBinding.withHelp(['ctrl+p'], 'ctrl+p', 'commands');
  final search = KeyBinding.withHelp(['/'], '/', 'search');
  final help = KeyBinding.withHelp(['?'], '?', 'toggle help');
  final quit = KeyBinding.withHelp(['q'], 'q', 'quit');
}

void main() {
  test(
    'UV renderer matches WidgetApp view after wheel scrolling HelpView layout',
    () async {
      if (Platform.isWindows) return;

      const width = 100;
      const height = 24;
      final terminal = StringTerminal(
        terminalWidth: width,
        terminalHeight: height,
      );
      final program = Program<WidgetApp>(
        WidgetApp(_HelpScrollFixture()),
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
      final grid = _TermGrid(width, height);
      final runFuture = program.run();

      try {
        await _waitForRender(
          () => terminal.output.isNotEmpty && program.currentModel != null,
          reason: 'Initial UV render did not produce output',
        );
        grid.apply(terminal.output);
        terminal.clear();

        for (var i = 0; i < 8; i++) {
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
            reason: 'Wheel scroll did not produce renderer output',
          );
          grid.apply(terminal.output);
          terminal.clear();
        }

        final expected = _normalizeView(
          program.currentModel!.view() as String,
          width,
          height,
        );
        final observed = grid.dump();

        expect(expected, contains('Status Bar Pairing'));
        expect(expected, isNot(contains('HelpView Showcase')));
        expect(observed, expected);
      } finally {
        program.quit();
        try {
          await runFuture.timeout(const Duration(seconds: 2));
        } catch (_) {
          program.kill();
        }
      }
    },
  );
}
