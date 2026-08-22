import 'dart:convert';
import 'dart:typed_data';

/// A timestamped interaction observed during a PTY session.
sealed class PtyEvent {
  /// Creates an event at [elapsed] time since the session was attached.
  const PtyEvent(this.elapsed);

  /// Monotonic time elapsed since session attachment.
  final Duration elapsed;

  /// Stable event type used by the JSONL trace format.
  String get type;

  /// Converts this event to a JSON-compatible map.
  Map<String, Object?> toJson();

  /// Restores an event from a JSON-compatible map.
  static PtyEvent fromJson(Map<String, Object?> json) {
    final type = json['type'];
    if (type is! String) {
      throw const FormatException('PTY event type must be a string.');
    }

    final elapsed = Duration(
      microseconds: _readNonNegativeInt(json, 'elapsedMicros'),
    );

    return switch (type) {
      'output' => PtyOutputEvent(
        elapsed: elapsed,
        bytes: _readBytes(json, 'bytes'),
      ),
      'input' => PtyInputEvent(
        elapsed: elapsed,
        bytes: _readBytes(json, 'bytes'),
      ),
      'resize' => PtyResizeEvent(
        elapsed: elapsed,
        columns: _readPositiveInt(json, 'columns'),
        rows: _readPositiveInt(json, 'rows'),
      ),
      'exit' => PtyExitEvent(
        elapsed: elapsed,
        exitCode: _readInt(json, 'exitCode'),
      ),
      _ => throw FormatException('Unknown PTY event type: $type.'),
    };
  }

  /// Common JSON fields shared by every event.
  Map<String, Object?> _baseJson() => <String, Object?>{
    'type': type,
    'elapsedMicros': elapsed.inMicroseconds,
  };
}

/// Raw bytes emitted by the PTY child.
final class PtyOutputEvent extends PtyEvent {
  /// Creates an output event, defensively copying [bytes].
  PtyOutputEvent({required super.elapsed, required List<int> bytes})
    : bytes = Uint8List.fromList(bytes);

  /// Output bytes in the order received from the backend.
  final Uint8List bytes;

  @override
  String get type => 'output';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    ..._baseJson(),
    'bytes': base64Encode(bytes),
  };
}

/// Raw bytes successfully written to the PTY input side.
final class PtyInputEvent extends PtyEvent {
  /// Creates an input event, defensively copying [bytes].
  PtyInputEvent({required super.elapsed, required List<int> bytes})
    : bytes = Uint8List.fromList(bytes);

  /// Input bytes accepted by the backend.
  final Uint8List bytes;

  @override
  String get type => 'input';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    ..._baseJson(),
    'bytes': base64Encode(bytes),
  };
}

/// A successful terminal resize request.
final class PtyResizeEvent extends PtyEvent {
  /// Creates a resize event.
  const PtyResizeEvent({
    required super.elapsed,
    required this.columns,
    required this.rows,
  });

  /// New terminal width in character cells.
  final int columns;

  /// New terminal height in character cells.
  final int rows;

  @override
  String get type => 'resize';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    ..._baseJson(),
    'columns': columns,
    'rows': rows,
  };
}

/// The child process exit status.
final class PtyExitEvent extends PtyEvent {
  /// Creates an exit event.
  const PtyExitEvent({required super.elapsed, required this.exitCode});

  /// Platform-normalized child exit code reported by the backend.
  final int exitCode;

  @override
  String get type => 'exit';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    ..._baseJson(),
    'exitCode': exitCode,
  };
}

Uint8List _readBytes(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('PTY event $key must be a base64 string.');
  }
  try {
    return Uint8List.fromList(base64Decode(value));
  } on FormatException catch (error) {
    throw FormatException('PTY event $key is not valid base64.', error);
  }
}

int _readInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('PTY event $key must be an integer.');
  }
  return value;
}

int _readNonNegativeInt(Map<String, Object?> json, String key) {
  final value = _readInt(json, key);
  if (value < 0) {
    throw FormatException('PTY event $key must not be negative.');
  }
  return value;
}

int _readPositiveInt(Map<String, Object?> json, String key) {
  final value = _readInt(json, key);
  if (value <= 0) {
    throw FormatException('PTY event $key must be positive.');
  }
  return value;
}
