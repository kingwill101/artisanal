import 'package:artisanal/editor_core.dart'
    show EditorCommandIds, TextDiagnosticRange, TextDiagnosticSeverity;
import 'package:artisanal/bubbles.dart'
    show
        TextAreaCompletionErrorMsg,
        TextAreaCompletionMsg,
        TreeItem,
        TreeModel,
        TreeRow;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/style.dart' show Border;
import 'package:artisanal/terminal.dart' show Key, KeyType;
import 'package:artisanal_widgets/app.dart' as app;
import 'package:artisanal_widgets/editors.dart' as editors;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:path/path.dart' as p;

import '../lsp/editor_language_service.dart';
import '../modal/modal_editing.dart' show ModalEditingMode;
import '../workspace/editor_file_repository.dart';
import '../workspace/editor_workspace.dart';

Future<void> runEditorApp(EditorWorkspace workspace) {
  return app.runWidgetApp(
    app.ArtisanalApp(
      title: 'Artisanal Editor',
      home: EditorScreen(workspace: workspace),
      theme: w.OpenCodeThemes.ayu(),
    ),
    options: app.defaultWidgetProgramOptions
        .withFilter(_editorInputFilter)
        .withoutSuspendSignal(),
  );
}

runtime.Msg? _editorInputFilter(runtime.Model _, runtime.Msg message) {
  return remapEditorInput(message);
}

/// Reclaims the runtime suspend message as the editor's `Ctrl+Z` undo key.
runtime.Msg remapEditorInput(runtime.Msg message) {
  if (message is runtime.SuspendMsg) {
    return const runtime.KeyMsg(Key(KeyType.runes, runes: [0x7a], ctrl: true));
  }
  return message;
}

final class _BufferOpened extends runtime.Msg {
  _BufferOpened(this.buffer);

  final EditorBuffer buffer;
}

final class _Saved extends runtime.Msg {
  _Saved(this.path);

  final String path;
}

final class _SavedAndClosed extends runtime.Msg {
  _SavedAndClosed(this.buffer);

  final EditorBuffer buffer;
}

enum _DirtyCloseAction { save, discard }

final class _DirtyCloseResolved extends runtime.Msg {
  _DirtyCloseResolved(this.buffer, this.action);

  final EditorBuffer buffer;
  final _DirtyCloseAction? action;
}

final class _EditorFailure extends runtime.Msg {
  _EditorFailure(this.error);

  final Object error;
}

final class _WorkspaceChanged extends runtime.Msg {
  _WorkspaceChanged(this.event);

  final EditorWorkspaceEvent event;
}

final class _HoverLoaded extends runtime.Msg {
  _HoverLoaded({
    required this.path,
    required this.cursorOffset,
    required this.hover,
  });

  final String path;
  final int cursorOffset;
  final EditorLanguageHover? hover;
}

enum _PaletteAction {
  save,
  saveAndClose,
  close,
  nextBuffer,
  previousBuffer,
  undo,
  redo,
  nextProblem,
  previousProblem,
  hover,
  problemsPanel,
  outputPanel,
  toggleExplorer,
  togglePanel,
  toggleMarkdownPreview,
}

final class _OpenFileAction {
  const _OpenFileAction(this.file);

  final EditorFileEntry file;
}

final class _ProblemAction {
  const _ProblemAction(this.buffer, this.diagnostic);

  final EditorBuffer buffer;
  final TextDiagnosticRange diagnostic;
}

final class _InlineDiagnostic {
  const _InlineDiagnostic({
    required this.path,
    required this.diagnostic,
    required this.screenRow,
  });

  final String path;
  final TextDiagnosticRange diagnostic;
  final int screenRow;
}

class EditorScreen extends w.StatefulWidget {
  EditorScreen({required this.workspace, super.key});

  final EditorWorkspace workspace;

