import 'package:artisanal/bubbles.dart'
    show
        CodeLanguageProfile,
        CursorModel,
        TextAreaKeyMap,
        TextAreaModel,
        TextAreaStyles,
        TextDecorationRange,
        TextSyntaxBuildResult,
        TextSyntaxDecorationPatch,
        TextSyntaxSession,
        TextSyntaxSnapshot,
        TextSyntaxProvider,
        TextDocument,
        TextDocumentChange,
        keyMatchesSingle,
        codeHandleClosingDelimiterAlignment,
        codeHandlePairBackspace,
        codeHandleAutoPair,
        codeInsertIndentedNewline,
        codeToggleBlockComments,
        resolveCodeLanguageProfile,
        textSyntaxChangeWindow,
        textSyntaxDecorationLayerKey,
        textSyntaxDecorationLayerPriority;
import 'package:artisanal/artisanal.dart'
    show
        AdaptiveChromaTheme,
        ChromaTheme,
        SyntaxHighlighter,
        highlightCodeString;
import 'package:artisanal/style.dart' show Border, Style;
import 'package:artisanal/style.dart';
import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart' show Cmd, KeyMsg, KeyBinding;
import 'package:artisanal_widgets/widgets.dart';

import 'text_area_controller_core_bridge.dart'
    show TextAreaControllerCoreBridge;

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
  late final TextDecorationLayerBinding _syntaxDecorationBinding;
  late final TextSyntaxSession<void> _syntaxSession;
  TextAreaController get _controller =>
      widget.controller ??
      (_internalController ??= TextAreaController(model: widget.model));
  TextAreaControllerCoreBridge get _coreBridge =>
      TextAreaControllerCoreBridge(_controller);

  @override
  void initState() {
    super.initState();
    _syntaxSession = TextSyntaxSession<void>(
      provider: _CodeEditorSyntaxProvider(),
    );
    _syntaxDecorationBinding = TextDecorationLayerBinding(
      controller: _controller,
      layerKey: textSyntaxDecorationLayerKey,
      buildDecorations: _buildSyntaxDecorations,
      priority: textSyntaxDecorationLayerPriority,
      syncImmediately: false,
    );
    _controller.addListener(_handleControllerChanged);
    _syntaxDecorationBinding.sync(force: true);
  }

  @override
  Cmd? didUpdateWidget(covariant CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final oldController = oldWidget.controller ?? _internalController;
      oldController?.removeListener(_handleControllerChanged);
      if (!identical(oldController, _controller)) {
        oldController?.clearDecorationLayer(textSyntaxDecorationLayerKey);
      }
      _syntaxDecorationBinding.controller = _controller;
      _controller.addListener(_handleControllerChanged);
    }
    if (oldWidget.model != widget.model && widget.model != null) {
      _controller.model = widget.model!;
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.model != widget.model ||
        oldWidget.language != widget.language) {
      _syntaxSession.clear();
      _syntaxDecorationBinding.sync(force: true);
    }
    return null;
  }

  @override
  void dispose() {
    final controller = widget.controller ?? _internalController;
    controller?.removeListener(_handleControllerChanged);
    _syntaxDecorationBinding.clear();
    _syntaxDecorationBinding.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    _syntaxDecorationBinding.sync();
    setState(() {});
  }

  CodeLanguageProfile get _languageProfile =>
      resolveCodeLanguageProfile(widget.language);

  ChromaTheme _resolvedSyntaxTheme() {
    if (widget.syntaxTheme != null) {
      return widget.syntaxTheme!;
    }

    return (widget.adaptiveSyntaxTheme ?? AdaptiveChromaTheme.draculaGithub)
        .resolve(hasDarkBackground: hasDarkBackground);
  }

  TextAreaStyles _resolvedEditorStyles(Theme theme) {
    final baseStyles = widget.styles ?? textAreaStylesFromTheme(theme);
    final syntaxDecorationStyles = SyntaxHighlighter(
      theme: _resolvedSyntaxTheme(),
    ).decorationStyles();
    if (syntaxDecorationStyles.isEmpty) {
      return baseStyles;
    }

    return baseStyles.copyWith(
      focused: baseStyles.focused.copyWith(
        decorationStyles: <String, Style>{
          ...baseStyles.focused.decorationStyles,
          ...syntaxDecorationStyles,
        },
      ),
      blurred: baseStyles.blurred.copyWith(
        decorationStyles: <String, Style>{
          ...baseStyles.blurred.decorationStyles,
          ...syntaxDecorationStyles,
        },
      ),
    );
  }

  List<TextDecorationRange> _buildSyntaxDecorations(String _) {
    return _syntaxSession
        .syncDocument(
          _controller.document,
          language: widget.language,
          change: _controller.consumeLastDocumentChange(),
        )
        .decorations;
  }

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
    final document = _controller.document;
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

    final document = _controller.document;
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
    final document = _controller.document;
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
    final document = _controller.document;
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

    final document = _controller.document;
    if (document.length == 0) {
      return;
    }

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

    final resolvedTheme = _resolvedSyntaxTheme();
    return highlightCodeString(
      text,
      language: widget.language,
      theme: resolvedTheme,
    );
  }

  Widget _buildPreviewPane(Theme theme, String previewTitle) {
    final editorTheme = theme.editorTheme;
    final titleStyle = copyStyle(theme.titleSmall)
      ..foreground(
        editorTheme?.inactiveTitleForeground ?? theme.resolvedOnSurfaceVariant,
      );

    return Frame(
      background: editorTheme?.inactiveShellBackground ?? theme.surface,
      border: Border.rounded,
      borderColor: editorTheme?.inactiveShellBorderColor ?? theme.border,
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        gap: 1,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Frame(
            background: editorTheme?.utilityBackground ?? theme.surface,
            border: Border.normal,
            borderColor:
                editorTheme?.utilityBorderColor ?? theme.resolvedOutline,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(previewTitle, style: titleStyle),
          ),
          Frame(
            background: editorTheme?.inactiveBodyBackground ?? theme.background,
            border: Border.normal,
            borderColor: editorTheme?.inactiveBodyBorderColor ?? theme.border,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: ScrollArea(
              controller: widget.previewController,
              height: widget.previewHeight,
              showScrollbar: widget.showPreviewScrollbar,
              child: Text(_highlightedPreview(), softWrap: widget.previewWrap),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
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
          styles: _resolvedEditorStyles(theme),
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
        if (widget.showPreview) _buildPreviewPane(theme, previewTitle),
      ],
    );
  }
}

