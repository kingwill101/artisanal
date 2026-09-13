/// Cell-level semantic coverage for sequence diagram drawing.
library;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/uv.dart';
import 'package:test/test.dart';

SequenceDiagram _diagram(String source) => parseSequenceDiagram(source)!;

Canvas _render(SequenceDiagram diagram) {
  final layout = layoutSequenceDiagram(diagram);
  final canvas = Canvas(layout.width, layout.height);
  addTearDown(canvas.dispose);
  drawSequenceDiagram(canvas, canvas.bounds(), diagram);
  return canvas;
}

Iterable<Cell> _cells(Canvas canvas) sync* {
  final bounds = canvas.bounds();
  for (var y = bounds.minY; y < bounds.maxY; y++) {
    for (var x = bounds.minX; x < bounds.maxX; x++) {
      final cell = canvas.cellAt(x, y);
      if (cell != null) yield cell;
    }
  }
}

void main() {
  test('group captions have room without covering the next participant', () {
    final canvas = _render(
      _diagram('''
sequenceDiagram
box red LONGGROUPCAPTION
participant A
end
participant B
A->>B: hello
'''),
    );
    final caption = _locate(canvas, 'LONGGROUPCAPTION');
    final next = _locate(canvas, 'B');
    expect(caption.x + 'LONGGROUPCAPTION'.length, lessThan(next.x));
  });

  test('nested rects with identical message spans keep the inner color', () {
    final canvas = _render(
      _diagram('''
sequenceDiagram
rect rgb(10,20,30)
  rect rgb(40,50,60)
    A->>B: INSIDE
  end
end
'''),
    );
    final position = _locate(canvas, 'INSIDE');
    expect(
      canvas.cellAt(position.x, position.y)!.style.bg,
      const UvColor.rgb(40, 50, 60),
    );
  });

  test('transparent rect does not introduce a gray background', () {
    final canvas = _render(
      _diagram('''
sequenceDiagram
rect transparent
  A->>B: TRANSPARENT
end
'''),
    );
    final position = _locate(canvas, 'TRANSPARENT');
    expect(canvas.cellAt(position.x, position.y)!.style.bg, isNull);
    expect((parseMermaidColor('rgba(10,20,30,0.5)') as UvRgb).a, 128);
  });

  test('side notes stay on their requested side without clipping', () {
    final canvas = _render(
      _diagram('''
sequenceDiagram
participant A
participant B
note left of A: LEFTLABEL
note right of B: RIGHTLABEL
'''),
    );
    final left = _locate(canvas, 'LEFTLABEL');
    final right = _locate(canvas, 'RIGHTLABEL');
    final a = _locate(canvas, 'A');
    final b = _locate(canvas, 'B');
    expect(left.x + 'LEFTLABEL'.length, lessThan(a.x));
    expect(right.x, greaterThan(b.x));
    expect(right.x + 'RIGHTLABEL'.length, lessThanOrEqualTo(canvas.width()));
  });

  test(
    'parsed nested rect colors cover labels and arrows without losing text',
    () {
      final canvas = _render(
        _diagram('''
sequenceDiagram
participant A
participant B
rect rgb(10,20,30)
  A->>B: OUTER
  rect rgb(40,50,60)
    B-->>A: INNER
  end
end
'''),
      );
      for (final (label, color) in [
        ('OUTER', const UvColor.rgb(10, 20, 30)),
        ('INNER', const UvColor.rgb(40, 50, 60)),
      ]) {
        final position = _locate(canvas, label);
        expect(canvas.cellAt(position.x, position.y)!.style.bg, color);
        expect(canvas.cellAt(position.x, position.y + 1)!.style.bg, color);
        expect(canvas.cellAt(position.x - 2, position.y)!.content, '│');
        expect(canvas.cellAt(position.x - 2, position.y)!.style.bg, color);
      }
    },
  );

  test('parsed group color includes participant headers and message cells', () {
    final canvas = _render(
      _diagram('''
sequenceDiagram
box rgb(70,80,90) Team
participant A
participant B
end
A->>B: hello
'''),
    );
    for (final label in ['A', 'B', 'hello']) {
      final position = _locate(canvas, label);
      expect(
        canvas.cellAt(position.x, position.y)!.style.bg,
        const UvColor.rgb(70, 80, 90),
        reason: label,
      );
    }
    final lastRow = [
      for (var x = 0; x < canvas.width(); x++)
        canvas.cellAt(x, canvas.height() - 1)!.content,
    ].join();
    expect(lastRow, contains('└'));
    expect(lastRow, contains('┘'));
  });

  test('rect background preserves wide message cell geometry', () {
    final canvas = _render(
      _diagram('''
sequenceDiagram
rect rgb(10,20,30)
A->>B: 界
end
'''),
    );
    final position = _locate(canvas, '界');
    final glyph = canvas.cellAt(position.x, position.y)!;
    expect(glyph.width, 2);
    expect(glyph.style.bg, const UvColor.rgb(10, 20, 30));
    expect(canvas.cellAt(position.x + 1, position.y)!.content, isEmpty);
    expect(
      canvas.cellAt(position.x + 1, position.y)!.style.bg,
      const UvColor.rgb(10, 20, 30),
    );
  });

  test('shortcut and explicit activation draw continuous bars', () {
    final shortcut = _render(
      _diagram('''
sequenceDiagram
  A->>+B: begin
  B-->>-A: finish
'''),
    );
    final explicit = _render(
      _diagram('''
sequenceDiagram
  A->>B: begin
  activate B
  B-->>A: finish
  deactivate B
'''),
    );

    final shortcutBars = _cells(
      shortcut,
    ).where((cell) => cell.content == '┃').length;
    final explicitBars = _cells(
      explicit,
    ).where((cell) => cell.content == '┃').length;
    expect(shortcutBars, greaterThanOrEqualTo(2));
    expect(explicitBars, greaterThanOrEqualTo(2));
  });

  test('nested activation bars use distinct horizontal cells', () {
    final canvas = _render(
      _diagram('''
sequenceDiagram
  A->>+B: outer
  B->>+B: inner
  B-->>-B: return
  B-->>-A: done
'''),
    );
    final positions = <int>{};
    for (var y = 0; y < canvas.bounds().maxY; y++) {
      for (var x = 0; x < canvas.bounds().maxX; x++) {
        if (canvas.cellAt(x, y)?.content == '┃') positions.add(x);
      }
    }
    expect(positions.length, greaterThanOrEqualTo(2));
  });

  test('rect background preserves glyph and nested rect precedence', () {
    const outer = UvColor.rgb(10, 20, 30);
    const inner = UvColor.rgb(40, 50, 60);
    final base = _diagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: outer
  B-->>A: inner
''');
    final diagram = (
      participants: base.participants,
      messages: base.messages,
      steps: base.steps,
      groups: base.groups,
      actorStyles: base.actorStyles,
      rects: [
        const SequenceRect(
          backgroundColor: outer,
          foregroundColor: null,
          startIndex: 0,
          endIndex: 2,
        ),
        const SequenceRect(
          backgroundColor: inner,
          foregroundColor: null,
          startIndex: 1,
          endIndex: 2,
        ),
      ],
    );
    final canvas = _render(diagram);
    final cells = _cells(canvas).where((cell) => cell.content == '│');
    expect(cells.any((cell) => cell.style.bg == outer), isTrue);
    expect(cells.any((cell) => cell.style.bg == inner), isTrue);
  });

  test('colored group background covers its interior', () {
    const color = UvColor.rgb(70, 80, 90);
    final base = _diagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: hello
''');
    final canvas = _render((
      participants: base.participants,
      messages: base.messages,
      steps: base.steps,
      rects: base.rects,
      actorStyles: base.actorStyles,
      groups: [
        const SequenceParticipantGroup(
          label: 'Team',
          ids: ['A', 'B'],
          backgroundColor: color,
        ),
      ],
    ));
    final bounds = canvas.bounds();
    var interior = 0;
    for (var y = 1; y < bounds.maxY; y++) {
      for (var x = 0; x < bounds.maxX; x++) {
        final cell = canvas.cellAt(x, y);
        if (cell?.style.bg == color) interior++;
      }
    }
    expect(interior, greaterThan(2));
  });

  test('nested fragment borders are inset and enclose timeline rows', () {
    final output = Style.stripAnsi(
      renderSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  alt outer
    A->>B: one
    loop inner
      B-->>A: two
    end
  else fallback
    A->>B: three
  end
'''),
    );
    final lines = output.split('\n');
    final innerStart = lines.indexWhere((line) => line.contains('loop: inner'));
    final innerEnd = lines.indexWhere(
      (line) => line.length > 1 && line[1] == '└',
    );
    final branch = lines.indexWhere((line) => line.contains('else: fallback'));
    final outerEnd = lines.indexWhere((line) => line.startsWith('└'));
    final innerMessage = lines.indexWhere((line) => line.contains('two'));
    final lastMessage = lines.indexWhere((line) => line.contains('three'));
    expect(innerStart, greaterThan(0));
    expect(innerMessage, greaterThan(innerStart));
    expect(innerEnd, greaterThan(innerMessage));
    expect(branch, greaterThan(innerEnd));
    expect(lastMessage, greaterThan(branch));
    expect(outerEnd, greaterThan(lastMessage));
    final innerRight = lines[innerStart].lastIndexOf('┤');
    for (var row = innerStart + 1; row < innerEnd; row++) {
      expect(lines[row][1], '│', reason: 'inner left boundary on row $row');
      expect(
        lines[row][innerRight],
        '│',
        reason: 'inner right boundary on row $row',
      );
    }
  });
}

({int x, int y}) _locate(Canvas canvas, String text) {
  for (var y = 0; y < canvas.height(); y++) {
    for (var x = 0; x <= canvas.width() - text.length; x++) {
      final actual = [
        for (var dx = 0; dx < text.length; dx++)
          canvas.cellAt(x + dx, y)?.content ?? '',
      ].join();
      if (actual == text) return (x: x, y: y);
    }
  }
  fail('Missing $text in ${canvas.render()}');
}
