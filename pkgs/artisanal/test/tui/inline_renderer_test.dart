import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/src/terminal/terminal_base.dart';
import 'package:artisanal/src/tui/renderer.dart';
import 'package:artisanal/src/tui/program.dart' show ScreenMode, UiAnchor;
import 'package:test/test.dart';

import 'inline_terminal_harness.dart';

void main() {
  group('UltravioletTuiRenderer inline mode', () {
    UltravioletTuiRenderer buildInlineRenderer(
      StringTerminal terminal, {
      int inlineHeight = 4,
      UiAnchor uiAnchor = UiAnchor.bottom,
      bool hideCursor = true,
    }) {
      return UltravioletTuiRenderer(
        terminal: terminal,
        options: TuiRendererOptions(
          fps: 100000,
          altScreen: false,
          hideCursor: hideCursor,
          screenMode: ScreenMode.inline,
          inlineHeight: inlineHeight,
          uiAnchor: uiAnchor,
        ),
      );
    }

    test('does not enter alt-screen in inline mode', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal);
      renderer.initialize();
      renderer.render('test');

      // Should not contain alt-screen enter sequence
      expect(terminal.output, isNot(contains(Ansi.altScreenEnter)));
    });

    test('does not emit full-screen clear in inline mode', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('inline');

      expect(terminal.output, isNot(contains(Ansi.clearScreen)));
    });

    test('does not scroll viewport on first frame', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('inline');

      expect(terminal.output, isNot(contains(Ansi.scrollUpBy(4))));
      expect(terminal.output, isNot(contains(Ansi.scrollDownBy(4))));
    });

    test('renders content within the UI region (bottom-anchored)', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 6);

      renderer.render('Hello inline');

      // For bottom-anchored height=6 on 24-row terminal:
      // UI starts at row 24 - 6 + 1 = 19.
      // The CUP in the UV output should be offset to row 19+.
      // Expect cursorTo(19,1) for clearing the first UI row.
      expect(terminal.output, contains(Ansi.cursorTo(19, 1)));
    });

    test('renders content within the UI region (top-anchored)', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(
        terminal,
        inlineHeight: 4,
        uiAnchor: UiAnchor.top,
      );

      renderer.render('Hello top');

      // Top-anchored: UI starts at row 1, offset = 0.
      // Content CUP should start at row 1.
      expect(terminal.output, contains(Ansi.cursorTo(1, 1)));
    });

    test('clears UI region rows before writing content', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 3);

      terminal.clear();
      renderer.render('line1\nline2\nline3');

      // Should clear lines at rows 22, 23, 24 (bottom 3 rows)
      expect(terminal.output, contains(Ansi.cursorTo(22, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(23, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(24, 1)));
      expect(terminal.output, contains(Ansi.clearLine));
    });

    test('offsets CUP rows in UV output', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('test');

      // Bottom-anchored, height=4: uiStartRow = 24 - 4 + 1 = 21
      // UV output has CUP at row 1 -> should become row 21
      // The UV renderer emits cursorTo(1,1) for first line,
      // which should be offset to cursorTo(21, 1).
      final output = terminal.output;

      // Should NOT contain cursorTo(1,1) from the UV renderer (it was offset)
      // But the clear loop uses cursorTo(21,1) which is the same sequence.
      // Instead, verify the content appears after the UI region positioning.
      expect(output, contains(Ansi.cursorTo(21, 1)));
    });

    test('does not double-offset home cursor sequence', () {
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 10);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 3);

      renderer.render(
        'Inline Status Bar\nRUNNING  Events: 0\nSpace toggle  q quit',
      );

      // Bottom-anchored 10-row terminal with 3-row UI starts at row 8.
      expect(terminal.output, contains(Ansi.cursorTo(8, 1)));
      expect(terminal.output, isNot(contains(Ansi.cursorTo(15, 1))));
    });

    test('uses synchronized update markers', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal);

      renderer.render('content');

      expect(terminal.output, contains(Ansi.beginSynchronizedUpdate));
      expect(terminal.output, contains(Ansi.endSynchronizedUpdate));
      expect(terminal.output, contains('\x1b[?7l'));
      expect(terminal.output, contains('\x1b[?7h'));
    });

    test('prints bottom inline lines through a bounded scroll region', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('dashboard');
      terminal.clear();

      renderer.printLine('first log line');

      // Bottom-anchored height=4 leaves rows 1..20 for logs. Every log insert
      // must use that stable region so the first line participates in the same
      // scroll flow as later lines.
      expect(terminal.output, contains(Ansi.cursorSaveDec));
      expect(terminal.output, contains(Ansi.setScrollRegion(1, 20)));
      expect(terminal.output, contains(Ansi.cursorTo(20, 1)));
      expect(terminal.output, contains('\r\n'));
      expect(terminal.output, contains('first log line'));
      expect(terminal.output, contains(Ansi.resetScrollRegion));
      expect(terminal.output, contains(Ansi.cursorRestoreDec));
      expect(terminal.output, isNot(contains(Ansi.scrollUp)));
      expect(terminal.output, isNot(contains(Ansi.clearScreen)));
      expect(terminal.output, isNot(contains(Ansi.clearScreenAndScrollback)));
    });

    test('keeps a stable log scroll region across inserts', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('dashboard');
      terminal.clear();

      renderer.printLine('first');
      renderer.printLine('second');

      final output = terminal.output;
      expect(_count(output, Ansi.setScrollRegion(1, 20)), 2);
      expect(output, isNot(contains(Ansi.setScrollRegion(20, 20))));
      expect(output, isNot(contains(Ansi.setScrollRegion(19, 20))));
    });

    test('truncates bottom inline log lines before the wrap column', () {
      final terminal = StringTerminal(terminalWidth: 8, terminalHeight: 12);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 3);

      renderer.render('dashboard');
      terminal.clear();

      renderer.printLine('1234567890');

      expect(terminal.output, contains('1234567'));
      expect(terminal.output, isNot(contains('12345678')));
      expect(terminal.output, contains('\x1b[?7l'));
      expect(terminal.output, contains('\x1b[?7h'));
    });

    test('shows cursor at end of frame', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, hideCursor: false);

      renderer.render('content');

      expect(terminal.output, contains(Ansi.cursorShow));
    });

    test('dispose does not exit alt-screen', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal);
      renderer.initialize();
      renderer.render('content');

      terminal.clear();
      renderer.dispose();

      // Should NOT exit alt-screen (we never entered it)
      expect(terminal.output, isNot(contains(Ansi.altScreenExit)));
      expect(terminal.output, contains(Ansi.resetScrollRegion));
      // Should track showCursor operation
      expect(terminal.operations, contains('showCursor'));
    });

    test('dispose clears inline UI without scrolling the viewport', () {
      final terminal = StringTerminal(terminalWidth: 24, terminalHeight: 8);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 3);
      final vt = InlineVirtualTerminal(width: 24, height: 8);

      renderer.render('PIN A\nPIN B\nPIN C');
      vt.feed(terminal.output);
      terminal.clear();

      for (var i = 1; i <= 8; i++) {
        renderer.printLine('log-$i');
        vt.feed(terminal.output);
        terminal.clear();
      }

      renderer.dispose();
      final disposeOutput = terminal.output;
      vt.feed(disposeOutput);

      expect(disposeOutput, isNot(contains('\r\n')));
      expect(vt.line(6).trim(), isEmpty);
      expect(vt.line(7).trim(), isEmpty);
      expect(vt.line(8).trim(), isEmpty);
      expect(vt.scrollback.join('\n'), isNot(contains('PIN')));
    });

    test('resize forces a clean repaint in the new bottom region', () {
      final terminal = _ResizableStringTerminal(width: 40, height: 10);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('OLD A\nOLD B\nOLD C\nOLD D');
      terminal.clear();

      terminal.resize(width: 32, height: 7);
      renderer.render('NEW A\nNEW B\nNEW C\nNEW D');

      expect(terminal.output, contains(Ansi.cursorTo(4, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(5, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(6, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(7, 1)));
      expect(terminal.output, contains('NEW A'));
      expect(terminal.output, contains('NEW D'));
      expect(terminal.output, isNot(contains('OLD A')));
    });

    test('height-only resize replays visible logs above pinned UI', () {
      final terminal = _ResizableStringTerminal(width: 40, height: 10);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      const view = 'PIN A\nPIN B\nPIN C\nPIN D';
      renderer.render(view);
      terminal.clear();

      for (var i = 1; i <= 8; i++) {
        renderer.printLine('log-$i');
        terminal.clear();
      }

      terminal.resize(width: 40, height: 14);
      renderer.render(view);

      expect(terminal.output, contains(Ansi.cursorTo(11, 1)));
      expect(terminal.output, contains(Ansi.cursorTo(14, 1)));
      expect(terminal.output, contains('log-1'));
      expect(terminal.output, contains('log-8'));
      expect(terminal.output, contains('PIN A'));
      expect(terminal.output, contains('PIN D'));
    });

    test('height-only resize clears stale inline buffer cells', () {
      final terminal = _ResizableStringTerminal(width: 40, height: 10);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('LONG STATUS VALUE\nSECOND LINE');
      terminal.clear();

      terminal.resize(width: 40, height: 12);
      renderer.render('OK\nSECOND LINE');

      expect(terminal.output, contains('OK'));
      expect(terminal.output, isNot(contains('NG STATUS VALUE')));
    });

    test('diffing works across frames', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render('Hello');
      terminal.clear();

      renderer.render('World');

      // The second frame should contain the new content
      expect(terminal.output, contains('World'));
    });

    test('offsets incremental row updates inside the inline region', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

      renderer.render(
        'Inline Status Bar\nRUNNING  Events: 0\n\nSpace toggle  q quit',
      );
      terminal.clear();
      renderer.render(
        'Inline Status Bar\nRUNNING  Events: 1\n\nSpace toggle  q quit',
      );

      expect(
        terminal.output,
        anyOf(contains('\x1b[22d'), contains('\x1b[22;18H')),
      );
      expect(
        terminal.output,
        isNot(anyOf(contains('\x1b[2d'), contains('\x1b[2;18H'))),
      );
    });

    test(
      'virtual terminal keeps dashboard fixed while logs fill scrollback',
      () {
        final terminal = StringTerminal(terminalWidth: 24, terminalHeight: 8);
        final renderer = buildInlineRenderer(terminal, inlineHeight: 3);
        final vt = InlineVirtualTerminal(width: 24, height: 8);

        renderer.render('DASH A\nDASH B\nDASH C');
        vt.feed(terminal.output);
        terminal.clear();

        for (var i = 1; i <= 8; i++) {
          renderer.printLine('log-$i');
          vt.feed(terminal.output);
          terminal.clear();
        }

        expect(vt.line(6), contains('DASH A'));
        expect(vt.line(7), contains('DASH B'));
        expect(vt.line(8), contains('DASH C'));
        expect(vt.visibleLines.take(5).join('\n'), isNot(contains('DASH')));
        expect(vt.line(1), contains('log-4'));
        expect(vt.line(2), contains('log-5'));
        expect(vt.line(3), contains('log-6'));
        expect(vt.line(4), contains('log-7'));
        expect(vt.line(5), contains('log-8'));
        expect(vt.scrollback, contains('log-3'));
        expect(vt.scrollback.join('\n'), isNot(contains('DASH')));
      },
    );

    test('trace playback reproduces inline width-resize wrap corruption', () {
      final terminal = _TraceResizableStringTerminal(width: 80, height: 18);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 6);
      final playback = InlineVirtualTerminal(width: 80, height: 18);
      final trace = _InlineOutputTrace(playback);

      void drain() {
        final output = terminal.takeOutput();
        if (output.isNotEmpty) trace.write(output);
      }

      renderer.render(_wideInlineDashboard(progress: 10));
      drain();
      for (var i = 1; i <= 14; i++) {
        renderer.printLine('[${i.toString().padLeft(4, '0')}] $i build log');
        drain();
      }

      terminal.resize(width: 40, height: 18);
      trace.resize(width: 40, height: 18);
      renderer.render(_wideInlineDashboard(progress: 44));
      drain();

      for (var i = 15; i <= 20; i++) {
        renderer.printLine('[${i.toString().padLeft(4, '0')}] $i build log');
        drain();
      }
      renderer.render(_wideInlineDashboard(progress: 70));
      drain();

      final visible = playback.visibleLines;
      final inlineRows = visible.skip(12).toList(growable: false);
      final dump = visible
          .asMap()
          .entries
          .map(
            (entry) =>
                '${(entry.key + 1).toString().padLeft(2)} ${entry.value}',
          )
          .join('\n');
      printOnFailure(dump);

      expect(
        inlineRows.first.trimRight(),
        startsWith('+ flutter build dashboard '),
      );
      expect(
        inlineRows.last.trimRight(),
        startsWith('+'),
        reason:
            'The bottom border should remain in the 6-row inline viewport '
            'after resizing and streaming more logs. Playback currently shows '
            'the wide dashboard wrapping into extra rows, which is the blank '
            'column/corrupted panel seen in the terminal.\n$dump',
      );
    });

    test('trace playback fills resized log band from retained history', () {
      final terminal = _TraceResizableStringTerminal(width: 76, height: 32);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 6);
      final playback = InlineVirtualTerminal(width: 76, height: 32);
      final trace = _InlineOutputTrace(playback);

      void drain() {
        final output = terminal.takeOutput();
        if (output.isNotEmpty) trace.write(output);
      }

      renderer.render(_wideInlineDashboard(progress: 10));
      drain();
      for (var i = 1; i <= 90; i++) {
        renderer.printLine(
          '[${i.toString().padLeft(4, '0')}] retained resize log line',
        );
        drain();
      }

      terminal.resize(width: 70, height: 32);
      trace.resize(width: 70, height: 32);
      renderer.render(_wideInlineDashboard(progress: 25));
      drain();

      final visible = playback.visibleLines;
      final logBand = visible.take(26).toList(growable: false);
      final dump = visible
          .asMap()
          .entries
          .map(
            (entry) =>
                '${(entry.key + 1).toString().padLeft(2)} ${entry.value}',
          )
          .join('\n');
      printOnFailure(dump);

      expect(
        logBand.every((line) => line.trim().isNotEmpty),
        isTrue,
        reason:
            'After a resize, the visible log band should be repainted from '
            'retained history, not left blank at the top.\n$dump',
      );
      expect(logBand.first, contains('[0065]'));
      expect(logBand.last, contains('[0090]'));
    });

    test('trace playback replays resized log band before post-resize logs', () {
      final terminal = _TraceResizableStringTerminal(width: 76, height: 32);
      final renderer = buildInlineRenderer(terminal, inlineHeight: 6);
      final playback = InlineVirtualTerminal(width: 76, height: 32);
      final trace = _InlineOutputTrace(playback);

      void drain() {
        final output = terminal.takeOutput();
        if (output.isNotEmpty) trace.write(output);
      }

      renderer.render(_wideInlineDashboard(progress: 10));
      drain();
      for (var i = 1; i <= 90; i++) {
        renderer.printLine(
          '[${i.toString().padLeft(4, '0')}] pre-resize retained log',
        );
        drain();
      }

      terminal.resize(width: 70, height: 32);
      trace.resize(width: 70, height: 32);

      for (var i = 91; i <= 96; i++) {
        renderer.printLine(
          '[${i.toString().padLeft(4, '0')}] post-resize live log',
        );
        drain();
      }

      final visible = playback.visibleLines;
      final logBand = visible.take(26).toList(growable: false);
      final dump = visible
          .asMap()
          .entries
          .map(
            (entry) =>
                '${(entry.key + 1).toString().padLeft(2)} ${entry.value}',
          )
          .join('\n');
      printOnFailure(dump);

      expect(
        logBand.every((line) => line.trim().isNotEmpty),
        isTrue,
        reason:
            'Logs that arrive after resize but before the next UI render must '
            'first restore the retained log band. Otherwise the terminal keeps '
            'a blank top region until enough new logs arrive.\n$dump',
      );
      expect(logBand.first, contains('[0071]'));
      expect(logBand.last, contains('[0096]'));
    });
    // -------------------------------------------------------------------------
    // Regression tests: ESC[J (Erase Display) must never reach the terminal
    // in inline mode.  The UV renderer's erase() emits ESC[H ESC[2J to reset
    // its diff state, but in inline mode we own all clearing.  If ESC[2J
    // escapes, it wipes every row the log-replay just wrote.
    // -------------------------------------------------------------------------

    group('ESC[J suppression after resize (regression)', () {
      // Sentinel regex that matches any Erase Display variant.
      final edPattern = RegExp(r'\x1b\[\d*J');

      test('no Erase Display (ESC[J) in UV output after terminal resize', () {
        // Setup: 80×24 terminal with 6-row inline UI + enough logs to fill
        // the log band (rows 1-18).
        final terminal = _TraceResizableStringTerminal(width: 80, height: 24);
        final renderer = buildInlineRenderer(terminal, inlineHeight: 6);

        renderer.render(_wideInlineDashboard(progress: 10));
        terminal.takeOutput(); // discard first-paint
        for (var i = 1; i <= 20; i++) {
          renderer.printLine('[$i] build log line');
          terminal.takeOutput();
        }

        // Trigger a resize — this is the path that calls _renderer?.erase()
        // and previously leaked ESC[2J into the captured UV output.
        terminal.resize(width: 70, height: 24);
        renderer.render(_wideInlineDashboard(progress: 50));
        final postResizeOutput = terminal.takeOutput();

        expect(
          postResizeOutput,
          isNot(matches(edPattern)),
          reason:
              'After a terminal resize the UV erase() must not emit '
              'ESC[J into the inline output — it erases the log band.',
        );
      });

      test('no Erase Display (ESC[J) in UV output after clear()', () {
        final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
        final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

        renderer.render('initial view');
        terminal.clear();

        // clear() calls _renderer?.erase(); it must not leak ESC[J.
        renderer.clear();
        terminal.clear();

        renderer.render('post-clear view');
        final output = terminal.output;

        expect(
          output,
          isNot(matches(edPattern)),
          reason:
              'clear() must drain the erase output from _inlineCapture '
              'before the next flush so ESC[J never reaches the terminal.',
        );
      });

      test('no Erase Display (ESC[J) in UV output after invalidate()', () {
        final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
        final renderer = buildInlineRenderer(terminal, inlineHeight: 4);

        renderer.render('initial view');
        terminal.clear();

        // invalidate() calls _renderer?.erase(); it must not leak ESC[J.
        renderer.invalidate();
        renderer.render('post-invalidate view');
        final output = terminal.output;

        expect(
          output,
          isNot(matches(edPattern)),
          reason:
              'invalidate() must drain the erase output from _inlineCapture '
              'so the subsequent render does not emit ESC[J.',
        );
      });

      test(
        'virtual terminal log band is intact after resize (ESC[2J would blank it)',
        () {
          // End-to-end test: feed output through InlineVirtualTerminal, which
          // NOW implements ESC[J.  If ESC[2J leaks, the virtual terminal blanks
          // all rows — the log band assertion fails.
          final terminal = _TraceResizableStringTerminal(width: 76, height: 32);
          final renderer = buildInlineRenderer(terminal, inlineHeight: 6);
          final playback = InlineVirtualTerminal(width: 76, height: 32);

          void drain() {
            final out = terminal.takeOutput();
            if (out.isNotEmpty) playback.feed(out);
          }

          renderer.render(_wideInlineDashboard(progress: 5));
          drain();
          for (var i = 1; i <= 40; i++) {
            renderer.printLine('[${i.toString().padLeft(4, '0')}] log line $i');
            drain();
          }

          // Resize — the post-resize flush previously contained ESC[2J.
          terminal.resize(width: 68, height: 32);
          playback.resize(width: 68, height: 32);
          renderer.render(_wideInlineDashboard(progress: 30));
          drain();

          // The log band spans rows 1..(32-6)=26.  Every row must be non-empty
          // because the log replay fills them from the retained history.
          // If ESC[2J leaks, the VT blanks everything before the UI rows are
          // written, leaving most log rows empty.
          final logBand = List.generate(26, (i) => playback.line(i + 1));
          final dump = List.generate(
            32,
            (i) => '${(i + 1).toString().padLeft(2)}: ${playback.line(i + 1)}',
          ).join('\n');
          printOnFailure(dump);

          expect(
            logBand.every((l) => l.trim().isNotEmpty),
            isTrue,
            reason:
                'All 26 log-band rows must be non-empty after resize. '
                'An ESC[2J leak would blank them all before the UI is drawn.\n'
                '$dump',
          );
        },
      );
    });
  });

  group('UltravioletTuiRenderer fullscreen mode (regression)', () {
    UltravioletTuiRenderer buildFullScreenRenderer(StringTerminal terminal) {
      return UltravioletTuiRenderer(
        terminal: terminal,
        options: TuiRendererOptions(
          fps: 100000,
          altScreen: true,
          hideCursor: false,
          screenMode: ScreenMode.fullScreen,
        ),
      );
    }

    test('still enters alt-screen in fullscreen mode', () {
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = buildFullScreenRenderer(terminal);
      renderer.initialize();
      expect(terminal.operations, contains('enterAltScreen'));
    });
  });

  group('TuiRendererOptions.isInline', () {
    test('returns true for ScreenMode.inline', () {
      const options = TuiRendererOptions(screenMode: ScreenMode.inline);
      expect(options.isInline, isTrue);
    });

    test('returns true for ScreenMode.inlineAuto', () {
      const options = TuiRendererOptions(screenMode: ScreenMode.inlineAuto);
      expect(options.isInline, isTrue);
    });

    test('returns false for ScreenMode.fullScreen', () {
      const options = TuiRendererOptions(screenMode: ScreenMode.fullScreen);
      expect(options.isInline, isFalse);
    });
  });
}

