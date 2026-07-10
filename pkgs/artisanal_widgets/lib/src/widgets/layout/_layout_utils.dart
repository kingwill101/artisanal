import 'dart:math' as math;

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart'
    show
        Cmd,
        Msg,
        KeyType,
        KeyMsg,
        MouseMsg,
        MouseAction,
        MouseButton,
        HitTestMouseMsg,
        View,
        TuiTrace,
        TraceTag;
import 'package:artisanal/uv.dart'
    show
        Canvas,
        Cell,
        Drawable,
        ITerm2ImageDrawable,
        KittyImageDrawable,
        SixelImageDrawable,
        StyledString,
        TerminalCapabilities,
        UvStyle,
        UvBasic16,
        UvColor,
        UvIndexed256,
        UvRgb,
        UnderlineStyle,
        HalfBlockImageDrawable,
        mayContainTerminalGraphics;

import '../core/element.dart' show elementOf;
import '../core/widget.dart';
import '../theme/theme.dart' show hasDarkBackground;
import 'container.dart';
import 'spacing.dart';

final Expando<_UvColorCacheEntry> _uvColorCache = Expando<_UvColorCacheEntry>(
  'artisanal_widgets.uvColor',
);

UvColor? colorToUvColor(Color? color) {
  if (color == null || color is NoColor) return null;

  final cached = _uvColorCache[color];
  if (cached != null) {
    if (hasDarkBackground && cached.hasDarkValue) return cached.darkValue;
    if (!hasDarkBackground && cached.hasLightValue) return cached.lightValue;
  }

  Color resolved = color;
  if (color is AdaptiveColor) {
    resolved = hasDarkBackground ? color.dark : color.light;
  }

  final value = _resolvedColorToUvColor(resolved);
  final entry = cached ?? (_uvColorCache[color] = _UvColorCacheEntry());
  if (hasDarkBackground) {
    entry
      ..hasDarkValue = true
      ..darkValue = value;
  } else {
    entry
      ..hasLightValue = true
      ..lightValue = value;
  }
  return value;
}

UvColor? _resolvedColorToUvColor(Color resolved) {
  final hex = resolved.toHex();
  if (hex.isEmpty) {
    if (resolved is AnsiColor) {
      return UvColor.indexed256(resolved.code);
    }
    return null;
  }

  final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
  if (normalized.length != 6) {
    return null;
  }

  final r = int.tryParse(normalized.substring(0, 2), radix: 16) ?? 0;
  final g = int.tryParse(normalized.substring(2, 4), radix: 16) ?? 0;
  final b = int.tryParse(normalized.substring(4, 6), radix: 16) ?? 0;

  return UvColor.rgb(r, g, b);
}

final class _UvColorCacheEntry {
  bool hasDarkValue = false;
  bool hasLightValue = false;
  UvColor? darkValue;
  UvColor? lightValue;
}

int roundClamp(num value) => math.max(0, value.round());

int? resolveDimension(num? value) {
  if (value == null) return null;
  if (value is double && (value.isNaN || value.isInfinite)) return null;
  return roundClamp(value);
}

double? resolveDimensionDouble(num? value) {
  if (value == null) return null;
  if (value is double && value.isNaN) return null;
  if (value is double && value.isInfinite) return double.infinity;
  return value.toDouble();
}

HorizontalAlign horizontalFromAlignment(Alignment alignment) {
  if (alignment.x <= -0.5) return HorizontalAlign.left;
  if (alignment.x >= 0.5) return HorizontalAlign.right;
  return HorizontalAlign.center;
}

VerticalAlign verticalFromAlignment(Alignment alignment) {
  if (alignment.y <= -0.5) return VerticalAlign.top;
  if (alignment.y >= 0.5) return VerticalAlign.bottom;
  return VerticalAlign.center;
}

String viewToString(Object v) {
  if (v is String) return v;
  if (v is View) return v.content;
  return v.toString();
}

String renderWidget(Widget widget) {
  final element = elementOf(widget);
  if (element != null) return element.render();
  return viewToString(widget.view());
}

String constrainContent(String content, {int? width, int? height}) {
  if (width != null && width <= 0) return '';
  if (height != null && height <= 0) return '';

  var result = content;
  if (width != null) {
    result = Layout.truncateLines(result, width, ellipsis: '...');
  }
  if (height != null) {
    result = Layout.truncateHeight(result, height);
  }

  final size = Layout.getSize(result);
  final targetWidth = width ?? size.width;
  final targetHeight = height ?? size.height;

  if (targetWidth == size.width && targetHeight == size.height) {
    return result;
  }

  return Layout.place(
    width: targetWidth,
    height: targetHeight,
    horizontal: HorizontalAlign.left,
    vertical: VerticalAlign.top,
    content: result,
  );
}

