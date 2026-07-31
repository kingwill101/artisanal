part of 'charting.dart';

/// A sequence diagram widget that renders Mermaid sequence diagram syntax.
///
/// Accepts either raw Mermaid source text or a pre-parsed [SequenceDiagram]
/// object. Supports custom themes and explicit dimensions.
///
/// ```dart
/// // From Mermaid source
/// SequenceDiagramChart(
///   mermaid: '''
///     sequenceDiagram
///       participant A as Alice
///       participant B as Bob
///       A->>B: Hello
///       B-->>A: Hi back!
///   ''',
///   width: 80,
///   height: 20,
/// )
///
/// // From parsed diagram
/// SequenceDiagramChart.fromDiagram(
///   diagram: parsedDiagram,
///   width: 80,
///   height: 20,
/// )
/// ```
class SequenceDiagramChart extends LeafRenderObjectWidget {
  SequenceDiagramChart({
    this.mermaid = '',
    this.width,
    this.height,
    this.diagramTheme,
    super.key,
  });

  /// Mermaid sequence diagram source text.
  final String mermaid;

  /// Explicit render width in cells. Falls back to constraint or 80.
  final int? width;

  /// Explicit render height in cells. Falls back to constraint or 24.
  final int? height;

  /// Custom theme for rendering. Uses default theme if null.
  final SequenceDiagramTheme? diagramTheme;

  @override
  RenderObject createRenderObject() {
    return _RenderSequenceDiagramChart(
      mermaid: mermaid,
      chartWidth: width,
      chartHeight: height,
      theme: diagramTheme ?? SequenceDiagramTheme.defaultTheme,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final ro = renderObject as _RenderSequenceDiagramChart;
    ro
      ..mermaid = mermaid
      ..chartWidth = width
      ..chartHeight = height
      ..theme = diagramTheme ?? SequenceDiagramTheme.defaultTheme;
  }

  @override
  Object view() => _renderSequenceDiagramString(
    mermaid,
    width ?? 80,
    height ?? 24,
    diagramTheme ?? SequenceDiagramTheme.defaultTheme,
  );
}

class _RenderSequenceDiagramChart extends RenderBox {
  _RenderSequenceDiagramChart({
    required this.mermaid,
    required this.chartWidth,
    required this.chartHeight,
    required this.theme,
  });

  String mermaid;
  int? chartWidth;
  int? chartHeight;
  SequenceDiagramTheme theme;
  String? _lastPaint;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final w = _resolveAxis(
      chartWidth,
      constraints.hasBoundedWidth,
      constraints.maxWidth,
      80,
    );
    final h = _resolveAxis(
      chartHeight,
      constraints.hasBoundedHeight,
      constraints.maxHeight,
      24,
    );
    _lastPaint = _renderSequenceDiagramString(mermaid, w, h, theme);
    size = constraints.constrain(Size(w.toDouble(), h.toDouble()));
  }

  @override
  String paint() {
    final w = chartWidth ?? 80;
    final h = chartHeight ?? 24;
    return _lastPaint ?? _renderSequenceDiagramString(mermaid, w, h, theme);
  }
}

String _renderSequenceDiagramString(
  String mermaid,
  int width,
  int height,
  SequenceDiagramTheme theme,
) {
  final rendered = renderSequenceDiagram(
    mermaid,
    theme: theme,
    maxWidth: width,
  );
  if (rendered.isEmpty) return '';
  return rendered;
}
