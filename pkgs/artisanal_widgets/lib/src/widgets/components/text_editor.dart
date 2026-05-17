import 'dart:math' as math;

import 'package:artisanal/bubbles.dart' hide Text, Row, Column;
import 'package:artisanal/style.dart';
import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart' show Cmd, KeyBinding, KeyMsg, KeyMap;
import 'package:artisanal/widgets.dart';

import 'text_area_controller_core_bridge.dart' show TextAreaControllerCoreBridge;

/// A higher-level editor surface built on top of [TextArea].
///
/// `TextEditor` adds lightweight chrome around the raw textarea:
/// a title row, dirty/save status, cursor/length status, and a compact
/// shortcuts bar.
///
/// ```dart
/// final controller = TextAreaController(text: 'notes');
///
/// TextEditor(
///   title: 'Scratchpad',
///   controller: controller,
///   height: 8,
///   onSave: (value) => saveDraft(value),
/// )
/// ```
class TextEditor extends StatefulWidget {
  TextEditor({
    this.title = 'Editor',
    this.controller,
    this.model,
    this.focusController,
    this.focusId,
    this.autofocus = false,
    this.enabled = true,
    this.prompt,
    this.placeholder,
    this.width,
    this.height = 8,
    this.showLineNumbers = true,
    this.softWrap = true,
    this.useVirtualCursor,
    this.keyMap,
    this.styles,
    this.cursor,
    this.showHelpBar = true,
    this.helpExpanded = false,
    this.headerTrailing,
    this.footer,
    this.onChanged,
    this.onSave,
    this.onKey,
    this.extraHelpBindings = const [],
    this.showSaveStatus = true,
    this.cleanLabel = 'saved',
    this.dirtyLabel = 'modified',
    this.indentWidth = 2,
    super.key,
  });

  /// Title shown in the editor header.
  final String title;

  /// Optional textarea controller.
  final TextAreaController? controller;

  /// Optional textarea model.
  final TextAreaModel? model;

  /// Optional focus controller for focus coordination.
  final FocusController? focusController;

  /// Optional focus identifier.
  final String? focusId;

  /// Whether to request focus on first build.
  final bool autofocus;

  /// Whether input is enabled.
  final bool enabled;

  /// Prompt displayed before each line.
  final String? prompt;

  /// Placeholder text when empty.
  final String? placeholder;

  /// Explicit editor width in cells.
  final int? width;

  /// Visible editor height in rows.
  final int height;

  /// Whether to show line numbers.
  final bool showLineNumbers;

  /// Whether to soft-wrap long lines.
  final bool softWrap;

  /// Whether to render a virtual cursor.
  final bool? useVirtualCursor;

  /// Optional key bindings for the embedded textarea.
  final TextAreaKeyMap? keyMap;

  /// Optional textarea styles.
  final TextAreaStyles? styles;

  /// Optional cursor model.
  final CursorModel? cursor;

  /// Whether to show the compact help footer.
  final bool showHelpBar;

  /// Whether to expand the help footer into grouped mode.
  final bool helpExpanded;

  /// Optional trailing widget in the header row.
  final Widget? headerTrailing;

  /// Optional footer widget shown below the help bar.
  final Widget? footer;

  /// Called when the text changes.
  final TextChangedCallback? onChanged;

  /// Called when the user saves the current editor contents with `Ctrl+S`.
  final ValueCmdCallback<String>? onSave;

  /// Optional extra key handler invoked after search/goto handling and before
  /// the default indent/save shortcuts.
  final ValueCmdCallback<KeyMsg>? onKey;

  /// Optional additional help bindings to show in the footer.
  final List<KeyBinding> extraHelpBindings;

  /// Whether to show the clean/dirty status label in the header.
  final bool showSaveStatus;

  /// Header label shown after the current contents have been saved.
  final String cleanLabel;

  /// Header label shown when the contents have unsaved changes.
  final String dirtyLabel;

  /// Number of spaces inserted when `Tab` is pressed inside the editor.
  final int indentWidth;

