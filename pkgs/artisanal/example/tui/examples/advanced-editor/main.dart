/// Full-screen editor-workbench example built from Artisanal editor primitives.
///
/// Keys: ctrl+p command palette, ctrl+f search for `TODO`, ctrl+d add cursor
/// below, ctrl+z undo, ctrl+y redo, F8 next diagnostic, ctrl+s checkpoint, esc
/// closes overlays, ctrl+c quits. Ordinary textarea editing remains active.
library;

import 'package:artisanal/artisanal.dart' show AnsiColor, Style;
import 'package:artisanal/bubbles.dart' as b;
import 'package:artisanal/editor_core.dart' as core;
import 'package:artisanal/tui.dart' as tui;

final class AdvancedEditorModel implements tui.Model {
  AdvancedEditorModel._(this.editor, this.palette);

  factory AdvancedEditorModel.initial() {
    final defaults = b.defaultTextAreaStyles();
    final syntaxStyles = <String, Style>{
      'syntax.keyword': Style().foreground(const AnsiColor(75)).bold(),
      'syntax.type': Style().foreground(const AnsiColor(215)),
      'syntax.string': Style().foreground(const AnsiColor(114)),
    };
    final editor = b.TextAreaModel(
      prompt: '│ ',
      placeholder: 'Start editing…',
      showLineNumbers: true,
      minimumLineNumberDigits: 3,
      width: 100,
      height: 28,
      styles: defaults.copyWith(
        focused: defaults.focused.copyWith(
          decorationStyles: {
            ...defaults.focused.decorationStyles,
            ...syntaxStyles,
          },
        ),
        blurred: defaults.blurred.copyWith(
          decorationStyles: {
            ...defaults.blurred.decorationStyles,
            ...syntaxStyles,
          },
        ),
      ),
    )..setText(_initialSource, recordHistory: false);
    editor.focus();
    final model = AdvancedEditorModel._(
      editor,
      core.EditorCommandPalette(
        registry: editor.commandRegistry,
        target: editor,
      ),
    );
    model._refreshAnalysis();
    return model;
  }

  b.TextAreaModel editor;
  final core.EditorCommandPalette<b.TextAreaModel> palette;
  int width = 100;
  int height = 30;
  int revision = 0;
  int checkpointRevision = 0;
  String status = 'NORMAL  •  editor core workbench';

