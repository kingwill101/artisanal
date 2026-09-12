import 'package:ultraviolet/core.dart' as uv;

/// The JSON format version emitted by [TerminalCapture].
const int terminalCaptureFormatVersion = 1;

/// Maximum number of columns accepted by a capture.
const int terminalCaptureMaxColumns = 1000;

/// Maximum number of rows accepted by a capture.
const int terminalCaptureMaxRows = 10000;

/// Maximum number of cells accepted by a capture.
const int terminalCaptureMaxCells = 1000000;

const int _maxTextLength = 100000;
const int _maxLinkPartLength = 8192;
const int _maxLinkTotalLength = 16384;
const int _knownAttrs = 0xff;

/// An immutable snapshot of a terminal cell buffer.
///
/// [fromAnsi] deliberately parses only SGR styling, OSC 8 links, newlines and
/// tabs through UV's [uv.StyledString]. Cursor movement, graphics, and other
/// terminal controls are rejected; this is not a PTY emulator.
final class TerminalCapture {
  TerminalCapture._(this._buffer)
    : columns = _buffer.width(),
      rows = _buffer.height();

  /// Copies [source] after validating its dimensions and cell contents.
  ///
  /// Captures are detached from [source]. Throws [FormatException] for data
  /// outside the capture format and [UnsupportedError] for drawable cells.
  factory TerminalCapture.fromBuffer(uv.Buffer source) {
    _checkDimensions(source.width(), source.height());
    for (var y = 0; y < source.height(); y++) {
      final line = source.line(y);
      if (line == null || line.length != source.width()) {
        throw const FormatException('buffer has an invalid rectangular grid');
      }
      for (var x = 0; x < source.width(); x++) {
        _validateCell(
          line.at(x) ?? (throw const FormatException('missing cell')),
        );
      }
    }
    final cells = <List<uv.Cell>>[];
    for (var y = 0; y < source.height(); y++) {
      final line = source.line(y);
      cells.add([
        for (var x = 0; x < source.width(); x++)
          _copyCell(
            line!.at(x) ?? (throw const FormatException('missing cell')),
          ),
      ]);
    }
    return TerminalCapture._(uv.Buffer.fromCells(cells));
  }

  /// Captures supported styled text into a fixed-size screen.
  ///
  /// Only printable text, tabs, line feeds, SGR, and OSC 8 hyperlinks are
  /// accepted. Dimensions must be positive and within the published limits.
  factory TerminalCapture.fromAnsi(
    String ansi, {
    required int columns,
    required int rows,
    bool wrap = false,
  }) {
    _checkDimensions(columns, rows);
    _validateAnsi(ansi);
    final screen = uv.ScreenBuffer(columns, rows, tracksDirty: false);
    uv.StyledString(
      _normalizeAnsi(ansi),
      wrap: wrap,
    ).draw(screen, screen.bounds());
    return TerminalCapture.fromBuffer(screen.buffer);
  }

  /// Decodes and validates a capture JSON object.
  ///
  /// Malformed input consistently throws [FormatException], including invalid
  /// forced widths and values that would otherwise make UV throw
  /// [ArgumentError].
  factory TerminalCapture.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version is! int || version != terminalCaptureFormatVersion) {
      throw FormatException('unsupported capture version: $version');
    }
    final columns = _integer(json['columns'], 'columns');
    final rows = _integer(json['rows'], 'rows');
    _checkDimensions(columns, rows);
    final rawRows = json['cells'];
    if (rawRows is! List || rawRows.length != rows) {
      throw const FormatException('cells must contain exactly rows rows');
    }
    final parsed = <List<uv.Cell>>[];
    for (var y = 0; y < rows; y++) {
      final rawRow = rawRows[y];
      if (rawRow is! List || rawRow.length != columns) {
        throw const FormatException('every cell row must have columns cells');
      }
      parsed.add([
        for (var x = 0; x < columns; x++)
          _cellFromJson(rawRow[x], 'cells[$y][$x]'),
      ]);
    }
    return TerminalCapture._(uv.Buffer.fromCells(parsed));
  }

  final uv.Buffer _buffer;

  /// Number of cells in each row.
  final int columns;

  /// Number of rows in the capture.
  final int rows;

  /// Returns a detached copy of this capture's buffer.
  uv.Buffer toBuffer() => TerminalCapture.fromBuffer(_buffer)._buffer;

  /// Encodes this lossless capture as a JSON-compatible object.
  Map<String, Object?> toJson() => <String, Object?>{
    'version': terminalCaptureFormatVersion,
    'columns': columns,
    'rows': rows,
    'cells': [
      for (var y = 0; y < rows; y++)
        [for (var x = 0; x < columns; x++) _cellToJson(_buffer.cellAt(x, y)!)],
    ],
  };
}

