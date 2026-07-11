import 'package:markdown/markdown.dart';

import '../../style/style.dart';
import '../../style/color.dart';
import 'backend.dart' as markdown_backend;
import 'html_context.dart';
import 'options.dart';
import 'render_context.dart';
import 'headings.dart';
import 'lists.dart';
import 'code_block.dart' show startCodeBlock, endCodeBlock;
import 'hr.dart' show renderHorizontalRule;
import 'tables.dart' show renderTable;
import 'images.dart' show renderImage;

/// Renders markdown to ANSI-styled terminal output using standalone functions.
///
/// This is the new generation renderer that delegates all element rendering
/// to focused, independently-testable functions in separate files.
///
/// Unlike [AnsiRenderer], this renderer uses [MarkdownRenderContext] with
/// public state, making it easy to extend, customize, and maintain.
///
/// ```dart
/// final result = MarkdownRenderer().renderToAnsi('''
/// # Hello
/// **bold** and *italic*.
/// ''');
/// ```
class MarkdownRenderer implements NodeVisitor {
  MarkdownRenderer({AnsiRendererOptions? options})
      : _options = options ?? const AnsiRendererOptions();

  final AnsiRendererOptions _options;
  late final MarkdownRenderContext _ctx = MarkdownRenderContext(
    options: _options,
    styleToAnsi: _styleToAnsiOpen,
    headingStyleOf: (tag) => headingStyle(_ctx, tag),
  );


  // ─── Public API ────────────────────────────────────────────────────

  /// Renders a markdown string to ANSI-styled text.
  String renderToAnsi(String markdown) {
    final nodes = markdown_backend.parseMarkdownNodes(markdown);
    return render(nodes);
  }

  /// Renders parsed markdown nodes to ANSI-styled text.
  String render(List<Node> nodes) {
    _ctx.buffer.clear();
    _ctx.elementStack.clear();
    _ctx.listCounters.clear();
    _ctx.listItemStack.clear();
    _ctx.listDepth = 0;
    _ctx.inBlockquote = false;
    _ctx.blockquoteDepth = 0;
    _ctx.lastWasBlock = false;
    _ctx.pendingLinkUrl = null;
    _ctx.detailsStack.clear();
    _ctx.tableHeaders.clear();
    _ctx.tableRows.clear();
    _ctx.tableAlignments.clear();
    _ctx.currentTableRow.clear();
    _ctx.currentCellBuffer.clear();
    _ctx.inTableHeader = false;
    _ctx.inTableCell = false;
    _ctx.inCodeBlock = false;
    _ctx.codeBlockLanguage = null;
    _ctx.inParagraph = false;
    _ctx.paragraphBuffer.clear();
    _ctx.textStyleActive = false;
    _ctx.activeBuffer = _ctx.buffer;

    for (final node in nodes) {
      node.accept(this);
    }

    return _ctx.buffer.toString();
  }

  // ─── NodeVisitor implementation ────────────────────────────────────

  @override
  void visitText(Text text) {
    var content = text.text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    // Decode HTML entities
    content = _ctx.htmlUnescape.convert(content);

    if (_ctx.inParagraph) {
      _ctx.paragraphBuffer.write(content);
    } else {
      _ctx.activeBuffer.write(content);
    }
  }

