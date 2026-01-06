import 'dart:convert';

import 'package:ormed_cli/runtime.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  test('formatPretendEntry emits normalized JSON log entries', () {
    final payload = DocumentStatementPayload(
      command: 'find',
      arguments: {
        'filter': {'title': 'Dart'},
      },
    );
    final preview = StatementPreview(payload: payload);
    final entry = QueryLogEntry(
      type: 'query',
      preview: preview,
      duration: const Duration(milliseconds: 5),
      success: true,
    );

    final formatted = formatPretendEntry(entry);
    final decoded = jsonDecode(formatted) as Map<String, Object?>;

    expect(decoded['type'], 'document');
    expect(decoded['command'], 'find');
    expect(
      decoded['arguments'],
      equals({
        'filter': {'title': 'Dart'},
      }),
    );
    expect(
      decoded['duration_ms'],
      equals(entry.duration.inMicroseconds / 1000),
    );
    expect(decoded['success'], isTrue);
  });
}
