import 'dart:convert';
import 'dart:typed_data';

import 'pty_event.dart';
import 'pty_spawn_request.dart';

/// Immutable capture of a PTY scenario.
final class PtyTrace {
  /// Creates a trace from [request] and ordered [events].
  PtyTrace({
    required this.request,
    required Iterable<PtyEvent> events,
  }) : events = List<PtyEvent>.unmodifiable(events);

  /// Current trace schema version.
  static const int schemaVersion = 1;

  /// Redacted process metadata associated with the trace.
  final PtySpawnRequest request;

  /// Events in capture order.
  final List<PtyEvent> events;

  /// Concatenated output bytes, independent of backend chunk boundaries.
  Uint8List get outputBytes {
    final builder = BytesBuilder(copy: false);
    for (final event in events) {
      if (event is PtyOutputEvent) {
        builder.add(event.bytes);
      }
    }
    return builder.takeBytes();
  }

  /// Concatenated input bytes in successful write order.
  Uint8List get inputBytes {
    final builder = BytesBuilder(copy: false);
    for (final event in events) {
      if (event is PtyInputEvent) {
        builder.add(event.bytes);
      }
    }
    return builder.takeBytes();
  }

  /// Convenience UTF-8 view of [outputBytes].
  ///
  /// Raw bytes remain the source of truth. Malformed byte sequences are
  /// replaced only in this diagnostic view.
  String get outputText => utf8.decode(outputBytes, allowMalformed: true);

  /// Elapsed time of the final event, or zero for an empty trace.
  Duration get duration => events.isEmpty ? Duration.zero : events.last.elapsed;

  /// Serializes this trace as newline-delimited JSON.
  ///
  /// The first line contains schema and spawn metadata; subsequent lines are
  /// individual events. A trailing newline is included for append-friendly
  /// tooling.
  String toJsonLines() {
    final lines = <String>[
      jsonEncode(<String, Object?>{
        'type': 'trace',
        'schemaVersion': schemaVersion,
        'spawn': request.toTraceJson(),
      }),
      for (final event in events) jsonEncode(event.toJson()),
    ];
    return '${lines.join('\n')}\n';
  }

  /// Parses a trace produced by [toJsonLines].
  factory PtyTrace.fromJsonLines(String source) {
    final lines = source
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      throw const FormatException('PTY trace is empty.');
    }

    final metadata = _decodeMap(lines.first, lineNumber: 1);
    if (metadata['type'] != 'trace') {
      throw const FormatException('PTY trace metadata type must be "trace".');
    }
    if (metadata['schemaVersion'] != schemaVersion) {
      throw FormatException(
        'Unsupported PTY trace schema version: '
        '${metadata['schemaVersion']}.',
      );
    }

    final spawn = metadata['spawn'];
    if (spawn is! Map) {
      throw const FormatException('PTY trace spawn metadata must be an object.');
    }

    final events = <PtyEvent>[];
    for (var index = 1; index < lines.length; index++) {
      events.add(
        PtyEvent.fromJson(_decodeMap(lines[index], lineNumber: index + 1)),
      );
    }

    return PtyTrace(
      request: PtySpawnRequest.fromTraceJson(
        Map<String, Object?>.from(spawn),
      ),
      events: events,
    );
  }
}

Map<String, Object?> _decodeMap(String source, {required int lineNumber}) {
  Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException catch (error) {
    throw FormatException('Invalid JSON on PTY trace line $lineNumber.', error);
  }
  if (decoded is! Map) {
    throw FormatException('PTY trace line $lineNumber must be a JSON object.');
  }
  return Map<String, Object?>.from(decoded);
}