String padToWidth(String content, int targetWidth, int targetHeight) {
  final lines = content.split('\n');
  final result = <String>[];

  for (var i = 0; i < targetHeight; i++) {
    final line = i < lines.length ? lines[i] : '';
    final lineWidth = Layout.visibleLength(line);
    if (lineWidth < targetWidth) {
      result.add('$line${' ' * (targetWidth - lineWidth)}');
    } else {
      result.add(line);
    }
  }

  return result.join('\n');
}

String padToStackSize(String content, int targetWidth, int targetHeight) {
  final lines = content.split('\n');
  final result = <String>[];

  for (var i = 0; i < targetHeight; i++) {
    final line = i < lines.length ? lines[i] : '';
    final lineWidth = Layout.visibleLength(line);
    final padded = lineWidth < targetWidth
        ? Layout.pad(line, targetWidth)
        : line;
    result.add(padded);
  }

  return result.join('\n');
}

String renderPlainContainerContent({
  required String content,
  required int contentHeight,
  required int targetWidth,
  required int targetHeight,
  required int marginLeft,
  required int marginTop,
  required int padLeft,
  required int padTop,
  required int alignedX,
  required int alignedY,
}) {
  final lines = content.split('\n');
  final buffer = StringBuffer();
  final contentX = marginLeft + padLeft + alignedX;
  final contentY = marginTop + padTop + alignedY;
  final blankLine = ' ' * targetWidth;

  for (var y = 0; y < targetHeight; y++) {
    if (y > 0) buffer.write('\n');

    final sourceY = y - contentY;
    if (sourceY < 0 || sourceY >= contentHeight || sourceY >= lines.length) {
      buffer.write(blankLine);
      continue;
    }

    var line = lines[sourceY];
    final maxLineWidth = math.max(0, targetWidth - contentX);
    if (maxLineWidth <= 0) {
      buffer.write(blankLine);
      continue;
    }

    var lineWidth = Layout.visibleLength(line);
    if (lineWidth > maxLineWidth) {
      line = Layout.truncate(line, maxLineWidth, ellipsis: '');
      lineWidth = Layout.visibleLength(line);
    }

    final prefixWidth = contentX.clamp(0, targetWidth);
    final suffixWidth = math.max(0, targetWidth - prefixWidth - lineWidth);
    buffer
      ..write(' ' * prefixWidth)
      ..write(line);
    if (suffixWidth > 0) {
      if (_mayLeaveTerminalStateOpen(line)) {
        buffer.write(_ansiResetStyleForPlainComposition);
      }
      buffer.write(' ' * suffixWidth);
    }
  }

  return buffer.toString();
}

bool needsPlainContainerCanvasComposition(String content) {
  if (mayContainTerminalGraphics(content)) return true;
  return hasUnsupportedPlainContainerControls(content);
}

bool hasUnsupportedPlainContainerControls(String text) {
  for (var i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    if (code == 0x1B) {
      if (i + 1 >= text.length) return true;
      final next = text.codeUnitAt(i + 1);
      if (next == 0x5B) continue; // CSI, including SGR.
      return true;
    }
    if (code == 0x9B) continue; // C1 CSI.
    if (code >= 0x80 && code <= 0x9F) return true;
  }
  return false;
}

bool _mayLeaveTerminalStateOpen(String line) {
  return line.contains('\x1b[') || line.contains('\x9b');
}

const _ansiResetStyleForPlainComposition = '\x1b[m';

int offsetForHorizontal(
  HorizontalAlign align,
  int containerWidth,
  int childWidth,
) {
  return switch (align) {
    HorizontalAlign.left => 0,
    HorizontalAlign.center => (containerWidth - childWidth) ~/ 2,
    HorizontalAlign.right => containerWidth - childWidth,
  };
}

int offsetForVertical(
  VerticalAlign align,
  int containerHeight,
  int childHeight,
) {
  return switch (align) {
    VerticalAlign.top => 0,
    VerticalAlign.center => (containerHeight - childHeight) ~/ 2,
    VerticalAlign.bottom => containerHeight - childHeight,
  };
}