  @override
  tui.Cmd? init() => editor.focus();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.InterruptMsg():
        return (this, tui.Cmd.quit());
      case tui.WindowSizeMsg(width: final w, height: final h):
        width = w;
        height = h;
        editor
          ..setWidth(w.clamp(1, 400))
          ..setHeight((h - 2).clamp(1, 200));
        return (this, null);
      case tui.KeyMsg(:final key):
        if (_ctrl(key, 0x63)) return (this, tui.Cmd.quit());
        if (palette.isOpen) return _updatePalette(key);
        if (_ctrl(key, 0x7a)) {
          final result = editor.executeCommand(core.EditorCommandIds.undo);
          if (result == core.EditorCommandDispatchResult.handled) {
            revision++;
            _refreshAnalysis();
          }
          status = result == core.EditorCommandDispatchResult.handled
              ? 'UNDO  •  document revision $revision'
              : 'UNDO  •  nothing to undo';
          return (this, null);
        }
        if (_ctrl(key, 0x79)) {
          final result = editor.executeCommand(core.EditorCommandIds.redo);
          if (result == core.EditorCommandDispatchResult.handled) {
            revision++;
            _refreshAnalysis();
          }
          status = result == core.EditorCommandDispatchResult.handled
              ? 'REDO  •  document revision $revision'
              : 'REDO  •  nothing to redo';
          return (this, null);
        }
        if (_ctrl(key, 0x70)) {
          palette.open();
          status = 'COMMAND  •  type to filter, enter to run';
          return (this, null);
        }
        if (_ctrl(key, 0x66)) {
          final result = editor.startSearch(
            const core.TextSearchQuery(pattern: 'TODO', caseSensitive: false),
          );
          status = 'SEARCH  •  ${result.matches.length} TODO match(es)';
          return (this, null);
        }
        if (_ctrl(key, 0x64)) {
          editor.executeCommand(core.EditorCommandIds.addCursorBelow);
          status =
              'MULTI-CURSOR  •  ${editor.selections.ranges.length} cursors';
          return (this, null);
        }
        if (_ctrl(key, 0x73)) {
          checkpointRevision = revision;
          status = 'CHECKPOINT  •  revision $revision saved in memory';
          return (this, null);
        }
        if (key.type == tui.KeyType.f8) {
          editor.executeCommand(core.EditorCommandIds.nextDiagnostic);
          status = editor.activeDiagnostic?.message ?? 'No diagnostics';
          return (this, null);
        }
    }
    final before = editor.value;
    final beforeCursor = editor.editorState.cursor;
    final (next, command) = editor.update(msg);
    editor = next;
    if (editor.value != before) {
      revision++;
      _refreshAnalysis();
      status = 'INSERT  •  revision $revision';
    } else if (editor.editorState.cursor != beforeCursor) {
      final cursor = editor.editorState.cursor;
      status = 'NORMAL  •  Ln ${cursor.line + 1}, Col ${cursor.column + 1}';
    }
    return (this, command);
  }

  void _refreshAnalysis() {
    final decorations = <core.TextDecorationRange>[];
    for (final query in const [
      core.TextSearchQuery(pattern: r'\b(import|void|final)\b', isRegex: true),
    ]) {
      decorations.addAll(
        core
            .findTextSearchMatches(editor.document, query)
            .matches
            .map(
              (match) => core.TextDecorationRange(
                startOffset: match.startOffset,
                endOffset: match.endOffset,
                styleKey: 'syntax.keyword',
              ),
            ),
      );
    }
    decorations.addAll(
      core
          .findTextSearchMatches(
            editor.document,
            const core.TextSearchQuery(pattern: r"'[^'\n]*'", isRegex: true),
          )
          .matches
          .map(
            (match) => core.TextDecorationRange(
              startOffset: match.startOffset,
              endOffset: match.endOffset,
              styleKey: 'syntax.string',
            ),
          ),
    );
    editor.setDecorationLayer(
      core.textSyntaxDecorationLayerKey,
      decorations,
      priority: core.textSyntaxDecorationLayerPriority,
    );
    final todos = core.findTextSearchMatches(
      editor.document,
      const core.TextSearchQuery(pattern: 'TODO'),
    );
    editor.setDiagnostics([
      for (final match in todos.matches)
        core.TextDiagnosticRange(
          startOffset: match.startOffset,
          endOffset: match.endOffset,
          severity: core.TextDiagnosticSeverity.warning,
          message: 'Resolve this task before shipping.',
        ),
    ]);
  }

  (tui.Model, tui.Cmd?) _updatePalette(tui.Key key) {
    if (key.type == tui.KeyType.escape) {
      palette.close();
      status = 'NORMAL  •  palette dismissed';
    } else if (key.type == tui.KeyType.up) {
      palette.moveSelection(-1);
    } else if (key.type == tui.KeyType.down) {
      palette.moveSelection(1);
    } else if (key.type == tui.KeyType.enter) {
      final selected = palette.selectedCommand?.label;
      final result = palette.executeSelected();
      status = result == core.EditorCommandDispatchResult.handled
          ? 'COMMAND  •  $selected'
          : 'COMMAND  •  no change';
    } else if (key.type == tui.KeyType.backspace) {
      final query = palette.query;
      if (query.isNotEmpty) {
        palette.updateQuery(query.substring(0, query.length - 1));
      }
    } else if (key.type == tui.KeyType.runes && !key.ctrl && !key.alt) {
      palette.updateQuery(palette.query + String.fromCharCodes(key.runes));
    }
    return (this, null);
  }

  @override
  String view() {
    final title = _bar(
      ' ARTISANAL EDITOR  demo.dart',
      'Dart  UTF-8  ${editor.lineCount} lines ',
    );
    final dirty = revision == checkpointRevision ? 'saved' : 'modified';
    final diagnostics = editor.diagnostics.length;
    final cursor = editor.editorState.cursor;
    final position = 'Ln ${cursor.line + 1}, Col ${cursor.column + 1}';
    final footer = _bar(
      ' $status',
      '$position  $dirty  $diagnostics warning(s)  ctrl+p commands  ctrl+c quit ',
    );
    final editorLines = editor.view().toString().split('\n');
    final bodyHeight = (height - 2).clamp(0, height).toInt();
    final body = editorLines.length > bodyHeight
        ? editorLines.sublist(0, bodyHeight)
        : <String>[
            ...editorLines,
            ...List<String>.filled(bodyHeight - editorLines.length, ''),
          ];
    final base = <String>[title, ...body, footer].join('\n');
    if (!palette.isOpen) return base;
    return b.CommandPaletteComponent(
      palette: palette,
      width: (width - 12).clamp(30, 72),
    ).render(base, screenWidth: width, screenHeight: height);
  }

  String _bar(String left, String right) {
    final space = (width - left.length - right.length).clamp(1, width);
    return Style()
        .background(const AnsiColor(236))
        .foreground(const AnsiColor(252))
        .render('$left${' ' * space}$right');
  }

  static bool _ctrl(tui.Key key, int rune) =>
      key.type == tui.KeyType.runes &&
      key.runes.length == 1 &&
      ((key.ctrl && key.runes.first == rune) || key.runes.first == rune - 0x60);
}

const _initialSource = '''import 'package:artisanal/editor_core.dart';

void main() {
  final message = 'Edit this complete full-screen example.';
  // TODO: try search, diagnostics, commands, and multiple cursors.
  print(message);
}
''';

/// Reclaims Ctrl+Z from Bubble Tea's suspend lifecycle for editor undo.
tui.Msg? _editorInputFilter(tui.Model model, tui.Msg msg) {
  if (msg is tui.SuspendMsg) {
    return const tui.KeyMsg(
      tui.Key(tui.KeyType.runes, runes: [0x7a], ctrl: true),
    );
  }
  return msg;
}

Future<void> main() async {
  await tui.runProgram(
    AdvancedEditorModel.initial(),
    options: const tui.ProgramOptions(
      altScreen: true,
      hideCursor: true,
      bracketedPaste: true,
    ).withFilter(_editorInputFilter).withoutSuspendSignal(),
  );
}
