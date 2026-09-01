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
import 'package:artisanal_widgets/src/widgets/selection/selection_text_utils.dart';
import 'package:artisanal_widgets/src/widgets/widgets.dart';
import '../style.dart';
part 'selectable_markdown_text.dart';
part 'selectable_rich_text.dart';
part 'selectable_text.dart';
part 'selectable_view.dart';
part 'selection_adapters.dart';
part 'selection_area.dart';
part 'selection_controller.dart';
