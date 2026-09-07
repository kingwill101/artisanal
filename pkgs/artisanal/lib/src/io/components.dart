import 'dart:async';

import '../style/chars.dart';
import '../style/style.dart';
import '../tui/bubbles/components/alert.dart' show Alert, AlertDisplayStyle;
import '../tui/bubbles/components/base.dart'
    show RenderConfig, DisplayComponent;
import '../tui/bubbles/components/list.dart' show BulletList;
import '../tui/bubbles/components/table.dart' show HorizontalTableComponent;
import '../tui/bubbles/components/titled_block.dart' show TitledBlockComponent;
import '../tui/bubbles/components/two_column_detail.dart'
    show TwoColumnDetailComponent, TwoColumnDetailList;
import '../tui/bubbles/components/styled_block.dart' show CommentComponent;
import '../tui/bubbles/components/exception.dart' show ExceptionComponent;
import '../tui/bubbles/components/text.dart' show Rule;
import '../tui/bubbles/prompt.dart'
    show promptProgramOptions, runTextAreaPrompt;
import '../tui/bubbles/spinner.dart' show Spinner, Spinners;
import '../tui/bubbles/textarea.dart' show TextAreaModel;
import '../tui/program.dart' show ProgramOptions;
import 'console.dart';
import 'console_operations.dart';
import 'console_presentation.dart';

/// Higher-level console UI components (Laravel-style).
///
/// Access via `io.components`.
///
/// ```dart
/// io.components.task('Running migrations', run: () async {
///   return TaskResult.success;
/// });
/// io.components.twoColumnDetail('Name', 'Value');
/// io.components.bulletList(['Item 1', 'Item 2']);
/// io.components.alert('Important!');
/// io.components.spin('Loading...', run: () async { ... });
/// ```
class Components {
  /// Creates a components helper for the given I/O instance.
  Components({required this.io});

  /// The I/O instance to use for output.
  final Console io;

  late final ConsoleOperations _operations = ConsoleOperations(io);

  /// The style configuration.
  Style get style => io.style;

  RenderConfig get _renderConfig => io.renderConfig;

  Style _styleFor(String role, Style themed) =>
      resolveConsoleComponentStyle(themed, io.getStyle(role));

  /// Helper to apply muted styling.
  String muted(String text) => _styleFor(
    'muted',
    io.componentTheme.mutedStyle(_renderConfig),
  ).render(text);

  void _writeComponent(DisplayComponent component) =>
      writeConsoleComponent(component, io.writeln);

  /// Displays a task with dotted fill and DONE/FAIL/SKIPPED status.
  Future<TaskResult> task(
    String description, {
    FutureOr<TaskResult> Function()? run,
  }) => _operations.task(description, run: run);

  /// Displays two columns aligned with proper spacing.
  void twoColumnDetail(String first, [String? second]) {
    _writeComponent(
      TwoColumnDetailComponent(
        left: first,
        right: second ?? '',
        renderConfig: _renderConfig,
      ),
    );
  }

