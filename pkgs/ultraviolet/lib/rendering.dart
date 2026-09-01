/// Diff rendering, ANSI styling, effects, and terminal graphics primitives.
///
/// This entrypoint also exports [core.dart] so rendering consumers can work
/// with buffers and cells through a single stable package boundary.
///
/// {@category Ultraviolet}
library;

export 'core.dart';
export 'src/uv/ansi.dart' show UvAnsi;
export 'src/uv/effects.dart'
    show
        AmberTrailFilter,
        ColorMatrix,
        ColorMatrixFilter,
        AmberTerminalFilter,
        CrtTrailFilter,
        PhosphorFilter,
        PhosphorTrailFilter;
export 'src/uv/filters.dart'
    show
        BufferFilter,
        BufferRenderSink,
        LiquifyFilter,
        CompositeFilter,
        VignetteFilter,
        ScanlineFilter,
        WaveDistortionFilter,
        GhostingFilter,
        CrtFilter,
        AtmosphereFilter;
export 'src/uv/halfblock_drawable.dart' show HalfBlockImageDrawable;
export 'src/uv/iterm2_drawable.dart' show ITerm2ImageDrawable;
export 'src/uv/kitty_drawable.dart' show KittyImageDrawable;
export 'src/uv/progress_bar.dart';
export 'src/uv/screen_ops.dart';
export 'src/uv/sixel_drawable.dart' show SixelImageDrawable;
export 'src/uv/style_ops.dart';
export 'src/uv/terminal_graphics.dart';
export 'src/uv/terminal_renderer.dart';
export 'src/uv/wrap.dart';