int _integer(Object? value, String name) {
  if (value is! int || value < 0) {
    throw FormatException('$name must be a non-negative integer');
  }
  return value;
}

void _checkDimensions(int columns, int rows) {
  if (columns < 1 ||
      rows < 1 ||
      columns > terminalCaptureMaxColumns ||
      rows > terminalCaptureMaxRows) {
    throw const FormatException('capture dimensions are out of range');
  }
  if (rows > terminalCaptureMaxCells ~/ columns) {
    throw const FormatException('capture contains too many cells');
  }
}

uv.Cell _copyCell(uv.Cell cell) {
  _validateCell(cell);
  if (cell.drawable != null) {
    throw UnsupportedError(
      'drawable cells cannot be represented in capture JSON',
    );
  }
  return uv.Cell(
    content: cell.content,
    style: _copyStyle(cell.style),
    link: uv.Link(url: cell.link.url, params: cell.link.params),
    width: cell.width,
    diffOption: cell.diffOption.isForcedWidth
        ? uv.CellDiffOption.forcedWidth(cell.diffOption.width!)
        : cell.diffOption.isSkip
        ? uv.CellDiffOption.skip
        : cell.diffOption.isAlwaysUpdate
        ? uv.CellDiffOption.alwaysUpdate
        : uv.CellDiffOption.normal,
  );
}

void _validateCell(uv.Cell cell) {
  if (cell.drawable != null) {
    throw UnsupportedError(
      'drawable cells cannot be represented in capture JSON',
    );
  }
  if (cell.content.length > _maxTextLength || !_isSafeText(cell.content)) {
    throw const FormatException('cell content contains unsupported controls');
  }
  if (cell.width < 0 || cell.width > 5) {
    throw const FormatException('cell width is out of range');
  }
  if (cell.style.attrs < 0 || cell.style.attrs & ~_knownAttrs != 0) {
    throw const FormatException('cell style has unknown attributes');
  }
  _validateLink(cell.link.url, cell.link.params);
  if (cell.diffOption.isForcedWidth &&
      (cell.diffOption.width == null ||
          cell.diffOption.width! < 1 ||
          cell.diffOption.width! > terminalCaptureMaxColumns)) {
    throw const FormatException('forced cell width is out of range');
  }
  _validateColor(cell.style.fg);
  _validateColor(cell.style.bg);
  _validateColor(cell.style.underlineColor);
}

void _validateColor(uv.UvColor? color) {
  if (color == null) return;
  final valid = switch (color) {
    uv.UvBasic16 c => c.index >= 0 && c.index < 8,
    uv.UvIndexed256 c => c.index >= 0 && c.index < 256,
    uv.UvRgb c =>
      c.r >= 0 &&
          c.r < 256 &&
          c.g >= 0 &&
          c.g < 256 &&
          c.b >= 0 &&
          c.b < 256 &&
          c.a >= 0 &&
          c.a < 256,
  };
  if (!valid) throw const FormatException('color value is out of range');
}

bool _isSafeText(String value) {
  for (var i = 0; i < value.length; i++) {
    final code = value.codeUnitAt(i);
    if ((code < 0x20 && code != 0x09 && code != 0x0a) ||
        (code >= 0x7f && code <= 0x9f)) {
      return false;
    }
  }
  return true;
}

