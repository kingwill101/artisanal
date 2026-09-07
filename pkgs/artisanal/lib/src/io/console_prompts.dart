import '../style/style.dart';
import '../tui/bubbles/number_input.dart';
import '../tui/bubbles/password.dart';
import '../tui/bubbles/prompt.dart'
    show runNumberInputPrompt, runPasswordPrompt;
import 'console_context.dart';
import 'console_presentation.dart';
import 'validators.dart';

/// Shared implementation of synchronous console prompts.
final class ConsolePrompts {
  /// Creates prompts backed by [host].
  ConsolePrompts(this.host);

  /// Input, output, and presentation capabilities used by prompts.
  final ConsolePromptHost host;

  /// Prompts for a yes/no response.
  bool confirm(String question, {bool defaultValue = true}) {
    if (!host.interactive) return defaultValue;

    final suffix = defaultValue ? '[Y/n]' : '[y/N]';
    host.write('${_promptStyle().render(question)} $suffix ');
    final input = (host.readConsoleLine() ?? '').trim().toLowerCase();
    return switch (input) {
      'y' || 'yes' => true,
      'n' || 'no' => false,
      _ => defaultValue,
    };
  }

  /// Prompts for validated text input.
  String ask(
    String question, {
    String? defaultValue,
    String? Function(String value)? validator,
    int attempts = 3,
  }) {
    if (!host.interactive) {
      if (defaultValue != null) return defaultValue;
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    for (var attempt = 0; attempt < attempts; attempt++) {
      final suffix = defaultValue == null ? '' : ' [$defaultValue]';
      host.write('${_promptStyle().render(question)}$suffix: ');
      final raw = host.readConsoleLine();
      final value = (raw == null || raw.isEmpty) ? (defaultValue ?? '') : raw;
      final error = validator?.call(value);
      if (error == null) return value;
      host.writelnErr(_styleFor('error').render('Error: $error'));
    }

    throw StateError('Too many invalid attempts.');
  }

  /// Prompts for secret input without echo.
  Future<String> secret(String question, {String? fallback}) async {
    if (!host.interactive) {
      if (fallback != null) return fallback;
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    final configured = host.readConfiguredSecret(question, fallback: fallback);
    if (configured != null) return configured;

    final result = await runPasswordPrompt(
      PasswordModel(
        prompt: question,
        styles: host.componentTheme.passwordStyles(host.renderConfig),
      ),
      host.promptTerminal,
    );
    if (result != null) return result;
    if (fallback != null) return fallback;
    throw StateError('Password prompt cancelled.');
  }

  /// Prompts for one or more choices using numbered text input.
  Object choice(
    String question, {
    required List<String> choices,
    int? defaultIndex,
    bool multiSelect = false,
  }) {
    if (!host.interactive) {
      if (defaultIndex != null &&
          defaultIndex >= 0 &&
          defaultIndex < choices.length) {
        return multiSelect
            ? <String>[choices[defaultIndex]]
            : choices[defaultIndex];
      }
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    host.writeln(_promptStyle().render(question));
    for (var index = 0; index < choices.length; index++) {
      host.writeln('  [$index] ${choices[index]}');
    }

    if (!multiSelect) {
      final raw = ask(
        defaultIndex == null
            ? 'Select an option'
            : 'Select an option [$defaultIndex]',
        defaultValue: defaultIndex?.toString(),
      );
      final selected = int.tryParse(raw);
      if (selected == null || selected < 0 || selected >= choices.length) {
        throw StateError('Invalid selection: $raw');
      }
      return choices[selected];
    }

    final raw = ask(
      defaultIndex == null
          ? 'Select options (comma separated)'
          : 'Select options (comma separated) [$defaultIndex]',
      defaultValue: defaultIndex?.toString(),
    );
    final parts = raw
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    final selected = <String>[];
    for (final part in parts) {
      final index = int.tryParse(part);
      if (index == null || index < 0 || index >= choices.length) {
        throw StateError('Invalid selection: $part');
      }
      selected.add(choices[index]);
    }
    return selected;
  }

  /// Prompts for a numeric value.
  Future<num> number(
    String question, {
    num? defaultValue,
    num? min,
    num? max,
    num step = 1,
    int attempts = 3,
    String hint = '',
  }) async {
    if (!host.interactive) {
      final validator = Validators.combine([
        Validators.required(),
        Validators.numeric(min: min, max: max),
      ]);
      final raw = ask(
        question,
        defaultValue: defaultValue?.toString(),
        validator: (value) {
          try {
            return validator(value);
          } catch (error) {
            return error.toString();
          }
        },
        attempts: attempts,
      );
      return num.parse(raw);
    }

    final result = await runNumberInputPrompt(
      NumberInputModel(
        prompt: question,
        defaultValue: defaultValue,
        min: min,
        max: max,
        step: step,
        hint: hint,
        styles: host.componentTheme.numberInputStyles(host.renderConfig),
      ),
      host.promptTerminal,
    );
    if (result != null) return result;
    if (defaultValue != null) return defaultValue;
    throw StateError('Number prompt cancelled.');
  }

  Style _promptStyle() => _styleFor(
    'question',
    themed: host.componentTheme.promptStyle(host.renderConfig),
  );

  Style _styleFor(String role, {Style? themed}) => resolveConsoleComponentStyle(
    themed ?? host.componentTheme.errorStyle(host.renderConfig),
    host.getStyle(role),
  );
}
