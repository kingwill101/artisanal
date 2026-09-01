/// Liquid tag renderer adapters using the liquify package.
///
/// Provides custom render targets to stream template output into UV buffers
/// or other sinks for building terminal UIs.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:artisanal/style.dart';
import 'package:liquify/liquify.dart' as liquify;
import 'package:liquify/parser.dart' as liq_parser;
import 'package:petitparser/petitparser.dart' as pp;

import '../charting/charting.dart' as chart;
import '../tui/bubbles/components/base.dart' show RenderConfig;
import '../tui/bubbles/components/table.dart' as table_component;
import '../tui/bubbles/components/panel.dart';
import 'package:ultraviolet/core.dart' show Buffer, ScreenBuffer;
import 'package:ultraviolet/core.dart' show StyledString;

/// Convenience wrapper for liquify templates.
final class LiquidTemplate {
  /// Internal constructor wrapping a liquify [Template].
  LiquidTemplate._(this.template);

  /// The underlying liquify template.
  final liquify.Template template;

  factory LiquidTemplate.parse(
    String source, {
    Map<String, Object?> data = const {},
  }) {
    return LiquidTemplate._(liquify.Template.parse(source, data: data));
  }

  /// Renders the template to a string using the default target.
  String render() => template.render();

  /// Renders the template using a custom [target].
  String renderWith(liquify.RenderTarget<String> target) {
    return template.renderWith(target);
  }

  /// Asynchronously renders the template using a custom [target].
  Future<String> renderWithAsync(liquify.RenderTarget<String> target) {
    return template.renderWithAsync(target);
  }

  /// Renders the template into a UV [Buffer] of the given dimensions.
  Buffer renderToBuffer({required int width, required int height}) {
    return template.renderWith(UvBufferTarget(width: width, height: height));
  }

  /// Asynchronously renders the template into a UV [Buffer].
  Future<Buffer> renderToBufferAsync({
    required int width,
    required int height,
  }) {
    return template.renderWithAsync(
      UvBufferTarget(width: width, height: height),
    );
  }
}

/// Registers Liquid UI tags for terminal layout.
///
/// Use this in `environmentSetup` to scope tags to a template, or pass no
/// environment to register globally.
void registerLiquidUiTags({liquify.Environment? environment}) {
  void register(
    String name,
    liq_parser.AbstractTag Function(
      List<liq_parser.ASTNode>,
      List<liq_parser.Filter>,
    )
    create,
  ) {
    liquify.TagRegistry.register(name, create);
    if (environment != null) {
      environment.registerLocalTag(name, create);
    }
  }

  void registerFilter(String name, liquify.FilterFunction function) {
    liquify.FilterRegistry.register(name, function);
    if (environment != null) {
      environment.registerLocalFilter(name, function);
    }
  }

  register('panel', (content, filters) => _PanelTag(content, filters));
  register(
    'frame',
    (content, filters) => _PanelTag(content, filters, tagName: 'frame'),
  );
  register('hstack', (content, filters) => _StackTag(content, filters, false));
  register('vstack', (content, filters) => _StackTag(content, filters, true));
  register('grid', (content, filters) => _GridTag(content, filters));
  register('spark', (content, filters) => _SparkTag(content, filters));
  register('rule', (content, filters) => _RuleTag(content, filters));
  register('text', (content, filters) => _TextTag(content, filters));
  register('table', (content, filters) => _TableTag(content, filters));
  register('progress', (content, filters) => _ProgressTag(content, filters));
  register('line', (content, filters) => _LineTag(content, filters));
  register('histogram', (content, filters) => _HistogramTag(content, filters));
  register('pie', (content, filters) => _PieTag(content, filters));

  registerFilter('term_width', (value, context, filters) {
    return stdout.hasTerminal ? stdout.terminalColumns : 0;
  });
  registerFilter('term_height', (value, context, filters) {
    return stdout.hasTerminal ? stdout.terminalLines : 0;
  });
  registerFilter(
    'term_is_tty',
    (value, context, filters) => stdout.hasTerminal,
  );
}

