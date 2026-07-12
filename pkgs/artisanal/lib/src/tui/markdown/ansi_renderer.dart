/// ANSI renderer for markdown content.
///
/// Converts markdown AST to ANSI-styled terminal output using artisanal's
/// [Style] system.
///
/// ```dart
/// final markdown = '''
/// # Hello World
///
/// This is **bold** and *italic* text.
///
/// - Item 1
/// - Item 2
/// ''';
///
/// print(markdownToAnsi(markdown));
/// ```
library;

import 'dart:typed_data';

import 'package:html_unescape/html_unescape.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:markdown/markdown.dart';

import 'package:image/image.dart' as img;

import '../../style/border.dart' as style_border;
import '../../style/style.dart';
import '../../style/color.dart';
import '../../tui/bubbles/components/table.dart' as table_component;
import '../../uv/wrap.dart' as uv_wrap;
import 'backend.dart' as markdown_backend;
import 'syntax_highlighter.dart';
import 'options.dart';
import 'html_context.dart';
import 'image_renderer.dart'
    show
        ImageProtocol,
        detectImageProtocol,
        imageCellDimensions,
        renderImageToAnsi;
export 'options.dart';
export 'styles.dart' show MarkdownElementStyle;

/// Configuration options for ANSI markdown rendering.
///
/// Provides customizable styles for different markdown elements and
/// various rendering options like terminal width and hyperlink support.
// ─────────────────────────────────────────────────────────────────────────────
// Default Styles
// ─────────────────────────────────────────────────────────────────────────────

/// Default style for H1 headings.
Style _defaultH1Style() => Style().bold().foreground(Colors.brightCyan);

/// Default style for H2 headings.
Style _defaultH2Style() => Style().bold().foreground(Colors.cyan);

/// Default style for H3 headings.
Style _defaultH3Style() => Style().bold().foreground(Colors.blue);

/// Default style for H4 headings.
Style _defaultH4Style() => Style().bold();

/// Default style for H5 headings.
Style _defaultH5Style() => Style().bold().dim();

/// Default style for H6 headings.
Style _defaultH6Style() => Style().dim();

/// Default style for emphasized text.
Style _defaultEmphasisStyle() => Style().italic();

/// Default style for strong text.
Style _defaultStrongStyle() => Style().bold();

/// Default style for inline code.
Style _defaultCodeStyle() =>
    Style().foreground(Colors.brightYellow).background(Colors.gray800);

/// Default style for code blocks.
Style _defaultCodeBlockStyle() => Style().foreground(Colors.brightYellow);

/// Default style for links.
Style _defaultLinkStyle() => Style().foreground(Colors.blue).underline();

/// Default style for blockquotes.
Style _defaultBlockquoteStyle() => Style().italic().dim();

/// Default color for blockquote border.
Color _defaultBlockquoteBorderColor() => Colors.gray;

/// Default style for strikethrough.
Style _defaultStrikethroughStyle() => Style().strikethrough().dim();

// ─────────────────────────────────────────────────────────────────────────────
// Renderer
// ─────────────────────────────────────────────────────────────────────────────

/// Renders markdown AST nodes to ANSI-styled terminal output.
///
/// Implements the [NodeVisitor] interface from the markdown package to
/// traverse the AST and produce styled output.
class AnsiRenderer implements NodeVisitor {
  /// Creates an ANSI renderer with the given options.
  AnsiRenderer({AnsiRendererOptions? options})
    : options = options ?? const AnsiRendererOptions();

  /// The rendering options.
  final AnsiRendererOptions options;

  /// Pre-downloaded image bytes keyed by URL.
  ///
  /// Populated by [AnsiRenderer.loadImages] or [MarkdownRenderer.preloadImages]
  /// before rendering. When [options.renderImages] is true, [_renderImage]
  /// looks up the URL here, decodes the image, and renders it through the
  /// detected terminal graphics protocol.
  final Map<String, Uint8List> imageCache = {};

  /// Output buffer.
  final StringBuffer _buffer = StringBuffer();

  /// Stack of active elements for context tracking.
  final List<Element> _elementStack = [];

  /// Current list nesting depth.
  int _listDepth = 0;

  /// Current list item index (for ordered lists).
  final List<int> _listCounters = [];

  /// Render state for active list items.
  final List<_ListItemContext> _listItemStack = [];

  /// Whether we're inside a blockquote.
  bool _inBlockquote = false;

  /// Current blockquote nesting depth.
  int _blockquoteDepth = 0;

  /// Whether the next block inside a quote should consume a blank separator.
  bool _blockquoteBlankLinePending = false;

  /// Whether the last output was a block element (needs trailing newline).
  bool _lastWasBlock = false;

  /// Pending link URL for the current link element.
  String? _pendingLinkUrl;

  /// Render state for HTML `<details>` elements normalized by the backend.
  final List<DetailsContext> _detailsStack = [];

  // ─────────────────────────────────────────────────────────────────────────────
  // Table State
  // ─────────────────────────────────────────────────────────────────────────────

  /// Collected table header cells.
  final List<String> _tableHeaders = [];

  /// Collected table data rows.
  final List<List<String>> _tableRows = [];

  /// Collected table column alignments.
  final List<table_component.TableAlign> _tableAlignments = [];

  /// Current row being built.
  final List<String> _currentTableRow = [];

  /// Buffer for current cell content (to handle inline formatting).
  final StringBuffer _currentCellBuffer = StringBuffer();

  /// Whether we're inside the table header section.
  bool _inTableHeader = false;

  /// Whether we're inside a table cell (th or td).
  bool _inTableCell = false;

  /// Whether we're inside a code block with borders.
  bool _inCodeBlock = false;

  /// Current code block language for syntax highlighting.
  String? _codeBlockLanguage;

  /// Whether we're inside a paragraph (for text wrapping).
  bool _inParagraph = false;

  /// Buffer for collecting paragraph content (for text wrapping).
  final StringBuffer _paragraphBuffer = StringBuffer();

  /// Whether body text styling is currently active.
  bool _textStyleActive = false;

  /// Lazy-initialized syntax highlighter.
  SyntaxHighlighter? _syntaxHighlighter;

  /// HTML entity decoder for converting &lt; &gt; &amp; &quot; etc.
  final HtmlUnescape _htmlUnescape = HtmlUnescape();

  /// Gets or creates the syntax highlighter.
  ///
  /// If [options.syntaxTheme] is provided, uses that theme directly.
  /// Otherwise, uses [ChromaTheme.dark] for dark backgrounds or
  /// [ChromaTheme.light] for light backgrounds based on
  /// [options.hasDarkBackground].
  SyntaxHighlighter get _highlighter {
    if (_syntaxHighlighter != null) return _syntaxHighlighter!;

    if (options.syntaxTheme != null) {
      // Use explicitly provided theme
      _syntaxHighlighter = SyntaxHighlighter(theme: options.syntaxTheme);
    } else {
      // Auto-select theme based on background
      _syntaxHighlighter = SyntaxHighlighter.adaptive(
        hasDarkBackground: options.hasDarkBackground,
      );
    }
    return _syntaxHighlighter!;
  }

