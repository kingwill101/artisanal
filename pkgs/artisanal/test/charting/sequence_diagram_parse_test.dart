/// Tests for the sequence diagram parser.
library;

import 'package:artisanal/charting.dart';
import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart' show UvColor, UvRgb;

void _expectRgb(UvColor? color, int r, int g, int b) {
  expect(
    color,
    isA<UvRgb>(),
    reason: 'expected UvRgb but got ${color.runtimeType}',
  );
  final rgb = color as UvRgb;
  expect(rgb.r, r, reason: 'red channel');
  expect(rgb.g, g, reason: 'green channel');
  expect(rgb.b, b, reason: 'blue channel');
}

void main() {
  group('isSequenceDiagram', () {
    test('returns true for valid sequenceDiagram header', () {
      expect(isSequenceDiagram('sequenceDiagram\n  A->>B: Hello'), isTrue);
    });

    test('returns true case-insensitively', () {
      expect(isSequenceDiagram('SequenceDiagram\n  A->>B: Hello'), isTrue);
      expect(isSequenceDiagram('SEQUENCEDIAGRAM\n  A->>B: Hello'), isTrue);
    });

    test('skips comment lines before header', () {
      expect(isSequenceDiagram('%% comment\nsequenceDiagram'), isTrue);
    });

    test('returns false for non-sequence content', () {
      expect(isSequenceDiagram('graph TD\n  A --> B'), isFalse);
    });

    test('returns false for empty content', () {
      expect(isSequenceDiagram(''), isFalse);
    });
  });

  group('parseMermaidColor', () {
    test('parses CSS color names', () {
      _expectRgb(parseMermaidColor('red'), 255, 0, 0);
      _expectRgb(parseMermaidColor('blue'), 0, 0, 255);
    });

    test('parses CSS color names case-insensitively', () {
      _expectRgb(parseMermaidColor('Red'), 255, 0, 0);
    });

    test('parses 3-digit hex', () {
      _expectRgb(parseMermaidColor('#F00'), 255, 0, 0);
    });

    test('parses 6-digit hex', () {
      _expectRgb(parseMermaidColor('#FF8000'), 255, 128, 0);
    });

    test('parses rgb()', () {
      _expectRgb(parseMermaidColor('rgb(255, 128, 64)'), 255, 128, 64);
    });

    test('parses rgba()', () {
      _expectRgb(parseMermaidColor('rgba(255, 128, 64, 0.5)'), 255, 128, 64);
    });

    test('returns null for transparent', () {
      expect(parseMermaidColor('transparent'), isNull);
    });

    test('returns null for invalid input', () {
      expect(parseMermaidColor('notacolor'), isNull);
    });

    test('parses grey synonym', () {
      _expectRgb(parseMermaidColor('grey'), 128, 128, 128);
    });
  });

  group('parseSequenceDiagram', () {
    test('returns null for non-sequence content', () {
      expect(parseSequenceDiagram('graph TD'), isNull);
    });

    test('parses participants', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A as Alice
  participant B as Bob
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      expect(d.participants.length, 2);
      expect(d.participants[0].id, 'A');
      expect(d.participants[0].label, 'Alice');
      expect(d.participants[1].id, 'B');
      expect(d.participants[1].label, 'Bob');
    });

    test('parses participant without alias', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant Alice
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      expect(d.participants.length, 1);
      expect(d.participants[0].id, 'Alice');
      expect(d.participants[0].label, 'Alice');
    });

    test('parses actor declaration', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  actor A as Alice
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      expect(d.participants.length, 1);
      expect(d.participants[0].id, 'A');
    });

    test('parses solid arrow message', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->>B: Hello
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      expect(d.messages.length, 1);
      final msg = d.messages[0];
      expect(msg.from, 'A');
      expect(msg.to, 'B');
      expect(msg.label, 'Hello');
      expect(msg.style, SequenceMessageStyle.solid);
    });

    test('parses dashed arrow message', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A-->>B: Response
''');
      expect(diagram, isNotNull);
      final msg = diagram!.messages[0];
      expect(msg.style, SequenceMessageStyle.dashed);
    });

    test('parses cross arrow head', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A--xB: Cancel
''');
      expect(diagram, isNotNull);
      final msg = diagram!.messages[0];
      expect(msg.head, SequenceArrowHead.cross);
    });

    test('parses async arrow head', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->)B: Signal
