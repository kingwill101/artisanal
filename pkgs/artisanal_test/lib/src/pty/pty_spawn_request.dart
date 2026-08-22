/// Describes the program and initial terminal state requested from a PTY
/// backend.
final class PtySpawnRequest {
  /// Creates a validated PTY spawn request.
  PtySpawnRequest({
    required this.executable,
    List<String> arguments = const <String>[],
    this.workingDirectory,
    Map<String, String>? environment,
    this.columns = 80,
    this.rows = 24,
  }) : arguments = List<String>.unmodifiable(arguments),
       environment = environment == null
           ? null
           : Map<String, String>.unmodifiable(environment) {
    if (executable.isEmpty) {
      throw ArgumentError.value(executable, 'executable', 'Must not be empty.');
    }
    _validateTerminalSize(columns: columns, rows: rows);
  }

  /// Executable passed to the backend.
  final String executable;

  /// Arguments passed to [executable].
  final List<String> arguments;

  /// Optional child working directory.
  final String? workingDirectory;

  /// Optional environment overrides or replacement map, according to the
  /// selected backend's documented environment semantics.
  ///
  /// Environment values are never written by [toTraceJson].
  final Map<String, String>? environment;

  /// Initial terminal width in character cells.
  final int columns;

  /// Initial terminal height in character cells.
  final int rows;

  /// Converts the non-secret portion of this request to trace metadata.
  ///
  /// The environment is intentionally excluded to prevent credentials and
  /// tokens from leaking into test artifacts.
  Map<String, Object?> toTraceJson() => <String, Object?>{
    'executable': executable,
    'arguments': arguments,
    if (workingDirectory != null) 'workingDirectory': workingDirectory,
    'columns': columns,
    'rows': rows,
  };

  /// Restores a request from trace metadata.
  ///
  /// Since traces redact the environment, the restored request always has a
  /// null [environment].
  factory PtySpawnRequest.fromTraceJson(Map<String, Object?> json) {
    final executable = json['executable'];
    if (executable is! String || executable.isEmpty) {
      throw const FormatException('Trace spawn executable must be a string.');
    }

    final rawArguments = json['arguments'];
    if (rawArguments is! List) {
      throw const FormatException('Trace spawn arguments must be a list.');
    }
    final arguments = <String>[];
    for (final argument in rawArguments) {
      if (argument is! String) {
        throw const FormatException(
          'Every trace spawn argument must be a string.',
        );
      }
      arguments.add(argument);
    }

    final workingDirectory = json['workingDirectory'];
    if (workingDirectory != null && workingDirectory is! String) {
      throw const FormatException(
        'Trace spawn workingDirectory must be a string or null.',
      );
    }

    return PtySpawnRequest(
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory as String?,
      columns: _readPositiveInt(json, 'columns'),
      rows: _readPositiveInt(json, 'rows'),
    );
  }
}

void _validateTerminalSize({required int columns, required int rows}) {
  if (columns <= 0) {
    throw RangeError.range(columns, 1, null, 'columns');
  }
  if (rows <= 0) {
    throw RangeError.range(rows, 1, null, 'rows');
  }
}

int _readPositiveInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int || value <= 0) {
    throw FormatException('Trace spawn $key must be a positive integer.');
  }
  return value;
}
