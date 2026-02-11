part of 'layout_widgets.dart';

UvColor? _colorToUvColor(Color? color) {
  if (color == null || color is NoColor) return null;

  Color resolved = color;
  if (color is AdaptiveColor) {
    resolved = hasDarkBackground ? color.dark : color.light;
  }

  final hex = resolved.toHex();
  if (hex.isEmpty) {
    if (resolved is AnsiColor) {
      return UvColor.indexed256(resolved.code);
    }
    return null;
  }

  final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
  if (normalized.length != 6) return null;

  final r = int.tryParse(normalized.substring(0, 2), radix: 16) ?? 0;
  final g = int.tryParse(normalized.substring(2, 4), radix: 16) ?? 0;
  final b = int.tryParse(normalized.substring(4, 6), radix: 16) ?? 0;

  return UvColor.rgb(r, g, b);
}

int _roundClamp(num value) => math.max(0, value.round());

int? _resolveDimension(num? value) {
  if (value == null) return null;
  if (value is double && (value.isNaN || value.isInfinite)) return null;
  return _roundClamp(value);
}

double? _resolveDimensionDouble(num? value) {
  if (value == null) return null;
  if (value is double && value.isNaN) return null;
  if (value is double && value.isInfinite) return double.infinity;
  return value.toDouble();
}

HorizontalAlign _horizontalFromAlignment(Alignment alignment) {
  if (alignment.x <= -0.5) return HorizontalAlign.left;
  if (alignment.x >= 0.5) return HorizontalAlign.right;
  return HorizontalAlign.center;
}

VerticalAlign _verticalFromAlignment(Alignment alignment) {
  if (alignment.y <= -0.5) return VerticalAlign.top;
  if (alignment.y >= 0.5) return VerticalAlign.bottom;
  return VerticalAlign.center;
}

String _viewToString(Object v) {
  if (v is String) return v;
  if (v is View) return v.content;
  return v.toString();
}

String _renderWidget(Widget widget) {
  final element = elementOf(widget);
  if (element != null) return element.render();
  return _viewToString(widget.view());
}

