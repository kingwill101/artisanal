/// Utilities for formatting command listings in help output.
library;

/// Indents each line of [input] by [spaces] spaces.
String indentBlock(String input, int spaces) {
  final prefix = ' ' * spaces;
  return input
      .split('\n')
      .map((line) => line.isEmpty ? line : '$prefix$line')
      .join('\n');
}

/// Formats option usage text, highlighting option names.
///
/// [usage] is the raw output from `argParser.usage`.
/// [styleOption] is an optional callback to style the option flags (e.g. `--foo`).
String formatOptionsUsage(
  String usage, {
  String Function(String text)? styleOption,
}) {
  final lines = usage.split('\n');
  final styled = <String>[];
  for (final line in lines) {
    if (line.trim().isEmpty) {
      styled.add(line);
      continue;
    }

    final match = RegExp(r'^(\s*)(.*)$').firstMatch(line);
    if (match == null) {
      styled.add(line);
      continue;
    }

    final indent = match.group(1) ?? '';
    final rest = match.group(2) ?? '';
    final split = RegExp(r'\s{2,}').firstMatch(rest);
    if (split == null) {
      styled.add(line);
      continue;
    }

    final left = rest.substring(0, split.start).trimRight();
    final spacing = rest.substring(split.start, split.end);
    final right = rest.substring(split.end);

    final formattedLeft = styleOption != null ? styleOption(left) : left;
    styled.add('$indent$formattedLeft$spacing$right');
  }

  return styled.join('\n');
}

/// Formats a list of commands for display, grouping by namespace.
///
/// Commands are grouped by their namespace prefix (e.g., `ui:task` belongs
/// to the `ui` namespace). Ungrouped commands appear first.
///
/// ```dart
/// final output = formatCommandListing(
///   entries,
///   namespaceSeparator: ':',
///   styleNamespace: style.heading,
///   styleCommand: style.command,
/// );
/// ```
String formatCommandListing(
  Iterable<CommandListingEntry> entries, {
  required String namespaceSeparator,
  String Function(String text)? styleNamespace,
  String Function(String text)? styleCommand,
}) {
  final list = entries.toList(growable: false);
  if (list.isEmpty) return '';

  final unnamed = <CommandListingEntry>[];
  final grouped = <String, List<CommandListingEntry>>{};

  for (final entry in list) {
    final ns = _namespaceFor(entry.name, namespaceSeparator);
    if (ns == null) {
      unnamed.add(entry);
      continue;
    }
    grouped.putIfAbsent(ns, () => []).add(entry);
  }

  unnamed.sort((a, b) => a.name.compareTo(b.name));
  for (final group in grouped.values) {
    group.sort((a, b) => a.name.compareTo(b.name));
  }

  final maxName = list
      .map((e) => e.name.length)
      .fold<int>(0, (m, v) => v > m ? v : m);

  final buffer = StringBuffer();

  for (final entry in unnamed) {
    buffer.writeln(
      _formatCommandLine(entry, nameWidth: maxName, styleCommand: styleCommand),
    );
  }

  final namespaces = grouped.keys.toList()..sort();
  if (unnamed.isNotEmpty && namespaces.isNotEmpty) {
    buffer.writeln();
  }
  for (final ns in namespaces) {
    buffer.writeln(styleNamespace == null ? ns : styleNamespace(ns));
    for (final entry in grouped[ns]!) {
      buffer.writeln(
        _formatCommandLine(
          entry,
          nameWidth: maxName,
          styleCommand: styleCommand,
        ),
      );
    }
    if (ns != namespaces.last) {
      buffer.writeln();
    }
  }

  return buffer.toString().trimRight();
}

String? _namespaceFor(String name, String separator) {
  final index = name.indexOf(separator);
  if (index <= 0) return null;
  final ns = name.substring(0, index).trim();
  return ns.isEmpty ? null : ns;
}

String _formatCommandLine(
  CommandListingEntry entry, {
  required int nameWidth,
  String Function(String text)? styleCommand,
}) {
  final rawName = entry.name;
  final padding = nameWidth - rawName.length;
  final name =
      (styleCommand == null ? rawName : styleCommand(rawName)) +
      (' ' * (padding > 0 ? padding : 0));
  final description = entry.description.trim();
  if (description.isEmpty) {
    return '  $name';
  }
  return '  $name  $description';
}

/// An entry in a command listing.
class CommandListingEntry {
  /// Creates a new command listing entry.
  CommandListingEntry({required this.name, required this.description});

  /// The command name (e.g., `ui:task`).
  final String name;

  /// A brief description of the command.
  final String description;
}