void _validateLink(String url, String params) {
  if (url.length > _maxLinkPartLength ||
      params.length > _maxLinkPartLength ||
      url.length + params.length > _maxLinkTotalLength ||
      !_isSafeLinkText(url) ||
      !_isSafeLinkText(params)) {
    throw const FormatException('link contains unsupported data');
  }
}

bool _isSafeLinkText(String value) {
  for (var i = 0; i < value.length; i++) {
    final code = value.codeUnitAt(i);
    if (code < 0x20 || (code >= 0x7f && code <= 0x9f)) {
      return false;
    }
  }
  return true;
}

uv.UvStyle _copyStyle(uv.UvStyle style) => uv.UvStyle(
  fg: _copyColor(style.fg),
  bg: _copyColor(style.bg),
  underlineColor: _copyColor(style.underlineColor),
  underline: style.underline,
  attrs: style.attrs,
);

uv.UvColor? _copyColor(uv.UvColor? color) => switch (color) {
  null => null,
  uv.UvBasic16 c => uv.UvColor.basic16(c.index, bright: c.bright),
  uv.UvIndexed256 c => uv.UvColor.indexed256(c.index),
  uv.UvRgb c => uv.UvColor.rgb(c.r, c.g, c.b, a: c.a),
};

Map<String, Object?> _cellToJson(uv.Cell cell) => <String, Object?>{
  'content': cell.content,
  'width': cell.width,
  'style': <String, Object?>{
    'fg': _colorToJson(cell.style.fg),
    'bg': _colorToJson(cell.style.bg),
    'underlineColor': _colorToJson(cell.style.underlineColor),
    'underline': cell.style.underline.name,
    'attrs': cell.style.attrs,
  },
  'link': <String, Object?>{'url': cell.link.url, 'params': cell.link.params},
  'diff': cell.diffOption.isForcedWidth
      ? <String, Object?>{'kind': 'forcedWidth', 'width': cell.diffOption.width}
      : <String, Object?>{
          'kind': cell.diffOption.isSkip
              ? 'skip'
              : cell.diffOption.isAlwaysUpdate
              ? 'alwaysUpdate'
              : 'normal',
        },
};

Object? _colorToJson(uv.UvColor? color) => switch (color) {
  null => null,
  uv.UvBasic16 c => <String, Object?>{
    'kind': 'basic16',
    'index': c.index,
    'bright': c.bright,
  },
  uv.UvIndexed256 c => <String, Object?>{
    'kind': 'indexed256',
    'index': c.index,
  },
  uv.UvRgb c => <String, Object?>{
    'kind': 'rgb',
    'r': c.r,
    'g': c.g,
    'b': c.b,
    'a': c.a,
  },
};

uv.Cell _cellFromJson(Object? value, String path) {
  if (value is! Map) throw FormatException('$path must be an object');
  final content = value['content'];
  final width = value['width'];
  if (content is! String || width is! int || width < 0 || width > 5) {
    throw FormatException('$path has invalid content or width');
  }
  final rawStyle = value['style'];
  final rawLink = value['link'];
  final rawDiff = value['diff'];
  if (rawStyle is! Map || rawLink is! Map || rawDiff is! Map) {
    throw FormatException('$path requires style, link, and diff');
  }
  final attrs = rawStyle['attrs'];
  final underline = rawStyle['underline'];
  if (attrs is! int ||
      attrs < 0 ||
      attrs & ~_knownAttrs != 0 ||
      underline is! String ||
      content.length > _maxTextLength ||
      !_isSafeText(content)) {
    throw FormatException('$path has invalid style');
  }
  final underlineStyle = uv.UnderlineStyle.values.asNameMap()[underline];
  if (underlineStyle == null) {
    throw FormatException('$path has invalid underline');
  }
  final url = rawLink['url'];
  final params = rawLink['params'];
  if (url is! String || params is! String) {
    throw FormatException('$path has invalid link');
  }
  _validateLink(url, params);
  final kind = rawDiff['kind'];
  if (kind is! String) {
    throw FormatException('$path has invalid diff');
  }
  final diff = switch (kind) {
    'normal' => uv.CellDiffOption.normal,
    'skip' => uv.CellDiffOption.skip,
    'alwaysUpdate' => uv.CellDiffOption.alwaysUpdate,
    'forcedWidth' => _forcedWidth(rawDiff['width'], '$path diff width'),
    _ => throw FormatException('$path has invalid diff kind'),
  };
  try {
    return uv.Cell(
      content: content,
      width: width,
      style: uv.UvStyle(
        fg: _colorFromJson(rawStyle['fg'], '$path fg'),
        bg: _colorFromJson(rawStyle['bg'], '$path bg'),
        underlineColor: _colorFromJson(
          rawStyle['underlineColor'],
          '$path underlineColor',
        ),
        underline: underlineStyle,
        attrs: attrs,
      ),
      link: uv.Link(url: url, params: params),
      diffOption: diff,
    );
  } on ArgumentError catch (error) {
    throw FormatException('$path contains invalid UV cell data: $error');
  }
}

