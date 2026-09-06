/// Full-screen editor-workbench example built from Artisanal editor primitives.
///
/// Keys:
/// - `ctrl+p` command palette
/// - `ctrl+f` find overlay (`ctrl+h` find and replace)
/// - `ctrl+space` completions, `ctrl+.` code actions
/// - `ctrl+d` add cursor below, `tab`/`shift+tab` indent
/// - `ctrl+z` undo, `ctrl+y` redo, `F8` next diagnostic
/// - `ctrl+s` save, `ctrl+m` matching bracket, `F9` toggle fold
/// - `esc` closes overlays, `ctrl+c` quits
library;

import 'dart:io' as io;

import 'package:artisanal/artisanal.dart' show AnsiColor, Style;
import 'package:artisanal/bubbles.dart' as b;
import 'package:artisanal/editor_core.dart' as core;
import 'package:artisanal/tui.dart' as tui;

enum _Overlay { none, palette, search, codeActions, recovery }

enum _SearchField { find, replace }

tui.Cmd _batch(Iterable<tui.Cmd?> commands) =>
    tui.Cmd.batch([for (final command in commands) ?command]);

final class _PersistenceDoneMsg extends tui.Msg {
  const _PersistenceDoneMsg({
    required this.kind,
    required this.ok,
    this.revision,
    this.error,
  });

  final String kind;
  final bool ok;
  final int? revision;
  final Object? error;
}

final class AdvancedEditorRecoveryMsg extends tui.Msg {
  const AdvancedEditorRecoveryMsg(this.snapshot);
  final core.EditorDocumentSnapshot? snapshot;
}

final class _SyntaxReadyMsg extends tui.Msg {
  const _SyntaxReadyMsg(this.snapshot);
  final core.TextSyntaxSnapshot<int>? snapshot;
}

final class AdvancedEditorModel implements tui.Model {
  AdvancedEditorModel._({
    required this.editor,
    required this.palette,
    required this.persistence,
    required this.syntaxSession,
    required this.asyncSyntax,
    required this.documentId,
  });

  factory AdvancedEditorModel.initial({
    core.EditorDocumentStore? store,
    String documentId = 'demo.dart',
    Duration syntaxDelay = Duration.zero,
  }) {
    final defaults = b.defaultTextAreaStyles();
    final syntaxStyles = <String, Style>{
      'syntax.keyword': Style().foreground(const AnsiColor(75)).bold(),
      'syntax.type': Style().foreground(const AnsiColor(215)),
      'syntax.string': Style().foreground(const AnsiColor(114)),
      'syntax.comment': Style().foreground(const AnsiColor(245)).italic(),
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
    editor.markSaved();
    final resolvedStore = store ?? _defaultStore();
    final model = AdvancedEditorModel._(
      editor: editor,
      palette: core.EditorCommandPalette(
        registry: editor.commandRegistry,
        target: editor,
      ),
      persistence: core.EditorPersistenceSession(
        documentId: documentId,
        store: resolvedStore,
      ),
      syntaxSession: core.TextSyntaxSession<int>(
        provider: DemoDartSyntaxProvider(),
        language: 'dart',
      ),
      asyncSyntax: core.AsyncTextSyntaxSession<int>(
        provider: DemoAsyncDartSyntaxProvider(delay: syntaxDelay),
        language: 'dart',
      ),
      documentId: documentId,
    );
    model._registerDemoCommands();
    model._refreshAnalysis();
    model._refreshFolds();
    return model;
  }

  b.TextAreaModel editor;
  final core.EditorCommandPalette<b.TextAreaModel> palette;
  final core.EditorPersistenceSession persistence;
  final core.TextSyntaxSession<int> syntaxSession;
  final core.AsyncTextSyntaxSession<int> asyncSyntax;
  final String documentId;
  final tui.CommandPaletteController codeActionPalette =
      tui.CommandPaletteController();

  int width = 100;
  int height = 30;
  int revision = 0;
  String status = 'NORMAL  •  editor core workbench';
  _Overlay _overlay = _Overlay.none;
  _SearchField _searchField = _SearchField.find;
  String searchQuery = '';
  String replaceQuery = '';

  core.SnippetSession? snippet;
  int snippetOrigin = 0;
  core.EditorDocumentSnapshot? pendingRecovery;
  Object? saveError;
  int syntaxGeneration = 0;

  bool get isDirty =>
      editor.isDirty ||
      (persistence.savedRevision != null && persistence.isDirty(revision));

  @override
  tui.Cmd? init() {
    editor.focus();
    return _batch([
      tui.Cmd.perform(
        persistence.loadRecovery,
        onSuccess: AdvancedEditorRecoveryMsg.new,
      ),
      _syntaxCommand(),
    ]);
  }

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
      case AdvancedEditorRecoveryMsg(:final snapshot):
        if (snapshot != null) {
          pendingRecovery = snapshot;
          _overlay = _Overlay.recovery;
          status = 'RECOVERY  •  unsaved checkpoint found';
        }
        return (this, null);
      case _PersistenceDoneMsg(
        :final kind,
        :final ok,
        :final error,
        :final revision,
      ):
        if (!ok && error == null) return (this, null);
        saveError = ok ? null : error;
        if (ok && kind == 'save') {
          editor.markSaved();
          status = 'SAVED  •  revision ${revision ?? this.revision}';
        } else if (ok && kind == 'checkpoint') {
          status =
              'CHECKPOINT  •  recovery revision ${revision ?? this.revision}';
        } else {
          status = 'SAVE FAILED  •  ${error ?? 'unknown error'}';
        }
        return (this, null);
      case _SyntaxReadyMsg(:final snapshot):
        if (snapshot != null) {
          editor.setDecorationLayer(
            core.textSyntaxDecorationLayerKey,
            snapshot.decorations,
            priority: core.textSyntaxDecorationLayerPriority,
          );
          syntaxGeneration = snapshot.state ?? syntaxGeneration;
        }
        return (this, null);
      case tui.KeyMsg(:final key):
        if (_ctrl(key, 0x63)) return (this, tui.Cmd.quit());
        return _updateKey(key);
    }

