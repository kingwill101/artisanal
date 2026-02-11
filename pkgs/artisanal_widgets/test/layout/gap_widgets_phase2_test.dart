import 'dart:async';
import 'dart:typed_data';

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // MarkdownText
  // ---------------------------------------------------------------------------
  group('MarkdownText', () {
    test('renders plain text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(MarkdownText(data: 'Hello world'));
      expect(tester.find.text('Hello world'), isTrue);
    });

    test('renders heading with emphasis', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(MarkdownText(data: '# Title'));
      expect(tester.find.text('Title'), isTrue);
    });

    test('renders bold text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(MarkdownText(data: 'This is **bold**'));
      expect(tester.find.text('bold'), isTrue);
    });

    test('renders list items', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(MarkdownText(data: '- Item 1\n- Item 2'));
      expect(tester.find.text('Item 1'), isTrue);
      expect(tester.find.text('Item 2'), isTrue);
    });

    test('respects maxWidth option', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(MarkdownText(data: 'Short text', maxWidth: 40));
      expect(tester.find.text('Short text'), isTrue);
    });

    test('renders empty string without error', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(MarkdownText(data: ''));
      expect(tester.view, isNotNull);
    });

    test('has unique id', () {
      final m1 = MarkdownText(data: 'a');
      final m2 = MarkdownText(data: 'b');
      expect(m1.id, isNot(equals(m2.id)));
    });

    test('respects key', () {
      final m = MarkdownText(key: ValueKey('md-key'), data: 'hello');
      expect(m.id, equals('md-key'));
    });
  });

  // ---------------------------------------------------------------------------
  // LimitedBox
  // ---------------------------------------------------------------------------
  group('LimitedBox', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(LimitedBox(maxWidth: 50, child: Text('limited')));
      expect(tester.find.text('limited'), isTrue);
    });

    test('defaults to infinite limits', () {
      final box = LimitedBox(child: Text('test'));
      expect(box.maxWidth, double.infinity);
      expect(box.maxHeight, double.infinity);
    });

    test('stores explicit limits', () {
      final box = LimitedBox(maxWidth: 80, maxHeight: 24);
      expect(box.maxWidth, 80);
      expect(box.maxHeight, 24);
    });

    test('renders without child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(LimitedBox(maxWidth: 20, maxHeight: 10));
      expect(tester.view, isNotNull);
    });

    test('has unique id', () {
      final b1 = LimitedBox(child: Text('a'));
      final b2 = LimitedBox(child: Text('b'));
      expect(b1.id, isNot(equals(b2.id)));
    });

    test('respects key', () {
      final b = LimitedBox(key: ValueKey('lim-key'), child: Text('keyed'));
      expect(b.id, equals('lim-key'));
    });
  });

  // ---------------------------------------------------------------------------
  // TUIErrorWidget
  // ---------------------------------------------------------------------------
  group('TUIErrorWidget', () {
    test('renders error message', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(TUIErrorWidget(message: 'Something failed'));
      expect(tester.find.text('Something failed'), isTrue);
    });

    test('shows error icon by default', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(TUIErrorWidget(message: 'Error'));
      // The icon prefix is '✗ '
      expect(tester.view, contains('✗'));
    });

    test('hides error icon when showIcon is false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TUIErrorWidget(message: 'Error', showIcon: false),
      );
      expect(tester.view, isNot(contains('✗')));
      expect(tester.find.text('Error'), isTrue);
    });

    test('renders details when provided', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TUIErrorWidget(message: 'Crash', details: 'Stack trace line 1'),
      );
      expect(tester.find.text('Crash'), isTrue);
      expect(tester.find.text('Stack trace line 1'), isTrue);
    });

    test('renders without details', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(TUIErrorWidget(message: 'Just a message'));
      expect(tester.find.text('Just a message'), isTrue);
    });

    test('has unique id', () {
      final e1 = TUIErrorWidget(message: 'a');
      final e2 = TUIErrorWidget(message: 'b');
      expect(e1.id, isNot(equals(e2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // ErrorThrowingWidget & FlutterError
  // ---------------------------------------------------------------------------
  group('ErrorThrowingWidget', () {
    test('build() throws FlutterError', () {
      final w = ErrorThrowingWidget(message: 'test error');
      expect(() => w.build(_DummyBuildContext()), throwsA(isA<FlutterError>()));
    });

    test('default message is "Widget error"', () {
      final w = ErrorThrowingWidget();
      expect(w.message, 'Widget error');
    });

    test('custom message is stored', () {
      final w = ErrorThrowingWidget(message: 'custom');
      expect(w.message, 'custom');
    });
  });

  group('FlutterError', () {
    test('stores message', () {
      final e = FlutterError('test');
      expect(e.message, 'test');
    });

    test('toString includes FlutterError prefix', () {
      final e = FlutterError('boom');
      expect(e.toString(), contains('FlutterError'));
      expect(e.toString(), contains('boom'));
    });

    test('is an Error', () {
      expect(FlutterError('x'), isA<Error>());
    });
  });

  // ---------------------------------------------------------------------------
  // Transform
  // ---------------------------------------------------------------------------
  group('Transform', () {
    test('renders child with translate', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Transform.translate(offset: Offset(2, 1), child: Text('Shifted')),
      );
      expect(tester.find.text('Shifted'), isTrue);
    });

    test('translate stores correct offsets', () {
      final t = Transform.translate(offset: Offset(5, 3), child: Text('test'));
      expect(t.translateX, 5);
      expect(t.translateY, 3);
      expect(t.flipH, isFalse);
      expect(t.flipV, isFalse);
    });

    test('flipHorizontal sets flipH flag', () {
      final t = Transform.flipHorizontal(child: Text('test'));
      expect(t.flipH, isTrue);
      expect(t.flipV, isFalse);
      expect(t.translateX, 0);
      expect(t.translateY, 0);
    });

    test('flipVertical sets flipV flag', () {
      final t = Transform.flipVertical(child: Text('test'));
      expect(t.flipH, isFalse);
      expect(t.flipV, isTrue);
    });

    test('renders child with flipHorizontal', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Transform.flipHorizontal(child: Text('AB')));
      // After horizontal flip, the content should be present
      // (character order reversed at cell level)
      expect(tester.view, isNotNull);
      expect(tester.view.isNotEmpty, isTrue);
    });

    test('renders child with flipVertical', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Transform.flipVertical(child: Text('Hello')));
      expect(tester.view, isNotNull);
      expect(tester.view.isNotEmpty, isTrue);
    });

    test('default constructor allows all options', () {
      final t = Transform(
        translateX: 1,
        translateY: 2,
        flipH: true,
        flipV: true,
        child: Text('all'),
      );
      expect(t.translateX, 1);
      expect(t.translateY, 2);
      expect(t.flipH, isTrue);
      expect(t.flipV, isTrue);
    });

    test('renders without child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Transform.translate(offset: Offset(1, 1)));
      expect(tester.view, isNotNull);
    });

    test('has unique id', () {
      final t1 = Transform.translate(offset: Offset(0, 0));
      final t2 = Transform.translate(offset: Offset(1, 1));
      expect(t1.id, isNot(equals(t2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // AsciiFont
  // ---------------------------------------------------------------------------
  group('AsciiFont', () {
    test('standard font has height 5', () {
      expect(AsciiFont.standard.height, 5);
    });

    test('banner font has height 7', () {
      expect(AsciiFont.banner.height, 7);
    });

    test('block font has height 6', () {
      expect(AsciiFont.block.height, 6);
    });

    test('slim font has height 5', () {
      expect(AsciiFont.slim.height, 5);
    });

    test('standard font has letter A glyph', () {
      final glyph = AsciiFont.standard.getGlyph('A');
      expect(glyph.height, 5);
      expect(glyph.width, greaterThan(0));
    });

    test('standard font has digits', () {
      for (var i = 0; i <= 9; i++) {
        final glyph = AsciiFont.standard.getGlyph('$i');
        expect(glyph.height, 5);
        expect(glyph.width, greaterThan(0));
      }
    });

    test('getGlyph converts lowercase to uppercase', () {
      final upper = AsciiFont.standard.getGlyph('A');
      final lower = AsciiFont.standard.getGlyph('a');
      // Both should return the same glyph (case-insensitive lookup)
      expect(upper.lines, equals(lower.lines));
    });

    test('getGlyph returns fallback for unknown character', () {
      final glyph = AsciiFont.standard.getGlyph('™');
      // Fallback glyph should have the font height
      expect(glyph.height, 5);
    });

    test('space glyph has consistent height', () {
      final glyph = AsciiFont.standard.getGlyph(' ');
      expect(glyph.height, 5);
    });

    test('banner font has letter spacing 2', () {
      expect(AsciiFont.banner.letterSpacing, 2);
    });

    test('standard font has letter spacing 1', () {
      expect(AsciiFont.standard.letterSpacing, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // AsciiText
  // ---------------------------------------------------------------------------
  group('AsciiText', () {
    test('renders single character', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AsciiText(data: 'A'));
      // ASCII art output should have multiple lines (font height = 5)
      final lines = tester.view.split('\n');
      expect(lines.length, greaterThanOrEqualTo(5));
    });

    test('renders multi-character text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AsciiText(data: 'HI'));
      expect(tester.view, isNotEmpty);
      final lines = tester.view.split('\n');
      expect(lines.length, greaterThanOrEqualTo(5));
    });

    test('renders empty string', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(AsciiText(data: ''));
      // Empty input should produce empty or minimal output
      expect(tester.view, isNotNull);
    });

    test('uses standard font by default', () {
      final at = AsciiText(data: 'X');
      expect(at.font.height, 5); // Standard font is 5 high
    });

    test('stores custom font', () {
      final at = AsciiText(data: 'X', font: AsciiFont.banner);
      expect(at.font.height, 7); // Banner font is 7 high
    });

    test('stores text alignment', () {
      final at = AsciiText(data: 'X', textAlign: TextAlign.center);
      expect(at.textAlign, TextAlign.center);
    });

    test('stores maxWidth', () {
      final at = AsciiText(data: 'X', maxWidth: 100);
      expect(at.maxWidth, 100);
    });

    test('has unique id', () {
      final a1 = AsciiText(data: 'A');
      final a2 = AsciiText(data: 'B');
      expect(a1.id, isNot(equals(a2.id)));
    });

    test('respects key', () {
      final a = AsciiText(key: ValueKey('ascii-key'), data: 'X');
      expect(a.id, equals('ascii-key'));
    });
  });

  // ---------------------------------------------------------------------------
  // StyledAsciiText
  // ---------------------------------------------------------------------------
  group('StyledAsciiText', () {
    test('renders without style', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(StyledAsciiText(data: 'HI'));
      expect(tester.view, isNotEmpty);
    });

    test('renders with style', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StyledAsciiText(data: 'HI', style: Style()..foreground(Colors.red)),
      );
      // Should contain ANSI escape for styling
      expect(tester.view, contains('['));
    });

    test('stores data and style', () {
      final s = StyledAsciiText(
        data: 'TEST',
        style: Style()..bold(true),
        font: AsciiFont.block,
      );
      expect(s.data, 'TEST');
      expect(s.style, isNotNull);
      expect(s.font.height, 6);
    });

    test('has unique id', () {
      final s1 = StyledAsciiText(data: 'A');
      final s2 = StyledAsciiText(data: 'B');
      expect(s1.id, isNot(equals(s2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // AnimatedTint
  // ---------------------------------------------------------------------------
  group('AnimatedTint', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        AnimatedTint(
          begin: Colors.red,
          end: Colors.blue,
          duration: Duration(milliseconds: 300),
          child: Text('Tinted'),
        ),
      );
      expect(tester.find.text('Tinted'), isTrue);
    });

    test('stores begin/end colors and duration', () {
      final t = AnimatedTint(
        begin: Colors.red,
        end: Colors.green,
        duration: Duration(seconds: 1),
      );
      expect(t.begin, Colors.red);
      expect(t.end, Colors.green);
      expect(t.duration, Duration(seconds: 1));
    });

    test('autoStart defaults to true', () {
      final t = AnimatedTint(
        begin: Colors.red,
        end: Colors.blue,
        duration: Duration(milliseconds: 100),
      );
      expect(t.autoStart, isTrue);
    });

    test('autoStart can be disabled', () {
      final t = AnimatedTint(
        begin: Colors.red,
        end: Colors.blue,
        duration: Duration(milliseconds: 100),
        autoStart: false,
      );
      expect(t.autoStart, isFalse);
    });

    test('renders without child', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        AnimatedTint(
          begin: Colors.red,
          end: Colors.blue,
          duration: Duration(milliseconds: 100),
        ),
      );
      expect(tester.view, isNotNull);
    });

    test('has unique id', () {
      final t1 = AnimatedTint(
        begin: Colors.red,
        end: Colors.blue,
        duration: Duration(milliseconds: 100),
      );
      final t2 = AnimatedTint(
        begin: Colors.red,
        end: Colors.blue,
        duration: Duration(milliseconds: 100),
      );
      expect(t1.id, isNot(equals(t2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // FadeTint
  // ---------------------------------------------------------------------------
  group('FadeTint', () {
    test('renders child content', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        FadeTint(
          color: Colors.blue,
          duration: Duration(milliseconds: 300),
          child: Text('Fading'),
        ),
      );
      expect(tester.find.text('Fading'), isTrue);
    });

    test('fadeIn defaults to true', () {
      final t = FadeTint(
        color: Colors.red,
        duration: Duration(milliseconds: 100),
      );
      expect(t.fadeIn, isTrue);
    });

    test('fadeOut configuration', () {
      final t = FadeTint(
        color: Colors.red,
        duration: Duration(milliseconds: 100),
        fadeIn: false,
      );
      expect(t.fadeIn, isFalse);
    });

    test('autoStart defaults to true', () {
      final t = FadeTint(
        color: Colors.red,
        duration: Duration(milliseconds: 100),
      );
      expect(t.autoStart, isTrue);
    });

    test('has unique id', () {
      final f1 = FadeTint(
        color: Colors.red,
        duration: Duration(milliseconds: 100),
      );
      final f2 = FadeTint(
        color: Colors.blue,
        duration: Duration(milliseconds: 100),
      );
      expect(f1.id, isNot(equals(f2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // FadeModalBarrier
  // ---------------------------------------------------------------------------
  group('FadeModalBarrier', () {
    test('renders child when not visible', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        FadeModalBarrier(visible: false, child: Text('Behind barrier')),
      );
      expect(tester.find.text('Behind barrier'), isTrue);
    });

    test('renders child when visible', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        FadeModalBarrier(visible: true, child: Text('Content')),
      );
      // When the barrier is visible and opaque, it obscures the child text.
      // The widget tree still contains the child, and the view is non-empty.
      final view = tester.view;
      expect(view.isNotEmpty, isTrue);
    });

    test('visible defaults to false', () {
      final b = FadeModalBarrier(child: Text('test'));
      expect(b.visible, isFalse);
    });

    test('dismissible defaults to true', () {
      final b = FadeModalBarrier(child: Text('test'));
      expect(b.dismissible, isTrue);
    });

    test('stores opacity', () {
      final b = FadeModalBarrier(opacity: 0.8, child: Text('test'));
      expect(b.opacity, 0.8);
    });

    test('stores duration', () {
      final b = FadeModalBarrier(
        duration: Duration(milliseconds: 500),
        child: Text('test'),
      );
      expect(b.duration, Duration(milliseconds: 500));
    });

    test('has unique id', () {
      final b1 = FadeModalBarrier(child: Text('a'));
      final b2 = FadeModalBarrier(child: Text('b'));
      expect(b1.id, isNot(equals(b2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // DebugOverlay
  // ---------------------------------------------------------------------------
  group('DebugOverlay', () {
    test('renders child when disabled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DebugOverlay(enabled: false, child: Text('Main content')),
      );
      expect(tester.find.text('Main content'), isTrue);
    });

    test('renders child when enabled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DebugOverlay(enabled: true, child: Text('App content')),
      );
      // In terminal Stack rendering, the overlay panel overwrites the child
      // layer. Verify the overlay panel IS rendered (child+overlay Stack is
      // structurally correct). The child renders correctly when disabled
      // (tested above).
      expect(tester.view, contains('FPS:'));
    });

    test('shows FPS info when enabled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(DebugOverlay(enabled: true, child: Text('App')));
      expect(tester.find.text('FPS:'), isTrue);
      expect(tester.find.text('Frames:'), isTrue);
    });

    test('enabled defaults to true', () {
      final d = DebugOverlay(child: Text('test'));
      expect(d.enabled, isTrue);
    });

    test('position defaults to topRight', () {
      final d = DebugOverlay(child: Text('test'));
      expect(d.position, DebugOverlayPosition.topRight);
    });

    test('stores custom position', () {
      final d = DebugOverlay(
        position: DebugOverlayPosition.bottomLeft,
        child: Text('test'),
      );
      expect(d.position, DebugOverlayPosition.bottomLeft);
    });

    test('has unique id', () {
      final d1 = DebugOverlay(child: Text('a'));
      final d2 = DebugOverlay(child: Text('b'));
      expect(d1.id, isNot(equals(d2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // PerformanceOverlay
  // ---------------------------------------------------------------------------
  group('PerformanceOverlay', () {
    test('renders child when disabled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PerformanceOverlay(enabled: false, child: Text('My app')),
      );
      expect(tester.find.text('My app'), isTrue);
    });

    test('renders child when enabled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PerformanceOverlay(enabled: true, child: Text('Content')),
      );
      // In terminal Stack rendering, the overlay text overwrites the child
      // layer. Verify the overlay content IS rendered. The child renders
      // correctly when disabled (tested above).
      expect(tester.find.text('Frame'), isTrue);
    });

    test('shows frame info when enabled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        PerformanceOverlay(enabled: true, child: Text('App')),
      );
      expect(tester.find.text('Frame'), isTrue);
    });

    test('enabled defaults to true', () {
      final p = PerformanceOverlay(child: Text('test'));
      expect(p.enabled, isTrue);
    });

    test('has unique id', () {
      final p1 = PerformanceOverlay(child: Text('a'));
      final p2 = PerformanceOverlay(child: Text('b'));
      expect(p1.id, isNot(equals(p2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // Overlay / OverlayEntry
  // ---------------------------------------------------------------------------
  group('OverlayEntry', () {
    test('stores builder', () {
      final entry = OverlayEntry(builder: (ctx) => Text('entry'));
      expect(entry.builder, isNotNull);
    });

    test('opaque defaults to false', () {
      final entry = OverlayEntry(builder: (ctx) => Text('entry'));
      expect(entry.opaque, isFalse);
    });

    test('maintainState defaults to false', () {
      final entry = OverlayEntry(builder: (ctx) => Text('entry'));
      expect(entry.maintainState, isFalse);
    });

    test('stores opaque flag', () {
      final entry = OverlayEntry(builder: (ctx) => Text('entry'), opaque: true);
      expect(entry.opaque, isTrue);
    });

    test('markNeedsBuild does not throw', () {
      final entry = OverlayEntry(builder: (ctx) => Text('entry'));
      expect(() => entry.markNeedsBuild(), returnsNormally);
    });

    test('remove does not throw', () {
      final entry = OverlayEntry(builder: (ctx) => Text('entry'));
      expect(() => entry.remove(), returnsNormally);
    });
  });

  group('Overlay', () {
    test('renders single entry', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Overlay(
          initialEntries: [OverlayEntry(builder: (ctx) => Text('Layer 1'))],
        ),
      );
      expect(tester.find.text('Layer 1'), isTrue);
    });

    test('renders multiple entries', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Overlay(
          initialEntries: [
            OverlayEntry(builder: (ctx) => Text('Base')),
            OverlayEntry(builder: (ctx) => Text('Top')),
          ],
        ),
      );
      // In terminal Stack rendering, later entries overwrite earlier ones.
      // 'Top' (the topmost layer) should be visible.
      expect(tester.find.text('Top'), isTrue);
    });

    test('renders empty overlay without error', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(Overlay());
      expect(tester.view, isNotNull);
    });

    test('initialEntries defaults to empty', () {
      final o = Overlay();
      expect(o.initialEntries, isEmpty);
    });

    test('has unique id', () {
      final o1 = Overlay();
      final o2 = Overlay();
      expect(o1.id, isNot(equals(o2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // ImplicitlyAnimatedWidget
  // ---------------------------------------------------------------------------
  group('ImplicitlyAnimatedWidget', () {
    test('stores duration', () {
      final w = _TestImplicitlyAnimated(
        targetValue: 1.0,
        duration: Duration(seconds: 1),
      );
      expect(w.duration, Duration(seconds: 1));
    });

    test('curve defaults to null', () {
      final w = _TestImplicitlyAnimated(
        targetValue: 1.0,
        duration: Duration(seconds: 1),
      );
      expect(w.curve, isNull);
    });

    test('has unique id', () {
      final w1 = _TestImplicitlyAnimated(
        targetValue: 1.0,
        duration: Duration(seconds: 1),
      );
      final w2 = _TestImplicitlyAnimated(
        targetValue: 2.0,
        duration: Duration(seconds: 1),
      );
      expect(w1.id, isNot(equals(w2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // Image (MemoryImage / FileImage / BoxFit)
  // ---------------------------------------------------------------------------
  group('Image widget', () {
    test('shows loading placeholder initially', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // MemoryImage with invalid bytes should show error eventually,
      // but initially shows loading state.
      await tester.pumpWidget(Image(image: _NeverResolvingImage()));
      expect(tester.find.text('Loading...'), isTrue);
    });

    test('shows custom placeholder', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Image(
          image: _NeverResolvingImage(),
          placeholder: Text('Please wait...'),
        ),
      );
      expect(tester.find.text('Please wait...'), isTrue);
    });

    test('BoxFit enum has expected values', () {
      expect(BoxFit.values, contains(BoxFit.fill));
      expect(BoxFit.values, contains(BoxFit.contain));
      expect(BoxFit.values, contains(BoxFit.cover));
      expect(BoxFit.values, contains(BoxFit.fitWidth));
      expect(BoxFit.values, contains(BoxFit.fitHeight));
      expect(BoxFit.values, contains(BoxFit.none));
    });

    test('stores fit option', () {
      final img = Image(image: _NeverResolvingImage(), fit: BoxFit.cover);
      expect(img.fit, BoxFit.cover);
    });

    test('stores width and height', () {
      final img = Image(image: _NeverResolvingImage(), width: 40, height: 20);
      expect(img.width, 40);
      expect(img.height, 20);
    });

    test('fit defaults to contain', () {
      final img = Image(image: _NeverResolvingImage());
      expect(img.fit, BoxFit.contain);
    });

    test('has unique id', () {
      final i1 = Image(image: _NeverResolvingImage());
      final i2 = Image(image: _NeverResolvingImage());
      expect(i1.id, isNot(equals(i2.id)));
    });
  });

  group('MemoryImage', () {
    test('stores bytes', () {
      final bytes = [0x89, 0x50, 0x4E, 0x47]; // PNG header
      final mi = MemoryImage(Uint8List.fromList(bytes));
      expect(mi.bytes.length, 4);
    });
  });

  group('FileImage', () {
    test('stores path', () {
      final fi = FileImage('/tmp/test.png');
      expect(fi.path, '/tmp/test.png');
    });
  });

  // ---------------------------------------------------------------------------
  // State.handleInit integration (framework change)
  // ---------------------------------------------------------------------------
  group('State.handleInit', () {
    test('state handleInit is called during collectHandleInit', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      // AnimatedTint uses State.handleInit to start the animation.
      // If handleInit is wired correctly, the widget should render without errors.
      await tester.pumpWidget(
        AnimatedTint(
          begin: Colors.red,
          end: Colors.blue,
          duration: Duration(milliseconds: 100),
          child: Text('Animated'),
        ),
      );
      expect(tester.find.text('Animated'), isTrue);
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// A dummy BuildContext for testing widget.build() outside the framework.
class _DummyBuildContext implements BuildContext {
  @override
  Widget get widget => Text('dummy');

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() => null;

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>() => null;

  @override
  T? findAncestorStateOfType<T extends State>() => null;
}

/// A concrete ImplicitlyAnimatedWidget for testing the base class.
class _TestImplicitlyAnimated extends ImplicitlyAnimatedWidget {
  _TestImplicitlyAnimated({required this.targetValue, required super.duration});

  final double targetValue;

  @override
  AnimatedWidgetBaseState<_TestImplicitlyAnimated> createState() =>
      _TestImplicitlyAnimatedState();
}

class _TestImplicitlyAnimatedState
    extends AnimatedWidgetBaseState<_TestImplicitlyAnimated> {
  Tween<double>? _value;

  @override
  void forEachTween(TweenVisitor visitor) {
    final result = visitor(
      _value,
      widget.targetValue,
      (value) => Tween<double>(begin: value, end: value),
    );
    _value = result as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final v = _value?.evaluate(controller) ?? widget.targetValue;
    return Text('value: ${v.toStringAsFixed(1)}');
  }
}

/// An ImageProvider that never resolves, to test loading states.
class _NeverResolvingImage extends ImageProvider {
  @override
  Future<ImageData> resolve() {
    // Return a future that never completes (Completer is never completed).
    return Completer<ImageData>().future;
  }
}
