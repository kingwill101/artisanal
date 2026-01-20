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

import 'package:html_unescape/html_unescape.dart';
import 'package:markdown/markdown.dart';

import '../style/border.dart' as style_border;
import '../style/style.dart';
import '../style/color.dart';
import '../tui/bubbles/components/table.dart' as table_component;
import '../uv/wrap.dart' as uv_wrap;
import 'syntax_highlighter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

/// Configuration options for ANSI markdown rendering.
///
/// Provides customizable styles for different markdown elements and
/// various rendering options like terminal width and hyperlink support.
class AnsiRendererOptions {
  /// Creates renderer options with the given settings.
  const AnsiRendererOptions({
    this.width,
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.h4Style,
    this.h5Style,
    this.h6Style,
    this.emphasisStyle,
    this.strongStyle,
    this.codeStyle,
    this.codeBlockStyle,
    this.linkStyle,
    this.blockquoteStyle,
    this.blockquoteBorderColor,
    this.strikethroughStyle,
    this.bulletChar = '\u2022',
    this.hyperlinks = true,
    this.hrChar = '\u2500',
    this.hrWidth,
    this.checkboxChecked = '\u2611',
    this.checkboxUnchecked = '\u2610',
    this.listIndent = 2,
    this.codeBlockBorder = true,
    this.tableBorder,
    this.tableHeaderStyle,
    this.tableCellStyle,
    this.tableBorderStyle,
    this.syntaxHighlighting = true,
    this.syntaxTheme,
    this.codeBlockBorderStyle,
  });

  /// Terminal width for text wrapping. If null, no wrapping is applied.
  final int? width;

  /// Style for H1 headings.
  final Style? h1Style;

  /// Style for H2 headings.
  final Style? h2Style;

  /// Style for H3 headings.
  final Style? h3Style;

  /// Style for H4 headings.
  final Style? h4Style;

  /// Style for H5 headings.
  final Style? h5Style;

  /// Style for H6 headings.
  final Style? h6Style;

  /// Style for emphasized (italic) text.
  final Style? emphasisStyle;

  /// Style for strong (bold) text.
  final Style? strongStyle;

  /// Style for inline code.
  final Style? codeStyle;

  /// Style for code blocks.
  final Style? codeBlockStyle;

  /// Style for links.
  final Style? linkStyle;

  /// Style for blockquote text.
  final Style? blockquoteStyle;

  /// Color for blockquote border.
  final Color? blockquoteBorderColor;

  /// Style for strikethrough text.
  final Style? strikethroughStyle;

  /// Character used for bullet points.
  final String bulletChar;

  /// Whether to use OSC 8 hyperlinks for links.
  final bool hyperlinks;

  /// Character used for horizontal rules.
  final String hrChar;

  /// Width of horizontal rules. If null, uses [width] or 40.
  final int? hrWidth;

  /// Character for checked checkboxes.
  final String checkboxChecked;

  /// Character for unchecked checkboxes.
  final String checkboxUnchecked;

  /// Number of spaces for list indentation per level.
  final int listIndent;

  /// Whether to draw a border around code blocks.
  final bool codeBlockBorder;

  /// Border style for tables. If null, uses rounded borders.
  final style_border.Border? tableBorder;

  /// Style for table header cells.
  final Style? tableHeaderStyle;

  /// Style for table data cells.
  final Style? tableCellStyle;

  /// Style for table borders.
  final Style? tableBorderStyle;

  /// Whether to apply syntax highlighting to fenced code blocks.
  ///
  /// When enabled, code blocks with a language specifier (e.g., ```dart)
  /// will be syntax highlighted using the [syntaxTheme].
  final bool syntaxHighlighting;

  /// Theme for syntax highlighting.
  ///
  /// If null, uses [ChromaTheme.dark]. Available themes include:
  /// - [ChromaTheme.dark] - Default dark theme
  /// - [ChromaTheme.light] - Light terminal theme
  /// - [ChromaTheme.monokai] - Monokai-inspired
  /// - [ChromaTheme.dracula] - Dracula-inspired
  /// - [ChromaTheme.github] - GitHub-inspired (light)
  final ChromaTheme? syntaxTheme;