/// Render target that converts Liquify output into a UV [Buffer].
final class UvBufferTarget extends liquify.RenderTarget<Buffer> {
  /// Creates a buffer target of the given [width] and [height].
  const UvBufferTarget({required this.width, required this.height});

  /// Buffer width in columns.
  final int width;

  /// Buffer height in rows.
  final int height;

  @override
  liquify.RenderSink createSink() => _StringSink();

  @override
  Buffer finalize(liquify.RenderSink sink) {
    final text = (sink as _StringSink).value;
    final screen = ScreenBuffer(width, height);
    final styled = StyledString(text)..wrap = true;
    styled.draw(screen, screen.bounds());
    return screen.buffer.clone();
  }
}

/// Render target that captures output into a raw string.
final class StringRenderTarget extends liquify.RenderTarget<String> {
  /// Const constructor.
  const StringRenderTarget();

  @override
  liquify.RenderSink createSink() => _StringSink();

  @override
  String finalize(liquify.RenderSink sink) => (sink as _StringSink).value;
}

final class _StringSink extends liquify.RenderSink {
  final StringBuffer _buffer = StringBuffer();

  String get value => _buffer.toString();

  @override
  void write(Object? value) {
    _buffer.write(value?.toString() ?? '');
  }

  @override
  void writeln([Object? value]) {
    if (value != null) {
      write(value);
    }
    _buffer.write('\n');
  }

  @override
  void clear() {
    _buffer.clear();
  }

  @override
  liquify.RenderSink spawn() => _StringSink();

  @override
  void merge(liquify.RenderSink other) {
    if (other is _StringSink) {
      _buffer.write(other.value);
    } else {
      _buffer.write(other.debugString());
    }
  }

  @override
  Object? result() => value;

  @override
  String debugString() => value;
}

/// Convenience extensions on liquify [Template] for UV buffer rendering.
extension LiquidTemplateExtensions on liquify.Template {
  /// Renders this template into a UV [Buffer] of the given dimensions.
  Buffer renderToBuffer({required int width, required int height}) {
    return renderWith(UvBufferTarget(width: width, height: height));
  }

  /// Asynchronously renders this template into a UV [Buffer].
  Future<Buffer> renderToBufferAsync({
    required int width,
    required int height,
  }) {
    return renderWithAsync(UvBufferTarget(width: width, height: height));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag implementations
// ─────────────────────────────────────────────────────────────────────────────

final class _PanelTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _PanelTag(super.content, super.filters, {this.tagName = 'panel'});

  final String tagName;

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final title = _stringArg(args, 'title') ?? '';
    final width = _intArg(args, 'width');
    final height = _intArg(args, 'height');
    final padding = _intArg(args, 'padding') ?? _intArg(args, 'pad');
    final border = _borderFrom(_stringArg(args, 'border'));
    final contentText =
        _stringArg(args, 'body') ??
        _stringArg(args, 'content') ??
        _renderBody(evaluator, body);

    final cleaned = _trimEmptyLines(contentText);
    var lines = cleaned.split('\n');
    if (width != null) {
      final pad = padding ?? 0;
      final maxWidth = math.max(1, width - 2 - pad * 2);
      lines = lines
          .map((line) => Layout.truncate(line, maxWidth, ellipsis: ''))
          .toList();
    }
    if (height != null) {
      final pad = padding ?? 0;
      final innerHeight = math.max(1, height - 2 - pad * 2);
      lines = _padLines(lines, innerHeight);
    }

    final renderWidth = width ?? 80;
    final panel = Panel(
      renderConfig: RenderConfig(terminalWidth: renderWidth),
    ).title(title).border(border).lines(lines);
    final titleStyle = _styleFromHex(_stringArg(args, 'titleColor'));
    if (titleStyle != null) panel.titleStyle(titleStyle);
    final borderStyle = _styleFromHex(_stringArg(args, 'borderColor'));
    if (borderStyle != null) panel.borderStyle(borderStyle);
    final contentStyle = _styleFromHex(_stringArg(args, 'color'));
    if (contentStyle != null) panel.contentStyle(contentStyle);
    if (width != null) panel.width(width);
    if (padding != null) panel.padding(padding);

    buffer.write(panel.render());
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser(tagName, config: config);
  }
}

