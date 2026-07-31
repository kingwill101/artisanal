/// Higher-level widgets built from layout primitives.
///
/// This library groups reusable UI components such as cards, buttons,
/// overlays, command palette utilities, and the git diff viewer.
///
/// {@category Widgets}
library;

export 'package:artisanal/bubbles.dart'
    show
        DiffCommentAnchor,
        DiffCommentLineHighlight,
        DiffCommentLineHighlightKind,
        DiffCommentLineKey,
        DiffCommentKind,
        DiffCommentSide,
        DiffFile,
        DiffStyles,
        DiffViewMode,
        GitDiffModel;

export 'component_style.dart';
export 'text_editor.dart' show TextEditor;
export 'code_editor.dart' show CodeEditor;
export 'markdown_editor.dart' show MarkdownEditor;

export 'frame.dart';
export 'button.dart';
export 'badge.dart';
export 'chip.dart';
export 'card.dart';
export 'panel.dart';
export 'alert.dart';
export 'toast.dart';
export 'tabs.dart';
export 'tooltip.dart';
export 'modal.dart';
export 'progress_indicator.dart';
export 'spinner_indicator.dart';
export 'slider.dart';
export 'checkbox.dart';
export 'radio.dart';
export 'switch.dart';
export 'select.dart';
export 'popup_menu.dart';
export 'list_item.dart';
export 'breadcrumbs.dart';
export 'pagination.dart';
export 'accordion.dart';
export 'split_view.dart';
export 'sidebar.dart';
export 'drawer.dart';
export 'scroll_area.dart';
export 'fade_modal_barrier.dart';
export 'debug_overlay.dart';
export 'debug_console.dart';
export 'git_diff.dart';
export 'key_hint.dart';
export 'help_view.dart';
export 'status_bar.dart';
export 'status_line.dart';
export 'replay_event_panel.dart';
export 'replay_event_history_panel.dart';
export 'history_panel.dart';
export 'decision_card.dart';
export 'accent_panel.dart';
export 'command_palette.dart';
export 'data_table.dart';
export 'monthly_calendar.dart';
export 'tree_view.dart';
export 'metric_display.dart';
export 'step_indicator.dart';
export 'wizard.dart';
export 'file_picker.dart';
export 'hyperlink_text.dart';
export 'action_button.dart';
export 'prompt_footer_bar.dart';
export 'dialog_stack.dart';
export 'dialog_select.dart';
export 'dialog_confirm.dart';
export 'dialog_alert.dart';
export 'dialog_prompt.dart';
