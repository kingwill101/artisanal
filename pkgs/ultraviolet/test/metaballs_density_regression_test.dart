import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:ultraviolet/src/uv/uv.dart';

final class _TestSink implements StringSink {
  final StringBuffer _b = StringBuffer();

  String get value => _b.toString();

  void reset() => _b.clear();

  @override
  void write(Object? obj) => _b.write(obj);

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _b.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _b.writeCharCode(charCode);

  @override
  void writeln([Object? obj = '']) => _b.writeln(obj);
}

final class _Metaball {
  const _Metaball({required this.x, required this.y, required this.radius});

  final double x;
  final double y;
  final double radius;
}

void main() {
  group('Metaballs density renderer regression', () {
    test('captures ANSI for left-edge density frames', () {
      final out = _TestSink();
      final renderer =
          UvTerminalRenderer(
              out,
              env: const [
                'TERM=xterm-256color',
                'TTY_FORCE=1',
                'COLORTERM=truecolor',
              ],
            )
            ..setFullscreen(true)
            ..setScrollOptim(false);

      final frames = <Buffer>[
        _densityFrame(
          width: 32,
          height: 12,
          threshold: 2.8,
          metaballs: const [
            _Metaball(x: 0.2, y: 4.0, radius: 4.0),
            _Metaball(x: 10.0, y: 5.0, radius: 3.5),
          ],
        ),
        _densityFrame(
          width: 32,
          height: 12,
          threshold: 2.8,
          metaballs: const [
            _Metaball(x: 0.2, y: 5.0, radius: 4.0),
            _Metaball(x: 10.0, y: 5.0, radius: 3.5),
          ],
        ),
        _densityFrame(
          width: 32,
          height: 12,
          threshold: 2.8,
          metaballs: const [
            _Metaball(x: 0.2, y: 6.0, radius: 4.0),
            _Metaball(x: 10.0, y: 5.0, radius: 3.5),
          ],
        ),
      ];

      renderer.erase();
      renderer.render(frames.first);
      renderer.flush();

      final captured = <String>[];
      for (final frame in frames.skip(1)) {
        out.reset();
        renderer.render(frame);
        renderer.flush();
        captured.add(out.value.replaceAll('\x1b', '<ESC>'));
      }

      for (final frame in captured) {
        // These are the suspicious row-start primitives we have been chasing.
        // Keep the test capturing them so regressions are easy to inspect.
        expect(frame, isNotEmpty);
      }
    });

    test(
      'repaints styled leading spaces instead of skipping to first glyph',
      () {
        final out = _TestSink();
        final renderer =
            UvTerminalRenderer(
                out,
                env: const [
                  'TERM=xterm-256color',
                  'TTY_FORCE=1',
                  'COLORTERM=truecolor',
                ],
              )
              ..setFullscreen(true)
              ..setScrollOptim(false);

        final first = Buffer.create(8, 1);
        final second = Buffer.create(8, 1);
        for (var x = 0; x < 8; x++) {
          first.setCell(x, 0, Cell(content: '.', style: _styleForRatio(0.9)));
        }
        first.setCell(0, 0, Cell(content: '#', style: _styleForRatio(1.8)));
        first.setCell(1, 0, Cell(content: '#', style: _styleForRatio(1.8)));

        for (var x = 0; x < 8; x++) {
          second.setCell(x, 0, Cell(content: '.', style: _styleForRatio(0.9)));
        }
        second.setCell(1, 0, Cell(content: '#', style: _styleForRatio(1.8)));

        renderer.erase();
        renderer.render(first);
        renderer.flush();
        out.reset();

        renderer.render(second);
        renderer.flush();

        expect(
          out.value,
          isNot(
            contains(
              '${UvAnsi.cursorForward(1)}\x1b[1;38;2;255;252;210;48;2;8;14;24m',
            ),
          ),
        );
      },
    );

    test('repaints styled leading dots near the left edge', () {
      final out = _TestSink();
      final renderer =
          UvTerminalRenderer(
              out,
              env: const [
                'TERM=xterm-256color',
                'TTY_FORCE=1',
                'COLORTERM=truecolor',
              ],
            )
            ..setFullscreen(true)
            ..setScrollOptim(false);

      final first = Buffer.create(8, 1);
      final second = Buffer.create(8, 1);
      for (var x = 0; x < 8; x++) {
        first.setCell(x, 0, Cell(content: '.', style: _styleForRatio(0.9)));
        second.setCell(x, 0, Cell(content: '.', style: _styleForRatio(0.9)));
      }
      first.setCell(2, 0, Cell(content: '#', style: _styleForRatio(1.8)));
      second.setCell(3, 0, Cell(content: '#', style: _styleForRatio(1.8)));

      renderer.erase();
      renderer.render(first);
      renderer.flush();
      out.reset();

      renderer.render(second);
      renderer.flush();

      expect(out.value, isNot(contains('${UvAnsi.cursorForward(3)}#')));
    });
  });
}

Buffer _densityFrame({
  required int width,
  required int height,
  required double threshold,
  required List<_Metaball> metaballs,
}) {
  final buffer = Buffer.create(width, height);
  for (var y = 0; y < height; y++) {
    final y1 = math.min(height - 1, y + 1);
    for (var x = 0; x < width; x++) {
      final x1 = math.min(width - 1, x + 1);
      final f00 = _fieldAt(x.toDouble(), y.toDouble(), metaballs);
      final f10 = _fieldAt(x1.toDouble(), y.toDouble(), metaballs);
      final f11 = _fieldAt(x1.toDouble(), y1.toDouble(), metaballs);
      final f01 = _fieldAt(x.toDouble(), y1.toDouble(), metaballs);
      final avg = (f00 + f10 + f11 + f01) / 4;
      final ratio = avg / threshold;
      buffer.setCell(
        x,
        y,
        Cell(content: _densityGlyph(ratio), style: _styleForRatio(ratio)),
      );
    }
  }
  return buffer;
}

double _fieldAt(double x, double y, List<_Metaball> metaballs) {
  var sum = 0.0;
  for (final ball in metaballs) {
    final dx = x - ball.x;
    final dy = y - ball.y;
    final d2 = dx * dx + dy * dy + 0.25;
    sum += (ball.radius * ball.radius) / d2;
  }
  return sum;
}

String _densityGlyph(double ratio) {
  const ramp = ' .:-=+*#%@';
  final clamped = ratio.clamp(0.0, 2.2);
  final index = ((clamped / 2.2) * (ramp.length - 1)).floor();
  return ramp[index];
}

UvStyle _styleForRatio(double ratio) {
  if (ratio < 0.75) {
    return const UvStyle(
      fg: UvColor.rgb(100, 133, 186),
      bg: UvColor.rgb(8, 14, 24),
    );
  }
  if (ratio < 1.1) {
    return const UvStyle(
      fg: UvColor.rgb(132, 187, 255),
      bg: UvColor.rgb(8, 14, 24),
    );
  }
  if (ratio < 1.5) {
    return const UvStyle(
      fg: UvColor.rgb(166, 231, 255),
      bg: UvColor.rgb(8, 14, 24),
      attrs: Attr.bold,
    );
  }
  return const UvStyle(
    fg: UvColor.rgb(255, 252, 210),
    bg: UvColor.rgb(8, 14, 24),
    attrs: Attr.bold,
  );
}