final class _CodeEditorSyntaxProvider implements TextSyntaxProvider<void> {
  _CodeEditorSyntaxProvider({SyntaxHighlighter? highlighter})
    : _highlighter = highlighter ?? SyntaxHighlighter();

  final SyntaxHighlighter _highlighter;

  @override
  TextSyntaxBuildResult<void> build(
    String text, {
    TextDocument? document,
    String? language,
    TextSyntaxSnapshot<void>? previous,
    TextDocumentChange? change,
  }) {
    if (document != null) {
      return buildDocument(
        document,
        language: language,
        previous: previous,
        change: change,
      );
    }

    if (text.isEmpty) {
      return const TextSyntaxBuildResult<void>(
        decorations: <TextDecorationRange>[],
      );
    }

    return TextSyntaxBuildResult<void>(
      decorations: _highlightDecorations(text, language: language),
    );
  }

  @override
  TextSyntaxBuildResult<void> buildDocument(
    TextDocument document, {
    String? language,
    TextSyntaxSnapshot<void>? previous,
    TextDocumentChange? change,
  }) {
    if (document.length == 0) {
      return const TextSyntaxBuildResult<void>(
        decorations: <TextDecorationRange>[],
      );
    }

    final previousDocument = previous?.document;
    if (previous == null ||
        previousDocument == null ||
        change == null ||
        change.isNoop) {
      final fullText = document.textBetweenLines(
        startLine: 0,
        endLine: document.lineCount,
      );
      return TextSyntaxBuildResult<void>(
        decorations: _highlightDecorations(fullText, language: language),
      );
    }

    final window = textSyntaxChangeWindow(
      previousDocument: previousDocument,
      nextDocument: document,
      change: change,
      lookBehindLines: 1,
      lookAheadLines: 1,
    );
    final windowText = document.textBetweenLines(
      startLine: window.nextLines.startLine,
      endLine: window.nextLines.endLine,
    );
    return TextSyntaxBuildResult<void>.patch(
      patch: TextSyntaxDecorationPatch.forChangeWindow(
        previousDocument: previousDocument,
        nextDocument: document,
        window: window,
        decorations: _highlightDecorations(
          windowText,
          language: language,
          offsetBase: window.nextLines.startOffsetIn(document),
        ),
      ),
    );
  }

  List<TextDecorationRange> _highlightDecorations(
    String text, {
    String? language,
    int offsetBase = 0,
  }) {
    final spans = _highlighter.highlightSpans(text, language: language);
    return <TextDecorationRange>[
      for (final span in spans)
        TextDecorationRange(
          startOffset: span.startOffset + offsetBase,
          endOffset: span.endOffset + offsetBase,
          styleKey: span.styleKey,
        ),
    ];
  }
}
