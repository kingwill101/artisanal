/// Core cell-buffer, geometry, layout, and drawing primitives.
///
/// Import this entrypoint when an application needs to build or manipulate
/// terminal frames without terminal lifecycle, input decoding, or rendering.
///
/// {@category Ultraviolet}
library;

export 'src/uv/border.dart';
export 'src/uv/buffer.dart' show Buffer, Line, LineData, ScreenBuffer;
export 'src/uv/canvas.dart' show Canvas;
export 'src/uv/capabilities.dart';
export 'src/uv/cell.dart'
    show
        Cell,
        CellDiffOption,
        Link,
        UvStyle,
        UvColor,
        UvBasic16,
        UvIndexed256,
        UvRgb,
        Attr,
        UnderlineStyle;
export 'src/uv/color_utils.dart';
export 'src/uv/drawable.dart' show Drawable, EmptyDrawable;
export 'src/uv/geometry.dart' show Position, Rectangle, rect;
export 'src/uv/layer.dart' show Layer, Compositor, newLayer, LayerHit;
export 'src/uv/layout.dart';
export 'src/uv/screen.dart';
export 'src/uv/styled_string.dart'
    show
        StyledString,
        newStyledString,
        LinkState,
        StyleState,
        readLink,
        readStyle,
        SgrParam;