String _constrainContent(String content, {int? width, int? height}) {
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

String _padToWidth(String content, int targetWidth, int targetHeight) {
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

String _padToStackSize(String content, int targetWidth, int targetHeight) {
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

int _offsetForHorizontal(
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

int _offsetForVertical(
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

void _drawStyledContent(
  Canvas canvas,
  String content,
  int startX,
  int startY,
  UvStyle bgStyle, {
  bool transparent = false,
}) {
  final span = TuiTrace.begin(
    '_drawStyledContent',
    tag: TraceTag.paint,
    extra:
        'startX=$startX startY=$startY canvasW=${canvas.width()} canvasH=${canvas.height()}',
  );
  final styledBounds = StyledString(content).bounds();
  final tempCanvas = Canvas(styledBounds.width, styledBounds.height);
  StyledString(content).draw(tempCanvas, tempCanvas.bounds());

  for (var y = 0; y < styledBounds.height; y++) {
    for (var x = 0; x < styledBounds.width; x++) {
      final destX = startX + x;
      final destY = startY + y;

      if (destX < 0 || destY < 0) continue;
      if (destX >= canvas.width() || destY >= canvas.height()) continue;

      final srcCell = tempCanvas.cellAt(x, y);
      if (srcCell == null || srcCell.isZero) continue;
      // Skip plain unstyled spaces so that the container's pre-filled
      // background color shows through.  This applies in transparent mode
      // (Stack overlays) AND whenever the container has a background color,
      // because Layout.place() padding produces isEmpty cells that would
      // otherwise overwrite the bg-filled canvas.
      if (srcCell.isEmpty && (transparent || bgStyle.bg != null)) continue;

      final mergedStyle = srcCell.style.bg == null && bgStyle.bg != null
          ? srcCell.style.copyWith(bg: bgStyle.bg)
          : srcCell.style;

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
  span.end(extra: 'bounds=${styledBounds.width}x${styledBounds.height}');
}

String _renderContainerContent({
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
    '_renderContainerContent',
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

  final padLeft = _roundClamp(padding?.left ?? 0);
  final padRight = _roundClamp(padding?.right ?? 0);
  final padTop = _roundClamp(padding?.top ?? 0);
  final padBottom = _roundClamp(padding?.bottom ?? 0);

  final marginLeft = _roundClamp(margin?.left ?? 0);
  final marginRight = _roundClamp(margin?.right ?? 0);
  final marginTop = _roundClamp(margin?.top ?? 0);
  final marginBottom = _roundClamp(margin?.bottom ?? 0);

  // Inner width/height includes border + padding + content.
  final paddedWidth = contentWidth + padLeft + padRight + borderH;
  final paddedHeight = contentHeight + padTop + padBottom + borderV;

  final resolvedWidth = _resolveDimension(width);
  final resolvedHeight = _resolveDimension(height);
  final innerWidth = resolvedWidth ?? paddedWidth;
  final innerHeight = resolvedHeight ?? paddedHeight;

  final targetWidth = innerWidth + marginLeft + marginRight;
  final targetHeight = innerHeight + marginTop + marginBottom;

  if (targetWidth == 0 || targetHeight == 0) {
    span.end(extra: 'empty');
    return '';
  }

  final canvas = Canvas(targetWidth, targetHeight);
  final bgColor = _colorToUvColor(color ?? decoration?.color ?? background);
  final fgColor = _colorToUvColor(foregroundDecoration?.color ?? foreground);
  final bgStyle = UvStyle(bg: bgColor, fg: fgColor);

  // Fill entire canvas with blank cells (margin area).
  final blankCell = Cell(content: ' ', width: 1, style: const UvStyle());
  for (var y = 0; y < targetHeight; y++) {
    for (var x = 0; x < targetWidth; x++) {
      canvas.setCell(x, y, blankCell.clone());
    }
  }

  // Fill inner area (inside margin, including border) with background cells.
  final bgCell = Cell(content: ' ', width: 1, style: bgStyle);
  for (var y = marginTop; y < marginTop + innerHeight; y++) {
    for (var x = marginLeft; x < marginLeft + innerWidth; x++) {
      canvas.setCell(x, y, bgCell.clone());
    }
  }

  // Apply gradient to background cells (inside border, row-by-row).
  if (gradient != null && gradient.colors.length >= 2) {
    final gradientAreaTop = marginTop + borderTop;
    final gradientAreaHeight = math.max(0, innerHeight - borderV);
    if (gradientAreaHeight > 0) {
      final gradientColors = blend1D(
        gradientAreaHeight,
        gradient.colors,
        hasDarkBackground: hasDarkBackground,
      );
      for (var row = 0; row < gradientAreaHeight; row++) {
        final rowColor = _colorToUvColor(gradientColors[row]);
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

  // Compute alignment and content offset (inside border + padding).
  final resolvedAlign = alignment == null
      ? align
      : _horizontalFromAlignment(alignment);
  final resolvedVertical = alignment == null
      ? verticalAlign
      : _verticalFromAlignment(alignment);

  final availableWidth = math.max(0, innerWidth - padLeft - padRight - borderH);
  final availableHeight = math.max(
    0,
    innerHeight - padTop - padBottom - borderV,
  );

  final alignedX = resolvedWidth != null
      ? _offsetForHorizontal(resolvedAlign, availableWidth, contentWidth)
      : 0;
  final alignedY = resolvedHeight != null
      ? _offsetForVertical(resolvedVertical, availableHeight, contentHeight)
      : 0;

  final offsetX = marginLeft + borderLeft + padLeft + alignedX;
  final offsetY = marginTop + borderTop + padTop + alignedY;

  // Draw content.
  if (contentStr.isNotEmpty) {
    // Use the gradient-aware bg style for the content area: if gradient is
    // active, the row-specific bg is already on the canvas cells and
    // _drawStyledContent merges bg from bgStyle only when the source cell
    // has no bg. We pass the base bgStyle here; for gradient containers the
    // canvas already has per-row bg so the merge is harmless.
    _drawStyledContent(canvas, contentStr, offsetX, offsetY, bgStyle);
  }

  // Draw border characters onto the canvas.
  if (border != null && border.isVisible) {
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
    result = _padToWidth(result, targetWidth, targetHeight);
  }
  span.end(extra: 'size=${targetWidth}x$targetHeight');
  return result;
}

String? _keyToZoneId(Key? key) {
  if (key == null) return null;
  if (key is ValueKey<Object?>) {
    final value = key.value;
    if (value is String) return value;
    return value?.toString();
  }
  return key.toString();
}