final class _StackTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _StackTag(super.content, super.filters, this.vertical);

  final bool vertical;

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final gap = _intArg(args, 'gap') ?? 0;
    final alignValue = _stringArg(args, 'align');
    final vAlign = _vAlignFrom(alignValue);
    final hAlign = _hAlignFrom(alignValue);

    final items =
        _stringListArg(args, 'items') ??
        _stringArg(args, 'content')?.split('|') ??
        _splitContent(_renderBody(evaluator, body));

    if (items == null || items.isEmpty) return null;

    final rendered = items.map((e) => e.trim()).toList();
    final out = vertical
        ? Layout.joinVertical(hAlign, rendered, gap: gap)
        : Layout.joinHorizontal(vAlign, rendered, gap: gap);

    buffer.write(out);
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser(
      vertical ? 'vstack' : 'hstack',
      config: config,
    );
  }
}

final class _GridTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _GridTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final columns = math.max(1, _intArg(args, 'columns') ?? 2);
    final gap = math.max(0, _intArg(args, 'gap') ?? 1);

    final items =
        _stringListArg(args, 'items') ??
        _stringArg(args, 'content')?.split('|') ??
        _splitContent(_renderBody(evaluator, body));

    if (items == null || items.isEmpty) return null;

    final rows = <List<String>>[];
    for (var i = 0; i < items.length; i += columns) {
      rows.add(items.sublist(i, math.min(i + columns, items.length)));
    }

    final widths = List<int>.filled(columns, 0);
    for (final row in rows) {
      for (var i = 0; i < row.length; i++) {
        final (cellWidth, _) = Layout.size(row[i]);
        widths[i] = math.max(widths[i], cellWidth);
      }
    }

    final renderedRows = <String>[];
    for (final row in rows) {
      final padded = <String>[];
      for (var i = 0; i < row.length; i++) {
        padded.add(Layout.pad(row[i], widths[i]));
      }
      renderedRows.add(
        Layout.joinHorizontal(VerticalAlign.top, padded, gap: gap),
      );
    }

    buffer.write(
      Layout.joinVertical(HorizontalAlign.left, renderedRows, gap: gap),
    );
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser('grid', config: config);
  }
}

final class _SparkTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _SparkTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final width = math.max(4, _intArg(args, 'width') ?? 16);
    final color = _stringArg(args, 'color') ?? '#9b5de5';
    final series =
        _doubleListArg(args, 'data') ??
        _doubleListFromContent(_renderBody(evaluator, body));

    if (series == null || series.isEmpty) return null;

    final lines = chart.renderChartLines(
      width,
      1,
      (screen, area) => chart.drawSparkline(
        screen,
        area,
        series,
        style: chart.uvStyleFromHex(color),
      ),
    );
    if (lines.isNotEmpty) buffer.write(lines.first);
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser('spark', config: config);
  }
}

final class _RuleTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _RuleTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final width = math.max(1, _intArg(args, 'width') ?? 24);
    final glyph = _stringArg(args, 'char') ?? '─';
    final color = _stringArg(args, 'color');
    final line = _repeatGlyph(glyph, width);
    final style = _styleFromHex(color);
    buffer.write(style?.render(line) ?? line);
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser('rule', config: config);
  }
}