  bool _shouldSyntaxHighlight(String code, String? language) {
    if (!options.syntaxHighlighting || language == null) return false;
    final maxCodeUnits = options.maxSyntaxHighlightCodeUnits;
    return maxCodeUnits == null || code.length <= maxCodeUnits;
  }

  /// Renders a list of markdown nodes to ANSI-styled text.
  String render(List<Node> nodes) {
    _buffer.clear();
    _elementStack.clear();
    _listDepth = 0;
    _listCounters.clear();
    _listItemStack.clear();
    _inBlockquote = false;
    _blockquoteDepth = 0;
    _lastWasBlock = false;
    _pendingLinkUrl = null;
    _detailsStack.clear();

    // Reset table state
    _tableHeaders.clear();
    _tableRows.clear();
    _tableAlignments.clear();
    _currentTableRow.clear();
    _currentCellBuffer.clear();
    _inTableHeader = false;
    _inTableCell = false;
    _inCodeBlock = false;
    _codeBlockLanguage = null;
    _inParagraph = false;
    _paragraphBuffer.clear();
    _textStyleActive = false;

    for (final node in nodes) {
      node.accept(this);
    }

    // Trim trailing whitespace but preserve structure
    var result = _buffer.toString();
    while (result.endsWith('\n\n')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // NodeVisitor Implementation
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void visitText(Text text) {
    if (_insideCollapsedDetailsBody) return;

    var content = text.text;
    if (!_inCodeBlock && _looksLikeRawHtml(content)) {
      content = _renderHtmlFragment(content);
    } else {
      // Decode HTML entities (e.g., &lt; &gt; &amp; &quot; &#39;)
      content = _htmlUnescape.convert(content);
    }

    if (!_inCodeBlock && _listItemStack.isNotEmpty) {
      final listItem = _listItemStack.last;
      if (listItem.trimLeadingWhitespace) {
        content = content.replaceFirst(RegExp(r'^\s+'), '');
        if (content.isNotEmpty) {
          listItem.trimLeadingWhitespace = false;
        }
      }
    }

    // Apply syntax highlighting for code blocks
    if (_inCodeBlock) {
      if (_shouldSyntaxHighlight(content, _codeBlockLanguage)) {
        // Apply syntax highlighting
        content = _highlighter.highlightCode(
          content,
          language: _codeBlockLanguage,
        );
      }

      // Apply code block border prefix for each line (after highlighting)
      if (options.codeBlockBorder && content.contains('\n')) {
        content = _applyCodeBlockPrefix(content);
      }

      // Apply blockquote prefix after highlighting so the quote markers don't
      // get treated as code content by the syntax highlighter.
      if (_inBlockquote) {
        content = _applyBlockquotePrefixAll(content);
      }
    } else if (_inBlockquote && content.contains('\n')) {
      content = _applyBlockquotePrefix(content);
    }

    // If inside a table cell, write to cell buffer instead
    _activeBuffer.write(content);
  }

  @override
  bool visitElementBefore(Element element) {
    _elementStack.add(element);

    if (_insideCollapsedDetailsBody && element.tag != 'summary') {
      _elementStack.removeLast();
      return false;
    }

    switch (element.tag) {
      // Block elements
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        _ensureNewline();
        _startHeading(element.tag);
        return true;

      case 'p':
        _ensureNewline();
        if (_inBlockquote) {
          _writeBlockquotePrefix();
        }
        // Start paragraph buffering for text wrapping
        if (options.width != null) {
          _inParagraph = true;
          _paragraphBuffer.clear();
        }
        _startTextStyle();
        return true;

      case 'blockquote':
        if (_inBlockquote &&
            _blockquoteBlankLinePending &&
            _blockquoteDepth > 0) {
          // Consume the separator without emitting an extra blank quoted row;
          // the nested quote should attach directly to the preceding quoted line.
          _blockquoteBlankLinePending = false;
        } else {
          _ensureNewline();
        }
        _inBlockquote = true;
        _blockquoteDepth++;
        return true;

      case 'pre':
        if (_inBlockquote && _blockquoteBlankLinePending) {
          _buffer.write('${_blockquotePrefixOnly()}\n');
          _blockquoteBlankLinePending = false;
        } else {
          _ensureNewline();
        }
        _startCodeBlock(element);
        return true;

      case 'ul':
        if (_listDepth == 0) {
          _ensureNewline();
        } else {
          // Nested list: add newline after parent item text
          _flushCurrentListItem();
          _buffer.write('\n');
        }
        _listDepth++;
        return true;

      case 'ol':
        if (_listDepth == 0) {
          _ensureNewline();
        } else {
          // Nested list: add newline after parent item text
          _flushCurrentListItem();
          _buffer.write('\n');
        }
        _listDepth++;
        _listCounters.add(
          int.tryParse(element.attributes['start'] ?? '1') ?? 1,
        );
        return true;

      case 'li':
        _startListItem(element);
        _startTextStyle();
        return true;

      case 'hr':
        _ensureNewline();
        _renderHorizontalRule();
        return false; // No children to visit

      case 'details':
        _ensureNewline();
        _detailsStack.add(
          DetailsContext(
            expanded:
                element.attributes.containsKey('open') ||
                element.attributes['open'] == 'true',
          ),
        );
        return true;

      case 'summary':
        if (_detailsStack.isNotEmpty) {
          final details = _detailsStack.last;
          details.inSummary = true;
          _buffer.write(details.expanded ? '\u25be ' : '\u25b8 ');
        }
        return true;

      case 'table':
        _ensureNewline();
        _tableHeaders.clear();
        _tableRows.clear();
        _tableAlignments.clear();
        return true;

      case 'thead':
        _inTableHeader = true;
        return true;

      case 'tbody':
        _inTableHeader = false;
        return true;

      case 'tr':
        _currentTableRow.clear();
        return true;

      case 'th':
        _inTableCell = true;
        _currentCellBuffer.clear();
        // Capture alignment from header cells
        final align = element.attributes['align'];
        if (align != null) {
          _tableAlignments.add(_parseTableAlign(align));
        }
        return true;

      case 'td':
        _inTableCell = true;
        _currentCellBuffer.clear();
        return true;

      // Inline elements
      case 'em':
        _startInlineStyle(_getEmphasisStyle());
        return true;

      case 'strong':
        _startInlineStyle(_getStrongStyle());
        return true;

      case 'code':
        // Check if inside a pre block (code block vs inline code)
        if (!_isInsidePreBlock()) {
          _startInlineStyle(_getCodeStyle());
        }
        return true;

      case 'a':
        _pendingLinkUrl = element.attributes['href'];
        _startLink();
        return true;

      case 'del':
        _startInlineStyle(_getStrikethroughStyle());
        return true;

      case 'u':
        _startInlineStyle(Style().underline());
        return true;

      case 'mark':
        _startInlineStyle(Style().inverse());
        return true;

      case 'br':
        _buffer.write('\n');
        if (_inBlockquote) {
          _writeBlockquotePrefix();
        }
        return false;

      case 'img':
        _renderImage(element);
        return false;

      case 'input':
        // Task list checkbox
        if (_isTaskListInput(element) &&
            _listItemStack.isNotEmpty &&
            _listItemStack.last.taskCheckboxRendered) {
          return false;
        }
        final checked = element.attributes['checked'] != null;
        final char = checked
            ? options.checkboxChecked
            : options.checkboxUnchecked;
        _buffer.write(char);
        _buffer.write(' ');
        return false;

      default:
        return true;
    }
  }

  @override
  void visitElementAfter(Element element) {
    _elementStack.removeLast();

    switch (element.tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        _endHeading();
        _buffer.write('\n');
        _lastWasBlock = true;
        break;

      case 'p':
        _endTextStyle();
        // Apply text wrapping if width is set
        if (_inParagraph && options.width != null) {
          final content = _paragraphBuffer.toString();
          _paragraphBuffer.clear();
          _inParagraph = false;

          if (content.isNotEmpty) {
            // Calculate effective width (account for blockquote prefix)
            var effectiveWidth = options.width!;
            if (_inBlockquote) {
              // Each blockquote level takes 2 chars: "│ "
              effectiveWidth -= _blockquoteDepth * 2;
            }

            if (effectiveWidth > 0) {
              final wrapped = _wrapText(content, effectiveWidth);
              _activeBuffer.write(wrapped);
            } else {
              _activeBuffer.write(content);
            }
          }
        }
        if (_inBlockquote) {
          _buffer.write('\n');
          _blockquoteBlankLinePending = true;
        } else {
          _buffer.write('\n');
        }
        _lastWasBlock = true;
        break;

      case 'blockquote':
        _blockquoteDepth--;
        if (_blockquoteDepth <= 0) {
          _inBlockquote = false;
          _blockquoteBlankLinePending = false;
          if (_blockquoteDepth < 0) {
            _blockquoteDepth = 0;
          }
        }
        _lastWasBlock = true;
        break;

      case 'pre':
        _endCodeBlock();
        _lastWasBlock = true;
        break;

      case 'ul':
        _listDepth--;
        if (_listDepth == 0) {
          _lastWasBlock = true;
        }
        break;

      case 'ol':
        _listDepth--;
        _listCounters.removeLast();
        if (_listDepth == 0) {
          _lastWasBlock = true;
        }
        break;

      case 'li':
        _endTextStyle();
        _flushCurrentListItem();
        if (_listItemStack.isNotEmpty) {
          _listItemStack.removeLast();
        }
        // Only add newline if the li didn't end with a nested list
        // (nested lists already handle their own newlines)
        if (!_hasNestedList(element)) {
          _buffer.write('\n');
        }
        break;

      case 'em':
        _endInlineStyle();
        break;

      case 'strong':
        _endInlineStyle();
        break;

      case 'code':
        if (!_isInsidePreBlock()) {
          _endInlineStyle();
        }
        break;

      case 'a':
        _endLink();
        _pendingLinkUrl = null;
        break;

      case 'del':
        _endInlineStyle();
        break;

      case 'u':
      case 'mark':
        _endInlineStyle();
        break;

      case 'summary':
        if (_detailsStack.isNotEmpty) {
          _detailsStack.last.inSummary = false;
          _buffer.write('\n');
        }
        break;

      case 'details':
        if (_detailsStack.isNotEmpty) {
          _detailsStack.removeLast();
        }
        _ensureNewline();
        _lastWasBlock = true;
        break;

      case 'table':
        _renderTable();
        _lastWasBlock = true;
        break;

      case 'thead':
        _inTableHeader = false;
        break;

      case 'tbody':
        // Nothing to do
        break;

      case 'tr':
        // Add completed row to headers or rows
        if (_inTableHeader) {
          _tableHeaders.addAll(_currentTableRow);
        } else {
          _tableRows.add(List<String>.from(_currentTableRow));
        }
        _currentTableRow.clear();
        break;

      case 'th':
      case 'td':
        // Save cell content to current row
        _currentTableRow.add(_currentCellBuffer.toString().trim());
        _currentCellBuffer.clear();
        _inTableCell = false;
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Heading Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  void _startHeading(String tag) {
    final style = _getHeadingStyle(tag);
    _buffer.write(_styleToAnsiOpen(style));
  }

  void _endHeading() {
    _buffer.write(_ansiReset);
  }

  Style _getHeadingStyle(String tag) {
    return switch (tag) {
      'h1' => options.h1Style ?? _defaultH1Style(),
      'h2' => options.h2Style ?? _defaultH2Style(),
      'h3' => options.h3Style ?? _defaultH3Style(),
      'h4' => options.h4Style ?? _defaultH4Style(),
      'h5' => options.h5Style ?? _defaultH5Style(),
      'h6' => options.h6Style ?? _defaultH6Style(),
      _ => Style(),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // List Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  void _startListItem(Element element) {
    // Add blockquote prefix if inside a blockquote
    if (_inBlockquote) {
      _writeBlockquotePrefix();
    }

    // Add indentation based on nesting level
    final indent = ' ' * ((_listDepth - 1) * options.listIndent);
    _buffer.write(indent);

    // Determine if this is an ordered or unordered list item
    final parent = _findParentList();
    final taskInput = _firstTaskListInput(element);
    final taskCheckbox = taskInput == null
        ? null
        : (taskInput.attributes['checked'] != null
              ? options.checkboxChecked
              : options.checkboxUnchecked);
    var marker = '';
    if (parent?.tag == 'ol') {
      // Ordered list
      final counter = _listCounters.isNotEmpty ? _listCounters.last : 1;
      marker = taskCheckbox == null ? '$counter. ' : '$counter. $taskCheckbox ';
      if (_listCounters.isNotEmpty) {
        _listCounters[_listCounters.length - 1] = counter + 1;
      }
    } else {
      // Unordered list
      marker = taskCheckbox == null
          ? '${options.bulletChar} '
          : '$taskCheckbox ';
    }

    _buffer.write(marker);
    _listItemStack.add(
      _ListItemContext(
        continuationIndent:
            Style.visibleLength(indent) + Style.visibleLength(marker),
        taskCheckboxRendered: taskCheckbox != null,
      ),
    );
  }

  Element? _findParentList() {
    for (var i = _elementStack.length - 1; i >= 0; i--) {
      if (_elementStack[i].tag == 'ul' || _elementStack[i].tag == 'ol') {
        return _elementStack[i];
      }
    }
    return null;
  }

  /// Checks whether a list item contains a nested list (ul or ol).
  bool _hasNestedList(Element element) {
    if (element.children == null) return false;
    for (final child in element.children!) {
      if (child is Element && (child.tag == 'ul' || child.tag == 'ol')) {
        return true;
      }
    }
    return false;
  }

  /// Returns the first task-list checkbox input when it starts [element].
  Element? _firstTaskListInput(Element element) {
    final children = element.children;
    if (children == null) return null;

    for (final child in children) {
      if (child is Text && child.text.trim().isEmpty) {
        continue;
      }
      if (child is Element && _isTaskListInput(child)) {
        return child;
      }
      return null;
    }

    return null;
  }

  bool _isTaskListInput(Element element) =>
      element.tag == 'input' && element.attributes['type'] == 'checkbox';

  /// Flushes buffered list-item text with indentation for wrapped lines.
  void _flushCurrentListItem() {
    if (_listItemStack.isEmpty) return;

    final context = _listItemStack.last;
    final content = context.buffer.toString();
    if (content.isEmpty) return;

    context.buffer.clear();
    if (options.width == null) {
      _buffer.write(content);
      return;
    }

    final width = options.width! - context.continuationIndent;
    final wrapped = _wrapText(content, width > 0 ? width : options.width!);
    _buffer.write(
      _indentContinuationLines(wrapped, context.continuationIndent),
    );
  }

  String _indentContinuationLines(String text, int indent) {
    if (indent <= 0 || !text.contains('\n')) return text;

    final continuation = ' ' * indent;
    final lines = text.split('\n');
    final hasTrailingNewline = text.endsWith('\n');
    final lastIndex = lines.length - 1;

    return lines
        .asMap()
        .entries
        .map((entry) {
          if (entry.key == 0) return entry.value;
          if (hasTrailingNewline &&
              entry.key == lastIndex &&
              entry.value.isEmpty) {
            return '';
          }
          return '$continuation${entry.value}';
        })
        .join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Blockquote Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  String _blockquotePrefixOnly() {
    final color =
        options.blockquoteBorderColor ?? _defaultBlockquoteBorderColor();
    final colorSeq = color.toAnsi(ColorProfile.trueColor);
    final prefix = '\u2502' * _blockquoteDepth + ' ';
    return '$colorSeq$prefix$_ansiReset';
  }

  void _writeBlockquotePrefix() {
    _buffer.write(_blockquotePrefixOnly());

    // Apply blockquote text style
    final style = options.blockquoteStyle ?? _defaultBlockquoteStyle();
    _buffer.write(_styleToAnsiOpen(style));
  }

  String _applyBlockquotePrefix(String text) {
    final lines = text.split('\n');
    final prefix = _blockquotePrefixOnly();

    return lines
        .asMap()
        .entries
        .map((entry) {
          final i = entry.key;
          final line = entry.value;
          if (i == 0) return line; // First line already has prefix
          if (line.isEmpty && i == lines.length - 1) return line;
          return '$prefix$line';
        })
        .join('\n');
  }

  String _applyBlockquotePrefixAll(String text) {
    final prefix = _blockquotePrefixOnly();
    return text.split('\n').map((line) => '$prefix$line').join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Code Block Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  void _startCodeBlock(Element element) {
    _inCodeBlock = true;
    _codeBlockLanguage = null;

    // Get the language hint if available
    final codeElement = element.children?.firstWhere(
      (n) => n is Element && n.tag == 'code',
      orElse: () => Text(''),
    );
    if (codeElement is Element) {
      final classes = codeElement.attributes['class']?.split(' ') ?? [];
      for (final cls in classes) {
        if (cls.startsWith('language-')) {
          _codeBlockLanguage = cls.substring(9);
          break;
        }
      }
    }

    if (options.codeBlockBorder) {
      // Get the border style (default to rounded)
      final border =
          options.codeBlockBorderStyle ?? style_border.Border.rounded;
      final borderColor = Colors.gray;
      final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);

      if (_inBlockquote) {
        _buffer.write('${_blockquotePrefixOnly()}\n${_blockquotePrefixOnly()}');
      }

      if (_codeBlockLanguage != null) {
        _buffer.write(
          '$borderSeq${border.topLeft}${border.top} $_codeBlockLanguage $_ansiReset\n',
        );
      } else {
        _buffer.write(
          '$borderSeq${border.topLeft}${border.top}${border.top}${border.top}$_ansiReset\n',
        );
      }
      _buffer.write('$borderSeq${border.left}$_ansiReset ');
    }

    // Only apply default code style if syntax highlighting is disabled
    // or if no language is specified
    if (!options.syntaxHighlighting || _codeBlockLanguage == null) {
      final style = options.codeBlockStyle ?? _defaultCodeBlockStyle();
      _buffer.write(_styleToAnsiOpen(style));
    }
  }

  void _endCodeBlock() {
    // Only close style if we opened it (no syntax highlighting)
    if (!options.syntaxHighlighting || _codeBlockLanguage == null) {
      _buffer.write(_ansiReset);
    }
    _inCodeBlock = false;
    _codeBlockLanguage = null;

    if (options.codeBlockBorder) {
      final border =
          options.codeBlockBorderStyle ?? style_border.Border.rounded;
      final borderColor = Colors.gray;
      final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);
      // Close the last line and draw bottom border
      _buffer.write('\n');
      if (_inBlockquote) {
        _buffer.write(_blockquotePrefixOnly());
      }
      _buffer.write(
        '$borderSeq${border.bottomLeft}${border.bottom}${border.bottom}${border.bottom}$_ansiReset\n',
      );
    } else {
      _buffer.write('\n');
    }
  }

  /// Applies the code block border prefix to each line of content.
  String _applyCodeBlockPrefix(String text) {
    final border = options.codeBlockBorderStyle ?? style_border.Border.rounded;
    final borderColor = Colors.gray;
    final borderSeq = borderColor.toAnsi(ColorProfile.trueColor);
    final prefix = '$borderSeq${border.left}$_ansiReset ';

    // Only re-apply code style if syntax highlighting is not active
    final useSyntaxHighlighting =
        options.syntaxHighlighting && _codeBlockLanguage != null;
    final styleSeq = useSyntaxHighlighting
        ? ''
        : _styleToAnsiOpen(options.codeBlockStyle ?? _defaultCodeBlockStyle());

    final lines = text.split('\n');
    return lines
        .asMap()
        .entries
        .map((entry) {
          final i = entry.key;
          final line = entry.value;
          if (i == 0) {
            return line; // First line already has prefix from _startCodeBlock
          }
          // For subsequent lines, add border prefix and optionally re-apply code style
          return '$prefix$styleSeq$line';
        })
        .join('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Horizontal Rule
  // ─────────────────────────────────────────────────────────────────────────────

  void _renderHorizontalRule() {
    final width = options.hrWidth ?? options.width ?? 40;
    final line = options.hrChar * width;
    final dimStyle = Style().dim();
    _buffer.write(_styleToAnsiOpen(dimStyle));
    _buffer.write(line);
    _buffer.write(_ansiReset);
    _buffer.write('\n');
    _lastWasBlock = true;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Table Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Parses a markdown alignment string to [TableAlign].
  table_component.TableAlign _parseTableAlign(String align) {
    return switch (align.toLowerCase()) {
      'left' => table_component.TableAlign.left,
      'center' => table_component.TableAlign.center,
      'right' => table_component.TableAlign.right,
      _ => table_component.TableAlign.left,
    };
  }

  /// Renders the collected table using artisanal's Table component.
  void _renderTable() {
    if (_tableHeaders.isEmpty && _tableRows.isEmpty) return;

    final table = table_component.Table()
      ..headers(_tableHeaders)
      ..rows(_tableRows)
      ..border(options.tableBorder ?? style_border.Border.rounded)
      ..padding(1)
      ..wrap(false); // Disable wrapping to preserve content

    // Apply column alignments if any were specified
    if (_tableAlignments.isNotEmpty) {
      table.alignments(_tableAlignments);
    }

    // Apply header style if specified
    if (options.tableHeaderStyle != null) {
      table.headerStyle(options.tableHeaderStyle!);
    } else {
      // Default: bold headers
      table.headerStyle(Style().bold());
    }

    // Apply cell style if specified
    if (options.tableCellStyle != null) {
      table.cellStyle(options.tableCellStyle!);
    }

    // Apply border style if specified
    if (options.tableBorderStyle != null) {
      table.borderStyle(options.tableBorderStyle!);
    }

    _buffer.write(table.render());
    _buffer.write('\n');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Image Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  void _renderImage(Element element) {
    final alt = element.attributes['alt'] ?? 'image';
    final src = element.attributes['src'] ?? '';

    if (options.renderImages && src.isNotEmpty && imageCache.containsKey(src)) {
      final bytes = imageCache[src]!;
      final image = img.decodeImage(bytes);
      if (image != null) {
        _renderTerminalImage(image);
        return;
      }
    }

    // Fall back to text placeholder
    final style = Style().dim();
    _buffer.write(_styleToAnsiOpen(style));
    _buffer.write('[Image: $alt]');
    if (src.isNotEmpty) {
      _buffer.write(' ($src)');
    }
    _buffer.write(_ansiReset);
  }

  void _renderTerminalImage(img.Image image) {
    final (cols, rows) = imageCellDimensions(
      image,
      maxColumns: options.imageMaxWidth,
      maxRows: options.imageMaxHeight,
    );

    // Use forced protocol if set.
    var protocol = options.imageProtocol ?? detectImageProtocol();
    if (protocol == ImageProtocol.none) {
      // Fall back to half-block rendering (▀ with true-color ANSI).
      // Works in any terminal that supports 24-bit color — no special
      // graphics protocol required.
      protocol = ImageProtocol.halfblock;
    }

    final escaped = renderImageToAnsi(
      image,
      protocol,
      columns: cols,
      rows: rows,
    );
    if (escaped != null) {
      _buffer.write(escaped);
      return;
    }
    _buffer.write('[Image: ${image.width}x${image.height}px]');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Raw HTML Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  bool _looksLikeRawHtml(String text) {
    return RegExp(
      r'<(?:[a-zA-Z][a-zA-Z0-9:-]*(?:\s|>|/>)|/[a-zA-Z][a-zA-Z0-9:-]*\s*>|!--|\?|!)',
      dotAll: true,
    ).hasMatch(text);
  }

  String _renderHtmlFragment(String source) {
    final fragment = html_parser.parseFragment(source);
    final buffer = StringBuffer();
    final context = HtmlRenderContext();

    for (final node in fragment.nodes) {
      _renderHtmlNode(node, buffer, context);
    }

    return _cleanupHtmlOutput(buffer.toString());
  }

  void _renderHtmlNode(
    dom.Node node,
    StringBuffer buffer,
    HtmlRenderContext context,
  ) {
    if (node is dom.Text) {
      _writeHtmlText(node.text, buffer);
      return;
    }

    if (node is! dom.Element) return;

    final tag = node.localName?.toLowerCase() ?? node.localName ?? '';
    switch (tag) {
      case 'html':
      case 'body':
      case 'span':
      case 'abbr':
      case 'cite':
      case 'q':
      case 'time':
      case 'var':
        _renderHtmlChildren(node, buffer, context);
        break;

      case 'p':
      case 'div':
      case 'section':
      case 'article':
      case 'header':
      case 'footer':
      case 'main':
      case 'nav':
      case 'aside':
      case 'form':
      case 'fieldset':
      case 'figure':
      case 'figcaption':
      case 'caption':
      case 'center':
      case 'address':
      case 'dialog':
      case 'dd':
        _renderHtmlBlock(node, buffer, context);
        break;

      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        _renderHtmlHeading(node, buffer, context, tag);
        break;

      case 'strong':
      case 'b':
        _renderStyledHtmlChildren(node, buffer, context, _getStrongStyle());
        break;

      case 'em':
      case 'i':
        _renderStyledHtmlChildren(node, buffer, context, _getEmphasisStyle());
        break;

      case 'code':
      case 'kbd':
      case 'samp':
        _renderStyledHtmlChildren(node, buffer, context, _getCodeStyle());
        break;

      case 'del':
      case 's':
      case 'strike':
        _renderStyledHtmlChildren(
          node,
          buffer,
          context,
          _getStrikethroughStyle(),
        );
        break;

      case 'ins':
      case 'u':
        _renderStyledHtmlChildren(node, buffer, context, Style().underline());
        break;

      case 'mark':
        _renderStyledHtmlChildren(node, buffer, context, Style().inverse());
        break;

      case 'sub':
        buffer.write('_');
        _renderHtmlChildren(node, buffer, context);
        break;

      case 'sup':
        buffer.write('^');
        _renderHtmlChildren(node, buffer, context);
        break;

      case 'a':
        _renderHtmlLink(node, buffer, context);
        break;

      case 'br':
        buffer.write('\n');
        break;

      case 'hr':
        _ensureHtmlBlockStart(buffer);
        _renderHorizontalRuleTo(buffer);
        _ensureHtmlBlankLine(buffer);
        break;

      case 'img':
        _renderHtmlImage(node, buffer);
        break;

      case 'input':
        _renderHtmlInput(node, buffer);
        break;

      case 'ul':
        _renderHtmlList(node, buffer, context, ordered: false);
        break;

      case 'ol':
        _renderHtmlList(node, buffer, context, ordered: true);
        break;

      case 'li':
        _renderHtmlListItem(node, buffer, context);
        break;

      case 'blockquote':
        _renderHtmlBlockquote(node, buffer, context);
        break;

      case 'pre':
        _renderHtmlPre(node, buffer);
        break;

      case 'table':
        _renderHtmlTable(node, buffer, context);
        break;

      case 'thead':
      case 'tbody':
      case 'tfoot':
      case 'tr':
      case 'th':
      case 'td':
        _renderHtmlChildren(node, buffer, context);
        break;

      case 'details':
        _renderHtmlDetails(node, buffer, context);
        break;

      case 'summary':
        _renderHtmlBlock(node, buffer, context);
        break;

      case 'dl':
        _renderHtmlBlock(node, buffer, context);
        break;

      case 'dt':
        _renderHtmlHeading(node, buffer, context, 'h6');
        break;

      case 'iframe':
        final src = _htmlAttributeValue(node, 'src');
        if (src.isNotEmpty) buffer.write('[iframe: $src]');
        break;

      case 'script':
      case 'style':
      case 'head':
      case 'link':
      case 'meta':
      case 'base':
      case 'source':
      case 'track':
      case 'param':
      case 'title':
        break;

      default:
        _renderHtmlChildren(node, buffer, context);
        break;
    }
  }

  void _renderHtmlChildren(
    dom.Element element,
    StringBuffer buffer,
    HtmlRenderContext context,
  ) {
    for (final child in element.nodes) {
      _renderHtmlNode(child, buffer, context);
    }
  }

  void _renderStyledHtmlChildren(
    dom.Element element,
    StringBuffer buffer,
    HtmlRenderContext context,
    Style style,
  ) {
    buffer.write(_styleToAnsiOpen(style));
    _renderHtmlChildren(element, buffer, context);
    buffer.write(_contextualReset);
  }

  void _renderHtmlBlock(
    dom.Element element,
    StringBuffer buffer,
    HtmlRenderContext context,
  ) {
    _ensureHtmlBlockStart(buffer);
    _renderHtmlChildren(element, buffer, context);
    _ensureHtmlBlankLine(buffer);
  }

  void _renderHtmlHeading(
    dom.Element element,
    StringBuffer buffer,
    HtmlRenderContext context,
    String tag,
  ) {
    _ensureHtmlBlockStart(buffer);
    buffer.write(_styleToAnsiOpen(_getHeadingStyle(tag)));
    _renderHtmlChildren(element, buffer, context);
    buffer.write(_ansiReset);
    _ensureHtmlBlankLine(buffer);
  }

  void _renderHtmlLink(
    dom.Element element,
    StringBuffer buffer,
    HtmlRenderContext context,
  ) {
    final href = _htmlAttributeValue(element, 'href');
    buffer.write(_styleToAnsiOpen(options.linkStyle ?? _defaultLinkStyle()));
    if (options.hyperlinks && href.isNotEmpty) {
      buffer.write('\x1b]8;;$href\x1b\\');
    }
    _renderHtmlChildren(element, buffer, context);
    if (options.hyperlinks && href.isNotEmpty) {
      buffer.write('\x1b]8;;\x1b\\');
    }
    buffer.write(_contextualReset);
  }

  void _renderHtmlImage(dom.Element element, StringBuffer buffer) {
    final alt = _htmlAttributeValue(element, 'alt');
    final src = _htmlAttributeValue(element, 'src');
    final label = alt.isEmpty ? 'image' : alt;

    buffer.write(_styleToAnsiOpen(Style().dim()));
    buffer.write('[Image: $label]');
    if (src.isNotEmpty) {
      buffer.write(' ($src)');
    }
    buffer.write(_contextualReset);
  }

  void _renderHtmlInput(dom.Element element, StringBuffer buffer) {
    if (_htmlAttributeValue(element, 'type').toLowerCase() != 'checkbox') {
      return;
    }
    final checked = element.attributes.containsKey('checked');
    buffer.write(checked ? options.checkboxChecked : options.checkboxUnchecked);
    buffer.write(' ');
  }

  void _renderHtmlList(
    dom.Element element,
    StringBuffer buffer,
    HtmlRenderContext context, {
    required bool ordered,
  }) {
    _ensureHtmlBlockStart(buffer);
    context.lists.add(
      HtmlListContext(
        ordered: ordered,
        next: int.tryParse(_htmlAttributeValue(element, 'start')) ?? 1,
      ),
    );

    for (final child in element.nodes) {
      if (child is dom.Element && child.localName?.toLowerCase() == 'li') {
        _renderHtmlListItem(child, buffer, context);
      }
    }

    context.lists.removeLast();
    _ensureHtmlBlankLine(buffer);
  }

  void _renderHtmlListItem(
    dom.Element element,
    StringBuffer buffer,
    HtmlRenderContext context,
  ) {
    final list = context.lists.isEmpty ? null : context.lists.last;
    final depth = context.lists.isEmpty ? 0 : context.lists.length - 1;
    final indent = ' ' * (depth * options.listIndent);
    final marker = list == null
        ? '${options.bulletChar} '
        : list.ordered
        ? '${list.next++}. '
        : '${options.bulletChar} ';

    _ensureHtmlLineStart(buffer);
    buffer.write(indent);
    buffer.write(marker);

    for (final child in element.nodes) {
      if (child is dom.Element && child.localName?.toLowerCase() == 'p') {
        _renderHtmlChildren(child, buffer, context);
        continue;
      }
      _renderHtmlNode(child, buffer, context);
    }

    _ensureHtmlLineStart(buffer);
  }

  void _renderHtmlBlockquote(
    dom.Element element,
    StringBuffer buffer,
    HtmlRenderContext context,
  ) {
    final inner = StringBuffer();
    _renderHtmlChildren(element, inner, context);
    final content = _cleanupHtmlOutput(inner.toString()).trim();
    if (content.isEmpty) return;

    _ensureHtmlBlockStart(buffer);
    final color =
        options.blockquoteBorderColor ?? _defaultBlockquoteBorderColor();
    final border = color.toAnsi(ColorProfile.trueColor);
    final style = _styleToAnsiOpen(
      options.blockquoteStyle ?? _defaultBlockquoteStyle(),
    );
    for (final line in content.split('\n')) {
      buffer.write('$border\u2502 $_ansiReset$style$line$_ansiReset\n');
    }
    _ensureHtmlBlankLine(buffer);
  }

  void _renderHtmlPre(dom.Element element, StringBuffer buffer) {
    final code = element.querySelector('code');
    final language = code == null ? null : _htmlCodeLanguage(code);
    final content = (code?.text ?? element.text)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trimRight();

    _ensureHtmlBlockStart(buffer);
    _renderCodeBlockTo(buffer, content, language);
    _ensureHtmlBlankLine(buffer);
  }

  void _renderHtmlTable(
    dom.Element element,
    StringBuffer buffer,
    HtmlRenderContext context,
  ) {
    final headers = <String>[];
    final rows = <List<String>>[];
    final alignments = <table_component.TableAlign>[];

    for (final row in element.querySelectorAll('tr')) {
      final cells = row.children
          .where((child) {
            final tag = child.localName?.toLowerCase();
            return tag == 'th' || tag == 'td';
          })
          .toList(growable: false);
      if (cells.isEmpty) continue;

      final renderedCells = <String>[];
      final isHeader = cells.any(
        (cell) => cell.localName?.toLowerCase() == 'th',
      );

      for (final cell in cells) {
        final cellBuffer = StringBuffer();
        _renderHtmlChildren(cell, cellBuffer, context);
        renderedCells.add(_cleanupHtmlOutput(cellBuffer.toString()).trim());

        if (isHeader) {
          alignments.add(_parseTableAlign(_htmlAttributeValue(cell, 'align')));
        }
      }

      if (isHeader && headers.isEmpty) {
        headers.addAll(renderedCells);
      } else {
        rows.add(renderedCells);
      }
    }

    if (headers.isEmpty && rows.isEmpty) {
      _renderHtmlBlock(element, buffer, context);
      return;
    }

    _ensureHtmlBlockStart(buffer);
    final table = table_component.Table()
      ..headers(headers)
      ..rows(rows)
      ..border(options.tableBorder ?? style_border.Border.rounded)
      ..padding(1)
      ..wrap(false);

    if (alignments.isNotEmpty) table.alignments(alignments);
    table.headerStyle(options.tableHeaderStyle ?? Style().bold());
    if (options.tableCellStyle != null) {
      table.cellStyle(options.tableCellStyle!);
    }
    if (options.tableBorderStyle != null) {
      table.borderStyle(options.tableBorderStyle!);
    }

    buffer.write(table.render());
    _ensureHtmlBlankLine(buffer);
  }

  void _renderHtmlDetails(
    dom.Element element,
    StringBuffer buffer,
    HtmlRenderContext context,
  ) {
    final summary = element.children.firstWhere(
      (child) => child.localName?.toLowerCase() == 'summary',
      orElse: () => dom.Element.tag('summary'),
    );
    final summaryText = _htmlPlainText(summary.nodes).trim();
    final title = summaryText.isEmpty ? 'Details' : summaryText;
    final expanded = element.attributes.containsKey('open');

    _ensureHtmlBlockStart(buffer);
    buffer.write(expanded ? '\u25be ' : '\u25b8 ');
    buffer.write(title);
    buffer.write('\n');

    if (expanded) {
      for (final child in element.nodes) {
        if (child is dom.Element &&
            child.localName?.toLowerCase() == 'summary') {
          continue;
        }
        _renderHtmlNode(child, buffer, context);
      }
    }

    _ensureHtmlBlankLine(buffer);
  }

  void _renderCodeBlockTo(StringBuffer buffer, String code, String? language) {
    var content = code;
    final highlighted = _shouldSyntaxHighlight(content, language);
    if (highlighted) {
      content = _highlighter.highlightCode(content, language: language);
    }

    if (!options.codeBlockBorder) {
      if (!highlighted) {
        buffer.write(
          _styleToAnsiOpen(options.codeBlockStyle ?? _defaultCodeBlockStyle()),
        );
      }
      buffer.write(content);
      if (!highlighted) buffer.write(_ansiReset);
      buffer.write('\n');
      return;
    }

    final border = options.codeBlockBorderStyle ?? style_border.Border.rounded;
    final borderSeq = Colors.gray.toAnsi(ColorProfile.trueColor);
    if (language == null) {
      buffer.write('$borderSeq${border.topLeft}${border.top}${border.top}');
      buffer.write('${border.top}$_ansiReset\n');
    } else {
      buffer.write(
        '$borderSeq${border.topLeft}${border.top} $language $_ansiReset\n',
      );
    }

    final prefix = '$borderSeq${border.left}$_ansiReset ';
    final styleSeq = highlighted
        ? ''
        : _styleToAnsiOpen(options.codeBlockStyle ?? _defaultCodeBlockStyle());
    for (final line in content.split('\n')) {
      buffer.write(prefix);
      buffer.write(styleSeq);
      buffer.write(line);
      if (!highlighted) buffer.write(_ansiReset);
      buffer.write('\n');
    }

    buffer.write(
      '$borderSeq${border.bottomLeft}${border.bottom}${border.bottom}',
    );
    buffer.write('${border.bottom}$_ansiReset\n');
  }

  void _writeHtmlText(String text, StringBuffer buffer) {
    var content = _htmlUnescape
        .convert(text)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00a0', ' ');

    content = content.replaceAll(RegExp(r'\s+'), ' ');
    if (content.trim().isEmpty) {
      if (!_htmlBufferEndsWithWhitespace(buffer)) {
        buffer.write(' ');
      }
      return;
    }
    if (_htmlBufferEndsWithWhitespace(buffer)) {
      content = content.trimLeft();
    }

    final textStyle = options.textStyle;
    if (textStyle == null) {
      buffer.write(content);
      return;
    }

    buffer.write(_styleToAnsiOpen(textStyle));
    buffer.write(content);
    buffer.write(_ansiReset);
  }

  String _htmlPlainText(List<dom.Node> nodes) {
    final buffer = StringBuffer();
    for (final node in nodes) {
      if (node is dom.Text) {
        _writeHtmlText(node.text, buffer);
      } else if (node is dom.Element) {
        buffer.write(_htmlPlainText(node.nodes));
      }
    }
    return _cleanupHtmlOutput(buffer.toString());
  }

  String? _htmlCodeLanguage(dom.Element code) {
    final classes = _htmlAttributeValue(code, 'class').split(' ');
    for (final cls in classes) {
      if (cls.startsWith('language-')) return cls.substring(9);
    }
    return null;
  }

  String _htmlAttributeValue(dom.Element element, String name) {
    return _htmlUnescape.convert(element.attributes[name] ?? '');
  }

  void _renderHorizontalRuleTo(StringBuffer buffer) {
    final width = options.hrWidth ?? options.width ?? 40;
    final line = options.hrChar * width;
    buffer.write(_styleToAnsiOpen(Style().dim()));
    buffer.write(line);
    buffer.write(_ansiReset);
    buffer.write('\n');
  }

  void _ensureHtmlBlockStart(StringBuffer buffer) {
    _trimHtmlLineEnd(buffer);
    final text = buffer.toString();
    if (text.isEmpty || text.endsWith('\n\n')) return;
    if (text.endsWith('\n')) {
      buffer.write('\n');
    } else {
      buffer.write('\n\n');
    }
  }

  void _ensureHtmlLineStart(StringBuffer buffer) {
    _trimHtmlLineEnd(buffer);
    final text = buffer.toString();
    if (text.isNotEmpty && !text.endsWith('\n')) {
      buffer.write('\n');
    }
  }

  void _ensureHtmlBlankLine(StringBuffer buffer) {
    _trimHtmlLineEnd(buffer);
    final text = buffer.toString();
    if (text.isEmpty || text.endsWith('\n\n')) return;
    if (text.endsWith('\n')) {
      buffer.write('\n');
    } else {
      buffer.write('\n\n');
    }
  }

  void _trimHtmlLineEnd(StringBuffer buffer) {
    final text = buffer.toString();
    final trimmed = text.replaceFirst(RegExp(r'[ \t]+$'), '');
    if (trimmed.length == text.length) return;
    buffer
      ..clear()
      ..write(trimmed);
  }

  bool _htmlBufferEndsWithWhitespace(StringBuffer buffer) {
    if (buffer.isEmpty) return true;
    return RegExp(r'\s$').hasMatch(buffer.toString());
  }

  String _cleanupHtmlOutput(String text) {
    return text
        .split('\n')
        .map((line) => line.trimRight())
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Link Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  void _startLink() {
    final style = options.linkStyle ?? _defaultLinkStyle();
    _activeBuffer.write(_styleToAnsiOpen(style));

    // Add OSC 8 hyperlink if enabled and URL is available
    if (options.hyperlinks && _pendingLinkUrl != null) {
      _activeBuffer.write('\x1b]8;;${_pendingLinkUrl!}\x1b\\');
    }
  }

  void _endLink() {
    // Close OSC 8 hyperlink if enabled
    if (options.hyperlinks && _pendingLinkUrl != null) {
      _activeBuffer.write('\x1b]8;;\x1b\\');
    }

    _activeBuffer.write(_contextualReset);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Inline Style Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  void _startInlineStyle(Style style) {
    _activeBuffer.write(_styleToAnsiOpen(style));
  }

  void _endInlineStyle() {
    _activeBuffer.write(_contextualReset);
  }

  Style _getEmphasisStyle() => options.emphasisStyle ?? _defaultEmphasisStyle();
  Style _getStrongStyle() => options.strongStyle ?? _defaultStrongStyle();
  Style _getCodeStyle() => options.codeStyle ?? _defaultCodeStyle();
  Style _getStrikethroughStyle() =>
      options.strikethroughStyle ?? _defaultStrikethroughStyle();

  /// Starts applying the body text style if one is configured.
  void _startTextStyle() {
    if (options.textStyle != null) {
      _activeBuffer.write(_styleToAnsiOpen(options.textStyle!));
      _textStyleActive = true;
    }
  }

  /// Ends the body text style if one is active.
  void _endTextStyle() {
    if (_textStyleActive) {
      _activeBuffer.write(_ansiReset);
      _textStyleActive = false;
    }
  }

  /// Returns the appropriate reset sequence.
  ///
  /// When a [textStyle] is active (i.e., we're inside a paragraph or list
  /// item with body text styling), the reset restores the text style so that
  /// subsequent text continues with the correct foreground color.
  String get _contextualReset {
    if (_textStyleActive && options.textStyle != null) {
      return '$_ansiReset${_styleToAnsiOpen(options.textStyle!)}';
    }
    return _ansiReset;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Utility Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  bool _isInsidePreBlock() {
    return _elementStack.any((e) => e.tag == 'pre');
  }

  bool get _insideCollapsedDetailsBody {
    return _detailsStack.any((details) {
      return !details.expanded && !details.inSummary;
    });
  }

  /// Returns the currently active output buffer.
  ///
  /// When inside a table cell, returns [_currentCellBuffer].
  /// When inside a paragraph with width wrapping, returns [_paragraphBuffer].
  /// Otherwise, returns the main [_buffer].
  StringBuffer get _activeBuffer {
    if (_inTableCell) return _currentCellBuffer;
    if (_inParagraph && options.width != null && !_inCodeBlock) {
      return _paragraphBuffer;
    }
    if (_listItemStack.isNotEmpty && options.width != null && !_inCodeBlock) {
      return _listItemStack.last.buffer;
    }
    return _buffer;
  }

  void _ensureNewline() {
    if (_buffer.isNotEmpty && !_buffer.toString().endsWith('\n')) {
      _buffer.write('\n');
    }
    if (_lastWasBlock && !_inBlockquote) {
      _buffer.write('\n');
      _lastWasBlock = false;
    } else if (_lastWasBlock) {
      // Inside a blockquote: blank lines between paragraph→list are
      // syntactic separators, not content.  But nested blockquotes
      // (like those produced by normalizer-merged `> >`) represent
      // genuine section breaks and need a visible blank line.
      final enteringNestedBlockquote =
          _elementStack.isNotEmpty && _elementStack.last.tag == 'blockquote';
      if (enteringNestedBlockquote) {
        _buffer.write('\n');
      }
      _lastWasBlock = false;
    }
  }

  /// Wraps text to fit within the specified width.
  ///
  /// Uses ANSI-aware wrapping to preserve styling across line breaks.
  String _wrapText(String text, int width) {
    if (width <= 0) return text;
    return uv_wrap.wrapAnsiPreserving(text, width);
  }

  /// ANSI reset sequence.
  static const _ansiReset = '\x1b[0m';

  /// Converts a Style to ANSI escape sequence for opening.
  String _styleToAnsiOpen(Style style) {
    final codes = <int>[];

    if (style.isBold) codes.add(1);
    if (style.isDim) codes.add(2);
    if (style.isItalic) codes.add(3);
    if (style.isUnderline) codes.add(4);
    if (style.isBlink) codes.add(5);
    if (style.isInverse) codes.add(7);
    if (style.isStrikethrough) codes.add(9);

    final buffer = StringBuffer();

    // Add SGR codes
    if (codes.isNotEmpty) {
      buffer.write('\x1b[${codes.join(';')}m');
    }

    // Add foreground color
    final fg = style.getForeground;
    if (fg != null) {
      buffer.write(
        fg.toAnsi(
          ColorProfile.trueColor,
          hasDarkBackground: style.hasDarkBackground,
        ),
      );
    }

    // Add background color
    final bg = style.getBackground;
    if (bg != null) {
      buffer.write(
        bg.toAnsi(
          ColorProfile.trueColor,
          background: true,
          hasDarkBackground: style.hasDarkBackground,
        ),
      );
    }

    return buffer.toString();
  }
}

class _ListItemContext {
  _ListItemContext({
    required this.continuationIndent,
    required this.taskCheckboxRendered,
  }) : trimLeadingWhitespace = taskCheckboxRendered;

  final int continuationIndent;
  final bool taskCheckboxRendered;
  final StringBuffer buffer = StringBuffer();
  bool trimLeadingWhitespace;
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience Function
// ─────────────────────────────────────────────────────────────────────────────

/// Converts a markdown string to ANSI-styled terminal text.
///
/// This is a convenience function that parses the markdown and renders it
/// using [AnsiRenderer].
///
/// ```dart
/// final styled = markdownToAnsi('''
/// # Welcome
///
/// This is **bold** and *italic*.
///
/// - Item 1
/// - Item 2
/// ''');
///
/// print(styled);
/// ```
String markdownToAnsi(String markdown, {AnsiRendererOptions? options}) {
  final nodes = markdown_backend.parseMarkdownNodes(markdown);
  return AnsiRenderer(options: options).render(nodes);
}
