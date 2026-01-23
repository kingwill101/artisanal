/// Multi-view demo with progress animation (Bubble Tea "views" example).
library;

import 'package:artisanal/artisanal.dart' show BasicColor, Style;
import 'package:artisanal/tui.dart' as tui;

const _progressBarWidth = 71;
const _progressFullChar = '█';
const _progressEmptyChar = '░';
const _dotChar = ' • ';

// Styles
final _keywordStyle = Style().foreground(const BasicColor('211'));
final _subtleStyle = Style().foreground(const BasicColor('241'));
final _ticksStyle = Style().foreground(const BasicColor('79'));
final _checkboxStyle = Style().foreground(const BasicColor('212'));
final _progressEmpty = _subtleStyle.render(_progressEmptyChar);
final _dotStyle = Style().foreground(const BasicColor('236')).render(_dotChar);
final _mainStyle = Style().margin(0, 0, 0, 2);

// Gradient for progress bar
final _ramp = _makeRampStyles('#B14FFF', '#00FFA3', _progressBarWidth);

// Messages
class TickMsg extends tui.Msg {
  const TickMsg();
}

class FrameMsg extends tui.Msg {
  const FrameMsg();
}

class ViewsModel implements tui.Model {
  ViewsModel({
    required this.choice,
    required this.chosen,
    required this.ticks,
    required this.frames,
    required this.progress,
    required this.loaded,
    required this.quitting,
  });

  factory ViewsModel.initial() => ViewsModel(
    choice: 0,
    chosen: false,
    ticks: 10,
    frames: 0,
    progress: 0,
    loaded: false,
    quitting: false,
  );

  final int choice;
  final bool chosen;
  final int ticks;
  final int frames;
  final double progress;
  final bool loaded;
  final bool quitting;

  @override
  tui.Cmd? init() => _tick();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    // Global quit keys
    if (msg is tui.KeyMsg) {
      final k = msg.key;
      final rune = k.runes.isNotEmpty ? k.runes.first : -1;
      if (rune == 0x71 ||
          k.type == tui.KeyType.escape ||
          (k.ctrl && rune == 0x63)) {
        return (copyWith(quitting: true), tui.Cmd.quit());
      }
    }

    if (!chosen) {
      return _updateChoices(msg);
    }
    return _updateChosen(msg);
  }

  (tui.Model, tui.Cmd?) _updateChoices(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        if (key.type == tui.KeyType.runes && rune == 0x6a /* j */ ||
            key.type == tui.KeyType.down) {
          final next = (choice + 1).clamp(0, 3);
          return (copyWith(choice: next), null);
        }
        if (key.type == tui.KeyType.runes && rune == 0x6b /* k */ ||
            key.type == tui.KeyType.up) {
          final next = (choice - 1).clamp(0, 3);
          return (copyWith(choice: next), null);
        }
        if (key.type == tui.KeyType.enter) {
          return (copyWith(chosen: true), _frame());
        }
      case TickMsg():
        if (ticks == 0) {
          return (copyWith(quitting: true), tui.Cmd.quit());
        }
        return (copyWith(ticks: ticks - 1), _tick());
    }
    return (this, null);
  }

  (tui.Model, tui.Cmd?) _updateChosen(tui.Msg msg) {
    switch (msg) {
      case FrameMsg():
        if (!loaded) {
          final nextFrames = frames + 1;
          final nextProgress = _easeOutBounce(nextFrames / 100);
          if (nextProgress >= 1) {
            return (
              copyWith(frames: nextFrames, progress: 1, loaded: true, ticks: 3),
              _tick(),
            );
          }
          return (
            copyWith(frames: nextFrames, progress: nextProgress),
            _frame(),
          );
        }
      case TickMsg():
        if (loaded) {
          if (ticks == 0) {
            return (copyWith(quitting: true), tui.Cmd.quit());
          }
          return (copyWith(ticks: ticks - 1), _tick());
        }
    }
    return (this, null);
  }

  ViewsModel copyWith({
    int? choice,
    bool? chosen,
    int? ticks,
    int? frames,
    double? progress,
    bool? loaded,
    bool? quitting,
  }) {
    return ViewsModel(
      choice: choice ?? this.choice,
      chosen: chosen ?? this.chosen,
      ticks: ticks ?? this.ticks,
      frames: frames ?? this.frames,
      progress: progress ?? this.progress,
      loaded: loaded ?? this.loaded,
      quitting: quitting ?? this.quitting,
    );
  }

  @override
  String view() {
    if (quitting) return '\n  See you later!\n\n';
    final body = chosen ? _chosenView() : _choicesView();
    return _mainStyle.render('\n$body\n\n');
  }

  String _choicesView() {
    final c = choice;
    final tpl = StringBuffer()
      ..writeln('What to do today?\n')
      ..writeln(_checkbox('Plant carrots', c == 0))
      ..writeln(_checkbox('Go to the market', c == 1))
      ..writeln(_checkbox('Read something', c == 2))
      ..writeln(_checkbox('See friends', c == 3))
      ..writeln()
      ..writeln(
        'Program quits in ${_ticksStyle.render(ticks.toString())} seconds',
      )
      ..writeln()
      ..write(_subtleStyle.render('j/k, up/down: select'))
      ..write(_dotStyle)
      ..write(_subtleStyle.render('enter: choose'))
      ..write(_dotStyle)
      ..write(_subtleStyle.render('q, esc: quit'));
    return tpl.toString();
  }

  String _chosenView() {
    String msg;
    switch (choice) {
      case 0:
        msg =
            'Carrot planting?\n\nCool, we\'ll need ${_keywordStyle.render('libgarden')} and ${_keywordStyle.render('vegeutils')}...';
        break;
      case 1:
        msg =
            'A trip to the market?\n\nOkay, then we should install ${_keywordStyle.render('marketkit')} and ${_keywordStyle.render('libshopping')}...';
        break;
      case 2:
        msg =
            'Reading time?\n\nOkay, cool, then we’ll need a library. Yes, an ${_keywordStyle.render('actual library')}.';
        break;
      default:
        msg =
            'It’s always good to see friends.\n\nFetching ${_keywordStyle.render('social-skills')} and ${_keywordStyle.render('conversationutils')}...';
        break;
    }

    final label = loaded
        ? 'Downloaded. Exiting in ${_ticksStyle.render(ticks.toString())} seconds...'
        : 'Downloading...';

    return '$msg\n\n$label\n${_progressBar(progress)}%';
  }
}

