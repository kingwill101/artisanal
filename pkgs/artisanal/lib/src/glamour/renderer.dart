import 'package:html_unescape/html_unescape.dart';
import 'package:markdown/markdown.dart' as md;

import 'theme.dart';
import '../style/style.dart';
import '../uv/wrap.dart' as uv_wrap;

/// Renders markdown to ANSI using the Glamour theme system.
///
/// Note on blockquote nesting:
/// The markdown package creates separate blockquote elements for each `>` line,
/// so `renderStyle` normalizes the AST to merge adjacent blockquotes and
/// promote nested `>` markers into nested blockquote nodes before rendering.
class GlamourRenderer implements md.NodeVisitor {
  /// Creates a renderer with a theme and optional line width.
  GlamourRenderer({required this.theme, this.width = 80});

  /// The style theme used for rendering.
  final GlamourTheme theme;

  /// The maximum line width for word wrapping.
  final int width;

  final StringBuffer _outputBuffer = StringBuffer();
  final List<GlamourBlockContext> _blockStack = [];
  final List<GlamourPrimitiveStyle> _inlineStack = [];
  final List<String> _linkStack = [];
  final HtmlUnescape _htmlUnescape = HtmlUnescape();

  // Current render state
  final List<int> _listCounters = [];
  final List<bool> _listIsOrdered = [];
  int _lastChar = 0;

  // Syntax Highlighting

  // Table state
  final List<String> _tableHeaders = [];
  final List<List<String>> _tableRows = [];
  final List<String> _currentRow = [];
  bool _inTableHead = false;
  bool _inTableCell = false;