  @override
  State createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  static const Map<String, String> _selectionWrapPairs = {
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
    "'": "'",
    '`': '`',
  };
  static final KeyBinding _saveBinding = KeyBinding.withHelp(
    ['ctrl+s'],
    'ctrl+s',
    'save',
  );
  static final KeyBinding _searchBinding = KeyBinding.withHelp(
    ['ctrl+f'],
    'ctrl+f',
    'find',
  );
  static final KeyBinding _gotoBinding = KeyBinding.withHelp(
    ['ctrl+g'],
    'ctrl+g',
    'go to line',
  );
  static final KeyBinding _searchNextBinding = KeyBinding.withHelp(
    ['enter'],
    'enter',
    'next match',
  );
  static final KeyBinding _searchPreviousBinding = KeyBinding.withHelp(
    ['shift+enter'],
    'shift+enter',
    'prev match',
  );
  static final KeyBinding _searchCloseBinding = KeyBinding.withHelp(
    ['esc'],
    'esc',
    'close find',
  );
  static final KeyBinding _gotoApplyBinding = KeyBinding.withHelp(
    ['enter'],
    'enter',
    'go to line',
  );
  static final KeyBinding _gotoCloseBinding = KeyBinding.withHelp(
    ['esc'],
    'esc',
    'close goto',
  );
  static final KeyBinding _nextDiagnosticBinding = KeyBinding.withHelp(
    ['f8'],
    'f8',
    'next diagnostic',
  );
  static final KeyBinding _previousDiagnosticBinding = KeyBinding.withHelp(
    ['shift+f8'],
    'shift+f8',
    'prev diagnostic',
  );
  static final KeyBinding _indentBinding = KeyBinding.withHelp(
    ['tab'],
    'tab',
    'indent',
  );
  static final KeyBinding _outdentBinding = KeyBinding.withHelp(
    ['shift+tab'],
    'shift+tab',
    'outdent',
  );
  static final KeyBinding _joinLinesBinding = KeyBinding.withHelp(
    ['alt+j'],
    'alt+j',
    'join lines',
  );
  static final KeyBinding _deleteLineBinding = KeyBinding.withHelp(
    ['ctrl+shift+k'],
    'ctrl+shift+k',
    'delete line',
  );
  static final KeyBinding _duplicateLineBinding = KeyBinding.withHelp(
    ['ctrl+shift+d'],
    'ctrl+shift+d',
    'duplicate line',
  );
  static final KeyBinding _duplicateLineAboveBinding = KeyBinding.withHelp(
    ['alt+shift+up'],
    'alt+shift+↑',
    'duplicate above',
  );
  static final KeyBinding _duplicateLineBelowBinding = KeyBinding.withHelp(
    ['alt+shift+down'],
    'alt+shift+↓',
    'duplicate below',
  );
  static final KeyBinding _moveLineUpBinding = KeyBinding.withHelp(
    ['alt+up'],
    'alt+↑',
    'move line up',
  );
  static final KeyBinding _moveLineDownBinding = KeyBinding.withHelp(
    ['alt+down'],
    'alt+↓',
    'move line down',
  );
  static final KeyBinding _splitLineBinding = KeyBinding.withHelp(
    ['alt+shift+j'],
    'alt+shift+j',
    'split line',
  );
  static final KeyBinding _uppercaseTransformBinding = KeyBinding.withHelp(
    ['alt+shift+u'],
    'alt+shift+u',
    'uppercase block',
  );
  static final KeyBinding _lowercaseTransformBinding = KeyBinding.withHelp(
    ['alt+shift+l'],
    'alt+shift+l',
    'lowercase block',
  );
  static final KeyBinding _capitalizeTransformBinding = KeyBinding.withHelp(
    ['alt+shift+c'],
    'alt+shift+c',
    'capitalize block',
  );
  static final KeyBinding _sortLinesBinding = KeyBinding.withHelp(
    ['alt+shift+s'],
    'alt+shift+s',
    'sort lines',
  );
  static final KeyBinding _quoteLinesBinding = KeyBinding.withHelp(
    ['alt+shift+q'],
    'alt+shift+q',
    'quote lines',
  );
  static final KeyBinding _bulletListBinding = KeyBinding.withHelp(
    ['alt+shift+b'],
    'alt+shift+b',
    'bullet list',
  );
  static final KeyBinding _checklistBinding = KeyBinding.withHelp(
    ['alt+shift+x'],
    'alt+shift+x',
    'checklist',
  );
  static final KeyBinding _numberedListBinding = KeyBinding.withHelp(
    ['alt+shift+n'],
    'alt+shift+n',
    'numbered list',
  );
  static final KeyBinding _toggleChecklistStateBinding = KeyBinding.withHelp(
    ['alt+shift+m'],
    'alt+shift+m',
    'mark checklist',
  );
  static final KeyBinding _renumberListBinding = KeyBinding.withHelp(
    ['alt+shift+r'],
    'alt+shift+r',
    'renumber list',
  );
  static final KeyBinding _headingBinding = KeyBinding.withHelp(
    ['alt+shift+h'],
    'alt+shift+h',
    'heading',
  );
  static final KeyBinding _cleanupBinding = KeyBinding.withHelp(
    ['alt+shift+f'],
    'alt+shift+f',
    'cleanup whitespace',
  );
  static final KeyBinding _unwrapSelectionBinding = KeyBinding.withHelp(
    ['alt+shift+w'],
    'alt+shift+w',
    'unwrap selection',
  );

  TextAreaController? _internalController;
  TextFieldController? _internalSearchController;
  TextFieldController? _internalGotoController;
  FocusController? _internalFocusController;
  late final TextDecorationLayerBinding _searchDecorationBinding;
  String? _lastSavedText;
  bool _searchVisible = false;
  bool _gotoVisible = false;
  List<TextHighlightRange> _searchMatches = const [];
  int _activeSearchMatchIndex = -1;
  TextAreaController get _controller =>
      widget.controller ??
      (_internalController ??= TextAreaController(model: widget.model));
  TextFieldController get _searchController =>
      _internalSearchController ??= TextFieldController();
  TextFieldController get _gotoController =>
      _internalGotoController ??= TextFieldController();
  FocusController get _focusController =>
      widget.focusController ??
      (_internalFocusController ??= FocusController());
  String get _focusId => widget.focusId ?? '${widget.id}.editor';
  String get _searchFocusId => '$_focusId.search';
  String get _gotoFocusId => '$_focusId.goto';
  TextAreaControllerCoreBridge get _coreBridge =>
      TextAreaControllerCoreBridge(_controller);

