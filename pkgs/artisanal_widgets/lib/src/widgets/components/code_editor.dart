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
  static const Map<String, String> _autoPairs = {
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
    "'": "'",
    '`': '`',
  };
  static const Map<String, String> _closingToOpening = {
    ')': '(',
    ']': '[',
    '}': '{',
    '"': '"',
    "'": "'",
    '`': '`',
  };
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

  String get _lineCommentPrefix {
    final language = (widget.language ?? '').toLowerCase();
    return switch (language) {
      'python' ||
      'py' ||
      'ruby' ||
      'rb' ||
      'shell' ||
      'sh' ||
      'bash' ||
      'zsh' ||
      'yaml' ||
      'yml' ||
      'toml' ||
      'make' ||
      'makefile' => '#',
      'sql' || 'lua' || 'haskell' || 'hs' => '--',
      _ => '//',
    };
  }

  ({String start, String end})? get _blockCommentDelimiters {
    final language = (widget.language ?? '').toLowerCase();
    return switch (language) {
      'python' ||
      'py' ||
      'yaml' ||
      'yml' ||
      'toml' ||
      'make' ||
      'makefile' => null,
      'html' ||
      'xml' ||
      'svg' ||
      'markdown' ||
      'md' ||
      'mdx' => (start: '<!--', end: '-->'),
      _ => (start: '/*', end: '*/'),
    };
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
    if (!_closingToOpening.containsKey(typed)) {
      return false;
    }

    final text = _controller.text;
    final lines = text.split('\n');
    if (lines.isEmpty) {
      return false;
    }

    final lineIndex = _controller.line.clamp(0, lines.length - 1);
    final line = lines[lineIndex];
    final cursorColumn = _controller.column.clamp(0, line.length);
    final beforeCursor = line.substring(0, cursorColumn);
    if (beforeCursor.trim().isNotEmpty || line.trim().isNotEmpty) {
      return false;
    }

    final nextIndent = _outdentedIndent(beforeCursor, indentWidth);
    lines[lineIndex] = '$nextIndent$typed';
    final nextText = lines.join('\n');

    _controller.pushHistoryBoundary();
    _controller.text = nextText;
    _controller.setCursor(lineIndex, nextIndent.length + typed.length);
    _controller.pushHistoryBoundary();
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

    final text = _controller.text;
    final offset = _currentCursorOffset();
    if (offset <= 0 || offset >= text.length) {
      return false;
    }

    final before = text[offset - 1];
    final after = text[offset];
    final expectedOpening = _closingToOpening[after];
    if (expectedOpening == null || before != expectedOpening) {
      return false;
    }

    final nextText = text.replaceRange(offset - 1, offset + 1, '');
    final nextCursor = _offsetToPoint(nextText, offset - 1);
    _controller.pushHistoryBoundary();
    _controller.text = nextText;
    _controller.setCursor(nextCursor.line, nextCursor.column);
    _controller.pushHistoryBoundary();
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
    final matching = _autoPairs[typed];
    if (matching != null) {
      return _insertAutoPair(typed, matching);
    }

    if (!_autoPairs.containsValue(typed) || _controller.hasSelection) {
      return false;
    }

    final offset = _currentCursorOffset();
    final text = _controller.text;
    if (offset < text.length && text[offset] == typed) {
      final nextPoint = _offsetToPoint(text, offset + 1);
      _controller.setCursor(nextPoint.line, nextPoint.column);
      return true;
    }
    return false;
  }

  bool _insertAutoPair(String opening, String closing) {
    final text = _controller.text;
    final lines = text.split('\n');
    final offset = _currentCursorOffset();
    if (opening == closing &&
        !_shouldAutoPairSymmetricDelimiter(text, offset, opening)) {
      return false;
    }

    final selectionBase = _controller.selectionBase;
    final selectionExtent = _controller.selectionExtent;
    final hasSelection =
        _controller.hasSelection &&
        selectionBase != null &&
        selectionExtent != null;

    var startOffset = offset;
    var endOffset = offset;
    if (hasSelection) {
      startOffset = _pointToOffset(lines, selectionBase);
      endOffset = _pointToOffset(lines, selectionExtent);
      if (startOffset > endOffset) {
        final tmp = startOffset;
        startOffset = endOffset;
        endOffset = tmp;
      }
    }

    final selected = text.substring(startOffset, endOffset);
    final inserted = '$opening$selected$closing';
    final nextText = text.replaceRange(startOffset, endOffset, inserted);

    _controller.pushHistoryBoundary();
    _controller.text = nextText;
    if (hasSelection) {
      final nextBase = _offsetToPoint(nextText, startOffset + 1);
      final nextExtent = _offsetToPoint(
        nextText,
        startOffset + 1 + selected.length,
      );
      _controller.setSelection(
        baseLine: nextBase.line,
        baseColumn: nextBase.column,
        extentLine: nextExtent.line,
        extentColumn: nextExtent.column,
      );
    } else {
      final nextCursor = _offsetToPoint(nextText, startOffset + 1);
      _controller.setCursor(nextCursor.line, nextCursor.column);
    }
    _controller.pushHistoryBoundary();
    return true;
  }

  void _insertIndentedNewline({required int indentWidth}) {
    final text = _controller.text;
    final lines = text.split('\n');
    if (lines.isEmpty) {
      _controller.pushHistoryBoundary();
      _controller.text = '\n';
      _controller.setCursor(1, 0);
      _controller.pushHistoryBoundary();
      return;
    }

    final cursorLine = _controller.line.clamp(0, lines.length - 1);
    final cursorColumn = _controller.column.clamp(0, lines[cursorLine].length);
    final currentLine = lines[cursorLine];
    final beforeCursor = currentLine.substring(0, cursorColumn);
    final afterCursor = currentLine.substring(cursorColumn);
    final baseIndent = _leadingIndent(currentLine);
    final trimmedBefore = beforeCursor.trimRight();
    var nextIndent = baseIndent;
    if (_shouldIncreaseIndentAfter(trimmedBefore)) {
      nextIndent += ' ' * indentWidth;
    }

    final selectionBase = _controller.selectionBase;
    final selectionExtent = _controller.selectionExtent;
    final hasSelection =
        _controller.hasSelection &&
        selectionBase != null &&
        selectionExtent != null;
    final selectionStartPoint = hasSelection
        ? selectionBase
        : (line: cursorLine, column: cursorColumn);
    final selectionEndPoint = hasSelection
        ? selectionExtent
        : (line: cursorLine, column: cursorColumn);
    var startOffset = _pointToOffset(lines, selectionStartPoint);
    var endOffset = _pointToOffset(lines, selectionEndPoint);
    if (startOffset > endOffset) {
      final tmp = startOffset;
      startOffset = endOffset;
      endOffset = tmp;
    }

    final cursorInsertion = '\n$nextIndent';
    var insertion = cursorInsertion;
    if (!hasSelection) {
      final blockSuffix = _blockNewlineSuffix(
        beforeCursor: trimmedBefore,
        afterCursor: afterCursor,
        baseIndent: baseIndent,
      );
      if (blockSuffix != null) {
        insertion += blockSuffix.text;
        endOffset += blockSuffix.consumedColumns;
      }
    }
    final nextText = text.replaceRange(startOffset, endOffset, insertion);
    final nextCursor = _offsetToPoint(
      nextText,
      startOffset + cursorInsertion.length,
    );

    _controller.pushHistoryBoundary();
    _controller.text = nextText;
    _controller.setCursor(nextCursor.line, nextCursor.column);
    _controller.pushHistoryBoundary();
  }

  void _toggleBlockComments() {
    final delimiters = _blockCommentDelimiters;
    if (delimiters == null) {
      return;
    }

    final text = _controller.text;
    if (text.isEmpty) {
      return;
    }

    final lines = text.split('\n');
    final selectionBase = _controller.selectionBase;
    final selectionExtent = _controller.selectionExtent;
    final hasSelection =
        _controller.hasSelection &&
        selectionBase != null &&
        selectionExtent != null;

    final startOffset = hasSelection
        ? math.min(
            _pointToOffset(lines, selectionBase),
            _pointToOffset(lines, selectionExtent),
          )
        : _lineStartOffset(lines, _controller.line.clamp(0, lines.length - 1));
    final endOffset = hasSelection
        ? math.max(
            _pointToOffset(lines, selectionBase),
            _pointToOffset(lines, selectionExtent),
          )
        : startOffset +
              lines[_controller.line.clamp(0, lines.length - 1)].length;

    final toggled = _toggleDelimitedSegment(
      text.substring(startOffset, endOffset),
      startDelimiter: delimiters.start,
      endDelimiter: delimiters.end,
    );
    final nextText = text.replaceRange(startOffset, endOffset, toggled.text);

    _controller.pushHistoryBoundary();
    _controller.text = nextText;

    if (hasSelection) {
      final nextStart = _offsetToPoint(
        nextText,
        startOffset + toggled.selectionStart,
      );
      final nextEnd = _offsetToPoint(
        nextText,
        startOffset + toggled.selectionEnd,
      );
      _controller.setSelection(
        baseLine: nextStart.line,
        baseColumn: nextStart.column,
        extentLine: nextEnd.line,
        extentColumn: nextEnd.column,
      );
    } else {
      final cursor = _offsetToPoint(
        nextText,
        startOffset + toggled.selectionEnd,
      );
      _controller.setCursor(cursor.line, cursor.column);
    }

    _controller.pushHistoryBoundary();
  }

  void _toggleLineComments() {
    _controller.toggleLinePrefix(_lineCommentPrefix);
  }

  int _pointToOffset(List<String> lines, ({int line, int column}) point) {
    var offset = 0;
    final clampedLine = point.line.clamp(0, lines.length - 1);
    for (var index = 0; index < clampedLine; index++) {
      offset += lines[index].length + 1;
    }
    return offset + point.column.clamp(0, lines[clampedLine].length);
  }

  int _lineStartOffset(List<String> lines, int line) {
    var offset = 0;
    final clampedLine = line.clamp(0, lines.length - 1);
    for (var index = 0; index < clampedLine; index++) {
      offset += lines[index].length + 1;
    }
    return offset;
  }

  ({int line, int column}) _offsetToPoint(String text, int offset) {
    final clampedOffset = offset.clamp(0, text.length);
    var line = 0;
    var column = 0;
    for (var index = 0; index < clampedOffset; index++) {
      if (text.codeUnitAt(index) == 0x0a) {
        line++;
        column = 0;
      } else {
        column++;
      }
    }
    return (line: line, column: column);
  }

  ({String text, int selectionStart, int selectionEnd}) _toggleDelimitedSegment(
    String segment, {
    required String startDelimiter,
    required String endDelimiter,
  }) {
    final leadingWhitespace = segment.length - segment.trimLeft().length;
    final trailingWhitespace = segment.length - segment.trimRight().length;
    final coreEnd = segment.length - trailingWhitespace;
    final core = segment.substring(leadingWhitespace, coreEnd);

    if (core.startsWith(startDelimiter) && core.endsWith(endDelimiter)) {
      var innerStart = leadingWhitespace + startDelimiter.length;
      var innerEnd = coreEnd - endDelimiter.length;
      if (innerStart < innerEnd && segment.codeUnitAt(innerStart) == 0x20) {
        innerStart++;
      }
      if (innerStart < innerEnd && segment.codeUnitAt(innerEnd - 1) == 0x20) {
        innerEnd--;
      }
      final uncommented =
          segment.substring(0, leadingWhitespace) +
          segment.substring(innerStart, innerEnd) +
          segment.substring(coreEnd);
      return (
        text: uncommented,
        selectionStart: leadingWhitespace,
        selectionEnd: leadingWhitespace + (innerEnd - innerStart),
      );
    }

    final separator = core.isEmpty ? '' : ' ';
    final commented =
        segment.substring(0, leadingWhitespace) +
        startDelimiter +
        separator +
        core +
        separator +
        endDelimiter +
        segment.substring(coreEnd);
    return (
      text: commented,
      selectionStart: leadingWhitespace,
      selectionEnd:
          leadingWhitespace +
          startDelimiter.length +
          separator.length +
          core.length +
          separator.length +
          endDelimiter.length,
    );
  }

  String _leadingIndent(String line) {
    final buffer = StringBuffer();
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      if (char != ' ' && char != '\t') {
        break;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  bool _shouldIncreaseIndentAfter(String prefix) {
    if (prefix.isEmpty) {
      return false;
    }
    final last = prefix[prefix.length - 1];
    if (last == '{' || last == '[' || last == '(') {
      return true;
    }
    final language = (widget.language ?? '').toLowerCase();
    if ((language == 'python' ||
            language == 'py' ||
            language == 'yaml' ||
            language == 'yml') &&
        last == ':') {
      return true;
    }
    return false;
  }

  ({String text, int consumedColumns})? _blockNewlineSuffix({
    required String beforeCursor,
    required String afterCursor,
    required String baseIndent,
  }) {
    if (beforeCursor.isEmpty || afterCursor.isEmpty) {
      return null;
    }

    final opening = beforeCursor[beforeCursor.length - 1];
    final expectedClosing = switch (opening) {
      '{' => '}',
      '[' => ']',
      '(' => ')',
      _ => null,
    };
    if (expectedClosing == null) {
      return null;
    }

    final leadingWhitespace =
        afterCursor.length - afterCursor.trimLeft().length;
    if (leadingWhitespace >= afterCursor.length) {
      return null;
    }

    if (afterCursor[leadingWhitespace] != expectedClosing) {
      return null;
    }

    return (text: '\n$baseIndent', consumedColumns: leadingWhitespace);
  }

  int _currentCursorOffset() {
    final lines = _controller.text.split('\n');
    if (lines.isEmpty) {
      return 0;
    }
    return _pointToOffset(lines, (
      line: _controller.line.clamp(0, lines.length - 1),
      column: _controller.column.clamp(
        0,
        lines[_controller.line.clamp(0, lines.length - 1)].length,
      ),
    ));
  }

  bool _shouldAutoPairSymmetricDelimiter(
    String text,
    int offset,
    String delimiter,
  ) {
    if (_controller.hasSelection) {
      return true;
    }
    final before = offset > 0 ? text[offset - 1] : '';
    final after = offset < text.length ? text[offset] : '';
    final beforeBlocksPair =
        before.isNotEmpty && RegExp(r'[\w\\]').hasMatch(before);
    if (beforeBlocksPair) {
      return false;
    }
    return after.isEmpty || RegExp(r'[\s\]\)\}\>,.;:]').hasMatch(after);
  }

  String _outdentedIndent(String indent, int width) {
    if (indent.isEmpty) {
      return indent;
    }
    if (indent.endsWith('\t')) {
      return indent.substring(0, indent.length - 1);
    }
    final removeCount = math.min(width, indent.length);
    final trailing = indent.substring(indent.length - removeCount);
    if (trailing.runes.every((rune) => rune == 0x20)) {
      return indent.substring(0, indent.length - removeCount);
    }
    final lastSpace = indent.lastIndexOf(' ');
    if (lastSpace >= 0) {
      return indent.substring(0, lastSpace);
    }
    return '';
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
            if (_blockCommentDelimiters != null) _toggleBlockCommentBinding,
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
