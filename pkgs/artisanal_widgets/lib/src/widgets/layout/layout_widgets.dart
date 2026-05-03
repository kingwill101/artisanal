///
/// Provides Row, Column, and other layout primitives that use
/// the Layout API internally.
///
/// ```dart
/// Column(
///   gap: 1,
///   children: [
///     Text('Title'),
///     Row(children: [button1, button2]),
///   ],
/// )
/// ```
library;

import 'dart:async';
import 'dart:async' as dart_async;
import 'dart:collection';
import 'dart:io' show File, HttpClient, HttpHeaders, Platform;
import 'dart:math' as math;
import 'dart:typed_data' show BytesBuilder, Uint8List;

import 'package:artisanal/style.dart' hide Padding, Align;
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
import 'package:artisanal/markdown.dart'
    show markdownToAnsi, AnsiRendererOptions;
import 'package:image/image.dart' as img;
import 'geometry.dart';
import '../core/element.dart' show elementOf;
import '../core/framework.dart'
    show BuildContext, StatelessWidget, StatefulWidget, State;
import '../rendering/render_object.dart';
import '../rendering/render_layout.dart';
import '../core/widget.dart';
import '../focus/focus.dart' show Focusable;
import '../theme/theme.dart' show hasDarkBackground, currentTheme;
import '../theme/theme_scope.dart' show ThemeScope;
import '../gestures/gestures.dart';
import '../media/media_query.dart' show MediaQuery;
import '../animation/animation_controller.dart';
import '../animation/animation_mixin.dart';

part '_layout_utils.dart';
part 'enums.dart';
part 'spacing.dart';
part 'text.dart';
part 'label.dart';
part 'icon.dart';
part 'opacity.dart';
part 'gesture_detector.dart';
part 'mouse_region.dart';
part 'flex.dart';
part 'row.dart';
part 'column.dart';
part 'hbox.dart';
part 'vbox.dart';
part 'wrap.dart';
part 'container.dart';
part 'padding.dart';
part 'align.dart';
part 'center.dart';
part 'sized_box.dart';
part 'constrained_box.dart';
part 'shrink_wrap.dart';
part 'zone.dart';
part 'stack.dart';
part 'positioned.dart';
part 'visibility.dart';
part 'spacer.dart';
part 'flexible.dart';
part 'expanded.dart';
part 'divider.dart';
part 'builder.dart';
part 'vertical_divider.dart';
part 'colored_box.dart';
part 'decorated_box.dart';
part 'layout_builder.dart';
part 'clip_rect.dart';
part 'rich_text.dart';
part 'overflow_box.dart';
part 'tint.dart';
part 'image.dart';
part 'markdown_text.dart';
part 'limited_box.dart';
part 'animated_tint.dart';
part 'error_widget.dart';
part 'transform.dart';
part 'ascii_font.dart';
part 'ascii_text.dart';
part 'ignore_pointer.dart';
part 'async_builder.dart';