final class _TextTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _TextTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final text =
        _stringArg(args, 'content') ??
        _stringArg(args, 'text') ??
        _renderBody(evaluator, body);
    final color = _stringArg(args, 'color');
    final background = _stringArg(args, 'bg');
    final width = _intArg(args, 'width');
    final pad = _intArg(args, 'pad');
    final bold = _boolArg(args, 'bold') ?? false;
    final italic = _boolArg(args, 'italic') ?? false;
    final underline = _boolArg(args, 'underline') ?? false;
    final align = _stringArg(args, 'align');

    var style = Style();
    if (color != null) style = style.foreground(BasicColor(color));
    if (background != null) style = style.background(BasicColor(background));
    if (bold) style = style.bold();
    if (italic) style = style.italic();
    if (underline) style = style.underline();
    if (width != null) style = style.width(width);
    if (pad != null) style = style.padding(pad);
    if (align != null) style = style.align(_hAlignFrom(align));
    buffer.write(style.render(text));
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser('text', config: config);
  }
}

final class _TableTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _TableTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final headers = _stringListArg(args, 'headers') ?? const <String>[];
    final rows = _rowsArg(args, 'rows') ?? const <List<String>>[];
    final width = _intArg(args, 'width');
    final padding = _intArg(args, 'padding') ?? 0;
    final border = _borderFrom(_stringArg(args, 'border'));
    final alignments = _tableAlignments(_stringListArg(args, 'align'));
    final headerStyle = _styleFromHex(_stringArg(args, 'headerColor'));
    final borderStyle = _styleFromHex(_stringArg(args, 'borderColor'));
    final cellStyle = _styleFromHex(_stringArg(args, 'cellColor'));

    final renderWidth = width ?? 80;
    final table =
        table_component.Table(
            renderConfig: RenderConfig(terminalWidth: renderWidth),
          )
          ..headers(headers)
          ..rows(rows.map((row) => row.cast<Object?>()).toList())
          ..border(border)
          ..padding(padding);

    if (alignments != null) {
      table.alignments(alignments);
    }
    if (width != null) table.width(width);
    if (headerStyle != null) table.headerStyle(headerStyle);
    if (borderStyle != null) table.borderStyle(borderStyle);
    if (cellStyle != null) table.cellStyle(cellStyle);

    buffer.write(table.render());
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser('table', config: config);
  }
}

final class _ProgressTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _ProgressTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final width = math.max(4, _intArg(args, 'width') ?? 20);
    final raw = _doubleArg(args, 'value') ?? 0;
    final fraction = raw > 1 ? raw / 100.0 : raw;
    final clamped = fraction.clamp(0.0, 1.0);
    final fillCount = (clamped * width).round();
    final fillChar = _stringArg(args, 'fill') ?? '█';
    final emptyChar = _stringArg(args, 'empty') ?? '░';
    final fillStyle = _styleFromHex(_stringArg(args, 'color'));
    final emptyStyle = _styleFromHex(_stringArg(args, 'emptyColor'));

    final filled = _repeatGlyph(fillChar, fillCount);
    final empty = _repeatGlyph(emptyChar, width - fillCount);
    final filledOut = fillStyle?.render(filled) ?? filled;
    final emptyOut = emptyStyle?.render(empty) ?? empty;
    buffer.write('$filledOut$emptyOut');
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser('progress', config: config);
  }
}

final class _LineTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _LineTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final width = math.max(8, _intArg(args, 'width') ?? 32);
    final height = math.max(3, _intArg(args, 'height') ?? 6);
    final values =
        _doubleListArg(args, 'data') ??
        _doubleListFromContent(_renderBody(evaluator, body));
    if (values == null || values.isEmpty) return null;
    final color = _stringArg(args, 'color') ?? '#00bbf9';
    final grid = _boolArg(args, 'grid') ?? false;
    final gridColor = _stringArg(args, 'gridColor') ?? '#343a40';
    final markers = _boolArg(args, 'markers') ?? true;

    final lines = chart.renderChartLines(
      width,
      height,
      (screen, area) => chart.drawLineChart(
        screen,
        area,
        values,
        lineStyle: chart.uvStyleFromHex(color),
        gridStyle: chart.uvStyleFromHex(gridColor),
        showGrid: grid,
        showMarkers: markers,
      ),
    );
    buffer.write(lines.join('\n'));
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser('line', config: config);
  }
}