  @override
  w.State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends w.State<EditorScreen> {
  final w.FocusController _focus = w.FocusController();
  final Map<String, _EditorScrollController> _editorScrollControllers = {};
  final Set<String> _hiddenMarkdownPreviews = {};
  late final TreeModel<EditorFileEntry?> _fileTree;
  int _panelIndex = 0;
  String _activity = 'Ready';
  EditorLanguageHover? _hover;
  _InlineDiagnostic? _inlineDiagnostic;
  EditorBuffer? _closingDirtyBuffer;
  bool _paletteOpen = false;
  bool _explorerVisible = true;
  bool _panelVisible = false;

  EditorWorkspace get _workspace => widget.workspace;
  EditorBuffer? get _buffer => _workspace.activeBuffer;

  @override
  void initState() {
    super.initState();
    _fileTree = TreeModel(items: _buildFileTree(_workspace.files));
  }

  @override
  runtime.Cmd? handleInit() {
    return runtime.Cmd.listen<EditorWorkspaceEvent>(
      _workspace.events,
      onData: _WorkspaceChanged.new,
    );
  }

  @override
  void dispose() {
    for (final controller in _editorScrollControllers.values) {
      controller.dispose();
    }
    _editorScrollControllers.clear();
    _workspace.dispose();
    super.dispose();
  }

  @override
  runtime.Cmd? handleIntercept(runtime.Msg message) {
    if (message is runtime.InterruptMsg) return runtime.Cmd.quit();
    if (_closingDirtyBuffer != null) return null;
    if (message is! runtime.KeyMsg) return null;
    if (_paletteOpen) return null;

    final key = message.key;
    if (_inlineDiagnostic != null) {
      setState(() => _inlineDiagnostic = null);
      if (key.type == KeyType.escape) return runtime.Cmd.none();
    }
    if (_isControlCharacter(key, 'q')) return runtime.Cmd.quit();
    if (_isControlCharacter(key, 'p')) {
      setState(() {
        _hover = null;
        _paletteOpen = true;
        _activity = 'COMMAND PALETTE';
      });
      return runtime.Cmd.none();
    }
    if (_isControlCharacter(key, 's')) return _save();
    if (_isControlCharacter(key, 'b')) return _toggleExplorer();
    if (_isControlCharacter(key, 'j')) return _togglePanel();
    if (_isControlShiftCharacter(key, 'v')) {
      return _toggleMarkdownPreview();
    }
    if (_hover != null && key.type == KeyType.escape) {
      setState(() => _hover = null);
      return runtime.Cmd.none();
    }
    if (_isControlCharacter(key, 'w')) return _closeActive();
    if (key.type == KeyType.tab && key.ctrl) {
      return _activateBuffer(backwards: key.shift);
    }
    if (key.type == KeyType.f8) {
      return _selectProblem(backwards: key.shift);
    }

    final buffer = _buffer;
    if (buffer == null || !_focus.isFocused('editor', searchPath: true)) {
      return null;
    }
    if (buffer.controller.model.completionVisible &&
        _isCompletionNavigationKey(key)) {
      switch (key.type) {
        case KeyType.up:
          buffer.controller.moveCompletion(-1);
        case KeyType.down:
          buffer.controller.moveCompletion(1);
        case KeyType.tab || KeyType.enter:
          buffer.controller.acceptCompletion();
        case KeyType.escape:
          buffer.controller.cancelCompletions();
        default:
          break;
      }
      setState(() {});
      return runtime.Cmd.none();
    }
    if (_isCompletionShortcut(key)) {
      final provider = buffer.completionProvider;
      if (provider == null) {
        setState(() => _activity = 'No completion provider for this buffer');
        return runtime.Cmd.none();
      }
      setState(() {
        _hover = null;
        _activity = 'COMPLETION  •  ↑/↓ select, enter accept, esc dismiss';
      });
      return buffer.controller.requestCompletions(provider);
    }
    final chord = _normalizeKey(key);
    if (chord == null) return null;
    if (chord == 'K' && buffer.modal.mode == ModalEditingMode.normal) {
      return _requestHover(buffer);
    }
    final result = buffer.modal.handle(chord);
    if (!result.handled) return null;
    for (final command in result.commands) {
      buffer.controller.dispatch(command.commandId);
    }
    setState(() {
      _hover = null;
      _activity = buffer.modal.pendingKeys.isEmpty
          ? buffer.modal.modeLabel
          : buffer.modal.pendingKeys;
    });
    return runtime.Cmd.none();
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg message) {
    switch (message) {
      case _BufferOpened(:final buffer):
        setState(() {
          _hover = null;
          _workspace.activate(buffer);
          _activity = 'Opened ${buffer.file.relativePath}';
        });
        _focus.requestFocus('editor');
      case _Saved(:final path):
        setState(() => _activity = 'Saved $path');
      case _SavedAndClosed(:final buffer):
        setState(() {
          _workspace.close(buffer);
          _disposeBufferUi(buffer);
          _activity = 'Saved and closed ${buffer.file.name}';
        });
        _focus.requestFocus('editor');
      case _DirtyCloseResolved(:final buffer, :final action):
        if (!identical(_closingDirtyBuffer, buffer)) {
          return runtime.Cmd.none();
        }
        setState(() => _closingDirtyBuffer = null);
        switch (action) {
          case _DirtyCloseAction.save:
            return _saveAndClose(buffer);
          case _DirtyCloseAction.discard:
            setState(() {
              _workspace.close(buffer);
              _disposeBufferUi(buffer);
              _activity = 'Discarded changes and closed ${buffer.file.name}';
            });
            _focus.requestFocus('editor');
          case null:
            setState(() => _activity = 'Kept ${buffer.file.name} open');
            _focus.requestFocus('editor');
        }
      case _EditorFailure(:final error):
        setState(() {
          _closingDirtyBuffer = null;
          _activity = 'Error: $error';
        });
      case _WorkspaceChanged(:final event):
        setState(() {
          if (event.message case final message?) {
            _activity = message;
          }
        });
      case TextAreaCompletionMsg():
        setState(() {
          if (_buffer?.controller.model.completionVisible != true) {
            _activity = 'No completions found';
          }
        });
      case TextAreaCompletionErrorMsg(:final error):
        setState(() => _activity = 'Completion failed: $error');
      case _HoverLoaded(:final path, :final cursorOffset, :final hover):
        final buffer = _buffer;
        if (buffer == null ||
            buffer.file.path != path ||
            buffer.controller.model.cursorOffset != cursorOffset) {
          return runtime.Cmd.none();
        }
        setState(() {
          _hover = hover;
          _activity = hover == null
              ? 'No hover information'
              : 'HOVER  •  Esc dismisses';
        });
      default:
        return null;
    }
    return runtime.Cmd.none();
  }

  runtime.Cmd _open(EditorFileEntry file) {
    return runtime.Cmd.perform(
      () => _workspace.open(file),
      onSuccess: _BufferOpened.new,
      onError: (error, _) => _EditorFailure(error),
    );
  }

  runtime.Cmd _save() {
    final path = _buffer?.file.relativePath ?? 'buffer';
    setState(() => _activity = 'Saving $path…');
    return runtime.Cmd.perform(
      _workspace.saveActive,
      onSuccess: (_) => _Saved(path),
      onError: (error, _) => _EditorFailure(error),
    );
  }

  runtime.Cmd _requestHover(EditorBuffer buffer) {
    final cursorOffset = buffer.controller.model.cursorOffset;
    if (buffer.controller.model.completionVisible) {
      buffer.controller.cancelCompletions();
    }
    setState(() {
      _hover = null;
      _activity = 'Requesting hover…';
    });
    return runtime.Cmd.perform(
      () => _workspace.requestHover(buffer),
      onSuccess: (hover) => _HoverLoaded(
        path: buffer.file.path,
        cursorOffset: cursorOffset,
        hover: hover,
      ),
      onError: (error, _) => _EditorFailure(error),
    );
  }

  List<w.CommandPaletteItem> _paletteItems() {
    return [
      const w.CommandPaletteItem(
        id: 'file.save',
        label: 'Save File',
        description: 'Write the active buffer to disk',
        shortcut: 'Ctrl+S',
        group: 'File',
        tags: ['write', 'persist'],
        payload: _PaletteAction.save,
      ),
      const w.CommandPaletteItem(
        id: 'file.close',
        label: 'Close File',
        description: 'Close the active clean buffer',
        shortcut: 'Ctrl+W',
        group: 'File',
        tags: ['buffer', 'tab'],
        payload: _PaletteAction.close,
      ),
      const w.CommandPaletteItem(
        id: 'file.saveAndClose',
        label: 'Save and Close File',
        description: 'Save the active buffer, then close it',
        group: 'File',
        tags: ['write', 'buffer', 'tab'],
        payload: _PaletteAction.saveAndClose,
      ),
      const w.CommandPaletteItem(
        id: 'buffer.next',
        label: 'Next Buffer',
        shortcut: 'Ctrl+Tab',
        group: 'Navigation',
        tags: ['tab', 'file'],
        payload: _PaletteAction.nextBuffer,
      ),
      const w.CommandPaletteItem(
        id: 'buffer.previous',
        label: 'Previous Buffer',
        shortcut: 'Ctrl+Shift+Tab',
        group: 'Navigation',
        tags: ['tab', 'file'],
        payload: _PaletteAction.previousBuffer,
      ),
      const w.CommandPaletteItem(
        id: 'edit.undo',
        label: 'Undo',
        shortcut: 'u / Ctrl+Z',
        group: 'Edit',
        payload: _PaletteAction.undo,
      ),
      const w.CommandPaletteItem(
        id: 'edit.redo',
        label: 'Redo',
        shortcut: 'Ctrl+R',
        group: 'Edit',
        payload: _PaletteAction.redo,
      ),
      const w.CommandPaletteItem(
        id: 'problem.next',
        label: 'Next Problem',
        shortcut: 'F8',
        group: 'Diagnostics',
        tags: ['diagnostic', 'error', 'warning'],
        payload: _PaletteAction.nextProblem,
      ),
      const w.CommandPaletteItem(
        id: 'problem.previous',
        label: 'Previous Problem',
        shortcut: 'Shift+F8',
        group: 'Diagnostics',
        tags: ['diagnostic', 'error', 'warning'],
        payload: _PaletteAction.previousProblem,
      ),
      const w.CommandPaletteItem(
        id: 'language.hover',
        label: 'Show Hover Documentation',
        shortcut: 'K',
        group: 'Language',
        tags: ['lsp', 'type', 'documentation'],
        payload: _PaletteAction.hover,
      ),
      const w.CommandPaletteItem(
        id: 'view.problems',
        label: 'Show Problems Panel',
        shortcut: 'Ctrl+J',
        group: 'View',
        tags: ['diagnostics', 'errors', 'warnings'],
        payload: _PaletteAction.problemsPanel,
      ),
      const w.CommandPaletteItem(
        id: 'view.output',
        label: 'Show Output Panel',
        group: 'View',
        tags: ['logs', 'lsp'],
        payload: _PaletteAction.outputPanel,
      ),
      const w.CommandPaletteItem(
        id: 'view.toggleExplorer',
        label: 'Toggle Explorer',
        description: 'Show or hide the workspace file tree',
        shortcut: 'Ctrl+B',
        group: 'View',
        tags: ['files', 'sidebar', 'neo-tree'],
        payload: _PaletteAction.toggleExplorer,
      ),
      const w.CommandPaletteItem(
        id: 'view.togglePanel',
        label: 'Toggle Bottom Panel',
        description: 'Show or hide Problems and Output',
        shortcut: 'Ctrl+J',
        group: 'View',
        tags: ['problems', 'output', 'drawer'],
        payload: _PaletteAction.togglePanel,
      ),
      if (_buffer case final buffer? when _isMarkdown(buffer))
        w.CommandPaletteItem(
          id: 'view.toggleMarkdownPreview',
          label: _showsMarkdownPreview(buffer)
              ? 'Hide Markdown Preview'
              : 'Show Markdown Preview',
          description: 'Toggle the rendered preview beside the active editor',
          shortcut: 'Ctrl+Shift+V',
          group: 'View',
          tags: const ['markdown', 'preview', 'split'],
          payload: _PaletteAction.toggleMarkdownPreview,
        ),
      for (final problem in _paletteProblems())
        w.CommandPaletteItem(
          id:
              'problem:${problem.buffer.file.path}:'
              '${problem.diagnostic.startOffset}',
          label:
              problem.diagnostic.message ??
              problem.diagnostic.code ??
              'Diagnostic',
          description: _problemLocation(problem.buffer, problem.diagnostic),
          group: 'Problems',
          tags: [
            problem.buffer.file.name,
            problem.diagnostic.source ?? '',
            problem.diagnostic.severity.name,
          ],
          payload: problem,
        ),
      for (final file in _workspace.files.take(500))
        w.CommandPaletteItem(
          id: 'open:${file.path}',
          label: file.relativePath,
          description: 'Open file',
          group: 'Files',
          tags: ['open', file.name, file.language],
          payload: _OpenFileAction(file),
        ),
    ];
  }

  Iterable<_ProblemAction> _paletteProblems() sync* {
    var count = 0;
    for (final buffer in _workspace.openBuffers) {
      for (final diagnostic in buffer.controller.diagnostics) {
        yield _ProblemAction(buffer, diagnostic);
        count++;
        if (count >= 200) return;
      }
    }
  }

  runtime.Cmd _dismissPalette() {
    setState(() {
      _paletteOpen = false;
      _activity = 'Ready';
    });
    _focus.requestFocus('editor');
    return runtime.Cmd.none();
  }

  runtime.Cmd? _selectPaletteItem(w.CommandPaletteItem item) {
    final payload = item.payload;
    setState(() => _paletteOpen = false);
    _focus.requestFocus('editor');
    return switch (payload) {
      _OpenFileAction(:final file) => _open(file),
      _ProblemAction() => _openProblem(payload),
      _PaletteAction.save => _save(),
      _PaletteAction.saveAndClose => _saveAndCloseActive(),
      _PaletteAction.close => _closeActive(),
      _PaletteAction.nextBuffer => _activateBuffer(backwards: false),
      _PaletteAction.previousBuffer => _activateBuffer(backwards: true),
      _PaletteAction.undo => _dispatchEditorCommand(
        EditorCommandIds.undo,
        'Undo',
      ),
      _PaletteAction.redo => _dispatchEditorCommand(
        EditorCommandIds.redo,
        'Redo',
      ),
      _PaletteAction.nextProblem => _selectProblem(backwards: false),
      _PaletteAction.previousProblem => _selectProblem(backwards: true),
      _PaletteAction.hover => _requestActiveHover(),
      _PaletteAction.problemsPanel => _showPanel(0, 'Problems panel'),
      _PaletteAction.outputPanel => _showPanel(1, 'Output panel'),
      _PaletteAction.toggleExplorer => _toggleExplorer(),
      _PaletteAction.togglePanel => _togglePanel(),
      _PaletteAction.toggleMarkdownPreview => _toggleMarkdownPreview(),
      _ => runtime.Cmd.none(),
    };
  }

  runtime.Cmd _openProblem(_ProblemAction problem) {
    final position = problem.buffer.controller.document.positionForOffset(
      problem.diagnostic.startOffset,
    );
    setState(() {
      _workspace.activate(problem.buffer);
      problem.buffer.controller.setCursor(position.line, position.column);
      _inlineDiagnostic = null;
      _panelIndex = 0;
      _activity = _problemLocation(problem.buffer, problem.diagnostic);
    });
    _focus.requestFocus('editor');
    return runtime.Cmd.none();
  }

  String _problemLocation(EditorBuffer buffer, TextDiagnosticRange diagnostic) {
    final position = buffer.controller.document.positionForOffset(
      diagnostic.startOffset,
    );
    return '${buffer.file.relativePath}:'
        '${position.line + 1}:${position.column + 1}';
  }

  runtime.Cmd _requestActiveHover() {
    final buffer = _buffer;
    return buffer == null ? runtime.Cmd.none() : _requestHover(buffer);
  }

  runtime.Cmd _saveAndCloseActive() {
    final buffer = _buffer;
    if (buffer == null) {
      setState(() => _activity = 'No active buffer');
      return runtime.Cmd.none();
    }
    return _saveAndClose(buffer);
  }

  runtime.Cmd _saveAndClose(EditorBuffer buffer) {
    setState(() => _activity = 'Saving ${buffer.file.relativePath}…');
    return runtime.Cmd.perform(
      () async {
        await _workspace.save(buffer);
        return buffer;
      },
      onSuccess: _SavedAndClosed.new,
      onError: (error, _) => _EditorFailure(error),
    );
  }

  runtime.Cmd _closeActive() {
    final active = _buffer;
    return active == null ? _closeMissingBuffer() : _closeBuffer(active);
  }

  runtime.Cmd _closeMissingBuffer() {
    setState(() => _activity = 'No active buffer');
    return runtime.Cmd.none();
  }

  runtime.Cmd _closeBuffer(EditorBuffer buffer) {
    if (!buffer.isDirty) {
      setState(() {
        _workspace.close(buffer);
        _disposeBufferUi(buffer);
        _activity = 'Closed ${buffer.file.name}';
      });
      _focus.requestFocus('editor');
      return runtime.Cmd.none();
    }

    setState(() {
      _workspace.activate(buffer);
      _closingDirtyBuffer = buffer;
      _hover = null;
      _activity = '${buffer.file.name} has unsaved changes';
    });
    final decision = w.DialogSelect.show<_DirtyCloseAction>(
      context,
      title: 'UNSAVED CHANGES',
      searchHint: 'Choose what to do with ${buffer.file.name}',
      width: 54,
      height: 14,
      barrierDismissible: true,
      keybinds: const [
        (key: 'enter', description: 'choose'),
        (key: 'esc', description: 'keep open'),
      ],
      items: const [
        w.DialogSelectItem(
          label: 'Save and close',
          value: _DirtyCloseAction.save,
          description: 'Write the file before closing this buffer',
        ),
        w.DialogSelectItem(
          label: 'Discard changes',
          value: _DirtyCloseAction.discard,
          description: 'Close without writing the current edits',
        ),
      ],
    );
    return runtime.Cmd.perform(
      () => decision,
      onSuccess: (selection) => _DirtyCloseResolved(buffer, selection?.value),
      onError: (error, _) => _EditorFailure(error),
    );
  }

  runtime.Cmd _activateBuffer({required bool backwards}) {
    setState(() {
      _hover = null;
      _workspace.activateNext(backwards: backwards);
      _activity = backwards ? 'Previous buffer' : 'Next buffer';
    });
    _focus.requestFocus('editor');
    return runtime.Cmd.none();
  }

  runtime.Cmd _dispatchEditorCommand(String commandId, String label) {
    final result = _buffer?.controller.dispatch(commandId);
    setState(() => _activity = result == null ? 'No active buffer' : label);
    return runtime.Cmd.none();
  }

  runtime.Cmd _selectProblem({required bool backwards}) {
    final controller = _buffer?.controller;
    final selected = backwards
        ? controller?.selectPreviousDiagnostic() ?? false
        : controller?.selectNextDiagnostic() ?? false;
    setState(() {
      _activity = selected
          ? backwards
                ? 'Selected previous problem'
                : 'Selected next problem'
          : 'No problems in active buffer';
    });
    return runtime.Cmd.none();
  }

  runtime.Cmd _showPanel(int index, String activity) {
    setState(() {
      _panelIndex = index;
      _panelVisible = true;
      _activity = activity;
    });
    return runtime.Cmd.none();
  }

  runtime.Cmd _toggleExplorer() {
    setState(() {
      _explorerVisible = !_explorerVisible;
      _activity = _explorerVisible ? 'Explorer shown' : 'Explorer hidden';
    });
    _focus.requestFocus(_explorerVisible ? 'explorer' : 'editor');
    return runtime.Cmd.none();
  }

  runtime.Cmd _togglePanel() {
    setState(() {
      _panelVisible = !_panelVisible;
      _activity = _panelVisible ? 'Bottom panel shown' : 'Bottom panel hidden';
    });
    _focus.requestFocus('editor');
    return runtime.Cmd.none();
  }

  runtime.Cmd _toggleMarkdownPreview() {
    final buffer = _buffer;
    if (buffer == null || !_isMarkdown(buffer)) {
      setState(() => _activity = 'Markdown preview requires a Markdown buffer');
      return runtime.Cmd.none();
    }

    setState(() {
      if (_showsMarkdownPreview(buffer)) {
        _hiddenMarkdownPreviews.add(buffer.file.path);
        _activity = 'Markdown preview hidden';
      } else {
        _hiddenMarkdownPreviews.remove(buffer.file.path);
        _activity = 'Markdown preview shown';
      }
    });
    _focus.requestFocus('editor');
    return runtime.Cmd.none();
  }

  bool _isMarkdown(EditorBuffer buffer) => buffer.file.language == 'markdown';

  bool _showsMarkdownPreview(EditorBuffer buffer) =>
      _isMarkdown(buffer) &&
      !_hiddenMarkdownPreviews.contains(buffer.file.path);

  void _disposeBufferUi(EditorBuffer buffer) {
    _editorScrollControllers.remove(buffer.file.path)?.dispose();
    _hiddenMarkdownPreviews.remove(buffer.file.path);
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final workbench = w.Container(
      color: theme.background,
      child: w.LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth.toInt()
              : 100;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight.toInt()
              : 32;
          final showSidebar = _explorerVisible && width >= 56;
          final showPanel = _panelVisible && height >= 14;
          final editorHeight = (height - 2 - (showPanel ? 7 : 0)).clamp(4, 80);

          final editorArea = _buildEditorArea(
            context,
            editorHeight: editorHeight,
            showPanel: showPanel,
          );
          return w.Column(
            gap: 0,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Expanded(
                child: showSidebar
                    ? w.ResizableSplitView(
                        key: const w.ValueKey('workbench-split'),
                        initialFirstExtent: width >= 110 ? 28 : 22,
                        minFirstExtent: 16,
                        minSecondExtent: 36,
                        separator: w.Container(
                          color: theme.border,
                          child: w.Text('│', style: theme.labelSmall),
                        ),
                        first: _buildExplorer(context, height: height - 1),
                        second: editorArea,
                      )
                    : editorArea,
              ),
              _buildStatusLine(context),
            ],
          );
        },
      ),
    );
    final inlineDiagnostic = _inlineDiagnostic;
    final content = w.Stack(
      fit: w.StackFit.expand,
      children: [
        workbench,
        if (inlineDiagnostic != null &&
            inlineDiagnostic.path == _buffer?.file.path)
          w.Positioned(
            right: 1,
            top: inlineDiagnostic.screenRow,
            child: _buildInlineDiagnostic(context, inlineDiagnostic.diagnostic),
          ),
      ],
    );
    return w.CommandPalette(
      open: _paletteOpen,
      title: 'COMMAND PALETTE',
      hint: 'Type a command or file name',
      width: 64,
      maxHeight: 18,
      items: _paletteItems(),
      onDismiss: _dismissPalette,
      onSelect: _selectPaletteItem,
      child: content,
    );
  }

  w.Widget _buildInlineDiagnostic(
    w.BuildContext context,
    TextDiagnosticRange diagnostic,
  ) {
    final theme = w.ThemeScope.of(context);
    final color = switch (diagnostic.severity) {
      TextDiagnosticSeverity.error => theme.error,
      TextDiagnosticSeverity.warning => theme.warning,
      TextDiagnosticSeverity.info => theme.resolvedInfo,
      TextDiagnosticSeverity.hint => theme.resolvedOnSurfaceVariant,
    };
    final marker = switch (diagnostic.severity) {
      TextDiagnosticSeverity.error => '×',
      TextDiagnosticSeverity.warning => '▲',
      TextDiagnosticSeverity.info => 'i',
      TextDiagnosticSeverity.hint => '·',
    };
    final message =
        diagnostic.message ?? diagnostic.code ?? diagnostic.severity.name;
    return w.Container(
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      color: theme.background,
      child: w.Text(
        '$marker $message',
        style: theme.labelMedium.copy().foreground(color),
        softWrap: false,
      ),
    );
  }

  w.Widget _buildExplorer(w.BuildContext context, {required int height}) {
    final theme = w.ThemeScope.of(context);
    return w.LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toInt()
            : 24;
        final activePath = _buffer?.file.path;
        return w.Container(
          color: theme.surface,
          child: w.Column(
            gap: 0,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Container(
                padding: const w.EdgeInsets.symmetric(horizontal: 1),
                color: theme.resolvedSurfaceVariant,
                child: w.Text(
                  p.basename(_workspace.root).toUpperCase(),
                  style: theme.titleSmall,
                ),
              ),
              w.Expanded(
                child: w.TreeView<EditorFileEntry?>.model(
                  key: const w.ValueKey('workspace-file-tree'),
                  model: _fileTree,
                  height: (height - 1).clamp(4, 80),
                  width: (width - 1).clamp(4, 200),
                  showScrollbar: true,
                  focusController: _focus,
                  focusId: 'explorer',
                  itemBuilder: (context, row) =>
                      _buildExplorerRow(context, row, activePath, width),
                  onActivated: (item) {
                    final file = item.value;
                    return file == null ? runtime.Cmd.none() : _open(file);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  w.Widget _buildExplorerRow(
    w.BuildContext context,
    TreeRow<EditorFileEntry?> row,
    String? activePath,
    int width,
  ) {
    final theme = w.ThemeScope.of(context);
    final item = row.item;
    final file = item.value;
    final isDirectory = file == null;
    final isActive = file != null && activePath == file.path;
    final leading = isDirectory
        ? row.isExpanded
              ? '▾'
              : '▸'
        : isActive
        ? '›'
        : ' ';
    final trailing = isDirectory
        ? ' ${item.children.length}'
        : _isOpen(file)
        ? ' ●'
        : '';
    final line = '${row.prefix}${row.connector}$leading ${item.label}$trailing';
    final visible = _panExplorerLine(
      line,
      _fileTree.horizontalOffset,
      (width - 2).clamp(4, 200),
    );
    return w.ListTile(
      key: w.ValueKey('explorer:${item.id}'),
      dense: true,
      selected: isActive,
      padding: w.EdgeInsets.zero,
      background: theme.surface,
      selectedBackground: theme.resolvedSurfaceVariant,
      foreground: isDirectory
          ? theme.resolvedOnSurfaceVariant
          : theme.onSurface,
      selectedForeground: theme.primary,
      titleStyle: isDirectory ? theme.labelMedium : theme.bodyMedium,
      title: w.Text(
        visible,
        softWrap: false,
        overflow: w.TextOverflow.clip,
        maxWidth: (width - 2).clamp(4, 200),
      ),
    );
  }

  w.Widget _buildEditorArea(
    w.BuildContext context, {
    required int editorHeight,
    required bool showPanel,
  }) {
    final buffer = _buffer;
    if (buffer == null) {
      return w.Center(child: w.Text('No open buffer'));
    }
    final openBuffers = _workspace.openBuffers;
    final editorScroll = _editorScrollControllers.putIfAbsent(
      buffer.file.path,
      () => _EditorScrollController(buffer),
    )..viewportExtent = (editorHeight - 4).clamp(1, editorHeight);

    return w.Column(
      gap: 0,
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        _buildBufferTabs(context, openBuffers, buffer),
        w.Container(
          height: editorHeight,
          child: w.LayoutBuilder(
            builder: (context, constraints) {
              final editorPane = _buildEditablePane(
                context,
                buffer,
                editorScroll,
                editorHeight,
              );
              if (!_showsMarkdownPreview(buffer)) return editorPane;

              final width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth.toInt()
                  : 80;
              final initialEditorWidth = (width * 0.55).round();
              return w.ResizableSplitView(
                key: w.ValueKey('markdown-preview-split:${buffer.file.path}'),
                initialFirstExtent: initialEditorWidth,
                minFirstExtent: 32,
                minSecondExtent: 24,
                separator: w.Container(
                  color: w.ThemeScope.of(context).border,
                  child: w.Text(
                    '│',
                    style: w.ThemeScope.of(context).labelSmall,
                  ),
                ),
                first: editorPane,
                second: _buildMarkdownPreview(context, buffer, editorHeight),
              );
            },
          ),
        ),
        if (showPanel) _buildBottomPanel(context),
      ],
    );
  }

  w.Widget _buildEditablePane(
    w.BuildContext context,
    EditorBuffer buffer,
    _EditorScrollController editorScroll,
    int editorHeight,
  ) {
    return w.Stack(
      height: editorHeight,
      fit: w.StackFit.expand,
      children: [
        w.GestureDetector(
          onTapUp: (details) =>
              _showInlineDiagnostic(buffer, details.globalPosition.dy.toInt()),
          child: w.Scrollbar(
            key: w.ValueKey('editor-scrollbar:${buffer.file.path}'),
            controller: editorScroll,
            overlay: true,
            enableHover: true,
            mouseWheelDelta: 3,
            zoneId: 'editor-scrollbar:${buffer.file.path}',
            child: editors.CodeEditor(
              key: w.ValueKey(buffer.file.path),
              title: buffer.file.relativePath,
              language: buffer.file.language,
              controller: buffer.controller,
              focusController: _focus,
              focusId: 'editor',
              autofocus: true,
              height: editorHeight,
              showPreview: false,
              showHelpBar: false,
              showChrome: false,
              softWrap: false,
              showSaveStatus: false,
              onChanged: (_) => setState(() {}),
              onSave: (_) => _save(),
            ),
          ),
        ),
        if (buffer.controller.model.completionVisible)
          w.Positioned(
            left: 7 + buffer.controller.column,
            top: 2,
            child: _buildCompletionPopup(context, buffer),
          ),
        if (_hover case final hover?)
          w.Positioned(
            left: 7 + buffer.controller.column,
            top: 2,
            child: _buildHoverPopup(hover),
          ),
      ],
    );
  }

  w.Widget _buildMarkdownPreview(
    w.BuildContext context,
    EditorBuffer buffer,
    int editorHeight,
  ) {
    final theme = w.ThemeScope.of(context);
    return w.Container(
      color: theme.background,
      child: w.Column(
        gap: 0,
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Container(
            color: theme.resolvedSurfaceVariant,
            padding: const w.EdgeInsets.only(left: 1),
            child: w.Row(
              gap: 0,
              children: [
                w.Text('MARKDOWN PREVIEW', style: theme.labelSmall),
                w.Spacer(),
                w.GestureDetector(
                  key: w.ValueKey('close-markdown-preview:${buffer.file.path}'),
                  onTap: _toggleMarkdownPreview,
                  child: w.Container(
                    padding: const w.EdgeInsets.symmetric(horizontal: 1),
                    child: w.Text('×', style: theme.labelSmall),
                  ),
                ),
              ],
            ),
          ),
          w.Expanded(
            child: w.LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.isFinite
                    ? constraints.maxWidth.toInt()
                    : 40;
                final height = constraints.maxHeight.isFinite
                    ? constraints.maxHeight.toInt()
                    : editorHeight - 1;
                return w.ScrollArea(
                  key: w.ValueKey('markdown-preview:${buffer.file.path}'),
                  width: width,
                  height: height,
                  padding: const w.EdgeInsets.only(
                    left: 1,
                    top: 1,
                    right: 2,
                    bottom: 1,
                  ),
                  child: w.MarkdownText(
                    data: buffer.controller.text,
                    maxWidth: (width - 4).clamp(8, 200),
                    softWrap: true,
                    textStyle: theme.bodyMedium.copy().foreground(
                      theme.onBackground,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  runtime.Cmd _showInlineDiagnostic(EditorBuffer buffer, int screenRow) {
    final diagnostic = buffer.controller.activeDiagnostic;
    setState(() {
      _inlineDiagnostic = diagnostic == null
          ? null
          : _InlineDiagnostic(
              path: buffer.file.path,
              diagnostic: diagnostic,
              screenRow: screenRow,
            );
      if (diagnostic != null) {
        _activity = _problemLocation(buffer, diagnostic);
      }
    });
    return runtime.Cmd.none();
  }

  w.Widget _buildBufferTabs(
    w.BuildContext context,
    List<EditorBuffer> openBuffers,
    EditorBuffer activeBuffer,
  ) {
    final theme = w.ThemeScope.of(context);
    return w.Container(
      color: theme.surface,
      child: w.Row(
        gap: 0,
        children: [
          for (final open in openBuffers)
            w.Row(
              key: w.ValueKey('buffer-tab:${open.file.path}'),
              gap: 0,
              children: [
                w.Button(
                  label: '${open.isDirty ? "● " : ""}${open.file.name}',
                  variant: identical(open, activeBuffer)
                      ? w.ButtonVariant.secondary
                      : w.ButtonVariant.ghost,
                  size: w.ButtonSize.small,
                  textStyle: identical(open, activeBuffer)
                      ? theme.titleSmall
                      : theme.labelMedium,
                  onPressed: () {
                    setState(() {
                      _workspace.activate(open);
                      _hover = null;
                      _activity = 'Opened ${open.file.relativePath}';
                    });
                    _focus.requestFocus('editor');
                    return runtime.Cmd.none();
                  },
                ),
                w.Button(
                  key: w.ValueKey('close-tab:${open.file.path}'),
                  label: '×',
                  variant: identical(open, activeBuffer)
                      ? w.ButtonVariant.secondary
                      : w.ButtonVariant.ghost,
                  size: w.ButtonSize.small,
                  padding: const w.EdgeInsets.symmetric(horizontal: 1),
                  onPressed: () => _closeBuffer(open),
                ),
              ],
            ),
        ],
      ),
    );
  }

  w.Widget _buildCompletionPopup(w.BuildContext context, EditorBuffer buffer) {
    final model = buffer.controller.model;
    final items = model.completionItems.take(8).toList(growable: false);
    return w.Container(
      width: 42,
      child: w.PanelBox(
        title: 'COMPLETIONS',
        border: Border.rounded,
        padding: const w.EdgeInsets.symmetric(horizontal: 1),
        child: w.Column(
          gap: 0,
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < items.length; index++)
              w.Text(
                '${index == model.completionIndex ? "›" : " "} '
                '${items[index].label}'
                '${items[index].detail.isEmpty ? "" : "  ${items[index].detail}"}',
                softWrap: false,
                overflow: w.TextOverflow.ellipsis,
                maxWidth: 38,
              ),
          ],
        ),
      ),
    );
  }

  w.Widget _buildHoverPopup(EditorLanguageHover hover) {
    return w.Container(
      width: 52,
      child: w.PanelBox(
        title: 'HOVER',
        border: Border.rounded,
        padding: const w.EdgeInsets.symmetric(horizontal: 1),
        child: w.MarkdownText(
          data: _boundedHoverContents(hover.contents),
          maxWidth: 48,
        ),
      ),
    );
  }

  w.Widget _buildBottomPanel(w.BuildContext context) {
    final tabs = const [w.TabItem('Problems'), w.TabItem('Output')];
    return w.Container(
      height: 7,
      color: w.ThemeScope.of(context).surface,
      child: w.Column(
        gap: 0,
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Tabs(
            tabs: tabs,
            index: _panelIndex,
            onChanged: (index) {
              setState(() => _panelIndex = index);
              return null;
            },
          ),
          w.Expanded(
            child: _panelIndex == 0
                ? _buildProblems(context)
                : w.Container(
                    padding: const w.EdgeInsets.symmetric(horizontal: 1),
                    child: w.Column(
                      gap: 0,
                      crossAxisAlignment: w.CrossAxisAlignment.stretch,
                      children: [
                        for (final line in _workspace.outputLines.reversed.take(
                          3,
                        ))
                          w.Text(
                            line,
                            softWrap: false,
                            overflow: w.TextOverflow.ellipsis,
                          ),
                        if (_workspace.outputLines.isEmpty) w.Text(_activity),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  w.Widget _buildProblems(w.BuildContext context) {
    final problems = <({EditorBuffer buffer, TextDiagnosticRange diagnostic})>[
      for (final buffer in _workspace.openBuffers)
        for (final diagnostic in buffer.controller.diagnostics)
          (buffer: buffer, diagnostic: diagnostic),
    ];
    if (problems.isEmpty) {
      return w.Container(
        padding: const w.EdgeInsets.symmetric(horizontal: 1),
        child: w.Text('No problems detected'),
      );
    }

    return w.Container(
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      child: w.Column(
        gap: 0,
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          for (final item in problems.take(3))
            _problemRow(context, item.buffer, item.diagnostic),
        ],
      ),
    );
  }

  w.Widget _problemRow(
    w.BuildContext context,
    EditorBuffer buffer,
    TextDiagnosticRange diagnostic,
  ) {
    final position = buffer.controller.document.positionForOffset(
      diagnostic.startOffset,
    );
    final marker = switch (diagnostic.severity) {
      TextDiagnosticSeverity.error => '✕',
      TextDiagnosticSeverity.warning => '▲',
      TextDiagnosticSeverity.info => '●',
      TextDiagnosticSeverity.hint => '·',
    };
    return w.ListTile(
      dense: true,
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      leading: w.Text(marker),
      title: diagnostic.message ?? diagnostic.code ?? 'Problem',
      trailing: w.Text(
        '${buffer.file.name}:${position.line + 1}:${position.column + 1}',
      ),
      onTap: () {
        setState(() => _workspace.activate(buffer));
        buffer.controller.setCursor(position.line, position.column);
        _focus.requestFocus('editor');
        return null;
      },
    );
  }

  w.Widget _buildStatusLine(w.BuildContext context) {
    final buffer = _buffer;
    final diagnostics = buffer?.controller.diagnostics ?? const [];
    final errors = diagnostics
        .where((item) => item.severity == TextDiagnosticSeverity.error)
        .length;
    final warnings = diagnostics
        .where((item) => item.severity == TextDiagnosticSeverity.warning)
        .length;
    return w.StatusLine(
      left: [
        w.StatusItem.text(buffer?.modal.modeLabel ?? 'NORMAL'),
        w.StatusItem.text(_activity),
        w.StatusItem.text(p.basename(_workspace.root)),
      ],
      center: [if (buffer != null) w.StatusItem.text(buffer.file.relativePath)],
      right: [
        w.StatusItem.text('✕ $errors  ▲ $warnings'),
        w.StatusItem.text(_workspace.languageReady ? 'LSP ready' : 'LSP idle'),
        if (buffer != null)
          w.StatusItem.text(
            'Ln ${buffer.controller.line + 1}, '
            'Col ${buffer.controller.column + 1}',
          ),
        w.StatusItem.text(buffer?.file.language ?? 'text'),
        const w.StatusItem.text('UTF-8'),
      ],
      separator: ' │ ',
    );
  }

  bool _isOpen(EditorFileEntry file) =>
      _workspace.openBuffers.any((buffer) => buffer.file.path == file.path);
}

final class _EditorScrollController implements w.ScrollController {
  _EditorScrollController(this.buffer);

  final EditorBuffer buffer;
  final Set<void Function()> _listeners = {};
  @override
  int viewportExtent = 1;

  @override
  int get contentExtent => buffer.controller.model.lineCount;

  @override
  int get maxOffset => contentExtent <= 1 ? 0 : contentExtent - 1;

  @override
  int get offset => buffer.controller.line.clamp(0, maxOffset);

  @override
  double get scrollPercent => maxOffset == 0 ? 0 : offset / maxOffset;

  @override
  bool jumpTo(int offset) {
    final target = offset.clamp(0, maxOffset);
    if (target == buffer.controller.line) return false;
    final column = buffer.controller.column.clamp(
      0,
      buffer.controller.document.lineLength(target),
    );
    buffer.controller.setCursor(target, column);
    for (final listener in _listeners.toList(growable: false)) {
      listener();
    }
    return true;
  }

  @override
  bool scrollBy(int delta) => jumpTo(offset + delta);

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void dispose() {
    _listeners.clear();
  }
}

final class _FileTreeBuilderNode {
  _FileTreeBuilderNode({
    required this.name,
    required this.relativePath,
    this.file,
  });

  final String name;
  final String relativePath;
  EditorFileEntry? file;
  final List<_FileTreeBuilderNode> children = [];

  bool get isDirectory => file == null;
}

List<TreeItem<EditorFileEntry?>> _buildFileTree(
  Iterable<EditorFileEntry> files,
) {
  final roots = <_FileTreeBuilderNode>[];
  for (final file in files) {
    final parts = p
        .split(p.normalize(file.relativePath))
        .where((part) => part != '.' && part.isNotEmpty)
        .toList(growable: false);
    var siblings = roots;
    final pathParts = <String>[];
    for (var index = 0; index < parts.length; index++) {
      final name = parts[index];
      pathParts.add(name);
      final relativePath = p.joinAll(pathParts);
      final isFile = index == parts.length - 1;
      var node = siblings
          .where((candidate) => candidate.name == name)
          .firstOrNull;
      if (node == null) {
        node = _FileTreeBuilderNode(
          name: name,
          relativePath: relativePath,
          file: isFile ? file : null,
        );
        siblings.add(node);
      } else if (isFile) {
        node.file = file;
      }
      siblings = node.children;
    }
  }
  _sortFileTree(roots);
  return _freezeFileTree(roots);
}

void _sortFileTree(List<_FileTreeBuilderNode> nodes) {
  nodes.sort((left, right) {
    if (left.isDirectory != right.isDirectory) {
      return left.isDirectory ? -1 : 1;
    }
    return left.name.toLowerCase().compareTo(right.name.toLowerCase());
  });
  for (final node in nodes) {
    _sortFileTree(node.children);
  }
}

List<TreeItem<EditorFileEntry?>> _freezeFileTree(
  List<_FileTreeBuilderNode> nodes,
) {
  return [
    for (final node in nodes)
      TreeItem<EditorFileEntry?>(
        id: node.relativePath,
        label: node.name,
        value: node.file,
        children: _freezeFileTree(node.children),
        initiallyExpanded: false,
      ),
  ];
}

String _panExplorerLine(String line, int offset, int width) {
  if (width <= 0 || line.isEmpty) return '';
  final start = offset.clamp(0, line.length);
  final end = (start + width).clamp(start, line.length);
  return line.substring(start, end);
}

String _boundedHoverContents(String contents) {
  const maxLines = 12;
  const maxCharacters = 2000;
  final boundedCharacters = contents.length <= maxCharacters
      ? contents
      : '${contents.substring(0, maxCharacters)}…';
  final lines = boundedCharacters.split('\n');
  return lines.length <= maxLines
      ? boundedCharacters
      : '${lines.take(maxLines).join('\n')}\n…';
}

bool _isControlCharacter(Key key, String character) {
  return key.ctrl &&
      !key.alt &&
      !key.meta &&
      key.type == KeyType.runes &&
      key.char?.toLowerCase() == character;
}

bool _isControlShiftCharacter(Key key, String character) {
  return key.shift && _isControlCharacter(key, character);
}

bool _isCompletionShortcut(Key key) {
  return !key.isRelease && key.ctrl && !key.alt && !key.meta && key.isSpaceLike;
}

bool _isCompletionNavigationKey(Key key) {
  return switch (key.type) {
    KeyType.up ||
    KeyType.down ||
    KeyType.tab ||
    KeyType.enter ||
    KeyType.escape => true,
    _ => false,
  };
}

String? _normalizeKey(Key key) {
  if (key.isRelease) return null;
  final character = key.char;
  if (character != null && character.isNotEmpty) {
    final shifted =
        key.shift && character.toUpperCase() != character.toLowerCase();
    final value = shifted ? character.toUpperCase() : character;
    final modifiers = [
      if (key.ctrl) 'ctrl',
      if (key.alt) 'alt',
      if (key.meta) 'meta',
      if (key.superKey) 'super',
    ];
    return modifiers.isEmpty
        ? value
        : '${modifiers.join('+')}+${value.toLowerCase()}';
  }

  final name = switch (key.type) {
    KeyType.escape => 'escape',
    KeyType.left => 'left',
    KeyType.right => 'right',
    KeyType.up => 'up',
    KeyType.down => 'down',
    KeyType.home => 'home',
    KeyType.end => 'end',
    KeyType.delete => 'delete',
    KeyType.backspace => 'backspace',
    _ => null,
  };
  return name;
}
