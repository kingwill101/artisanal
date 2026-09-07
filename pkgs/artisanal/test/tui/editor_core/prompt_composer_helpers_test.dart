import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('placeholder ranges', () {
    test('expands a single placeholder', () {
      const display = 'Say [Pasted ~3 lines] please';
      const placeholder = '[Pasted ~3 lines]';
      final start = display.indexOf(placeholder);
      expect(
        expandPlaceholderRanges(display, [
          TrackedPlaceholderRange(
            startOffset: start,
            endOffset: start + placeholder.length,
            displayText: placeholder,
            fullText: 'line1\nline2\nline3',
          ),
        ]),
        'Say line1\nline2\nline3 please',
      );
    });

    test('expands multiple placeholders without offset drift', () {
      const text = 'A X B Y';
      expect(
        expandPlaceholderRanges(text, [
          const TrackedPlaceholderRange(
            startOffset: 2,
            endOffset: 3,
            displayText: 'X',
            fullText: 'xxx',
          ),
          const TrackedPlaceholderRange(
            startOffset: 6,
            endOffset: 7,
            displayText: 'Y',
            fullText: 'yyy',
          ),
        ]),
        'A xxx B yyy',
      );
    });

    test('expands grapheme-coordinate ranges after emoji', () {
      expect(
        expandPlaceholderRanges('😀 [Pasted]', const [
          TrackedPlaceholderRange(
            startOffset: 2,
            endOffset: 10,
            displayText: '[Pasted]',
            fullText: 'complete text',
          ),
        ]),
        '😀 complete text',
      );
    });

    test('skips ranges whose display text drifted', () {
      expect(
        expandPlaceholderRanges('hello world', [
          const TrackedPlaceholderRange(
            startOffset: 0,
            endOffset: 5,
            displayText: 'HELLO',
            fullText: 'expanded',
          ),
        ]),
        'hello world',
      );
    });
  });

  group('PlaceholderTracker', () {
    test('insertions shift later ranges', () {
      final tracker = PlaceholderTracker()
        ..track(
          const TrackedPlaceholderRange(
            startOffset: 4,
            endOffset: 8,
            displayText: 'ph',
            fullText: 'full',
          ),
        )
        ..applyInsertion(offset: 0, length: 3);
      expect(tracker.ranges.single.startOffset, 7);
      expect(tracker.ranges.single.endOffset, 11);
    });

    test('deletions drop contained ranges and shrink overlaps', () {
      final tracker = PlaceholderTracker()
        ..track(
          const TrackedPlaceholderRange(
            startOffset: 2,
            endOffset: 4,
            displayText: 'ab',
            fullText: 'full',
          ),
        )
        ..track(
          const TrackedPlaceholderRange(
            startOffset: 10,
            endOffset: 14,
            displayText: 'cd',
            fullText: 'full',
          ),
        );
      tracker.applyDeletion(startOffset: 0, endOffset: 6);
      expect(tracker.ranges, hasLength(1));
      expect(tracker.ranges.single.startOffset, 4);
    });
  });

  group('normalizePromptContent', () {
    test('strips one trailing newline from single-line prompts', () {
      expect(normalizePromptContent('hello\n'), 'hello');
      expect(normalizePromptContent('hello\r\n'), 'hello');
    });

    test('preserves multiline prompts ending with a newline', () {
      expect(normalizePromptContent('hello\nworld\n'), 'hello\nworld\n');
    });

    test('leaves other content alone', () {
      expect(normalizePromptContent('hello'), 'hello');
      expect(normalizePromptContent(''), '');
    });
  });

  group('resolveExternalEditorExecutable', () {
    test('prefers VISUAL over EDITOR over fallback', () {
      expect(
        resolveExternalEditorExecutable({
          'VISUAL': 'code --wait',
          'EDITOR': 'vim',
        }),
        'code',
      );
      expect(resolveExternalEditorExecutable({'EDITOR': 'hx'}), 'hx');
      expect(resolveExternalEditorExecutable({}), 'vi');
      expect(resolveExternalEditorExecutable({}, isWindows: true), 'notepad');
      expect(resolveExternalEditorExecutable({}, allowFallback: false), isNull);
    });
  });

  group('editor selection ingestion', () {
    test('selection key is stable and empty for null', () {
      expect(editorSelectionKey(null), '');
      const selection = EditorSelection(
        filePath: '/tmp/a.ts',
        source: 'zed',
        ranges: [
          EditorSelectionRange(
            text: 'foo',
            start: EditorSelectionPosition(line: 1, character: 1),
            end: EditorSelectionPosition(line: 1, character: 4),
          ),
        ],
      );
      expect(editorSelectionKey(selection), editorSelectionKey(selection));
    });

    test('wire positions resolve to clamped document offsets', () {
      final document = TextDocument(text: 'ab\ncd');
      const range = EditorSelectionRange(
        text: 'b\nc',
        start: EditorSelectionPosition(line: 1, character: 2),
        end: EditorSelectionPosition(line: 2, character: 2),
      );
      final resolved = resolveEditorSelectionRange(document, range);
      expect(resolved.startOffset, 1);
      expect(resolved.endOffset, 4);
      expect(
        document.textInRange(
          startOffset: resolved.startOffset,
          endOffset: resolved.endOffset,
        ),
        'b\nc',
      );
    });

    test('out-of-range wire positions clamp instead of throwing', () {
      final document = TextDocument(text: 'hi');
      const range = EditorSelectionRange(
        text: '',
        start: EditorSelectionPosition(line: 99, character: 99),
        end: EditorSelectionPosition(line: 1, character: 1),
      );
      final resolved = resolveEditorSelectionRange(document, range);
      expect(resolved.startOffset, 0);
      expect(resolved.endOffset, document.length);
    });

    test('labels and context shape', () {
      const single = EditorSelectionRange(
        text: 'foo',
        start: EditorSelectionPosition(line: 3, character: 1),
        end: EditorSelectionPosition(line: 3, character: 4),
      );
      expect(editorSelectionRangeLabel(single), '#3');
      const multi = EditorSelectionRange(
        text: 'x',
        start: EditorSelectionPosition(line: 2, character: 1),
        end: EditorSelectionPosition(line: 5, character: 1),
      );
      expect(editorSelectionRangeLabel(multi), '#2-5');
      const collapsed = EditorSelectionRange(
        text: '',
        start: EditorSelectionPosition(line: 1, character: 1),
        end: EditorSelectionPosition(line: 1, character: 1),
      );
      expect(editorSelectionRangeLabel(collapsed), isNull);

      const selection = EditorSelection(filePath: 'src/a.ts', ranges: [single]);
      final context = formatEditorSelectionContext(selection);
      expect(context, contains('src/a.ts'));
      expect(context, contains('#3'));
      expect(context, contains('system-reminder'));
    });
  });
}