final class _HistogramTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _HistogramTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final width = math.max(8, _intArg(args, 'width') ?? 32);
    final height = math.max(3, _intArg(args, 'height') ?? 6);
    final values =
        _doubleListArg(args, 'data') ??
        _doubleListFromContent(_renderBody(evaluator, body));
    if (values == null || values.isEmpty) return null;
    final color = _stringArg(args, 'color') ?? '#f72585';
    final grid = _boolArg(args, 'grid') ?? false;
    final gridColor = _stringArg(args, 'gridColor') ?? '#3a0ca3';

    final lines = chart.renderChartLines(
      width,
      height,
      (screen, area) => chart.drawHistogram(
        screen,
        area,
        values,
        barStyle: chart.uvStyleFromHex(color),
        gridStyle: chart.uvStyleFromHex(gridColor),
        showGrid: grid,
        showAxis: true,
      ),
    );
    buffer.write(lines.join('\n'));
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser('histogram', config: config);
  }
}

final class _PieTag extends liq_parser.AbstractTag
    with liq_parser.CustomTagParser {
  _PieTag(super.content, super.filters);

  @override
  dynamic evaluateWithContext(
    liq_parser.Evaluator evaluator,
    liq_parser.Buffer buffer,
  ) {
    final args = _namedArgs(this, evaluator);
    final width = math.max(6, _intArg(args, 'width') ?? 12);
    final height = math.max(4, _intArg(args, 'height') ?? 6);
    final values =
        _doubleListArg(args, 'data') ??
        _doubleListFromContent(_renderBody(evaluator, body));
    if (values == null || values.isEmpty) return null;
    final colors = _stringListArg(args, 'colors');
    final donut = _boolArg(args, 'donut') ?? true;
    final useBackground = _boolArg(args, 'useBackground') ?? false;
    final glyph = _stringArg(args, 'glyph') ?? '█';
    final innerRatio = _doubleArg(args, 'innerRatio') ?? 0.45;
    final cellAspect = _doubleArg(args, 'cellAspect') ?? 2.0;
    final styles = colors?.map((hex) => chart.uvStyleFromHex(hex)).toList();

    final lines = chart.renderChartLines(
      width,
      height,
      (screen, area) => chart.drawPieChart(
        screen,
        area,
        values,
        styles: styles,
        donut: donut,
        useBackground: useBackground,
        glyph: glyph,
        innerRadiusRatio: innerRatio,
        cellAspect: cellAspect,
      ),
    );
    buffer.write(lines.join('\n'));
    return null;
  }

  @override
  liq_parser.Parser parser([liq_parser.LiquidConfig? config]) {
    return _blockOrSimpleTagParser('pie', config: config);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag helpers
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _namedArgs(
  liq_parser.AbstractTag tag,
  liq_parser.Evaluator evaluator,
) {
  final out = <String, dynamic>{};
  for (final arg in tag.namedArgs) {
    out[arg.identifier.name] = evaluator.evaluate(arg.value);
  }
  return out;
}

String? _stringArg(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value == null) return null;
  return value.toString();
}

int? _intArg(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _doubleArg(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? _boolArg(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lowered = value.toLowerCase();
    return lowered == 'true' || lowered == 'yes' || lowered == '1';
  }
  return null;
}

List<String>? _stringListArg(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return null;
}

List<List<String>>? _rowsArg(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is List) {
    return value
        .map((row) {
          if (row is List) {
            return row.map((cell) => cell.toString()).toList();
          }
          return <String>[row.toString()];
        })
        .toList(growable: false);
  }
  return null;
}

List<double>? _doubleListArg(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is List) {
    return value.map((e) => (e as num).toDouble()).toList();
  }
  return null;
}

