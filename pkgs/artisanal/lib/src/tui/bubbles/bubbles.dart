/// TUI Bubbles - Interactive widgets for terminal applications.
///
/// This library provides a collection of reusable TUI components (called "bubbles")
/// that follow the Elm Architecture pattern. Each bubble is a [Model] that can
/// be composed into larger applications.
///
/// ## Available Widgets
///
/// - [KeyBinding] - Declarative key bindings with help text
/// - [CursorModel] - Blinking cursor for text inputs
/// - [SpinnerModel] - Animated loading spinners
/// - [HelpModel] - Help view for displaying key bindings
/// - [PaginatorModel] - Pagination state and rendering
/// - [ViewportModel] - Scrollable content viewport
/// - [ProgressModel] - Animated progress bars
/// - [TextInputModel] - Single-line text input
/// - [TextAreaModel] - Multi-line text editing
/// - [TableModel] - Interactive tables
/// - [ListModel] - Filterable list selection
/// - [TimerModel] - Countdown timer
/// - [StopwatchModel] - Stopwatch/elapsed time
/// - [FilePickerModel] - File/directory browser and selection
/// - [AnticipateModel] - Autocomplete input with suggestions
/// - [WizardModel] - Multi-step form wizard
///
/// ## Usage
///
/// Bubbles can be composed within your own models using [ComponentHost]:
///
/// ```dart
/// class MyModel with ComponentHost implements Model {
///   final TextInputModel input;
///   final SpinnerModel spinner;
///
///   MyModel({
///     TextInputModel? input,
///     SpinnerModel? spinner,
///   }) : input = input ?? TextInputModel(),
///        spinner = spinner ?? SpinnerModel();
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     // Delegate to child bubbles
///     final (newInput, inputCmd) = updateComponent(input, msg);
///     return (
///       MyModel(input: newInput, spinner: spinner),
///       inputCmd,
///     );
///   }
///
///   @override
///   String view() => '${spinner.view()} ${input.view()}';
/// }
/// ```
library;

// Display-only components (bubble-style string renderers)
export 'components.dart';

export 'key_binding.dart';
export 'cursor.dart';
export 'spinner.dart';
export 'help.dart';
export 'paginator.dart';
export 'viewport.dart';
export 'viewport_scroll_pane.dart';
export 'text.dart';
export 'progress.dart';
export 'textinput.dart';
export 'textarea.dart';
export 'table.dart';
export 'list.dart';
export 'timer.dart';
export 'stopwatch.dart';
export 'filepicker.dart';
export 'prompt.dart';
export 'pause.dart';

// Debug helpers
export 'debug_overlay.dart';

// Interactive selection components
export 'select.dart';
export 'password.dart';
export 'search.dart';
export 'confirm.dart';
export 'anticipate.dart';
export 'wizard.dart' hide ValidateFunc;
