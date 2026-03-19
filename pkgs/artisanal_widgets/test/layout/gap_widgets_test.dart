import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // RichText
  // ---------------------------------------------------------------------------
  group('RichText', () {
    test('renders plain text span', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(RichText(text: TextSpan(text: 'Hello')));
      expect(tester.find.text('Hello'), isTrue);
    });

    test('renders nested spans', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        RichText(
          text: TextSpan(
            text: 'Hello ',
            children: [TextSpan(text: 'World')],
          ),
        ),
      );
      expect(tester.find.text('Hello'), isTrue);
      expect(tester.find.text('World'), isTrue);
    });

    test('renders with styled spans (ANSI escapes present)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        RichText(
          text: TextSpan(
            text: 'Normal ',
            style: Style()..bold(true),
            children: [
              TextSpan(text: 'Red', style: Style()..foreground(Colors.red)),
            ],
          ),
        ),
      );
      // ANSI escape codes should be present for styling
      expect(tester.view, contains('['));
      expect(tester.find.text('Normal'), isTrue);
      expect(tester.find.text('Red'), isTrue);
    });

    test('respects textAlign center', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        RichText(
          text: TextSpan(text: 'Centered'),
          textAlign: TextAlign.center,
        ),
      );
      expect(tester.find.text('Centered'), isTrue);
    });

    test('respects textAlign right', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        RichText(
          text: TextSpan(text: 'Right'),
          textAlign: TextAlign.right,
        ),
      );
      expect(tester.find.text('Right'), isTrue);
    });

    test('respects overflow ellipsis with maxWidth', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        RichText(
          text: TextSpan(text: 'This is a very long text'),
          overflow: TextOverflow.ellipsis,
          maxWidth: 10,
        ),
      );
      expect(tester.find.text('This is a very long text'), isFalse);
      expect(tester.find.text('...'), isTrue);
    });

    test('renders empty span', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(RichText(text: TextSpan()));
      expect(tester.view, isNotNull);
    });

    test('renders deeply nested spans', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        RichText(
          text: TextSpan(
            text: 'A',
            children: [
              TextSpan(
                text: 'B',
                children: [TextSpan(text: 'C')],
              ),
            ],
          ),
        ),
      );
      expect(tester.find.text('ABC'), isTrue);
    });

    test('has unique id', () {
      final r1 = RichText(text: TextSpan(text: 'a'));
      final r2 = RichText(text: TextSpan(text: 'b'));
      expect(r1.id, isNot(equals(r2.id)));
    });

    test('respects key', () {
      final r = RichText(
        key: ValueKey('rich-key'),
        text: TextSpan(text: 'keyed'),
      );
      expect(r.id, equals('rich-key'));
    });

    test('is equivalent to Text.rich', () async {
      final tester1 = WidgetTester();
      addTearDown(() => tester1.dispose());
      final tester2 = WidgetTester();
      addTearDown(() => tester2.dispose());

      final span = TextSpan(
        text: 'Hello ',
        children: [TextSpan(text: 'World')],
      );

      await tester1.pumpWidget(RichText(text: span));
      await tester2.pumpWidget(Text.rich(span));

      // Both should render the same visible text
      expect(tester1.find.text('Hello'), isTrue);
      expect(tester2.find.text('Hello'), isTrue);
      expect(tester1.find.text('World'), isTrue);
      expect(tester2.find.text('World'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // BlockFocus
  // ---------------------------------------------------------------------------
  group('BlockFocus', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(BlockFocus(child: Text('Blocked')));
      expect(tester.find.text('Blocked'), isTrue);
    });

    test('renders child when blocking is false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        BlockFocus(blocking: false, child: Text('Unblocked')),
      );
      expect(tester.find.text('Unblocked'), isTrue);
    });

    test('blocking defaults to true', () {
      final bf = BlockFocus(child: Text('test'));
      expect(bf.blocking, isTrue);
    });

    test('has unique id', () {
      final b1 = BlockFocus(child: Text('a'));
      final b2 = BlockFocus(child: Text('b'));
      expect(b1.id, isNot(equals(b2.id)));
    });

    test('respects key', () {
      final b = BlockFocus(key: ValueKey('block-key'), child: Text('keyed'));
      expect(b.id, equals('block-key'));
    });

    test('blocks keyboard events from reaching children', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var keyReceived = false;
      await tester.pumpWidget(
        BlockFocus(
          child: KeyboardListener(
            onKey: (msg) {
              keyReceived = true;
              return null;
            },
            child: Text('Listener'),
          ),
        ),
      );

      tester.sendKey('a');
      expect(
        keyReceived,
        isFalse,
        reason: 'BlockFocus should prevent key events from reaching children',
      );
    });

    test('allows keyboard events when blocking is false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      var keyReceived = false;
      await tester.pumpWidget(
        BlockFocus(
          blocking: false,
          child: KeyboardListener(
            onKey: (msg) {
              keyReceived = true;
              return null;
            },
            child: Text('Listener'),
          ),
        ),
      );

      tester.sendKey('a');
      expect(
        keyReceived,
        isTrue,
        reason: 'Events should pass through when blocking is false',
      );
    });

    test('wraps complex child tree', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        BlockFocus(child: Column(children: [Text('Line 1'), Text('Line 2')])),
      );
      expect(tester.find.text('Line 1'), isTrue);
      expect(tester.find.text('Line 2'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // OverflowBox
  // ---------------------------------------------------------------------------
  group('OverflowBox', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(OverflowBox(child: Text('Overflow')));
      expect(tester.find.text('Overflow'), isTrue);
    });

    test('renders with no child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(OverflowBox());
      expect(tester.view, isNotNull);
    });

    test('has unique id', () {
      final o1 = OverflowBox(child: Text('a'));
      final o2 = OverflowBox(child: Text('b'));
      expect(o1.id, isNot(equals(o2.id)));
    });

    test('respects key', () {
      final o = OverflowBox(
        key: ValueKey('overflow-key'),
        child: Text('keyed'),
      );
      expect(o.id, equals('overflow-key'));
    });

    test('alignment defaults to center', () {
      final o = OverflowBox(child: Text('test'));
      expect(o.alignment, equals(Alignment.center));
    });

    test('constraint overrides are null by default', () {
      final o = OverflowBox(child: Text('test'));
      expect(o.minWidth, isNull);
      expect(o.maxWidth, isNull);
      expect(o.minHeight, isNull);
      expect(o.maxHeight, isNull);
    });

    test('accepts constraint overrides', () {
      final o = OverflowBox(
        minWidth: 5,
        maxWidth: 100,
        minHeight: 2,
        maxHeight: 50,
        child: Text('test'),
      );
      expect(o.minWidth, equals(5));
      expect(o.maxWidth, equals(100));
      expect(o.minHeight, equals(2));
      expect(o.maxHeight, equals(50));
    });

    test('children includes the child widget', () {
      final child = Text('inner');
      final box = OverflowBox(child: child);
      expect(box.children, equals([child]));
    });

    test('children is empty when no child', () {
      final box = OverflowBox();
      expect(box.children, isEmpty);
    });

    test('renders child within constrained parent', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        SizedBox(
          width: 10,
          height: 3,
          child: OverflowBox(maxWidth: 20, child: Text('Wide content')),
        ),
      );
      expect(tester.find.text('Wide'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // SizedOverflowBox
  // ---------------------------------------------------------------------------
  group('SizedOverflowBox', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        SizedOverflowBox(requestedSize: Size(20, 5), child: Text('Sized')),
      );
      expect(tester.find.text('Sized'), isTrue);
    });

    test('renders with no child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(SizedOverflowBox(requestedSize: Size(10, 3)));
      expect(tester.view, isNotNull);
    });

    test('has unique id', () {
      final s1 = SizedOverflowBox(requestedSize: Size(10, 5), child: Text('a'));
      final s2 = SizedOverflowBox(requestedSize: Size(10, 5), child: Text('b'));
      expect(s1.id, isNot(equals(s2.id)));
    });

    test('respects key', () {
      final s = SizedOverflowBox(
        key: ValueKey('sized-overflow-key'),
        requestedSize: Size(10, 5),
        child: Text('keyed'),
      );
      expect(s.id, equals('sized-overflow-key'));
    });

    test('stores requestedSize', () {
      final s = SizedOverflowBox(
        requestedSize: Size(30, 10),
        child: Text('test'),
      );
      expect(s.requestedSize.width, equals(30));
      expect(s.requestedSize.height, equals(10));
    });

    test('alignment defaults to center', () {
      final s = SizedOverflowBox(
        requestedSize: Size(10, 5),
        child: Text('test'),
      );
      expect(s.alignment, equals(Alignment.center));
    });

    test('children includes the child widget', () {
      final child = Text('inner');
      final box = SizedOverflowBox(requestedSize: Size(10, 5), child: child);
      expect(box.children, equals([child]));
    });

    test('children is empty when no child', () {
      final box = SizedOverflowBox(requestedSize: Size(10, 5));
      expect(box.children, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Tint
  // ---------------------------------------------------------------------------
  group('Tint', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Tint(color: Colors.red, child: Text('Tinted')));
      expect(tester.find.text('Tinted'), isTrue);
    });

    test('renders with no child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Tint(color: Colors.blue));
      expect(tester.view, isNotNull);
    });

    test('opacity defaults to 1.0', () {
      final t = Tint(color: Colors.red, child: Text('test'));
      expect(t.opacity, equals(1.0));
    });

    test('applies tint coloring (ANSI escapes present)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Tint(color: Colors.green, child: Text('Color')));
      // Should contain ANSI escape codes
      expect(tester.view, contains('['));
      expect(tester.find.text('Color'), isTrue);
    });

    test('zero opacity has no effect', () async {
      final tester1 = WidgetTester();
      addTearDown(() => tester1.dispose());
      final tester2 = WidgetTester();
      addTearDown(() => tester2.dispose());

      await tester1.pumpWidget(
        Tint(color: Colors.red, opacity: 0.0, child: Text('NoTint')),
      );
      await tester2.pumpWidget(Text('NoTint'));

      // With 0 opacity, tint should pass through content unchanged
      // Both should render the same visible text
      expect(tester1.find.text('NoTint'), isTrue);
      expect(tester2.find.text('NoTint'), isTrue);
    });

    test('partial opacity blends differently from full tint', () async {
      final partial = WidgetTester();
      addTearDown(() => partial.dispose());
      final full = WidgetTester();
      addTearDown(() => full.dispose());

      await partial.pumpWidget(
        Tint(color: Colors.red, opacity: 0.25, child: Text('Blend')),
      );
      await full.pumpWidget(
        Tint(color: Colors.red, opacity: 1.0, child: Text('Blend')),
      );

      expect(partial.view, isNot(equals(full.view)));
      expect(partial.find.text('Blend'), isTrue);
      expect(full.find.text('Blend'), isTrue);
    });

    test('has unique id', () {
      final t1 = Tint(color: Colors.red, child: Text('a'));
      final t2 = Tint(color: Colors.blue, child: Text('b'));
      expect(t1.id, isNot(equals(t2.id)));
    });

    test('respects key', () {
      final t = Tint(
        key: ValueKey('tint-key'),
        color: Colors.red,
        child: Text('keyed'),
      );
      expect(t.id, equals('tint-key'));
    });

    test('children includes the child widget', () {
      final child = Text('inner');
      final tint = Tint(color: Colors.red, child: child);
      expect(tint.children, equals([child]));
    });

    test('children is empty when no child', () {
      final tint = Tint(color: Colors.red);
      expect(tint.children, isEmpty);
    });

    test('wraps complex child tree', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Tint(
          color: Colors.blue,
          child: Column(children: [Text('Line 1'), Text('Line 2')]),
        ),
      );
      expect(tester.find.text('Line 1'), isTrue);
      expect(tester.find.text('Line 2'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Integration: composing new widgets together
  // ---------------------------------------------------------------------------
  group('New widgets integration', () {
    test('RichText inside ColoredBox', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ColoredBox(
          color: Colors.blue,
          child: RichText(text: TextSpan(text: 'Rich in color')),
        ),
      );
      expect(tester.find.text('Rich in color'), isTrue);
    });

    test('BlockFocus wrapping Tint', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        BlockFocus(
          child: Tint(color: Colors.red, child: Text('Blocked and tinted')),
        ),
      );
      expect(tester.find.text('Blocked and tinted'), isTrue);
    });

    test('OverflowBox inside ClipRect', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ClipRect(
          width: 15,
          child: OverflowBox(maxWidth: 30, child: Text('Overflowing clipped')),
        ),
      );
      // ClipRect should clip the overflowing content
      expect(tester.find.text('Overflowing cli'), isTrue);
    });

    test('RichText with multiple styled spans inside Container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          padding: EdgeInsets.all(1),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'Hello '),
                TextSpan(text: 'World', style: Style()..bold(true)),
              ],
            ),
          ),
        ),
      );
      expect(tester.find.text('Hello'), isTrue);
      expect(tester.find.text('World'), isTrue);
    });

    test('SizedOverflowBox in Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Text('Before'),
            SizedOverflowBox(requestedSize: Size(10, 1), child: Text('In box')),
            Text('After'),
          ],
        ),
      );
      expect(tester.find.text('Before'), isTrue);
      expect(tester.find.text('In box'), isTrue);
      expect(tester.find.text('After'), isTrue);
    });
  });
}