List<String> _padLines(List<String> lines, int height) {
  if (lines.length >= height) return lines.take(height).toList();
  final padded = [...lines];
  while (padded.length < height) {
    padded.add('');
  }
  return padded;
}

List<String>? _splitContent(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return null;

  final lines = trimmed.split('\n');
  final hasSeparator = lines.any((line) => line.trim() == '|');
  if (hasSeparator) {
    final sections = <String>[];
    final buffer = StringBuffer();
    for (final line in lines) {
      if (line.trim() == '|') {
        final section = _trimEmptyLines(buffer.toString());
        if (section.isNotEmpty) sections.add(section);
        buffer.clear();
        continue;
      }
      buffer.writeln(line);
    }
    final section = _trimEmptyLines(buffer.toString());
    if (section.isNotEmpty) sections.add(section);
    return sections;
  }

  return _trimEmptyLines(trimmed).split('\n');
}

String _trimEmptyLines(String value) {
  final lines = value.split('\n').toList();
  while (lines.isNotEmpty && lines.first.trim().isEmpty) {
    lines.removeAt(0);
  }
  while (lines.isNotEmpty && lines.last.trim().isEmpty) {
    lines.removeLast();
  }
  return lines.join('\n');
}

List<double>? _doubleListFromContent(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return null;
  return trimmed
      .split(',')
      .map((e) => double.tryParse(e.trim()) ?? 0)
      .toList(growable: false);
}

Border _borderFrom(String? value) {
  return switch (value) {
    'double' => Border.double,
    'thick' => Border.thick,
    'rounded' => Border.rounded,
    'normal' => Border.normal,
    'hidden' => Border.hidden,
    'none' => Border.none,
    _ => Border.rounded,
  };
}

Style? _styleFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  return Style().foreground(BasicColor(hex));
}

VerticalAlign _vAlignFrom(String? value) {
  return switch (value) {
    'middle' || 'center' => VerticalAlign.center,
    'bottom' => VerticalAlign.bottom,
    _ => VerticalAlign.top,
  };
}

HorizontalAlign _hAlignFrom(String? value) {
  return switch (value) {
    'center' || 'middle' => HorizontalAlign.center,
    'right' => HorizontalAlign.right,
    _ => HorizontalAlign.left,
  };
}

String _renderBody(
  liq_parser.Evaluator evaluator,
  List<liq_parser.ASTNode> body,
) {
  if (body.isEmpty) return '';
  final buffer = liq_parser.Buffer();
  return evaluator.withBuffer(buffer, () {
    for (final node in body) {
      if (node is liq_parser.Tag || node is liq_parser.Assignment) {
        node.accept(evaluator);
      } else {
        evaluator.currentBuffer.write(evaluator.evaluate(node));
      }
    }
    return buffer.toString();
  }, clearBuffer: false);
}

String _repeatGlyph(String glyph, int count) {
  if (count <= 0) return '';
  return List.filled(count, glyph).join();
}

List<table_component.TableAlign>? _tableAlignments(List<String>? values) {
  if (values == null || values.isEmpty) return null;
  return values
      .map(
        (value) => switch (value.toLowerCase()) {
          'center' => table_component.TableAlign.center,
          'right' => table_component.TableAlign.right,
          _ => table_component.TableAlign.left,
        },
      )
      .toList(growable: false);
}

liq_parser.Parser _blockOrSimpleTagParser(
  String name, {
  liq_parser.LiquidConfig? config,
}) {
  return _blockTagParser(
    name,
    config: config,
  ).or(_simpleTagParser(name, config: config));
}

final class _NestedBlockParser extends pp.Parser<String> {
  _NestedBlockParser(this.tagName, this.config);

  final String tagName;
  final liq_parser.LiquidConfig? config;

