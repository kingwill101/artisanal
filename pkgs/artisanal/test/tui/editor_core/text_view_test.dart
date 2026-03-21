import 'package:artisanal/src/tui/editor_core/editor_core.dart';
import 'package:artisanal/src/tui/editor_core/editor_core.dart' as commands;
import 'package:artisanal/src/tui/editor_core/editor_core.dart' as edit_ops;
import 'package:artisanal/src/tui/editor_core/editor_core.dart' as nav;
import 'package:test/test.dart';

typedef _HistoryState = ({String text, int cursor});
typedef _HistoryMarker = ({int cursor, int length});

enum _HistoryAction { insert, deleteBackward }

void main() {
  group('TextDocument', () {
    test('tracks grapheme-aware lines and length', () {
      final document = TextDocument(text: 'a\ne\u0301');

      expect(document.lineCount, 2);
      expect(document.lineLength(0), 1);
      expect(document.lineLength(1), 1);
      expect(document.length, 3);
      expect(document.text, 'a\ne\u0301');
    });

    test('maps positions to offsets and back', () {
      final document = TextDocument(text: 'ab\ncd');

      expect(
        document.offsetForPosition(const TextPosition(line: 1, column: 1)),
        4,
      );
      expect(
        document.positionForOffset(4),
        const TextPosition(line: 1, column: 1),
      );
      expect(
        document.positionForOffset(99),
        const TextPosition(line: 1, column: 2),
      );
    });

    test('rebuilds line-start offsets after text replacement', () {
      final document = TextDocument(text: 'ab\ncd');

      document.replaceText('w\nxyz\nq');

      expect(document.length, 7);
      expect(
        document.offsetForPosition(const TextPosition(line: 2, column: 1)),
        7,
      );
      expect(
        document.positionForOffset(5),
        const TextPosition(line: 1, column: 3),
      );
    });

    test('rebuilds line-start offsets after line replacement', () {
      final document = TextDocument(text: 'ab\ncd');

      document.replaceLines([
        ['x'],
        ['y', 'z'],
        ['q'],
      ]);

      expect(document.length, 6);
      expect(
        document.offsetForPosition(const TextPosition(line: 2, column: 1)),
        6,
      );
      expect(
        document.positionForOffset(2),
        const TextPosition(line: 1, column: 0),
      );
    });

    test('finds word boundaries on text and whitespace', () {
      final document = TextDocument(text: 'alpha  beta');

      final word = document.wordBoundaryAt(
        const TextPosition(line: 0, column: 1),
      );
      final gap = document.wordBoundaryAt(
        const TextPosition(line: 0, column: 5),
      );

      expect(word.start, const TextPosition(line: 0, column: 0));
      expect(word.end, const TextPosition(line: 0, column: 5));
      expect(gap.start, const TextPosition(line: 0, column: 5));
      expect(gap.end, const TextPosition(line: 0, column: 7));
    });

    test('reads graphemes and offset slices without flattening first', () {
      final document = TextDocument(text: 'ab\ncde');

      expect(document.graphemeAt(0), 'a');
      expect(document.graphemeAt(2), '\n');
      expect(document.graphemeAt(4), 'd');
      expect(document.graphemeAt(6), isNull);

      expect(
        document.graphemesInRange(startOffset: 1, endOffset: 5),
        const ['b', '\n', 'c', 'd'],
      );
      expect(
        document.matchesOffsetRange(
          startOffset: 2,
          graphemes: const ['\n', 'c'],
        ),
        isTrue,
      );
      expect(
        document.matchesOffsetRange(
          startOffset: 3,
          graphemes: const ['\n', 'c'],
        ),
        isFalse,
      );
      expect(document.lineGraphemesAt(1), const ['c', 'd', 'e']);
      expect(
        () => document.lineGraphemesAt(1).add('!'),
        throwsUnsupportedError,
      );
      expect(document.lineViews[0], const ['a', 'b']);
    });
  });

  group('TextHighlighting', () {
    test('finds grapheme-aware query highlights by offset', () {
      final document = TextDocument(text: 'Cafe\u0301\ncafe\u0301\ntea');

      final ranges = findTextQueryHighlights(
        document: document,
        query: 'CAFE\u0301',
      );

      expect(ranges, const [
        TextHighlightRange(startOffset: 0, endOffset: 4),
        TextHighlightRange(startOffset: 5, endOffset: 9),
      ]);
    });

    test('maps query matches onto reusable search decorations', () {
      final decorations = textSearchDecorations(const [
        TextHighlightRange(startOffset: 2, endOffset: 5),
        TextHighlightRange(startOffset: 8, endOffset: 11),
      ], activeIndex: 1);

      expect(decorations, const [
        TextDecorationRange(
          startOffset: 2,
          endOffset: 5,
          styleKey: textSearchMatchDecorationKey,
        ),
        TextDecorationRange(
          startOffset: 8,
          endOffset: 11,
          styleKey: textSearchActiveMatchDecorationKey,
        ),
      ]);
    });

    test('maps diagnostic severities onto reusable diagnostic decorations', () {
      final decorations = textDiagnosticDecorations(const [
        TextDiagnosticRange(
          startOffset: 1,
          endOffset: 4,
          severity: TextDiagnosticSeverity.error,
        ),
        TextDiagnosticRange(
          startOffset: 6,
          endOffset: 9,
          severity: TextDiagnosticSeverity.warning,
        ),
        TextDiagnosticRange(
          startOffset: 12,
          endOffset: 15,
          severity: TextDiagnosticSeverity.info,
        ),
        TextDiagnosticRange(
          startOffset: 18,
          endOffset: 21,
          severity: TextDiagnosticSeverity.hint,
        ),
      ]);

      expect(decorations, const [
        TextDecorationRange(
          startOffset: 1,
          endOffset: 4,
          styleKey: textDiagnosticErrorDecorationKey,
        ),
        TextDecorationRange(
          startOffset: 6,
          endOffset: 9,
          styleKey: textDiagnosticWarningDecorationKey,
        ),
        TextDecorationRange(
          startOffset: 12,
          endOffset: 15,
          styleKey: textDiagnosticInfoDecorationKey,
        ),
        TextDecorationRange(
          startOffset: 18,
          endOffset: 21,
          styleKey: textDiagnosticHintDecorationKey,
        ),
      ]);
    });

    test(
      'maps diagnostics onto whole-line decorations across spanned lines',
      () {
        final decorations = textDiagnosticLineDecorations(
          text: 'aa\nbb\ncc',
          diagnostics: const [
            TextDiagnosticRange(
              startOffset: 1,
              endOffset: 5,
              severity: TextDiagnosticSeverity.warning,
            ),
          ],
        );

        expect(decorations, const [
          TextLineDecoration(
            lineIndex: 0,
            styleKey: textDiagnosticWarningLineDecorationKey,
            lineNumberMarker: '~',
            lineNumberStyleKey: textDiagnosticWarningLineNumberDecorationKey,
          ),
          TextLineDecoration(
            lineIndex: 1,
            styleKey: textDiagnosticWarningLineDecorationKey,
            lineNumberMarker: '~',
            lineNumberStyleKey: textDiagnosticWarningLineNumberDecorationKey,
          ),
        ]);
      },
    );

    test('prefers the highest-severity line diagnostic style per row', () {
      final decorations = textDiagnosticLineDecorations(
        text: 'aa\nbb',
        diagnostics: const [
          TextDiagnosticRange(
            startOffset: 0,
            endOffset: 5,
            severity: TextDiagnosticSeverity.warning,
          ),
          TextDiagnosticRange(
            startOffset: 3,
            endOffset: 5,
            severity: TextDiagnosticSeverity.error,
          ),
        ],
      );

      expect(decorations, const [
        TextLineDecoration(
          lineIndex: 0,
          styleKey: textDiagnosticWarningLineDecorationKey,
          lineNumberMarker: '~',
          lineNumberStyleKey: textDiagnosticWarningLineNumberDecorationKey,
        ),
        TextLineDecoration(
          lineIndex: 1,
          styleKey: textDiagnosticErrorLineDecorationKey,
          lineNumberMarker: '!',
          lineNumberStyleKey: textDiagnosticErrorLineNumberDecorationKey,
        ),
      ]);
    });

    test('navigates diagnostics relative to the current cursor offset', () {
      final diagnostics = normalizeTextDiagnostics(const [
        TextDiagnosticRange(
          startOffset: 8,
          endOffset: 12,
          severity: TextDiagnosticSeverity.warning,
        ),
        TextDiagnosticRange(
          startOffset: 2,
          endOffset: 6,
          severity: TextDiagnosticSeverity.error,
        ),
      ]);

      expect(
        textDiagnosticNavigationIndex(
          diagnostics: diagnostics,
          cursorOffset: 0,
        ),
        0,
      );
      expect(
        textDiagnosticNavigationIndex(
          diagnostics: diagnostics,
          cursorOffset: 3,
        ),
        1,
      );
      expect(
        textDiagnosticNavigationIndex(
          diagnostics: diagnostics,
          cursorOffset: 20,
          wrap: false,
        ),
        isNull,
      );
      expect(
        textDiagnosticNavigationIndex(
          diagnostics: diagnostics,
          cursorOffset: 20,
          forward: false,
        ),
        1,
      );
      expect(
        textDiagnosticNavigationIndex(
          diagnostics: diagnostics,
          cursorOffset: 9,
          forward: false,
        ),
        0,
      );
    });

    test('preserves diagnostic metadata while normalizing and querying', () {
      final diagnostics = normalizeTextDiagnostics(const [
        TextDiagnosticRange(
          startOffset: 7,
          endOffset: 3,
          severity: TextDiagnosticSeverity.warning,
          code: 'TODO001',
          message: 'Address TODO markers before shipping this sample.',
          source: 'playground',
        ),
      ]);

      expect(diagnostics, const [
        TextDiagnosticRange(
          startOffset: 3,
          endOffset: 7,
          severity: TextDiagnosticSeverity.warning,
          code: 'TODO001',
          message: 'Address TODO markers before shipping this sample.',
          source: 'playground',
        ),
      ]);
      expect(
        textDiagnosticAtOffset(diagnostics: diagnostics, offset: 4)?.message,
        'Address TODO markers before shipping this sample.',
      );
      expect(
        textDiagnosticContainingIndex(diagnostics: diagnostics, offset: 4),
        0,
      );
    });

    test('converts line and column diagnostics into normalized offsets', () {
      final document = TextDocument(text: 'aa\nbb\ncc');
      final diagnostics = textDiagnosticsFromPositions(
        document: document,
        diagnostics: const [
          TextPositionDiagnosticRange(
            startLine: 2,
            startColumn: 1,
            endLine: 1,
            endColumn: 1,
            severity: TextDiagnosticSeverity.error,
            code: 'E1',
            message: 'Cross-line diagnostic',
            source: 'lsp',
          ),
        ],
      );

      expect(diagnostics, const [
        TextDiagnosticRange(
          startOffset: 4,
          endOffset: 7,
          severity: TextDiagnosticSeverity.error,
          code: 'E1',
          message: 'Cross-line diagnostic',
          source: 'lsp',
        ),
      ]);
    });

    test('resolves the displayed start position for a diagnostic', () {
      expect(
        textDiagnosticStartPosition(
          text: 'zero\nTODO here',
          diagnostic: const TextDiagnosticRange(
            startOffset: 5,
            endOffset: 9,
            severity: TextDiagnosticSeverity.warning,
          ),
        ),
        const TextPosition(line: 1, column: 0),
      );
    });

    test('formats a shared diagnostic summary label', () {
      expect(
        textDiagnosticSummaryLabel(
          text: 'zero\nTODO here',
          diagnostic: const TextDiagnosticRange(
            startOffset: 5,
            endOffset: 9,
            severity: TextDiagnosticSeverity.warning,
            code: 'TODO001',
            message: 'Address TODO markers before shipping this sample.',
            source: 'playground',
          ),
        ),
        'warning [playground/TODO001] L2:C1 '
        'Address TODO markers before shipping this sample.',
      );
    });

    test('builds positional diagnostics from shared pattern rules', () {
      expect(
        textPatternDiagnostics(
          text: 'TODO todoer\nnote TODO\nhint',
          rules: const [
            TextPatternDiagnosticRule(
              pattern: 'TODO',
              severity: TextDiagnosticSeverity.warning,
              code: 'TODO001',
              source: 'demo',
              wholeWord: true,
            ),
            TextPatternDiagnosticRule(
              pattern: 'NOTE',
              severity: TextDiagnosticSeverity.info,
              code: 'NOTE001',
              source: 'demo',
              wholeWord: true,
            ),
          ],
        ),
        const [
          TextPositionDiagnosticRange(
            startLine: 0,
            startColumn: 0,
            endLine: 0,
            endColumn: 4,
            severity: TextDiagnosticSeverity.warning,
            code: 'TODO001',
            source: 'demo',
          ),
          TextPositionDiagnosticRange(
            startLine: 1,
            startColumn: 0,
            endLine: 1,
            endColumn: 4,
            severity: TextDiagnosticSeverity.info,
            code: 'NOTE001',
            source: 'demo',
          ),
          TextPositionDiagnosticRange(
            startLine: 1,
            startColumn: 5,
            endLine: 1,
            endColumn: 9,
            severity: TextDiagnosticSeverity.warning,
            code: 'TODO001',
            source: 'demo',
          ),
        ],
      );
    });
  });

  group('TextSelection', () {
    test('normalizes start and end positions', () {
      const selection = TextSelection(
        base: TextPosition(line: 2, column: 1),
        extent: TextPosition(line: 0, column: 3),
      );

      expect(selection.start, const TextPosition(line: 0, column: 3));
      expect(selection.end, const TextPosition(line: 2, column: 1));
    });

    test('editor state reports selected line range', () {
      final state = EditorState(line: 4, column: 2)
        ..setSelection(
          base: const TextPosition(line: 3, column: 5),
          extent: const TextPosition(line: 1, column: 0),
        );

      expect(state.selectedLineRange(), (startLine: 1, endLine: 3));
    });

    test('editor state applies column deltas to cursor and selection', () {
      final state = EditorState(line: 1, column: 3)
        ..setSelection(
          base: const TextPosition(line: 0, column: 2),
          extent: const TextPosition(line: 1, column: 3),
        );

      state.applyColumnDeltas(const {0: 2, 1: -1}, lineLength: (line) => 8);

      expect(state.cursor, const TextPosition(line: 1, column: 2));
      expect(state.selection!.base, const TextPosition(line: 0, column: 4));
      expect(state.selection!.extent, const TextPosition(line: 1, column: 2));
    });

    test('editor state shifts cursor and selection rows in range', () {
      final state = EditorState(line: 1, column: 5)
        ..setSelection(
          base: const TextPosition(line: 1, column: 4),
          extent: const TextPosition(line: 2, column: 7),
        );

      state.shiftRowsInRange(
        startLine: 1,
        endLine: 2,
        delta: 1,
        maxLine: 4,
        lineLength: (line) => switch (line) {
          2 => 3,
          3 => 6,
          _ => 10,
        },
      );

      expect(state.cursor, const TextPosition(line: 3, column: 6));
      expect(state.selection!.base, const TextPosition(line: 2, column: 3));
      expect(state.selection!.extent, const TextPosition(line: 3, column: 6));
    });

    test('editor state begins, extends, and collapses selection', () {
      final state = EditorState(line: 0, column: 2);

      state.beginSelection();
      state.extendSelectionTo(const TextPosition(line: 1, column: 4));

      expect(state.selection!.base, const TextPosition(line: 0, column: 2));
      expect(state.selection!.extent, const TextPosition(line: 1, column: 4));

      state.collapseSelection();

      expect(state.selection, isNull);
      expect(state.cursor, const TextPosition(line: 1, column: 4));
    });
  });

  group('StateBridge', () {
    test('offset snapshots provide shared selection helpers', () {
      final selected = TextOffsetStateSnapshot.selection(
        baseOffset: 8,
        extentOffset: 1,
        cursorOffset: 8,
      );
      final collapsed = TextOffsetStateSnapshot.selection(
        baseOffset: 3,
        extentOffset: 3,
        cursorOffset: 3,
      );
      final clamped = TextOffsetStateSnapshot.selection(
        baseOffset: -2,
        extentOffset: 20,
        cursorOffset: 15,
      ).clamp(10);
      final cleared = selected.clearSelection(cursorOffset: 4);

      expect(selected.hasSelection, isTrue);
      expect(selected.normalizedSelectionRange, (start: 1, end: 8));

      expect(collapsed.hasSelection, isFalse);
      expect(collapsed.selectionBaseOffset, isNull);
      expect(collapsed.selectionExtentOffset, isNull);

      expect(clamped.cursorOffset, 10);
      expect(clamped.selectionBaseOffset, 0);
      expect(clamped.selectionExtentOffset, 10);

      expect(cleared.cursorOffset, 4);
      expect(cleared.selectionBaseOffset, isNull);
      expect(cleared.selectionExtentOffset, isNull);
    });

    test('line snapshots provide shared selection helpers', () {
      final selected = TextLineStateSnapshot.selection(
        base: const TextPosition(line: 1, column: 4),
        extent: const TextPosition(line: 0, column: 2),
        cursor: const TextPosition(line: 1, column: 4),
      );
      final collapsed = TextLineStateSnapshot.selection(
        base: const TextPosition(line: 3, column: 7),
        extent: const TextPosition(line: 3, column: 7),
        cursor: const TextPosition(line: 3, column: 7),
        preserveCollapsedSelection: true,
      );
      final clamped = TextLineStateSnapshot.selection(
        base: const TextPosition(line: -2, column: -1),
        extent: const TextPosition(line: 9, column: 8),
        cursor: const TextPosition(line: 7, column: 6),
      ).clamp(lineCount: 2, lineLength: (line) => line == 0 ? 5 : 4);
      final cleared = selected.clearSelection(
        cursor: const TextPosition(line: 0, column: 1),
      );

      expect(selected.hasSelection, isTrue);
      expect(selected.selection!.base, const TextPosition(line: 1, column: 4));
      expect(
        selected.selection!.extent,
        const TextPosition(line: 0, column: 2),
      );

      expect(collapsed.hasSelection, isFalse);
      expect(collapsed.selection!.base, const TextPosition(line: 3, column: 7));
      expect(
        collapsed.selection!.extent,
        const TextPosition(line: 3, column: 7),
      );

      expect(clamped.cursor, const TextPosition(line: 1, column: 4));
      expect(clamped.selectionBase, const TextPosition(line: 0, column: 0));
      expect(clamped.selectionExtent, const TextPosition(line: 1, column: 4));

      expect(cleared.cursor, const TextPosition(line: 0, column: 1));
      expect(cleared.selectionBase, isNull);
      expect(cleared.selectionExtent, isNull);
    });

    test('syncs editor state from offsets and captures offsets back', () {
      final document = TextDocument(text: 'alpha\nbeta');
      final state = EditorState();

      syncEditorStateFromOffsets(
        document,
        state,
        cursorOffset: 8,
        selectionBaseOffset: 1,
        selectionExtentOffset: 8,
      );

      expect(state.cursor, const TextPosition(line: 1, column: 2));
      expect(state.selection!.base, const TextPosition(line: 0, column: 1));
      expect(state.selection!.extent, const TextPosition(line: 1, column: 2));

      final snapshot = offsetSnapshotFromEditorState(
        document,
        state,
        textLength: document.length,
      );
      expect(snapshot.cursorOffset, 8);
      expect(snapshot.selectionBaseOffset, 1);
      expect(snapshot.selectionExtentOffset, 8);
    });

    test('preserves an explicit cursor distinct from selection extent', () {
      final document = TextDocument(text: 'alpha\nbeta');
      final state = EditorState();

      syncEditorStateFromOffsets(
        document,
        state,
        cursorOffset: 1,
        selectionBaseOffset: 1,
        selectionExtentOffset: 8,
      );

      expect(state.cursor, const TextPosition(line: 0, column: 1));
      expect(state.selection!.base, const TextPosition(line: 0, column: 1));
      expect(state.selection!.extent, const TextPosition(line: 1, column: 2));

      final snapshot = offsetSnapshotFromEditorState(
        document,
        state,
        textLength: document.length,
      );
      expect(snapshot.cursorOffset, 1);
      expect(snapshot.selectionBaseOffset, 1);
      expect(snapshot.selectionExtentOffset, 8);
    });

    test('syncs editor state from line snapshots and clamps positions', () {
      final state = EditorState();

      syncEditorStateFromLineSnapshot(
        state,
        const TextLineStateSnapshot(
          cursor: TextPosition(line: 4, column: 9),
          selectionBase: TextPosition(line: 0, column: 7),
          selectionExtent: TextPosition(line: 3, column: 8),
        ),
        lineCount: 2,
        lineLength: (line) => line == 0 ? 5 : 4,
      );

      expect(state.cursor, const TextPosition(line: 1, column: 4));
      expect(state.selection!.base, const TextPosition(line: 0, column: 5));
      expect(state.selection!.extent, const TextPosition(line: 1, column: 4));
    });

    test('captures line snapshots from editor state and offset snapshots', () {
      final state = EditorState()
        ..setSelection(
          base: const TextPosition(line: 0, column: 2),
          extent: const TextPosition(line: 8, column: 9),
        );

      final fromEditor = lineSnapshotFromEditorState(
        state,
        lineCount: 2,
        lineLength: (line) => line == 0 ? 5 : 4,
      );
      final document = TextDocument(text: 'alpha\nbeta');
      final fromOffsets = lineSnapshotFromOffsets(
        document,
        cursorOffset: 10,
        selectionBaseOffset: 6,
        selectionExtentOffset: 10,
      );

      expect(fromEditor.cursor, const TextPosition(line: 1, column: 4));
      expect(fromEditor.selectionBase, const TextPosition(line: 0, column: 2));
      expect(
        fromEditor.selectionExtent,
        const TextPosition(line: 1, column: 4),
      );

      expect(fromOffsets.cursor, const TextPosition(line: 1, column: 4));
      expect(fromOffsets.selectionBase, const TextPosition(line: 1, column: 0));
      expect(
        fromOffsets.selectionExtent,
        const TextPosition(line: 1, column: 4),
      );
    });
  });

  group('TextView', () {
    test('builds wrapped lines from document and editor state', () {
      final document = TextDocument(text: 'abcdef');
      final state = EditorState(line: 0, column: 4);
      final view = TextView(width: 4, height: 4, softWrap: true);

      final lines = view.buildLines(document, state);

      expect(lines.length, 2);
      expect(lines[0].text, 'abcd');
      expect(lines[0].charOffset, 0);
      expect(lines[0].hasCursor, isTrue);
      expect(lines[1].text, 'ef');
      expect(lines[1].charOffset, 4);
      expect(lines[1].hasCursor, isTrue);
    });

    test('hit testing maps visual rows back to logical coordinates', () {
      final document = TextDocument(text: 'abcdef');
      final state = EditorState(line: 0, column: 0);
      final view = TextView(width: 4, height: 4, softWrap: true);

      final hit = view.hitTestContent(document, state, localX: 1, visualRow: 1);

      expect(hit, isNotNull);
      expect(hit!.line, 0);
      expect(hit.column, 5);
    });

    test('builds a viewport window and keeps the cursor visible', () {
      final document = TextDocument(text: 'a\nb\nc\nd');
      final state = EditorState(line: 3, column: 1);
      final view = TextView(width: 8, height: 2, softWrap: true);

      final viewport = view.resolveViewport(document, state);
      final lines = view.buildViewportLines(document, state);

      expect(viewport.startRow, 2);
      expect(viewport.endRow, 4);
      expect(lines.map((line) => line.text).toList(), ['c', 'd']);
      expect(lines.last.hasCursor, isTrue);
    });

    test('hit testing uses viewport-local rows', () {
      final document = TextDocument(text: 'a\nb\nc\nd');
      final state = EditorState(line: 3, column: 1);
      final view = TextView(width: 8, height: 2, softWrap: true);

      final hit = view.hitTestContent(document, state, localX: 0, visualRow: 0);

      expect(hit, isNotNull);
      expect(hit!.line, 2);
      expect(hit.column, 0);
    });

    test('supports manual row scrolling and paging', () {
      final document = TextDocument(text: 'a\nb\nc\nd\ne');
      final state = EditorState(line: 2, column: 1);
      final view = TextView(width: 8, height: 2, softWrap: true);

      view.scrollByRows(1, document);
      expect(view.viewportStartRow, 1);

      view.pageDown(document);
      expect(view.viewportStartRow, 3);

      view.pageUp(document);
      expect(view.viewportStartRow, 1);

      final lines = view.buildViewportLines(document, state);
      expect(lines.map((line) => line.text).toList(), ['b', 'c']);
    });

    test('ensureCursorVisible updates the viewport start row', () {
      final document = TextDocument(text: 'a\nb\nc\nd\ne');
      final state = EditorState(line: 4, column: 1);
      final view = TextView(width: 8, height: 2, softWrap: true);

      view.scrollToRow(0, document);
      final startRow = view.ensureCursorVisible(document, state);

      expect(startRow, 3);
      expect(view.viewportStartRow, 3);
      expect(view.isCursorVisible(document, state), isTrue);
    });

    test('clips non-wrapped lines to the visible column window', () {
      final document = TextDocument(text: 'abcdefghij\nklmnopqrst');
      final state = EditorState(line: 0, column: 0);
      final view = TextView(width: 4, height: 4, softWrap: false);

      final lines = view.buildLinesForCurrentViewport(document, state);

      expect(lines.map((line) => line.text).toList(), ['abcd', 'klmn']);

      view.scrollToColumn(3, document, state);
      final scrolled = view.buildLinesForCurrentViewport(document, state);

      expect(scrolled.map((line) => line.text).toList(), ['defg', 'nopq']);
      expect(scrolled.first.charOffset, 3);
      expect(scrolled.last.charOffset, 3);
    });

    test('resolves a cursor-visible horizontal viewport for non-wrapped content', () {
      final document = TextDocument(text: 'abcdefghij');
      final state = EditorState(line: 0, column: 8);
      final view = TextView(width: 4, height: 2, softWrap: false);

      final viewport = view.resolveViewport(document, state);

      expect(viewport.startColumn, 5);
      expect(viewport.endColumn, 9);
      expect(viewport.totalColumns, 10);
    });

    test('hit testing uses the horizontal viewport offset', () {
      final document = TextDocument(text: 'abcdefghij');
      final state = EditorState(line: 0, column: 0);
      final view = TextView(width: 4, height: 2, softWrap: false);

      view.scrollToColumn(3, document, state);
      final hit = view.hitTestContent(document, state, localX: 1, visualRow: 0);

      expect(hit, isNotNull);
      expect(hit!.line, 0);
      expect(hit.column, 4);
    });

    test('ensureCursorVisible updates the horizontal viewport with scroll margin', () {
      final document = TextDocument(text: 'abcdefghij');
      final state = EditorState(line: 0, column: 8);
      final view = TextView(
        width: 4,
        height: 2,
        softWrap: false,
        scrollMargin: 1,
      );

      view.scrollToColumn(0, document, state);
      final startRow = view.ensureCursorVisible(document, state);

      expect(startRow, 0);
      expect(view.viewportStartColumn, 6);
      expect(view.isCursorVisible(document, state), isTrue);
    });

    test(
      'resolves soft-wrap boundary cursors to the continuation visual row',
      () {
        final document = TextDocument(text: 'abcdef');
        final state = EditorState(line: 0, column: 4);
        final view = TextView(width: 4, height: 4, softWrap: true);

        final visual = view.resolveCursorVisualPosition(document, state);

        expect(visual, isNotNull);
        expect(visual!.visualRow, 1);
        expect(visual.column, 0);
        expect(visual.displayColumn, 0);
        expect(visual.startOffset, 4);
        expect(visual.endOffset, 6);
        expect(view.cursorVisualRow(document, state), 1);
      },
    );
  });

  group('TextNavigation', () {
    test('moves and deletes across word boundaries', () {
      final graphemes = 'alpha  beta'.split('');
      bool isWord(String grapheme) => grapheme != ' ';

      expect(nav.moveWordBackward(graphemes, 7, isWord: isWord), 0);
      expect(nav.moveWordForward(graphemes, 0, isWord: isWord), 5);
      expect(nav.deleteWordBackwardRange(graphemes, 7, isWord: isWord), (
        start: 0,
        end: 7,
      ));
      expect(nav.deleteWordForwardRange(graphemes, 5, isWord: isWord), (
        start: 5,
        end: 11,
      ));
    });

    test('finds forward and fallback word ranges for transforms', () {
      final graphemes = '  alpha beta'.split('');
      bool isWord(String grapheme) => grapheme != ' ';

      expect(nav.nextWordRange(graphemes, 0, isWord: isWord), (
        start: 2,
        end: 7,
      ));
      expect(
        nav.previousWordRange(graphemes, graphemes.length, isWord: isWord),
        (start: 8, end: 12),
      );
      expect(
        nav.wordRangeForTransform(graphemes, graphemes.length, isWord: isWord),
        (start: 8, end: 12),
      );
    });
  });

  group('CodeEditPolicy', () {
    test('computes indentation growth and block newline suffixes', () {
      expect(codeLeadingIndent(' \t  value'), ' \t  ');
      expect(codeShouldIncreaseIndentAfter('if (ready) {'), isTrue);
      expect(
        codeShouldIncreaseIndentAfter('case:', language: 'python'),
        isTrue,
      );
      expect(codeShouldIncreaseIndentAfter('case:', language: 'dart'), isFalse);

      final suffix = codeBlockNewlineSuffix(
        beforeCursor: '{',
        afterCursor: '   }',
        baseIndent: '  ',
      );

      expect(suffix?.text, '\n  ');
      expect(suffix?.consumedColumns, 3);
    });

    test('computes symmetric auto-pair and outdent behavior', () {
      expect(codeShouldAutoPairSymmetricDelimiter('word', 4), isFalse);
      expect(codeShouldAutoPairSymmetricDelimiter(' ', 1), isTrue);
      expect(
        codeShouldAutoPairSymmetricDelimiter('word', 4, hasSelection: true),
        isTrue,
      );

      expect(codeOutdentedIndent('    ', 2), '  ');
      expect(codeOutdentedIndent('\t', 2), '');
      expect(codeOutdentedIndent('   ', 2), ' ');
    });
  });

  group('CodeLanguageProfile', () {
    test('resolves comment delimiters by language', () {
      final python = resolveCodeLanguageProfile('python');
      final markdown = resolveCodeLanguageProfile('markdown');
      final dart = resolveCodeLanguageProfile('dart');

      expect(python.lineCommentPrefix, '#');
      expect(python.blockCommentDelimiters, isNull);

      expect(markdown.lineCommentPrefix, '//');
      expect(markdown.blockCommentDelimiters?.start, '<!--');
      expect(markdown.blockCommentDelimiters?.end, '-->');

      expect(dart.lineCommentPrefix, '//');
      expect(dart.blockCommentDelimiters?.start, '/*');
      expect(dart.blockCommentDelimiters?.end, '*/');
    });

    test('provides shared auto-pair tables', () {
      final profile = resolveCodeLanguageProfile('dart');

      expect(profile.autoPairs['('], ')');
      expect(profile.autoPairs['"'], '"');
      expect(profile.closingToOpening[')'], '(');
      expect(profile.closingToOpening['"'], '"');
    });
  });

  group('CodeEditing', () {
    test('handles auto-pair insertion, skipping, and pair backspace', () {
      final profile = resolveCodeLanguageProfile('dart');
      final inserted = codeHandleAutoPair(
        document: TextDocument(text: 'print'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 5),
        profile: profile,
        typed: '(',
      );
      final skipped = codeHandleAutoPair(
        document: TextDocument(text: 'print()'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 6),
        profile: profile,
        typed: ')',
      );
      final deleted = codeHandlePairBackspace(
        document: TextDocument(text: 'print()'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 6),
        profile: profile,
      );

      expect(inserted.graphemes.join(), 'print()');
      expect(inserted.cursorOffset, 6);
      expect(skipped.graphemes.join(), 'print()');
      expect(skipped.cursorOffset, 7);
      expect(deleted.graphemes.join(), 'print');
      expect(deleted.cursorOffset, 5);
    });

    test(
      'handles closing-delimiter alignment, indented newline, and comments',
      () {
        final profile = resolveCodeLanguageProfile('dart');
        final aligned = codeHandleClosingDelimiterAlignment(
          document: TextDocument(text: 'if (ready) {\n  '),
          state: TextOffsetStateSnapshot.collapsed(cursorOffset: 15),
          profile: profile,
          typed: '}',
          indentWidth: 2,
        );
        final newline = codeInsertIndentedNewline(
          document: TextDocument(text: 'if (ready) {}'),
          state: TextOffsetStateSnapshot.collapsed(cursorOffset: 12),
          indentWidth: 2,
          language: 'dart',
        );
        final commented = codeToggleBlockComments(
          document: TextDocument(text: 'alpha\nbeta\ngamma'),
          state: TextOffsetStateSnapshot.selection(
            baseOffset: 0,
            extentOffset: 10,
            cursorOffset: 10,
          ),
          profile: profile,
        );

        expect(aligned.graphemes.join(), 'if (ready) {\n}');
        expect(aligned.cursorOffset, 14);
        expect(newline.graphemes.join(), 'if (ready) {\n  \n}');
        expect(newline.cursorOffset, 15);
        expect(commented.graphemes.join(), '/* alpha\nbeta */\ngamma');
        expect(commented.selectionBaseOffset, 0);
        expect(commented.selectionExtentOffset, 16);
      },
    );
  });

  group('TextEditing', () {
    test('handles shared split and selection-or-line transforms', () {
      final split = textSplitLine(
        document: TextDocument(text: 'alpha beta'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 5),
      );
      final uppercased = textTransformSelectionOrLine(
        document: TextDocument(text: 'alpha\nbeta'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 7),
        transform: (text) => text.toUpperCase(),
      );
      final capitalized = textTransformSelectionOrLine(
        document: TextDocument(text: 'hello world'),
        state: TextOffsetStateSnapshot.selection(
          baseOffset: 0,
          extentOffset: 11,
          cursorOffset: 11,
        ),
        transform: textCapitalizeWords,
      );

      expect(split.graphemes.join(), 'alpha\n beta');
      expect(split.cursorOffset, 6);
      expect(uppercased.graphemes.join(), 'alpha\nBETA');
      expect(capitalized.graphemes.join(), 'Hello World');
      expect(capitalized.selectionBaseOffset, 0);
      expect(capitalized.selectionExtentOffset, 11);
    });

    test('handles shared wrap, unwrap, and word transforms', () {
      final wrapped = textWrapSelection(
        document: TextDocument(text: 'alpha'),
        state: TextOffsetStateSnapshot.selection(
          baseOffset: 0,
          extentOffset: 5,
          cursorOffset: 5,
        ),
        before: '**',
      );
      final unwrapped = textUnwrapSelection(
        document: TextDocument(text: '(alpha)'),
        state: TextOffsetStateSnapshot.selection(
          baseOffset: 1,
          extentOffset: 6,
          cursorOffset: 6,
        ),
        surroundPairs: const {'(': ')'},
      );
      final transformed = textTransformWordOrAdjacent(
        document: TextDocument(text: 'alpha beta'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 6),
        transform: (text) => text.toUpperCase(),
      );

      expect(wrapped.graphemes.join(), '**alpha**');
      expect(wrapped.selectionBaseOffset, 2);
      expect(wrapped.selectionExtentOffset, 7);
      expect(unwrapped.graphemes.join(), 'alpha');
      expect(unwrapped.selectionBaseOffset, 0);
      expect(unwrapped.selectionExtentOffset, 5);
      expect(transformed.graphemes.join(), 'alpha BETA');
      expect(transformed.cursorOffset, 10);
    });

    test('handles shared delete and movement intents', () {
      final deletedSelection = textDeleteSelection(
        document: TextDocument(text: 'alpha beta'),
        state: TextOffsetStateSnapshot.selection(
          baseOffset: 6,
          extentOffset: 10,
          cursorOffset: 10,
        ),
      );
      final deletedPrevious = textDeletePrevious(
        document: TextDocument(text: 'alpha'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 5),
      );
      final deletedNext = textDeleteNext(
        document: TextDocument(text: 'alpha'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 0),
      );
      final deletedWordBackward = textDeleteWordBackward(
        document: TextDocument(text: 'alpha beta'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 10),
      );
      final deletedWordForward = textDeleteWordForward(
        document: TextDocument(text: 'alpha beta'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 6),
      );
      final deletedToLineStart = textDeleteToLineStart(
        document: TextDocument(text: 'alpha\nbeta'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 8),
      );
      final deletedToLineEnd = textDeleteToLineEnd(
        document: TextDocument(text: 'alpha\nbeta'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 8),
      );
      final movedCharacter = textMoveByCharacter(
        document: TextDocument(text: 'alpha'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 1),
        forward: true,
      );
      final movedWord = textMoveByWord(
        document: TextDocument(text: 'alpha beta'),
        state: TextOffsetStateSnapshot.selection(
          baseOffset: 0,
          extentOffset: 6,
          cursorOffset: 6,
        ),
        forward: false,
        clearSelection: true,
      );
      final movedBoundary = textMoveToDocumentBoundary(
        document: TextDocument(text: 'alpha'),
        state: TextOffsetStateSnapshot.selection(
          baseOffset: 0,
          extentOffset: 2,
          cursorOffset: 1,
        ),
        forward: true,
        clearSelection: false,
      );

      expect(deletedSelection.graphemes.join(), 'alpha ');
      expect(deletedSelection.cursorOffset, 6);
      expect(deletedPrevious.graphemes.join(), 'alph');
      expect(deletedPrevious.cursorOffset, 4);
      expect(deletedNext.graphemes.join(), 'lpha');
      expect(deletedNext.cursorOffset, 0);
      expect(deletedWordBackward.graphemes.join(), 'alpha ');
      expect(deletedWordBackward.cursorOffset, 6);
      expect(deletedWordForward.graphemes.join(), 'alpha ');
      expect(deletedWordForward.cursorOffset, 6);
      expect(deletedToLineStart.graphemes.join(), 'alpha\nta');
      expect(deletedToLineStart.cursorOffset, 6);
      expect(deletedToLineEnd.graphemes.join(), 'alpha\nbe');
      expect(deletedToLineEnd.cursorOffset, 8);
      expect(movedCharacter.cursorOffset, 2);
      expect(movedWord.cursorOffset, 0);
      expect(movedWord.selectionBaseOffset, isNull);
      expect(movedWord.selectionExtentOffset, isNull);
      expect(movedBoundary.cursorOffset, 5);
      expect(movedBoundary.selectionBaseOffset, 0);
      expect(movedBoundary.selectionExtentOffset, 2);
    });

    test('supports custom word predicates for shared word intents', () {
      bool isWhitespaceDelimitedWord(String grapheme) {
        return !const <String>{' ', '\t', '\n', '\r'}.contains(grapheme);
      }

      final defaultMoved = textMoveByWord(
        document: TextDocument(text: 'foo.bar baz'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 0),
        forward: true,
      );
      final customMoved = textMoveByWord(
        document: TextDocument(text: 'foo.bar baz'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 0),
        forward: true,
        isWord: isWhitespaceDelimitedWord,
      );
      final customDeleted = textDeleteWordBackward(
        document: TextDocument(text: 'foo.bar baz'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 7),
        isWord: isWhitespaceDelimitedWord,
      );

      expect(defaultMoved.cursorOffset, 3);
      expect(customMoved.cursorOffset, 7);
      expect(customDeleted.graphemes.join(), ' baz');
      expect(customDeleted.cursorOffset, 0);
    });

    test('prepares sanitized inserted graphemes with multiline limits', () {
      final singleLine = textPrepareInsertedGraphemes(
        'a\tb\nc\u0000d'.runes.toList(),
        multiline: false,
      );
      final multilineLimited = textPrepareInsertedGraphemes(
        'a\tb\nc'.runes.toList(),
        multiline: true,
        maxGraphemes: 6,
      );

      expect(singleLine.join(), 'a b cd');
      expect(multilineLimited.join(), 'a    b');
    });

    test('plans collapsed and chunked paste behavior', () {
      final collapsed = planTextPaste(
        'alpha\nbeta\ngamma',
        collapseLargePaste: true,
        collapsedPasteMinChars: 999,
        collapsedPasteMinLines: 3,
        chunkThresholdRunes: 1200,
      );
      final chunked = planTextPaste(
        'a' * 1200,
        collapseLargePaste: false,
        collapsedPasteMinChars: 9999,
        collapsedPasteMinLines: 9999,
        chunkThresholdRunes: 1200,
      );
      final inline = planTextPaste(
        'short',
        collapseLargePaste: false,
        collapsedPasteMinChars: 9999,
        collapsedPasteMinLines: 9999,
        chunkThresholdRunes: 1200,
      );
      final lastChunk = nextTextPasteChunk(
        totalRunes: 10,
        offset: 7,
        chunkSize: 3,
      );

      expect(collapsed.mode, TextPasteMode.collapsed);
      expect(collapsed.lineCount, 3);
      expect(textCollapsedPasteToken(lineCount: 3), '[Pasted ~3 lines]');
      expect(chunked.mode, TextPasteMode.chunked);
      expect(chunked.runeCount, 1200);
      expect(inline.mode, TextPasteMode.inline);
      expect(lastChunk, isNotNull);
      expect(lastChunk!.start, 7);
      expect(lastChunk.end, 10);
      expect(lastChunk.hasMore, isFalse);
      expect(
        nextTextPasteChunk(totalRunes: 10, offset: 10, chunkSize: 3),
        isNull,
      );
    });

    test('advances chunked paste sessions through shared steps', () {
      final session = TextPasteSession.fromText('abcdefg');
      final first = session.takeChunk(3);
      final second = first!.nextSession!.takeChunk(3);
      final third = second!.nextSession!.takeChunk(3)!;

      expect(first.runes, [97, 98, 99]);
      expect(first.start, 0);
      expect(first.end, 3);
      expect(first.hasMore, isTrue);
      expect(second.runes, [100, 101, 102]);
      expect(second.start, 3);
      expect(second.end, 6);
      expect(second.hasMore, isTrue);
      expect(third.runes, [103]);
      expect(third.start, 6);
      expect(third.end, 7);
      expect(third.hasMore, isFalse);
      expect(third.nextSession, isNull);
    });

    test('stores collapsed paste references through shared store', () {
      final store = TextPasteReferenceStore();
      final first = store.store('alpha\nbeta', lineCount: 2);
      final second = store.store('gamma', lineCount: 1);

      expect(first.uri, 'paste://1');
      expect(first.content, 'alpha\nbeta');
      expect(first.token, '[Pasted ~2 lines]');
      expect(second.uri, 'paste://2');
      expect(store.lastRef, 'paste://2');
      expect(store.buffer['paste://1'], 'alpha\nbeta');
      expect(store.buffer['paste://2'], 'gamma');
    });

    test(
      'tracks collapsed references and chunked sessions in a controller',
      () {
        final controller = TextPasteController();
        final ref = controller.storeCollapsed('alpha\nbeta', lineCount: 2);
        final first = controller.startChunked('abcdefg', chunkSize: 3)!;
        final stillPendingAfterFirst = controller.hasPendingChunkedPaste;
        final second = controller.takeNextChunk(chunkSize: 3)!;
        final third = controller.takeNextChunk(chunkSize: 3)!;

        expect(ref.uri, 'paste://1');
        expect(controller.buffer[ref.uri], 'alpha\nbeta');
        expect(first.runes, [97, 98, 99]);
        expect(stillPendingAfterFirst, isTrue);
        expect(second.runes, [100, 101, 102]);
        expect(third.runes, [103]);
        expect(controller.hasPendingChunkedPaste, isFalse);
      },
    );

    test('handles shared insert and transpose intents', () {
      final inserted = textInsertText(
        document: TextDocument(text: 'alpha'),
        state: TextOffsetStateSnapshot.selection(
          baseOffset: 0,
          extentOffset: 5,
          cursorOffset: 5,
        ),
        text: 'beta',
      );
      final newline = textInsertText(
        document: TextDocument(text: 'alpha beta'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 5),
        text: '\n',
      );
      final insertedGraphemes = textInsertGraphemes(
        document: TextDocument(text: 'alpha'),
        state: TextOffsetStateSnapshot.selection(
          baseOffset: 0,
          extentOffset: 5,
          cursorOffset: 5,
        ),
        graphemes: const ['b', 'e', 't', 'a'],
        replaceSelection: false,
      );
      final transposed = textTransposeBackward(
        document: TextDocument(text: 'ab'),
        state: TextOffsetStateSnapshot.collapsed(cursorOffset: 2),
      );

      expect(inserted.graphemes.join(), 'beta');
      expect(inserted.cursorOffset, 4);
      expect(newline.graphemes.join(), 'alpha\n beta');
      expect(newline.cursorOffset, 6);
      expect(insertedGraphemes.graphemes.join(), 'alphabeta');
      expect(insertedGraphemes.cursorOffset, 9);
      expect(insertedGraphemes.selectionBaseOffset, isNull);
      expect(insertedGraphemes.selectionExtentOffset, isNull);
      expect(transposed.graphemes.join(), 'ba');
      expect(transposed.cursorOffset, 2);
    });

    test('handles shared line movement and prefix/list commands', () {
      final moved = textMoveSelectedLines(
        lines: const ['alpha', 'beta', 'gamma'],
        state: TextLineStateSnapshot.collapsed(
          cursor: const TextPosition(line: 1, column: 0),
        ),
        direction: -1,
      );
      final prefixed = textToggleLinePrefix(
        lines: const ['alpha'],
        state: TextLineStateSnapshot.collapsed(
          cursor: const TextPosition(line: 0, column: 0),
        ),
        prefix: '-',
      );
      final numbered = textToggleNumberedList(
        lines: const ['alpha', 'beta'],
        state: TextLineStateSnapshot.selection(
          base: const TextPosition(line: 0, column: 0),
          extent: const TextPosition(line: 1, column: 4),
        ),
      );

      expect(moved.lines, ['beta', 'alpha', 'gamma']);
      expect(prefixed.lines, ['- alpha']);
      expect(numbered.lines, ['1. alpha', '2. beta']);
    });

    test('handles shared indent, outdent, join, and delete intents', () {
      final indented = textIndentLines(
        lines: const ['alpha', 'beta'],
        state: TextLineStateSnapshot.selection(
          base: const TextPosition(line: 0, column: 0),
          extent: const TextPosition(line: 1, column: 4),
        ),
        width: 2,
      );
      final outdented = textOutdentLines(
        lines: indented.lines,
        state: TextLineStateSnapshot.selection(
          base: indented.selectionBase!,
          extent: indented.selectionExtent!,
        ),
        width: 2,
      );
      final joined = textJoinLines(
        lines: const ['alpha', '  beta'],
        state: TextLineStateSnapshot.collapsed(
          cursor: const TextPosition(line: 0, column: 1),
        ),
      );
      final deleted = textDeleteLines(
        lines: const ['alpha', 'beta', 'gamma'],
        state: TextLineStateSnapshot.collapsed(
          cursor: const TextPosition(line: 1, column: 1),
        ),
      );

      expect(indented.lines, ['  alpha', '  beta']);
      expect(outdented.lines, ['alpha', 'beta']);
      expect(joined.lines, ['alpha beta']);
      expect(joined.cursor, const TextPosition(line: 0, column: 10));
      expect(deleted.lines, ['alpha', 'gamma']);
      expect(deleted.cursor, const TextPosition(line: 1, column: 1));
    });

    test('handles shared sort and cleanup intents', () {
      final sorted = textSortSelectedLines(
        lines: const ['delta', 'beta', 'alpha'],
        state: TextLineStateSnapshot.collapsed(
          cursor: const TextPosition(line: 2, column: 3),
        ),
      );
      final cleaned = textCleanupWhitespace(
        lines: const ['alpha  ', 'beta\t', '', ''],
        state: TextLineStateSnapshot.collapsed(
          cursor: const TextPosition(line: 3, column: 0),
        ),
      );

      expect(sorted.lines, ['alpha', 'beta', 'delta']);
      expect(sorted.cursor, const TextPosition(line: 2, column: 3));
      expect(cleaned.lines, ['alpha', 'beta']);
      expect(cleaned.cursor, const TextPosition(line: 1, column: 4));
    });
  });

  group('TextEditOps', () {
    test('removes and replaces grapheme ranges with stable cursor offsets', () {
      final removed = edit_ops.removeRange(
        'alpha beta'.split(''),
        start: 5,
        end: 10,
      );
      final replaced = edit_ops.replaceRange(
        'alpha'.split(''),
        start: 0,
        end: 5,
        replacement: 'beta'.split(''),
      );

      expect(removed.graphemes.join(), 'alpha');
      expect(removed.cursorOffset, 5);
      expect(replaced.graphemes.join(), 'beta');
      expect(replaced.cursorOffset, 4);
    });

    test('supports cursor-relative delete helpers', () {
      final graphemes = 'alpha beta'.split('');

      final before = edit_ops.deleteBeforeCursor(graphemes, 5);
      final after = edit_ops.deleteAfterCursor(graphemes, 6);
      final previous = edit_ops.deletePreviousGrapheme(graphemes, 6);
      final next = edit_ops.deleteNextGrapheme(graphemes, 5);

      expect(before.graphemes.join(), ' beta');
      expect(before.cursorOffset, 0);
      expect(after.graphemes.join(), 'alpha ');
      expect(after.cursorOffset, 6);
      expect(previous.graphemes.join(), 'alphabeta');
      expect(previous.cursorOffset, 5);
      expect(next.graphemes.join(), 'alphabeta');
      expect(next.cursorOffset, 5);
    });

    test('supports insertion at the cursor', () {
      final inserted = edit_ops.insertAtCursor(
        'alpha'.split(''),
        2,
        'Z'.split(''),
      );

      expect(inserted.graphemes.join(), 'alZpha');
      expect(inserted.cursorOffset, 3);
    });
  });

  group('EditHistoryController', () {
    EditHistoryController<_HistoryAction, _HistoryState, _HistoryMarker>
    buildHistory() {
      return EditHistoryController<
        _HistoryAction,
        _HistoryState,
        _HistoryMarker
      >(
        maxEntries: 10,
        sameState: (a, b) => a == b,
        canCoalesce:
            (
              action, {
              required lastAction,
              required lastMarker,
              required currentState,
            }) {
              if (lastAction != action || lastMarker == null) {
                return false;
              }
              return switch (action) {
                _HistoryAction.insert =>
                  lastMarker.cursor == currentState.cursor &&
                      lastMarker.length == currentState.text.length,
                _HistoryAction.deleteBackward =>
                  lastMarker.cursor == currentState.cursor &&
                      lastMarker.length == currentState.text.length,
              };
            },
        markerForState: (action, state) =>
            (cursor: state.cursor, length: state.text.length),
      );
    }

    test('coalesces adjacent insert frames into one undo step', () {
      final history = buildHistory();
      var state = (text: '', cursor: 0);

      history.runFrame(
        captureState: () => state,
        body: () {
          history.beginAction(_HistoryAction.insert);
          history.recordUndoSnapshot(() => state);
          state = (text: 'a', cursor: 1);
        },
      );
      history.runFrame(
        captureState: () => state,
        body: () {
          history.beginAction(_HistoryAction.insert);
          history.recordUndoSnapshot(() => state);
          state = (text: 'ab', cursor: 2);
        },
      );

      expect(history.canUndo, isTrue);
      expect(
        history.undo(
          captureState: () => state,
          restoreState: (next) => state = next,
        ),
        isTrue,
      );
      expect(state, (text: '', cursor: 0));
    });

    test('breakCoalescing preserves the intermediate undo step', () {
      final history = buildHistory();
      var state = (text: '', cursor: 0);

      history.runFrame(
        captureState: () => state,
        body: () {
          history.beginAction(_HistoryAction.insert);
          history.recordUndoSnapshot(() => state);
          state = (text: 'a', cursor: 1);
        },
      );
      history.breakCoalescing();
      history.runFrame(
        captureState: () => state,
        body: () {
          history.beginAction(_HistoryAction.insert);
          history.recordUndoSnapshot(() => state);
          state = (text: 'ab', cursor: 2);
        },
      );

      expect(
        history.undo(
          captureState: () => state,
          restoreState: (next) => state = next,
        ),
        isTrue,
      );
      expect(state, (text: 'a', cursor: 1));
      expect(
        history.redo(
          captureState: () => state,
          restoreState: (next) => state = next,
        ),
        isTrue,
      );
      expect(state, (text: 'ab', cursor: 2));
    });
  });

  group('TextCommands', () {
    test('replaces selection or inserts at cursor', () {
      final replaced = commands.replaceSelectionOrInsert(
        'alpha beta'.split(''),
        cursorOffset: 10,
        selectionBaseOffset: 6,
        selectionExtentOffset: 10,
        replacement: 'dart'.split(''),
      );
      final inserted = commands.replaceSelectionOrInsert(
        'alpha'.split(''),
        cursorOffset: 2,
        replacement: 'Z'.split(''),
      );

      expect(replaced.graphemes.join(), 'alpha dart');
      expect(replaced.cursorOffset, 10);
      expect(inserted.graphemes.join(), 'alZpha');
      expect(inserted.cursorOffset, 3);
    });

    test('deletes the normalized selection range', () {
      final deleted = commands.deleteSelection(
        'alpha beta'.split(''),
        selectionBaseOffset: 10,
        selectionExtentOffset: 6,
        cursorOffset: 10,
      );

      expect(deleted.changed, isTrue);
      expect(deleted.graphemes.join(), 'alpha ');
      expect(deleted.cursorOffset, 6);
    });

    test('deletes previous or next grapheme when selection is collapsed', () {
      final previous = commands.deletePreviousOrSelection(
        'alpha'.split(''),
        cursorOffset: 5,
      );
      final next = commands.deleteNextOrSelection(
        'alpha'.split(''),
        cursorOffset: 0,
      );

      expect(previous.graphemes.join(), 'alph');
      expect(previous.cursorOffset, 4);
      expect(next.graphemes.join(), 'lpha');
      expect(next.cursorOffset, 0);
    });

    test('deletes words and line segments from offset-state wrappers', () {
      bool isWord(String grapheme) => grapheme != ' ';

      final deleteWord = TextOffsetStateSnapshot.collapsed(
        cursorOffset: 10,
      ).deleteWordBackwardCommand('alpha beta'.split(''), isWord: isWord);
      final deleteLineEnd = TextOffsetStateSnapshot.collapsed(
        cursorOffset: 5,
      ).deleteToLineEndCommand('alpha beta'.split(''), lineEndOffset: 10);

      expect(deleteWord.graphemes.join(), 'alpha ');
      expect(deleteWord.cursorOffset, 6);
      expect(deleteLineEnd.graphemes.join(), 'alpha');
      expect(deleteLineEnd.cursorOffset, 5);
    });

    test('moves cursor offsets and extends selections', () {
      final selected = commands.moveCursorByCharacter(
        'alpha'.split(''),
        cursorOffset: 1,
        forward: true,
        extendSelection: true,
      );
      final extended = commands.moveCursorByCharacter(
        'alpha'.split(''),
        cursorOffset: selected.cursorOffset,
        selectionBaseOffset: selected.selectionBaseOffset,
        selectionExtentOffset: selected.selectionExtentOffset,
        forward: true,
        extendSelection: true,
      );

      expect(selected.cursorOffset, 2);
      expect(selected.selectionBaseOffset, 1);
      expect(selected.selectionExtentOffset, 2);
      expect(extended.cursorOffset, 3);
      expect(extended.selectionBaseOffset, 1);
      expect(extended.selectionExtentOffset, 3);
    });

    test(
      'offset-state command wrappers forward stored cursor and selection',
      () {
        final snapshot = TextOffsetStateSnapshot.selection(
          baseOffset: 1,
          extentOffset: 1,
          cursorOffset: 1,
          preserveCollapsedSelection: true,
        );
        final result = snapshot.moveByCharacterCommand(
          'alpha'.split(''),
          forward: true,
          clearSelection: false,
        );

        expect(result.cursorOffset, 2);
        expect(result.selectionBaseOffset, 1);
        expect(result.selectionExtentOffset, 1);
      },
    );

    test('moves by word while clearing an existing selection', () {
      bool isWord(String grapheme) => grapheme != ' ';

      final result = commands.moveCursorByWord(
        'alpha beta'.split(''),
        cursorOffset: 6,
        selectionBaseOffset: 0,
        selectionExtentOffset: 6,
        forward: false,
        isWord: isWord,
        clearSelection: true,
      );

      expect(result.cursorOffset, 0);
      expect(result.selectionBaseOffset, isNull);
      expect(result.selectionExtentOffset, isNull);
    });

    test(
      'moves to document boundaries without dropping selection by default',
      () {
        final result = commands.moveCursorToDocumentBoundary(
          'alpha'.split(''),
          cursorOffset: 1,
          selectionBaseOffset: 0,
          selectionExtentOffset: 2,
          forward: true,
          clearSelection: false,
        );

        expect(result.cursorOffset, 5);
        expect(result.selectionBaseOffset, 0);
        expect(result.selectionExtentOffset, 2);
      },
    );

    test('moves by wrapped visual lines and visual line boundaries', () {
      final document = TextDocument(text: 'abcdef');
      final lowerState = EditorState(line: 0, column: 5);
      final upperState = EditorState(line: 0, column: 1);
      final view = TextView(width: 4, height: 4, softWrap: true);

      final up = commands.moveCursorByVisualLine(
        document,
        lowerState,
        view,
        cursorOffset: 5,
        lineDelta: -1,
        desiredDisplayColumn: 1,
      );
      final start = commands.moveCursorToVisualLineBoundary(
        document,
        lowerState,
        view,
        cursorOffset: 5,
        end: false,
      );
      final end = commands.moveCursorToVisualLineBoundary(
        document,
        upperState,
        view,
        cursorOffset: 1,
        end: true,
      );

      expect(up.cursorOffset, 1);
      expect(start.cursorOffset, 4);
      expect(end.cursorOffset, 4);
    });

    test('transforms the selection or current line', () {
      final selected = commands.transformSelectionOrLine(
        'alpha\nbeta'.split(''),
        cursorOffset: 5,
        lineStartOffset: 6,
        lineEndOffset: 10,
        selectionBaseOffset: 0,
        selectionExtentOffset: 5,
        transform: (text) => text.toUpperCase(),
      );
      final line = commands.transformSelectionOrLine(
        'alpha\nbeta'.split(''),
        cursorOffset: 2,
        lineStartOffset: 0,
        lineEndOffset: 5,
        transform: (text) => text.toUpperCase(),
      );

      expect(selected.graphemes.join(), 'ALPHA\nbeta');
      expect(selected.cursorOffset, 5);
      expect(selected.selectionBaseOffset, 0);
      expect(selected.selectionExtentOffset, 5);

      expect(line.graphemes.join(), 'ALPHA\nbeta');
      expect(line.cursorOffset, 2);
      expect(line.selectionBaseOffset, isNull);
      expect(line.selectionExtentOffset, isNull);
    });

    test('transforms the next word or falls back to the previous word', () {
      bool isWord(String grapheme) => grapheme != ' ';

      final forward = commands.transformWordOrAdjacent(
        'hello world'.split(''),
        cursorOffset: 0,
        isWord: isWord,
        transform: (text) => text.toUpperCase(),
      );
      final previous = commands.transformWordOrAdjacent(
        'hello world'.split(''),
        cursorOffset: 11,
        isWord: isWord,
        transform: (text) => text.toUpperCase(),
      );

      expect(forward.graphemes.join(), 'HELLO world');
      expect(forward.cursorOffset, 5);
      expect(previous.graphemes.join(), 'hello WORLD');
      expect(previous.cursorOffset, 11);
    });

    test('offset-state wrapper transforms the current or adjacent word', () {
      bool isWord(String grapheme) => grapheme != ' ';

      final result = TextOffsetStateSnapshot.collapsed(cursorOffset: 0)
          .transformWordOrAdjacentCommand(
            'hello world'.split(''),
            isWord: isWord,
            transform: (text) => text.toUpperCase(),
          );

      expect(result.graphemes.join(), 'HELLO world');
      expect(result.cursorOffset, 5);
    });

    test('inserts auto pairs and skips matching closing delimiters', () {
      final inserted = TextOffsetStateSnapshot.collapsed(cursorOffset: 5)
          .insertAutoPairCommand(
            'print'.split(''),
            opening: const ['('],
            closing: const [')'],
          );
      final skipped = TextOffsetStateSnapshot.collapsed(
        cursorOffset: 6,
      ).skipClosingDelimiterCommand('print()'.split(''), closing: const [')']);

      expect(inserted.graphemes.join(), 'print()');
      expect(inserted.cursorOffset, 6);
      expect(skipped.cursorOffset, 7);
    });

    test('deletes surrounding pairs and toggles delimited segments', () {
      final deleted = TextOffsetStateSnapshot.collapsed(cursorOffset: 6)
          .deleteSurroundingPairCommand(
            'print()'.split(''),
            surroundPairs: const {'(': ')'},
          );
      final toggled =
          TextOffsetStateSnapshot.selection(
            baseOffset: 0,
            extentOffset: 10,
            cursorOffset: 10,
          ).toggleDelimitedSegmentCommand(
            'alpha\nbeta\ngamma'.split(''),
            rangeStartOffset: 0,
            rangeEndOffset: 10,
            startDelimiter: '/*',
            endDelimiter: '*/',
          );

      expect(deleted.graphemes.join(), 'print');
      expect(deleted.cursorOffset, 5);
      expect(toggled.graphemes.join(), '/* alpha\nbeta */\ngamma');
      expect(toggled.selectionBaseOffset, 0);
      expect(toggled.selectionExtentOffset, 16);
    });

    test(
      'inserts indented newlines and replaces closing-brace spacer text',
      () {
        final preservedIndent =
            TextOffsetStateSnapshot.collapsed(
              cursorOffset: 7,
            ).insertIndentedNewlineCommand(
              '  alpha'.split(''),
              baseIndent: const [' ', ' '],
            );
        final blockIndented =
            TextOffsetStateSnapshot.collapsed(
              cursorOffset: 12,
            ).insertIndentedNewlineCommand(
              'if (ready) {   }'.split(''),
              baseIndent: const <String>[],
              additionalIndent: const [' ', ' '],
              trailingSuffix: const ['\n'],
              trailingSuffixReplaceCount: 3,
            );

        expect(preservedIndent.graphemes.join(), '  alpha\n  ');
        expect(preservedIndent.cursorOffset, 10);
        expect(blockIndented.graphemes.join(), 'if (ready) {\n  \n}');
        expect(blockIndented.cursorOffset, 15);
      },
    );

    test('wraps the normalized selection and preserves the inner range', () {
      final result = commands.wrapSelection(
        'alpha beta'.split(''),
        cursorOffset: 10,
        selectionBaseOffset: 10,
        selectionExtentOffset: 6,
        before: '('.split(''),
        after: ')'.split(''),
      );

      expect(result.graphemes.join(), 'alpha (beta)');
      expect(result.cursorOffset, 11);
      expect(result.selectionBaseOffset, 7);
      expect(result.selectionExtentOffset, 11);
    });

    test('unwraps a matching pair around the normalized selection', () {
      final result = commands.unwrapSelection(
        'alpha (beta)'.split(''),
        cursorOffset: 11,
        selectionBaseOffset: 11,
        selectionExtentOffset: 7,
        surroundPairs: const {'(': ')'},
      );

      expect(result.graphemes.join(), 'alpha beta');
      expect(result.cursorOffset, 10);
      expect(result.selectionBaseOffset, 6);
      expect(result.selectionExtentOffset, 10);
    });

    test('toggles a line prefix for the cursor line or selection', () {
      final singleLine = commands.toggleLinePrefix(
        const ['alpha', 'beta'],
        cursor: const TextPosition(line: 0, column: 2),
        prefix: '>',
      );
      final selectedLines = commands.toggleLinePrefix(
        const ['alpha', 'beta'],
        cursor: const TextPosition(line: 1, column: 4),
        selectionBase: const TextPosition(line: 0, column: 0),
        selectionExtent: const TextPosition(line: 1, column: 4),
        prefix: '//',
      );

      expect(singleLine.lines, const ['> alpha', 'beta']);
      expect(singleLine.cursor, const TextPosition(line: 0, column: 4));
      expect(singleLine.selectionBase, isNull);
      expect(singleLine.selectionExtent, isNull);

      expect(selectedLines.lines, const ['// alpha', '// beta']);
      expect(selectedLines.cursor, const TextPosition(line: 1, column: 7));
      expect(
        selectedLines.selectionBase,
        const TextPosition(line: 0, column: 0),
      );
      expect(
        selectedLines.selectionExtent,
        const TextPosition(line: 1, column: 7),
      );
    });

    test('line-state command wrappers forward stored cursor and selection', () {
      final snapshot = TextLineStateSnapshot.selection(
        base: const TextPosition(line: 0, column: 0),
        extent: const TextPosition(line: 1, column: 4),
        cursor: const TextPosition(line: 1, column: 4),
      );
      final result = snapshot.toggleLinePrefixCommand(const [
        'alpha',
        'beta',
      ], prefix: '//');

      expect(result.lines, const ['// alpha', '// beta']);
      expect(result.cursor, const TextPosition(line: 1, column: 7));
      expect(result.selectionBase, const TextPosition(line: 0, column: 0));
      expect(result.selectionExtent, const TextPosition(line: 1, column: 7));
    });

    test('toggles numbered list prefixes for selected lines', () {
      final added = commands.toggleNumberedList(
        const ['alpha', 'beta'],
        cursor: const TextPosition(line: 1, column: 4),
        selectionBase: const TextPosition(line: 0, column: 0),
        selectionExtent: const TextPosition(line: 1, column: 4),
      );
      final removed = commands.toggleNumberedList(
        const ['1. alpha', '2. beta'],
        cursor: const TextPosition(line: 1, column: 7),
        selectionBase: const TextPosition(line: 0, column: 0),
        selectionExtent: const TextPosition(line: 1, column: 7),
      );

      expect(added.lines, const ['1. alpha', '2. beta']);
      expect(added.cursor, const TextPosition(line: 1, column: 7));
      expect(added.selectionBase, const TextPosition(line: 0, column: 0));
      expect(added.selectionExtent, const TextPosition(line: 1, column: 7));

      expect(removed.lines, const ['alpha', 'beta']);
      expect(removed.cursor, const TextPosition(line: 1, column: 4));
      expect(removed.selectionBase, const TextPosition(line: 0, column: 0));
      expect(removed.selectionExtent, const TextPosition(line: 1, column: 4));
    });

    test('renumbers numbered list items and adjusts selection', () {
      final result = commands.renumberNumberedList(
        const ['9. alpha', '10. beta'],
        cursor: const TextPosition(line: 1, column: 8),
        selectionBase: const TextPosition(line: 0, column: 0),
        selectionExtent: const TextPosition(line: 1, column: 8),
      );

      expect(result.lines, const ['1. alpha', '2. beta']);
      expect(result.cursor, const TextPosition(line: 1, column: 7));
      expect(result.selectionBase, const TextPosition(line: 0, column: 0));
      expect(result.selectionExtent, const TextPosition(line: 1, column: 7));
    });

    test('toggles heading prefixes and preserves the selection range', () {
      final added = commands.toggleHeadingPrefix(
        const ['alpha', '## beta'],
        cursor: const TextPosition(line: 1, column: 7),
        selectionBase: const TextPosition(line: 0, column: 0),
        selectionExtent: const TextPosition(line: 1, column: 7),
      );
      final removed = commands.toggleHeadingPrefix(
        const ['# alpha', '# beta'],
        cursor: const TextPosition(line: 1, column: 6),
        selectionBase: const TextPosition(line: 0, column: 0),
        selectionExtent: const TextPosition(line: 1, column: 6),
      );

      expect(added.lines, const ['# alpha', '# beta']);
      expect(added.cursor, const TextPosition(line: 1, column: 6));
      expect(added.selectionBase, const TextPosition(line: 0, column: 0));
      expect(added.selectionExtent, const TextPosition(line: 1, column: 6));

      expect(removed.lines, const ['alpha', 'beta']);
      expect(removed.cursor, const TextPosition(line: 1, column: 4));
      expect(removed.selectionBase, const TextPosition(line: 0, column: 0));
      expect(removed.selectionExtent, const TextPosition(line: 1, column: 4));
    });

    test('toggles checklist state without shifting cursor or selection', () {
      final result = commands.toggleChecklistState(
        const ['- [ ] alpha', '- [x] beta'],
        cursor: const TextPosition(line: 1, column: 10),
        selectionBase: const TextPosition(line: 0, column: 0),
        selectionExtent: const TextPosition(line: 1, column: 10),
      );

      expect(result.lines, const ['- [x] alpha', '- [x] beta']);
      expect(result.cursor, const TextPosition(line: 1, column: 10));
      expect(result.selectionBase, const TextPosition(line: 0, column: 0));
      expect(result.selectionExtent, const TextPosition(line: 1, column: 10));
    });

    test('moves a selected line block up and down', () {
      final up = commands.moveSelectedLines(
        const ['alpha', 'beta', 'gamma', 'delta'],
        cursor: const TextPosition(line: 2, column: 5),
        selectionBase: const TextPosition(line: 1, column: 0),
        selectionExtent: const TextPosition(line: 2, column: 5),
        direction: -1,
      );
      final down = commands.moveSelectedLines(
        up.lines,
        cursor: up.cursor,
        selectionBase: up.selectionBase,
        selectionExtent: up.selectionExtent,
        direction: 1,
      );

      expect(up.lines, const ['beta', 'gamma', 'alpha', 'delta']);
      expect(up.cursor, const TextPosition(line: 1, column: 5));
      expect(up.selectionBase, const TextPosition(line: 0, column: 0));
      expect(up.selectionExtent, const TextPosition(line: 1, column: 5));

      expect(down.lines, const ['alpha', 'beta', 'gamma', 'delta']);
      expect(down.cursor, const TextPosition(line: 2, column: 5));
      expect(down.selectionBase, const TextPosition(line: 1, column: 0));
      expect(down.selectionExtent, const TextPosition(line: 2, column: 5));
    });

    test('duplicates a selected block above and below', () {
      final above = commands.duplicateSelectedLinesAbove(
        const ['alpha', 'beta', 'gamma'],
        cursor: const TextPosition(line: 2, column: 5),
        selectionBase: const TextPosition(line: 1, column: 0),
        selectionExtent: const TextPosition(line: 2, column: 5),
      );
      final below = commands.duplicateSelectedLinesBelow(const [
        'alpha',
        'beta',
        'gamma',
      ], cursor: const TextPosition(line: 1, column: 2));

      expect(above.lines, const ['alpha', 'beta', 'gamma', 'beta', 'gamma']);
      expect(above.cursor, const TextPosition(line: 2, column: 5));
      expect(above.selectionBase, const TextPosition(line: 1, column: 0));
      expect(above.selectionExtent, const TextPosition(line: 2, column: 5));

      expect(below.lines, const ['alpha', 'beta', 'beta', 'gamma']);
      expect(below.cursor, const TextPosition(line: 2, column: 2));
      expect(below.selectionBase, isNull);
      expect(below.selectionExtent, isNull);
    });
  });
}