  @override
  bool visitElementBefore(Element element) {
    _ctx.elementStack.add(element);

    switch (element.tag) {
      // ─── Headings ──────────────────────────────────────────────
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        _ensureNewline();
        renderHeading(_ctx, element.tag);
        return true;

      // ─── Paragraphs ────────────────────────────────────────────
      case 'p':
        _ensureNewline();
        _ctx.inParagraph = true;
        _ctx.paragraphBuffer.clear();
        return true;

      // ─── Blockquotes ───────────────────────────────────────────
      case 'blockquote':
        _ensureNewline();
        _ctx.inBlockquote = true;
        _ctx.blockquoteDepth++;
        renderWriteBlockquotePrefix(_ctx);
        return true;

      // ─── Code blocks ───────────────────────────────────────────
      case 'pre':
        startCodeBlock(_ctx, element);
        return true;

      // ─── Lists ─────────────────────────────────────────────────
      case 'ul':
        _ensureNewline();
        _ctx.listDepth++;
        return true;

      case 'ol':
        _ensureNewline();
        _ctx.listDepth++;
        _ctx.listCounters.add(1);
        return true;

      case 'li':
        renderStartListItem(_ctx, element);
        return true;

      // ─── Horizontal rules ──────────────────────────────────────
      case 'hr':
        renderHorizontalRule(_ctx);
        return false;

      // ─── Details / Summary ─────────────────────────────────────
      case 'details':
        final isOpen = element.attributes['open'] != null;
        _ctx.detailsStack.add(DetailsContext(expanded: isOpen));
        return true;

      case 'summary':
        if (_ctx.detailsStack.isNotEmpty) {
          _ctx.detailsStack.last.inSummary = true;
        }
        return true;

      // ─── Tables ────────────────────────────────────────────────
      case 'table':
        _ensureNewline();
        _ctx.tableHeaders.clear();
        _ctx.tableRows.clear();
        _ctx.tableAlignments.clear();
        _ctx.activeBuffer = _ctx.buffer;
        return true;

      case 'thead':
        _ctx.inTableHeader = true;
        return true;

      case 'tbody':
        _ctx.inTableHeader = false;
        return true;

      case 'tr':
        _ctx.currentTableRow.clear();
        return true;

      case 'th':
      case 'td':
        _ctx.inTableCell = true;
        _ctx.currentCellBuffer.clear();
        _ctx.activeBuffer = _ctx.currentCellBuffer;
        return true;

      // ─── Inline elements ───────────────────────────────────────
      case 'em':
        _startTextStyle(_getEmphasisStyle());
        return true;

      case 'strong':
        _startTextStyle(_getStrongStyle());
        return true;

      case 'code':
        _startTextStyle(_getCodeStyle());
        return true;

      case 'a':
        _ctx.pendingLinkUrl = element.attributes['href'];
        _startTextStyle(_getLinkStyle());
        return true;

      case 'del':
        _startTextStyle(_getStrikethroughStyle());
        return true;

      case 'u':
      case 'mark':
        // Styled inline - handled generically
        return true;

      case 'br':
        _ctx.buffer.write('\n');
        return false;

      case 'img':
        renderImage(_ctx, element);
        return false;

      case 'input':
        final checked = element.attributes['type'] == 'checkbox' &&
            element.attributes.containsKey('checked');
        _ctx.buffer.write(
          checked ? _ctx.options.checkboxChecked : _ctx.options.checkboxUnchecked,
        );
        return false;

      default:
        return true;
    }
  }

  @override
  void visitElementAfter(Element element) {
    _ctx.elementStack.removeLast();

    switch (element.tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        endHeading(_ctx);
        _ctx.buffer.write('\n');
        _ctx.lastWasBlock = true;
        break;

      case 'p':
        _endTextStyle();
        if (_ctx.inParagraph && _ctx.options.width != null) {
          final content = _ctx.paragraphBuffer.toString();
          _ctx.paragraphBuffer.clear();
          _ctx.inParagraph = false;
          if (content.isNotEmpty) {
            var effectiveWidth = _ctx.options.width!;
            if (_ctx.inBlockquote) {
              effectiveWidth -= _ctx.blockquoteDepth * 2;
            }
            if (effectiveWidth > 0) {
              final wrapped = _wrapText(content, effectiveWidth);
              _ctx.activeBuffer.write(wrapped);
            } else {
              _ctx.activeBuffer.write(content);
            }
          }
        }
        _ctx.buffer.write('\n');
        _ctx.lastWasBlock = true;
        break;

      case 'blockquote':
        _ctx.blockquoteDepth--;
        if (_ctx.blockquoteDepth <= 0) {
          _ctx.inBlockquote = false;
        }
        _ctx.lastWasBlock = true;
        break;

      case 'pre':
        endCodeBlock(_ctx);
        break;

      case 'ul':
        _ctx.listDepth--;
        if (_ctx.listDepth <= 0) {
          _ctx.listDepth = 0;
        }
        break;

      case 'ol':
        _ctx.listDepth--;
        _ctx.listCounters.removeLast();
        break;

      case 'li':
        renderFlushCurrentListItem(_ctx);
        break;

      case 'details':
        if (_ctx.detailsStack.isNotEmpty) {
          _ctx.detailsStack.removeLast();
        }
        break;

      case 'summary':
        if (_ctx.detailsStack.isNotEmpty) {
          _ctx.detailsStack.last.inSummary = false;
        }
        break;

      case 'table':
        renderTable(_ctx);
        break;

      case 'thead':
        _ctx.inTableHeader = false;
        break;

      case 'tr':
        if (_ctx.inTableHeader) {
          _ctx.tableHeaders.addAll(
            _ctx.currentTableRow.map((e) => e.trim()),
          );
        } else {
          _ctx.tableRows.add(
            _ctx.currentTableRow.map((e) => e.trim()).toList(),
          );
        }
        break;

      case 'th':
      case 'td':
        _ctx.inTableCell = false;
        _ctx.currentTableRow.add(_ctx.currentCellBuffer.toString());
        _ctx.activeBuffer = _ctx.buffer;
        break;

      case 'em':
      case 'strong':
      case 'code':
      case 'del':
      case 'u':
      case 'mark':
        _endTextStyle();
        break;

      case 'a':
        _endTextStyle();
        if (_ctx.pendingLinkUrl != null && _ctx.options.hyperlinks) {
          _ctx.buffer.write('\x1b]8;;${_ctx.pendingLinkUrl}\x1b\\');
          _ctx.pendingLinkUrl = null;
        }
        break;
    }
  }