uv.CellDiffOption _forcedWidth(Object? value, String path) {
  final width = _integer(value, path);
  if (width < 1 || width > terminalCaptureMaxColumns) {
    throw FormatException('$path is out of range');
  }
  return uv.CellDiffOption.forcedWidth(width);
}

uv.UvColor? _colorFromJson(Object? value, String path) {
  if (value == null) return null;
  if (value is! Map || value['kind'] is! String) {
    throw FormatException('$path is invalid');
  }
  final kind = value['kind'];
  final index = value['index'];
  switch (kind) {
    case 'basic16':
      if (index is! int || index < 0 || index > 7 || value['bright'] is! bool) {
        throw FormatException('$path is invalid');
      }
      return uv.UvColor.basic16(index, bright: value['bright'] as bool);
    case 'indexed256':
      if (index is! int || index < 0 || index > 255) {
        throw FormatException('$path is invalid');
      }
      return uv.UvColor.indexed256(index);
    case 'rgb':
      final r = value['r'], g = value['g'], b = value['b'], a = value['a'];
      if ([r, g, b, a].any((v) => v is! int || v < 0 || v > 255)) {
        throw FormatException('$path is invalid');
      }
      return uv.UvColor.rgb(r as int, g as int, b as int, a: a as int);
    default:
      throw FormatException('$path has unknown color kind');
  }
}

void _validateAnsi(String text) {
  for (var i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    if (code == 0x0d) {
      if (i + 1 >= text.length || text.codeUnitAt(i + 1) != 0x0a) {
        throw const FormatException('lone carriage return is not supported');
      }
      continue;
    }
    if (code == 0x1b) {
      if (i + 1 >= text.length) {
        throw const FormatException('truncated ANSI escape');
      }
      if (text.codeUnitAt(i + 1) == 0x5b) {
        final end = text.indexOf('m', i + 2);
        if (end < 0 ||
            !RegExp(
              r'^\x1b\[[0-9;:]*m$',
            ).hasMatch(text.substring(i, end + 1))) {
          throw const FormatException('only SGR ANSI sequences are supported');
        }
        i = end;
      } else if (text.startsWith('\x1b]8;', i)) {
        final st = text.indexOf('\x1b\\', i + 4);
        final bel = text.indexOf('\x07', i + 4);
        final usesBel = bel >= 0 && (st < 0 || bel < st);
        final end = usesBel ? bel : st;
        if (end < 0) throw const FormatException('truncated OSC 8 hyperlink');
        final payload = text.substring(i + 4, end);
        if (!payload.contains(';') ||
            payload.contains('\x1b') ||
            payload.contains('\x07') ||
            !_isSafeLinkText(payload)) {
          throw const FormatException('invalid OSC 8 hyperlink');
        }
        // BEL and ST are both valid OSC terminators. BEL outside a complete
        // OSC 8 sequence remains rejected by the control-character allowlist.
        i = end + (usesBel ? 0 : 1);
      } else {
        throw const FormatException('unsupported terminal control sequence');
      }
    } else if ((code < 0x20 && code != 0x09 && code != 0x0a) ||
        (code >= 0x7f && code <= 0x9f)) {
      throw const FormatException('unsupported terminal control character');
    }
  }
}

String _normalizeAnsi(String text) => text.replaceAll('\r\n', '\n');
