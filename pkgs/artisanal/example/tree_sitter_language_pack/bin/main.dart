import 'package:artisanal/artisanal.dart' show AnsiColor, Style;
import 'package:artisanal/bubbles.dart' as bubbles;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_tree_sitter_language_pack_example/tree_sitter_language_pack_adapter.dart';

const _pythonSource = '''
# Edit this Python source; Tree-sitter reparses after every change.
import os

class Greeter:
    """Build friendly greetings."""

    def greet(self, name):
        return f'Hi {name} from {os.name}'
''';

final class _AnalysisReadyMsg extends tui.Msg {
  const _AnalysisReadyMsg(this.generation, this.analysis);

  final int generation;
  final LanguagePackAnalysis analysis;
}

final class _AnalysisFailedMsg extends tui.Msg {
  const _AnalysisFailedMsg(this.generation, this.error);

  final int generation;
  final Object error;
}

final class TreeSitterEditorModel implements tui.Model {
  TreeSitterEditorModel(this.provider)
    : editor = bubbles.TextAreaModel(
        prompt: '│ ',
        showLineNumbers: true,
        minimumLineNumberDigits: 3,
        width: 100,
        height: 26,
        styles: _editorStyles(),
      )..setText(_pythonSource, recordHistory: false) {
    editor.focus();
  }

  final LanguagePackSyntaxProvider provider;
  bubbles.TextAreaModel editor;
  int width = 100;
  int height = 28;
  int _generation = 0;
  int _nodeCount = 0;
  String _status = 'starting Tree-sitter…';

  @override
  tui.Cmd? init() => _analyze();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.InterruptMsg():
        return (this, tui.Cmd.quit());
      case tui.WindowSizeMsg(width: final nextWidth, height: final nextHeight):
        width = nextWidth;
        height = nextHeight;
        editor
          ..setWidth(nextWidth.clamp(1, 400))
          ..setHeight((nextHeight - 2).clamp(1, 200));
        return (this, null);
      case _AnalysisReadyMsg(:final generation, :final analysis):
        if (generation != _generation) return (this, null);
        editor.setDecorationLayer(
          'tree-sitter',
          analysis.decorations,
          priority: 100,
        );
        _nodeCount = analysis.tree.nodes.length - 1;
        _status = 'highlighted ${analysis.decorations.length} ranges';
        return (this, null);
      case _AnalysisFailedMsg(:final generation, :final error):
        if (generation == _generation) _status = 'parse failed: $error';
        return (this, null);
      case tui.KeyMsg(:final key) when key.ctrl && key.runes.contains(0x63):
        return (this, tui.Cmd.quit());
    }

    final before = editor.value;
    final (next, command) = editor.update(msg);
    editor = next;
    if (editor.value == before) return (this, command);
    _status = 'parsing…';
    return (this, tui.Cmd.batch([?command, _analyze()]));
  }

  tui.Cmd _analyze() {
    final generation = ++_generation;
    final document = editor.document.copy();
    return tui.Cmd.perform(
      () => provider.analyze(document, revision: generation),
      onSuccess: (analysis) => _AnalysisReadyMsg(generation, analysis),
      onError: (error, _) => _AnalysisFailedMsg(generation, error),
    );
  }

  @override
  String view() {
    final header = ' TREE-SITTER PYTHON  •  live syntax highlighting';
    final footer = ' $_status  •  $_nodeCount structure nodes  •  ctrl+c quit';
    return '$header\n${editor.view()}\n$footer';
  }
}

bubbles.TextAreaStyles _editorStyles() {
  final defaults = bubbles.defaultTextAreaStyles();
  final syntax = <String, Style>{
    'syntax.keyword': Style().foreground(const AnsiColor(75)).bold(),
    'syntax.comment': Style().foreground(const AnsiColor(245)).italic(),
    'syntax.string': Style().foreground(const AnsiColor(114)),
    'syntax.number': Style().foreground(const AnsiColor(173)),
    'syntax.identifier': Style().foreground(const AnsiColor(81)),
    'syntax.constant': Style().foreground(const AnsiColor(173)).bold(),
    'syntax.operator': Style().foreground(const AnsiColor(204)),
  };
  return defaults.copyWith(
    focused: defaults.focused.copyWith(
      decorationStyles: {...defaults.focused.decorationStyles, ...syntax},
    ),
    blurred: defaults.blurred.copyWith(
      decorationStyles: {...defaults.blurred.decorationStyles, ...syntax},
    ),
  );
}

Future<void> main() async {
  await LanguagePackRuntime.initialize();
  try {
    final provider = await LanguagePackSyntaxProvider.create('python');
    await tui.runProgram(
      TreeSitterEditorModel(provider),
      options: const tui.ProgramOptions(
        altScreen: true,
        hideCursor: true,
        bracketedPaste: true,
      ),
    );
  } finally {
    LanguagePackRuntime.dispose();
  }
}
