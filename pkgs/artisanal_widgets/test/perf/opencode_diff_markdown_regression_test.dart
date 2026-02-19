import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart' show MouseAction, MouseButton, MouseMsg;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/opencode/models/message.dart';
import '../../example/opencode/widgets/chat_body.dart';

void main() {
  test(
    'OpenCode diff-heavy: expand diffs and profile interactions',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      try {
        const diffCount = 36;
        final messages = List<ChatMessage>.generate(diffCount, (i) {
          return ChatMessage.assistant(
            [
              TextPart('Diff-heavy regression item #$i'),
              DiffPart(
                filePath: 'lib/src/widgets/heavy/file_$i.dart',
                diff: _syntheticDiff(i),
                additions: 120 + i,
                deletions: 28 + (i % 9),
                expanded: true,
              ),
            ],
            id: 'diff-heavy-$i',
            agent: 'code',
          );
        });

        await tester.pumpWidget(
          w.Container(
            key: const w.ValueKey<String>('diff-heavy-root'),
            child: ChatBody(messages: messages),
          ),
        );

        final expandedDiffViewers = tester.find.byType<w.GitDiffViewer>();
        expect(expandedDiffViewers.length, greaterThanOrEqualTo(1));

        final durations = _runProfileSequence(tester, rounds: 90);
        final stats = _LatencyStats.from(durations);

        print('Diff-heavy events: ${durations.length}');
        print(
          'Diff-heavy latency (ms): avg=${_ms(stats.avgUs)} '
          'p95=${_ms(stats.p95Us)} max=${_ms(stats.maxUs)}',
        );
        expect(stats.p95Us / 1000, lessThan(95));
        expect(stats.maxUs / 1000, lessThan(140));
      } finally {
        await tester.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test(
    'Markdown-heavy: large snippet list remains within latency budget',
    () async {
      final tester = WidgetTester(screenWidth: 120, screenHeight: 40);
      try {
        final snippets = List<String>.generate(120, _heavyMarkdownSnippet);
        await tester.pumpWidget(_MarkdownStressView(snippets: snippets));

        final markdownNodes = tester.find.byType<w.MarkdownText>();
        expect(markdownNodes.length, equals(snippets.length));

        final root = tester.find.byKey(
          const w.ValueKey<String>('markdown-stress-root'),
        );
        expect(root.length, equals(1));

        final durations = _runProfileSequence(tester, rounds: 260);
        final stats = _LatencyStats.from(durations);

        print('Markdown-heavy events: ${durations.length}');
        print(
          'Markdown-heavy latency (ms): avg=${_ms(stats.avgUs)} '
          'p95=${_ms(stats.p95Us)} max=${_ms(stats.maxUs)}',
        );

        expect(stats.p95Us / 1000, lessThan(24));
        expect(stats.maxUs / 1000, lessThan(60));
      } finally {
        await tester.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

List<int> _runProfileSequence(WidgetTester tester, {required int rounds}) {
  final durations = <int>[];
  for (var i = 0; i < rounds; i++) {
    final down = i % 4 != 0;
    durations.add(
      _timeUs(
        () => tester.sendMsg(
          MouseMsg(
            action: MouseAction.wheel,
            button: down ? MouseButton.wheelDown : MouseButton.wheelUp,
            x: 82,
            y: 14,
          ),
        ),
      ),
    );
    if (i % 20 == 0) {
      durations.add(
        _timeUs(() => tester.sendSpecialKey(terminal_keys.KeyType.pageDown)),
      );
      durations.add(
        _timeUs(() => tester.sendSpecialKey(terminal_keys.KeyType.up)),
      );
    }
  }
  return durations;
}

int _timeUs(void Function() fn) {
  final sw = Stopwatch()..start();
  fn();
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

class _MarkdownStressView extends w.StatelessWidget {
  _MarkdownStressView({required this.snippets});

  final List<String> snippets;

  @override
  w.Widget build(w.BuildContext context) {
    final children = <w.Widget>[];
    for (var i = 0; i < snippets.length; i++) {
      children.add(
        w.Container(
          key: w.ValueKey<String>('md-card-$i'),
          padding: const w.EdgeInsets.only(
            left: 1,
            right: 1,
            top: 1,
            bottom: 1,
          ),
          child: w.MarkdownText(data: snippets[i]),
        ),
      );
    }

    return w.Container(
      key: const w.ValueKey<String>('markdown-stress-root'),
      child: w.VirtualListView(
        variableHeight: true,
        estimatedItemExtent: 10,
        mouseWheelDelta: 3,
        children: children,
      ),
    );
  }
}

String _syntheticDiff(int seed) {
  final path = 'lib/src/widgets/heavy/file_$seed.dart';
  final b = StringBuffer()
    ..writeln('diff --git a/$path b/$path')
    ..writeln('index 1111111..2222222 100644')
    ..writeln('--- a/$path')
    ..writeln('+++ b/$path');

  for (var hunk = 0; hunk < 3; hunk++) {
    final start = 20 + hunk * 16;
    b.writeln('@@ -$start,8 +$start,12 @@ void block$hunk() {');
    for (var j = 0; j < 4; j++) {
      b.writeln('-  final old$hunk$j = runOld($j);');
    }
    for (var j = 0; j < 7; j++) {
      b.writeln('+  final next$hunk$j = runNew($seed + $j);');
    }
    b.writeln(' }');
  }
  return b.toString();
}

String _heavyMarkdownSnippet(int i) {
  final n = i + 1;
  final code = List<String>.generate(
    8,
    (j) => 'final value$j = computeValue($n + $j) * ${j + 2};',
  ).join('\n');
  final bullets = List<String>.generate(
    8,
    (j) => '- bullet $j: a detailed markdown item with inline `code$j` value.',
  ).join('\n');

  return '''
# Stress Heading $n

This is a synthetic markdown paragraph for regression testing. It includes
**bold**, _italic_, `inline code`, and a [link](https://example.com/$n).

## Checklist
$bullets

## Table
| Metric | Value |
| ------ | ----- |
| p95    | ${10 + (i % 7)}ms |
| max    | ${40 + (i % 11)}ms |

## Code
```dart
$code
```

> Quote block $n: rendering and wrapping should remain stable.
''';
}
