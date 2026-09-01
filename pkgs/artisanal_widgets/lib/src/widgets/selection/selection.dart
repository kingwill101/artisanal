/// Text selection widgets: [SelectableText] and [SelectionArea].
///
/// [SelectableText] is a drop-in replacement for [Text] that supports
/// click-drag text selection and Ctrl+C copy.
///
/// [SelectionArea] wraps a subtree and enables cross-widget text selection
/// for all [SelectableText] descendants.
///
/// {@category Selection}
library;

import 'dart:math' as math;

import 'package:artisanal/markdown.dart' show AnsiRendererOptions;
import 'package:artisanal/runtime.dart'
    show
        Cmd,
        Msg,
        KeyMsg,
        MouseMsg,
        MouseAction,
        MouseButton,
        HitTestMouseMsg,
        View;
import '../core/element.dart';
import '../core/framework.dart';
import '../core/widget.dart';
import '../layout/_layout_core.dart';
import '../layout/markdown_text.dart';
import '../rendering/render_object.dart';
import '../scroll/scroll_widgets.dart';
import 'selection_text_utils.dart';
import '../style.dart';
import '../theme/theme_scope.dart';
part 'selectable_markdown_text.dart';
part 'selectable_rich_text.dart';
part 'selectable_text.dart';
part 'selectable_view.dart';
part 'selection_adapters.dart';
part 'selection_area.dart';
part 'selection_controller.dart';
