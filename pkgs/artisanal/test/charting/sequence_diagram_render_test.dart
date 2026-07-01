/// Tests for the sequence diagram renderer.
library;

import 'package:artisanal/charting.dart';
import 'package:artisanal/uv.dart';
import 'package:test/test.dart';

Cell? _cellAt(Canvas canvas, int x, int y) => canvas.cellAt(x, y);

void main() {
  group('renderSequenceDiagram', () {
    test('renders basic message flow', () {
      final output = renderSequenceDiagram('''
sequenceDiagram
  A->>B: Hello
  B-->>A: World
''');
      expect(output, isNotEmpty);
      expect(output, contains('Hello'));
      expect(output, contains('World'));
    });

    test('renders participant labels', () {
      final output = renderSequenceDiagram('''
sequenceDiagram
  participant A as Alice
  participant B as Bob
  A->>B: Hi
''');
      expect(output, contains('Alice'));
      expect(output, contains('Bob'));
    });

    test('renders participant boxes', () {
      final output = renderSequenceDiagram('''
sequenceDiagram
  participant A as Alice
  participant B as Bob
  A->>B: Hi
''');
      expect(output, contains('┌'));
      expect(output, contains('┐'));
      expect(output, contains('└'));
      expect(output, contains('┘'));
    });

    test('renders lifelines', () {
      final output = renderSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
''');
      expect(output, contains('│'));
    });

    test('renders dashed messages', () {
      final output = renderSequenceDiagram('''
sequenceDiagram
  A->>B: Request
  B-->>A: Response
''');
      expect(output, contains('Request'));
      expect(output, contains('Response'));
    });

    test('renders notes', () {
      final output = renderSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
  note over A: Hi
''');
      expect(output, contains('Hi'));
    });

    test('renders notes over multiple participants', () {
      final output = renderSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
  note over A,B: Note
''');
      expect(output, contains('Note'));
    });

    test('renders fragment headers', () {
      final output = renderSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  alt condition
    A->>B: True
  else
    A->>B: False
  end
''');
      expect(output, contains('alt'));
      expect(output, contains('condition'));
    });

    test('renders loop fragments', () {
      final output = renderSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  loop 3 times
    A->>B: Repeat
  end
''');
      expect(output, contains('loop'));
      expect(output, contains('Repeat'));
    });

    test('renders with autonumbering', () {
      final output = renderSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  autonumber
  A->>B: First
  A->>B: Second
''');
      expect(output, contains('1. First'));
      expect(output, contains('2. Second'));
    });

    test('returns empty string for invalid content', () {
      final output = renderSequenceDiagram('not a sequence diagram');
      expect(output, isEmpty);
    });

    test('returns empty string for empty diagram', () {
      final output = renderSequenceDiagram('sequenceDiagram');
      expect(output, isEmpty);
    });

    test('custom theme applies', () {
      final output = renderSequenceDiagram(
        '''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
''',
        theme: const SequenceDiagramTheme(
          participantBox: UvStyle(fg: UvColor.rgb(255, 0, 0)),
          participantLabel: UvStyle(fg: UvColor.rgb(0, 255, 0)),
          lifeline: UvStyle(fg: UvColor.rgb(0, 0, 255)),
          request: UvStyle(fg: UvColor.rgb(255, 255, 0)),
          response: UvStyle(fg: UvColor.rgb(255, 0, 255)),
          note: UvStyle(fg: UvColor.rgb(100, 100, 100)),
          fragment: UvStyle(fg: UvColor.rgb(200, 200, 200)),
          fragmentLabel: UvStyle(fg: UvColor.rgb(150, 150, 150)),
          group: UvStyle(fg: UvColor.rgb(50, 50, 50)),
          rect: UvStyle(fg: UvColor.rgb(30, 30, 30)),
        ),
      );
      expect(output, isNotEmpty);
      expect(output, contains('Hello'));
    });
  });

  group('layoutSequenceDiagram', () {
    test('returns positive dimensions for valid diagram', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
''');
      expect(diagram, isNotNull);
      final layout = layoutSequenceDiagram(diagram!);
      expect(layout.width, greaterThan(0));
      expect(layout.height, greaterThan(0));
      expect(layout.lines.length, layout.height);
    });

    test('returns zero dimensions for empty diagram', () {
      final diagram = parseSequenceDiagram('sequenceDiagram');
      expect(diagram, isNotNull);
      final layout = layoutSequenceDiagram(diagram!);
      expect(layout.width, 0);
      expect(layout.height, 0);
    });

    test('height increases with more steps', () {
      final diagram1 = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
''');

      final diagram2 = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
  B-->>A: World
  note over A: Note
''');

      final layout1 = layoutSequenceDiagram(diagram1!);
      final layout2 = layoutSequenceDiagram(diagram2!);

      expect(layout2.height, greaterThan(layout1.height));
    });

    test('width increases with more participants', () {
      final diagram1 = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
''');

      final diagram2 = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  participant C
  A->>B: Hello
  B->>C: World
''');

      final layout1 = layoutSequenceDiagram(diagram1!);
      final layout2 = layoutSequenceDiagram(diagram2!);

      expect(layout2.width, greaterThanOrEqualTo(layout1.width));
    });
  });

  group('drawSequenceDiagram', () {
    test('draws participant boxes on canvas', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A as Alice
  participant B as Bob
  A->>B: Hello
''');
      expect(diagram, isNotNull);

      final canvas = Canvas(100, 20);
      final area = rect(0, 0, 100, 20);
      drawSequenceDiagram(canvas, area, diagram!);

      var foundTopLeft = false;
      for (var x = 0; x < 100; x++) {
        if (_cellAt(canvas, x, 0)?.content == '┌') {
          foundTopLeft = true;
          break;
        }
      }
      expect(
        foundTopLeft,
        isTrue,
        reason: 'should have at least one box corner',
      );
    });

    test('draws participant labels', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A as Alice
''');
      expect(diagram, isNotNull);

      final canvas = Canvas(100, 20);
      final area = rect(0, 0, 100, 20);
      drawSequenceDiagram(canvas, area, diagram!);

      final output = canvas.render();
      expect(output, contains('Alice'));
    });

    test('draws message arrows', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
''');
      expect(diagram, isNotNull);

      final canvas = Canvas(100, 20);
      final area = rect(0, 0, 100, 20);
      drawSequenceDiagram(canvas, area, diagram!);

      final output = canvas.render();
      expect(output, contains('Hello'));
    });

    test('draws fragment borders', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  alt condition
    A->>B: True
  end
''');
      expect(diagram, isNotNull);

      final canvas = Canvas(100, 20);
      final area = rect(0, 0, 100, 20);
      drawSequenceDiagram(canvas, area, diagram!);

      final output = canvas.render();
      expect(output, contains('alt'));
      expect(output, contains('├'));
    });

    test('draws notes', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
  note over A: Hi
''');
      expect(diagram, isNotNull);

      final canvas = Canvas(100, 20);
      final area = rect(0, 0, 100, 20);
      drawSequenceDiagram(canvas, area, diagram!);

      final output = canvas.render();
      expect(output, contains('Hi'));
    });

    test('respects area bounds', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
''');
      expect(diagram, isNotNull);

      final canvas = Canvas(20, 10);
      final area = rect(0, 0, 20, 10);
      drawSequenceDiagram(canvas, area, diagram!);

      for (var y = 0; y < 10; y++) {
        final cell = _cellAt(canvas, 0, y);
        expect(cell, isNotNull);
      }
    });

    test('does nothing for empty diagram', () {
      final diagram = parseSequenceDiagram('sequenceDiagram');
      expect(diagram, isNotNull);

      final canvas = Canvas(20, 10);
      final area = rect(0, 0, 20, 10);
      drawSequenceDiagram(canvas, area, diagram!);

      final output = canvas.render();
      expect(output.trim(), isEmpty);
    });
  });

  group('SequenceDiagramTheme', () {
    test('defaultTheme is accessible', () {
      expect(SequenceDiagramTheme.defaultTheme, isNotNull);
    });

    test('defaultTheme has all fields set', () {
      final theme = SequenceDiagramTheme.defaultTheme;
      expect(theme.participantBox, isNotNull);
      expect(theme.participantLabel, isNotNull);
      expect(theme.lifeline, isNotNull);
      expect(theme.request, isNotNull);
      expect(theme.response, isNotNull);
      expect(theme.note, isNotNull);
      expect(theme.fragment, isNotNull);
      expect(theme.fragmentLabel, isNotNull);
      expect(theme.group, isNotNull);
      expect(theme.rect, isNotNull);
    });
  });

  group('SequenceMessageStyle', () {
    test('solid has default style', () {
      expect(SequenceMessageStyle.solid.defaultStyle, isNotNull);
    });

    test('dashed has default style', () {
      expect(SequenceMessageStyle.dashed.defaultStyle, isNotNull);
    });
  });

  group('SequenceFragmentKind', () {
    test('alt has prefix and styles', () {
      expect(SequenceFragmentKind.alt.prefix, 'alt');
      expect(SequenceFragmentKind.alt.defaultStyle, isNotNull);
      expect(SequenceFragmentKind.alt.defaultLabelStyle, isNotNull);
    });

    test('elsePart has prefix', () {
      expect(SequenceFragmentKind.elsePart.prefix, 'else');
    });

    test('loop has prefix', () {
      expect(SequenceFragmentKind.loop.prefix, contains('loop'));
    });

    test('end has default empty prefix', () {
      expect(SequenceFragmentKind.end.prefix, 'end');
    });
  });

  group('SequenceArrowHead', () {
    test('open uses > character', () {
      expect(SequenceArrowHead.open.char, '>');
    });

    test('cross uses ✕ character', () {
      expect(SequenceArrowHead.cross.char, '✕');
    });

    test('async uses ) character', () {
      expect(SequenceArrowHead.async.char, ')');
    });
  });
}
