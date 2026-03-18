/// Higher-level widgets built from layout primitives.
///
/// This library groups reusable UI components such as cards, buttons,
/// overlays, command palette utilities, and the git diff viewer.
@experimental
library;

import 'package:artisanal/widgets.dart';
import 'package:meta/meta.dart' show experimental;

import 'dart:math' as math;

import 'package:artisanal/bubbles.dart' show EchoMode;
import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart'
    show
        Cmd,
        InterruptMsg,
        Msg,
        KeyBinding,
        KeyMap,
        KeyMsg,
        MouseMsg,
        RenderMetrics,
        RenderMetricsMsg,
        every;
export 'package:artisanal/bubbles.dart'
    show GitDiffModel, DiffFile, DiffStyles, DiffViewMode;

part '_component_utils.dart';
part 'frame.dart';
part 'button.dart';
part 'badge.dart';
part 'chip.dart';
part 'card.dart';
part 'panel.dart';
part 'alert.dart';
part 'toast.dart';
part 'tabs.dart';
part 'tooltip.dart';
part 'modal.dart';
part 'progress_indicator.dart';
part 'spinner_indicator.dart';
part 'slider.dart';
part 'checkbox.dart';
part 'radio.dart';
part 'switch.dart';
part 'select.dart';
part 'popup_menu.dart';
part 'list_item.dart';
part 'breadcrumbs.dart';
part 'pagination.dart';
part 'accordion.dart';
part 'split_view.dart';
part 'sidebar.dart';
part 'drawer.dart';
part 'scroll_area.dart';
part 'fade_modal_barrier.dart';
part 'debug_overlay.dart';
part 'git_diff.dart';
part 'key_hint.dart';
part 'help_view.dart';
part 'status_bar.dart';
part 'accent_panel.dart';
part 'command_palette.dart';
part 'data_table.dart';
part 'tree_view.dart';
part 'metric_display.dart';
part 'step_indicator.dart';
part 'wizard.dart';
part 'hyperlink_text.dart';
part 'action_button.dart';
part 'prompt_footer_bar.dart';
part 'dialog_stack.dart';
part 'dialog_select.dart';
part 'dialog_confirm.dart';
part 'dialog_alert.dart';
part 'dialog_prompt.dart';
