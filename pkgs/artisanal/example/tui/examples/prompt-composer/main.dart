/// Prompt-composer example: terminal prompt editing on the artisanal core.
///
/// Demonstrates four composer integrations built on the editor core:
/// tracked paste placeholders, prompt normalization, `$EDITOR` round-trip
/// via [Cmd.openEditor], and IDE selection ingestion.
///
/// Keys:
/// - type normally to compose; `enter` inserts a newline
/// - `ctrl+v` simulates a large paste (inserts a tracked `[Pasted …]`
///   placeholder; the full text is restored on submit)
/// - `ctrl+t` submits (expands placeholders, normalizes, clears).
///   (`ctrl+s` also submits: the runtime disables XOFF flow control while
///   raw mode owns the terminal, so it arrives as a key instead of freezing
///   output.)
/// - `ctrl+o` opens `$EDITOR` on the draft (terminal is released/restored)
/// - `ctrl+g` attaches a simulated IDE selection; `ctrl+d` dismisses it
/// - `ctrl+c` / `q` quits (when the composer is empty, `q` quits)
library;

import 'dart:io' as io;

import 'package:artisanal/bubbles.dart' as b;
import 'package:artisanal/editor_core.dart' as core;
import 'package:artisanal/tui.dart' as tui;

/// Fake file content backing the simulated IDE selection.
const _ideFileContent = 'void main() {\n  print("hello");\n}\n';

final class _EditorFinishedMsg extends tui.Msg {
  const _EditorFinishedMsg(this.result, this.filePath);
  final tui.ExecResult result;
  final String filePath;
}

final class PromptComposerModel implements tui.Model {
  PromptComposerModel({required this.composer}) {
    composer.focus();
  }

  factory PromptComposerModel.initial() {
    final composer = b.TextAreaModel(
      prompt: '❯ ',
      placeholder: 'Type a prompt… (ctrl+t submit, ctrl+o editor)',
      showLineNumbers: false,
    )..setHeight(8);
    return PromptComposerModel(composer: composer);
  }

  b.TextAreaModel composer;
  final core.PlaceholderTracker placeholders = core.PlaceholderTracker();
  final List<String> submitted = <String>[];
  core.EditorSelection? ideSelection;
  String? dismissedSelectionKey;
  String? status;
  String? lastKey;
  int pasteCount = 0;
  int width = 80;

