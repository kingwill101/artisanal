import '../style/style.dart';
import '../tui/bubbles/data_table.dart';
import '../tui/bubbles/number_input.dart';
import '../tui/bubbles/password.dart';
import '../tui/bubbles/prompt.dart'
    show
        runDataTablePrompt,
        runMultiSearchPrompt,
        runMultiSelectPrompt,
        runNumberInputPrompt,
        runPasswordPrompt,
        runSearchPrompt,
        runSelectPrompt,
        runSuggestPrompt;
import '../tui/bubbles/search.dart';
import '../tui/bubbles/select.dart';
import '../tui/bubbles/suggest.dart';
import '../tui/bubbles/table.dart' show Column;
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
      final raw = defaultValue?.toString();
      if (raw == null) {
        throw StateError('Cannot prompt in non-interactive mode.');
      }
      final error = validator(raw);
      if (error != null) throw StateError(error);
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

  /// Runs an interactive single-select prompt.
  Future<T?> selectChoice<T>(
    String question, {
    required List<T> choices,
    int? defaultIndex,
    String Function(T)? display,
  }) async {
    if (!host.interactive) {
      if (defaultIndex != null &&
          defaultIndex >= 0 &&
          defaultIndex < choices.length) {
        return choices[defaultIndex];
      }
      throw StateError('Cannot prompt in non-interactive mode.');
    }
    return await runSelectPrompt(
      SelectModel<T>(
        items: choices,
        title: question,
        initialIndex: defaultIndex ?? 0,
        display: display,
        styles: _selectStyles(),
      ),
      host.promptTerminal,
    );
  }

  /// Runs an interactive multi-select prompt.
  Future<List<T>> multiSelectChoice<T>(
    String question, {
    required List<T> choices,
    List<int> defaultSelected = const [],
    String Function(T)? display,
  }) async {
    final defaults = defaultSelected
        .where((index) => index >= 0 && index < choices.length)
        .toSet();
    if (!host.interactive) {
      return defaults.map((index) => choices[index]).toList();
    }
    final result = await runMultiSelectPrompt(
      MultiSelectModel<T>(
        items: choices,
        title: question,
        initialIndex: defaults.isNotEmpty ? defaults.first : 0,
        initialSelected: defaults,
        display: display,
        styles: _multiSelectStyles(),
      ),
      host.promptTerminal,
    );
    return result ?? [];
  }

  /// Runs an interactive fuzzy-search prompt.
  Future<T?> search<T>(
    String question, {
    required List<T> items,
    String Function(T)? display,
    String placeholder = 'Type to search...',
    String noResultsText = 'No matches found',
  }) async {
    if (!host.interactive) {
      return items.isNotEmpty ? items.first : null;
    }
    return await runSearchPrompt(
      SearchModel<T>(
        items: items,
        title: question,
        display: display,
        placeholder: placeholder,
        noResultsText: noResultsText,
        styles: _searchStyles(),
      ),
      host.promptTerminal,
    );
  }

  /// Runs an interactive multi-selection fuzzy-search prompt.
  Future<List<T>> multiSearch<T>(
    String question, {
    required List<T> items,
    String Function(T)? display,
    String placeholder = 'Type to search...',
    String noResultsText = 'No matches found',
    String? hint,
  }) async {
    if (!host.interactive) return [];
    final result = await runMultiSearchPrompt(
      MultiSearchModel<T>(
        items: items,
        title: question,
        display: display,
        placeholder: placeholder,
        noResultsText: noResultsText,
        hint: hint ?? '(Space to toggle, ^a to toggle all, Enter to confirm)',
        styles: _searchStyles(),
      ),
      host.promptTerminal,
    );
    return result ?? [];
  }

  /// Runs an interactive searchable data-table prompt.
  Future<T?> dataTable<T>(
    String question, {
    required List<Column> columns,
    required List<T> items,
    required List<String> Function(T) rowBuilder,
    int pageSize = 10,
  }) async {
    if (!host.interactive) {
      return items.isNotEmpty ? items.first : null;
    }
    final themed = host.componentTheme.dataTableStyles(host.renderConfig);
    return await runDataTablePrompt<T>(
      DataTableModel<T>(
        items: items,
        columns: columns,
        rowBuilder: rowBuilder,
        title: question,
        pageSize: pageSize,
        styles: DataTableStyles(
          title: _resolve(themed.title, 'question'),
          prompt: _resolve(themed.prompt, 'info'),
          tableHeader: _resolve(themed.tableHeader, 'info'),
          tableCell: themed.tableCell,
          tableSelected: _resolve(themed.tableSelected, 'alert'),
          dimmed: _resolve(themed.dimmed, 'muted'),
          noResults: themed.noResults,
        ),
      ),
      host.promptTerminal,
    );
  }

  /// Runs an interactive suggestion prompt.
  Future<String?> suggest(
    String question, {
    required List<String> options,
    String placeholder = '',
    String? defaultValue,
    int scroll = 5,
    String hint = '',
  }) async {
    if (!host.interactive) return defaultValue;
    return await runSuggestPrompt(
      SuggestModel(
        prompt: question,
        options: options,
        placeholder: placeholder,
        defaultValue: defaultValue ?? '',
        scroll: scroll,
        hint: hint,
        styles: _suggestStyles(),
      ),
      host.promptTerminal,
    );
  }

  Style _promptStyle() => _styleFor(
    'question',
    themed: host.componentTheme.promptStyle(host.renderConfig),
  );

  Style _styleFor(String role, {Style? themed}) => resolveConsoleComponentStyle(
    themed ?? host.componentTheme.errorStyle(host.renderConfig),
    host.getStyle(role),
  );

  Style _resolve(Style themed, String role) =>
      resolveConsoleComponentStyle(themed, host.getStyle(role));

  SelectStyles _selectStyles() {
    final themed = host.componentTheme.selectStyles(host.renderConfig);
    return SelectStyles(
      title: _resolve(themed.title, 'question'),
      item: themed.item,
      selectedItem: themed.selectedItem,
      cursor: themed.cursor,
      dimmed: _resolve(themed.dimmed, 'muted'),
      cursorPrefix: themed.cursorPrefix,
      itemPrefix: themed.itemPrefix,
    );
  }

  MultiSelectStyles _multiSelectStyles() {
    final themed = host.componentTheme.multiSelectStyles(host.renderConfig);
    return MultiSelectStyles(
      title: _resolve(themed.title, 'question'),
      item: themed.item,
      highlightedItem: themed.highlightedItem,
      selectedIcon: themed.selectedIcon,
      unselectedIcon: themed.unselectedIcon,
      dimmed: _resolve(themed.dimmed, 'muted'),
      cursorPrefix: themed.cursorPrefix,
      selectedIconChar: themed.selectedIconChar,
      unselectedIconChar: themed.unselectedIconChar,
    );
  }

  SearchStyles _searchStyles() {
    final themed = host.componentTheme.searchStyles(host.renderConfig);
    return SearchStyles(
      title: _resolve(themed.title, 'question'),
      prompt: _resolve(themed.prompt, 'info'),
      item: themed.item,
      selectedItem: themed.selectedItem,
      matchHighlight: themed.matchHighlight,
      cursor: themed.cursor,
      dimmed: _resolve(themed.dimmed, 'muted'),
      noResults: themed.noResults,
      selectedIcon: themed.selectedIcon,
      unselectedIcon: themed.unselectedIcon,
      selectedIconChar: themed.selectedIconChar,
      unselectedIconChar: themed.unselectedIconChar,
      cursorPrefix: themed.cursorPrefix,
      itemPrefix: themed.itemPrefix,
    );
  }

  SuggestStyles _suggestStyles() {
    final themed = host.componentTheme.suggestStyles(host.renderConfig);
    return SuggestStyles(
      title: _resolve(themed.title, 'question'),
      value: themed.value,
      placeholder: themed.placeholder,
      highlighted: themed.highlighted,
      suggestion: themed.suggestion,
      hint: themed.hint,
      dimmed: _resolve(themed.dimmed, 'muted'),
      pointer: themed.pointer,
    );
  }
}
