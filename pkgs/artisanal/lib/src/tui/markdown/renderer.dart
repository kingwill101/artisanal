import 'dart:typed_data';

import 'package:markdown/markdown.dart';

import '../../style/style.dart';
import '../../style/color.dart';
import 'backend.dart' as markdown_backend;
import 'html_context.dart';
import 'options.dart';
import 'render_context.dart';
import 'syntax_highlighter.dart';
import 'headings.dart';
import 'lists.dart';
import 'code_block.dart'
    show startCodeBlock, endCodeBlock, applyCodeBlockPrefix;
import 'hr.dart' show renderHorizontalRule;
import 'tables.dart' show renderTable;
import 'images.dart' show renderImage;
import 'package:ultraviolet/rendering.dart' as uv_wrap;
import 'image_bytes_loader_stub.dart'
    if (dart.library.io) 'image_bytes_loader_io.dart'
    as image_loader;

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
  final List<bool> _handledBlockStack = [];

  // ─── Public API ────────────────────────────────────────────────────

  /// Renders a markdown string to ANSI-styled text.
  /// Renders a markdown string to ANSI-styled text.
  ///
  /// If [options.renderImages] is true, pre-download images first using
  /// [preloadImages] and pass [imageCache] for terminal-protocol rendering.
  String renderToAnsi(String markdown, {Map<String, Uint8List>? imageCache}) {
    final nodes = markdown_backend.parseMarkdownNodes(markdown);
    return render(nodes, imageCache: imageCache);
  }

  /// Renders parsed markdown nodes to ANSI-styled text.
  String render(List<Node> nodes, {Map<String, Uint8List>? imageCache}) {
    _ctx.buffer.clear();
    _ctx.activeBuffer = _ctx.buffer;
    _ctx.elementStack.clear();
    _ctx.listDepth = 0;
    _ctx.listCounters.clear();
    _ctx.listItemStack.clear();
    _ctx.inBlockquote = false;
    _ctx.blockquoteDepth = 0;
    _ctx.lastWasBlock = false;
    _ctx.pendingLinkUrl = null;
    _ctx.imageAltText = null;
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
    _ctx.syntaxHighlighter = null;
    _ctx.inParagraph = false;
    _ctx.paragraphBuffer.clear();
    _ctx.textStyleActive = false;
    _inlineStyleDepth = 0;
    _handledBlockStack.clear();
    if (imageCache != null) {
      _ctx.imageCache.addAll(imageCache);
    }

    for (final node in nodes) {
      node.accept(this);
    }

    var result = _ctx.buffer.toString();
    while (result.endsWith('\n\n')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Scans markdown for image URLs and downloads them in parallel.
  ///
  /// Returns a map of URL → image bytes. Pass the result to [renderToAnsi]
  /// or [render] when [AnsiRendererOptions.renderImages] is enabled.
  static Future<Map<String, Uint8List>> preloadImages(String markdown) async {
    final nodes = markdown_backend.parseMarkdownNodes(markdown);
    final urls = <String>[];
    _collectImageUrls(nodes, urls);

    if (urls.isEmpty) return {};

    final results = await Future.wait(
      urls.map(image_loader.loadMarkdownImageBytes),
    );
    final cache = <String, Uint8List>{};
    for (var i = 0; i < urls.length; i++) {
      if (results[i] != null) {
        cache[urls[i]] = results[i]!;
      }
    }
    return cache;
  }

  static void _collectImageUrls(List<Node> nodes, List<String> urls) {
    for (final node in nodes) {
      if (node is Element && node.tag == 'img') {
        final src = node.attributes['src'];
        if (src != null && src.isNotEmpty) {
          urls.add(src);
        }
      }
      if (node is Element && node.children != null) {
        _collectImageUrls(node.children!, urls);
      }
    }
  }

  // ─── NodeVisitor implementation ────────────────────────────────────

  @override
  void visitText(Text text) {
    if (_insideCollapsedDetailsBody) return;

    var content = text.text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Decode HTML entities
    content = _ctx.htmlUnescape.convert(content);

    if (!_ctx.inCodeBlock && _ctx.listItemStack.isNotEmpty) {
      final listItem = _ctx.listItemStack.last;
      if (listItem.trimLeadingWhitespace) {
        content = content.replaceFirst(RegExp(r'^\s+'), '');
        if (content.isNotEmpty) {
          listItem.trimLeadingWhitespace = false;
        }
      }
    }

    if (_ctx.inBlockquote && !_ctx.inParagraph && content.contains('\n')) {
      content = renderApplyBlockquotePrefixAll(_ctx, content);
    }

    if (_ctx.inCodeBlock) {
      if (_shouldSyntaxHighlight(content, _ctx.codeBlockLanguage)) {
        content = _highlighter.highlightCode(
          content,
          language: _ctx.codeBlockLanguage,
        );
      }
      if (_ctx.options.codeBlockBorder && content.contains('\n')) {
        content = applyCodeBlockPrefix(_ctx, content);
      }
      _outputBuffer.write(content);
      return;
    }

    if (_ctx.inParagraph) {
      _ctx.paragraphBuffer.write(content);
    } else {
      _outputBuffer.write(content);
    }
  }

  @override
  bool visitElementBefore(Element element) {
    _ctx.elementStack.add(element);
    _handledBlockStack.add(false);

    final handlerOutput = _renderCustomBlock(element);
    if (handlerOutput != null) {
      _handledBlockStack[_handledBlockStack.length - 1] = true;
      _outputBuffer.write(handlerOutput);
      return false;
    }

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
        if (_ctx.inBlockquote) {
          renderWriteBlockquotePrefix(_ctx);
        }
        _ctx.inParagraph = true;
        _ctx.paragraphBuffer.clear();
        _startBodyTextStyle();
        return true;

      // ─── Blockquotes ───────────────────────────────────────────
      case 'blockquote':
        _ensureNewline();
        _ctx.inBlockquote = true;
        _ctx.blockquoteDepth++;
        return true;

      // ─── Code blocks ───────────────────────────────────────────
      case 'pre':
        startCodeBlock(_ctx, element);
        return true;

      // ─── Lists ─────────────────────────────────────────────────
      case 'ul':
        if (_ctx.listDepth == 0) {
          _ensureNewline();
        } else {
          renderFlushCurrentListItem(_ctx);
          _ctx.buffer.write('\n');
        }
        _ctx.listDepth++;
        return true;

      case 'ol':
        if (_ctx.listDepth == 0) {
          _ensureNewline();
        } else {
          renderFlushCurrentListItem(_ctx);
          _ctx.buffer.write('\n');
        }
        _ctx.listDepth++;
        final start = int.tryParse(element.attributes['start'] ?? '1') ?? 1;
        _ctx.listCounters.add(start);
        return true;

      case 'li':
        renderStartListItem(_ctx, element);
        _startBodyTextStyle();
        return true;

      // ─── Horizontal rules ──────────────────────────────────────
      case 'hr':
        renderHorizontalRule(_ctx);
        return false;

      // ─── Details / Summary ─────────────────────────────────────
      case 'details':
        _ensureNewline();
        if (_ctx.inBlockquote) {
          renderWriteBlockquotePrefix(_ctx);
        }
        final isOpen = element.attributes['open'] != null;
        _ctx.detailsStack.add(DetailsContext(expanded: isOpen));
        return true;

      case 'summary':
        if (_ctx.detailsStack.isNotEmpty) {
          final details = _ctx.detailsStack.last;
          details.inSummary = true;
          _outputBuffer.write(details.expanded ? '\u25be ' : '\u25b8 ');
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
        _startInlineStyle(_getEmphasisStyle());
        return true;

      case 'strong':
        _startInlineStyle(_getStrongStyle());
        return true;

      case 'code':
        if (!_isInsidePreBlock()) {
          _startInlineStyle(_getCodeStyle());
        }
        return true;

      case 'a':
        _ctx.pendingLinkUrl = element.attributes['href'];
        _startInlineStyle(_getLinkStyle());
        if (_ctx.options.hyperlinks && _ctx.pendingLinkUrl != null) {
          _outputBuffer.write('\x1b]8;;${_ctx.pendingLinkUrl}\x1b\\');
        }
        return true;

      case 'del':
        _startInlineStyle(_getStrikethroughStyle());
        return true;

      case 'u':
      case 'mark':
        // Styled inline - handled generically
        return true;

      case 'br':
        if (_ctx.inParagraph) {
          _ctx.paragraphBuffer.write('\n');
        } else {
          _outputBuffer.write('\n');
        }
        if (_ctx.inBlockquote && !_ctx.inParagraph) {
          renderWriteBlockquotePrefix(_ctx);
        }
        return false;

      case 'img':
        renderImage(_ctx, element);
        return false;

      case 'input':
        if (_ctx.listItemStack.isNotEmpty &&
            _ctx.listItemStack.last.taskCheckboxRendered) {
          return false;
        }
        final checked =
            element.attributes['type'] == 'checkbox' &&
            element.attributes.containsKey('checked');
        _outputBuffer.write(
          checked
              ? _ctx.options.checkboxChecked
              : _ctx.options.checkboxUnchecked,
        );
        return false;

      default:
        return true;
    }
  }

  @override
  void visitElementAfter(Element element) {
    _ctx.elementStack.removeLast();
    final handled = _handledBlockStack.removeLast();
    if (handled) return;

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
        _endBodyTextStyle();
        if (_ctx.inParagraph) {
          var content = _ctx.paragraphBuffer.toString();
          _ctx.paragraphBuffer.clear();
          _ctx.inParagraph = false;
          if (content.isNotEmpty) {
            if (_ctx.options.width != null) {
              var effectiveWidth = _ctx.options.width!;
              if (_ctx.inBlockquote) {
                effectiveWidth -= _ctx.blockquoteDepth * 2;
              }
              if (effectiveWidth > 0) {
                content = _wrapText(content, effectiveWidth);
              }
            }
            if (_ctx.inBlockquote) {
              content = renderApplyBlockquotePrefix(_ctx, content);
            }
            _outputBuffer.write(content);
          }
        }
        _outputBuffer.write('\n');
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
          _ctx.lastWasBlock = true;
        }
        break;

      case 'ol':
        _ctx.listDepth--;
        if (_ctx.listCounters.isNotEmpty) {
          _ctx.listCounters.removeLast();
        }
        if (_ctx.listDepth <= 0) {
          _ctx.listDepth = 0;
          _ctx.lastWasBlock = true;
        }
        break;

      case 'li':
        _endBodyTextStyle();
        renderFlushCurrentListItem(_ctx);
        if (_ctx.listItemStack.isNotEmpty) {
          _ctx.listItemStack.removeLast();
        }
        if (!renderHasNestedList(element)) {
          _ctx.buffer.write('\n');
        }
        break;

      case 'details':
        if (_ctx.detailsStack.isNotEmpty) {
          _ctx.detailsStack.removeLast();
        }
        _ensureNewline();
        break;

      case 'summary':
        if (_ctx.detailsStack.isNotEmpty) {
          _ctx.detailsStack.last.inSummary = false;
          _outputBuffer.write('\n');
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
          _ctx.tableHeaders.addAll(_ctx.currentTableRow.map((e) => e.trim()));
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
      case 'del':
      case 'u':
      case 'mark':
        _endInlineStyle();
        break;

      case 'code':
        if (!_isInsidePreBlock()) {
          _endInlineStyle();
        }
        break;

      case 'a':
        if (_ctx.pendingLinkUrl != null && _ctx.options.hyperlinks) {
          _outputBuffer.write('\x1b]8;;\x1b\\');
          _ctx.pendingLinkUrl = null;
        }
        _endInlineStyle();
        break;
    }
  }

  // ─── Style helpers ────────────────────────────────────────────────

  Style _getEmphasisStyle() =>
      _ctx.options.emphasisStyle ?? _defaultEmphasisStyle();
  Style _getStrongStyle() => _ctx.options.strongStyle ?? _defaultStrongStyle();
  Style _getCodeStyle() => _ctx.options.codeStyle ?? _defaultCodeStyle();
  Style _getLinkStyle() => _ctx.options.linkStyle ?? _defaultLinkStyle();
  Style _getStrikethroughStyle() =>
      _ctx.options.strikethroughStyle ?? _defaultStrikethroughStyle();

  // ─── Inline/body style helpers ────────────────────────────────────
  int _inlineStyleDepth = 0;

  void _startInlineStyle(Style style) {
    _outputBuffer.write(_styleToAnsiOpen(style));
    _inlineStyleDepth++;
  }

  void _endInlineStyle() {
    if (_inlineStyleDepth <= 0) return;
    _outputBuffer.write(_contextualReset);
    _inlineStyleDepth--;
  }

  void _startBodyTextStyle() {
    final style = _ctx.options.textStyle;
    if (style == null || _ctx.textStyleActive) return;
    _outputBuffer.write(_styleToAnsiOpen(style));
    _ctx.textStyleActive = true;
  }

  void _endBodyTextStyle() {
    if (!_ctx.textStyleActive) return;
    _outputBuffer.write(_ansiReset);
    _ctx.textStyleActive = false;
  }

  String get _contextualReset {
    if (_ctx.textStyleActive && _ctx.options.textStyle != null) {
      return '$_ansiReset${_styleToAnsiOpen(_ctx.options.textStyle!)}';
    }
    return _ansiReset;
  }

  StringBuffer get _outputBuffer {
    if (_ctx.inTableCell) return _ctx.currentCellBuffer;
    if (_ctx.inParagraph && _ctx.options.width != null && !_ctx.inCodeBlock) {
      return _ctx.paragraphBuffer;
    }
    if (_ctx.listItemStack.isNotEmpty &&
        _ctx.options.width != null &&
        !_ctx.inCodeBlock) {
      return _ctx.listItemStack.last.buffer;
    }
    return _ctx.buffer;
  }

  bool _isInsidePreBlock() =>
      _ctx.elementStack.any((element) => element.tag == 'pre');

  // ─── Text wrapping ────────────────────────────────────────────
  String _wrapText(String text, int width) {
    if (width <= 0) return text;
    return uv_wrap.wrapAnsiPreserving(text, width);
  }

  bool _shouldSyntaxHighlight(String code, String? language) {
    if (!_ctx.options.syntaxHighlighting || language == null) return false;
    final maxCodeUnits = _ctx.options.maxSyntaxHighlightCodeUnits;
    return maxCodeUnits == null || code.length <= maxCodeUnits;
  }

  SyntaxHighlighter get _highlighter {
    if (_ctx.syntaxHighlighter != null) return _ctx.syntaxHighlighter!;
    if (_ctx.options.syntaxTheme != null) {
      _ctx.syntaxHighlighter = SyntaxHighlighter(
        theme: _ctx.options.syntaxTheme,
      );
    } else {
      _ctx.syntaxHighlighter = SyntaxHighlighter.adaptive(
        hasDarkBackground: _ctx.options.hasDarkBackground,
      );
    }
    return _ctx.syntaxHighlighter!;
  }

  // ─── Internal helpers ─────────────────────────────────────────────

  void _ensureNewline() {
    final buffer = _outputBuffer;
    final hasVisibleContent = _bufferHasVisibleContent(buffer);
    if (hasVisibleContent && !buffer.toString().endsWith('\n')) {
      buffer.write('\n');
    }
    if (_ctx.lastWasBlock && !_ctx.inBlockquote) {
      if (hasVisibleContent) {
        buffer.write('\n');
      }
      _ctx.lastWasBlock = false;
    }
  }

  bool _bufferHasVisibleContent(StringBuffer buffer) {
    if (buffer.isEmpty) return false;
    return Style.stripAnsi(buffer.toString()).trim().isNotEmpty;
  }

  bool get _insideCollapsedDetailsBody {
    return _ctx.detailsStack.any((details) {
      return !details.expanded && !details.inSummary;
    });
  }

  String? _renderCustomBlock(Element element) {
    if (_options.blockHandlers.isEmpty || !_isBlockElement(element.tag)) {
      return null;
    }

    final context = MarkdownBlockContext(
      element: element,
      options: _options,
      renderMarkdown: (markdown, {int? width}) {
        final renderer = MarkdownRenderer(
          options: _options.copyWith(width: width ?? _options.width),
        );
        return renderer.renderToAnsi(markdown);
      },
    );

    for (final handler in _options.blockHandlers) {
      final output = handler(context);
      if (output != null) return output;
    }

    return null;
  }

  bool _isBlockElement(String tag) {
    return switch (tag) {
      'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6' => true,
      'p' || 'blockquote' || 'pre' || 'ul' || 'ol' || 'li' => true,
      'hr' || 'table' || 'thead' || 'tbody' || 'tfoot' || 'tr' => true,
      'th' || 'td' || 'details' || 'figure' || 'section' || 'article' => true,
      _ => false,
    };
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

    final buffer = StringBuffer();
    if (codes.isNotEmpty) {
      buffer.write('\x1b[${codes.join(';')}m');
    }

    final fg = style.getForeground;
    if (fg != null) {
      buffer.write(
        fg.toAnsi(
          ColorProfile.trueColor,
          hasDarkBackground: style.hasDarkBackground,
        ),
      );
    }

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

// ─── Default style functions (standalone) ───────────────────────────────

Style _defaultEmphasisStyle() => Style().italic();
Style _defaultStrongStyle() => Style().bold();
Style _defaultCodeStyle() =>
    Style().foreground(Colors.brightYellow).background(Colors.gray800);
Style _defaultLinkStyle() => Style().foreground(Colors.blue).underline();
Style _defaultStrikethroughStyle() => Style().strikethrough().dim();
