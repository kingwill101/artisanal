/// Prompt-composer example: terminal prompt editing on the artisanal core.
///
/// Demonstrates four composer integrations built on the editor core:
/// atomic large-paste elements, prompt normalization, `$EDITOR` round-trip
/// via [Cmd.openEditor], and IDE selection ingestion. A collapsed paste keeps
/// its full content in a sidecar, opens a preview at either cursor edge, and
/// expands only when submitted or opened in the external editor.
///
/// Keys:
/// - type normally to compose; `enter` inserts a newline
/// - bracketed pastes over 20 lines or 1200 characters collapse to one
///   non-editable `[Pasted: …]` element; `ctrl+v` simulates one
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
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

/// Fake file content backing the simulated IDE selection.
const _ideFileContent = 'void main() {\n  print("hello");\n}\n';
const _pasteDecorationLayer = 'prompt.paste';
const _pasteDecorationStyle = 'prompt.paste.collapsed';
const _collapsedPasteMinChars = 1200;
const _collapsedPasteMinLines = 20;

final class _EditorFinishedMsg extends tui.Msg {
  const _EditorFinishedMsg(this.result, this.filePath);
  final tui.ExecResult result;
  final String filePath;
}

final class _CollapsedPaste {
  _CollapsedPaste({
    required this.displayText,
    required this.fullText,
    required this.lineCount,
  });

  final String displayText;
  final String fullText;
  final int lineCount;
  int? elementId;
}

final class PromptComposerModel implements tui.Model {
  PromptComposerModel({required this.composer}) {
    composer.focus();
  }

  factory PromptComposerModel.initial() {
    final styles = b.defaultTextAreaStyles();
    final pasteStyle = Style()
        .background(const AnsiColor(252))
        .foreground(const AnsiColor(240));
    styles.focused.decorationStyles = {
      ...styles.focused.decorationStyles,
      _pasteDecorationStyle: pasteStyle,
    };
    styles.blurred.decorationStyles = {
      ...styles.blurred.decorationStyles,
      _pasteDecorationStyle: pasteStyle,
    };
    final composer = b.TextAreaModel(
      prompt: '❯ ',
      placeholder: 'Type a prompt… (ctrl+t submit, ctrl+o editor)',
      showLineNumbers: false,
      styles: styles,
    )..setHeight(8);
    return PromptComposerModel(composer: composer);
  }

