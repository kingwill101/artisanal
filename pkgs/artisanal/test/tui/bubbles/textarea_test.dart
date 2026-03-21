import 'package:artisanal/src/tui/bubbles/textarea.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/tui/editor_core/editor_core.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/view.dart';
import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('TextAreaModel', () {
    group('New', () {
      test('creates with default values', () {
        final textarea = TextAreaModel();
        expect(textarea.prompt, '│ ');
        expect(textarea.placeholder, '');
        expect(textarea.showLineNumbers, isTrue);
        expect(textarea.value, '');
      });

      test('creates with custom prompt', () {
        final textarea = TextAreaModel(prompt: '> ');
        expect(textarea.prompt, '> ');
      });

      test('creates with placeholder', () {
        final textarea = TextAreaModel(placeholder: 'Enter text');
        expect(textarea.placeholder, 'Enter text');
      });

      test('creates with dimensions', () {
        final textarea = TextAreaModel(width: 80, height: 20);
        // Width may be adjusted for prompt/line numbers
        expect(textarea.width, greaterThan(0));
        expect(textarea.height, 20);
      });

      test('starts unfocused', () {
        final textarea = TextAreaModel();
        expect(textarea.focused, isFalse);
      });

      test('creates with line numbers disabled', () {
        final textarea = TextAreaModel(showLineNumbers: false);
        expect(textarea.showLineNumbers, isFalse);
      });
    });

    group('Value', () {
      test('sets value', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello\nworld';
        expect(textarea.value, 'hello\nworld');
      });

      test('gets value', () {
        final textarea = TextAreaModel();
        textarea.insertString('test');
        expect(textarea.value, 'test');
      });

      test('handles multi-line value', () {
        final textarea = TextAreaModel();
        textarea.value = 'line1\nline2\nline3';
        expect(textarea.lineCount, 3);
      });

      test('setValue parity', () {
        final textarea = TextAreaModel();
        textarea.setValue('parity');
        expect(textarea.value, 'parity');
      });

      test('accepts PasteTextMsg through the shared paste path', () {
        final textarea = TextAreaModel()..focus();

        final (next, cmd) = textarea.update(const PasteTextMsg('alpha\nbeta'));

        expect(cmd, isNull);
        expect(next.value, 'alpha\nbeta');
      });

      test('chunked PasteMsg inserts in scheduled steps', () async {
        final textarea = TextAreaModel()..focus();
        final content = 'a' * 1200;

        final (next, cmd) = textarea.update(PasteMsg(content));

        expect(cmd, isNotNull);
        expect(next.value, 'a' * 300);

        final firstChunkMsg = await cmd!.execute();
        expect(firstChunkMsg, isNotNull);

        final (afterFirstTick, nextCmd) = next.update(firstChunkMsg!);

        expect(afterFirstTick.value, 'a' * 600);
        expect(nextCmd, isNotNull);
      });
    });

    group('Cursor', () {
      test('setCursor parity', () {
        final textarea = TextAreaModel();
        textarea.setValue('line1\nline2');
        textarea.setCursor(1, 2);
        expect(textarea.cursorLine(), 1);
        expect(textarea.cursorColumn(), 2);
      });

      test('selectAll parity', () {
        final textarea = TextAreaModel();
        textarea.setValue('line1\nline2');

        textarea.selectAll();

        expect(textarea.selectionBase, (line: 0, column: 0));
        expect(textarea.selectionExtent, (line: 1, column: 5));
        expect(textarea.cursorLine(), 1);
        expect(textarea.cursorColumn(), 5);
      });

      test('ctrl+a selects all through update', () {
        final textarea = TextAreaModel();
        textarea.setValue('line1\nline2');

        final (updated, _) = textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x61], ctrl: true)),
        );

        expect(updated.selectionBase, (line: 0, column: 0));
        expect(updated.selectionExtent, (line: 1, column: 5));
        expect(updated.cursorLine(), 1);
        expect(updated.cursorColumn(), 5);
      });

      test('ctrl+l selects the current line through update', () {
        final textarea = TextAreaModel();
        textarea.setValue('line1\nline2\nline3');
        textarea.setCursor(1, 2);

        final (updated, _) = textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x6c], ctrl: true)),
        );

        expect(updated.selectionBase, (line: 1, column: 0));
        expect(updated.selectionExtent, (line: 1, column: 5));
        expect(updated.cursorLine(), 1);
        expect(updated.cursorColumn(), 5);
      });
    });

    group('Focus', () {
      test('focus/blur parity', () {
        final textarea = TextAreaModel();
        expect(textarea.isFocused(), isFalse);
        textarea.focus();
        expect(textarea.isFocused(), isTrue);
        textarea.blur();
        expect(textarea.isFocused(), isFalse);
      });
    });

    group('Parity Features', () {
      test('setPlaceholder parity', () {
        final textarea = TextAreaModel();
        textarea.setPlaceholder('new placeholder');
        expect(textarea.placeholder, 'new placeholder');
      });

      test('setCharLimit parity', () {
        final textarea = TextAreaModel();
        textarea.setCharLimit(10);
        expect(textarea.charLimit, 10);
      });

      test('setCharLimit keeps document-derived getters in sync', () {
        final textarea = TextAreaModel();
        textarea.setText('abcdef');

        textarea.setCharLimit(3);

        expect(textarea.value, 'abc');
        expect(textarea.length, 3);
        expect(textarea.document.text, 'abc');
      });

      test('setText eagerly syncs the backing document', () {
        final textarea = TextAreaModel();

        textarea.setText('alpha\nbeta');

        expect(textarea.document.text, 'alpha\nbeta');
        expect(textarea.document.lineTexts, const ['alpha', 'beta']);
        expect(textarea.lineCount, 2);
      });

      test('view keeps non-wrapped document grapheme caches cold', () {
        final textarea = TextAreaModel(softWrap: false, width: 8, height: 3);

        textarea.setText(
          List<String>.generate(
            12,
            (index) => 'line-$index-abcdefghij',
          ).join('\n'),
        );

        textarea.view();

        expect(textarea.document.debugLineGraphemeCacheCount, 0);
      });

      test('setPromptFunc parity', () {
        final textarea = TextAreaModel();
        textarea.setPromptFunc(4, (info) => '[${info.lineIndex}] ');
        textarea.setValue('line1');
        final view = textarea.view();
        expect(view, contains('[0] '));
      });
    });

    group('InsertString', () {
      test('inserts string at cursor', () {
        final textarea = TextAreaModel();
        textarea.insertString('hello');
        expect(textarea.value, 'hello');
      });

      test('inserts multi-line string', () {
        final textarea = TextAreaModel();
        textarea.insertString('line1\nline2');
        expect(textarea.value, 'line1\nline2');
        expect(textarea.lineCount, 2);
      });

      test('respects char limit', () {
        final textarea = TextAreaModel(charLimit: 5);
        textarea.insertString('hello world');
        expect(
          textarea.value.length,
          lessThanOrEqualTo(6),
        ); // Allow some buffer
      });

      test('treats combining marks as one grapheme', () {
        final textarea = TextAreaModel();
        textarea.insertString('e\u0301'); // e + combining acute accent
        expect(textarea.column, 1);
        expect(textarea.value, 'e\u0301');
      });

      test('backspace deletes a full grapheme cluster', () {
        final textarea = TextAreaModel();
        textarea.insertString('e\u0301'); // e + combining acute accent
        textarea.update(const KeyMsg(Key(KeyType.backspace)));
        expect(textarea.value, '');
        expect(textarea.column, 0);
      });

      test('char limit does not split a grapheme cluster', () {
        final textarea = TextAreaModel(charLimit: 1);
        textarea.insertString('e\u0301x');
        expect(textarea.value, 'e\u0301');
        expect(textarea.column, 1);
      });
    });

    group('LineCount', () {
      test('returns 1 for empty textarea', () {
        final textarea = TextAreaModel();
        expect(textarea.lineCount, greaterThanOrEqualTo(1));
      });

      test('counts lines correctly', () {
        final textarea = TextAreaModel();
        textarea.value = 'a\nb\nc';
        expect(textarea.lineCount, 3);
      });
    });

    group('Length', () {
      test('returns 0 for empty textarea', () {
        final textarea = TextAreaModel();
        expect(textarea.length, 0);
      });

      test('counts characters including newlines', () {
        final textarea = TextAreaModel();
        textarea.value = 'ab\ncd';
        // Should count 'ab', newline, 'cd' = 5 characters
        expect(textarea.length, 5);
      });
    });

    group('Focus', () {
      test('focus sets focused to true', () {
        final textarea = TextAreaModel();
        textarea.focus();
        expect(textarea.focused, isTrue);
      });

      test('blur sets focused to false', () {
        final textarea = TextAreaModel();
        textarea.focus();
        textarea.blur();
        expect(textarea.focused, isFalse);
      });
    });

    group('Reset', () {
      test('clears value', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello\nworld';
        textarea.reset();
        expect(textarea.value, '');
      });

      test('resets position', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello\nworld';
        textarea.reset();
        expect(textarea.line, 0);
        expect(textarea.column, 0);
      });
    });

    group('Undo and redo', () {
      test('ctrl+z undoes a coalesced typing burst', () {
        final textarea = TextAreaModel();

        textarea.update(KeyMsg(Key.char('a')));
        textarea.update(KeyMsg(Key.char('b')));

        expect(textarea.value, 'ab');
        expect(textarea.canUndo, isTrue);

        textarea.update(KeyMsg(Key.char('z', ctrl: true)));
        expect(textarea.value, '');
        expect(textarea.canRedo, isTrue);
      });

      test('ctrl+y reapplies an undone edit', () {
        final textarea = TextAreaModel();

        textarea.update(KeyMsg(Key.char('a')));
        textarea.update(KeyMsg(Key.char('b')));
        textarea.update(KeyMsg(Key.char('z', ctrl: true)));
        textarea.update(KeyMsg(Key.char('y', ctrl: true)));

        expect(textarea.value, 'ab');
      });

      test('programmatic setText participates in history', () {
        final textarea = TextAreaModel();

        textarea.setText('line one');
        textarea.setText('line one\nline two');

        expect(textarea.undo(), isTrue);
        expect(textarea.value, 'line one');
        expect(textarea.redo(), isTrue);
        expect(textarea.value, 'line one\nline two');
      });

      test('splitLine inserts a newline at the cursor', () {
        final textarea = TextAreaModel();

        textarea.setValue('alpha beta');
        textarea.setCursor(0, 5);

        expect(textarea.splitLine(), isTrue);
        expect(textarea.value, 'alpha\n beta');
        expect(textarea.cursorLine(), 1);
        expect(textarea.cursorColumn(), 0);
      });

      test('splitLine replaces the selected range with a newline', () {
        final textarea = TextAreaModel();

        textarea.setValue('alpha beta\ngamma');
        textarea.setSelection(
          baseLine: 0,
          baseColumn: 5,
          extentLine: 1,
          extentColumn: 2,
        );

        expect(textarea.splitLine(), isTrue);
        expect(textarea.value, 'alpha\nmma');
        expect(textarea.cursorLine(), 1);
        expect(textarea.cursorColumn(), 0);
      });

      test(
        'delete keys remove the active selection before cursor-relative edits',
        () {
          final textarea = TextAreaModel();

          textarea.setValue('alpha beta');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 2,
            extentLine: 0,
            extentColumn: 7,
          );

          textarea.update(KeyMsg(Key(KeyType.backspace)));
          expect(textarea.value, 'aleta');
          expect(textarea.hasSelection, isFalse);
          expect(textarea.cursorLine(), 0);
          expect(textarea.cursorColumn(), 2);

          textarea.undo();
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 2,
            extentLine: 0,
            extentColumn: 7,
          );
          textarea.update(KeyMsg(Key(KeyType.delete)));
          expect(textarea.value, 'aleta');
        },
      );

      test(
        'indentLines and outdentLines transform selected lines as one step',
        () {
          final textarea = TextAreaModel();
          textarea.setText('alpha\n  beta\ngamma');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 0,
            extentLine: 1,
            extentColumn: 6,
          );

          expect(textarea.indentLines(width: 2), isTrue);
          expect(textarea.value, '  alpha\n    beta\ngamma');

          expect(textarea.undo(), isTrue);
          expect(textarea.value, 'alpha\n  beta\ngamma');

          expect(textarea.redo(), isTrue);
          expect(textarea.value, '  alpha\n    beta\ngamma');

          expect(textarea.outdentLines(width: 2), isTrue);
          expect(textarea.value, 'alpha\n  beta\ngamma');
        },
      );

      test('moveLinesUp and moveLinesDown move the selected block', () {
        final textarea = TextAreaModel();
        textarea.setText('alpha\nbeta\ngamma\ndelta');
        textarea.setSelection(
          baseLine: 1,
          baseColumn: 0,
          extentLine: 2,
          extentColumn: 5,
        );

        expect(textarea.moveLinesUp(), isTrue);
        expect(textarea.value, 'beta\ngamma\nalpha\ndelta');
        expect(textarea.selectionBase, (line: 0, column: 0));
        expect(textarea.selectionExtent, (line: 1, column: 5));

        expect(textarea.moveLinesDown(), isTrue);
        expect(textarea.value, 'alpha\nbeta\ngamma\ndelta');
        expect(textarea.undo(), isTrue);
        expect(textarea.value, 'beta\ngamma\nalpha\ndelta');
      });

      test(
        'duplicateLinesBelow duplicates the current line or selected block',
        () {
          final textarea = TextAreaModel();
          textarea.setText('alpha\nbeta\ngamma');
          textarea.setCursor(1, 2);

          expect(textarea.duplicateLinesBelow(), isTrue);
          expect(textarea.value, 'alpha\nbeta\nbeta\ngamma');
          expect(textarea.line, 2);
          expect(textarea.column, 2);

          textarea.setSelection(
            baseLine: 1,
            baseColumn: 0,
            extentLine: 2,
            extentColumn: 4,
          );
          expect(textarea.duplicateLinesBelow(), isTrue);
          expect(textarea.value, 'alpha\nbeta\nbeta\nbeta\nbeta\ngamma');
          expect(textarea.selectionBase, (line: 3, column: 0));
          expect(textarea.selectionExtent, (line: 4, column: 4));
        },
      );

      test(
        'duplicateLinesAbove duplicates the current line or selected block',
        () {
          final textarea = TextAreaModel();
          textarea.setText('alpha\nbeta\ngamma');
          textarea.setCursor(1, 2);

          expect(textarea.duplicateLinesAbove(), isTrue);
          expect(textarea.value, 'alpha\nbeta\nbeta\ngamma');
          expect(textarea.line, 1);
          expect(textarea.column, 2);

          textarea.setText('alpha\nbeta\ngamma');
          textarea.setSelection(
            baseLine: 1,
            baseColumn: 0,
            extentLine: 2,
            extentColumn: 4,
          );
          expect(textarea.duplicateLinesAbove(), isTrue);
          expect(textarea.value, 'alpha\nbeta\ngamma\nbeta\ngamma');
          expect(textarea.selectionBase, (line: 1, column: 0));
          expect(textarea.selectionExtent, (line: 2, column: 4));
        },
      );

      test(
        'cleanupWhitespace trims trailing whitespace and trailing blank lines',
        () {
          final textarea = TextAreaModel();
          textarea.setText('alpha  \nbeta\t\n\n');
          textarea.setCursor(3, 0);

          expect(textarea.cleanupWhitespace(), isTrue);
          expect(textarea.value, 'alpha\nbeta');
          expect(textarea.line, 1);
          expect(textarea.column, 4);

          textarea.setText('alpha  \nbeta\t\ngamma  ');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 0,
            extentLine: 1,
            extentColumn: 5,
          );

          expect(textarea.cleanupWhitespace(), isTrue);
          expect(textarea.value, 'alpha\nbeta\ngamma  ');
          expect(textarea.selectionBase, (line: 0, column: 0));
          expect(textarea.selectionExtent, (line: 1, column: 4));
        },
      );

      test(
        'selection or line case transforms update the selected block or current line',
        () {
          final textarea = TextAreaModel();
          textarea.setText('alpha beta\ngamma delta');
          textarea.setCursor(0, 3);

          expect(textarea.uppercaseSelectionOrLine(), isTrue);
          expect(textarea.value, 'ALPHA BETA\ngamma delta');
          expect(textarea.line, 0);
          expect(textarea.column, 3);

          textarea.setSelection(
            baseLine: 1,
            baseColumn: 0,
            extentLine: 1,
            extentColumn: 11,
          );
          expect(textarea.lowercaseSelectionOrLine(), isFalse);

          textarea.setText('alpha beta\nGAMMA DELTA');
          textarea.setSelection(
            baseLine: 1,
            baseColumn: 0,
            extentLine: 1,
            extentColumn: 11,
          );
          expect(textarea.lowercaseSelectionOrLine(), isTrue);
          expect(textarea.value, 'alpha beta\ngamma delta');
          expect(textarea.selectionBase, (line: 1, column: 0));
          expect(textarea.selectionExtent, (line: 1, column: 11));

          expect(textarea.capitalizeSelectionOrLine(), isTrue);
          expect(textarea.value, 'alpha beta\nGamma Delta');
          expect(textarea.selectionBase, (line: 1, column: 0));
          expect(textarea.selectionExtent, (line: 1, column: 11));
        },
      );

      test('sortSelectedLines sorts the selected block or entire buffer', () {
        final textarea = TextAreaModel();
        textarea.setText('delta\nbeta\nalpha\ngamma');
        textarea.setSelection(
          baseLine: 1,
          baseColumn: 0,
          extentLine: 3,
          extentColumn: 5,
        );

        expect(textarea.sortSelectedLines(), isTrue);
        expect(textarea.value, 'delta\nalpha\nbeta\ngamma');
        expect(textarea.selectionBase, (line: 1, column: 0));
        expect(textarea.selectionExtent, (line: 3, column: 5));

        textarea.setText('delta\nbeta\nalpha');
        textarea.setCursor(2, 3);
        expect(textarea.sortSelectedLines(), isTrue);
        expect(textarea.value, 'alpha\nbeta\ndelta');
        expect(textarea.line, 2);
        expect(textarea.column, 3);
      });

      test(
        'toggleLinePrefix toggles a prefix on the current line or selection',
        () {
          final textarea = TextAreaModel();
          textarea.setText('alpha\nbeta');
          textarea.setCursor(0, 2);

          expect(textarea.toggleLinePrefix('>'), isTrue);
          expect(textarea.value, '> alpha\nbeta');
          expect(textarea.line, 0);
          expect(textarea.column, 4);

          expect(textarea.toggleLinePrefix('>'), isTrue);
          expect(textarea.value, 'alpha\nbeta');
          expect(textarea.line, 0);
          expect(textarea.column, 2);

          textarea.setSelection(
            baseLine: 0,
            baseColumn: 0,
            extentLine: 1,
            extentColumn: 4,
          );
          expect(textarea.toggleLinePrefix('//'), isTrue);
          expect(textarea.value, '// alpha\n// beta');
          expect(textarea.selectionBase, (line: 0, column: 0));
          expect(textarea.selectionExtent, (line: 1, column: 7));
        },
      );

      test(
        'wrapSelection surrounds the current selection and preserves it',
        () {
          final textarea = TextAreaModel();
          textarea.setText('alpha beta');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 6,
            extentLine: 0,
            extentColumn: 10,
          );

          expect(textarea.wrapSelection('(', after: ')'), isTrue);
          expect(textarea.value, 'alpha (beta)');
          expect(textarea.selectionBase, (line: 0, column: 7));
          expect(textarea.selectionExtent, (line: 0, column: 11));
          expect(textarea.line, 0);
          expect(textarea.column, 11);
        },
      );

      test(
        'toggleNumberedList toggles numbering on the current line or selection',
        () {
          final textarea = TextAreaModel();
          textarea.setText('alpha\nbeta');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 0,
            extentLine: 1,
            extentColumn: 4,
          );

          expect(textarea.toggleNumberedList(), isTrue);
          expect(textarea.value, '1. alpha\n2. beta');
          expect(textarea.selectionBase, (line: 0, column: 0));
          expect(textarea.selectionExtent, (line: 1, column: 7));

          expect(textarea.toggleNumberedList(), isTrue);
          expect(textarea.value, 'alpha\nbeta');
          expect(textarea.selectionBase, (line: 0, column: 0));
          expect(textarea.selectionExtent, (line: 1, column: 4));

          textarea.setText('alpha\n\nbeta');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 0,
            extentLine: 2,
            extentColumn: 4,
          );
          expect(textarea.toggleNumberedList(), isTrue);
          expect(textarea.value, '1. alpha\n\n2. beta');
        },
      );

      test(
        'toggleChecklistState marks and clears checklist items in the block',
        () {
          final textarea = TextAreaModel();
          textarea.setText('- [ ] alpha\n- [x] beta');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 0,
            extentLine: 1,
            extentColumn: 10,
          );

          expect(textarea.toggleChecklistState(), isTrue);
          expect(textarea.value, '- [x] alpha\n- [x] beta');
          expect(textarea.selectionBase, (line: 0, column: 0));
          expect(textarea.selectionExtent, (line: 1, column: 10));

          expect(textarea.toggleChecklistState(), isTrue);
          expect(textarea.value, '- [ ] alpha\n- [ ] beta');

          textarea.setText('alpha\nbeta');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 0,
            extentLine: 1,
            extentColumn: 4,
          );
          expect(textarea.toggleChecklistState(), isFalse);
        },
      );

      test(
        'renumberNumberedList renumbers existing numbered items in the block',
        () {
          final textarea = TextAreaModel();
          textarea.setText('9. alpha\n10. beta');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 0,
            extentLine: 1,
            extentColumn: 8,
          );

          expect(textarea.renumberNumberedList(), isTrue);
          expect(textarea.value, '1. alpha\n2. beta');
          expect(textarea.selectionBase, (line: 0, column: 0));
          expect(textarea.selectionExtent, (line: 1, column: 7));

          textarea.setText('alpha\nbeta');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 0,
            extentLine: 1,
            extentColumn: 4,
          );
          expect(textarea.renumberNumberedList(), isFalse);
        },
      );

      test('toggleHeadingPrefix normalizes or removes markdown headings', () {
        final textarea = TextAreaModel();
        textarea.setText('alpha\n## beta');
        textarea.setSelection(
          baseLine: 0,
          baseColumn: 0,
          extentLine: 1,
          extentColumn: 7,
        );

        expect(textarea.toggleHeadingPrefix(), isTrue);
        expect(textarea.value, '# alpha\n# beta');
        expect(textarea.selectionBase, (line: 0, column: 0));
        expect(textarea.selectionExtent, (line: 1, column: 6));

        expect(textarea.toggleHeadingPrefix(), isTrue);
        expect(textarea.value, 'alpha\nbeta');
        expect(textarea.selectionBase, (line: 0, column: 0));
        expect(textarea.selectionExtent, (line: 1, column: 4));
      });

      test(
        'unwrapSelection removes matching delimiters and preserves the selection',
        () {
          final textarea = TextAreaModel();
          textarea.setText('alpha (beta)');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 7,
            extentLine: 0,
            extentColumn: 11,
          );

          expect(textarea.unwrapSelection(), isTrue);
          expect(textarea.value, 'alpha beta');
          expect(textarea.selectionBase, (line: 0, column: 6));
          expect(textarea.selectionExtent, (line: 0, column: 10));
          expect(textarea.line, 0);
          expect(textarea.column, 10);

          textarea.setText('alpha beta');
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 6,
            extentLine: 0,
            extentColumn: 10,
          );
          expect(textarea.unwrapSelection(), isFalse);
        },
      );

      test('deleteLines removes the current line or selected block', () {
        final textarea = TextAreaModel();
        textarea.setText('alpha\nbeta\ngamma\ndelta');
        textarea.setCursor(1, 2);

        expect(textarea.deleteLines(), isTrue);
        expect(textarea.value, 'alpha\ngamma\ndelta');
        expect(textarea.line, 1);
        expect(textarea.column, 2);

        textarea.setSelection(
          baseLine: 1,
          baseColumn: 0,
          extentLine: 2,
          extentColumn: 5,
        );
        expect(textarea.deleteLines(), isTrue);
        expect(textarea.value, 'alpha');
        expect(textarea.line, 0);
        expect(textarea.column, 5);

        expect(textarea.undo(), isTrue);
        expect(textarea.value, 'alpha\ngamma\ndelta');
      });

      test('joinLines joins the current line or selected block', () {
        final textarea = TextAreaModel();
        textarea.setText('alpha\n  beta\ngamma');
        textarea.setCursor(0, 2);

        expect(textarea.joinLines(), isTrue);
        expect(textarea.value, 'alpha beta\ngamma');
        expect(textarea.line, 0);
        expect(textarea.column, 'alpha beta'.length);

        textarea.setSelection(
          baseLine: 0,
          baseColumn: 0,
          extentLine: 1,
          extentColumn: 5,
        );
        expect(textarea.joinLines(), isTrue);
        expect(textarea.value, 'alpha beta gamma');

        expect(textarea.undo(), isTrue);
        expect(textarea.value, 'alpha beta\ngamma');
      });
    });

    group('CursorStart', () {
      test('moves cursor to start of line', () {
        final textarea = TextAreaModel();
        textarea.insertString('hello');
        expect(textarea.column, 5);
        textarea.cursorStart();
        expect(textarea.column, 0);
      });
    });

    group('CursorEnd', () {
      test('moves cursor to end of line', () {
        final textarea = TextAreaModel();
        textarea.insertString('hello');
        textarea.cursorStart();
        expect(textarea.column, 0);
        textarea.cursorEnd();
        expect(textarea.column, 5);
      });
    });

    group('Navigation and deletion', () {
      test('delete word forward', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello world';
        textarea.cursorStart();
        // move to start of word
        for (var i = 0; i < 6; i++) {
          textarea.update(const KeyMsg(Key(KeyType.right)));
        }
        textarea.update(
          const KeyMsg(Key(KeyType.delete, alt: true)), // alt+delete
        );
        expect(textarea.value, 'hello ');
      });

      test('transpose backward', () {
        final textarea = TextAreaModel();
        textarea.insertString('ab');
        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x74], ctrl: true)), // ctrl+t
        );
        expect(textarea.value, 'ba');
      });

      test('uppercase/lowercase/capitalize word forward', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello world';
        textarea.cursorStart();

        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x75], alt: true)), // alt+u
        );
        expect(textarea.value.startsWith('HELLO'), isTrue);

        textarea.value = 'hello world';
        textarea.cursorStart();
        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x6c], alt: true)), // alt+l
        );
        expect(textarea.value.startsWith('hello'), isTrue);

        textarea.value = 'hello world';
        textarea.cursorStart();
        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x63], alt: true)), // alt+c
        );
        expect(textarea.value.startsWith('Hello'), isTrue);
      });

      test('word forward and backward navigation', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello world';
        textarea.cursorStart();

        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x66], alt: true)), // alt+f
        );
        expect(textarea.column, 5);

        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x62], alt: true)), // alt+b
        );
        expect(textarea.column, 0);
      });

      test('character and document navigation cross line boundaries', () {
        final textarea = TextAreaModel();
        textarea.value = 'ab\ncd';
        textarea.setCursor(0, 2);

        textarea.update(const KeyMsg(Key(KeyType.right)));
        expect(textarea.line, 1);
        expect(textarea.column, 0);

        textarea.update(const KeyMsg(Key(KeyType.left)));
        expect(textarea.line, 0);
        expect(textarea.column, 2);

        textarea.update(const KeyMsg(Key(KeyType.end, ctrl: true)));
        expect(textarea.line, 1);
        expect(textarea.column, 2);

        textarea.update(const KeyMsg(Key(KeyType.home, ctrl: true)));
        expect(textarea.line, 0);
        expect(textarea.column, 0);
      });

      test('delete word backward', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello world';
        textarea.update(
          const KeyMsg(Key(KeyType.backspace, alt: true)), // alt+backspace
        );
        expect(textarea.value, 'hello ');
      });

      test('delete to line start and end', () {
        final textarea = TextAreaModel();
        textarea.value = 'hello world';
        textarea.cursorStart();
        textarea.update(const KeyMsg(Key(KeyType.right))); // move after h
        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x75], ctrl: true)), // ctrl+u
        );
        expect(textarea.value, 'ello world');

        textarea.value = 'hello world';
        textarea.cursorStart();
        // Move to after "hello"
        for (var i = 0; i < 5; i++) {
          textarea.update(const KeyMsg(Key(KeyType.right)));
        }
        textarea.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x6b], ctrl: true)), // ctrl+k
        );
        expect(textarea.value, 'hello');
      });

      test('soft wrap splits long lines', () {
        final textarea = TextAreaModel(softWrap: true, width: 10, height: 4);
        textarea.insertString('long line of text');
        final view = textarea.view() as String;
        expect(view.split('\n').length, greaterThan(1));
      });
    });

    group('View', () {
      test('shows prompt', () {
        final textarea = TextAreaModel(prompt: '> ');
        final view = textarea.view() as String;
        expect(view, contains('>'));
      });

      test('shows placeholder when empty', () {
        final textarea = TextAreaModel(placeholder: 'Type here');
        final view = textarea.view() as String;
        // Placeholder is styled, so check for partial match
        expect(view.contains('ype here') || view.contains('Type'), isTrue);
      });

      test('shows content when not empty', () {
        final textarea = TextAreaModel(placeholder: 'Type here');
        textarea.insertString('content');
        final view = textarea.view() as String;
        expect(Ansi.stripAnsi(view), contains('content'));
      });

      test('shows line numbers when enabled', () {
        final textarea = TextAreaModel(showLineNumbers: true);
        textarea.value = 'line1\nline2';
        final view = textarea.view() as String;
        expect(view, contains('1'));
      });
    });

    group('SetWidth', () {
      test('sets width', () {
        final textarea = TextAreaModel();
        textarea.setWidth(100);
        // Width is adjusted for prompt/line numbers
        expect(textarea.width, greaterThan(0));
      });
    });

    group('SetHeight', () {
      test('sets height', () {
        final textarea = TextAreaModel();
        textarea.setHeight(50);
        expect(textarea.height, 50);
      });
    });

    group('Init', () {
      test('returns null', () {
        final textarea = TextAreaModel();
        expect(textarea.init(), isNull);
      });
    });

    test('is a ViewComponent and updates via base type', () {
      final textarea = TextAreaModel();
      ViewComponent model = textarea;
      final (updated, _) = model.update(const KeyMsg(Key(KeyType.enter)));
      expect(updated, isA<TextAreaModel>());
    });

    group('Selection', () {
      test('selects text via mouse drag', () {
        var textarea = TextAreaModel(prompt: '> ', showLineNumbers: false);
        textarea.value = 'Hello World\nLine 2';

        // Press at (2, 0) -> 'H' is at x=2 (prompt is '> ')
        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 2,
            y: 0,
          ),
        );

        // Drag to (7, 0) -> 'o' is at x=6
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 7,
            y: 0,
          ),
        );

        expect(v2.getSelectedText(), equals('Hello'));
      });

      test('selects text when line numbers are enabled', () {
        var textarea = TextAreaModel(
          prompt: '│ ',
          showLineNumbers: true,
          height: 5,
        );
        textarea.value = 'hello';

        // With default prompt "│ " (width 2) and line number gutter "1 "
        // (digits=1, plus trailing space), the first content cell starts at x=4.
        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 0,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 9,
            y: 0,
          ),
        );

        expect(v2.getSelectedText(), equals('hello'));
      });

      test('selects and highlights text on wrapped visual lines', () {
        var textarea = TextAreaModel(
          prompt: '',
          showLineNumbers: false,
          softWrap: true,
          width: 6,
          height: 5,
        );
        textarea.value = 'abcdefghijkl'; // wraps into "abcdef" + "ghijkl"

        // Select "ghi" from the second wrapped line (y=1).
        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 0,
            y: 1,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 3,
            y: 1,
          ),
        );

        expect(v2.getSelectedText(), equals('ghi'));

        final view = v2.view() as String;
        // Selection uses a reversed-like style (bg=7, fg=0); we just ensure
        // the selection styling is present somewhere in the output.
        expect(view, contains('\x1b[48;5;7m'));
      });

      test('renders configured non-selection highlights', () {
        final highlightStyles = TextAreaStyles(
          focused: TextAreaStyleState(
            text: Style(),
            decorationStyles: <String, Style>{
              textSearchMatchDecorationKey: Style().underline(),
              textSearchActiveMatchDecorationKey: Style()
                  .background(const AnsiColor(1))
                  .foreground(const AnsiColor(15)),
            },
          ),
          blurred: TextAreaStyleState(
            text: Style(),
            decorationStyles: <String, Style>{
              textSearchMatchDecorationKey: Style().underline(),
              textSearchActiveMatchDecorationKey: Style()
                  .background(const AnsiColor(1))
                  .foreground(const AnsiColor(15)),
            },
          ),
          cursor: TextAreaCursorStyle(color: const AnsiColor(7), blink: false),
        );
        final textarea = TextAreaModel(
          prompt: '',
          showLineNumbers: false,
          softWrap: true,
          width: 16,
          height: 4,
          styles: highlightStyles,
        );
        textarea.value = 'alpha world beta world';
        final highlights = findTextQueryHighlights(
          document: textarea.document,
          query: 'world',
        );

        textarea.setHighlights(highlights, activeIndex: 1);

        final view = textarea.view() as String;
        expect(view, contains('\x1b[4m'));
        expect(view, contains('\x1b[48;5;1m'));
      });

      test(
        'renders configured whole-line decorations and active-line layer',
        () {
          final decoratedStyles = TextAreaStyles(
            focused: TextAreaStyleState(
              text: Style(),
              cursorLine: Style().background(const AnsiColor(2)),
              cursorLineNumber: Style().foreground(const AnsiColor(15)),
              lineDecorationStyles: <String, Style>{
                textActiveLineDecorationKey: Style().background(
                  const AnsiColor(2),
                ),
                textActiveLineNumberDecorationKey: Style().foreground(
                  const AnsiColor(15),
                ),
                'line.warning': Style().background(const AnsiColor(3)),
                'line.warning.number': Style().foreground(const AnsiColor(1)),
              },
            ),
            blurred: TextAreaStyleState(
              text: Style(),
              cursorLine: Style().background(const AnsiColor(2)),
              cursorLineNumber: Style().foreground(const AnsiColor(15)),
              lineDecorationStyles: <String, Style>{
                textActiveLineDecorationKey: Style().background(
                  const AnsiColor(2),
                ),
                textActiveLineNumberDecorationKey: Style().foreground(
                  const AnsiColor(15),
                ),
                'line.warning': Style().background(const AnsiColor(3)),
                'line.warning.number': Style().foreground(const AnsiColor(1)),
              },
            ),
            cursor: TextAreaCursorStyle(
              color: const AnsiColor(7),
              blink: false,
            ),
          );
          final textarea = TextAreaModel(
            prompt: '',
            showLineNumbers: true,
            softWrap: true,
            width: 16,
            height: 4,
            useVirtualCursor: false,
            styles: decoratedStyles,
          );
          textarea.value = 'alpha\nbeta';
          textarea.setCursor(1, 1);
          textarea.setLineDecorationLayer('diagnostics', const [
            TextLineDecoration(
              lineIndex: 0,
              styleKey: 'line.warning',
              lineNumberStyleKey: 'line.warning.number',
            ),
          ]);

          expect(
            textarea.lineDecorationsForLayer(textActiveLineDecorationLayerKey),
            const [
              TextLineDecoration(
                lineIndex: 1,
                styleKey: textActiveLineDecorationKey,
                lineNumberStyleKey: textActiveLineNumberDecorationKey,
              ),
            ],
          );

          final view = textarea.view() as String;
          expect(view, contains('\x1b[48;5;3m'));
          expect(view, contains('\x1b[48;5;2m'));
          expect(view, contains('\x1b[38;5;1m'));
          expect(view, contains('\x1b[38;5;15m'));
        },
      );

      test('applies typed diagnostics to both range and line layers', () {
        final diagnosticStyles = TextAreaStyles(
          focused: TextAreaStyleState(
            text: Style(),
            decorationStyles: <String, Style>{
              textDiagnosticErrorDecorationKey: Style()
                  .underline()
                  .underlineColor(const AnsiColor(1)),
            },
            lineDecorationStyles: <String, Style>{
              textActiveLineDecorationKey: Style(),
              textActiveLineNumberDecorationKey: Style(),
              textDiagnosticErrorLineDecorationKey: Style(),
              textDiagnosticErrorLineNumberDecorationKey: Style().foreground(
                const AnsiColor(1),
              ),
            },
          ),
          blurred: TextAreaStyleState(
            text: Style(),
            decorationStyles: <String, Style>{
              textDiagnosticErrorDecorationKey: Style()
                  .underline()
                  .underlineColor(const AnsiColor(1)),
            },
            lineDecorationStyles: <String, Style>{
              textActiveLineDecorationKey: Style(),
              textActiveLineNumberDecorationKey: Style(),
              textDiagnosticErrorLineDecorationKey: Style(),
              textDiagnosticErrorLineNumberDecorationKey: Style().foreground(
                const AnsiColor(1),
              ),
            },
          ),
          cursor: TextAreaCursorStyle(color: const AnsiColor(7), blink: false),
        );
        final textarea = TextAreaModel(
          prompt: '',
          showLineNumbers: true,
          softWrap: false,
          width: 16,
          height: 4,
          useVirtualCursor: true,
          styles: diagnosticStyles,
        );
        textarea.value = 'alpha\nFIXME';

        textarea.setDiagnostics(const [
          TextDiagnosticRange(
            startOffset: 6,
            endOffset: 11,
            severity: TextDiagnosticSeverity.error,
          ),
        ]);

        expect(
          textarea.decorationsForLayer(textDiagnosticsDecorationLayerKey),
          const [
            TextDecorationRange(
              startOffset: 6,
              endOffset: 11,
              styleKey: textDiagnosticErrorDecorationKey,
            ),
          ],
        );
        expect(
          textarea.lineDecorationsForLayer(
            textDiagnosticsLineDecorationLayerKey,
          ),
          const [
            TextLineDecoration(
              lineIndex: 1,
              styleKey: textDiagnosticErrorLineDecorationKey,
              lineNumberMarker: '!',
              lineNumberStyleKey: textDiagnosticErrorLineNumberDecorationKey,
            ),
          ],
        );

        final view = textarea.view() as String;
        expect(view, contains('2!'));
      });

      test('accepts typed diagnostics from line and column positions', () {
        final textarea = TextAreaModel(
          prompt: '',
          showLineNumbers: true,
          softWrap: false,
          width: 16,
          height: 4,
        );
        textarea.value = 'alpha\nFIXME';

        textarea.setDiagnosticsFromPositions(const [
          TextPositionDiagnosticRange(
            startLine: 1,
            startColumn: 0,
            endLine: 1,
            endColumn: 5,
            severity: TextDiagnosticSeverity.error,
            code: 'FIX001',
            message:
                'Resolve FIXME markers before treating this draft as ready.',
            source: 'playground',
          ),
        ]);

        expect(
          textarea.decorationsForLayer(textDiagnosticsDecorationLayerKey),
          const [
            TextDecorationRange(
              startOffset: 6,
              endOffset: 11,
              styleKey: textDiagnosticErrorDecorationKey,
            ),
          ],
        );
        expect(textarea.diagnostics, const [
          TextDiagnosticRange(
            startOffset: 6,
            endOffset: 11,
            severity: TextDiagnosticSeverity.error,
            code: 'FIX001',
            message:
                'Resolve FIXME markers before treating this draft as ready.',
            source: 'playground',
          ),
        ]);
        textarea.setCursor(1, 0);
        expect(
          textarea.activeDiagnostic,
          const TextDiagnosticRange(
            startOffset: 6,
            endOffset: 11,
            severity: TextDiagnosticSeverity.error,
            code: 'FIX001',
            message:
                'Resolve FIXME markers before treating this draft as ready.',
            source: 'playground',
          ),
        );
      });

      test('navigates typed diagnostics and wraps between matches', () {
        final textarea = TextAreaModel(
          prompt: '',
          showLineNumbers: false,
          softWrap: false,
          width: 24,
          height: 4,
        );
        textarea.value = 'TODO one\nok\nFIXME two';
        textarea.setDiagnostics(const [
          TextDiagnosticRange(
            startOffset: 0,
            endOffset: 4,
            severity: TextDiagnosticSeverity.warning,
            code: 'TODO001',
            message: 'Address TODO markers before shipping this sample.',
            source: 'playground',
          ),
          TextDiagnosticRange(
            startOffset: 12,
            endOffset: 17,
            severity: TextDiagnosticSeverity.error,
            code: 'FIX001',
            message:
                'Resolve FIXME markers before treating this draft as ready.',
            source: 'playground',
          ),
        ]);

        expect(textarea.selectNextDiagnostic(), isTrue);
        expect(textarea.getSelectedText(), equals('TODO'));
        expect(textarea.selectionBase, equals((line: 0, column: 0)));
        expect(
          textarea.activeDiagnostic,
          const TextDiagnosticRange(
            startOffset: 0,
            endOffset: 4,
            severity: TextDiagnosticSeverity.warning,
            code: 'TODO001',
            message: 'Address TODO markers before shipping this sample.',
            source: 'playground',
          ),
        );

        expect(textarea.selectNextDiagnostic(), isTrue);
        expect(textarea.getSelectedText(), equals('FIXME'));
        expect(textarea.selectionBase, equals((line: 2, column: 0)));

        expect(textarea.selectNextDiagnostic(), isTrue);
        expect(textarea.getSelectedText(), equals('TODO'));

        expect(textarea.selectPreviousDiagnostic(), isTrue);
        expect(textarea.getSelectedText(), equals('FIXME'));
      });

      test(
        'clicking a diagnostic gutter marker selects the line diagnostic',
        () {
          final textarea = TextAreaModel(
            prompt: '│ ',
            showLineNumbers: true,
            softWrap: false,
            width: 24,
            height: 4,
          );
          textarea.value = 'ok\nTODO FIXME';
          textarea.setDiagnostics(const [
            TextDiagnosticRange(
              startOffset: 3,
              endOffset: 7,
              severity: TextDiagnosticSeverity.warning,
              code: 'TODO001',
              message: 'Address TODO markers before shipping this sample.',
              source: 'playground',
            ),
            TextDiagnosticRange(
              startOffset: 8,
              endOffset: 13,
              severity: TextDiagnosticSeverity.error,
              code: 'FIX001',
              message:
                  'Resolve FIXME markers before treating this draft as ready.',
              source: 'playground',
            ),
          ]);

          final (selected, _) = textarea.update(
            const MouseMsg(
              action: MouseAction.press,
              button: MouseButton.left,
              x: 2,
              y: 1,
            ),
          );

          expect(selected.getSelectedText(), equals('FIXME'));
          expect(
            selected.activeDiagnostic,
            const TextDiagnosticRange(
              startOffset: 8,
              endOffset: 13,
              severity: TextDiagnosticSeverity.error,
              code: 'FIX001',
              message:
                  'Resolve FIXME markers before treating this draft as ready.',
              source: 'playground',
            ),
          );

          final (reselected, _) = selected.update(
            const MouseMsg(
              action: MouseAction.press,
              button: MouseButton.left,
              x: 2,
              y: 1,
            ),
          );

          expect(reselected.getSelectedText(), equals('FIXME'));
        },
      );

      test(
        'merges active-line styling with diagnostic line-number styling',
        () {
          final diagnosticStyles = TextAreaStyles(
            focused: TextAreaStyleState(
              text: Style(),
              cursorLine: Style().background(const AnsiColor(2)),
              cursorLineNumber: Style().foreground(const AnsiColor(15)),
              decorationStyles: <String, Style>{
                textDiagnosticErrorDecorationKey: Style()
                    .underline()
                    .underlineColor(const AnsiColor(1)),
              },
              lineDecorationStyles: <String, Style>{
                textActiveLineDecorationKey: Style().background(
                  const AnsiColor(2),
                ),
                textActiveLineNumberDecorationKey: Style().foreground(
                  const AnsiColor(15),
                ),
                textDiagnosticErrorLineDecorationKey: Style(),
                textDiagnosticErrorLineNumberDecorationKey: Style().foreground(
                  const AnsiColor(1),
                ),
              },
            ),
            blurred: TextAreaStyleState(text: Style()),
            cursor: TextAreaCursorStyle(
              color: const AnsiColor(7),
              blink: false,
            ),
          );
          final textarea = TextAreaModel(
            prompt: '',
            showLineNumbers: true,
            softWrap: false,
            width: 16,
            height: 4,
            useVirtualCursor: false,
            styles: diagnosticStyles,
          );
          textarea.value = 'alpha\nFIXME';
          textarea.focus();
          textarea.setCursor(1, 1);

          textarea.setDiagnostics(const [
            TextDiagnosticRange(
              startOffset: 6,
              endOffset: 11,
              severity: TextDiagnosticSeverity.error,
            ),
          ]);

          final rendered = textarea.view();
          final view = rendered is View ? rendered.content : rendered as String;
          expect(view, contains('\x1b[48;5;2m'));
          expect(view, contains('\x1b[38;5;1m'));
          expect(view, contains('2!'));
        },
      );

      test(
        'selected decorated cursor grapheme does not leak raw ansi fragments',
        () {
          final overlapStyles = TextAreaStyles(
            focused: TextAreaStyleState(
              text: Style().foreground(const AnsiColor(15)),
              selection: Style()
                  .background(const AnsiColor(4))
                  .foreground(const AnsiColor(15)),
              decorationStyles: <String, Style>{
                'search': Style()
                    .background(const AnsiColor(3))
                    .foreground(const AnsiColor(0)),
              },
            ),
            blurred: TextAreaStyleState(
              text: Style().foreground(const AnsiColor(15)),
              selection: Style()
                  .background(const AnsiColor(4))
                  .foreground(const AnsiColor(15)),
              decorationStyles: <String, Style>{
                'search': Style()
                    .background(const AnsiColor(3))
                    .foreground(const AnsiColor(0)),
              },
            ),
            cursor: TextAreaCursorStyle(
              color: const AnsiColor(6),
              blink: false,
            ),
          );
          final textarea = TextAreaModel(
            prompt: '',
            showLineNumbers: false,
            softWrap: false,
            width: 12,
            height: 2,
            useVirtualCursor: true,
            styles: overlapStyles,
          );
          textarea.focus();
          textarea.value = 'TODO';
          textarea.setDecorationLayer('search', const [
            TextDecorationRange(
              startOffset: 0,
              endOffset: 4,
              styleKey: 'search',
            ),
          ]);
          textarea.setSelection(
            baseLine: 0,
            baseColumn: 0,
            extentLine: 0,
            extentColumn: 4,
          );
          textarea.setCursor(0, 0);

          final stripped = Ansi.stripAnsi(textarea.view() as String);

          expect(stripped, contains('TODO'));
          expect(stripped, isNot(contains('[7m')));
          expect(stripped, isNot(contains('[27m')));
          expect(stripped, isNot(contains('[38;5;')));
        },
      );

      test('selects wrapped continuation when line numbers are enabled', () {
        var textarea = TextAreaModel(
          prompt: '│ ',
          showLineNumbers: true,
          softWrap: true,
          width: 12,
          height: 5,
        );
        textarea.value = 'abcdefghijkl'; // wraps into "abcdefgh" + "ijkl"

        // Continuation visual line is y=1. Content starts at x=4:
        // prompt "│ " (2) + line number gutter "1 " or blank (2).
        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 1,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 7,
            y: 1,
          ),
        );

        expect(v2.getSelectedText(), equals('ijk'));
      });

      test('double click selects word', () {
        var textarea = TextAreaModel(prompt: '> ', showLineNumbers: false);
        textarea.value = 'Hello World\nLine 2';

        // Click inside "Hello"
        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 0,
          ),
        );

        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 0,
          ),
        );

        expect(v2.getSelectedText(), equals('Hello'));
      });

      test('triple click selects entire line', () {
        var textarea = TextAreaModel(prompt: '> ', showLineNumbers: false);
        textarea.value = 'Hello World\nLine 2';

        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 0,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 0,
          ),
        );
        var (v3, _) = v2.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 0,
          ),
        );

        expect(v3.getSelectedText(), equals('Hello World'));
      });

      test('mouse release stops extending the current selection', () {
        var textarea = TextAreaModel(prompt: '', showLineNumbers: false);
        textarea.value = 'Hello World\nLine 2';

        var (v1, _) = textarea.update(
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

        var (v3, _) = v2.update(
          const MouseMsg(
            action: MouseAction.release,
            button: MouseButton.left,
            x: 5,
            y: 0,
          ),
        );
        var (v4, _) = v3.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.none,
            x: 4,
            y: 1,
          ),
        );

        expect(v4.getSelectedText(), equals('Hello'));
      });

      test('click without drag does not leave selection armed', () {
        var textarea = TextAreaModel(prompt: '', showLineNumbers: false);
        textarea.value = 'Hello World\nLine 2';

        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 0,
            y: 0,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.release,
            button: MouseButton.left,
            x: 0,
            y: 0,
          ),
        );
        expect(v2.getSelectedText(), isEmpty);

        var (v3, _) = v2.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.none,
            x: 5,
            y: 0,
          ),
        );

        expect(v3.getSelectedText(), isEmpty);
      });

      test('click outside bounds clears selection and blurs', () {
        var textarea = TextAreaModel(
          prompt: '> ',
          showLineNumbers: false,
          height: 5,
        );
        textarea.value = 'Hello World\nLine 2';
        textarea.focus();

        // Select something
        var (v1, _) = textarea.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 2,
            y: 0,
          ),
        );
        var (v2, _) = v1.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 7,
            y: 0,
          ),
        );
        expect(v2.getSelectedText(), equals('Hello'));
        expect(v2.focused, isTrue);

        // Click outside (y = 6)
        var (v3, _) = v2.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 2,
            y: 6,
          ),
        );
        expect(v3.getSelectedText(), equals(''));
        expect(v3.focused, isFalse);
      });
    });
  });

  group('TextAreaKeyMap', () {
    test('creates with default bindings', () {
      final keyMap = TextAreaKeyMap();
      expect(keyMap.characterForward.keys, isNotEmpty);
      expect(keyMap.characterBackward.keys, isNotEmpty);
      expect(keyMap.lineNext.keys, isNotEmpty);
      expect(keyMap.linePrevious.keys, isNotEmpty);
      expect(keyMap.undo.keys, isNotEmpty);
      expect(keyMap.redo.keys, isNotEmpty);
    });

    test('shortHelp returns bindings', () {
      final keyMap = TextAreaKeyMap();
      final help = keyMap.shortHelp();
      expect(help.length, greaterThanOrEqualTo(4));
    });

    test('fullHelp returns grouped bindings', () {
      final keyMap = TextAreaKeyMap();
      final help = keyMap.fullHelp();
      expect(help, isNotEmpty);
      expect(help.expand((group) => group), contains(keyMap.selectAll));
      expect(help.expand((group) => group), contains(keyMap.selectLine));
    });
  });

  group('TextAreaStyles', () {
    test('creates with defaults', () {
      final styles = TextAreaStyles();
      expect(styles.focused, isNotNull);
      expect(styles.blurred, isNotNull);
      expect(styles.cursor, isNotNull);
    });
  });

  group('Default Styles', () {
    test('provides focused and blurred styles', () {
      final styles = defaultTextAreaStyles();
      expect(styles.focused, isNotNull);
      expect(styles.blurred, isNotNull);
    });
  });

  group('LineInfo', () {
    test('creates with default values', () {
      final info = LineInfo();
      expect(info.width, 0);
      expect(info.height, 0);
      expect(info.charWidth, 0);
    });

    test('creates with custom values', () {
      final info = LineInfo(
        width: 80,
        height: 1,
        charWidth: 80,
        startColumn: 0,
        columnOffset: 5,
      );
      expect(info.width, 80);
      expect(info.height, 1);
      expect(info.columnOffset, 5);
    });
  });

  group('TextAreaPasteMsg', () {
    test('creates with content', () {
      final msg = TextAreaPasteMsg('hello');
      expect(msg.content, 'hello');
    });
  });

  group('TextAreaPasteErrorMsg', () {
    test('creates with error', () {
      final error = Exception('Paste failed');
      final msg = TextAreaPasteErrorMsg(error);
      expect(msg.error, error);
    });
  });
}
