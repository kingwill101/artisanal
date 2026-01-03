/// Reusable interactive components for Artisanal TUI.
///
/// This library provides a collection of widgets (Bubbles) like text inputs,
/// viewports, progress bars, and spinners that can be composed into
/// larger applications.
///
/// {@category TUI}
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
///
/// ## Usage
///
/// {@macro artisanal_bubbles_composition}
///
/// ## Display Components
///
/// {@macro artisanal_bubbles_display_components}
///
/// {@template artisanal_bubbles_composition}
/// Bubbles can be composed within your own models using `ComponentHost`:
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
/// {@endtemplate}
///
/// {@template artisanal_bubbles_display_components}
/// In addition to interactive models, Artisanal provides `DisplayComponent`s.
/// These are simple string renderers that don't handle input but provide
/// consistent styling for tables, lists, and panels.
///
/// Use `RenderConfig` to adapt these components to the current terminal
/// width and color capabilities.
/// {@endtemplate}
library;

export 'src/tui/bubbles/bubbles.dart';
