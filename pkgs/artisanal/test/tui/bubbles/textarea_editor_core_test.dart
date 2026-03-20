import 'package:artisanal/src/tui/bubbles/textarea.dart';
import 'package:artisanal/src/tui/editor_core/editor_core.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('TextAreaModel editor core bridge', () {
    test('keeps document and editor state in sync', () {
      final textarea = TextAreaModel(width: 6, height: 3, softWrap: true);
      textarea.setValue('alpha\nbeta');
      textarea.setSelection(
        baseLine: 0,
        baseColumn: 1,
        extentLine: 1,
        extentColumn: 2,
      );

      expect(textarea.document.text, 'alpha\nbeta');
      expect(textarea.editorState.line, 1);
      expect(textarea.editorState.column, 2);
      expect(textarea.editorState.hasSelection, isTrue);
    });

    test('wrapped view still renders through textarea view', () {
      final textarea = TextAreaModel(width: 6, height: 3, softWrap: true);
      textarea.setValue('abcdef');
      textarea.setCursor(0, 5);

      final rendered = textarea.view().toString();

      expect(rendered.split('\n').length, greaterThanOrEqualTo(2));
      expect(rendered, contains('a'));
      expect(rendered, contains('f'));
    });

    test('viewported view follows the cursor in a short textarea', () {
      final textarea = TextAreaModel(width: 8, height: 2, softWrap: true);
      textarea.setValue('a\nb\nc\nd');
      textarea.setCursor(3, 1);

      final rendered = textarea.view().toString();

      expect(rendered, isNot(contains('1 ')));
      expect(rendered, contains('3 '));
      expect(rendered, contains('4 '));
    });

    test('setCursor preserves selection while moving editor core cursor', () {
      final textarea = TextAreaModel(width: 8, height: 3, softWrap: true);
      textarea.setValue('alpha\nbeta');
      textarea.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 4,
      );

      textarea.setCursor(0, 2);

      expect(textarea.selectionBase, (line: 0, column: 0));
      expect(textarea.selectionExtent, (line: 1, column: 4));
      expect(textarea.editorState.hasSelection, isTrue);
      expect(textarea.editorState.line, 0);
      expect(textarea.editorState.column, 2);
      expect(
        textarea.editorState.selection?.extent,
        const TextPosition(line: 1, column: 4),
      );
    });

    test('cursorStart preserves selection while moving to line start', () {
      final textarea = TextAreaModel(width: 8, height: 3, softWrap: true);
      textarea.setValue('alpha\nbeta');
      textarea.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 1,
        extentColumn: 4,
      );

      textarea.cursorStart();

      expect(textarea.selectionBase, (line: 0, column: 0));
      expect(textarea.selectionExtent, (line: 1, column: 4));
      expect(textarea.editorState.hasSelection, isTrue);
      expect(textarea.editorState.line, 1);
      expect(textarea.editorState.column, 0);
    });

    test('line navigation keys preserve selection while moving cursor', () {
      final textarea = TextAreaModel(width: 8, height: 3, softWrap: true);
      textarea.setValue('alpha\nbeta\ngamma');
      textarea.setSelection(
        baseLine: 0,
        baseColumn: 0,
        extentLine: 2,
        extentColumn: 5,
      );
      textarea.setCursor(1, 2);

      final (down, _) = textarea.update(const KeyMsg(Key(KeyType.down)));
      final (home, _) = down.update(const KeyMsg(Key(KeyType.home)));

      expect(home.selectionBase, (line: 0, column: 0));
      expect(home.selectionExtent, (line: 2, column: 5));
      expect(home.editorState.hasSelection, isTrue);
      expect(home.editorState.line, 2);
      expect(home.editorState.column, 0);
    });
  });
}