tui.Cmd _tick() =>
    tui.Cmd.tick(const Duration(seconds: 1), (_) => const TickMsg());

tui.Cmd _frame() => tui.Cmd.tick(
  const Duration(milliseconds: 1000 ~/ 60),
  (_) => const FrameMsg(),
);

String _checkbox(String label, bool checked) =>
    checked ? _checkboxStyle.render('[x] $label') : '[ ] $label';

String _progressBar(double percent) {
  final w = _progressBarWidth.toDouble();
  final fullSize = (w * percent.clamp(0, 1)).round();

  final buffer = StringBuffer();
  for (var i = 0; i < fullSize && i < _ramp.length; i++) {
    buffer.write(_ramp[i].render(_progressFullChar));
  }
  final emptySize = _progressBarWidth - fullSize;
  buffer.write(List.filled(emptySize, _progressEmpty).join());

  final pct = (percent * 100).round();
  return '${buffer.toString()} ${pct.toString().padLeft(3)}';
}

// Utilities
List<Style> _makeRampStyles(String colorA, String colorB, int steps) {
  final a = _hexToRgb(colorA);
  final b = _hexToRgb(colorB);
  final out = <Style>[];
  for (var i = 0; i < steps; i++) {
    final t = i / steps;
    final r = (a[0] + (b[0] - a[0]) * t).round();
    final g = (a[1] + (b[1] - a[1]) * t).round();
    final bl = (a[2] + (b[2] - a[2]) * t).round();
    out.add(Style().foreground(BasicColor(_rgbToHex(r, g, bl))));
  }
  return out;
}

List<int> _hexToRgb(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 3) {
    h = h.split('').map((c) => '$c$c').join();
  }
  final value = int.parse(h, radix: 16);
  return [(value >> 16) & 0xff, (value >> 8) & 0xff, value & 0xff];
}

String _rgbToHex(int r, int g, int b) =>
    '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';

// Bounce easing (equivalent to fogleman/ease OutBounce)
double _easeOutBounce(double t) {
  const n1 = 7.5625;
  const d1 = 2.75;
  if (t < 1 / d1) {
    return n1 * t * t;
  } else if (t < 2 / d1) {
    t -= 1.5 / d1;
    return n1 * t * t + 0.75;
  } else if (t < 2.5 / d1) {
    t -= 2.25 / d1;
    return n1 * t * t + 0.9375;
  } else {
    t -= 2.625 / d1;
    return n1 * t * t + 0.984375;
  }
}

Future<void> main() async {
  await tui.runProgram(
    ViewsModel.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
