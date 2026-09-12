import 'dart:convert';
import 'dart:io';

/// Regenerates the checked-in Dart map used by standalone OpenCode builds.
///
/// Run from the repository root:
/// `dart run apps/opencode/tool/generate_assets.dart`
void main() {
  final root = Directory('apps/opencode');
  final entries = <String, String>{};
  for (final kind in ['themes', 'scenarios']) {
    final directory = Directory('${root.path}/$kind');
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = file.uri.pathSegments.last.replaceFirst(
        RegExp(r'\.json$'),
        '',
      );
      final decoded = jsonDecode(file.readAsStringSync());
      entries['$kind/$name'] = '${jsonEncode(decoded)}\n';
    }
  }

  final output = StringBuffer(
    '// GENERATED FILE. Run dart run apps/opencode/tool/generate_assets.dart.\n'
    'library;\n\n'
    '/// Canonical JSON for built-in OpenCode themes and replay scenarios.\n'
    'const Map<String, String> openCodeBuiltinAssets = '
    '<String, String>{\n',
  );
  for (final entry in entries.entries) {
    // JSON string syntax is also valid Dart double-quoted string syntax.
    // Escape interpolation markers, which JSON itself does not escape.
    final source = jsonEncode(entry.value).replaceAll(r'$', r'\$');
    output
      ..write('  ${jsonEncode(entry.key)}: ')
      ..write(source)
      ..writeln(',');
  }
  output.write('};\n');
  File(
    '${root.path}/lib/src/opencode/generated/builtin_assets.dart',
  ).writeAsStringSync(output.toString());
}
