import 'package:artisanal/src/tui/bubbles/viewport.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/terminal/ansi.dart';
import 'package:test/test.dart';

void main() {
  group('ViewportModel', () {
    group('New', () {
      test('creates with default values', () {
        final viewport = ViewportModel();
        expect(viewport.width, 80);
        expect(viewport.height, 24);
        expect(viewport.yOffset, 0);
        expect(viewport.xOffset, 0);
      });

      test('creates with custom dimensions', () {
        final viewport = ViewportModel(width: 120, height: 30);
        expect(viewport.width, 120);
        expect(viewport.height, 30);
      });

      test('creates with mouse settings', () {
        final viewport = ViewportModel(
          mouseWheelEnabled: false,
          mouseWheelDelta: 5,
        );
        expect(viewport.mouseWheelEnabled, isFalse);
        expect(viewport.mouseWheelDelta, 5);
      });
    });

    group('SetContent', () {
      test('sets content lines', () {
        final viewport = ViewportModel(height: 5);
        final updated = viewport.setContent('line1\nline2\nline3');
        expect(updated.lines, ['line1', 'line2', 'line3']);
      });

      test('normalizes CRLF to LF', () {
        final viewport = ViewportModel(height: 5);
        final updated = viewport.setContent('line1\r\nline2\r\nline3');
        expect(updated.lines, ['line1', 'line2', 'line3']);
      });

      test('handles empty content', () {
        final viewport = ViewportModel();
        final updated = viewport.setContent('');
        expect(updated.lines, ['']);
      });

      test('adjusts offset when content becomes shorter', () {
        final viewport = ViewportModel(height: 3, yOffset: 10);
        final updated = viewport.setContent('line1\nline2');
        expect(updated.yOffset, lessThanOrEqualTo(updated.lines.length));
      });
    });

    test('is a ViewComponent and updates via base type', () {
      final viewport = ViewportModel(height: 3).setContent('a\nb\nc\nd');
      ViewComponent model = viewport;
      final (updated, _) = model.update(const WindowSizeMsg(80, 24));
      expect(updated, isA<ViewportModel>());
    });

    group('SetYOffset', () {
      test('sets Y offset', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4\nline5\nline6');
        final updated = viewport.setYOffset(2);
        expect(updated.yOffset, 2);
      });

      test('clamps Y offset to max', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4');
        final updated = viewport.setYOffset(100);
        expect(updated.yOffset, 1); // max is lines - height = 4 - 3 = 1
      });

      test('clamps Y offset to 0', () {
        final viewport = ViewportModel(height: 3).setContent('line1\nline2');
        final updated = viewport.setYOffset(-5);
        expect(updated.yOffset, 0);
      });
    });

    group('SetXOffset', () {
      test('sets X offset', () {
        final viewport = ViewportModel(
          width: 10,
        ).setContent('this is a very long line that exceeds width');
        final updated = viewport.setXOffset(5);
        expect(updated.xOffset, 5);
      });
    });

    group('Parity Features', () {
      test('softWrap wraps long lines', () {
        final viewport = ViewportModel(
          width: 10,
          softWrap: true,
        ).setContent('this is a very long line');
        final view = viewport.view();
        // With width 10, 'this is a very long line' should wrap into multiple lines
        expect(view.split('\n').length, greaterThan(1));
      });

      test('showLineNumbers adds gutter', () {
        final viewport = ViewportModel(
          width: 20,
          showLineNumbers: true,
        ).setContent('line1\nline2');
        final view = viewport.view();
        expect(view, contains('1 '));
        expect(view, contains('2 '));
      });

      test('highlights apply styles', () {
        final viewport =
            ViewportModel(
              width: 20,
              highlightStyle: Style().foreground(const AnsiColor(1)),
            ).setContent('test line').setHighlights([
              [0, 4],
            ]);
        final view = viewport.view();
        expect(view, contains('\x1b[38;5;1mtest\x1b[m'));
      });

      test('leftGutterFunc customizes gutter', () {
        final viewport = ViewportModel(
          width: 20,
          leftGutterFunc: (i) => '[${i.index + 1}] ',
        ).setContent('line1');
        final view = viewport.view();
        expect(view, contains('[1] '));
      });

      test('view terminates ANSI when wrapping + height truncates', () {
        // Regression: when a styled segment spans wrapped lines, height
        // truncation can drop the trailing reset; the viewport output must not
        // leak styles into subsequent renders.
        var viewport = ViewportModel(
          width: 10,
          height: 1,
        ).setContent('this is a very long selected line that will wrap');
        // Select the entire first (and only) content line.
        viewport = viewport.copyWith(
          selectionStart: (0, 0),
          selectionEnd: (Style.visibleLength(viewport.lines.first), 0),
        );

        final view = viewport.view();
        expect(view, contains('\x1b[')); // selection styling emits SGR codes
        expect(view, endsWith(Ansi.reset));
      });
    });

    group('HorizontalStep', () {
      test('disables horizontal scrolling when 0', () {
        final viewport = ViewportModel(horizontalStep: 0);
        expect(viewport.horizontalStep, 0);
      });

      test('enables horizontal scrolling when positive', () {
        final viewport = ViewportModel(horizontalStep: 4);
        expect(viewport.horizontalStep, 4);
      });
    });

    group('ScrollDown', () {
      test('scrolls down by n lines', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4\nline5\nline6');
        final updated = viewport.scrollDown(2);
        expect(updated.yOffset, 2);
      });

      test('does not scroll past bottom', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4');
        final updated = viewport.scrollDown(100);
        expect(updated.yOffset, 1); // max offset
      });

      test('does nothing when already at bottom', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4').setYOffset(1);
        expect(viewport.atBottom, isTrue);
        final updated = viewport.scrollDown(1);
        expect(updated, viewport);
      });

      test('does nothing for 0 lines', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4');
        final updated = viewport.scrollDown(0);
        expect(updated, viewport);
      });
    });

    group('ScrollUp', () {
      test('scrolls up by n lines', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4\nline5\nline6').setYOffset(3);
        final updated = viewport.scrollUp(2);
        expect(updated.yOffset, 1);
      });

      test('does not scroll past top', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4').setYOffset(1);
        final updated = viewport.scrollUp(100);
        expect(updated.yOffset, 0);
      });

      test('does nothing when already at top', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4');
        expect(viewport.atTop, isTrue);
        final updated = viewport.scrollUp(1);
        expect(updated, viewport);
      });
    });

    group('ScrollLeft', () {
      test('scrolls left by n columns', () {
        final viewport = ViewportModel(
          width: 10,
          horizontalStep: 4,
        ).setContent('this is a very long line').setXOffset(10);
        final updated = viewport.scrollLeft(5);
        expect(updated.xOffset, 5);
      });
    });

    group('ScrollRight', () {
      test('scrolls right by n columns', () {
        final viewport = ViewportModel(
          width: 10,
          horizontalStep: 4,
        ).setContent('this is a very long line');
        final updated = viewport.scrollRight(5);
        expect(updated.xOffset, 5);
      });
    });

    group('PageDown', () {
      test('scrolls down by page height', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        final updated = viewport.pageDown();
        expect(updated.yOffset, 5);
      });

      test('does nothing when at bottom', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent('line1\nline2\nline3');
        expect(viewport.atBottom, isTrue);
        final updated = viewport.pageDown();
        expect(updated, viewport);
      });
    });

    group('PageUp', () {
      test('scrolls up by page height', () {
        final viewport = ViewportModel(height: 5)
            .setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'))
            .setYOffset(10);
        final updated = viewport.pageUp();
        expect(updated.yOffset, 5);
      });

      test('does nothing when at top', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        expect(viewport.atTop, isTrue);
        final updated = viewport.pageUp();
        expect(updated, viewport);
      });
    });

    group('HalfPageDown', () {
      test('scrolls down by half page height', () {
        final viewport = ViewportModel(
          height: 10,
        ).setContent(List.generate(30, (i) => 'line${i + 1}').join('\n'));
        final updated = viewport.halfPageDown();
        expect(updated.yOffset, 5);
      });
    });

    group('HalfPageUp', () {
      test('scrolls up by half page height', () {
        final viewport = ViewportModel(height: 10)
            .setContent(List.generate(30, (i) => 'line${i + 1}').join('\n'))
            .setYOffset(10);
        final updated = viewport.halfPageUp();
        expect(updated.yOffset, 5);
      });
    });

    group('GotoTop', () {
      test('goes to top', () {
        final viewport = ViewportModel(height: 5)
            .setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'))
            .setYOffset(10);
        final updated = viewport.gotoTop();
        expect(updated.yOffset, 0);
      });

      test('does nothing when already at top', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        expect(viewport.atTop, isTrue);
        final updated = viewport.gotoTop();
        expect(updated, viewport);
      });
    });

    group('GotoBottom', () {
      test('goes to bottom', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        final updated = viewport.gotoBottom();
        expect(updated.yOffset, 15); // 20 lines - 5 height = 15
      });
    });

    group('Highlights', () {
      test('highlightNext scrolls to the next highlight', () {
        final content = '${'Line 1\n' * 10}Target\n${'Line 2\n' * 10}';
        final style = Style().bold();

        // Find the index of "Target" in the full content.
        final targetIndex = content.indexOf('Target');

        var viewport =
            ViewportModel(
              width: 20,
              height: 5,
              highlightStyle: style,
            ).setContent(content).setHighlights([
              [targetIndex, targetIndex + 6],
            ]);

        // setHighlights() ensures the current highlight is visible.
        expect(viewport.yOffset, anyOf(10, 11));

        viewport = viewport.highlightNext();

        // With only one highlight, highlightNext keeps it selected.
        expect(viewport.yOffset, anyOf(10, 11));
      });

      test('highlightPrev scrolls to the previous highlight', () {
        final content = 'Target 1\n${'Line\n' * 10}Target 2\n';
        final style = Style().bold();

        final t1Idx = content.indexOf('Target 1');
        final t2Idx = content.indexOf('Target 2');

        var viewport =
            ViewportModel(width: 20, height: 5, highlightStyle: style)
                .setContent(content)
                .setHighlights([
                  [t1Idx, t1Idx + 8],
                  [t2Idx, t2Idx + 8],
                ])
                .setYOffset(10);

        final startYOffset = viewport.yOffset; // clamped to maxYOffset
        viewport = viewport.highlightPrev();

        // Starting on the first highlight, highlightPrev wraps to the last
        // highlight ("Target 2"). It's already visible at the bottom, so the
        // yOffset should remain unchanged.
        expect(viewport.yOffset, startYOffset);
      });
    });

    group('AtTop', () {
      test('returns true when at top', () {
        final viewport = ViewportModel(height: 5).setContent('line1\nline2');
        expect(viewport.atTop, isTrue);
      });

      test('returns false when not at top', () {
        final viewport = ViewportModel(height: 3)
            .setContent(List.generate(10, (i) => 'line${i + 1}').join('\n'))
            .setYOffset(2);
        expect(viewport.atTop, isFalse);
      });
    });

    group('AtBottom', () {
      test('returns true when at bottom', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent('line1\nline2\nline3\nline4').setYOffset(1);
        expect(viewport.atBottom, isTrue);
      });

      test('returns false when not at bottom', () {
        final viewport = ViewportModel(
          height: 3,
        ).setContent(List.generate(10, (i) => 'line${i + 1}').join('\n'));
        expect(viewport.atBottom, isFalse);
      });
    });

    group('ScrollPercent', () {
      test('returns 0 at top', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        expect(viewport.scrollPercent, 0.0);
      });

      test('returns 1 at bottom', () {
        final viewport = ViewportModel(height: 5)
            .setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'))
            .gotoBottom();
        expect(viewport.scrollPercent, 1.0);
      });

      test('returns 1 when content fits in viewport', () {
        final viewport = ViewportModel(
          height: 10,
        ).setContent('line1\nline2\nline3');
        expect(viewport.scrollPercent, 1.0);
      });
    });

    group('VisibleLineCount', () {
      test('returns visible line count', () {
        final viewport = ViewportModel(
          height: 5,
        ).setContent(List.generate(20, (i) => 'line${i + 1}').join('\n'));
        expect(viewport.visibleLineCount, 5);
      });

      test('returns line count when content is shorter than viewport', () {
        final viewport = ViewportModel(
          height: 10,
        ).setContent('line1\nline2\nline3');
        expect(viewport.visibleLineCount, 3);
      });
    });

    group('TotalLineCount', () {
      test('returns total line count', () {
        final viewport = ViewportModel().setContent(
          List.generate(20, (i) => 'line${i + 1}').join('\n'),
        );
        expect(viewport.totalLineCount, 20);
      });
    });

    group('View', () {
      test('returns visible lines', () {
        final viewport = ViewportModel(
          width: 20,
          height: 3,
        ).setContent('line1\nline2\nline3\nline4\nline5');
        final view = viewport.view();
        expect(view, contains('line1'));
        expect(view, contains('line2'));
        expect(view, contains('line3'));
        expect(view, isNot(contains('line4')));
      });

      test('softWrap wraps long lines', () {
        final content =
            'This is a very long line that should be wrapped by the viewport.';
        final viewport = ViewportModel(
          width: 20,
          height: 5,
          softWrap: true,
        ).setContent(content);

        final view = viewport.view();
        final lines = view.split('\n');

        expect(lines[0].trim(), 'This is a very long');
        expect(lines[1].trim(), 'line that should be');
        // Note: softWrap is fixed-width segmentation (not word wrap).
        expect(lines[2].trim(), 'wrapped by the viewp');
        expect(lines[3].trim(), 'ort.');
      });

      test('softWrap disables horizontal scrolling', () {
        final viewport = ViewportModel(
          width: 10,
          height: 2,
          softWrap: true,
        ).setContent('0123456789abcdef');

        final scrolled = viewport.setXOffset(5).scrollRight(5);
        expect(scrolled.xOffset, 0);
      });

      test('ensureVisible maps to the correct wrapped segment', () {
        // maxWidth = 10, highlight at colstart ~ 25 should land on segment 2.
        final viewport = ViewportModel(
          width: 10,
          height: 2,
          softWrap: true,
        ).setContent('0123456789abcdefghijABCDEFGHIJ');

        final updated = viewport.ensureVisible(0, 25, 26);
        // height=2 means maxYOffset=1, which still makes segment 2 visible.
        expect(updated.yOffset, 1);
        expect(updated.xOffset, 0);
      });

      test('gotoBottom uses virtual line count when softWrap is enabled', () {
        // 25 chars at width 10 => 3 virtual lines. height=2 => maxYOffset=1.
        final viewport = ViewportModel(
          width: 10,
          height: 2,
          softWrap: true,
        ).setContent('0123456789abcdefghijABCDE');

        expect(viewport.gotoBottom().yOffset, 1);
      });

      test(
        'setContent clamps yOffset using virtual maxYOffset under softWrap',
        () {
          final viewport = ViewportModel(
            width: 10,
            height: 2,
            softWrap: true,
          ).setContent('0123456789abcdefghijABCDE').setYOffset(2);

          // Now shrink content so there are no extra virtual lines.
          final updated = viewport.setContent('short');
          expect(updated.yOffset, 0);
        },
      );

      test('leftGutterFunc receives soft=true for wrapped continuations', () {
        final viewport = ViewportModel(
          width: 8,
          height: 3,
          softWrap: true,
          leftGutterFunc: (ctx) => ctx.soft ? '> ' : '| ',
        ).setContent('0123456789ABCDEF');

        final lines = viewport.view().split('\n');
        expect(lines[0], startsWith('| '));
        expect(lines[1], startsWith('> '));
      });

      test('gutter is preserved during horizontal scrolling', () {
        final viewport = ViewportModel(
          width: 10,
          height: 1,
          softWrap: false,
          leftGutterFunc: (_) => '| ',
        ).setContent('0123456789abcdef').setXOffset(5);

        final view = viewport.view();
        expect(view, startsWith('| '));
        expect(Style.stripAnsi(view), contains('56789'));
      });

      test('leftGutterFunc provides dynamic gutters', () {
        final content = 'Line 1\nLine 2\nLine 3';
        final viewport = ViewportModel(
          width: 20,
          height: 5,
          leftGutterFunc: (ctx) => '${ctx.index + 1} | ',
        ).setContent(content);

        final view = viewport.view();
        final lines = view.split('\n');

        expect(lines[0], startsWith('1 | Line 1'));
        expect(lines[1], startsWith('2 | Line 2'));
        expect(lines[2], startsWith('3 | Line 3'));
      });

      test('highlights apply styles to content', () {
        final content = 'Hello World';
        final style = Style().foreground(const BasicColor('#ff0000'));
        final viewport =
            ViewportModel(
              width: 20,
              height: 5,
              highlightStyle: style,
            ).setContent(content).setHighlights([
              [6, 11],
            ]);

        final view = viewport.view();
        // "World" should be styled
        expect(view, contains(style.render('World')));
      });

      test('highlights handle ANSI prefixes without shifting columns', () {
        final content = '${Ansi.csi}31mHello${Ansi.csi}0m World';
        final start = content.indexOf('World');
        final end = start + 'World'.length;

        final style = Style()
            .background(const AnsiColor(7))
            .foreground(const AnsiColor(0));
        final viewport =
            ViewportModel(
              width: 80,
              height: 3,
              highlightStyle: style,
            ).setContent(content).setHighlights([
              [start, end],
            ]);

        final view = viewport.view();
        expect(view, contains(style.render('World')));
      });

      test(
        'highlights handle wide graphemes (emoji) with correct cell widths',
        () {
          final content = 'a🙂b';
          final start = content.indexOf('🙂');
          final end = start + '🙂'.length;

          final style = Style()
              .background(const AnsiColor(7))
              .foreground(const AnsiColor(0));
          final viewport =
              ViewportModel(
                width: 10,
                height: 2,
                highlightStyle: style,
              ).setContent(content).setHighlights([
                [start, end],
              ]);

          final view = viewport.view();
          expect(view, contains(style.render('🙂')));
        },
      );

      test('highlights spanning newlines apply on each line', () {
        final content = 'ab\ncd';
        final start = content.indexOf('b');
        final end = content.indexOf('d') + 1;

        final style = Style()
            .background(const AnsiColor(7))
            .foreground(const AnsiColor(0));
        final viewport =
            ViewportModel(
              width: 10,
              height: 3,
              highlightStyle: style,
            ).setContent(content).setHighlights([
              [start, end],
            ]);

        final view = viewport.view();
        expect(view, contains('a${style.render('b')}'));
        expect(view, contains(style.render('cd')));
      });

      test('pads lines to width', () {
        final viewport = ViewportModel(
          width: 10,
          height: 2,
        ).setContent('short\nline');
        final lines = viewport.view().split('\n');
        expect(lines[0].length, 10);
        expect(lines[1].length, 10);
      });

      test('pads height with empty lines', () {
        final viewport = ViewportModel(
          width: 5,
          height: 5,
        ).setContent('line1\nline2');
        final lines = viewport.view().split('\n');
        expect(lines.length, 5);
      });

      test('horizontal scrolling is grapheme-aware (combining marks)', () {
        final viewport = ViewportModel(
          width: 1,
          height: 1,
        ).setContent('e\u0301x');

        final scrolled = viewport.setXOffset(1);
        expect(Style.stripAnsi(scrolled.view()), equals('x'));
      });
    });

    group('CopyWith', () {
      test('creates copy with changed values', () {
        final viewport = ViewportModel(width: 80, height: 24);
        final copy = viewport.copyWith(width: 120);
        expect(copy.width, 120);
        expect(copy.height, 24);
        expect(viewport.width, 80);
      });

      test('preserves content on copy', () {
        final viewport = ViewportModel().setContent('hello\nworld');
        final copy = viewport.copyWith(height: 5);
        expect(copy.lines, ['hello', 'world']);
      });
    });

    group('Init', () {
      test('returns null', () {
        final viewport = ViewportModel();
        expect(viewport.init(), isNull);
      });
    });

    group('Mouse Wheel', () {
      test('scrolls when action is MouseAction.wheel (UV adapter)', () {
        final viewport = ViewportModel(height: 2).setContent('a\nb\nc');

        final (v1, _) = viewport.update(
          const MouseMsg(
            action: MouseAction.wheel,
            button: MouseButton.wheelDown,
            x: 0,
            y: 0,
          ),
        );

        expect(v1.yOffset, 1);
      });
    });

    group('Selection', () {
      test('selects text via mouse drag', () {
        var viewport = ViewportModel(
          width: 20,
          height: 5,
        ).setContent('Hello World\nLine 2');

        // Press at (0, 0)
        var (v1, _) = viewport.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 0,
            y: 0,
          ),
        );

        // Drag to (5, 0)
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 5,
            y: 0,
          ),
        );

        expect(v2.getSelectedText(), equals('Hello'));
      });

      test('renders selection with highlight style', () {
        var viewport = ViewportModel(
          width: 20,
          height: 5,
        ).setContent('Hello World');

        // Select "Hello".
        final (v1, _) = viewport.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 0,
            y: 0,
          ),
        );
        final (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 5,
            y: 0,
          ),
        );

        final view = v2.view();
        final selectionStyle = Style()
            .background(const AnsiColor(7))
            .foreground(const AnsiColor(0));
        expect(view, contains(selectionStyle.render('Hello')));
      });

      test('double click selects word', () {
        var viewport = ViewportModel(
          width: 20,
          height: 5,
        ).setContent('Hello World\nLine 2');

        // First click at (2, 0) - inside "Hello"
        var (v1, _) = viewport.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 2,
            y: 0,
          ),
        );

        // Second click at same position immediately
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 2,
            y: 0,
          ),
        );

        expect(v2.getSelectedText(), equals('Hello'));
      });

      test('double click selects whitespace', () {
        var viewport = ViewportModel(
          width: 20,
          height: 5,
        ).setContent('Hello   World');

        // Click in the middle of spaces
        var (v1, _) = viewport.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 6,
            y: 0,
          ),
        );

        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 6,
            y: 0,
          ),
        );

        expect(v2.getSelectedText(), equals('   '));
      });

      test('click outside bounds clears selection', () {
        var viewport = ViewportModel(
          width: 20,
          height: 5,
        ).setContent('Hello World');
        // Select something
        var (v1, _) = viewport.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 0,
            y: 0,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 5,
            y: 0,
          ),
        );
        expect(v2.getSelectedText(), equals('Hello'));

        // Click outside (y = -1)
        var (v3, _) = v2.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 0,
            y: -1,
          ),
        );
        expect(v3.getSelectedText(), equals(''));
      });
    });
  });

  group('ViewportKeyMap', () {
    test('creates with default bindings', () {
      final keyMap = ViewportKeyMap();
      expect(keyMap.up.keys, isNotEmpty);
      expect(keyMap.down.keys, isNotEmpty);
      expect(keyMap.pageUp.keys, isNotEmpty);
      expect(keyMap.pageDown.keys, isNotEmpty);
    });

    test('shortHelp returns navigation bindings', () {
      final keyMap = ViewportKeyMap();
      final help = keyMap.shortHelp();
      expect(help.length, greaterThanOrEqualTo(4));
    });

    test('fullHelp returns grouped bindings', () {
      final keyMap = ViewportKeyMap();
      final help = keyMap.fullHelp();
      expect(help, isNotEmpty);
    });
  });
}