  @override
  void initState() {
    super.initState();
    _lastSavedText = _controller.text;
    _controller.addListener(_handleControllerChanged);
    _searchController.addListener(_handleSearchChanged);
    _searchDecorationBinding = TextDecorationLayerBinding(
      controller: _controller,
      layerKey: textSearchDecorationLayerKey,
      buildDecorations: _buildSearchDecorations,
      priority: textSearchDecorationLayerPriority,
      isActive: () => _searchVisible,
      syncImmediately: false,
    );
  }

  @override
  Cmd? didUpdateWidget(covariant TextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final oldController = oldWidget.controller ?? _internalController;
      oldController?.removeListener(_handleControllerChanged);
      if (!identical(oldController, _controller)) {
        oldController?.clearDecorationLayer(textSearchDecorationLayerKey);
      }
      _searchMatches = const [];
      _activeSearchMatchIndex = -1;
      _searchDecorationBinding.controller = _controller;
      _controller.addListener(_handleControllerChanged);
      _lastSavedText = _controller.text;
    }
    if (oldWidget.model != widget.model && widget.model != null) {
      _controller.model = widget.model!;
      _lastSavedText = _controller.text;
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.model != widget.model) {
      if (_searchVisible) {
        _refreshSearchMatches(jumpToFirst: true, forceDecorationSync: true);
      } else {
        _searchDecorationBinding.clear();
      }
    }
    return null;
  }

  @override
  void dispose() {
    (widget.controller ?? _internalController)?.removeListener(
      _handleControllerChanged,
    );
    _internalSearchController?.removeListener(_handleSearchChanged);
    _searchDecorationBinding.clear();
    _searchDecorationBinding.dispose();
    _internalController?.dispose();
    _internalSearchController?.dispose();
    _internalGotoController?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    if (_searchVisible) {
      _refreshSearchMatches();
    }
    setState(() {});
  }

  bool get _isDirty => _controller.text != (_lastSavedText ?? '');
  bool get _isSearchFocused => _focusController.isFocused(_searchFocusId);
  bool get _isGotoFocused => _focusController.isFocused(_gotoFocusId);
  bool get _isUtilityFocused => _isSearchFocused || _isGotoFocused;
  bool get _hasDiagnostics => _controller.diagnostics.isNotEmpty;

  void _handleSearchChanged() {
    if (!mounted) return;
    _refreshSearchMatches(jumpToFirst: true, forceDecorationSync: true);
    setState(() {});
  }

  void _openSearch() {
    setState(() {
      _searchVisible = true;
      _gotoVisible = false;
    });
    _refreshSearchMatches(jumpToFirst: true, forceDecorationSync: true);
    _focusController.requestFocus(_searchFocusId);
  }

  void _openGotoLine() {
    _gotoController.text = '${_controller.line + 1}';
    setState(() {
      _gotoVisible = true;
      _searchVisible = false;
    });
    _searchDecorationBinding.clear();
    _focusController.requestFocus(_gotoFocusId);
  }

  void _closeUtilityBar() {
    final wasSearchVisible = _searchVisible;
    setState(() {
      _searchVisible = false;
      _gotoVisible = false;
    });
    if (wasSearchVisible) {
      _searchDecorationBinding.clear();
    }
    _focusController.requestFocus(_focusId);
  }

  List<TextDecorationRange> _buildSearchDecorations(String _) {
    if (!_searchVisible || _searchMatches.isEmpty) {
      return const [];
    }
    return textSearchDecorations(
      _searchMatches,
      activeIndex: _activeSearchMatchIndex,
    );
  }

  void _refreshSearchMatches({
    bool jumpToFirst = false,
    bool forceDecorationSync = false,
  }) {
    final document = _controller.document;
    final matches = findTextQueryHighlights(
      document: document,
      query: _searchController.text,
    );
    _searchMatches = matches;
    if (matches.isEmpty) {
      _activeSearchMatchIndex = -1;
      _searchDecorationBinding.sync(force: forceDecorationSync);
      return;
    }

    if (jumpToFirst) {
      _activeSearchMatchIndex = 0;
      _searchDecorationBinding.sync(force: forceDecorationSync);
      _jumpToSearchMatch(0, document: document);
      return;
    }

    if (_activeSearchMatchIndex < 0) {
      _activeSearchMatchIndex = 0;
    }
    if (_activeSearchMatchIndex >= matches.length) {
      _activeSearchMatchIndex = matches.length - 1;
    }
    _searchDecorationBinding.sync(force: forceDecorationSync);
  }

  void _jumpToSearchMatch(int index, {TextDocument? document}) {
    final match = _searchMatches[index];
    final searchDocument = document ?? _controller.document;
    final position = searchDocument.positionForOffset(match.startOffset);
    _controller.setCursor(position.line, position.column);
  }

  void _stepSearch(int delta) {
    if (_searchMatches.isEmpty) return;
    final next = (_activeSearchMatchIndex + delta) % _searchMatches.length;
    final normalized = next < 0 ? next + _searchMatches.length : next;
    setState(() {
      _activeSearchMatchIndex = normalized;
    });
    _searchDecorationBinding.sync(force: true);
    _jumpToSearchMatch(normalized);
  }

  void _stepDiagnostic(int delta) {
    final changed = delta < 0
        ? _controller.selectPreviousDiagnostic()
        : _controller.selectNextDiagnostic();
    if (changed) {
      _focusController.requestFocus(_focusId);
    }
  }

  Color _diagnosticColor(Theme theme, TextDiagnosticSeverity severity) {
    return switch (severity) {
      TextDiagnosticSeverity.error => theme.error,
      TextDiagnosticSeverity.warning => theme.warning,
      TextDiagnosticSeverity.info => theme.resolvedInfo,
      TextDiagnosticSeverity.hint => theme.resolvedOnSurfaceVariant,
    };
  }

  void _applyGotoLine() {
    final requested = int.tryParse(_gotoController.text.trim());
    if (requested == null) return;
    final totalLines = _controller.document.lineCount;
    final clamped = requested.clamp(1, totalLines);
    _controller.setCursor(clamped - 1, 0);
  }

  Cmd? _handleEditorKey(KeyMsg msg) {
    final key = msg.key;
    if (keyMatchesSingle(key, _searchBinding)) {
      _openSearch();
      return Cmd.none();
    }
    if (keyMatchesSingle(key, _gotoBinding)) {
      _openGotoLine();
      return Cmd.none();
    }

    if (_searchVisible && _isSearchFocused) {
      if (key.type == terminal_keys.KeyType.escape) {
        _closeUtilityBar();
        return Cmd.none();
      }
      if (key.isEnterLike) {
        _stepSearch(key.shift ? -1 : 1);
        return Cmd.none();
      }
    }

    if (_gotoVisible && _isGotoFocused) {
      if (key.type == terminal_keys.KeyType.escape) {
        _closeUtilityBar();
        return Cmd.none();
      }
      if (key.isEnterLike) {
        _applyGotoLine();
        _closeUtilityBar();
        return Cmd.none();
      }
    }

    if (_hasDiagnostics &&
        key.type == terminal_keys.KeyType.f8 &&
        !key.ctrl &&
        !key.alt &&
        !key.meta) {
      _stepDiagnostic(key.shift ? -1 : 1);
      return Cmd.none();
    }

    final extraCmd = widget.onKey?.call(msg);
    if (extraCmd != null) {
      return extraCmd;
    }

    if (key.type == terminal_keys.KeyType.tab &&
        key.shift &&
        !key.ctrl &&
        !key.alt &&
        !key.meta) {
      final width = widget.indentWidth < 1 ? 1 : widget.indentWidth;
      _applyLineEdit(
        (document, state) => textOutdentLinesDocument(
          document: document,
          state: state,
          width: width,
        ),
      );
      return Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.tab &&
        !key.shift &&
        !key.ctrl &&
        !key.alt &&
        !key.meta) {
      final width = widget.indentWidth < 1 ? 1 : widget.indentWidth;
      if (_controller.hasSelection) {
        _applyLineEdit(
          (document, state) => textIndentLinesDocument(
            document: document,
            state: state,
            width: width,
          ),
        );
        return Cmd.none();
      }
      _controller.insertText(' ' * width);
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _joinLinesBinding)) {
      _applyLineEdit(
        (document, state) =>
            textJoinLinesDocument(document: document, state: state),
      );
      return Cmd.none();
    }

    if (key.ctrl &&
        key.shift &&
        !key.alt &&
        !key.meta &&
        key.type == terminal_keys.KeyType.runes &&
        key.runes.isNotEmpty &&
        String.fromCharCode(key.runes.first).toLowerCase() == 'k') {
      _applyLineEdit(
        (document, state) =>
            textDeleteLinesDocument(document: document, state: state),
      );
      return Cmd.none();
    }

    if (key.ctrl &&
        key.shift &&
        !key.alt &&
        !key.meta &&
        key.type == terminal_keys.KeyType.runes &&
        key.runes.isNotEmpty &&
        String.fromCharCode(key.runes.first).toLowerCase() == 'd') {
      _applyLineEdit(
        (document, state) => textDuplicateSelectedLinesBelowDocument(
          document: document,
          state: state,
        ),
      );
      return Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.up &&
        key.alt &&
        key.shift &&
        !key.ctrl &&
        !key.meta) {
      _applyLineEdit(
        (document, state) => textDuplicateSelectedLinesAboveDocument(
          document: document,
          state: state,
        ),
      );
      return Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.down &&
        key.alt &&
        key.shift &&
        !key.ctrl &&
        !key.meta) {
      _applyLineEdit(
        (document, state) => textDuplicateSelectedLinesBelowDocument(
          document: document,
          state: state,
        ),
      );
      return Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.up &&
        key.alt &&
        !key.shift &&
        !key.ctrl &&
        !key.meta) {
      _applyLineEdit(
        (document, state) => textMoveSelectedLinesDocument(
          document: document,
          state: state,
          direction: -1,
        ),
      );
      return Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.down &&
        key.alt &&
        !key.shift &&
        !key.ctrl &&
        !key.meta) {
      _applyLineEdit(
        (document, state) => textMoveSelectedLinesDocument(
          document: document,
          state: state,
          direction: 1,
        ),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _splitLineBinding)) {
      _applyOffsetEdit(
        (document, state) => textSplitLine(document: document, state: state),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _uppercaseTransformBinding)) {
      _applyOffsetEdit(
        (document, state) => textTransformSelectionOrLine(
          document: document,
          state: state,
          transform: (text) => text.toUpperCase(),
        ),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _lowercaseTransformBinding)) {
      _applyOffsetEdit(
        (document, state) => textTransformSelectionOrLine(
          document: document,
          state: state,
          transform: (text) => text.toLowerCase(),
        ),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _capitalizeTransformBinding)) {
      _applyOffsetEdit(
        (document, state) => textTransformSelectionOrLine(
          document: document,
          state: state,
          transform: textCapitalizeWords,
        ),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _sortLinesBinding)) {
      _applyLineEdit(
        (document, state) =>
            textSortSelectedLinesDocument(document: document, state: state),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _quoteLinesBinding)) {
      _applyLineEdit(
        (document, state) => textToggleLinePrefixDocument(
          document: document,
          state: state,
          prefix: '>',
        ),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _bulletListBinding)) {
      _applyLineEdit(
        (document, state) => textToggleLinePrefixDocument(
          document: document,
          state: state,
          prefix: '-',
        ),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _checklistBinding)) {
      _applyLineEdit(
        (document, state) => textToggleLinePrefixDocument(
          document: document,
          state: state,
          prefix: '- [ ]',
        ),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _numberedListBinding)) {
      _applyLineEdit(
        (document, state) =>
            textToggleNumberedListDocument(document: document, state: state),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _toggleChecklistStateBinding)) {
      _applyLineEdit(
        (document, state) =>
            textToggleChecklistStateDocument(document: document, state: state),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _renumberListBinding)) {
      _applyLineEdit(
        (document, state) =>
            textRenumberNumberedListDocument(document: document, state: state),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _headingBinding)) {
      _applyLineEdit(
        (document, state) =>
            textToggleHeadingPrefixDocument(document: document, state: state),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _cleanupBinding)) {
      _applyLineEdit(
        (document, state) =>
            textCleanupWhitespaceDocument(document: document, state: state),
      );
      return Cmd.none();
    }

    if (keyMatchesSingle(key, _unwrapSelectionBinding)) {
      _handleUnwrapSelectionKey();
      return Cmd.none();
    }

    if (_handleSelectionWrapKey(key)) {
      return Cmd.none();
    }

    if (widget.onSave == null || !keyMatchesSingle(msg.key, _saveBinding)) {
      return null;
    }
    final text = _controller.text;
    _controller.pushHistoryBoundary();
    setState(() {
      _lastSavedText = text;
    });
    return widget.onSave!(text) ?? Cmd.none();
  }

  bool _handleSelectionWrapKey(terminal_keys.Key key) {
    if (!_controller.hasSelection) return false;
    if (key.type != terminal_keys.KeyType.runes ||
        key.runes.length != 1 ||
        key.ctrl ||
        key.alt ||
        key.meta) {
      return false;
    }
    final opening = String.fromCharCode(key.runes.single);
    final closing = _selectionWrapPairs[opening];
    if (closing == null) return false;
    final document = _controller.document;
    final result = textWrapSelection(
      document: document,
      state: _coreBridge.currentOffsetStateSnapshot(document: document),
      before: opening,
      after: closing,
    );
    if (!result.changed) {
      return false;
    }
    _coreBridge.applyTextCommandResult(result);
    return true;
  }

  bool _handleUnwrapSelectionKey() {
    if (!_controller.hasSelection) return false;
    final document = _controller.document;
    final result = textUnwrapSelection(
      document: document,
      state: _coreBridge.currentOffsetStateSnapshot(document: document),
      surroundPairs: _selectionWrapPairs,
    );
    if (!result.changed) {
      return false;
    }
    _coreBridge.applyTextCommandResult(result);
    return true;
  }

  void _applyOffsetEdit(
    TextCommandResult Function(
      TextDocument document,
      TextOffsetStateSnapshot state,
    )
    edit,
  ) {
    final document = _controller.document;
    final result = edit(
      document,
      _coreBridge.currentOffsetStateSnapshot(document: document),
    );
    if (!result.changed) {
      return;
    }
    _coreBridge.applyTextCommandResult(result);
  }

  void _applyLineEdit(
    TextCommandResult Function(
      TextDocument document,
      TextLineStateSnapshot state,
    )
    edit,
  ) {
    final document = _controller.document;
    final result = edit(document, _coreBridge.currentLineStateSnapshot());
    if (!result.changed) {
      return;
    }
    _coreBridge.applyTextCommandResult(result);
  }

  Widget _buildSearchBar(Theme theme, int width) {
    final editorTheme = theme.editorTheme;
    final query = _searchController.text;
    final statusText = switch ((query.isEmpty, _searchMatches.isEmpty)) {
      (true, _) => 'Type to search',
      (false, true) => 'No matches',
      _ => '${_activeSearchMatchIndex + 1}/${_searchMatches.length} matches',
    };
    final statusStyle = theme.labelSmall.copy().foreground(
      theme.resolvedOnSurfaceVariant,
    );
    final searchFieldWidth = math.max(18, (width > 0 ? width : 72) - 24);
    final searchField = TextField(
      controller: _searchController,
      focusController: _focusController,
      focusId: _searchFocusId,
      width: searchFieldWidth,
      placeholder: 'Find in document',
      onChanged: (_) {
        _refreshSearchMatches(jumpToFirst: true, forceDecorationSync: true);
        setState(() {});
      },
    );
    final searchLabel = Text('Find', style: theme.labelMedium);
    final statusLabel = Text(statusText, style: statusStyle);
    final searchHint = Text(
      'enter next  shift+enter prev  esc close',
      style: statusStyle,
    );

    final content = width >= 72
        ? Column(
            gap: 1,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                gap: 2,
                children: [
                  searchLabel,
                  Expanded(child: searchField),
                  statusLabel,
                ],
              ),
              searchHint,
            ],
          )
        : Column(
            gap: 1,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [searchLabel, searchField, statusLabel, searchHint],
          );

    return Frame(
      background: editorTheme?.utilityBackground ?? theme.background,
      border: Border.normal,
      borderColor: _isSearchFocused
          ? (editorTheme?.activeShellBorderColor ?? theme.primary)
          : (editorTheme?.utilityBorderColor ?? theme.resolvedOutline),
      padding: const EdgeInsets.all(1),
      child: content,
    );
  }

  Widget _buildGotoBar(Theme theme, int width) {
    final editorTheme = theme.editorTheme;
    final totalLines = _controller.document.lineCount;
    final requested = int.tryParse(_gotoController.text.trim());
    final statusText = switch (requested) {
      null => 'Enter a line number',
      final line when line < 1 => 'Line number must be at least 1',
      final line when line > totalLines => 'Clamped to $totalLines',
      final line => 'Line $line of $totalLines',
    };
    final statusStyle = theme.labelSmall.copy().foreground(
      theme.resolvedOnSurfaceVariant,
    );
    final gotoFieldWidth = math.max(12, (width > 0 ? width : 72) - 28);
    final gotoField = TextField(
      controller: _gotoController,
      focusController: _focusController,
      focusId: _gotoFocusId,
      width: gotoFieldWidth,
      placeholder: 'Line number',
      onChanged: (_) {
        _applyGotoLine();
        setState(() {});
      },
    );
    final gotoLabel = Text('Go to line', style: theme.labelMedium);
    final statusLabel = Text(statusText, style: statusStyle);
    final gotoHint = Text('enter apply  esc close', style: statusStyle);

    final content = width >= 72
        ? Column(
            gap: 1,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                gap: 2,
                children: [
                  gotoLabel,
                  Expanded(child: gotoField),
                  statusLabel,
                ],
              ),
              gotoHint,
            ],
          )
        : Column(
            gap: 1,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [gotoLabel, gotoField, statusLabel, gotoHint],
          );

    return Frame(
      background: editorTheme?.utilityBackground ?? theme.background,
      border: Border.normal,
      borderColor: _isGotoFocused
          ? (editorTheme?.activeShellBorderColor ?? theme.primary)
          : (editorTheme?.utilityBorderColor ?? theme.resolvedOutline),
      padding: const EdgeInsets.all(1),
      child: content,
    );
  }

  Widget _buildChromeBand(
    Theme theme, {
    required bool active,
    required Widget child,
  }) {
    final editorTheme = theme.editorTheme;
    return Frame(
      background: active
          ? (editorTheme?.utilityBackground ?? theme.surface)
          : (editorTheme?.inactiveShellBackground ?? theme.surface),
      border: Border.normal,
      borderColor: active
          ? (editorTheme?.utilityBorderColor ?? theme.resolvedOutline)
          : (editorTheme?.inactiveShellBorderColor ?? theme.border),
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final width = MediaQuery.of(context).size.width.round();
    final bodyController = _controller;
    final editorTheme = theme.editorTheme;
    final baseBodyStyles = widget.styles ?? textAreaStylesFromTheme(theme);
    final bodyStyles = _isUtilityFocused
        ? baseBodyStyles.copyWith(blurred: baseBodyStyles.focused)
        : baseBodyStyles;
    final isEditorActive =
        _focusController.isFocused(_focusId) || _isUtilityFocused;
    final keyMap = widget.keyMap ?? bodyController.model.keyMap;
    final helpKeyMap = _TextEditorHelpKeyMap(
      keyMap,
      saveBinding: widget.onSave == null ? null : _saveBinding,
      searchBinding: _searchBinding,
      gotoBinding: _gotoBinding,
      searchNextBinding: _searchNextBinding,
      searchPreviousBinding: _searchPreviousBinding,
      searchCloseBinding: _searchCloseBinding,
      nextDiagnosticBinding: _hasDiagnostics ? _nextDiagnosticBinding : null,
      previousDiagnosticBinding: _hasDiagnostics
          ? _previousDiagnosticBinding
          : null,
      gotoApplyBinding: _gotoApplyBinding,
      gotoCloseBinding: _gotoCloseBinding,
      searchActive: _searchVisible,
      gotoActive: _gotoVisible,
      indentBinding: _indentBinding,
      outdentBinding: _outdentBinding,
      joinLinesBinding: _joinLinesBinding,
      splitLineBinding: _splitLineBinding,
      extraBindings: [
        _uppercaseTransformBinding,
        _lowercaseTransformBinding,
        _capitalizeTransformBinding,
        _deleteLineBinding,
        _duplicateLineBinding,
        _duplicateLineAboveBinding,
        _duplicateLineBelowBinding,
        _moveLineUpBinding,
        _moveLineDownBinding,
        _sortLinesBinding,
        _quoteLinesBinding,
        _bulletListBinding,
        _checklistBinding,
        _numberedListBinding,
        _toggleChecklistStateBinding,
        _renumberListBinding,
        _headingBinding,
        _cleanupBinding,
        _unwrapSelectionBinding,
        ...widget.extraHelpBindings,
      ],
    );
    final statsStyle = copyStyle(theme.labelSmall)
      ..foreground(
        isEditorActive
            ? (editorTheme?.metaForeground ?? theme.resolvedOnSurfaceVariant)
            : (editorTheme?.inactiveMetaForeground ?? theme.muted),
      );
    final statusStyle = copyStyle(theme.labelSmall)
      ..foreground(
        _isDirty
            ? theme.warning
            : (isEditorActive
                  ? (editorTheme?.metaForeground ??
                        theme.resolvedOnSurfaceVariant)
                  : (editorTheme?.inactiveMetaForeground ?? theme.muted)),
      );
    final activeDiagnostic = bodyController.activeDiagnostic;
    final diagnosticStyle = activeDiagnostic == null
        ? null
        : (copyStyle(theme.labelSmall)
            ..foreground(_diagnosticColor(theme, activeDiagnostic.severity)));
    final titleStyle = copyStyle(theme.titleMedium)
      ..foreground(
        isEditorActive
            ? (editorTheme?.titleForeground ?? theme.onSurface)
            : (editorTheme?.inactiveTitleForeground ??
                  theme.resolvedOnSurfaceVariant),
      );
    final shellBorderColor = isEditorActive
        ? (editorTheme?.activeShellBorderColor ?? theme.primary)
        : (editorTheme?.inactiveShellBorderColor ?? theme.resolvedOutline);
    final shellBackground = isEditorActive
        ? (editorTheme?.shellBackground ?? theme.resolvedSurfaceVariant)
        : (editorTheme?.inactiveShellBackground ?? theme.surface);

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.title, style: titleStyle),
        Row(
          gap: 2,
          children: [
            if (widget.showSaveStatus && widget.onSave != null)
              Text(
                _isDirty ? widget.dirtyLabel : widget.cleanLabel,
                style: statusStyle,
              ),
            Text(
              'Ln ${bodyController.line + 1}, Col ${bodyController.column + 1}',
              style: statsStyle,
            ),
            Text(
              '${bodyController.text.runes.length} chars',
              style: statsStyle,
            ),
            if (widget.headerTrailing != null) widget.headerTrailing!,
          ],
        ),
      ],
    );

    final diagnosticBanner = activeDiagnostic == null
        ? null
        : Text(
            textDiagnosticSummaryLabel(
              text: _controller.text,
              diagnostic: activeDiagnostic,
            ),
            style: diagnosticStyle,
            softWrap: true,
          );

    final editorBody = FocusScope(
      controller: _focusController,
      child: Frame(
        background: isEditorActive
            ? (editorTheme?.bodyBackground ?? theme.background)
            : (editorTheme?.inactiveBodyBackground ?? theme.background),
        border: Border.normal,
        borderColor: isEditorActive
            ? (editorTheme?.activeBodyBorderColor ?? theme.resolvedOutline)
            : (editorTheme?.inactiveBodyBorderColor ?? theme.border),
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: TextArea(
          controller: bodyController,
          focusController: _focusController,
          focusId: _focusId,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          prompt: widget.prompt,
          placeholder: widget.placeholder,
          width: widget.width,
          height: widget.height,
          showLineNumbers: widget.showLineNumbers,
          softWrap: widget.softWrap,
          useVirtualCursor: widget.useVirtualCursor,
          keyMap: widget.keyMap,
          styles: bodyStyles,
          cursor: widget.cursor,
          onChanged: widget.onChanged,
        ),
      ),
    );
    final headerBandChildren = <Widget>[header, ?diagnosticBanner];

    final children = <Widget>[
      _buildChromeBand(
        theme,
        active: isEditorActive,
        child: Column(
          gap: 1,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: headerBandChildren,
        ),
      ),
      editorBody,
    ];

    if (_searchVisible) {
      children.add(_buildSearchBar(theme, width));
    }
    if (_gotoVisible) {
      children.add(_buildGotoBar(theme, width));
    }

    final lowerBandChildren = <Widget>[
      if (widget.showHelpBar)
        HelpView(
          keyMap: helpKeyMap,
          showAll: widget.helpExpanded,
          itemSpacing: 2,
          columnGap: 4,
        ),
      if (widget.footer != null) widget.footer!,
    ];

    if (lowerBandChildren.isNotEmpty) {
      children.add(
        _buildChromeBand(
          theme,
          active: isEditorActive,
          child: Column(
            gap: 1,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: lowerBandChildren,
          ),
        ),
      );
    }

    return KeyboardListener(
      onKey: _handleEditorKey,
      child: Frame(
        background: shellBackground,
        border: Border.rounded,
        borderColor: shellBorderColor,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          gap: 1,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _TextEditorHelpKeyMap implements KeyMap {
  _TextEditorHelpKeyMap(
    this.base, {
    this.saveBinding,
    this.searchBinding,
    this.gotoBinding,
    this.searchNextBinding,
    this.searchPreviousBinding,
    this.searchCloseBinding,
    this.nextDiagnosticBinding,
    this.previousDiagnosticBinding,
    this.gotoApplyBinding,
    this.gotoCloseBinding,
    this.searchActive = false,
    this.gotoActive = false,
    this.indentBinding,
    this.outdentBinding,
    this.joinLinesBinding,
    this.splitLineBinding,
    this.extraBindings = const [],
  });

  final KeyMap base;
  final KeyBinding? saveBinding;
  final KeyBinding? searchBinding;
  final KeyBinding? gotoBinding;
  final KeyBinding? searchNextBinding;
  final KeyBinding? searchPreviousBinding;
  final KeyBinding? searchCloseBinding;
  final KeyBinding? nextDiagnosticBinding;
  final KeyBinding? previousDiagnosticBinding;
  final KeyBinding? gotoApplyBinding;
  final KeyBinding? gotoCloseBinding;
  final bool searchActive;
  final bool gotoActive;
  final KeyBinding? indentBinding;
  final KeyBinding? outdentBinding;
  final KeyBinding? joinLinesBinding;
  final KeyBinding? splitLineBinding;
  final List<KeyBinding> extraBindings;

  @override
  List<KeyBinding> shortHelp() {
    if (base is! TextAreaKeyMap) {
      final bindings = base.shortHelp();
      return [
        ?saveBinding,
        ?searchBinding,
        ?gotoBinding,
        if (searchActive && searchNextBinding != null) searchNextBinding!,
        if (searchActive && searchPreviousBinding != null)
          searchPreviousBinding!,
        if (searchActive && searchCloseBinding != null) searchCloseBinding!,
        ?nextDiagnosticBinding,
        ?previousDiagnosticBinding,
        if (gotoActive && gotoApplyBinding != null) gotoApplyBinding!,
        if (gotoActive && gotoCloseBinding != null) gotoCloseBinding!,
        ?indentBinding,
        ?outdentBinding,
        ?joinLinesBinding,
        ?splitLineBinding,
        ...extraBindings,
        ...bindings,
      ];
    }

    final textAreaKeyMap = base as TextAreaKeyMap;
    return [
      ?saveBinding,
      ?searchBinding,
      ?gotoBinding,
      if (searchActive && searchNextBinding != null) searchNextBinding!,
      if (searchActive && searchPreviousBinding != null) searchPreviousBinding!,
      if (searchActive && searchCloseBinding != null) searchCloseBinding!,
      ?nextDiagnosticBinding,
      ?previousDiagnosticBinding,
      if (gotoActive && gotoApplyBinding != null) gotoApplyBinding!,
      if (gotoActive && gotoCloseBinding != null) gotoCloseBinding!,
      ?indentBinding,
      ?outdentBinding,
      ?joinLinesBinding,
      ?splitLineBinding,
      ...extraBindings,
      textAreaKeyMap.selectAll,
      textAreaKeyMap.selectLine,
      textAreaKeyMap.undo,
      textAreaKeyMap.redo,
      textAreaKeyMap.insertNewline,
      textAreaKeyMap.wordBackward,
      textAreaKeyMap.wordForward,
      textAreaKeyMap.linePrevious,
      textAreaKeyMap.lineNext,
    ];
  }

  @override
  List<List<KeyBinding>> fullHelp() {
    final groups = [...base.fullHelp()];
    final editorBindings = <KeyBinding>[
      ?saveBinding,
      ?searchBinding,
      ?gotoBinding,
      if (searchActive && searchNextBinding != null) searchNextBinding!,
      if (searchActive && searchPreviousBinding != null) searchPreviousBinding!,
      if (searchActive && searchCloseBinding != null) searchCloseBinding!,
      ?nextDiagnosticBinding,
      ?previousDiagnosticBinding,
      if (gotoActive && gotoApplyBinding != null) gotoApplyBinding!,
      if (gotoActive && gotoCloseBinding != null) gotoCloseBinding!,
      ?indentBinding,
      ?outdentBinding,
      ?joinLinesBinding,
      ?splitLineBinding,
      ...extraBindings,
    ];
    if (editorBindings.isNotEmpty) {
      groups.insert(0, editorBindings);
    }
    return groups;
  }
}
