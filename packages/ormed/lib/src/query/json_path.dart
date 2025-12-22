final RegExp _jsonSimpleProperty = RegExp(r'^[A-Za-z0-9_]+$');

/// Normalized reference to a JSON selector (column + path).
class JsonSelector {
  /// Creates a new [JsonSelector].
  const JsonSelector(this.column, this.path, this.extractsText);

  /// The column name containing the JSON data.
  final String column;

  /// The JSON path within the column.
  final String path;

  /// Whether the value should be extracted as text (e.g. using `->>` operator).
  final bool extractsText;
}

/// Whether [expression] contains a JSON selector operator.
bool hasJsonSelector(String expression) => expression.contains('->');

/// Attempts to parse [expression] into a [JsonSelector]. Returns null when no
/// JSON operator is present.
JsonSelector? parseJsonSelectorExpression(String expression) {
  if (!hasJsonSelector(expression)) {
    return null;
  }
  final operator = expression.contains('->>') ? '->>' : '->';
  final parts = expression.split(operator);
  if (parts.length < 2) {
    return null;
  }
  final field = parts.first.trim();
  final rawPath = parts.sublist(1).join(operator).trim();
  if (rawPath.isEmpty) {
    return JsonSelector(field, r'$', operator == '->>');
  }
  final normalized = normalizeJsonPath(rawPath);
  return JsonSelector(field, normalized, operator == '->>');
}

/// Normalizes a user-supplied JSON path expression into a canonical
/// representation starting with `$`.
String normalizeJsonPath(String rawPath) {
  final stripped = _stripJsonPathWrapper(rawPath);
  final tokens = _tokenizeJsonPath(stripped);
  return _buildNormalizedJsonPath(tokens);
}

/// Splits a normalized JSON path (starting with `$`) into its individual
/// segments.
List<String> jsonPathSegments(String normalizedPath) =>
    _segmentsFromNormalizedPath(normalizedPath);

String _stripJsonPathWrapper(String path) {
  final trimmed = path.trim();
  if (trimmed.length >= 2) {
    final quote = trimmed[0];
    if ((quote == '\'' || quote == '"') && trimmed.endsWith(quote)) {
      return trimmed.substring(1, trimmed.length - 1);
    }
  }
  return trimmed;
}

List<_JsonPathToken> _tokenizeJsonPath(String rawPath) {
  final input = rawPath.trim();
  if (input.isEmpty) {
    return const <_JsonPathToken>[];
  }
  final tokens = <_JsonPathToken>[];

  bool isDotIndexToken(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return false;
    if (cleaned == '0') return true;
    if (cleaned.startsWith('0')) return false;
    return int.tryParse(cleaned) != null;
  }

  void addProperty(String value, {bool quoted = false}) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;
    final needsQuoting = quoted || !_jsonSimpleProperty.hasMatch(cleaned);
    tokens.add(
      _JsonPathToken(cleaned, isArrayIndex: false, needsQuoting: needsQuoting),
    );
  }

  void addIndex(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;
    tokens.add(_JsonPathToken(cleaned, isArrayIndex: true));
  }

  var index = 0;
  while (index < input.length) {
    final char = input[index];
    if (char == r'$') {
      index += 1;
      continue;
    }
    if (char == '.') {
      index += 1;
      final buffer = StringBuffer();
      while (index < input.length &&
          input[index] != '.' &&
          input[index] != '[') {
        buffer.write(input[index]);
        index += 1;
      }
      final segment = buffer.toString().trim();
      if (isDotIndexToken(segment)) {
        addIndex(segment);
      } else {
        addProperty(segment);
      }
      continue;
    }
    if (char == '[') {
      index += 1;
      if (index < input.length &&
          (input[index] == '"' || input[index] == '\'')) {
        final quote = input[index];
        index += 1;
        final buffer = StringBuffer();
        while (index < input.length) {
          final current = input[index];
          if (current == '\\' && index + 1 < input.length) {
            buffer.write(input[index + 1]);
            index += 2;
            continue;
          }
          if (current == quote) {
            index += 1;
            break;
          }
          buffer.write(current);
          index += 1;
        }
        while (index < input.length && input[index] != ']') {
          index += 1;
        }
        if (index < input.length && input[index] == ']') {
          index += 1;
        }
        addProperty(buffer.toString(), quoted: true);
      } else {
        final buffer = StringBuffer();
        while (index < input.length && input[index] != ']') {
          buffer.write(input[index]);
          index += 1;
        }
        if (index < input.length && input[index] == ']') {
          index += 1;
        }
        final value = buffer.toString().trim();
        if (value.isEmpty) {
          continue;
        }
        final numeric = int.tryParse(value) != null;
        if (numeric) {
          addIndex(value);
        } else {
          addProperty(value, quoted: true);
        }
      }
      continue;
    }
    final buffer = StringBuffer();
    while (index < input.length && input[index] != '.' && input[index] != '[') {
      buffer.write(input[index]);
      index += 1;
    }
    addProperty(buffer.toString());
  }
  return tokens;
}

String _buildNormalizedJsonPath(List<_JsonPathToken> tokens) {
  if (tokens.isEmpty) {
    return r'$';
  }
  final buffer = StringBuffer(r'$');
  for (final token in tokens) {
    if (token.isArrayIndex) {
      buffer
        ..write('[')
        ..write(token.value)
        ..write(']');
      continue;
    }
    if (token.needsQuoting) {
      final escaped = token.value
          .replaceAll('\\', r'\\')
          .replaceAll('"', r'\"');
      buffer
        ..write('["')
        ..write(escaped)
        ..write('"]');
      continue;
    }
    buffer
      ..write('.')
      ..write(token.value);
  }
  return buffer.toString();
}

List<String> _segmentsFromNormalizedPath(String path) {
  if (path.isEmpty) {
    return const [];
  }
  final segments = <String>[];
  var index = 0;
  while (index < path.length) {
    final char = path[index];
    if (char == r'$') {
      index += 1;
      continue;
    }
    if (char == '.') {
      index += 1;
      final buffer = StringBuffer();
      while (index < path.length && path[index] != '.' && path[index] != '[') {
        buffer.write(path[index]);
        index += 1;
      }
      final value = buffer.toString();
      if (value.isNotEmpty) {
        segments.add(value);
      }
      continue;
    }
    if (char == '[') {
      index += 1;
      if (index < path.length && path[index] == '"') {
        index += 1;
        final buffer = StringBuffer();
        while (index < path.length) {
          final current = path[index];
          if (current == '\\' && index + 1 < path.length) {
            buffer.write(path[index + 1]);
            index += 2;
            continue;
          }
          if (current == '"') {
            index += 1;
            break;
          }
          buffer.write(current);
          index += 1;
        }
        while (index < path.length && path[index] != ']') {
          index += 1;
        }
        if (index < path.length && path[index] == ']') {
          index += 1;
        }
        segments.add(buffer.toString());
      } else {
        final buffer = StringBuffer();
        while (index < path.length && path[index] != ']') {
          buffer.write(path[index]);
          index += 1;
        }
        if (index < path.length && path[index] == ']') {
          index += 1;
        }
        final value = buffer.toString();
        if (value.isNotEmpty) {
          segments.add(value);
        }
      }
      continue;
    }
    index += 1;
  }
  return segments;
}

class _JsonPathToken {
  _JsonPathToken(
    this.value, {
    this.isArrayIndex = false,
    this.needsQuoting = false,
  });

  final String value;
  final bool isArrayIndex;
  final bool needsQuoting;
}