  /// Border style for code blocks.
  ///
  /// If null, uses rounded borders (╭─╮│╰─╯). Available styles include:
  /// - [style_border.Border.rounded] - Rounded corners (default)
  /// - [style_border.Border.normal] - Sharp corners (┌─┐│└─┘)
  /// - [style_border.Border.thick] - Heavy lines (┏━┓┃┗━┛)
  /// - [style_border.Border.double] - Double lines (╔═╗║╚═╝)
  /// - [style_border.Border.ascii] - ASCII compatible (+--+||+--+)
  final style_border.Border? codeBlockBorderStyle;

  /// Creates a copy with the given fields replaced.
  AnsiRendererOptions copyWith({
    int? width,
    Style? h1Style,
    Style? h2Style,
    Style? h3Style,
    Style? h4Style,
    Style? h5Style,
    Style? h6Style,
    Style? emphasisStyle,
    Style? strongStyle,
    Style? codeStyle,
    Style? codeBlockStyle,
    Style? linkStyle,
    Style? blockquoteStyle,
    Color? blockquoteBorderColor,
    Style? strikethroughStyle,
    String? bulletChar,
    bool? hyperlinks,
    String? hrChar,
    int? hrWidth,
    String? checkboxChecked,
    String? checkboxUnchecked,
    int? listIndent,
    bool? codeBlockBorder,
    style_border.Border? tableBorder,
    Style? tableHeaderStyle,
    Style? tableCellStyle,
    Style? tableBorderStyle,
    bool? syntaxHighlighting,
    ChromaTheme? syntaxTheme,
    style_border.Border? codeBlockBorderStyle,
  }) {
    return AnsiRendererOptions(
      width: width ?? this.width,
      h1Style: h1Style ?? this.h1Style,
      h2Style: h2Style ?? this.h2Style,
      h3Style: h3Style ?? this.h3Style,
      h4Style: h4Style ?? this.h4Style,
      h5Style: h5Style ?? this.h5Style,
      h6Style: h6Style ?? this.h6Style,
      emphasisStyle: emphasisStyle ?? this.emphasisStyle,
      strongStyle: strongStyle ?? this.strongStyle,
      codeStyle: codeStyle ?? this.codeStyle,
      codeBlockStyle: codeBlockStyle ?? this.codeBlockStyle,
      linkStyle: linkStyle ?? this.linkStyle,
      blockquoteStyle: blockquoteStyle ?? this.blockquoteStyle,
      blockquoteBorderColor:
          blockquoteBorderColor ?? this.blockquoteBorderColor,
      strikethroughStyle: strikethroughStyle ?? this.strikethroughStyle,
      bulletChar: bulletChar ?? this.bulletChar,
      hyperlinks: hyperlinks ?? this.hyperlinks,
      hrChar: hrChar ?? this.hrChar,
      hrWidth: hrWidth ?? this.hrWidth,
      checkboxChecked: checkboxChecked ?? this.checkboxChecked,
      checkboxUnchecked: checkboxUnchecked ?? this.checkboxUnchecked,
      listIndent: listIndent ?? this.listIndent,
      codeBlockBorder: codeBlockBorder ?? this.codeBlockBorder,
      tableBorder: tableBorder ?? this.tableBorder,
      tableHeaderStyle: tableHeaderStyle ?? this.tableHeaderStyle,
      tableCellStyle: tableCellStyle ?? this.tableCellStyle,
      tableBorderStyle: tableBorderStyle ?? this.tableBorderStyle,
      syntaxHighlighting: syntaxHighlighting ?? this.syntaxHighlighting,
      syntaxTheme: syntaxTheme ?? this.syntaxTheme,
      codeBlockBorderStyle: codeBlockBorderStyle ?? this.codeBlockBorderStyle,
    );
  }
}

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

  /// Output buffer.
  final StringBuffer _buffer = StringBuffer();

  /// Stack of active elements for context tracking.
  final List<Element> _elementStack = [];

  /// Current list nesting depth.
  int _listDepth = 0;

  /// Current list item index (for ordered lists).
  final List<int> _listCounters = [];

  /// Whether we're inside a blockquote.
  bool _inBlockquote = false;

  /// Current blockquote nesting depth.
  int _blockquoteDepth = 0;

  /// Whether the last output was a block element (needs trailing newline).
  bool _lastWasBlock = false;

  /// Pending link URL for the current link element.
  String? _pendingLinkUrl;

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

  /// Whether we're inside a table.
  bool _inTable = false;

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

  /// Lazy-initialized syntax highlighter.
  SyntaxHighlighter? _syntaxHighlighter;

  /// HTML entity decoder for converting &lt; &gt; &amp; &quot; etc.
  final HtmlUnescape _htmlUnescape = HtmlUnescape();

  /// Gets or creates the syntax highlighter.
  SyntaxHighlighter get _highlighter =>
      _syntaxHighlighter ??= SyntaxHighlighter(theme: options.syntaxTheme);

  /// Renders a list of markdown nodes to ANSI-styled text.
  String render(List<Node> nodes) {
    _buffer.clear();
    _elementStack.clear();
    _listDepth = 0;
    _listCounters.clear();
    _inBlockquote = false;
    _blockquoteDepth = 0;
    _lastWasBlock = false;
    _pendingLinkUrl = null;

    // Reset table state
    _tableHeaders.clear();
    _tableRows.clear();
    _tableAlignments.clear();
    _currentTableRow.clear();
    _currentCellBuffer.clear();
    _inTable = false;
    _inTableHeader = false;
    _inTableCell = false;
    _inCodeBlock = false;
    _codeBlockLanguage = null;
    _inParagraph = false;
    _paragraphBuffer.clear();

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
    // Decode HTML entities (e.g., &lt; &gt; &amp; &quot; &#39;)
    var content = _htmlUnescape.convert(text.text);

    // Apply blockquote prefix if inside a blockquote
    if (_inBlockquote && content.contains('\n')) {
      content = _applyBlockquotePrefix(content);
    }

    // Apply syntax highlighting for code blocks
    if (_inCodeBlock) {
      if (options.syntaxHighlighting && _codeBlockLanguage != null) {
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
    }

    // If inside a table cell, write to cell buffer instead
    if (_inTableCell) {
      _currentCellBuffer.write(content);
    } else if (_inParagraph && options.width != null && !_inCodeBlock) {
      // Buffer paragraph content for wrapping
      _paragraphBuffer.write(content);
    } else {
      _buffer.write(content);
    }
  }

  @override
  bool visitElementBefore(Element element) {
    _elementStack.add(element);

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
        return true;

      case 'blockquote':
        _ensureNewline();
        _inBlockquote = true;
        _blockquoteDepth++;
        return true;

      case 'pre':
        _ensureNewline();
        _startCodeBlock(element);
        return true;

      case 'ul':
        if (_listDepth == 0) _ensureNewline();
        _listDepth++;
        return true;

      case 'ol':
        if (_listDepth == 0) _ensureNewline();
        _listDepth++;
        _listCounters.add(
          int.tryParse(element.attributes['start'] ?? '1') ?? 1,
        );
        return true;

      case 'li':
        _startListItem(element);
        return true;

      case 'hr':
        _ensureNewline();
        _renderHorizontalRule();
        return false; // No children to visit

      case 'table':
        _ensureNewline();
        _inTable = true;
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
              _buffer.write(wrapped);
            } else {
              _buffer.write(content);
            }
          }
        }
        _buffer.write('\n');
        _lastWasBlock = true;
        break;

      case 'blockquote':
        _blockquoteDepth--;
        if (_blockquoteDepth == 0) {
          _inBlockquote = false;
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
        _buffer.write('\n');
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

      case 'table':
        _renderTable();
        _inTable = false;
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
    // Add indentation based on nesting level
    final indent = ' ' * ((_listDepth - 1) * options.listIndent);
    _buffer.write(indent);

    // Determine if this is an ordered or unordered list item
    final parent = _findParentList();
    if (parent?.tag == 'ol') {
      // Ordered list
      final counter = _listCounters.isNotEmpty ? _listCounters.last : 1;
      _buffer.write('$counter. ');
      if (_listCounters.isNotEmpty) {
        _listCounters[_listCounters.length - 1] = counter + 1;
      }
    } else {
      // Unordered list
      _buffer.write('${options.bulletChar} ');
    }
  }

  Element? _findParentList() {
    for (var i = _elementStack.length - 1; i >= 0; i--) {
      if (_elementStack[i].tag == 'ul' || _elementStack[i].tag == 'ol') {
        return _elementStack[i];
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Blockquote Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  void _writeBlockquotePrefix() {
    final color =
        options.blockquoteBorderColor ?? _defaultBlockquoteBorderColor();
    final colorSeq = color.toAnsi(ColorProfile.trueColor);
    final prefix = '\u2502 ' * _blockquoteDepth;
    _buffer.write('$colorSeq$prefix$_ansiReset');

    // Apply blockquote text style
    final style = options.blockquoteStyle ?? _defaultBlockquoteStyle();
    _buffer.write(_styleToAnsiOpen(style));
  }

  String _applyBlockquotePrefix(String text) {
    final lines = text.split('\n');
    final color =
        options.blockquoteBorderColor ?? _defaultBlockquoteBorderColor();
    final colorSeq = color.toAnsi(ColorProfile.trueColor);
    final prefix = '\u2502 ' * _blockquoteDepth;

    return lines
        .asMap()
        .entries
        .map((entry) {
          final i = entry.key;
          final line = entry.value;
          if (i == 0) return line; // First line already has prefix
          if (line.isEmpty && i == lines.length - 1) return line;
          return '$colorSeq$prefix$_ansiReset$line';
        })
        .join('\n');
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
      _buffer.write(
        '\n$borderSeq${border.bottomLeft}${border.bottom}${border.bottom}${border.bottom}$_ansiReset\n',
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
          if (i == 0)
            return line; // First line already has prefix from _startCodeBlock
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

    // Render as [Image: alt] (url) in terminal
    final style = Style().dim();
    _buffer.write(_styleToAnsiOpen(style));
    _buffer.write('[Image: $alt]');
    if (src.isNotEmpty) {
      _buffer.write(' ($src)');
    }
    _buffer.write(_ansiReset);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Link Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  void _startLink() {
    final style = options.linkStyle ?? _defaultLinkStyle();
    _buffer.write(_styleToAnsiOpen(style));

    // Add OSC 8 hyperlink if enabled and URL is available
    if (options.hyperlinks && _pendingLinkUrl != null) {
      _buffer.write('\x1b]8;;${_pendingLinkUrl!}\x1b\\');
    }
  }

  void _endLink() {
    // Close OSC 8 hyperlink if enabled
    if (options.hyperlinks && _pendingLinkUrl != null) {
      _buffer.write('\x1b]8;;\x1b\\');
    }

    _buffer.write(_ansiReset);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Inline Style Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  void _startInlineStyle(Style style) {
    _buffer.write(_styleToAnsiOpen(style));
  }

  void _endInlineStyle() {
    _buffer.write(_ansiReset);
  }

  Style _getEmphasisStyle() => options.emphasisStyle ?? _defaultEmphasisStyle();
  Style _getStrongStyle() => options.strongStyle ?? _defaultStrongStyle();
  Style _getCodeStyle() => options.codeStyle ?? _defaultCodeStyle();
  Style _getStrikethroughStyle() =>
      options.strikethroughStyle ?? _defaultStrikethroughStyle();

  // ─────────────────────────────────────────────────────────────────────────────
  // Utility Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  bool _isInsidePreBlock() {
    return _elementStack.any((e) => e.tag == 'pre');
  }

  void _ensureNewline() {
    if (_buffer.isNotEmpty && !_buffer.toString().endsWith('\n')) {
      _buffer.write('\n');
    }
    if (_lastWasBlock) {
      _buffer.write('\n');
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
      buffer.write(fg.toAnsi(ColorProfile.trueColor));
    }

    // Add background color
    final bg = style.getBackground;
    if (bg != null) {
      buffer.write(bg.toAnsi(ColorProfile.trueColor, background: true));
    }

    return buffer.toString();
  }
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
  final document = Document(extensionSet: ExtensionSet.gitHubFlavored);
  final nodes = document.parse(markdown);
  return AnsiRenderer(options: options).render(nodes);
}