  // ─── Style helpers ────────────────────────────────────────────────

  Style _getEmphasisStyle() =>
      _ctx.options.emphasisStyle ?? _defaultEmphasisStyle();
  Style _getStrongStyle() =>
      _ctx.options.strongStyle ?? _defaultStrongStyle();
  Style _getCodeStyle() =>
      _ctx.options.codeStyle ?? _defaultCodeStyle();
  Style _getLinkStyle() =>
      _ctx.options.linkStyle ?? _defaultLinkStyle();
  Style _getStrikethroughStyle() =>
      _ctx.options.strikethroughStyle ?? _defaultStrikethroughStyle();

  // ─── Inline style helpers ─────────────────────────────────────
  Style? _currentInlineStyle;

  void _startTextStyle(Style style) {
    _currentInlineStyle = style;
    _ctx.buffer.write(_styleToAnsiOpen(style));
  }

  void _endTextStyle() {
    if (_currentInlineStyle != null) {
      _ctx.buffer.write(_ansiReset);
      _currentInlineStyle = null;
    }
  }

  // ─── Text wrapping ────────────────────────────────────────────
  String _wrapText(String text, int width) {
    // Simple word-wrap at width
    if (text.length <= width) return text;
    
    final result = StringBuffer();
    var lineLength = 0;
    final words = text.split(' ');
    
    for (final word in words) {
      if (lineLength + word.length + 1 > width) {
        result.write('\n');
        result.write(word);
        lineLength = word.length;
      } else {
        if (lineLength > 0) {
          result.write(' ');
          lineLength++;
        }
        result.write(word);
        lineLength += word.length;
      }
    }
    
    return result.toString();
  }

  // ─── Internal helpers ─────────────────────────────────────────────

  void _ensureNewline() {
    if (_ctx.buffer.length > 0 &&
        !_ctx.buffer.toString().endsWith('\n')) {
      _ctx.buffer.write('\n');
    }
  }

  static const _ansiReset = '\x1b[0m';

  static String _styleToAnsiOpen(Style style) {
    final codes = <int>[];
    if (style.isBold) codes.add(1);
    if (style.isDim) codes.add(2);
    if (style.isItalic) codes.add(3);
    if (style.isUnderline) codes.add(4);
    if (style.isBlink) codes.add(5);
    if (style.isInverse) codes.add(7);
    if (style.isStrikethrough) codes.add(9);
    if (codes.isEmpty) return '';
    return '\x1b[${codes.join(';')}m';
  }
}

// ─── Default style functions (standalone) ───────────────────────────────

Style _defaultEmphasisStyle() => Style().italic();
Style _defaultStrongStyle() => Style().bold();
Style _defaultCodeStyle() =>
    Style().foreground(Colors.brightYellow).background(Colors.gray800);
Style _defaultLinkStyle() =>
    Style().foreground(Colors.blue).underline();
Style _defaultStrikethroughStyle() => Style().strikethrough().dim();