    final before = editor.value;
    final beforeCursor = editor.editorState.cursor;
    final (next, command) = editor.update(msg);
    editor = next;
    var followUp = command;
    if (msg is b.TextAreaCodeActionsMsg && editor.codeActions.isNotEmpty) {
      _openCodeActionPalette();
    }
    if (editor.value != before) {
      revision++;
      snippet = null;
      _refreshAnalysis();
      _refreshFolds();
      followUp = _batch([command, _syntaxCommand(), _checkpointCommand()]);
      status = 'INSERT  •  revision $revision';
    } else if (editor.editorState.cursor != beforeCursor) {
      final cursor = editor.editorState.cursor;
      status = 'NORMAL  •  Ln ${cursor.line + 1}, Col ${cursor.column + 1}';
    }
    return (this, followUp);
  }

  (tui.Model, tui.Cmd?) _updateKey(tui.Key key) {
    switch (_overlay) {
      case _Overlay.palette:
        return _updatePalette(key);
      case _Overlay.search:
        return _updateSearch(key);
      case _Overlay.codeActions:
        return _updateCodeActions(key);
      case _Overlay.recovery:
        return _updateRecovery(key);
      case _Overlay.none:
        break;
    }

    if (_ctrl(key, 0x70)) {
      _overlay = _Overlay.palette;
      palette.open();
      status = 'COMMAND  •  type to filter, enter to run';
      return (this, null);
    }
    if (_ctrl(key, 0x66) || _ctrl(key, 0x68)) {
      _overlay = _Overlay.search;
      _searchField = _SearchField.find;
      if (searchQuery.isEmpty) searchQuery = editor.getSelectedText();
      _applySearch();
      status = _ctrl(key, 0x68)
          ? 'REPLACE  •  tab switches fields, enter next match'
          : 'FIND  •  enter next, shift+enter previous';
      return (this, null);
    }
    if (key.type == tui.KeyType.space && key.ctrl) {
      status = 'COMPLETION  •  ↑/↓ select, enter accept, esc dismiss';
      return (this, editor.requestCompletions(const DemoCompletionProvider()));
    }
    if (_ctrl(key, 0x2e) ||
        (key.type == tui.KeyType.runes &&
            key.ctrl &&
            key.runes.first == 0x2e)) {
      status = 'CODE ACTION  •  requesting fixes';
      return (
        this,
        editor.requestCodeActions(DemoCodeActionProvider(documentId)),
      );
    }
    if (_ctrl(key, 0x64)) {
      editor.executeCommand(core.EditorCommandIds.addCursorBelow);
      status = 'MULTI-CURSOR  •  ${editor.selections.ranges.length} cursors';
      return (this, null);
    }
    if (_ctrl(key, 0x73)) {
      return (this, _saveCommand());
    }
    if (_ctrl(key, 0x7a)) {
      final result = editor.executeCommand(core.EditorCommandIds.undo);
      if (result == core.EditorCommandDispatchResult.handled) {
        revision++;
        _refreshAnalysis();
        _refreshFolds();
      }
      status = result == core.EditorCommandDispatchResult.handled
          ? 'UNDO  •  document revision $revision'
          : 'UNDO  •  nothing to undo';
      return (
        this,
        _batch([
          _syntaxCommand(),
          if (result == core.EditorCommandDispatchResult.handled)
            _checkpointCommand(),
        ]),
      );
    }
    if (_ctrl(key, 0x79)) {
      final result = editor.executeCommand(core.EditorCommandIds.redo);
      if (result == core.EditorCommandDispatchResult.handled) {
        revision++;
        _refreshAnalysis();
        _refreshFolds();
      }
      status = result == core.EditorCommandDispatchResult.handled
          ? 'REDO  •  document revision $revision'
          : 'REDO  •  nothing to redo';
      return (
        this,
        _batch([
          _syntaxCommand(),
          if (result == core.EditorCommandDispatchResult.handled)
            _checkpointCommand(),
        ]),
      );
    }
    if (key.type == tui.KeyType.f8) {
      editor.executeCommand(core.EditorCommandIds.nextDiagnostic);
      status = editor.activeDiagnostic?.message ?? 'No diagnostics';
      return (this, null);
    }
    if (key.type == tui.KeyType.f9) {
      _toggleFoldAtCursor();
      return (this, null);
    }
    if (_ctrl(key, 0x6d)) {
      _jumpToBracket();
      return (this, null);
    }
    if (snippet != null && key.type == tui.KeyType.tab) {
      _advanceSnippet(back: key.shift);
      return (this, null);
    }

    final before = editor.value;
    final beforeCursor = editor.editorState.cursor;
    final (next, command) = editor.update(tui.KeyMsg(key));
    editor = next;
    if (editor.value != before) {
      revision++;
      snippet = null;
      _refreshAnalysis();
      _refreshFolds();
      status = 'INSERT  •  revision $revision';
      return (this, _batch([command, _syntaxCommand(), _checkpointCommand()]));
    }
    if (editor.editorState.cursor != beforeCursor) {
      final cursor = editor.editorState.cursor;
      status = 'NORMAL  •  Ln ${cursor.line + 1}, Col ${cursor.column + 1}';
    }
    return (this, command);
  }

  (tui.Model, tui.Cmd?) _updatePalette(tui.Key key) {
    if (key.type == tui.KeyType.escape) {
      palette.close();
      _overlay = _Overlay.none;
      status = 'NORMAL  •  palette dismissed';
    } else if (key.type == tui.KeyType.up) {
      palette.moveSelection(-1);
    } else if (key.type == tui.KeyType.down) {
      palette.moveSelection(1);
    } else if (key.type == tui.KeyType.enter) {
      final selected = palette.selectedCommand;
      final beforeText = editor.value;
      final beforeRevision = revision;
      final result = palette.executeSelected();
      _overlay = _Overlay.none;
      tui.Cmd? followUp;
      if (editor.value != beforeText) {
        if (revision == beforeRevision) revision++;
        _refreshAnalysis();
        _refreshFolds();
        followUp = _batch([_syntaxCommand(), _checkpointCommand()]);
      }
      status = result == core.EditorCommandDispatchResult.handled
          ? 'COMMAND  •  ${selected?.label}'
          : 'COMMAND  •  no change';
      return (this, followUp);
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

  (tui.Model, tui.Cmd?) _updateSearch(tui.Key key) {
    if (key.type == tui.KeyType.escape) {
      _overlay = _Overlay.none;
      editor.closeSearch();
      status = 'NORMAL  •  search dismissed';
      return (this, null);
    }
    if (key.type == tui.KeyType.tab) {
      _searchField = _searchField == _SearchField.find
          ? _SearchField.replace
          : _SearchField.find;
      return (this, null);
    }
    if (key.type == tui.KeyType.enter) {
      if (key.alt) {
        final replaced = editor.replaceAllSearchMatches(replaceQuery);
        if (replaced) {
          revision++;
          _refreshAnalysis();
        }
        status = replaced
            ? 'REPLACE ALL  •  $replaceQuery'
            : 'REPLACE ALL  •  no matches';
        _applySearch();
        return (
          this,
          _batch([_syntaxCommand(), if (replaced) _checkpointCommand()]),
        );
      }
      if (key.ctrl) {
        final replaced = editor.replaceActiveSearchMatch(replaceQuery);
        if (replaced) {
          revision++;
          _refreshAnalysis();
        }
        status = replaced
            ? 'REPLACE  •  $replaceQuery'
            : 'REPLACE  •  no active match';
        _applySearch();
        return (
          this,
          _batch([_syntaxCommand(), if (replaced) _checkpointCommand()]),
        );
      }
      editor.executeCommand(
        key.shift
            ? core.EditorCommandIds.previousSearchMatch
            : core.EditorCommandIds.nextSearchMatch,
      );
      status = _searchStatus();
      return (this, null);
    }
    if (key.type == tui.KeyType.backspace) {
      if (_searchField == _SearchField.find) {
        if (searchQuery.isNotEmpty) {
          searchQuery = searchQuery.substring(0, searchQuery.length - 1);
          _applySearch();
        }
      } else if (replaceQuery.isNotEmpty) {
        replaceQuery = replaceQuery.substring(0, replaceQuery.length - 1);
      }
      status = _searchStatus();
      return (this, null);
    }
    if (key.type == tui.KeyType.runes && !key.ctrl && !key.alt) {
      final text = String.fromCharCodes(key.runes);
      if (_searchField == _SearchField.find) {
        searchQuery += text;
        _applySearch();
      } else {
        replaceQuery += text;
      }
      status = _searchStatus();
    }
    return (this, null);
  }

  (tui.Model, tui.Cmd?) _updateCodeActions(tui.Key key) {
    if (key.type == tui.KeyType.escape) {
      _overlay = _Overlay.none;
      editor.cancelCodeActions();
      status = 'NORMAL  •  code actions dismissed';
      return (this, null);
    }
    if (key.type == tui.KeyType.up) {
      codeActionPalette.moveSelection(-1);
      return (this, null);
    }
    if (key.type == tui.KeyType.down) {
      codeActionPalette.moveSelection(1);
      return (this, null);
    }
    if (key.type == tui.KeyType.enter) {
      final item = codeActionPalette.selectedItem;
      _overlay = _Overlay.none;
      final action = item?.payload;
      if (action is core.EditorCodeAction) {
        _applyCodeAction(action);
        status = 'CODE ACTION  •  ${action.title}';
        return (this, _batch([_syntaxCommand(), _checkpointCommand()]));
      }
      status = 'CODE ACTION  •  no change';
    } else if (key.type == tui.KeyType.backspace) {
      final query = codeActionPalette.query;
      if (query.isNotEmpty) {
        codeActionPalette.updateQuery(query.substring(0, query.length - 1));
      }
    } else if (key.type == tui.KeyType.runes && !key.ctrl && !key.alt) {
      codeActionPalette.updateQuery(
        codeActionPalette.query + String.fromCharCodes(key.runes),
      );
    }
    return (this, null);
  }

  (tui.Model, tui.Cmd?) _updateRecovery(tui.Key key) {
    if (key.type == tui.KeyType.escape || _isRune(key, 0x6e)) {
      _overlay = _Overlay.none;
      pendingRecovery = null;
      return (
        this,
        tui.Cmd.perform(
          () => persistence.store.deleteRecovery(documentId),
          onSuccess: (_) =>
              const _PersistenceDoneMsg(kind: 'discard', ok: true),
        ),
      );
    }
    if (_isRune(key, 0x79) || key.type == tui.KeyType.enter) {
      final snapshot = pendingRecovery;
      _overlay = _Overlay.none;
      pendingRecovery = null;
      if (snapshot != null) {
        editor.setText(snapshot.document.text, recordHistory: false);
        revision = snapshot.revision;
        _refreshAnalysis();
        _refreshFolds();
        status = 'RECOVERED  •  revision $revision';
      }
      return (this, _syntaxCommand());
    }
    return (this, null);
  }

  void _applySearch() {
    editor.startSearch(
      core.TextSearchQuery(pattern: searchQuery, caseSensitive: false),
    );
  }

  String _searchStatus() {
    final truncated = editor.searchTruncated ? ' (truncated)' : '';
    final error = editor.searchError;
    if (error != null) return 'FIND  •  $error';
    final current = editor.searchMatchIndex < 0
        ? '-'
        : '${editor.searchMatchIndex + 1}';
    return 'FIND  •  $current/${editor.searchMatches.length}$truncated';
  }

  void _openCodeActionPalette() {
    _overlay = _Overlay.codeActions;
    codeActionPalette
      ..updateItems([
        for (final action in editor.codeActions)
          tui.CommandPaletteItem(
            id: action.commandId ?? action.title,
            payload: action,
            label: action.title,
            description: action.kind,
            group: 'Code Action',
            tags: [action.kind, if (action.preferred) 'preferred'],
          ),
      ])
      ..updateQuery('');
    status = 'CODE ACTION  •  ${editor.codeActions.length} action(s)';
  }

  void _applyCodeAction(core.EditorCodeAction action) {
    editor.acceptCodeAction();
    final edits =
        action.edit.files[documentId] ??
        (action.edit.files.isEmpty
            ? const <core.FileTextEdit>[]
            : action.edit.files.values.first);
    if (edits.isNotEmpty) {
      final applied = core.applyFileEdits(documentId, editor.value, edits);
      if (applied.applied && applied.newText != editor.value) {
        editor.setText(applied.newText);
        revision++;
        _refreshAnalysis();
        _refreshFolds();
      }
    }
    editor.cancelCodeActions();
  }

  void _refreshAnalysis() {
    final todos = core.findTextSearchMatches(
      editor.document,
      const core.TextSearchQuery(pattern: 'TODO'),
      maxResults: editor.workAssessment.maxSearchResults,
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
    if (editor.workAssessment.allowSynchronousSyntax) {
      editor.syncSyntax(syntaxSession, language: 'dart');
    }
  }

  tui.Cmd? _syntaxCommand() {
    if (editor.workAssessment.allowSynchronousSyntax) {
      editor.syncSyntax(syntaxSession, language: 'dart');
      return null;
    }
    return tui.Cmd.perform(
      () => editor.syncSyntaxAsync(asyncSyntax, language: 'dart'),
      onSuccess: _SyntaxReadyMsg.new,
    );
  }

  tui.Cmd _saveCommand() {
    final current = revision;
    return tui.Cmd.perform(
      () => persistence.save(editor.document, revision: current),
      onSuccess: (ok) =>
          _PersistenceDoneMsg(kind: 'save', ok: ok, revision: current),
      onError: (error, _) =>
          _PersistenceDoneMsg(kind: 'save', ok: false, error: error),
    );
  }

  tui.Cmd _checkpointCommand() {
    final current = revision;
    return tui.Cmd.perform(
      () => persistence.checkpoint(editor.document, revision: current),
      onSuccess: (ok) =>
          _PersistenceDoneMsg(kind: 'checkpoint', ok: ok, revision: current),
      onError: (error, _) =>
          _PersistenceDoneMsg(kind: 'checkpoint', ok: false, error: error),
    );
  }

  void _refreshFolds() {
    editor.refreshIndentFolds();
    editor.setLineDecorationLayer('folds', [
      for (final range in editor.folds.ranges)
        core.TextLineDecoration(
          lineIndex: range.startLine,
          styleKey: 'line.active',
          lineNumberMarker: editor.folds.isCollapsedAt(range.startLine)
              ? '▸'
              : '▾',
        ),
    ]);
  }

  void _toggleFoldAtCursor() {
    final result = editor.executeCommand(core.EditorCommandIds.toggleFold);
    if (result != core.EditorCommandDispatchResult.handled) {
      status = 'FOLD  •  no fold at cursor';
      return;
    }
    _refreshFolds();
    final line = editor.editorState.cursor.line;
    status = editor.folds.isCollapsedAt(line)
        ? 'FOLD  •  collapsed line ${line + 1}'
        : 'FOLD  •  expanded line ${line + 1}';
  }

  void _jumpToBracket() {
    final match = core.findMatchingBracket(
      editor.document,
      editor.cursorOffset,
    );
    if (match == null) {
      status = 'BRACKET  •  no match';
      return;
    }
    editor.addCursorAtOffset(match);
    editor.setSelections(core.TextSelectionSet.collapsed(match));
    status = 'BRACKET  •  jumped to offset $match';
  }

  void _insertSnippet(String source) {
    final parsed = core.parseSnippet(source);
    snippetOrigin = editor.cursorOffset;
    editor.insertString(parsed.text);
    snippet = core.SnippetSession(parsed)..next();
    revision++;
    _selectSnippetStop();
    _refreshAnalysis();
    _refreshFolds();
  }

  void _advanceSnippet({required bool back}) {
    final session = snippet;
    if (session == null) return;
    final stop = back ? session.previous() : session.next();
    if (stop == null) {
      snippet = null;
      status = 'SNIPPET  •  done';
      return;
    }
    _selectSnippetStop();
  }

  void _selectSnippetStop() {
    final stop = snippet?.current;
    if (stop == null) return;
    editor.setSelections(
      core.TextSelectionSet([
        core.TextSelectionRange(
          startOffset: snippetOrigin + stop.startOffset,
          endOffset: snippetOrigin + stop.endOffset,
        ),
      ], primaryOffset: snippetOrigin + stop.endOffset),
    );
    status = 'SNIPPET  •  tabstop ${stop.index}';
  }

  void _registerDemoCommands() {
    editor.commandRegistry.registerAll([
      core.EditorCommand(
        id: _demoSnippetCommandId,
        label: 'Insert for-loop snippet',
        category: 'Snippets',
        description: 'Expands a tabstop snippet at the cursor',
        execute: (_) {
          _insertSnippet(_forLoopSnippet);
          return true;
        },
      ),
      core.EditorCommand(
        id: core.EditorCommandIds.goToMatchingBracket,
        label: 'Go to Matching Bracket',
        category: 'Cursor',
        execute: (_) {
          _jumpToBracket();
          return true;
        },
      ),
    ]);
  }

  @override
  String view() {
    final title = _bar(
      ' ARTISANAL EDITOR  $documentId',
      'Dart  UTF-8  ${editor.lineCount} lines ',
    );
    final dirty = isDirty ? 'modified' : 'saved';
    final diagnostics = editor.diagnostics.length;
    final cursor = editor.editorState.cursor;
    final position = 'Ln ${cursor.line + 1}, Col ${cursor.column + 1}';
    final foldsCollapsed = editor.folds.collapsedStarts.length;
    final footer = _bar(
      ' $status',
      '$position  $dirty  $diagnostics warning(s)  '
          '$foldsCollapsed fold(s)  ctrl+p commands  ctrl+c quit ',
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
    return switch (_overlay) {
      _Overlay.palette => b.CommandPaletteComponent(
        palette: palette,
        width: (width - 12).clamp(30, 72),
      ).render(base, screenWidth: width, screenHeight: height),
      _Overlay.codeActions => b.CommandPaletteOverlay(
        controller: codeActionPalette,
        isOpen: true,
        title: 'Code Actions',
        width: (width - 12).clamp(30, 72),
      ).render(base, screenWidth: width, screenHeight: height),
      _Overlay.search => _renderSearch(base),
      _Overlay.recovery => b.renderModal(
        base,
        [
          'Unsaved recovery checkpoint found.',
          'Restore it into the buffer?',
          '',
          'y restore   n discard   esc dismiss',
        ],
        chrome: const b.ModalChrome(
          title: 'Recover unsaved work',
          footer: ['y restore  n discard'],
          width: 48,
        ),
        screenW: width,
        screenH: height,
      ),
      _Overlay.none => base,
    };
  }

  String _renderSearch(String base) {
    final findPrefix = _searchField == _SearchField.find ? '>' : ' ';
    final replacePrefix = _searchField == _SearchField.replace ? '>' : ' ';
    final count =
        editor.searchError ??
        '${editor.searchMatchIndex < 0 ? '-' : editor.searchMatchIndex + 1}'
            '/${editor.searchMatches.length}'
            '${editor.searchTruncated ? ' truncated' : ''}';
    return b.renderModal(
      base,
      [
        '$findPrefix find: $searchQuery',
        '$replacePrefix replace: $replaceQuery',
        '',
        count,
      ],
      chrome: const b.ModalChrome(
        title: 'Find and Replace',
        footer: [
          'enter next  shift+enter prev  tab field  ctrl+enter replace  alt+enter all',
        ],
        width: 64,
      ),
      screenW: width,
      screenH: height,
    );
  }

  String _bar(String left, String right) {
    final space = (width - left.length - right.length).clamp(1, width);
    return Style()
        .background(const AnsiColor(236))
        .foreground(const AnsiColor(252))
        .render('$left${' ' * space}$right');
  }

  static bool _ctrl(tui.Key key, int rune) {
    if (key.type == tui.KeyType.space && key.ctrl && rune == 0x20) {
      return true;
    }
    return key.type == tui.KeyType.runes &&
        key.runes.length == 1 &&
        ((key.ctrl && key.runes.first == rune) ||
            key.runes.first == rune - 0x60);
  }

  static bool _isRune(tui.Key key, int rune) =>
      key.type == tui.KeyType.runes &&
      key.runes.length == 1 &&
      key.runes.first == rune;
}

core.EditorDocumentStore _defaultStore() {
  try {
    final directory = io.Directory(
      '${io.Directory.systemTemp.path}'
      '${io.Platform.pathSeparator}artisanal-editor-demo',
    )..createSync(recursive: true);
    return ExampleFileDocumentStore(directory);
  } on Object {
    return core.MemoryEditorDocumentStore();
  }
}

/// File-backed [core.EditorDocumentStore] used by the full-screen example.
final class ExampleFileDocumentStore implements core.EditorDocumentStore {
  ExampleFileDocumentStore(this.directory);

  final io.Directory directory;

  io.File _file(String documentId, {required bool recovery}) {
    final name = Uri.encodeComponent(documentId);
    final suffix = recovery ? '.recover' : '.txt';
    return io.File('${directory.path}/$name$suffix');
  }

  Future<core.EditorDocumentSnapshot?> _readFile(io.File file) async {
    if (!file.existsSync()) return null;
    final raw = await file.readAsString();
    final split = raw.indexOf('\n');
    if (split < 0) return null;
    final header = raw.substring(0, split).split('|');
    final revision = int.tryParse(header.first) ?? 0;
    final savedAt =
        DateTime.tryParse(header.length > 1 ? header[1] : '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return core.EditorDocumentSnapshot(
      documentId: header.length > 2 ? header[2] : file.uri.toString(),
      document: core.TextDocument(text: raw.substring(split + 1)),
      revision: revision,
      savedAt: savedAt,
    );
  }

  Future<void> _writeFile(io.File file, core.EditorDocumentSnapshot snapshot) {
    return file.writeAsString(
      '${snapshot.revision}|${snapshot.savedAt.toIso8601String()}|${snapshot.documentId}\n'
      '${snapshot.document.text}',
    );
  }

  @override
  Future<core.EditorDocumentSnapshot?> read(String documentId) =>
      _readFile(_file(documentId, recovery: false));

  @override
  Future<void> write(core.EditorDocumentSnapshot snapshot) =>
      _writeFile(_file(snapshot.documentId, recovery: false), snapshot);

  @override
  Future<core.EditorDocumentSnapshot?> readRecovery(String documentId) =>
      _readFile(_file(documentId, recovery: true));

  @override
  Future<void> writeRecovery(core.EditorDocumentSnapshot snapshot) =>
      _writeFile(_file(snapshot.documentId, recovery: true), snapshot);

  @override
  Future<void> deleteRecovery(String documentId) async {
    final file = _file(documentId, recovery: true);
    if (file.existsSync()) await file.delete();
  }
}

/// Regex syntax provider that patches only the changed line window.
final class DemoDartSyntaxProvider extends core.TextSyntaxProvider<int> {
  static final _patterns = <(RegExp, String)>[
    (RegExp(r'//[^\n]*'), 'syntax.comment'),
    (RegExp("'[^'\\n]*'"), 'syntax.string'),
    (RegExp(r'\b(import|void|final|class|return|if|for)\b'), 'syntax.keyword'),
  ];

  @override
  core.TextSyntaxBuildResult<int> build(
    String text, {
    core.TextDocument? document,
    String? language,
    core.TextSyntaxSnapshot<int>? previous,
    core.TextDocumentChange? change,
  }) {
    final resolved = document ?? core.TextDocument(text: text);
    final state = (previous?.state ?? 0) + 1;
    if (previous != null &&
        change != null &&
        !change.isNoop &&
        previous.document != null) {
      final window = core.textSyntaxChangeWindow(
        previousDocument: previous.document!,
        nextDocument: resolved,
        change: change,
        lookBehindLines: 1,
        lookAheadLines: 1,
      );
      return core.TextSyntaxBuildResult.patch(
        patch: core.TextSyntaxDecorationPatch.forChangeWindow(
          previousDocument: previous.document!,
          nextDocument: resolved,
          window: window,
          decorations: _scan(
            resolved,
            startOffset: window.nextLines.startOffsetIn(resolved),
            endOffset: window.nextLines.endOffsetIn(resolved),
          ),
        ),
        state: state,
      );
    }
    return core.TextSyntaxBuildResult(
      decorations: _scan(resolved, startOffset: 0, endOffset: resolved.length),
      state: state,
    );
  }

  List<core.TextDecorationRange> _scan(
    core.TextDocument document, {
    required int startOffset,
    required int endOffset,
  }) {
    final slice = document.textInRange(
      startOffset: startOffset,
      endOffset: endOffset,
    );
    final decorations = <core.TextDecorationRange>[];
    for (final (pattern, styleKey) in _patterns) {
      for (final match in pattern.allMatches(slice)) {
        decorations.add(
          core.TextDecorationRange(
            startOffset: startOffset + match.start,
            endOffset: startOffset + match.end,
            styleKey: styleKey,
          ),
        );
      }
    }
    decorations.sort((a, b) => a.startOffset.compareTo(b.startOffset));
    return decorations;
  }
}

/// Async wrapper that demonstrates stale-result rejection.
final class DemoAsyncDartSyntaxProvider
    extends core.AsyncTextSyntaxProvider<int> {
  DemoAsyncDartSyntaxProvider({this.delay = Duration.zero});

  final Duration delay;
  final DemoDartSyntaxProvider _inner = DemoDartSyntaxProvider();

  @override
  Future<core.TextSyntaxBuildResult<int>> buildDocument(
    core.TextDocument document, {
    String? language,
    core.TextSyntaxSnapshot<int>? previous,
    core.TextDocumentChange? change,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return _inner.buildDocument(
      document,
      language: language,
      previous: previous,
      change: change,
    );
  }
}

final class DemoCompletionProvider implements core.EditorCompletionProvider {
  const DemoCompletionProvider();

  static const _items = <core.EditorCompletionItem>[
    core.EditorCompletionItem(
      label: 'print',
      insertText: 'print',
      kind: core.EditorCompletionKind.function,
      detail: 'void print(Object? object)',
    ),
    core.EditorCompletionItem(
      label: 'final',
      insertText: 'final',
      kind: core.EditorCompletionKind.keyword,
    ),
    core.EditorCompletionItem(
      label: 'for',
      insertText: r'for (var ${1:i} = 0; $1 < ${2:n}; $1++) {\n  $0\n}',
      kind: core.EditorCompletionKind.snippet,
      detail: 'for loop',
    ),
  ];

  @override
  core.EditorCompletionResult provide(core.EditorCompletionRequest request) {
    final prefix = _prefixAt(request.documentText, request.cursorOffset);
    return core.EditorCompletionResult(
      items: core.filterEditorCompletions(_items, prefix),
    );
  }

  String _prefixAt(String text, int offset) {
    final clamped = offset.clamp(0, text.length);
    var start = clamped;
    while (start > 0) {
      final unit = text.codeUnitAt(start - 1);
      final isWord =
          (unit >= 0x41 && unit <= 0x5a) ||
          (unit >= 0x61 && unit <= 0x7a) ||
          (unit >= 0x30 && unit <= 0x39) ||
          unit == 0x5f;
      if (!isWord) break;
      start--;
    }
    return text.substring(start, clamped);
  }
}

final class DemoCodeActionProvider implements core.EditorCodeActionProvider {
  const DemoCodeActionProvider(this.documentId);
  final String documentId;

  @override
  List<core.EditorCodeAction> provide(core.EditorCodeActionRequest request) {
    final actions = <core.EditorCodeAction>[];
    for (final diagnostic in request.diagnostics) {
      if (request.documentText.substring(
            diagnostic.startOffset,
            diagnostic.endOffset,
          ) ==
          'TODO') {
        actions.add(
          core.EditorCodeAction(
            title: 'Replace TODO with FIXME',
            kind: 'quickfix',
            preferred: true,
            edit: core.WorkspaceEdit(
              files: {
                documentId: [
                  core.FileTextEdit(
                    startOffset: diagnostic.startOffset,
                    endOffset: diagnostic.endOffset,
                    replacement: 'FIXME',
                  ),
                ],
              },
            ),
          ),
        );
      }
    }
    actions.add(
      const core.EditorCodeAction(
        title: 'Insert trailing newline',
        kind: 'source',
      ),
    );
    return actions;
  }
}

const _demoSnippetCommandId = 'demo.insertForLoopSnippet';
const _forLoopSnippet =
    'for (var \${1:i} = 0; \$1 < \${2:n}; \$1++) {\n  \$0\n}';

const _initialSource = r'''import 'package:artisanal/editor_core.dart';

void main() {
  final message = 'Edit this complete full-screen example.';
  // TODO: try search, diagnostics, commands, and multiple cursors.
  if (true) {
    print(message);
  }
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