  core.EditorSelection? get activeIdeSelection {
    final selection = ideSelection;
    if (selection == null) return null;
    if (core.editorSelectionKey(selection) == dismissedSelectionKey) {
      return null;
    }
    return selection;
  }

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(:final key):
        lastKey = _describeKey(key);
        if (_isCtrlRune(key, 0x63)) {
          return (this, tui.Cmd.quit());
        }
        if (_isCtrlRune(key, 0x76)) {
          _simulateBigPaste();
          return (this, null);
        }
        if (_isCtrlRune(key, 0x73) || _isCtrlRune(key, 0x74)) {
          _submit();
          return (this, null);
        }
        if (_isCtrlRune(key, 0x6f)) {
          return (this, _openExternalEditor());
        }
        if (_isCtrlRune(key, 0x67)) {
          _attachIdeSelection();
          return (this, null);
        }
        if (_isCtrlRune(key, 0x64)) {
          dismissedSelectionKey = core.editorSelectionKey(ideSelection);
          status = 'IDE context dismissed.';
          return (this, null);
        }
        if (_isPlainRune(key, 0x71) && composer.value.isEmpty) {
          return (this, tui.Cmd.quit());
        }
      case tui.InterruptMsg():
        // Ctrl+C arrives here under the default ProgramOptions
        // (SIGINT is converted to InterruptMsg instead of a KeyMsg).
        return (this, tui.Cmd.quit());
      case _EditorFinishedMsg(:final result, :final filePath):
        _finishExternalEditor(result, filePath);
        return (this, null);
      case tui.WindowSizeMsg(width: final w):
        width = w;
        composer.setWidth(w - 4);
    }
    final (next, cmd) = composer.update(msg);
    composer = next;
    return (this, cmd);
  }

  /// Matches a Ctrl+letter binding in either form terminals produce it:
  /// the `ctrl` flag with the letter rune (`ctrl` + `c`), or the raw
  /// control code (`0x03` for Ctrl+C, i.e. letter minus `0x60`).
  static bool _isCtrlRune(tui.Key key, int rune) {
    if (key.type != tui.KeyType.runes ||
        key.runes.length != 1 ||
        key.alt ||
        key.meta) {
      return false;
    }
    final code = key.runes.first;
    return (key.ctrl && code == rune) || code == rune - 0x60;
  }

  static bool _isPlainRune(tui.Key key, int rune) =>
      !key.ctrl &&
      !key.alt &&
      key.type == tui.KeyType.runes &&
      key.runes.length == 1 &&
      key.runes.first == rune;

  void _simulateBigPaste() {
    pasteCount++;
    final fullText = List<String>.generate(
      8,
      (i) => 'pasted line ${i + 1}',
    ).join('\n');
    final display = '[Pasted ~8 lines #$pasteCount]';
    composer.insertString(display);
    final offset = composer.value.indexOf(display);
    if (offset >= 0) {
      placeholders.track(
        core.TrackedPlaceholderRange(
          startOffset: offset,
          endOffset: offset + display.length,
          displayText: display,
          fullText: fullText,
        ),
      );
      status = 'Tracked placeholder #$pasteCount (${fullText.length} chars).';
    }
  }

  void _submit() {
    final expanded = core.expandPlaceholderRanges(
      composer.value,
      placeholders.ranges,
    );
    final normalized = core.normalizePromptContent(expanded);
    if (normalized.isEmpty) {
      status = 'Nothing to submit.';
      return;
    }
    final selection = activeIdeSelection;
    final buffer = StringBuffer(normalized);
    if (selection != null) {
      buffer.write('\n---\n');
      buffer.write(core.formatEditorSelectionContext(selection));
    }
    submitted.add(buffer.toString());
    composer.setText('');
    placeholders.clear();
    status = 'Submitted (${normalized.length} chars).';
  }

  tui.Cmd? _openExternalEditor() {
    final draft = composer.value;
    final tempDir = io.Directory.systemTemp.createTempSync('prompt_composer_');
    final file = io.File('${tempDir.path}/prompt.md')
      ..writeAsStringSync(draft);
    status = 'External editor open…';
    return tui.Cmd.openEditor(
      file.path,
      onComplete: (result) => _EditorFinishedMsg(result, file.path),
    );
  }

  void _finishExternalEditor(tui.ExecResult result, String filePath) {
    try {
      if (result.success) {
        final edited = io.File(filePath).readAsStringSync();
        composer.setText(core.normalizePromptContent(edited));
        placeholders.clear();
        status = 'External edit applied.';
      } else {
        status = 'Editor exited with code ${result.exitCode}.';
      }
    } on io.FileSystemException {
      status = 'Could not read editor file.';
    } finally {
      io.Directory(io.File(filePath).parent.path).deleteSync(recursive: true);
    }
  }

  void _attachIdeSelection() {
    // Simulated wire selection (1-based), as produced by IDE sources.
    ideSelection = const core.EditorSelection(
      filePath: 'lib/main.dart',
      source: 'zed',
      ranges: [
        core.EditorSelectionRange(
          text: 'print("hello");',
          start: core.EditorSelectionPosition(line: 2, character: 3),
          end: core.EditorSelectionPosition(line: 2, character: 18),
        ),
      ],
    );
    dismissedSelectionKey = null;
    final document = core.TextDocument(text: _ideFileContent);
    final resolved = core.resolveEditorSelectionRange(
      document,
      ideSelection!.ranges.single,
    );
    status =
        'IDE selection ${core.editorSelectionRangeLabel(ideSelection!.ranges.single)} '
        '→ offsets ${resolved.startOffset}–${resolved.endOffset}.';
  }

  @override
  String view() {
    final buffer = StringBuffer();
    buffer.writeln('Prompt composer demo');
    buffer.writeln(composer.view());
    final selection = activeIdeSelection;
    if (selection != null) {
      buffer.writeln('IDE: ${selection.filePath} '
          '${core.editorSelectionRangeLabel(selection.ranges.single) ?? ''}');
    }
    if (!placeholders.isEmpty) {
      buffer.writeln('Placeholders: ${placeholders.ranges.length} tracked.');
    }
    if (status != null) buffer.writeln(status);
    if (lastKey != null) buffer.writeln('Last key: $lastKey');
    if (submitted.isNotEmpty) {
      buffer.writeln('--- submitted (${submitted.length}) ---');
      buffer.writeln(submitted.last);
    }
    buffer.writeln(
      '[ctrl+v paste] [ctrl+t submit] [ctrl+o \$EDITOR] [ctrl+g IDE] [q quit]',
    );
    return buffer.toString();
  }

  /// One-line summary of a key event for the debug footer.
  static String _describeKey(tui.Key key) {
    final runes = key.runes
        .map((rune) => '0x${rune.toRadixString(16).padLeft(2, '0')}')
        .join(' ');
    final mods = [
      if (key.ctrl) 'ctrl',
      if (key.alt) 'alt',
      if (key.shift) 'shift',
      if (key.meta) 'meta',
    ].join('+');
    return '${key.type.name} [$runes]${mods.isEmpty ? '' : ' $mods'}';
  }
}

Future<void> main() async {
  await tui.runProgram(
    PromptComposerModel.initial(),
    options: const tui.ProgramOptions(altScreen: false),
  );
}