''');
      expect(diagram, isNotNull);
      final msg = diagram!.messages[0];
      expect(msg.head, SequenceArrowHead.async);
    });

    test('parses activation marker', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->>+B: Call
''');
      expect(diagram, isNotNull);
      final msg = diagram!.messages[0];
      expect(msg.activate, 'B');
    });

    test('parses deactivation marker', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->>-B: Return
''');
      expect(diagram, isNotNull);
      final msg = diagram!.messages[0];
      expect(msg.deactivate, 'A');
    });

    test('parses note over single participant', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->>B: Hello
  note over A: This is A
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      expect(d.steps.whereType<SequenceStepNote>().length, 1);
      final noteStep = d.steps.whereType<SequenceStepNote>().first;
      expect(noteStep.note.over, ['A']);
      expect(noteStep.note.label, 'This is A');
    });

    test('parses note over multiple participants', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->>B: Hello
  note over A,B: Shared note
''');
      expect(diagram, isNotNull);
      final noteStep = diagram!.steps.whereType<SequenceStepNote>().first;
      expect(noteStep.note.over, ['A', 'B']);
    });

    test('parses note right/left', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->>B: Hello
  note right of A: Right note
  note left of B: Left note
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final notes = d.steps.whereType<SequenceStepNote>().toList();
      expect(notes.length, 2);
      expect(notes[0].note.over, ['A']);
      expect(notes[1].note.over, ['B']);
    });

    test('parses activation/deactivation steps', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->>B: Call
  activate B
  B->>A: Response
  deactivate B
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final activations = d.steps.whereType<SequenceStepActivation>().toList();
      expect(activations.length, 2);
      expect(activations[0].activation.participant, 'B');
      expect(activations[0].activation.active, isTrue);
      expect(activations[1].activation.participant, 'B');
      expect(activations[1].activation.active, isFalse);
    });

    test('parses alt fragment', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  alt condition
    A->>B: Yes
  else
    A->>B: No
  end
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final fragments = d.steps.whereType<SequenceStepFragment>().toList();
      expect(fragments.length, 3);
      expect(fragments[0].fragment.kind, SequenceFragmentKind.alt);
      expect(fragments[0].fragment.label, 'condition');
      expect(fragments[1].fragment.kind, SequenceFragmentKind.elsePart);
      expect(fragments[2].fragment.kind, SequenceFragmentKind.end);
    });

    test('parses loop fragment', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  loop 3 times
    A->>B: Repeat
  end
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final fragments = d.steps.whereType<SequenceStepFragment>().toList();
      expect(fragments.length, 2);
      expect(fragments[0].fragment.kind, SequenceFragmentKind.loop);
      expect(fragments[0].fragment.label, '3 times');
    });

    test('parses opt fragment (as alt)', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  opt condition
    A->>B: Optional
  end
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final fragments = d.steps.whereType<SequenceStepFragment>().toList();
      expect(fragments.length, 2);
      expect(fragments[0].fragment.kind, SequenceFragmentKind.alt);
    });

    test('parses box grouping', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  box Group 1
    participant A
    participant B
  end
  participant C
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      expect(d.groups.length, 1);
      expect(d.groups[0].label, 'Group 1');
      expect(d.groups[0].ids, ['A', 'B']);
    });

    test('parses rect regions', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  rect rgb(200, 200, 200)
    A->>B: In rect
  end
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      expect(d.rects.length, 1);
      expect(d.rects[0].startIndex, 0);
    });

    test('parses autonumbering', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  autonumber
  A->>B: First
  A->>B: Second
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final msgs = d.messages;
      expect(msgs[0].number, 1);
      expect(msgs[1].number, 2);
    });

    test('parses autonumber with start and increment', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  autonumber 10 5
  A->>B: First
  A->>B: Second
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final msgs = d.messages;
      expect(msgs[0].number, 10);
      expect(msgs[1].number, 15);
    });

    test('parses style declarations', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A
  style A fill:#f9f,stroke:#333
''');
      expect(diagram, isNotNull);
      expect(diagram!.actorStyles.containsKey('A'), isTrue);
    });

    test('parses classDef declarations', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  classDef myClass fill:#f9f
''');
      expect(diagram, isNotNull);
      expect(diagram!.actorStyles.containsKey('classDef:myClass'), isTrue);
    });

    test('auto-creates participants from messages', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->>B: Hello
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      expect(d.participants.length, 2);
      expect(d.participants.map((p) => p.id), contains('A'));
      expect(d.participants.map((p) => p.id), contains('B'));
    });

    test('parses self-message', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->>A: Self call
''');
      expect(diagram, isNotNull);
      final msg = diagram!.messages[0];
      expect(msg.from, msg.to);
    });

    test('parses quoted labels', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A->>B: "Hello World"
''');
      expect(diagram, isNotNull);
      expect(diagram!.messages[0].label, 'Hello World');
    });

    test('parses bidirectional arrow', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  A<->B: Sync
''');
      expect(diagram, isNotNull);
      expect(diagram!.messages.length, 1);
    });

    test('parses empty diagram body', () {
      final diagram = parseSequenceDiagram('sequenceDiagram');
      expect(diagram, isNotNull);
      final d = diagram!;
      expect(d.participants, isEmpty);
      expect(d.messages, isEmpty);
    });

    test('steps contain correct types', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  participant A
  participant B
  A->>B: Hello
  note over A: Note
  loop repeat
    A->>B: Again
  end
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final stepTypes = d.steps.map((s) => s.runtimeType).toList();
      expect(stepTypes, contains(SequenceStepMessage));
      expect(stepTypes, contains(SequenceStepNote));
      expect(stepTypes, contains(SequenceStepFragment));
    });

    test('parses critical fragment', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  critical must succeed
    A->>B: Do it
  end
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final fragments = d.steps.whereType<SequenceStepFragment>().toList();
      expect(fragments[0].fragment.kind, SequenceFragmentKind.alt);
    });

    test('parses par fragment', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  par parallel
    A->>B: Task 1
  and
    A->>C: Task 2
  end
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final fragments = d.steps.whereType<SequenceStepFragment>().toList();
      expect(fragments.length, 3);
      expect(fragments[0].fragment.kind, SequenceFragmentKind.alt);
      expect(fragments[1].fragment.kind, SequenceFragmentKind.elsePart);
    });

    test('parses break statement', () {
      final diagram = parseSequenceDiagram('''
sequenceDiagram
  loop try
    A->>B: Attempt
  break failure
    A->>A: Handle error
  end
''');
      expect(diagram, isNotNull);
      final d = diagram!;
      final fragments = d.steps.whereType<SequenceStepFragment>().toList();
      final breakFragment = fragments.firstWhere(
        (f) => f.fragment.label == 'failure',
      );
      expect(breakFragment.fragment.kind, SequenceFragmentKind.elsePart);
    });
  });
}