  /// Renders a markdown string to styled ANSI output.
  String render(List<md.Node> nodes) {
    _outputBuffer.clear();
    _blockStack.clear();
    _inlineStack.clear();
    _linkStack.clear();
    _listCounters.clear();
    _listIsOrdered.clear();
    _lastChar = 0;

    // Push document root block
    _enterBlock(theme.document, width);

    for (final node in nodes) {
      node.accept(this);
    }

    // Pop document root block which flushes to output
    _exitBlock();

    // Trim trailing newlines if any
    var result = _outputBuffer.toString();
    while (result.endsWith('\n\n')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  void _enterBlock(GlamourBlockStyle style, int maxWidth) {
    final blockPrefix = style.style.blockPrefix;
    if (blockPrefix != null && blockPrefix.isNotEmpty) {
      _writeStyled(blockPrefix, _currentBlockPrimitive);
    }

    // If not root, calculate inheritence/margin/indent
    int effectiveWidth = maxWidth;

    if (style.margin != null) {
      effectiveWidth -= (style.margin! * 2);
    }
    if (style.indent != null) {
      effectiveWidth -= (style.indent! * 2);
    }

    // Ensure positive width
    if (effectiveWidth < 1) effectiveWidth = 10;

    _blockStack.add(
      GlamourBlockContext(style: style, maxWidth: effectiveWidth),
    );

    // Write entering prefix
    final prefix = style.style.prefix;
    if (prefix != null && prefix.isNotEmpty) {
      _writeStyled(prefix, style.style);
    }
  }

  void _exitBlock() {
    if (_blockStack.isEmpty) return;

    final ctx = _blockStack.last;
    final content = ctx.buffer.toString();

    // Apply wrapping and styling to the block content
    final styledContent = _processBlockContent(content, ctx);

    // Write to parent buffer (or output if root)
    final parentBuffer = _blockStack.length > 1
        ? _blockStack[_blockStack.length - 2].buffer
        : _outputBuffer;
    _writeRawTo(parentBuffer, styledContent, trackLastChar: false);

    final suffix = ctx.style.style.suffix;
    if (suffix != null && suffix.isNotEmpty) {
      _writeStyledTo(parentBuffer, suffix, ctx.style.style);
    }

    // Write exiting suffix
    final blockSuffix = ctx.style.style.blockSuffix;
    if (blockSuffix != null && blockSuffix.isNotEmpty) {
      final parentStyle = _blockStack.length > 1
          ? _blockStack[_blockStack.length - 2].style.style
          : const GlamourPrimitiveStyle();
      _writeStyledTo(parentBuffer, blockSuffix, parentStyle);
    }

    _blockStack.removeLast();
  }

  GlamourPrimitiveStyle get _currentBlockPrimitive => _blockStack.isNotEmpty
      ? _blockStack.last.style.style
      : const GlamourPrimitiveStyle();

  GlamourPrimitiveStyle _currentTextStyle() {
    var style = _cascadePrimitive(
      _currentBlockPrimitive,
      theme.text,
      toBlock: false,
    );
    for (final inline in _inlineStack) {
      style = _cascadePrimitive(style, inline, toBlock: true);
    }
    return style;
  }

  GlamourBlockStyle _cascadeBlocks(List<GlamourBlockStyle> styles) {
    var result = const GlamourBlockStyle();
    for (final style in styles) {
      result = _cascadeBlock(result, style, toBlock: true);
    }
    return result;
  }

  GlamourBlockStyle _cascadeBlock(
    GlamourBlockStyle parent,
    GlamourBlockStyle child, {
    required bool toBlock,
  }) {
    final mergedPrimitive = _cascadePrimitive(
      parent.style,
      child.style,
      toBlock: toBlock,
    );

    int? indent = child.indent;
    int? margin = child.margin;
    if (toBlock) {
      indent = parent.indent;
      margin = parent.margin;
    }
    if (child.indent != null) {
      indent = child.indent;
    }

    return GlamourBlockStyle(
      style: mergedPrimitive,
      margin: margin,
      indent: indent,
      indentToken: child.indentToken,
    );
  }

  GlamourPrimitiveStyle _cascadePrimitive(
    GlamourPrimitiveStyle parent,
    GlamourPrimitiveStyle child, {
    required bool toBlock,
  }) {
    String? blockPrefix = child.blockPrefix;
    String? blockSuffix = child.blockSuffix;
    String? prefix = child.prefix;
    String? suffix = child.suffix;
    if (toBlock) {
      blockPrefix = parent.blockPrefix;
      blockSuffix = parent.blockSuffix;
      prefix = parent.prefix;
      suffix = parent.suffix;
    }

    if (child.blockPrefix != null && child.blockPrefix!.isNotEmpty) {
      blockPrefix = child.blockPrefix;
    }
    if (child.blockSuffix != null && child.blockSuffix!.isNotEmpty) {
      blockSuffix = child.blockSuffix;
    }
    if (child.prefix != null && child.prefix!.isNotEmpty) {
      prefix = child.prefix;
    }
    if (child.suffix != null && child.suffix!.isNotEmpty) {
      suffix = child.suffix;
    }

    return GlamourPrimitiveStyle(
      blockPrefix: blockPrefix,
      blockSuffix: blockSuffix,
      prefix: prefix,
      suffix: suffix,
      color: child.color ?? parent.color,
      backgroundColor: child.backgroundColor ?? parent.backgroundColor,
      bold: child.bold ?? parent.bold,
      italic: child.italic ?? parent.italic,
      underline: child.underline ?? parent.underline,
      blink: child.blink ?? parent.blink,
      crossedOut: child.crossedOut ?? parent.crossedOut,
      faint: child.faint ?? parent.faint,
      conceal: child.conceal ?? parent.conceal,
      inverse: child.inverse ?? parent.inverse,
      upper: child.upper ?? parent.upper,
      lower: child.lower ?? parent.lower,
      title: child.title ?? parent.title,
      format: child.format,
    );
  }

  String _processBlockContent(String content, GlamourBlockContext ctx) {
    if (content.isEmpty) return '';

    // 1. Wrap text
    int wrapWidth = ctx.maxWidth;
    String indent = '';
    final indentCount = ctx.style.indent ?? 0;
    final indentToken = ctx.style.indentToken;
    if (indentToken != null && indentToken.isNotEmpty) {
      final count = indentCount > 0 ? indentCount : 1;
      indent = List.filled(count, indentToken).join();
      wrapWidth -= indent.length;
    } else if (indentCount > 0) {
      indent = ' ' * indentCount;
      wrapWidth -= indent.length;
    }

    var wrapped = uv_wrap.wrapAnsiPreserving(content, wrapWidth);

    // 2. Apply indent
    if (indent.isNotEmpty) {
      final lines = wrapped.split('\n');
      final hasTrailingNewline = wrapped.endsWith('\n');
      final lastIndex = lines.length - 1;
      wrapped = lines
          .asMap()
          .entries
          .map((entry) {
            if (hasTrailingNewline &&
                entry.key == lastIndex &&
                entry.value.isEmpty) {
              return '';
            }
            return '$indent${entry.value}';
          })
          .join('\n');
    }

    // 3. Apply block margins
    if (ctx.style.margin != null && ctx.style.margin! > 0) {
      final margin = ' ' * ctx.style.margin!;
      final lines = wrapped.split('\n');
      final hasTrailingNewline = wrapped.endsWith('\n');
      final lastIndex = lines.length - 1;
      wrapped = lines
          .asMap()
          .entries
          .map((entry) {
            if (hasTrailingNewline &&
                entry.key == lastIndex &&
                entry.value.isEmpty) {
              return '';
            }
            return '$margin${entry.value}';
          })
          .join('\n');
    }

    return wrapped;
  }

  @override
  bool visitElementBefore(md.Element element) {
    switch (element.tag) {
      case 'h1':
        _enterHeading(theme.h1);
        return true;
      case 'h2':
        _enterHeading(theme.h2);
        return true;
      case 'h3':
        _enterHeading(theme.h3);
        return true;
      case 'h4':
        _enterHeading(theme.h4);
        return true;
      case 'h5':
        _enterHeading(theme.h5);
        return true;
      case 'h6':
        _enterHeading(theme.h6);
        return true;

      case 'p':
        _ensureNewline();
        _enterParagraph();
        return true;

      case 'blockquote':
        final style = _cascadeBlock(
          _blockStack.last.style,
          theme.blockQuote,
          toBlock: false,
        );
        _enterBlock(style, _currentWidth);
        return true;

      case 'ul':
      case 'ol':
        _listCounters.add(0);
        _listIsOrdered.add(element.tag == 'ol');
        _ensureNewline();

        var style = theme.list.style;
        if (theme.list.levelIndent != null && theme.list.levelIndent! > 0) {
          style = GlamourBlockStyle(
            style: style.style,
            margin: (style.margin ?? 0) + theme.list.levelIndent!,
            indent: style.indent,
            indentToken: style.indentToken,
          );
        }
        final merged = _cascadeBlock(
          _blockStack.last.style,
          style,
          toBlock: false,
        );
        _enterBlock(merged, _currentWidth);
        return true;

      case 'li':
        _ensureNewline();
        _visitListItem(element);
        return true;

      case 'strong':
        _inlineStack.add(theme.strong);
        return true;
      case 'em':
        _inlineStack.add(theme.emph);
        return true;
      case 'code':
        _inlineStack.add(theme.code.style);
        return true;
      case 'a':
        _inlineStack.add(theme.linkText);
        _linkStack.add(element.attributes['href'] ?? '');
        return true;

      case 'hr':
        _ensureNewline();
        final format = theme.horizontalRule.format ?? '--------';
        _writeRaw('\x1b[0m'); // Reset before HR
        _writeRaw(theme.horizontalRule.toStyle.render(format));
        _ensureNewline();
        return true;

      case 'input':
        // Handle task list checkboxes
        final type = element.attributes['type'];
        if (type == 'checkbox') {
          final checked = element.attributes['checked'] == 'true';
          _writeStyled(
            checked ? theme.task.ticked : theme.task.unticked,
            theme.task.style,
          );
          return false; // Don't visit children
        }
        return true;

      case 'table':
        _tableHeaders.clear();
        _tableRows.clear();
        _currentRow.clear();
        return true;

      case 'thead':
        _inTableHead = true;
        return true;

      case 'tbody':
        _inTableHead = false;
        return true;

      case 'tr':
        // End current row
        if (_currentRow.isNotEmpty) {
          if (_inTableHead) {
            _tableHeaders.addAll(_currentRow);
          } else {
            _tableRows.add(List.from(_currentRow));
          }
          _currentRow.clear();
        }
        return true;

      case 'th':
        _inTableCell = true;
        return true;
      case 'td':
        _inTableCell = true;
        return true;

      default:
        return true;
    }
  }

  @override
  void visitText(md.Text text) {
    if (_inTableCell) return; // Don't write text for table cells
    var content = _htmlUnescape.convert(text.text);
    _writeStyled(content, _currentTextStyle());
  }

  @override
  void visitElementAfter(md.Element element) {
    switch (element.tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
      case 'blockquote':
        _exitBlock();
        break;
      case 'ul':
      case 'ol':
        _listCounters.removeLast();
        _listIsOrdered.removeLast();
        _exitBlock();
        break;
      case 'li':
        _ensureNewline();
        break;

      case 'p':
        _exitBlock();
        _ensureNewline();
        break;
      case 'strong':
        _inlineStack.removeLast();
        break;
      case 'em':
        _inlineStack.removeLast();
        break;
      case 'code':
        _inlineStack.removeLast();
        break;
      case 'a':
        _inlineStack.removeLast();
        _linkStack.removeLast();
        break;

      case 'table':
        _inTableCell = false;
        _renderTable();
        _tableHeaders.clear();
        _tableRows.clear();
        _currentRow.clear();
        break;

      case 'tr':
        if (_currentRow.isNotEmpty) {
          if (_inTableHead) {
            _tableHeaders.addAll(_currentRow);
          } else {
            _tableRows.add(List.from(_currentRow));
          }
          _currentRow.clear();
        }
        break;

      case 'th':
        _inTableCell = false;
        _currentRow.add(_captureCellContent(element));
        break;
      case 'td':
        _inTableCell = false;
        _currentRow.add(_captureCellContent(element));
        break;
    }
  }

  String _captureCellContent(md.Element element) {
    final buffer = StringBuffer();
    void visitNode(md.Node node) {
      if (node is md.Text) {
        buffer.write(_htmlUnescape.convert(node.text));
      } else if (node is md.Element) {
        for (final child in node.children ?? []) {
          visitNode(child);
        }
      }
    }

    for (final child in element.children ?? []) {
      visitNode(child);
    }
    return buffer.toString().trim();
  }

  void _renderTable() {
    if (_tableHeaders.isEmpty && _tableRows.isEmpty) return;

    final colCount = _tableHeaders.isEmpty
        ? (_tableRows.isNotEmpty ? _tableRows.first.length : 0)
        : _tableHeaders.length;

    if (colCount == 0) return;

    final widths = List<int>.filled(colCount, 0);
    for (var i = 0; i < _tableHeaders.length; i++) {
      widths[i] = widths[i] > _tableHeaders[i].length
          ? widths[i]
          : _tableHeaders[i].length;
    }
    for (final row in _tableRows) {
      for (var i = 0; i < row.length && i < colCount; i++) {
        widths[i] = widths[i] > row[i].length ? widths[i] : row[i].length;
      }
    }

    _ensureNewline();
    final table = StringBuffer();

    table.write('\x1b[0m'); // Reset styles before table

    final sepLine = '+${widths.map((w) => '-' * (w + 2)).join('+')}+';
    table.writeln(sepLine);

    if (_tableHeaders.isNotEmpty) {
      final headerCells = <String>[];
      for (var i = 0; i < _tableHeaders.length; i++) {
        headerCells.add(' ${_tableHeaders[i].padRight(widths[i])} ');
      }
      table.writeln('|${headerCells.join('|')}|');
      table.writeln(sepLine);
    }

    for (final row in _tableRows) {
      final cells = <String>[];
      for (var i = 0; i < colCount; i++) {
        final cell = i < row.length ? row[i] : '';
        cells.add(' ${cell.padRight(widths[i])} ');
      }
      table.writeln('|${cells.join('|')}|');
    }

    table.writeln(sepLine);
    _writeText(table.toString());
    _ensureNewline();
  }

  void _enterHeading(GlamourBlockStyle specificStyle) {
    final heading = _cascadeBlocks([theme.heading, specificStyle]);
    final merged = _cascadeBlock(
      _blockStack.last.style,
      heading,
      toBlock: false,
    );
    _enterBlock(merged, _currentWidth);
  }

  void _enterParagraph() {
    final style = _cascadeBlock(
      _blockStack.last.style,
      theme.paragraph,
      toBlock: false,
    );
    _enterBlock(style, _currentWidth);
  }

  void _visitListItem(md.Element element) {
    final isOrdered = _listIsOrdered.isNotEmpty ? _listIsOrdered.last : false;
    final itemStyle = _cascadePrimitive(
      _currentBlockPrimitive,
      isOrdered ? theme.enumeration : theme.item,
      toBlock: false,
    );
    if (_listCounters.isNotEmpty) {
      _listCounters.last++;
    }
    final index = _listCounters.isNotEmpty ? _listCounters.last : 1;
    final prefix = isOrdered
        ? '$index${theme.enumeration.blockPrefix ?? '. '}'
        : (theme.item.blockPrefix ?? '* ');
    _writeStyled(prefix, itemStyle);
  }

  // --- Output Helpers ---

  int get _currentWidth =>
      _blockStack.isNotEmpty ? _blockStack.last.maxWidth : width;

  void _writeStyled(String text, GlamourPrimitiveStyle style) {
    if (text.isEmpty) return;
    final transformed = _applyTransform(text, style);
    if (transformed.isEmpty) return;
    _lastChar = transformed.codeUnitAt(transformed.length - 1);
    _writeRaw(_applyLinkStyle(style).render(transformed));
  }

  void _writeStyledTo(
    StringBuffer buffer,
    String text,
    GlamourPrimitiveStyle style,
  ) {
    if (text.isEmpty) return;
    final transformed = _applyTransform(text, style);
    if (transformed.isEmpty) return;
    _lastChar = transformed.codeUnitAt(transformed.length - 1);
    buffer.write(_applyLinkStyle(style).render(transformed));
  }

  Style _applyLinkStyle(GlamourPrimitiveStyle style) {
    var styled = style.toStyle;
    if (_linkStack.isNotEmpty) {
      final url = _linkStack.last;
      if (url.isNotEmpty) {
        styled = styled.hyperlink(url);
      }
    }
    return styled;
  }

  void _writeRaw(String text) {
    if (text.isEmpty) return;
    if (_blockStack.isNotEmpty) {
      _blockStack.last.buffer.write(text);
    } else {
      _outputBuffer.write(text);
    }
  }

  void _writeText(String text) {
    if (text.isEmpty) return;
    _lastChar = text.codeUnitAt(text.length - 1);
    _writeRaw(text);
  }

  void _writeRawTo(
    StringBuffer buffer,
    String text, {
    bool trackLastChar = true,
  }) {
    if (text.isEmpty) return;
    if (trackLastChar) {
      _lastChar = text.codeUnitAt(text.length - 1);
    }
    buffer.write(text);
  }

  String _applyTransform(String text, GlamourPrimitiveStyle style) {
    var result = text;
    if (style.upper == true) {
      result = result.toUpperCase();
    }
    if (style.lower == true) {
      result = result.toLowerCase();
    }
    if (style.title == true) {
      result = _toTitleCase(result);
    }
    return result;
  }

  String _toTitleCase(String text) {
    final buffer = StringBuffer();
    var startWord = true;
    for (final rune in text.runes) {
      final isWord = _isWordRune(rune);
      if (!isWord) {
        startWord = true;
        buffer.writeCharCode(rune);
        continue;
      }
      final char = String.fromCharCode(rune);
      if (startWord) {
        buffer.write(char.toUpperCase());
        startWord = false;
      } else {
        buffer.write(char.toLowerCase());
      }
    }
    return buffer.toString();
  }

  bool _isWordRune(int rune) =>
      (rune >= 0x30 && rune <= 0x39) ||
      (rune >= 0x41 && rune <= 0x5A) ||
      (rune >= 0x61 && rune <= 0x7A);

  void _ensureNewline() {
    if (_lastChar != 10) {
      _writeRaw('\n');
      _lastChar = 10;
    }
  }
}

/// Tracks rendering state for a block-level markdown element.
///
/// Context for a nested block rendering context.
class GlamourBlockContext {
  /// Creates a block context with style, width, and buffer.
  GlamourBlockContext({required this.style, required this.maxWidth});

  /// The [Style] applied to this block.
  final GlamourBlockStyle style;

  /// The maximum width available for this block.
  final int maxWidth;

  /// The string buffer accumulating this block's output.
  final StringBuffer buffer = StringBuffer();
}
