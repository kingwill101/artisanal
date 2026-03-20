/// Text selection widgets: [SelectableText] and [SelectionArea].
///
/// [SelectableText] is a drop-in replacement for [Text] that supports
/// click-drag text selection and Ctrl+C copy.
///
/// [SelectionArea] wraps a subtree and enables cross-widget text selection
/// for all [SelectableText] descendants.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

import 'dart:math' as math;

import 'package:artisanal/markdown.dart' show AnsiRendererOptions;
import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart'
    show
        Cmd,
        Msg,
        KeyMsg,
        MouseMsg,
        MouseAction,
        MouseButton,
        HitTestMouseMsg,
        View;
import '../core/element.dart' show elementOf, Element, RenderObjectElement;
import '../core/framework.dart'
    show BuildContext, StatefulWidget, StatelessWidget, State, InheritedWidget;
import '../core/widget.dart';
import '../rendering/render_object.dart';
import '../layout/geometry.dart';
import '../layout/layout_widgets.dart'
    show Text, RichText, MarkdownText, TextSpan, TextAlign, TextOverflow;
import '../scroll/scroll_widgets.dart'
    show
        ScrollController,
        RenderSingleChildViewport,
        RenderListViewScrollViewport,
        RenderListViewport,
        RenderViewport;
import '../theme/theme_scope.dart' show ThemeScope;
import 'selection_text_utils.dart';

part 'selection_controller.dart';
part 'selection_adapters.dart';
part 'selectable_text.dart';
part 'selectable_rich_text.dart';
part 'selectable_markdown_text.dart';
part 'selectable_view.dart';
part 'selection_area.dart';
