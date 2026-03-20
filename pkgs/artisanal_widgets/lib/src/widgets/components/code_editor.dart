part of 'components_widgets.dart';

/// A higher-level code editor built on top of [TextEditor].
///
/// `CodeEditor` composes the editable surface with a syntax-highlighted
/// preview using artisanal's existing syntax highlighter.
///
/// ```dart
/// final controller = TextAreaController(
///   text: 'void main() {\n  print("hello");\n}',
/// );
///
/// CodeEditor(
///   title: 'main.dart',
///   language: 'dart',
///   controller: controller,
///   height: 8,
/// )
/// ```
class CodeEditor extends StatefulWidget {
  CodeEditor({
    this.title = 'Code',
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
    this.showSaveStatus = true,
    this.cleanLabel = 'saved',
    this.dirtyLabel = 'modified',
    this.indentWidth = 2,
    this.language = 'dart',
    this.showPreview = true,
    this.previewTitle = 'Preview',
    this.previewHeight = 8,
    this.previewWrap = true,
    this.previewController,
    this.showPreviewScrollbar = true,
    this.syntaxTheme,
    this.adaptiveSyntaxTheme,
    super.key,
  });

  final String title;
  final TextAreaController? controller;
  final TextAreaModel? model;
  final FocusController? focusController;
  final String? focusId;
  final bool autofocus;
  final bool enabled;
  final String? prompt;
  final String? placeholder;
  final int? width;
  final int height;
  final bool showLineNumbers;
  final bool softWrap;
  final bool? useVirtualCursor;
  final TextAreaKeyMap? keyMap;
  final TextAreaStyles? styles;
  final CursorModel? cursor;
  final bool showHelpBar;
  final bool helpExpanded;
  final Widget? headerTrailing;
  final Widget? footer;
  final TextChangedCallback? onChanged;
  final ValueCmdCallback<String>? onSave;
  final bool showSaveStatus;
  final String cleanLabel;
  final String dirtyLabel;
  final int indentWidth;
  final String? language;
  final bool showPreview;
  final String previewTitle;
  final int previewHeight;
  final bool previewWrap;
  final ScrollController? previewController;
  final bool showPreviewScrollbar;
  final ChromaTheme? syntaxTheme;
  final AdaptiveChromaTheme? adaptiveSyntaxTheme;

