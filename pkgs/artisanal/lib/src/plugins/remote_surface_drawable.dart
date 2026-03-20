import '../../uv.dart' as uv;
import 'remote_surface_protocol.dart';
import 'remote_surface_state.dart';

/// UV drawable adapter for one resolved remote plugin surface.
///
/// Hosts can wrap a [RemotePluginSurfaceState] with this drawable and then
/// compose it into an existing `Canvas`, `Layer`, or `Compositor` pipeline
/// without rewriting per-cell translation logic.
final class RemotePluginSurfaceDrawable implements uv.Drawable {
  const RemotePluginSurfaceDrawable(this.surface);

  final RemotePluginSurfaceState surface;

  @override
  uv.Rectangle bounds() => uv.Rectangle(
    minX: 0,
    minY: 0,
    maxX: surface.width,
    maxY: surface.height,
  );

  @override
  void draw(uv.Screen screen, uv.Rectangle area) {
    final clipWidth = area.width < surface.width ? area.width : surface.width;
    final clipHeight = area.height < surface.height ? area.height : surface.height;
    for (var row = 0; row < clipHeight; row++) {
      for (var column = 0; column < clipWidth; column++) {
        final source = surface.cellAt(column, row);
        final targetX = area.minX + column;
        final targetY = area.minY + row;
        screen.setCell(targetX, targetY, _toUvCell(source));
      }
    }
  }
}

uv.Cell _toUvCell(RemotePluginSurfaceCell cell) {
  return uv.Cell(
    content: cell.symbol,
    width: cell.width,
    style: uv.UvStyle(
      fg: _parseColor(cell.foreground),
      bg: _parseColor(cell.background),
      underline: cell.attributes.underline
          ? uv.UnderlineStyle.single
          : uv.UnderlineStyle.none,
      attrs: _attrsFor(cell.attributes),
    ),
  );
}

int _attrsFor(RemotePluginCellAttributes attributes) {
  var value = 0;
  if (attributes.bold) {
    value |= uv.Attr.bold;
  }
  if (attributes.dim) {
    value |= uv.Attr.faint;
  }
  if (attributes.italic) {
    value |= uv.Attr.italic;
  }
  if (attributes.inverse) {
    value |= uv.Attr.reverse;
  }
  return value;
}

uv.UvColor? _parseColor(String? value) {
  if (value == null) {
    return null;
  }

  final hex = value.startsWith('#') ? value.substring(1) : value;
  try {
    switch (hex.length) {
      case 3:
        return uv.UvColor.rgb(
          _doubleNibble(hex.substring(0, 1)),
          _doubleNibble(hex.substring(1, 2)),
          _doubleNibble(hex.substring(2, 3)),
        );
      case 4:
        return uv.UvColor.rgb(
          _doubleNibble(hex.substring(0, 1)),
          _doubleNibble(hex.substring(1, 2)),
          _doubleNibble(hex.substring(2, 3)),
          a: _doubleNibble(hex.substring(3, 4)),
        );
      case 6:
        return uv.UvColor.rgb(
          int.parse(hex.substring(0, 2), radix: 16),
          int.parse(hex.substring(2, 4), radix: 16),
          int.parse(hex.substring(4, 6), radix: 16),
        );
      case 8:
        return uv.UvColor.rgb(
          int.parse(hex.substring(0, 2), radix: 16),
          int.parse(hex.substring(2, 4), radix: 16),
          int.parse(hex.substring(4, 6), radix: 16),
          a: int.parse(hex.substring(6, 8), radix: 16),
        );
      default:
        return null;
    }
  } on FormatException {
    return null;
  }
}

int _doubleNibble(String value) {
  final nibble = int.parse(value, radix: 16);
  return nibble * 17;
}
