// tui:allow-stdout — standalone CLI tool, not a TUI program.
/// Inspect raw inline renderer trace events captured by pinned_build_dashboard.
///
/// Run:
///   dart run inspect_inline_trace.dart `build/inline-traces/<trace>.log`
library;

import 'dart:convert';
import 'dart:io';

import 'package:artisanal/runtime.dart';

void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    print('Usage: dart run inspect_inline_trace.dart <trace.log>');
    return;
  }

  final file = File(args.first);
  if (!file.existsSync()) {
    stderr.writeln('Trace not found: ${file.path}');
    exitCode = 1;
    return;
  }

  final counts = <String, int>{};
  final sizes = <String>{};
  final replayLines = <int>[];
  final rawChunks =
      <({int line, String type, int bytes, int width, int height})>[];

  for (final entry in file.readAsLinesSync().indexed) {
    final lineNo = entry.$1 + 1;
    final record = TuiTrace.tryParseEventLine(entry.$2);
    if (record == null) continue;
    counts.update(record.type, (value) => value + 1, ifAbsent: () => 1);

    final fields = record.fields;
    final width =
        _intField(fields, 'terminalWidth') ?? _intField(fields, 'width');
    final height =
        _intField(fields, 'terminalHeight') ?? _intField(fields, 'height');
    if (width != null && height != null) {
      sizes.add('${width}x$height');
    }

    if (record.type == 'inline.flush' && fields['replayLogBand'] == true) {
      replayLines.add(lineNo);
    }

    if (record.type.startsWith('inline.ansi.')) {
      rawChunks.add((
        line: lineNo,
        type: record.type,
        bytes: _intField(fields, 'byteLength') ?? 0,
        width: width ?? 0,
        height: height ?? 0,
      ));

      final encoded = fields['base64'];
      if (encoded is String) {
        // Validate the payload while inspecting so corrupt traces fail early.
        base64Decode(encoded);
      }
    }
  }

  print('Trace: ${file.path}');
  print('Events:');
  for (final key in counts.keys.toList()..sort()) {
    print('  $key: ${counts[key]}');
  }
  print('Sizes: ${sizes.join(', ')}');
  print('Replay flush lines: ${replayLines.join(', ')}');
  print('Raw ANSI chunks: ${rawChunks.length}');
  for (final chunk in rawChunks.take(20)) {
    print(
      '  line ${chunk.line}: ${chunk.type} '
      '${chunk.bytes} bytes @ ${chunk.width}x${chunk.height}',
    );
  }
  if (rawChunks.length > 20) {
    print('  ... ${rawChunks.length - 20} more');
  }
}

int? _intField(Map<String, Object?> fields, String key) {
  final value = fields[key];
  return value is int ? value : null;
}
