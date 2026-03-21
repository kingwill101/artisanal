import 'package:artisanal/src/tui/bubbles/textinput.dart';
import 'package:artisanal/src/tui/editor_core/editor_core.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/terminal/ansi.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart'
    show Key, KeyMsg, KeyType, MouseAction, MouseButton, MouseMsg;
import 'package:test/test.dart';

void main() {
  group('TextInputModel', () {
    group('New', () {
      test('creates with default values', () {
        final input = TextInputModel();
        expect(input.prompt, '> ');
        expect(input.placeholder, '');
        expect(input.echoMode, EchoMode.normal);
        expect(input.charLimit, 0);
        expect(input.value, '');
      });

      test('creates with custom prompt', () {
        final input = TextInputModel(prompt: 'Name: ');
        expect(input.prompt, 'Name: ');
      });

      test('creates with placeholder', () {
        final input = TextInputModel(placeholder: 'Enter text');
        expect(input.placeholder, 'Enter text');
      });

      test('creates with password mode', () {
        final input = TextInputModel(echoMode: EchoMode.password);
        expect(input.echoMode, EchoMode.password);
      });

      test('creates with char limit', () {
        final input = TextInputModel(charLimit: 10);
        expect(input.charLimit, 10);
      });

      test('starts unfocused', () {
        final input = TextInputModel();
        expect(input.focused, isFalse);
      });
    });

    group('Value', () {
      test('sets value', () {
        final input = TextInputModel();
        input.value = 'hello';
        expect(input.value, 'hello');
      });

      test('gets value', () {
        final input = TextInputModel();
        input.value = 'test';
        expect(input.value, 'test');
      });

      test('respects char limit when setting value', () {
        final input = TextInputModel(charLimit: 5);
        input.value = 'hello world';
        expect(input.value.length, lessThanOrEqualTo(5));
      });

      test('syncs the editor core document and cursor state', () {
        final input = TextInputModel(multiline: true);
        input.setText('alpha\nbeta');

        expect(input.document.text, 'alpha\nbeta');
        expect(
          input.editorState.cursor,
          const TextPosition(line: 1, column: 4),
        );
      });

      test('cursor and selection sync do not change document revision', () {
        final input = TextInputModel(multiline: true);
        input.setText('alpha\nbeta');
        final revision = input.document.revision;

        input.position = 1;
        expect(input.document.revision, revision);

        input.selectAll();
        expect(input.document.revision, revision);
      });

      test('syncs editor core selection state', () {
        final input = TextInputModel(multiline: true);
        input.setTextState(
          text: 'alpha\nbeta',
          selectionBase: 1,
          selectionExtent: 8,
        );

        expect(input.editorState.hasSelection, isTrue);
        expect(
          input.editorState.selection!.base,
          const TextPosition(line: 0, column: 1),
        );
        expect(
          input.editorState.selection!.extent,
          const TextPosition(line: 1, column: 2),
        );
      });

      test(
        'preserves position in editor core while selection remains active',
        () {
          final input = TextInputModel(multiline: true);
          input.setTextState(
            text: 'alpha\nbeta',
            selectionBase: 1,
            selectionExtent: 8,
          );

          input.position = 1;

          expect(input.position, 1);
          expect(
            input.editorState.cursor,
            const TextPosition(line: 0, column: 1),
          );
          expect(
            input.editorState.selection!.base,
            const TextPosition(line: 0, column: 1),
          );
          expect(
            input.editorState.selection!.extent,
            const TextPosition(line: 1, column: 2),
          );
        },
      );
    });

    group('Position', () {
      test('starts at end of value', () {
        final input = TextInputModel();
        input.value = 'hello';
        expect(input.position, 5);
      });

      test('sets position', () {
        final input = TextInputModel();
        input.value = 'hello';
        input.position = 2;
        expect(input.position, 2);
      });

      test('clamps position to valid range', () {
        final input = TextInputModel();
        input.value = 'hello';
        input.position = 10;
        expect(input.position, 5);
        input.position = -5;
        expect(input.position, 0);
      });

      test('counts position in grapheme clusters (combining marks)', () {
        final input = TextInputModel();
        input.value = 'e\u0301'; // single grapheme, two code points
        expect(input.position, 1);
      });
    });

    group('Focus', () {
      test('focus sets focused to true', () {
        final input = TextInputModel();
        input.focus();
        expect(input.focused, isTrue);
      });

      test('blur sets focused to false', () {
        final input = TextInputModel();
        input.focus();
        input.blur();
        expect(input.focused, isFalse);
      });
    });

    group('Reset', () {
      test('clears value', () {
        final input = TextInputModel();
        input.value = 'hello';
        input.reset();
        expect(input.value, '');
      });

      test('resets position to 0', () {
        final input = TextInputModel();
        input.value = 'hello';
        input.reset();
        expect(input.position, 0);
      });
    });

    group('CursorStart', () {
      test('moves cursor to start', () {
        final input = TextInputModel();
        input.value = 'hello';
        expect(input.position, 5);
        input.cursorStart();
        expect(input.position, 0);
      });
    });

    group('CursorEnd', () {
      test('moves cursor to end', () {
        final input = TextInputModel();
        input.value = 'hello';
        input.position = 0;
        input.cursorEnd();
        expect(input.position, 5);
      });
    });

    group('Suggestions', () {
      test('sets suggestions', () {
        final input = TextInputModel();
        input.suggestions = ['apple', 'banana', 'cherry'];
        expect(input.availableSuggestions, ['apple', 'banana', 'cherry']);
      });

      test('current suggestion is empty when no match', () {
        final input = TextInputModel();
        input.suggestions = ['apple', 'banana'];
        input.value = 'xyz';
        expect(input.currentSuggestion, '');
      });

      test('current suggestion matches input', () {
        final input = TextInputModel(showSuggestions: true);
        input.suggestions = ['apple', 'apricot', 'banana'];
        input.value = 'ap';
        // Should match apple or apricot
        if (input.matchedSuggestions.isNotEmpty) {
          expect(input.currentSuggestion, startsWith('ap'));
        }
      });
    });

    group('Validation', () {
      test('validates input', () {
        final input = TextInputModel(
          validate: (value) {
            if (value.isEmpty) return 'Required';
            return null;
          },
        );
        input.value = '';
        expect(input.error, 'Required');
      });

      test('clears error when valid', () {
        final input = TextInputModel(
          validate: (value) {
            if (value.isEmpty) return 'Required';
            return null;
          },
        );
        input.value = '';
        expect(input.error, 'Required');
        input.value = 'hello';
        expect(input.error, isNull);
      });
    });

    group('EchoMode', () {
      test('normal mode shows text', () {
        final input = TextInputModel(echoMode: EchoMode.normal);
        input.value = 'hello';
        final view = input.view() as String;
        expect(Ansi.stripAnsi(view), contains('hello'));
      });

      test('password mode shows mask', () {
        final input = TextInputModel(
          echoMode: EchoMode.password,
          echoCharacter: '*',
        );
        input.value = 'hello';
        final view = input.view() as String;
        // Should contain echo character
        expect(Ansi.stripAnsi(view), isNot(contains('hello')));
      });
    });

    group('View', () {
      test('shows prompt', () {
        final input = TextInputModel(prompt: '>> ');
        final view = input.view();
        expect(view, contains('>>'));
      });

      test('shows placeholder when empty', () {
        final input = TextInputModel(placeholder: 'Type here');
        final view = input.view() as String;
        // Placeholder is styled, so check without exact match
        expect(view.contains('ype here') || view.contains('Type'), isTrue);
      });

      test('shows value when not empty', () {
        final input = TextInputModel(placeholder: 'Type here');
        input.value = 'hello';
        final view = input.view() as String;
        expect(Ansi.stripAnsi(view), contains('hello'));
      });

      test(
        'selected cursor grapheme does not leak raw ansi fragments in single-line view',
        () {
          final styles = TextInputStyles(
            focused: TextInputStyleState(
              text: Style().foreground(const AnsiColor(15)),
              selection: Style()
                  .background(const AnsiColor(4))
                  .foreground(const AnsiColor(15)),
            ),
            blurred: TextInputStyleState(
              text: Style().foreground(const AnsiColor(15)),
              selection: Style()
                  .background(const AnsiColor(4))
                  .foreground(const AnsiColor(15)),
            ),
            cursor: TextInputCursorStyle(
              color: const AnsiColor(6),
              blink: false,
            ),
          );
          final input = TextInputModel(
            prompt: '',
            useVirtualCursor: true,
            styles: styles,
          )..focus();
          input.value = 'TODO';
          input.selectionStart = 0;
          input.selectionEnd = 4;
          input.position = 0;

          final stripped = Ansi.stripAnsi(input.view() as String);

          expect(stripped, contains('TODO'));
          expect(stripped, isNot(contains('[7m')));
          expect(stripped, isNot(contains('[27m')));
          expect(stripped, isNot(contains('[38;5;')));
        },
      );
    });

    group('Grapheme Editing', () {
      test('backspace deletes a full grapheme cluster', () {
        final input = TextInputModel()..focus();
        input.value = 'e\u0301x'; // 2 graphemes: "é" + "x"
        input.position = 1; // after first grapheme

        input.update(KeyMsg(const Key(KeyType.backspace)));

        expect(input.value, 'x');
        expect(input.position, 0);
      });

      test(
        'document-backed multiline backspace patches value without warming every line cache',
        () {
          final lines = List<String>.generate(
            300,
            (index) => 'line-$index',
            growable: false,
          );
          final input = TextInputModel(multiline: true)..focus();
          input.value = lines.join('\n');
          input.position =
              input.document.lineStartOffset(150) +
              input.document.lineLength(150);

          expect(input.document.debugStorageDepth, greaterThan(1));
          expect(input.document.debugLineGraphemeCacheCount, lessThan(10));

          input.update(KeyMsg(const Key(KeyType.backspace)));

          expect(input.document.lineAt(150), 'line-15');
          expect(input.document.debugLineGraphemeCacheCount, lessThan(10));
        },
      );

      test('delete removes a full grapheme cluster', () {
        final input = TextInputModel()..focus();
        input.value = 'e\u0301x'; // 2 graphemes: "é" + "x"
        input.position = 0;

        input.update(KeyMsg(const Key(KeyType.delete)));

        expect(input.value, 'x');
        expect(input.position, 0);
      });
    });

    group('Undo and redo', () {
      test('undo coalesces consecutive typed characters', () {
        final input = TextInputModel()..focus();

        input.update(KeyMsg(Key.char('a')));
        input.update(KeyMsg(Key.char('b')));

        expect(input.value, 'ab');
        expect(input.canUndo, isTrue);

        input.update(KeyMsg(Key.char('z', ctrl: true)));
        expect(input.value, '');
        expect(input.canRedo, isTrue);
      });

      test('redo reapplies an undone edit', () {
        final input = TextInputModel()..focus();

        input.update(KeyMsg(Key.char('a')));
        input.update(KeyMsg(Key.char('b')));
        input.update(KeyMsg(Key.char('z', ctrl: true)));
        input.update(KeyMsg(Key.char('y', ctrl: true)));

        expect(input.value, 'ab');
      });

      test('new edit clears redo history', () {
        final input = TextInputModel()..focus();

        input.update(KeyMsg(Key.char('a')));
        input.update(KeyMsg(Key.char('b')));
        input.update(KeyMsg(Key.char('z', ctrl: true)));
        expect(input.canRedo, isTrue);

        input.update(KeyMsg(Key.char('c')));

        expect(input.value, 'c');
        expect(input.canRedo, isFalse);
      });

      test('cursor movement breaks insert coalescing', () {
        final input = TextInputModel()..focus();

        input.update(KeyMsg(Key.char('a')));
        input.update(KeyMsg(Key.char('b')));
        input.update(const KeyMsg(Key(KeyType.left)));
        input.update(KeyMsg(Key.char('x')));

        expect(input.value, 'axb');

        input.update(KeyMsg(Key.char('z', ctrl: true)));
        expect(input.value, 'ab');

        input.update(KeyMsg(Key.char('z', ctrl: true)));
        expect(input.value, '');
      });

      test('backspace coalesces consecutive deletions', () {
        final input = TextInputModel()..focus();
        input.value = 'abcd';

        input.update(const KeyMsg(Key(KeyType.backspace)));
        input.update(const KeyMsg(Key(KeyType.backspace)));

        expect(input.value, 'ab');
        input.update(KeyMsg(Key.char('z', ctrl: true)));
        expect(input.value, 'abcd');
      });

      test('programmatic setText participates in history', () {
        final input = TextInputModel();

        input.setText('hello');
        input.setText('hello world');

        expect(input.undo(), isTrue);
        expect(input.value, 'hello');
        expect(input.redo(), isTrue);
        expect(input.value, 'hello world');
      });

      test('pushHistoryBoundary splits coalesced insert bursts', () {
        final input = TextInputModel()..focus();

        input.insertText('a', coalesce: true);
        input.insertText('b', coalesce: true);
        input.pushHistoryBoundary();
        input.insertText('c', coalesce: true);

        expect(input.value, 'abc');

        input.undo();
        expect(input.value, 'ab');

        input.undo();
        expect(input.value, '');
      });
    });

    group('Programmatic edit operations', () {
      test('insertText inserts at the cursor', () {
        final input = TextInputModel();
        input.value = 'ac';
        input.position = 1;

        input.insertText('b');

        expect(input.value, 'abc');
        expect(input.position, 2);
      });

      test('replaceSelection replaces selected content', () {
        final input = TextInputModel();
        input.value = 'hello world';
        input.selectionStart = 6;
        input.selectionEnd = 11;
        input.position = 11;

        input.replaceSelection('dart');

        expect(input.value, 'hello dart');
        expect(input.position, 10);
      });

      test('deleteBackward and deleteForward work programmatically', () {
        final input = TextInputModel();
        input.value = 'abcd';
        input.position = 2;

        expect(input.deleteBackward(), isTrue);
        expect(input.value, 'acd');

        expect(input.deleteForward(), isTrue);
        expect(input.value, 'ad');
      });

      test('word deletion uses whitespace-delimited word boundaries', () {
        final input = TextInputModel();
        input.value = 'foo.bar baz';
        input.position = 7;

        expect(input.deleteBackward(word: true), isTrue);
        expect(input.value, ' baz');
        expect(input.position, 0);
      });
    });

    group('Init', () {
      test('returns null', () {
        final input = TextInputModel();
        expect(input.init(), isNull);
      });
    });

    test('is a ViewComponent and updates via base type', () {
      final input = TextInputModel();
      ViewComponent model = input;
      final (updated, _) = model.update(const KeyMsg(Key(KeyType.left)));
      expect(updated, isA<TextInputModel>());
    });

    group('Selection', () {
      test('shift+arrow selection highlights without auto copy', () {
        var input = TextInputModel(prompt: '> ');
        input.focus();
        input.value = 'Hello World';
        input.position = 0;

        final (next, _) = input.update(
          const KeyMsg(Key(KeyType.right, shift: true)),
        );

        expect(next.getSelectedText(), equals('H'));
      });

      test('ctrl+shift+arrow extends selection by word', () {
        var input = TextInputModel(prompt: '> ');
        input.focus();
        input.value = 'Hello World';
        input.position = 0;

        final (next, _) = input.update(
          const KeyMsg(Key(KeyType.right, ctrl: true, shift: true)),
        );

        expect(next.getSelectedText(), equals('Hello'));
        expect(next.position, 5);
        expect(next.editorState.hasSelection, isTrue);
      });

      test(
        'ctrl+shift+arrow keeps textinput whitespace-delimited word motion',
        () {
          var input = TextInputModel(prompt: '> ');
          input.focus();
          input.value = 'foo.bar baz';
          input.position = 0;

          final (next, _) = input.update(
            const KeyMsg(Key(KeyType.right, ctrl: true, shift: true)),
          );

          expect(next.getSelectedText(), equals('foo.bar'));
          expect(next.position, 7);
          expect(next.editorState.hasSelection, isTrue);
        },
      );

      test('ctrl+arrow clears selection before moving by word', () {
        var input = TextInputModel(prompt: '> ');
        input.focus();
        input.value = 'Hello World';
        input.selectionStart = 0;
        input.selectionEnd = 5;
        input.position = 5;

        final (next, _) = input.update(
          const KeyMsg(Key(KeyType.right, ctrl: true)),
        );

        expect(next.position, 11);
        expect(next.selectionStart, isNull);
        expect(next.selectionEnd, isNull);
      });

      test('copy shortcut does not delete selected text', () {
        var input = TextInputModel(prompt: '> ');
        input.focus();
        input.value = 'Hello World';
        input.selectionStart = 0;
        input.selectionEnd = 5;

        final (next, cmd) = input.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x63], ctrl: true)),
        );

        expect(cmd, isNotNull);
        expect(next.value, equals('Hello World'));
        expect(next.getSelectedText(), equals('Hello'));
      });

      test('ctrl+shift+c control rune does not delete selection', () {
        var input = TextInputModel(prompt: '> ');
        input.focus();
        input.value = 'Hello World';
        input.selectionStart = 0;
        input.selectionEnd = 5;

        final (next, cmd) = input.update(
          const KeyMsg(Key(KeyType.runes, runes: [0x03])),
        );

        expect(cmd, isNotNull);
        expect(next.value, equals('Hello World'));
        expect(next.getSelectedText(), equals('Hello'));
      });

      test('selects text via mouse drag (motion button can be none)', () {
        var input = TextInputModel(prompt: '> ');
        input.value = 'Hello World';

        // Press at (2, 0) -> 'H' is at x=2 (prompt is '> ')
        var (v1, _) = input.update(
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
            button: MouseButton.none,
            x: 7,
            y: 0,
          ),
        );

        expect(v2.getSelectedText(), equals('Hello'));

        final (v3, cmd) = v2.update(
          const MouseMsg(
            action: MouseAction.release,
            button: MouseButton.left,
            x: 7,
            y: 0,
          ),
        );
        expect(cmd, isNotNull);
        expect(v3.value, equals('Hello World'));
        expect(v3.getSelectedText(), isEmpty);
      });

      test('double click selects word', () {
        var input = TextInputModel(prompt: '> ');
        input.value = 'Hello World';

        // Click inside "Hello"
        var (v1, _) = input.update(
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
        var input = TextInputModel(prompt: '> ');
        input.value = 'Hello World';

        var (v1, _) = input.update(
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

      test('click outside bounds clears selection and blurs', () {
        var input = TextInputModel(prompt: '> ');
        input.value = 'Hello World';
        input.focus();

        // Select something
        var (v1, _) = input.update(
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

        // Click outside (y = 1)
        var (v3, _) = v2.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 2,
            y: 1,
          ),
        );
        expect(v3.getSelectedText(), equals(''));
        expect(v3.focused, isFalse);
      });
    });

    group('Multiline input', () {
      test('shift+enter inserts newline', () {
        var input = TextInputModel(multiline: true);
        input.focus();
        input.value = 'abc';

        final (next, _) = input.update(
          const KeyMsg(Key(KeyType.enter, shift: true)),
        );

        expect(next.value, equals('abc\n'));
      });

      test('mouse wheel scrolls multiline viewport', () {
        var input = TextInputModel(multiline: true, maxHeight: 2, width: 20);
        input.focus();
        input.value = 'line1\nline2\nline3';
        input.position = 0;

        final (next, _) = input.update(
          const MouseMsg(
            action: MouseAction.wheel,
            button: MouseButton.wheelDown,
            x: 0,
            y: 0,
          ),
        );

        final view = Ansi.stripAnsi(next.view() as String);
        expect(view, contains('line2'));
        expect(view, contains('line3'));
        expect(next.textView.viewportStartRow, 1);
      });

      test('multiline core viewport follows cursor to the end', () {
        final input = TextInputModel(multiline: true, maxHeight: 2, width: 20);
        input.focus();
        input.value = 'line1\nline2\nline3\nline4';

        input.position = input.value.length;

        expect(input.textView.viewportStartRow, 2);
        final view = Ansi.stripAnsi(input.view() as String);
        expect(view, contains('line3'));
        expect(view, contains('line4'));
      });

      test('shift+up/down extends multiline selection', () {
        var input = TextInputModel(multiline: true);
        input.focus();
        input.value = 'line1\nline2\nline3';
        input.position = input.value.length;

        final (upSelected, _) = input.update(
          const KeyMsg(Key(KeyType.up, shift: true)),
        );
        expect(upSelected.getSelectedText(), isNotEmpty);

        upSelected.position = 0;
        final (downSelected, _) = upSelected.update(
          const KeyMsg(Key(KeyType.down, shift: true)),
        );
        expect(downSelected.getSelectedText(), isNotEmpty);
        expect(downSelected.editorState.hasSelection, isTrue);
      });

      test('home and end follow wrapped visual line boundaries', () {
        var input = TextInputModel(multiline: true, width: 4);
        input.focus();
        input.value = 'abcdef';
        input.position = 5;

        final (lineStart, _) = input.update(const KeyMsg(Key(KeyType.home)));
        expect(lineStart.position, 4);

        final (lineEnd, _) = lineStart.update(const KeyMsg(Key(KeyType.end)));
        expect(lineEnd.position, 6);
      });

      test(
        'selected cursor grapheme does not leak raw ansi fragments in multiline view',
        () {
          final styles = TextInputStyles(
            focused: TextInputStyleState(
              text: Style().foreground(const AnsiColor(15)),
              selection: Style()
                  .background(const AnsiColor(4))
                  .foreground(const AnsiColor(15)),
            ),
            blurred: TextInputStyleState(
              text: Style().foreground(const AnsiColor(15)),
              selection: Style()
                  .background(const AnsiColor(4))
                  .foreground(const AnsiColor(15)),
            ),
            cursor: TextInputCursorStyle(
              color: const AnsiColor(6),
              blink: false,
            ),
          );
          final input = TextInputModel(
            prompt: '',
            multiline: true,
            width: 8,
            maxHeight: 2,
            useVirtualCursor: true,
            styles: styles,
          )..focus();
          input.value = 'TODO';
          input.selectionStart = 0;
          input.selectionEnd = 4;
          input.position = 0;

          final stripped = Ansi.stripAnsi(input.view() as String);

          expect(stripped, contains('TODO'));
          expect(stripped, isNot(contains('[7m')));
          expect(stripped, isNot(contains('[27m')));
          expect(stripped, isNot(contains('[38;5;')));
        },
      );

      test('clicking far past line end moves cursor to end', () {
        var input = TextInputModel(multiline: true, prompt: ' ');
        input.focus();
        input.value = 'hello world';
        input.position = 0;

        final (next, _) = input.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 40,
            y: 0,
          ),
        );

        expect(next.position, equals(input.value.length));
      });

      test('clicking inside line positions cursor by mouse x', () {
        var input = TextInputModel(multiline: true, prompt: ' ');
        input.focus();
        input.value = 'hello world';
        input.position = 0;

        final (next, _) = input.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 4,
            y: 0,
          ),
        );

        expect(next.position, greaterThan(0));
        expect(next.position, lessThan(input.value.length));
      });

      test('dragging right-to-left selects from line end', () {
        var input = TextInputModel(multiline: true, prompt: ' ');
        input.focus();
        input.value = 'hello world';
        input.position = 0;

        final (pressed, _) = input.update(
          const MouseMsg(
            action: MouseAction.press,
            button: MouseButton.left,
            x: 40,
            y: 0,
          ),
        );
        expect(pressed.position, equals(input.value.length));

        final (dragged, _) = pressed.update(
          const MouseMsg(
            action: MouseAction.motion,
            button: MouseButton.left,
            x: 2,
            y: 0,
          ),
        );

        expect(dragged.getSelectedText(), isNotEmpty);
      });
    });
  });

  group('EchoMode', () {
    test('has normal mode', () {
      expect(EchoMode.normal, isNotNull);
    });

    test('has password mode', () {
      expect(EchoMode.password, isNotNull);
    });

    test('has none mode', () {
      expect(EchoMode.none, isNotNull);
    });
  });

  group('TextInputKeyMap', () {
    test('creates with default bindings', () {
      final keyMap = TextInputKeyMap();
      expect(keyMap.characterForward.keys, isNotEmpty);
      expect(keyMap.characterBackward.keys, isNotEmpty);
      expect(keyMap.deleteCharacterBackward.keys, isNotEmpty);
      expect(keyMap.undo.keys, isNotEmpty);
      expect(keyMap.redo.keys, isNotEmpty);
    });

    test('shortHelp returns bindings', () {
      final keyMap = TextInputKeyMap();
      final help = keyMap.shortHelp();
      expect(help.length, greaterThanOrEqualTo(3));
    });

    test('fullHelp returns grouped bindings', () {
      final keyMap = TextInputKeyMap();
      final help = keyMap.fullHelp();
      expect(help, isNotEmpty);
    });
  });

  group('PasteMsg', () {
    test('creates with content', () {
      final msg = PasteMsg('hello');
      expect(msg.content, 'hello');
    });

    test('inline paste sanitizes content and respects char limit', () {
      final input = TextInputModel(charLimit: 4)..focus();

      final (next, cmd) = input.update(PasteMsg('ab\tcd'));

      expect(cmd, isNull);
      expect(next.value, 'ab c');
      expect(next.position, 4);
    });

    test('large paste can collapse into a reference token', () {
      final input = TextInputModel(
        collapseLargePaste: true,
        collapsedPasteMinChars: 999,
        collapsedPasteMinLines: 2,
      )..focus();

      final (next, cmd) = input.update(PasteMsg('alpha\nbeta'));

      expect(cmd, isNull);
      expect(next.value, '[Pasted ~2 lines]');
      expect(next.lastPasteRef, isNotNull);
      expect(next.pasteBuffer[next.lastPasteRef], 'alpha\nbeta');
    });

    test(
      'very large paste starts chunked insertion and schedules follow-up',
      () {
        final input = TextInputModel()..focus();
        final content = 'a' * 1200;

        final (next, cmd) = input.update(PasteMsg(content));

        expect(cmd, isNotNull);
        expect(next.value, 'a' * 300);
        expect(next.position, 300);
      },
    );
  });

  group('PasteErrorMsg', () {
    test('creates with error', () {
      final error = Exception('Paste failed');
      final msg = PasteErrorMsg(error);
      expect(msg.error, error);
    });
  });
}
