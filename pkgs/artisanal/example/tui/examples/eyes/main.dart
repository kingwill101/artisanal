/// Blinking eyes animation ported from Bubble Tea.
library;

import 'dart:math' as math;
import 'dart:math' show Random;

import 'package:artisanal/artisanal.dart' show AnsiColor, Style;
import 'package:artisanal/tui.dart' as tui;

const _eyeWidth = 15;
const _eyeHeight = 12;
const _eyeSpacing = 40;

const _blinkFrames = 20;
const _openTimeMin = 1000;
const _openTimeMax = 4000;

const _eyeChar = '●';
const _bgChar = ' ';

class TickMsg extends tui.Msg {
  const TickMsg();
}

class EyesModel implements tui.Model {
  EyesModel({
    required this.width,
    required this.height,
    required this.eyePositions,
    required this.eyeY,
    required this.isBlinking,
    required this.blinkState,
    required this.lastBlink,
    required this.openTime,
  });

  factory EyesModel.initial() {
    final now = DateTime.now();
    final open = Duration(
      milliseconds:
          Random().nextInt(_openTimeMax - _openTimeMin) + _openTimeMin,
    );
    final model = EyesModel(
      width: 80,
      height: 24,
      eyePositions: const [0, 0],
      eyeY: 0,
      isBlinking: false,
      blinkState: 0,
      lastBlink: now,
      openTime: open,
    );
    return model._withUpdatedEyes();
  }

  final int width;
  final int height;
  final List<int> eyePositions; // length 2
  final int eyeY;
  final bool isBlinking;
  final int blinkState;
  final DateTime lastBlink;
  final Duration openTime;

  EyesModel copyWith({
    int? width,
    int? height,
    List<int>? eyePositions,
    int? eyeY,
    bool? isBlinking,
    int? blinkState,
    DateTime? lastBlink,
    Duration? openTime,
  }) {
    return EyesModel(
      width: width ?? this.width,
      height: height ?? this.height,
      eyePositions: eyePositions ?? this.eyePositions,
      eyeY: eyeY ?? this.eyeY,
      isBlinking: isBlinking ?? this.isBlinking,
      blinkState: blinkState ?? this.blinkState,
      lastBlink: lastBlink ?? this.lastBlink,
      openTime: openTime ?? this.openTime,
    );
  }

  EyesModel _withUpdatedEyes() {
    final startX = (width - _eyeSpacing) ~/ 2;
    final newPositions = [startX, startX + _eyeSpacing];
    final newEyeY = height ~/ 2;
    return copyWith(eyePositions: newPositions, eyeY: newEyeY);
  }

  @override
  tui.Cmd? init() => tui.Cmd.batch([
    tui.Cmd.tick(const Duration(milliseconds: 50), (_) => const TickMsg()),
    tui.Cmd.enterAltScreen(),
  ]);

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        if (key.type == tui.KeyType.escape ||
            (key.ctrl && key.runes.isNotEmpty && key.runes.first == 0x63)) {
          return (this, tui.Cmd.quit());
        }
      case tui.WindowSizeMsg(width: final w, height: final h):
        return (_withUpdatedEyes().copyWith(width: w, height: h), _tickCmd());
      case TickMsg():
        return (_advanceBlink(), _tickCmd());
    }

    return (this, null);
  }

  tui.Cmd _tickCmd() =>
      tui.Cmd.tick(const Duration(milliseconds: 50), (_) => const TickMsg());

  EyesModel _advanceBlink() {
    final now = DateTime.now();
    var model = this;

    if (!isBlinking && now.difference(lastBlink) >= openTime) {
      model = copyWith(isBlinking: true, blinkState: 0);
    }

    if (model.isBlinking) {
      final nextState = model.blinkState + 1;
      if (nextState >= _blinkFrames) {
        // finish blink
        final nextOpen = Duration(
          milliseconds:
              Random().nextInt(_openTimeMax - _openTimeMin) + _openTimeMin,
        );
        // 10% chance double blink
        final open = Random().nextInt(10) == 0
            ? const Duration(milliseconds: 300)
            : nextOpen;
        model = model.copyWith(
          isBlinking: false,
          blinkState: 0,
          lastBlink: now,
          openTime: open,
        );
      } else {
        model = model.copyWith(blinkState: nextState);
      }
    }

    return model;
  }

  @override
  String view() {
    if (width <= 0 || height <= 0) return '';

    // build blank canvas
    final canvas = List.generate(
      height,
      (_) => List.filled(width, _bgChar, growable: false),
    );

    // determine current height based on blink state
    var currentHeight = _eyeHeight;
    if (isBlinking) {
      double progress;
      if (blinkState < _blinkFrames / 2) {
        progress = blinkState / (_blinkFrames / 2);
        progress = 1.0 - (progress * progress);
      } else {
        progress = (blinkState - _blinkFrames / 2) / (_blinkFrames / 2);
        progress = progress * (2.0 - progress);
      }
      currentHeight = math.max(1, (_eyeHeight * progress).round());
    }

    for (final x in eyePositions) {
      _drawEllipse(canvas, x, eyeY, _eyeWidth, currentHeight);
    }

    final buffer = StringBuffer();
    for (final row in canvas) {
      buffer.writeln(row.join());
    }

    return Style().foreground(const AnsiColor(252)).render(buffer.toString());
  }

  void _drawEllipse(List<List<String>> canvas, int x0, int y0, int rx, int ry) {
    if (canvas.isEmpty || canvas.first.isEmpty) return;
    for (var y = -ry; y <= ry; y++) {
      final widthAtY = (rx * math.sqrt(1 - math.pow(y / ry, 2)))
          .clamp(0, rx)
          .round();
      for (var x = -widthAtY; x <= widthAtY; x++) {
        final cx = x0 + x;
        final cy = y0 + y;
        if (cy >= 0 && cy < canvas.length && cx >= 0 && cx < canvas[0].length) {
          canvas[cy][cx] = _eyeChar;
        }
      }
    }
  }
}

Future<void> main() async {
  await tui.runProgram(
    EyesModel.initial(),
    options: const tui.ProgramOptions(altScreen: true, hideCursor: false),
  );
}