void drawStyledContent(
  Canvas canvas,
  String content,
  int startX,
  int startY,
  UvStyle bgStyle, {
  bool transparent = false,
  int? contentWidth,
  int? contentHeight,
}) {
  final span = TuiTrace.begin(
    '_drawStyledContent',
    tag: TraceTag.paint,
    extra:
        'startX=$startX startY=$startY canvasW=${canvas.width()} canvasH=${canvas.height()}',
  );
  final styled = StyledString(content);
  final (styledWidth, styledHeight) = switch ((contentWidth, contentHeight)) {
    (final int width, final int height) => (width, height),
    _ => () {
      final bounds = styled.bounds();
      return (bounds.width, bounds.height);
    }(),
  };
  final tempCanvas = Canvas(styledWidth, styledHeight);
  styled.draw(tempCanvas, tempCanvas.bounds());

  for (var y = 0; y < styledHeight; y++) {
    for (var x = 0; x < styledWidth; x++) {
      final destX = startX + x;
      final destY = startY + y;

      if (destX < 0 || destY < 0) continue;
      if (destX >= canvas.width() || destY >= canvas.height()) continue;

      final srcCell = tempCanvas.cellAt(x, y);
      if (srcCell == null || srcCell.isZero) continue;
      final normalizedStyle = srcCell.style;
      final isSingleWidthSpace = srcCell.content == ' ' && srcCell.width == 1;

      // Skip layout/padding spaces that have no visible styling of their own so
      // the destination background remains visible. This covers both plain empty
      // cells and spaces that only carried a foreground/default-background style
      // after ANSI round-tripping.
      //
      // We unconditionally skip empty cells and transparent spaces — regardless
      // of whether the current container has a background color — so that
      // Layout.place/pad trailing-space padding never overwrites background fill
      // cells laid down by an inner widget. Without this, a no-bg intermediate
      // container (e.g. Container(width: 58) with no color) would pass empty
      // Layout.place spaces through to the parent canvas, overwriting the inner
      // widget's bg=highlight fill cells.
      final hasVisibleSpaceAttrs =
          (normalizedStyle.attrs & 32) != 0; // 32 == Attr.reverse
      final isTransparentSpace =
          isSingleWidthSpace &&
          normalizedStyle.fg == null &&
          normalizedStyle.bg == null &&
          normalizedStyle.underlineColor == null &&
          normalizedStyle.underline == UnderlineStyle.none &&
          !hasVisibleSpaceAttrs &&
          srcCell.link.isZero;
      if (srcCell.isEmpty || isTransparentSpace) {
        continue;
      }

      final mergedStyle = normalizedStyle.bg == null && bgStyle.bg != null
          ? normalizedStyle.copyWith(bg: bgStyle.bg)
          : normalizedStyle;

      canvas.setCell(
        destX,
        destY,
        Cell(
          content: srcCell.content,
          width: srcCell.width,
          style: mergedStyle,
          link: srcCell.link,
        ),
      );
    }
  }
  span.end(extra: 'bounds=${styledWidth}x$styledHeight');
}