int _count(String haystack, String needle) {
  var count = 0;
  var index = 0;
  while (true) {
    index = haystack.indexOf(needle, index);
    if (index == -1) return count;
    count++;
    index += needle.length;
  }
}

final class _ResizableStringTerminal extends StringTerminal {
  _ResizableStringTerminal({required int width, required int height})
    : _width = width,
      _height = height,
      super(terminalWidth: width, terminalHeight: height);

  int _width;
  int _height;

  void resize({required int width, required int height}) {
    _width = width;
    _height = height;
  }

  @override
  int get width => _width;

  @override
  int get height => _height;

  @override
  ({int width, int height}) get size => (width: _width, height: _height);
}

final class _TraceResizableStringTerminal extends StringTerminal {
  _TraceResizableStringTerminal({required int width, required int height})
    : _width = width,
      _height = height,
      super(terminalWidth: width, terminalHeight: height);

  int _width;
  int _height;

  void resize({required int width, required int height}) {
    _width = width;
    _height = height;
  }

  String takeOutput() {
    final output = this.output;
    clear();
    return output;
  }

  @override
  int get width => _width;

  @override
  int get height => _height;

  @override
  ({int width, int height}) get size => (width: _width, height: _height);
}

final class _InlineOutputTrace {
  _InlineOutputTrace(this._terminal);

  final InlineVirtualTerminal _terminal;

  void write(String bytes) => _terminal.feed(bytes);

  void resize({required int width, required int height}) {
    _terminal.resize(width: width, height: height);
  }
}

String _wideInlineDashboard({required int progress}) {
  final top = '+ flutter build dashboard ${'-' * 45}+';
  final status =
      '| RUNNING  phase: attach vm service   progress: ${progress.toString().padLeft(3)}% |';
  final bar = '| ${'#' * (progress ~/ 4)}${'.' * (25 - progress ~/ 4)} |';
  const perf = '| perf: 107fps   memory: 240MB   device: linux ready       |';
  const keys = '| keys: space pause/resume   q quit                        |';
  final bottom = '+${'-' * 70}+';
  return [top, status, bar, perf, keys, bottom].join('\n');
}
