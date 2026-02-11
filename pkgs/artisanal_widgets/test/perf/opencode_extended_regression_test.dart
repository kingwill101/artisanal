import 'dart:math' as math;

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart' show MouseAction, MouseButton, MouseMsg;
import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/opencode/main.dart' as opencode;

void main() {
  test(
    'OpenCode soak: long mixed session stays stable',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      try {
        await tester.pumpWidget(opencode.OpenCodeApp());

        final durationsUs = <int>[];
        const payload = 'soak profile text sample ';

        for (var i = 0; i < 2600; i++) {
          if (i % 2 == 0) {
            durationsUs.add(
              _timeUs(
                () => tester.sendMsg(
                  const MouseMsg(
                    action: MouseAction.wheel,
                    button: MouseButton.wheelDown,
                    x: 82,
                    y: 14,
                  ),
                ),
              ),
            );
          } else {
            durationsUs.add(
              _timeUs(
                () => tester.sendMsg(
                  const MouseMsg(
                    action: MouseAction.wheel,
                    button: MouseButton.wheelUp,
                    x: 82,
                    y: 14,
                  ),
                ),
              ),
            );
          }

          if (i % 9 == 0) {
            final c = payload[(i ~/ 9) % payload.length];
            durationsUs.add(_timeUs(() => tester.sendKey(c)));
          }
          if (i % 31 == 0) {
            durationsUs.add(
              _timeUs(
                () => tester.sendSpecialKey(terminal_keys.KeyType.backspace),
              ),
            );
          }
          if (i % 47 == 0) {
            durationsUs.add(
              _timeUs(
                () => tester.sendSpecialKey(terminal_keys.KeyType.pageDown),
              ),
            );
          }
        }

        final stats = _LatencyStats.from(durationsUs);
        print('Soak events: ${durationsUs.length}');
        print(
          'Soak latency (ms): avg=${_ms(stats.avgUs)} '
          'p95=${_ms(stats.p95Us)} max=${_ms(stats.maxUs)}',
        );

        expect(stats.p95Us / 1000, lessThan(35));
        expect(stats.maxUs / 1000, lessThan(120));
      } finally {
        await tester.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );

  test(
    'OpenCode resize stress: rapid window changes remain responsive',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      try {
        await tester.pumpWidget(opencode.OpenCodeApp());
        final durationsUs = <int>[];
        const sizes = <(int, int)>[
          (120, 40),
          (98, 32),
          (142, 46),
          (88, 30),
          (156, 44),
        ];

        for (var i = 0; i < 140; i++) {
          final (wWidth, wHeight) = sizes[i % sizes.length];
          durationsUs.add(_timeUs(() => tester.resize(wWidth, wHeight)));

          final x = math.min(82, wWidth - 2);
          final y = math.min(14, wHeight - 2);
          durationsUs.add(
            _timeUs(
              () => tester.sendMsg(
                MouseMsg(
                  action: MouseAction.wheel,
                  button: i.isEven
                      ? MouseButton.wheelDown
                      : MouseButton.wheelUp,
                  x: x,
                  y: y,
                ),
              ),
            ),
          );

          if (i % 5 == 0) {
            durationsUs.add(
              _timeUs(
                () => tester.sendSpecialKey(terminal_keys.KeyType.pageDown),
              ),
            );
          }
        }

        final stats = _LatencyStats.from(durationsUs);
        print('Resize events: ${durationsUs.length}');
        print(
          'Resize latency (ms): avg=${_ms(stats.avgUs)} '
          'p95=${_ms(stats.p95Us)} max=${_ms(stats.maxUs)}',
        );

        expect(stats.p95Us / 1000, lessThan(70));
        expect(stats.maxUs / 1000, lessThan(220));
      } finally {
        await tester.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test(
    'Style churn: repeated themed markdown remounts stay within budget',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      try {
        final snippets = List<String>.generate(80, _churnSnippet);
        final durationsUs = <int>[];

        for (var i = 0; i < 90; i++) {
          durationsUs.add(
            await _timeAsyncUs(
              () => tester.pumpWidget(
                _StyleChurnView(snippets: snippets, variant: i % 2),
              ),
            ),
          );

          durationsUs.add(
            _timeUs(
              () => tester.sendMsg(
                const MouseMsg(
                  action: MouseAction.wheel,
                  button: MouseButton.wheelDown,
                  x: 84,
                  y: 14,
                ),
              ),
            ),
          );
        }

        final stats = _LatencyStats.from(durationsUs);
        print('Style-churn events: ${durationsUs.length}');
        print(
          'Style-churn latency (ms): avg=${_ms(stats.avgUs)} '
          'p95=${_ms(stats.p95Us)} max=${_ms(stats.maxUs)}',
        );

        expect(stats.p95Us / 1000, lessThan(140));
        expect(stats.maxUs / 1000, lessThan(900));
      } finally {
        await tester.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

int _timeUs(void Function() fn) {
  final sw = Stopwatch()..start();
  fn();
  sw.stop();
  return sw.elapsedMicroseconds;
}

Future<int> _timeAsyncUs(Future<void> Function() fn) async {
  final sw = Stopwatch()..start();
  await fn();
  sw.stop();
  return sw.elapsedMicroseconds;
}

String _ms(double us) => (us / 1000).toStringAsFixed(2);

double _percentileUs(List<int> sortedValues, double p) {
  if (sortedValues.isEmpty) return 0;
  if (sortedValues.length == 1) return sortedValues.first.toDouble();
  final idx = (sortedValues.length - 1) * p;
  final low = idx.floor();
  final high = idx.ceil();
  if (low == high) return sortedValues[low].toDouble();
  final lowValue = sortedValues[low];
  final highValue = sortedValues[high];
  return lowValue * (high - idx) + highValue * (idx - low);
}

class _LatencyStats {
  _LatencyStats({
    required this.avgUs,
    required this.p95Us,
    required this.maxUs,
  });

  final double avgUs;
  final double p95Us;
  final double maxUs;

  factory _LatencyStats.from(List<int> valuesUs) {
    final ordered = List<int>.of(valuesUs)..sort();
    final avg =
        ordered.fold<int>(0, (sum, next) => sum + next) / ordered.length;
    return _LatencyStats(
      avgUs: avg,
      p95Us: _percentileUs(ordered, 0.95),
      maxUs: ordered.last.toDouble(),
    );
  }
}

class _StyleChurnView extends w.StatelessWidget {
  _StyleChurnView({required this.snippets, required this.variant});

  final List<String> snippets;
  final int variant;

  @override
  w.Widget build(w.BuildContext context) {
    final primary = variant == 0
        ? const style.AnsiColor(39)
        : const style.AnsiColor(208);
    final surface = variant == 0
        ? const style.AnsiColor(235)
        : const style.AnsiColor(238);

    return w.Container(
      key: w.ValueKey<String>('style-churn-$variant'),
      decoration: w.BoxDecoration(color: surface),
      child: w.VirtualListView(
        variableHeight: true,
        estimatedItemExtent: 8,
        mouseWheelDelta: 2,
        children: [
          for (var i = 0; i < snippets.length; i++)
            w.Container(
              padding: const w.EdgeInsets.only(
                left: 1,
                right: 1,
                top: 1,
                bottom: 1,
              ),
              child: w.Column(
                children: [
                  w.Text(
                    'Variant $variant snippet $i',
                    style: style.Style().foreground(primary).bold(),
                  ),
                  w.MarkdownText(data: snippets[i]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _churnSnippet(int i) {
  return '''
### Churn Snippet ${i + 1}

- This snippet is used for style churn regression.
- It includes **bold**, _italic_, and `inline code`.

```dart
final id = $i;
final score = id * 7 + 13;
print('snippet $i -> \$score');
```
''';
}