  @override
  State createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  static final KeyBinding _toggleCommentBinding = KeyBinding.withHelp(
    ['ctrl+/', 'ctrl+_'],
    'ctrl+/',
    'toggle comments',
  );
  static final KeyBinding _toggleBlockCommentBinding = KeyBinding.withHelp(
    ['alt+shift+a'],
    'alt+shift+a',
    'toggle block comment',
  );
  TextAreaController? _internalController;
  TextAreaController get _controller =>
      widget.controller ??
      (_internalController ??= TextAreaController(model: widget.model));
  _TextAreaControllerCoreBridge get _coreBridge =>
      _TextAreaControllerCoreBridge(_controller);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  Cmd? didUpdateWidget(covariant CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(
        _handleControllerChanged,
      );
      _controller.addListener(_handleControllerChanged);
    }
    if (oldWidget.model != widget.model && widget.model != null) {
      _controller.model = widget.model!;
    }
    return null;
  }

  @override
  void dispose() {
    (widget.controller ?? _internalController)?.removeListener(
      _handleControllerChanged,
    );
    _internalController?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  CodeLanguageProfile get _languageProfile =>
      resolveCodeLanguageProfile(widget.language);

  Cmd? _handleCodeEditorKey(KeyMsg msg) {
    final key = msg.key;
    final indentWidth = widget.indentWidth < 1 ? 1 : widget.indentWidth;

    if (_handlePairBackspaceKey(key)) {
      return Cmd.none();
    }

    if (_handleClosingDelimiterAlignment(key, indentWidth: indentWidth)) {
      return Cmd.none();
    }

    if (_handleAutoPairKey(key)) {
      return Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.enter &&
        !key.shift &&
        !key.ctrl &&
        !key.alt &&
        !key.meta) {
      _insertIndentedNewline(indentWidth: indentWidth);
      return Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.tab &&
        !key.ctrl &&
        !key.alt &&
        !key.meta) {
      if (key.shift) {
        _controller.outdentLines(width: indentWidth);
        return Cmd.none();
      }
      if (_controller.hasSelection) {
        _controller.indentLines(width: indentWidth);
        return Cmd.none();
      }
    }

    if (key.type == terminal_keys.KeyType.up &&
        key.alt &&
        !key.shift &&
        !key.ctrl &&
        !key.meta) {
      _controller.moveLinesUp();
      return Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.down &&
        key.alt &&
        !key.shift &&
        !key.ctrl &&
        !key.meta) {
      _controller.moveLinesDown();
      return Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.up &&
        key.alt &&
        key.shift &&
        !key.ctrl &&
        !key.meta) {
      _controller.duplicateLinesAbove();
      return Cmd.none();
    }

    if (key.type == terminal_keys.KeyType.down &&
        key.alt &&
        key.shift &&
        !key.ctrl &&
        !key.meta) {
      _controller.duplicateLinesBelow();
      return Cmd.none();
    }

    if (key.alt &&
        key.shift &&
        !key.ctrl &&
        !key.meta &&
        key.type == terminal_keys.KeyType.runes &&
        key.runes.isNotEmpty &&
        String.fromCharCode(key.runes.first).toLowerCase() == 'f') {
      _controller.cleanupWhitespace();
      return Cmd.none();
    }

    if (key.alt &&
        key.shift &&
        !key.ctrl &&
        !key.meta &&
        key.type == terminal_keys.KeyType.runes &&
        key.runes.isNotEmpty &&
        String.fromCharCode(key.runes.first).toLowerCase() == 'a') {
      _toggleBlockComments();
      return Cmd.none();
    }

    if (key.alt &&
        !key.shift &&
        !key.ctrl &&
        !key.meta &&
        key.type == terminal_keys.KeyType.runes &&
        key.runes.isNotEmpty &&
        String.fromCharCode(key.runes.first).toLowerCase() == 'j') {
      _controller.joinLines();
      return Cmd.none();
    }

    if (key.ctrl &&
        key.shift &&
        !key.alt &&
        !key.meta &&
        key.type == terminal_keys.KeyType.runes &&
        key.runes.isNotEmpty &&
        String.fromCharCode(key.runes.first).toLowerCase() == 'd') {
      _controller.duplicateLinesBelow();
      return Cmd.none();
    }

    if (key.ctrl &&
        key.shift &&
        !key.alt &&
        !key.meta &&
        key.type == terminal_keys.KeyType.runes &&
        key.runes.isNotEmpty &&
        String.fromCharCode(key.runes.first).toLowerCase() == 'k') {
      _controller.deleteLines();
      return Cmd.none();
    }

    if (!keyMatchesSingle(msg.key, _toggleCommentBinding)) {
      return null;
    }
    _toggleLineComments();
    return Cmd.none();
  }

  bool _handleClosingDelimiterAlignment(
    terminal_keys.Key key, {
    required int indentWidth,
  }) {
    if (key.ctrl ||
        key.alt ||
        key.meta ||
        key.type != terminal_keys.KeyType.runes ||
        key.runes.length != 1 ||
        _controller.hasSelection) {
      return false;
    }

    final typed = String.fromCharCode(key.runes.first);
    final document = TextDocument(text: _controller.text);
    final result = codeHandleClosingDelimiterAlignment(
      document: document,
      state: _coreBridge.currentOffsetStateSnapshot(document: document),
      profile: _languageProfile,
      typed: typed,
      indentWidth: indentWidth,
    );
    if (!result.changed) {
      return false;
    }

    _coreBridge.applyTextCommandResult(result);
    return true;
  }

  bool _handlePairBackspaceKey(terminal_keys.Key key) {
    if (key.ctrl ||
        key.alt ||
        key.meta ||
        key.shift ||
        key.type != terminal_keys.KeyType.backspace ||
        _controller.hasSelection) {
      return false;
    }

    final document = TextDocument(text: _controller.text);
    final result = codeHandlePairBackspace(
      document: document,
      state: _coreBridge.currentOffsetStateSnapshot(document: document),
      profile: _languageProfile,
    );
    if (!result.changed) {
      return false;
    }

    _coreBridge.applyTextCommandResult(result);
    return true;
  }

  bool _handleAutoPairKey(terminal_keys.Key key) {
    if (key.ctrl ||
        key.alt ||
        key.meta ||
        key.type != terminal_keys.KeyType.runes ||
        key.runes.length != 1) {
      return false;
    }

    final typed = String.fromCharCode(key.runes.first);
    final document = TextDocument(text: _controller.text);
    final result = codeHandleAutoPair(
      document: document,
      state: _coreBridge.currentOffsetStateSnapshot(document: document),
      profile: _languageProfile,
      typed: typed,
    );
    if (!result.changed) {
      return false;
    }

    _coreBridge.applyTextCommandResult(result);
    return true;
  }

  void _insertIndentedNewline({required int indentWidth}) {
    final document = TextDocument(text: _controller.text);
    final result = codeInsertIndentedNewline(
      document: document,
      state: _coreBridge.currentOffsetStateSnapshot(document: document),
      indentWidth: indentWidth,
      language: widget.language,
    );
    _coreBridge.applyTextCommandResult(result);
  }

  void _toggleBlockComments() {
    final delimiters = _languageProfile.blockCommentDelimiters;
    if (delimiters == null) {
      return;
    }

    final text = _controller.text;
    if (text.isEmpty) {
      return;
    }

    final document = TextDocument(text: text);
    final result = codeToggleBlockComments(
      document: document,
      state: _coreBridge.currentOffsetStateSnapshot(document: document),
      profile: _languageProfile,
    );
    if (!result.changed) {
      return;
    }
    _coreBridge.applyTextCommandResult(result);
  }

  void _toggleLineComments() {
    _controller.toggleLinePrefix(_languageProfile.lineCommentPrefix);
  }

  String _highlightedPreview() {
    final text = _controller.text;
    final theme = ThemeScope.of(context);
    if (text.isEmpty) {
      return theme.labelSmall
          .copy()
          .foreground(theme.muted)
          .render('No code yet.');
    }

    final resolvedTheme =
        widget.syntaxTheme ??
        (widget.adaptiveSyntaxTheme ?? AdaptiveChromaTheme.draculaGithub)
            .resolve(hasDarkBackground: hasDarkBackground);
    return highlightCodeString(
      text,
      language: widget.language,
      theme: resolvedTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewTitle = widget.language == null || widget.language!.isEmpty
        ? widget.previewTitle
        : '${widget.previewTitle} · ${widget.language}';

    return Column(
      gap: 1,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextEditor(
          title: widget.title,
          controller: _controller,
          focusController: widget.focusController,
          focusId: widget.focusId,
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
          styles: widget.styles,
          cursor: widget.cursor,
          showHelpBar: widget.showHelpBar,
          helpExpanded: widget.helpExpanded,
          headerTrailing: widget.headerTrailing,
          footer: widget.footer,
          onChanged: widget.onChanged,
          onSave: widget.onSave,
          onKey: _handleCodeEditorKey,
          extraHelpBindings: [
            _toggleCommentBinding,
            if (_languageProfile.blockCommentDelimiters != null)
              _toggleBlockCommentBinding,
          ],
          showSaveStatus: widget.showSaveStatus,
          cleanLabel: widget.cleanLabel,
          dirtyLabel: widget.dirtyLabel,
          indentWidth: widget.indentWidth,
        ),
        if (widget.showPreview)
          PanelBox(
            title: previewTitle,
            child: ScrollArea(
              controller: widget.previewController,
              height: widget.previewHeight,
              showScrollbar: widget.showPreviewScrollbar,
              child: Text(_highlightedPreview(), softWrap: widget.previewWrap),
            ),
          ),
      ],
    );
  }
}
