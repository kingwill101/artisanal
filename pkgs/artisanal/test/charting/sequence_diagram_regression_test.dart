import 'package:artisanal/src/charting/sequence_diagram.dart';
import 'package:artisanal/style.dart' show Layout, Style;
import 'package:test/test.dart';

// Mermaid source from devtools-profiler PR 10, comment 5610973298.
const _reportedDiagram = '''
sequenceDiagram
  participant Agent
  participant Marionette
  participant SearchScenario
  participant WorkerIsolate
  participant DevToolsProfiler
  Agent->>Marionette: call profiler_demo_search
  Marionette->>SearchScenario: pass seed and workload limits
  SearchScenario->>DevToolsProfiler: start marionette-search region
  SearchScenario->>WorkerIsolate: execute seeded search
  WorkerIsolate-->>SearchScenario: return checksum
  SearchScenario->>DevToolsProfiler: stop profiling region
  SearchScenario-->>Marionette: return completion result
''';

String _plain(String source, {int? width}) =>
    Style.stripAnsi(renderSequenceDiagram(source, maxWidth: width));

void main() {
  test('Mermaid line breaks survive aliases, messages, and notes', () {
    const source = '''
sequenceDiagram
participant A as Alice<br/>Client
participant B
A->>B: hello<br/>world
note over B: left<br/>right
''';
    final diagram = parseSequenceDiagram(source)!;
    expect(diagram.participants.first.label, 'Alice\nClient');
    expect(diagram.messages.single.label, 'hello\nworld');
    final output = _plain(source, width: 80);
    for (final text in ['Alice', 'Client', 'hello', 'world', 'left', 'right']) {
      expect(output, contains(text));
    }
    expect(output, isNot(contains('<br')));
  });

  test('oversized natural diagrams fail before allocating a canvas', () {
    final source = StringBuffer('sequenceDiagram\n');
    for (var i = 0; i < 100; i++) {
      source.writeln('participant A$i as ${'W' * 1000}');
      if (i > 0) source.writeln('A${i - 1}->>A$i: message');
    }
    expect(
      () => renderSequenceDiagram(source.toString()),
      throwsFormatException,
    );
  });

  for (final width in [80, 120, 180]) {
    test('complete reported diagram fits $width columns without lost text', () {
      final diagram = parseSequenceDiagram(_reportedDiagram)!;
      final rendered = _plain(_reportedDiagram, width: width);
      expect(rendered, isNot(contains('needs')));
      expect(rendered, isNot(contains('…')));
      expect(Layout.getWidth(rendered), lessThanOrEqualTo(width));
      final lines = rendered.split('\n');
      final boxes = RegExp(r'┌─+┐').allMatches(lines.first).toList();
      expect(boxes, hasLength(5));
      var headerBottom = 0;
      final centers = <int>[];
      for (var i = 0; i < boxes.length; i++) {
        final box = boxes[i];
        final bottom = lines.indexWhere(
          (line) => line.length > box.start && line[box.start] == '└',
        );
        expect(bottom, greaterThan(1));
        if (bottom > headerBottom) headerBottom = bottom;
        final text = StringBuffer();
        for (var row = 1; row < bottom; row++) {
          expect(lines[row][box.start], '│');
          expect(lines[row][box.end - 1], '│');
          text.write(lines[row].substring(box.start + 1, box.end - 1).trim());
        }
        expect(text.toString(), diagram.participants[i].label);
        centers.add(lines[bottom].indexOf('┬', box.start));
      }

      final arrowRows = <int>[
        for (var y = headerBottom + 1; y < lines.length; y++)
          if (RegExp(r'[─┄][<>]|[<>][─┄]').hasMatch(lines[y])) y,
      ];
      expect(arrowRows, hasLength(7));
      var previousRow = headerBottom;
      for (var i = 0; i < arrowRows.length; i++) {
        final label = lines
            .sublist(previousRow + 1, arrowRows[i])
            .join()
            .replaceAll(RegExp(r'[│\s]'), '');
        expect(
          label,
          diagram.messages[i].label.replaceAll(RegExp(r'\s'), ''),
          reason: 'Every message character must survive line wrapping.',
        );
        final target = diagram.participants.indexWhere(
          (p) => p.id == diagram.messages[i].to,
        );
        final sender = diagram.participants.indexWhere(
          (p) => p.id == diagram.messages[i].from,
        );
        expect(
          lines[arrowRows[i]][centers[target]],
          target > sender ? '>' : '<',
        );
        previousRow = arrowRows[i];
      }
    });
  }

  test('actor symbol survives header and lifeline painting', () {
    final text = _plain(
      'sequenceDiagram\nactor A\nparticipant B\nA->>B: hello',
    );
    expect(text, contains('○'));
    expect(text, contains('/|\\'));
    expect(text, contains('/ \\'));
    expect(RegExp(r'┌─+┐').allMatches(text.split('\n').first), hasLength(1));
  });

  for (final arrow in ['->', '-->']) {
    test('$arrow is a line without an arrowhead, including self messages', () {
      for (final target in ['A', 'B']) {
        final text = _plain('sequenceDiagram\nA$arrow$target: plain');
        expect(text, contains('plain'));
        expect(text, isNot(contains('>')));
        expect(text, isNot(contains('<')));
      }
    });
  }

  test('bidirectional and asynchronous heads follow participant direction', () {
    const source = '''
sequenceDiagram
participant A
participant B
A<<->>B: both ways
B--)A: asynchronous return
''';
    final diagram = parseSequenceDiagram(source)!;
    expect(diagram.participants.map((p) => p.id), ['A', 'B']);
    expect(diagram.messages.first.from, 'A');
    expect(diagram.messages.first.to, 'B');
    final text = _plain(source);
    expect(text, contains(RegExp(r'<─+>')));
    expect(text, contains(RegExp(r'\(┄+')));
  });

  test('unsupported configuration cannot become a misleading participant', () {
    for (final statement in [
      'participant A@{"type":"database"}',
      'A->>()B: central',
      'box hsl(10,40%,90%) Team\nparticipant A\nend',
    ]) {
      expect(
        () => parseSequenceDiagram('sequenceDiagram\n$statement'),
        throwsFormatException,
      );
    }
  });

  test('branches cannot jump across an unclosed nested region', () {
    expect(
      () => parseSequenceDiagram('''
sequenceDiagram
alt outer
rect red
else misplaced
end
end
'''),
      throwsFormatException,
    );
  });
}