  b.TextAreaModel composer;
  final core.PlaceholderTracker placeholders = core.PlaceholderTracker();
  final core.InlineElementStore elements = core.InlineElementStore();
  final List<_CollapsedPaste> _collapsedPastes = <_CollapsedPaste>[];
  final List<String> submitted = <String>[];
  core.EditorSelection? ideSelection;
  String? dismissedSelectionKey;
  String? status;
  String? lastKey;
  int pasteCount = 0;
  int width = 80;
  int height = 24;

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
        if (_handleCollapsedPasteKey(key)) {
          return (this, null);
        }
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
      case tui.PasteTextMsg(:final content):
        if (_collapsePasteIfLarge(content)) return (this, null);
      case tui.PasteMsg(:final content):
        if (_collapsePasteIfLarge(content)) return (this, null);
      case b.TextAreaPasteMsg(:final content):
        if (_collapsePasteIfLarge(content)) return (this, null);
      case tui.WindowSizeMsg(width: final w, height: final h):
        width = w;
        height = h;
        composer.setWidth(w - 4);
    }
    final before = composer.value;
    final (next, cmd) = composer.update(msg);
    composer = next;
    if (composer.value != before) _syncCollapsedPastes();
    _snapCursorOutOfCollapsedPaste();
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
    final fullText = List<String>.generate(
      28,
      (i) => 'pasted line ${i + 1}',
    ).join('\n');
    _insertCollapsedPaste(fullText, lineCount: 28);
  }

  bool _collapsePasteIfLarge(String content) {
    final plan = core.planTextPaste(
      content,
      collapseLargePaste: true,
      collapsedPasteMinChars: _collapsedPasteMinChars,
      collapsedPasteMinLines: _collapsedPasteMinLines,
      chunkThresholdRunes: _collapsedPasteMinChars,
    );
    if (!plan.collapse) return false;
    _insertCollapsedPaste(content, lineCount: plan.lineCount);
    return true;
  }

  void _insertCollapsedPaste(String fullText, {required int lineCount}) {
    pasteCount++;
    final display = '[Pasted: $lineCount lines #$pasteCount]';
    composer.insertString(display);
    _collapsedPastes.add(
      _CollapsedPaste(
        displayText: display,
        fullText: fullText,
        lineCount: lineCount,
      ),
    );
    _syncCollapsedPastes();
    status =
        'Collapsed paste #$pasteCount ($lineCount lines, ${fullText.length} chars).';
  }

  void _syncCollapsedPastes() {
    elements.clear();
    placeholders.clear();
    for (final paste in _collapsedPastes) {
      paste.elementId = null;
      final matches = core.findTextSearchMatches(
        composer.document,
        core.TextSearchQuery(pattern: paste.displayText),
        maxResults: 1,
      ).matches;
      if (matches.isEmpty) continue;
      final match = matches.single;
      paste.elementId = elements.create(
        kind: core.inlineElementPaste,
        startOffset: match.startOffset,
        endOffset: match.endOffset,
      );
      placeholders.track(
        core.TrackedPlaceholderRange(
          startOffset: match.startOffset,
          endOffset: match.endOffset,
          displayText: paste.displayText,
          fullText: paste.fullText,
        ),
      );
    }
    _syncPlaceholderDecorations();
  }

  _CollapsedPaste? get _activeCollapsedPaste {
    final offset = composer.cursorOffset;
    for (final paste in _collapsedPastes) {
      final id = paste.elementId;
      final element = id == null ? null : elements.get(id);
      if (element != null &&
          (element.containsOffset(offset) ||
              element.startOffset == offset ||
              element.endOffset == offset)) {
        return paste;
      }
    }
    return null;
  }

  /// Whether the cursor is touching a collapsed paste preview edge.
  bool get isPastePreviewVisible => _activeCollapsedPaste != null;

  bool _handleCollapsedPasteKey(tui.Key key) {
    final paste = _activeCollapsedPaste;
    final id = paste?.elementId;
    final element = id == null ? null : elements.get(id);
    if (paste == null || element == null) return false;
    final offset = composer.cursorOffset;

    if (key.type == tui.KeyType.left &&
        offset > element.startOffset &&
        offset <= element.endOffset) {
      _setCursorOffset(element.startOffset);
      return true;
    }
    if (key.type == tui.KeyType.right &&
        offset >= element.startOffset &&
        offset < element.endOffset) {
      _setCursorOffset(element.endOffset);
      return true;
    }
    if (key.type == tui.KeyType.backspace &&
        offset > element.startOffset &&
        offset <= element.endOffset) {
      _deleteCollapsedPaste(element, paste);
      return true;
    }
    if (key.type == tui.KeyType.delete &&
        offset >= element.startOffset &&
        offset < element.endOffset) {
      _deleteCollapsedPaste(element, paste);
      return true;
    }
    if (offset > element.startOffset && offset < element.endOffset) {
      final distanceFromStart = offset - element.startOffset;
      final distanceFromEnd = element.endOffset - offset;
      _setCursorOffset(
        distanceFromStart <= distanceFromEnd
            ? element.startOffset
            : element.endOffset,
      );
    }
    return false;
  }

  void _deleteCollapsedPaste(
    core.InlineElement element,
    _CollapsedPaste paste,
  ) {
    composer.setSelections(
      core.TextSelectionSet([
        core.TextSelectionRange(
          startOffset: element.startOffset,
          endOffset: element.endOffset,
        ),
      ], primaryOffset: element.endOffset),
    );
    composer.deleteSelections();
    _syncCollapsedPastes();
    status = 'Removed collapsed paste #${_collapsedPastes.indexOf(paste) + 1}.';
  }

  void _snapCursorOutOfCollapsedPaste() {
    final paste = _activeCollapsedPaste;
    final id = paste?.elementId;
    final element = id == null ? null : elements.get(id);
    if (element == null) return;
    final offset = composer.cursorOffset;
    if (offset <= element.startOffset || offset >= element.endOffset) return;
    final distanceFromStart = offset - element.startOffset;
    final distanceFromEnd = element.endOffset - offset;
    _setCursorOffset(
      distanceFromStart <= distanceFromEnd
          ? element.startOffset
          : element.endOffset,
    );
  }

  void _setCursorOffset(int offset) {
    composer.setSelections(core.TextSelectionSet.collapsed(offset));
  }

  void _syncPlaceholderDecorations() {
    composer.setDecorationLayer(
      _pasteDecorationLayer,
      [
        for (final range in placeholders.ranges)
          core.TextDecorationRange(
            startOffset: range.startOffset,
            endOffset: range.endOffset,
            styleKey: _pasteDecorationStyle,
          ),
      ],
    );
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
    _collapsedPastes.clear();
    elements.clear();
    placeholders.clear();
    _syncPlaceholderDecorations();
    status = 'Submitted (${normalized.length} chars).';
  }

  tui.Cmd? _openExternalEditor() {
    final draft = core.expandPlaceholderRanges(
      composer.value,
      placeholders.ranges,
    );
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
        _collapsedPastes.clear();
        elements.clear();
        placeholders.clear();
        _syncPlaceholderDecorations();
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
    final base = buffer.toString();
    final paste = _activeCollapsedPaste;
    if (paste == null) return base;
    final lines = paste.fullText.split('\n');
    final visibleCount = (height - 10).clamp(3, 12);
    return b.renderModal(
      base,
      [
        ...lines.take(visibleCount),
        if (lines.length > visibleCount)
          '… (${lines.length - visibleCount} more lines)',
      ],
      chrome: b.ModalChrome(
        title: 'Pasted: ${paste.lineCount} lines',
        footer: const ['←/→ move past  backspace/delete remove'],
        width: (width - 12).clamp(32, 76),
        maxHeight: height - 4,
      ),
      screenW: width,
      screenH: height,
    );
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
