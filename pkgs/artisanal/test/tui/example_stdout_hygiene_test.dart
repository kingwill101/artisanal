import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('tui examples avoid direct stdout/stderr writes', () {
    var root = Directory('packages/artisanal/example/tui');
    if (!root.existsSync()) {
      root = Directory('example/tui');
    }
    expect(root.existsSync(), isTrue, reason: 'Missing ${root.path}');

    const allowMarker = 'tui:allow-stdout';

    final bannedPatterns = <RegExp>[
      RegExp(r'\bprint\s*\('),
      RegExp(r'\bio\.(stdout|stderr)\s*\.(write|writeln)\s*\('),
      // Catch unprefixed `stdout.*` / `stderr.*` (dart:io globals) but avoid
      // false-positives like `result.stderr`.
      RegExp(r'(^|[^\w.])stdout\s*\.(write|writeln)\s*\('),
      RegExp(r'(^|[^\w.])stderr\s*\.(write|writeln)\s*\('),
      // Catch direct terminal writes inside examples (these bypass the
      // renderer/program pipeline and can desync UV rendering).
      RegExp(r'\bterminal\s*\.(write|writeln)\s*\('),
    ];

    final violations = <String>[];

    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final normalized = entity.path.replaceAll('\\', '/');
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains(allowMarker)) continue;
        for (final pattern in bannedPatterns) {
          if (pattern.hasMatch(line)) {
            violations.add('$normalized:${i + 1} matches ${pattern.pattern}');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Direct stdout/stderr writes desync UV renderer; use Cmd.println/WriteRawMsg instead.\n'
          '${violations.join('\n')}',
    );
  });
}