String renderContainerContent({
  required String contentStr,
  EdgeInsets? padding,
  EdgeInsets? margin,
  num? width,
  num? height,
  Color? background,
  Color? foreground,
  Color? color,
  Decoration? decoration,
  Decoration? foregroundDecoration,
  Alignment? alignment,
  HorizontalAlign align = HorizontalAlign.left,
  VerticalAlign verticalAlign = VerticalAlign.top,
}) {
  final span = TuiTrace.begin(
    'renderContainerContent',
    tag: TraceTag.paint,
    extra: 'w=$width h=$height',
  );
  final contentWidth = Layout.getWidth(contentStr);
  final contentHeight = Layout.getHeight(contentStr);

  // Extract BoxDecoration fields.
  final boxDecoration = decoration is BoxDecoration ? decoration : null;
  final border = boxDecoration?.border;
  final borderRadius = boxDecoration?.borderRadius;
  final gradient = boxDecoration?.gradient;

  // Compute border edge sizes (each edge consumes cells).
  final borderLeft = border != null && border.isVisible
      ? border.getLeftSize()
      : 0;
  final borderRight = border != null && border.isVisible
      ? border.getRightSize()
      : 0;
  final borderTop = border != null && border.isVisible
      ? border.getTopSize()
      : 0;
  final borderBottom = border != null && border.isVisible
      ? border.getBottomSize()
      : 0;
  final borderH = borderLeft + borderRight;
  final borderV = borderTop + borderBottom;
  final hasBorder = border != null && border.isVisible;
  final hasGradient = gradient != null && gradient.colors.length >= 2;

  final padLeft = roundClamp(padding?.left ?? 0);
  final padRight = roundClamp(padding?.right ?? 0);
  final padTop = roundClamp(padding?.top ?? 0);
  final padBottom = roundClamp(padding?.bottom ?? 0);

  final marginLeft = roundClamp(margin?.left ?? 0);
  final marginRight = roundClamp(margin?.right ?? 0);
  final marginTop = roundClamp(margin?.top ?? 0);
  final marginBottom = roundClamp(margin?.bottom ?? 0);

  // Inner width/height includes border + padding + content.
  final paddedWidth = contentWidth + padLeft + padRight + borderH;
  final paddedHeight = contentHeight + padTop + padBottom + borderV;

  final resolvedWidth = resolveDimension(width);
  final resolvedHeight = resolveDimension(height);
  final innerWidth = resolvedWidth ?? paddedWidth;
  final innerHeight = resolvedHeight ?? paddedHeight;

  final targetWidth = innerWidth + marginLeft + marginRight;
  final targetHeight = innerHeight + marginTop + marginBottom;

  if (targetWidth == 0 || targetHeight == 0) {
    span.end(extra: 'empty');
    return '';
  }

  final bgColor = colorToUvColor(color ?? decoration?.color ?? background);
  final fgColor = colorToUvColor(foregroundDecoration?.color ?? foreground);
  final bgStyle = UvStyle(bg: bgColor, fg: fgColor);
  final hasVisualStyle =
      bgColor != null || fgColor != null || hasBorder || hasGradient;
  if (!hasVisualStyle &&
      padLeft == 0 &&
      padRight == 0 &&
      padTop == 0 &&
      padBottom == 0 &&
      marginLeft == 0 &&
      marginRight == 0 &&
      marginTop == 0 &&
      marginBottom == 0 &&
      targetWidth == contentWidth &&
      targetHeight == contentHeight) {
    span.end(extra: 'passthrough size=${targetWidth}x$targetHeight');
    return contentStr;
  }

  // Compute alignment and content offset (inside border + padding).
  final resolvedAlign = alignment == null
      ? align
      : horizontalFromAlignment(alignment);
  final resolvedVertical = alignment == null
      ? verticalAlign
      : verticalFromAlignment(alignment);

  final availableWidth = math.max(0, innerWidth - padLeft - padRight - borderH);
  final availableHeight = math.max(
    0,
    innerHeight - padTop - padBottom - borderV,
  );

  final alignedX = resolvedWidth != null
      ? offsetForHorizontal(resolvedAlign, availableWidth, contentWidth)
      : 0;
  final alignedY = resolvedHeight != null
      ? offsetForVertical(resolvedVertical, availableHeight, contentHeight)
      : 0;

  final offsetX = marginLeft + borderLeft + padLeft + alignedX;
  final offsetY = marginTop + borderTop + padTop + alignedY;

  if (!hasVisualStyle &&
      offsetX >= 0 &&
      offsetY >= 0 &&
      !needsPlainContainerCanvasComposition(contentStr)) {
    final result = renderPlainContainerContent(
      content: contentStr,
      contentHeight: contentHeight,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      marginLeft: marginLeft,
      marginTop: marginTop,
      padLeft: padLeft,
      padTop: padTop,
      alignedX: alignedX,
      alignedY: alignedY,
    );
    span.end(extra: 'plain size=${targetWidth}x$targetHeight');
    return result;
  }

  final canvas = Canvas(targetWidth, targetHeight);

  // Fill inner area (inside margin, including border) with background cells.
  if (!bgStyle.isZero) {
    final bgCell = Cell(content: ' ', width: 1, style: bgStyle);
    for (var y = marginTop; y < marginTop + innerHeight; y++) {
      for (var x = marginLeft; x < marginLeft + innerWidth; x++) {
        canvas.setCell(x, y, bgCell.clone());
      }
    }
  }

  // Apply gradient to background cells (inside border, row-by-row).
  if (hasGradient) {
    final gradientAreaTop = marginTop + borderTop;
    final gradientAreaHeight = math.max(0, innerHeight - borderV);
    if (gradientAreaHeight > 0) {
      final gradientColors = blend1D(
        gradientAreaHeight,
        gradient.colors,
        hasDarkBackground: hasDarkBackground,
      );
      for (var row = 0; row < gradientAreaHeight; row++) {
        final rowColor = colorToUvColor(gradientColors[row]);
        final rowStyle = UvStyle(bg: rowColor, fg: fgColor);
        final rowCell = Cell(content: ' ', width: 1, style: rowStyle);
        final y = gradientAreaTop + row;
        for (
          var x = marginLeft + borderLeft;
          x < marginLeft + innerWidth - borderRight;
          x++
        ) {
          canvas.setCell(x, y, rowCell.clone());
        }
      }
    }
  }

  // Draw content.
  if (contentStr.isNotEmpty) {
    // Use the gradient-aware bg style for the content area: if gradient is
    // active, the row-specific bg is already on the canvas cells and
    // _drawStyledContent merges bg from bgStyle only when the source cell
    // has no bg. We pass the base bgStyle here; for gradient containers the
    // canvas already has per-row bg so the merge is harmless.
    drawStyledContent(
      canvas,
      contentStr,
      offsetX,
      offsetY,
      bgStyle,
      contentWidth: contentWidth,
      contentHeight: contentHeight,
    );
  }

  // Draw border characters onto the canvas.
  if (hasBorder) {
    final bx = marginLeft; // border area origin x
    final by = marginTop; // border area origin y
    final bw = innerWidth; // border area width
    final bh = innerHeight; // border area height

    // Resolve corner characters (apply borderRadius).
    var cornerTL = border.topLeft;
    var cornerTR = border.topRight;
    var cornerBL = border.bottomLeft;
    var cornerBR = border.bottomRight;
    if (borderRadius != null) {
      if (borderRadius.topLeft > 0) cornerTL = '╭';
      if (borderRadius.topRight > 0) cornerTR = '╮';
      if (borderRadius.bottomLeft > 0) cornerBL = '╰';
      if (borderRadius.bottomRight > 0) cornerBR = '╯';
    }

    final borderStyle = UvStyle(bg: bgColor, fg: fgColor);

    // Top-left corner.
    if (cornerTL.isNotEmpty) {
      canvas.setCell(
        bx,
        by,
        Cell(content: cornerTL, width: 1, style: borderStyle),
      );
    }
    // Top-right corner.
    if (cornerTR.isNotEmpty) {
      canvas.setCell(
        bx + bw - 1,
        by,
        Cell(content: cornerTR, width: 1, style: borderStyle),
      );
    }
    // Bottom-left corner.
    if (cornerBL.isNotEmpty) {
      canvas.setCell(
        bx,
        by + bh - 1,
        Cell(content: cornerBL, width: 1, style: borderStyle),
      );
    }
    // Bottom-right corner.
    if (cornerBR.isNotEmpty) {
      canvas.setCell(
        bx + bw - 1,
        by + bh - 1,
        Cell(content: cornerBR, width: 1, style: borderStyle),
      );
    }

    // Top edge.
    if (border.top.isNotEmpty) {
      for (var x = bx + borderLeft; x < bx + bw - borderRight; x++) {
        canvas.setCell(
          x,
          by,
          Cell(content: border.top, width: 1, style: borderStyle),
        );
      }
    }

    // Bottom edge.
    if (border.bottom.isNotEmpty) {
      for (var x = bx + borderLeft; x < bx + bw - borderRight; x++) {
        canvas.setCell(
          x,
          by + bh - 1,
          Cell(content: border.bottom, width: 1, style: borderStyle),
        );
      }
    }

    // Left edge.
    if (border.left.isNotEmpty) {
      for (var y = by + borderTop; y < by + bh - borderBottom; y++) {
        canvas.setCell(
          bx,
          y,
          Cell(content: border.left, width: 1, style: borderStyle),
        );
      }
    }

    // Right edge.
    if (border.right.isNotEmpty) {
      for (var y = by + borderTop; y < by + bh - borderBottom; y++) {
        canvas.setCell(
          bx + bw - 1,
          y,
          Cell(content: border.right, width: 1, style: borderStyle),
        );
      }
    }
  }

  var result = canvas.render();
  if (resolvedWidth != null ||
      resolvedHeight != null ||
      marginLeft > 0 ||
      marginRight > 0 ||
      marginTop > 0 ||
      marginBottom > 0) {
    result = padToWidth(result, targetWidth, targetHeight);
  }
  span.end(extra: 'size=${targetWidth}x$targetHeight');
  return result;
}
