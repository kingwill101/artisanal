import '../terminal/terminal.dart';
import '../style/style.dart';
import '../tui/bubbles/components/base.dart';
import 'component_theme.dart';

/// Internal console capabilities needed by interactive operation helpers.
abstract interface class ConsoleOperationHost {
  /// Whether interactive operations are enabled.
  bool get interactive;

  /// Terminal used for cursor-driven inline operations.
  Terminal get promptTerminal;

  /// Current component rendering configuration.
  RenderConfig get renderConfig;

  /// Theme used by interactive components.
  ComponentTheme get componentTheme;

  /// Looks up a named semantic style override.
  Style? getStyle(String name);

  /// Writes raw output without a trailing newline.
  void write(String text);

  /// Writes one output line.
  void writeln([String line = '']);

  /// Writes one or more blank lines.
  void newLine([int count = 1]);
}

/// Internal console capabilities needed by synchronous prompts.
abstract interface class ConsolePromptHost implements ConsoleOperationHost {
  /// Reads one line from the configured input source.
  String? readConsoleLine();

  /// Uses the configured secret reader, or returns null when none is installed.
  String? readConfiguredSecret(String prompt, {String? fallback});

  /// Writes one error line.
  void writelnErr([String line = '']);
}

/// Whether a console operation should use cursor-driven interactive output.
///
/// The terminal is resolved lazily so non-interactive consoles do not allocate
/// or inspect a terminal merely to select their plain-output fallback.
bool supportsInteractiveConsole(
  bool interactive,
  Terminal Function() terminal,
) => interactive && terminal().supportsAnsi;