  @override
  pp.Result<String> parseOn(pp.Context context) {
    final buffer = context.buffer;
    final startIndex = context.position;
    final startSeq = config?.tagStart ?? '{%';
    final endSeq = config?.tagEnd ?? '%}';
    final startSeqTrim = startSeq.endsWith('-') ? startSeq : '$startSeq-';
    final endSeqTrim = endSeq.startsWith('-') ? endSeq : '-$endSeq';

    var depth = 1;
    var position = startIndex;

    while (position < buffer.length) {
      final next = _findNextTagStart(buffer, position, startSeq, startSeqTrim);
      if (next == -1) {
        return context.failure('Unclosed tag: $tagName');
      }

      final usesTrimStart = buffer.startsWith(startSeqTrim, next);
      final startLen = usesTrimStart ? startSeqTrim.length : startSeq.length;
      var cursor = next + startLen;
      cursor = _skipWhitespace(buffer, cursor);

      final nameStart = cursor;
      cursor = _readIdentifier(buffer, cursor);
      if (cursor == nameStart) {
        position = next + startLen;
        continue;
      }

      final name = buffer.substring(nameStart, cursor);
      final isStart = name == tagName;
      final isEnd = name == 'end$tagName';

      final endIndex = _findTagEnd(buffer, cursor, endSeq, endSeqTrim);
      if (endIndex == -1) {
        return context.failure('Unclosed tag: $tagName');
      }

      final usesTrimEnd = buffer.startsWith(endSeqTrim, endIndex);
      final endLen = usesTrimEnd ? endSeqTrim.length : endSeq.length;

      if (isStart) depth++;
      if (isEnd) {
        depth--;
        if (depth == 0) {
          final body = buffer.substring(startIndex, next);
          return context.success(body, endIndex + endLen);
        }
      }

      position = endIndex + endLen;
    }

    return context.failure('Unclosed tag: $tagName');
  }

  @override
  pp.Parser<String> copy() => _NestedBlockParser(tagName, config);
}

int _findNextTagStart(
  String buffer,
  int start,
  String tagStart,
  String tagStartTrim,
) {
  final a = buffer.indexOf(tagStart, start);
  final b = buffer.indexOf(tagStartTrim, start);
  if (a == -1) return b;
  if (b == -1) return a;
  return a < b ? a : b;
}

int _findTagEnd(String buffer, int start, String tagEnd, String tagEndTrim) {
  final a = buffer.indexOf(tagEnd, start);
  final b = buffer.indexOf(tagEndTrim, start);
  if (a == -1) return b;
  if (b == -1) return a;
  return a < b ? a : b;
}

int _skipWhitespace(String buffer, int index) {
  var i = index;
  while (i < buffer.length) {
    final code = buffer.codeUnitAt(i);
    if (code != 32 && code != 9 && code != 10 && code != 13) break;
    i++;
  }
  return i;
}

int _readIdentifier(String buffer, int index) {
  var i = index;
  while (i < buffer.length) {
    final code = buffer.codeUnitAt(i);
    final isAlpha = (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
    final isDigit = code >= 48 && code <= 57;
    if (!(isAlpha || isDigit || code == 95 || code == 45)) {
      break;
    }
    i++;
  }
  return i;
}

liq_parser.Parser _blockTagParser(
  String name, {
  liq_parser.LiquidConfig? config,
}) {
  final open = liq_parser.someTag(name, config: config);
  return (open & _NestedBlockParser(name, config)).map((values) {
    final openTag = values[0] as liq_parser.Tag;
    final bodyText = values[1] as String;
    final bodyNodes = liq_parser.parseInput(bodyText, config: config);
    return liq_parser.Tag(
      name,
      openTag.content,
      filters: openTag.filters,
      body: bodyNodes,
    );
  });
}

liq_parser.Parser _simpleTagParser(
  String name, {
  liq_parser.LiquidConfig? config,
}) {
  return liq_parser.someTag(name, config: config);
}