  /// Displays a bulleted list of items.
  void bulletList(Iterable<Object> items) {
    final bullet = _renderConfig
        .configureStyle(
          _styleFor('muted', io.componentTheme.mutedStyle(_renderConfig)),
        )
        .render(DotChars.bullet);
    _writeComponent(
      BulletList(
        items: items.map((e) => e.toString()).toList(),
        bullet: bullet,
        indent: 2,
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Displays a boxed alert message.
  void alert(Object message) {
    final component = Alert(renderConfig: _renderConfig)
      ..warning()
      ..displayStyle(AlertDisplayStyle.block)
      ..message(message.toString())
      ..width(_renderConfig.terminalWidth);

    final style = _styleFor(
      'alert',
      _styleFor('warning', io.componentTheme.warningStyle(_renderConfig)),
    );
    component.prefixStyle(style.bold()).borderStyle(style);

    _writeComponent(component);
    io.newLine();
  }

  /// Displays an info block with a header.
  void info(String title, Object message) {
    _writeComponent(
      TitledBlockComponent(
        title: title,
        message: message,
        titleStyle: _styleFor(
          'info',
          io.componentTheme.infoStyle(_renderConfig),
        ),
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Displays a success block with a header.
  void success(String title, Object message) {
    _writeComponent(
      TitledBlockComponent(
        title: title,
        message: message,
        titleStyle: _styleFor(
          'success',
          io.componentTheme.successStyle(_renderConfig),
        ),
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Displays a warning block with a header.
  void warn(String title, Object message) {
    _writeComponent(
      TitledBlockComponent(
        title: title,
        message: message,
        titleStyle: _styleFor(
          'warning',
          io.componentTheme.warningStyle(_renderConfig),
        ),
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Displays an error block with a header.
  void error(String title, Object message) {
    _writeComponent(
      TitledBlockComponent(
        title: title,
        message: message,
        titleStyle: _styleFor(
          'error',
          io.componentTheme.errorStyle(_renderConfig),
        ),
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Renders a definition list (term/definition pairs).
  void definitionList(Map<String, Object?> definitions) {
    if (definitions.isEmpty) return;

    _writeComponent(
      TwoColumnDetailList(renderConfig: _renderConfig)
        ..width(_renderConfig.terminalWidth)
        ..fillChar('.')
        ..fillStyle(io.componentTheme.mutedStyle(_renderConfig))
        ..rows(definitions.map((k, v) => MapEntry(k, v?.toString() ?? ''))),
    );
    io.newLine();
  }

  /// Displays a line separator.
  void line([int width = 0]) {
    final w = width > 0 ? width : (io.terminalWidth * 0.6).round();
    io.writeln(muted('-' * w));
  }

  /// Displays a horizontal rule with optional centered text.
  void rule([String? text]) {
    final width = io.terminalWidth - 4;
    final cfg = RenderConfig(
      terminalWidth: width,
      colorProfile: _renderConfig.colorProfile,
      hasDarkBackground: _renderConfig.hasDarkBackground,
    );
    final line = Rule(text: text, renderConfig: cfg).render();
    io.writeln(muted(line));
    io.newLine();
  }

  /// Runs a callback while displaying an animated spinner.
  ///
  /// Unlike [Console.task], this shows a spinner animation while the task
  /// runs, then displays a success/failure indicator.
  ///
  /// Parameters:
  /// - [message]: Text to display next to the spinner
  /// - [run]: The async function to execute
  /// - [spinner]: Spinner animation to use (default: miniDot)
  /// - [clearOnDone]: If true, remove the spinner line after completion
  /// - [showResult]: If true (default), show ✓/✗ after completion
  ///
  /// Example:
  /// ```dart
  /// final result = await io.components.spin(
  ///   'Connecting to database',
  ///   run: () => connectToDb(),
  /// );
  ///
  /// // Spinner that disappears after task
  /// await io.components.spin(
  ///   'Processing...',
  ///   run: () => process(),
  ///   clearOnDone: true,
  /// );
  /// ```
  Future<R> spin<R>(
    String message, {
    required FutureOr<R> Function() run,
    Spinner spinner = Spinners.miniDot,
    bool clearOnDone = false,
    bool showResult = true,
    String? doneMessage,
  }) => _operations.spin(
    message,
    run: run,
    spinner: spinner,
    clearOnDone: clearOnDone,
    showResult: showResult,
    doneMessage: doneMessage,
  );

  /// Runs a multi-line text editor inline and returns the submitted value.
  Future<String?> textArea(
    TextAreaModel model, {
    ProgramOptions? options,
  }) async {
    return runTextAreaPrompt(
      model,
      io.promptTerminal,
      options: options ?? promptProgramOptions,
    );
  }

  /// Displays a comment (dimmed text with // prefix).
  void comment(Object message) {
    _writeComponent(
      CommentComponent(text: message, renderConfig: _renderConfig),
    );
  }

  /// Displays a horizontal table (row-as-headers layout).
  void horizontalTable(Map<String, Object?> data) {
    _writeComponent(
      HorizontalTableComponent(
        data: data,
        padding: 2,
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }

  /// Renders an exception with pretty formatting.
  void renderException(Object exception, [StackTrace? stackTrace]) {
    io.newLine();
    _writeComponent(
      ExceptionComponent(
        exception: exception,
        stackTrace: stackTrace,
        maxStackFrames: 10,
        renderConfig: _renderConfig,
      ),
    );
    io.newLine();
  }
}
