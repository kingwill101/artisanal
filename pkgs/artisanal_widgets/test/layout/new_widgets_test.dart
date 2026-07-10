import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Builder
  // ---------------------------------------------------------------------------
  group('Builder', () {
    test('renders widget returned by builder callback', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Builder(builder: (context) => Text('Built')));
      expect(tester.find.text('Built'), isTrue);
    });

    test('builder callback provides BuildContext', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      late Object capturedContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedContext = context;
            return Text('OK');
          },
        ),
      );
      expect(capturedContext, isNotNull);
    });

    test('can access theme from context', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            final theme = ThemeScope.of(context);
            // Theme should be available (uses global fallback)
            return Text('Theme: ${theme.primary}');
          },
        ),
      );
      expect(tester.find.text('Theme:'), isTrue);
    });

    test('renders complex widget tree from builder', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            return Column(children: [Text('Line 1'), Text('Line 2')]);
          },
        ),
      );
      expect(tester.find.text('Line 1'), isTrue);
      expect(tester.find.text('Line 2'), isTrue);
    });

    test('has unique id', () {
      final b1 = Builder(builder: (_) => Text('a'));
      final b2 = Builder(builder: (_) => Text('b'));
      expect(b1.id, isNot(equals(b2.id)));
    });

    test('respects key', () {
      final b = Builder(
        key: ValueKey('builder-key'),
        builder: (_) => Text('keyed'),
      );
      expect(b.id, equals('builder-key'));
    });

    test('is not focusable', () {
      final b = Builder(builder: (_) => Text('x'));
      expect(b.focusable, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // VerticalDivider
  // ---------------------------------------------------------------------------
  group('VerticalDivider', () {
    test('default height is 3', () {
      final divider = VerticalDivider();
      expect(divider.height, equals(3));
    });

    test('default char is │', () {
      final divider = VerticalDivider();
      expect(divider.char, equals('│'));
    });

    test('renders vertical line with default chars', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(VerticalDivider(height: 3));
      // Should render 3 '│' characters separated by newlines
      final pos = tester.locateText('│');
      expect(pos, isNotNull, reason: 'Should render │ character');
    });

    test('renders with custom height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(VerticalDivider(height: 5, char: '|'));
      final pos = tester.locateText('|');
      expect(pos, isNotNull, reason: 'Should render | character');
    });

    test('renders with custom char', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(VerticalDivider(height: 2, char: ':'));
      final pos = tester.locateText(':');
      expect(pos, isNotNull, reason: 'Should render : character');
    });

    test('uses theme border color by default', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(VerticalDivider());
      // Should have ANSI styling from theme border color
      expect(tester.view, contains('['));
    });

    test('has unique id', () {
      final d1 = VerticalDivider();
      final d2 = VerticalDivider();
      expect(d1.id, isNot(equals(d2.id)));
    });

    test('respects key', () {
      final d = VerticalDivider(key: ValueKey('vdiv-key'));
      expect(d.id, equals('vdiv-key'));
    });

    test('is not focusable', () {
      final d = VerticalDivider();
      expect(d.focusable, isFalse);
    });

    test('renders between horizontal items in Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Text('Left'),
            VerticalDivider(height: 1, char: '|'),
            Text('Right'),
          ],
        ),
      );
      expect(tester.locateText('Left'), isNotNull);
      expect(tester.locateText('|'), isNotNull);
      expect(tester.locateText('Right'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // ColoredBox
  // ---------------------------------------------------------------------------
  group('ColoredBox', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ColoredBox(color: Colors.blue, child: Text('Colored')),
      );
      expect(tester.find.text('Colored'), isTrue);
    });

    test('renders with no child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ColoredBox(color: Colors.red));
      // Should render without error even with no child
      expect(tester.view, isNotNull);
    });

    test('applies background color (ANSI escapes present)', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ColoredBox(color: Colors.green, child: Text('BG')),
      );
      // Raw view should contain ANSI escape codes for background
      expect(tester.view, contains('['));
      expect(tester.find.text('BG'), isTrue);
    });

    test('has unique id', () {
      final c1 = ColoredBox(color: Colors.red, child: Text('a'));
      final c2 = ColoredBox(color: Colors.blue, child: Text('b'));
      expect(c1.id, isNot(equals(c2.id)));
    });

    test('respects key', () {
      final c = ColoredBox(
        key: ValueKey('cbox-key'),
        color: Colors.red,
        child: Text('keyed'),
      );
      expect(c.id, equals('cbox-key'));
    });

    test('children includes the child widget', () {
      final child = Text('inner');
      final box = ColoredBox(color: Colors.red, child: child);
      expect(box.children, equals([child]));
    });

    test('children is empty when no child', () {
      final box = ColoredBox(color: Colors.red);
      expect(box.children, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // DecoratedBox
  // ---------------------------------------------------------------------------
  group('DecoratedBox', () {
    test('renders child with plain decoration', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecoratedBox(
          decoration: Decoration(color: Colors.cyan),
          child: Text('Decorated'),
        ),
      );
      expect(tester.find.text('Decorated'), isTrue);
    });

    test('renders child with BoxDecoration border', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecoratedBox(
          decoration: BoxDecoration(border: Border.rounded),
          child: Padding(padding: EdgeInsets.all(1), child: Text('Boxed')),
        ),
      );
      expect(tester.find.text('Boxed'), isTrue);
      // Should have border characters
      expect(tester.view, isNotEmpty);
    });

    test('renders with no child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecoratedBox(decoration: Decoration(color: Colors.red)),
      );
      expect(tester.view, isNotNull);
    });

    test('foreground position works', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecoratedBox(
          decoration: Decoration(color: Colors.yellow),
          position: DecorationPosition.foreground,
          child: Text('FG'),
        ),
      );
      expect(tester.find.text('FG'), isTrue);
    });

    test('has unique id', () {
      final d1 = DecoratedBox(decoration: Decoration(), child: Text('a'));
      final d2 = DecoratedBox(decoration: Decoration(), child: Text('b'));
      expect(d1.id, isNot(equals(d2.id)));
    });

    test('respects key', () {
      final d = DecoratedBox(
        key: ValueKey('dbox-key'),
        decoration: Decoration(),
        child: Text('keyed'),
      );
      expect(d.id, equals('dbox-key'));
    });

    test('children includes the child widget', () {
      final child = Text('inner');
      final box = DecoratedBox(decoration: Decoration(), child: child);
      expect(box.children, equals([child]));
    });

    test('DecorationPosition enum values exist', () {
      expect(DecorationPosition.values, hasLength(2));
      expect(
        DecorationPosition.values,
        contains(DecorationPosition.background),
      );
      expect(
        DecorationPosition.values,
        contains(DecorationPosition.foreground),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // LayoutBuilder
  // ---------------------------------------------------------------------------
  group('LayoutBuilder', () {
    test('renders widget from builder callback', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        LayoutBuilder(builder: (context, constraints) => Text('Layout')),
      );
      expect(tester.find.text('Layout'), isTrue);
    });

    test('provides BoxConstraints to builder', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      late BoxConstraints capturedConstraints;
      await tester.pumpWidget(
        LayoutBuilder(
          builder: (context, constraints) {
            capturedConstraints = constraints;
            return Text('Got constraints');
          },
        ),
      );
      expect(capturedConstraints, isNotNull);
    });

    test('constraints reflect MediaQuery when available', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      late BoxConstraints capturedConstraints;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(80, 24)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              capturedConstraints = constraints;
              return Text('With media');
            },
          ),
        ),
      );
      expect(capturedConstraints.maxWidth, equals(80));
      expect(capturedConstraints.maxHeight, equals(24));
    });

    test('has unique id', () {
      final l1 = LayoutBuilder(builder: (context, constraints) => Text('a'));
      final l2 = LayoutBuilder(builder: (context, constraints) => Text('b'));
      expect(l1.id, isNot(equals(l2.id)));
    });

    test('respects key', () {
      final l = LayoutBuilder(
        key: ValueKey('lb-key'),
        builder: (context, constraints) => Text('keyed'),
      );
      expect(l.id, equals('lb-key'));
    });

    test('is not focusable', () {
      final l = LayoutBuilder(builder: (context, constraints) => Text('x'));
      expect(l.focusable, isFalse);
    });

    test('can build responsive layout based on constraints', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(120, 40)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 80) {
                return Text('Wide layout');
              }
              return Text('Narrow layout');
            },
          ),
        ),
      );
      expect(tester.find.text('Wide layout'), isTrue);
    });

    test('narrow layout path works', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(60, 20)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 80) {
                return Text('Wide layout');
              }
              return Text('Narrow layout');
            },
          ),
        ),
      );
      expect(tester.find.text('Narrow layout'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ClipRect
  // ---------------------------------------------------------------------------
  group('ClipRect', () {
    test('renders child without clipping when no dimensions set', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ClipRect(child: Text('No clip')));
      expect(tester.find.text('No clip'), isTrue);
    });

    test('clips child width', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ClipRect(width: 5, child: Text('Hello World')));
      // 'Hello World' is 11 chars, clip to 5 should truncate
      expect(tester.find.text('Hello World'), isFalse);
      expect(tester.find.text('Hello'), isTrue);
    });

    test('clips child height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ClipRect(
          height: 1,
          child: Column(
            children: [Text('Line 1'), Text('Line 2'), Text('Line 3')],
          ),
        ),
      );
      // Only first line should be visible
      expect(tester.find.text('Line 1'), isTrue);
      expect(tester.find.text('Line 2'), isFalse);
      expect(tester.find.text('Line 3'), isFalse);
    });

    test('clips both width and height', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ClipRect(
          width: 4,
          height: 1,
          child: Column(
            children: [Text('Long text here'), Text('Second line')],
          ),
        ),
      );
      expect(tester.find.text('Long text here'), isFalse);
      expect(tester.find.text('Long'), isTrue);
      expect(tester.find.text('Second line'), isFalse);
    });

    test('renders with no child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(ClipRect(width: 10, height: 5));
      expect(tester.view, isNotNull);
    });

    test('has unique id', () {
      final c1 = ClipRect(child: Text('a'));
      final c2 = ClipRect(child: Text('b'));
      expect(c1.id, isNot(equals(c2.id)));
    });

    test('respects key', () {
      final c = ClipRect(key: ValueKey('clip-key'), child: Text('keyed'));
      expect(c.id, equals('clip-key'));
    });

    test('children includes the child widget', () {
      final child = Text('inner');
      final clip = ClipRect(child: child);
      expect(clip.children, equals([child]));
    });

    test('children is empty when no child', () {
      final clip = ClipRect();
      expect(clip.children, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Enhanced ProgressIndicator
  // ---------------------------------------------------------------------------
  group('Enhanced ProgressIndicator', () {
    test('block style uses block characters', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(
          value: 0.5,
          width: 10,
          progressStyle: ProgressStyle.block,
        ),
      );
      expect(tester.view, isNotEmpty);
      expect(tester.locateText('█'), isNotNull, reason: 'Block fill char');
      expect(tester.locateText('░'), isNotNull, reason: 'Block track char');
    });

    test('dot style uses dot characters', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(
          value: 0.5,
          width: 10,
          progressStyle: ProgressStyle.dot,
        ),
      );
      expect(tester.view, isNotEmpty);
      expect(tester.locateText('●'), isNotNull, reason: 'Dot fill char');
      expect(tester.locateText('○'), isNotNull, reason: 'Dot track char');
    });

    test('arrow style uses arrow characters', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(
          value: 0.5,
          width: 10,
          progressStyle: ProgressStyle.arrow,
        ),
      );
      expect(tester.view, isNotEmpty);
      expect(tester.locateText('>'), isNotNull, reason: 'Arrow fill char');
    });

    test('showBorder=false hides border characters', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(value: 0.5, width: 10, showBorder: false),
      );
      expect(tester.view, isNotEmpty);
      expect(tester.locateText('['), isNull, reason: 'No left border');
      expect(tester.locateText(']'), isNull, reason: 'No right border');
    });

    test('custom border characters', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(
          value: 0.5,
          width: 10,
          borderLeft: '(',
          borderRight: ')',
        ),
      );
      expect(tester.view, isNotEmpty);
      expect(tester.locateText('('), isNotNull, reason: 'Custom left border');
      expect(tester.locateText(')'), isNotNull, reason: 'Custom right border');
    });

    test('labelFormat callback formats label', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(
          value: 0.75,
          width: 10,
          labelFormat: (v) => '${(v * 100).toStringAsFixed(1)}%',
        ),
      );
      expect(tester.view, isNotEmpty);
      expect(
        tester.locateText('75.0%'),
        isNotNull,
        reason: 'Custom format should show 75.0%',
      );
    });

    test('left label position renders label before bar', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(
          value: 0.5,
          width: 10,
          showLabel: true,
          labelPosition: ProgressLabelPosition.left,
        ),
      );
      expect(tester.view, isNotEmpty);
      final labelPos = tester.locateText('50%');
      expect(labelPos, isNotNull);
    });

    test('ProgressStyle enum values exist', () {
      expect(ProgressStyle.values, hasLength(5));
      expect(ProgressStyle.values, contains(ProgressStyle.classic));
      expect(ProgressStyle.values, contains(ProgressStyle.block));
      expect(ProgressStyle.values, contains(ProgressStyle.arrow));
      expect(ProgressStyle.values, contains(ProgressStyle.dot));
      expect(ProgressStyle.values, contains(ProgressStyle.braille));
    });

    test('ProgressLabelPosition enum values exist', () {
      expect(ProgressLabelPosition.values, hasLength(3));
      expect(
        ProgressLabelPosition.values,
        contains(ProgressLabelPosition.right),
      );
      expect(
        ProgressLabelPosition.values,
        contains(ProgressLabelPosition.left),
      );
      expect(
        ProgressLabelPosition.values,
        contains(ProgressLabelPosition.inside),
      );
    });

    test('custom fillChar overrides progressStyle', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ProgressIndicator(
          value: 1.0,
          width: 5,
          progressStyle: ProgressStyle.block,
          fillChar: 'X',
        ),
      );
      expect(tester.view, isNotEmpty);
      expect(
        tester.locateText('XXXXX'),
        isNotNull,
        reason: 'fillChar should override progressStyle',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Integration
  // ---------------------------------------------------------------------------
  group('New widgets integration', () {
    test('Builder inside ColoredBox', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ColoredBox(
          color: Colors.blue,
          child: Builder(builder: (context) => Text('Inside colored box')),
        ),
      );
      expect(tester.find.text('Inside colored box'), isTrue);
    });

    test('ClipRect inside DecoratedBox', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecoratedBox(
          decoration: Decoration(color: Colors.green),
          child: ClipRect(
            width: 10,
            child: Text('A very long text that will be clipped'),
          ),
        ),
      );
      expect(tester.find.text('A very lon'), isTrue);
    });

    test('VerticalDivider between items in Row', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Row(
          children: [
            Text('A'),
            VerticalDivider(height: 1, char: '|'),
            Text('B'),
          ],
        ),
      );
      expect(tester.locateText('A'), isNotNull);
      expect(tester.locateText('|'), isNotNull);
      expect(tester.locateText('B'), isNotNull);
    });

    test('LayoutBuilder with ProgressIndicator', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        LayoutBuilder(
          builder: (context, constraints) {
            return ProgressIndicator(
              value: 0.5,
              width: 10,
              progressStyle: ProgressStyle.block,
            );
          },
        ),
      );
      expect(tester.view, isNotEmpty);
    });
  });
}
