part of 'raster.dart';

/// Cached glyph coverage relative to its baseline.
///
/// Applies TrueType implied on-curve points, then nonzero winding at four
/// samples per axis. Font parsing and composite expansion stay in pure_ui.
final class _GlyphMask {
  _GlyphMask(this.left, this.top, this.width, this.height, this.alpha);
  final int left;
  final int top;
  final int width;
  final int height;
  final Uint8List alpha;

  factory _GlyphMask.rasterize(ui.GlyphOutline outline, double scale) {
    if (outline.contours.length > 256 ||
        outline.contours.fold<int>(0, (sum, c) => sum + c.points.length) >
            4096) {
      throw const FormatException(
        'Glyph contour complexity exceeds raster limits',
      );
    }
    var vertices = 0;
    void append(List<(double, double)> points, (double, double) point) {
      if (++vertices > 32768) {
        throw const FormatException('Glyph tessellation exceeds raster limits');
      }
      points.add(point);
    }

    final contours = <List<(double, double)>>[];
    for (final contour in outline.contours) {
      final raw = contour.points;
      if (raw.isEmpty) continue;
      (double, double) point(ui.GlyphPoint p) => (p.x * scale, -p.y * scale);
      (double, double) midpoint(ui.GlyphPoint a, ui.GlyphPoint b) =>
          ((a.x + b.x) * scale / 2, -(a.y + b.y) * scale / 2);
      final start = raw.first.onCurve
          ? point(raw.first)
          : raw.last.onCurve
          ? point(raw.last)
          : midpoint(raw.last, raw.first);
      final points = <(double, double)>[];
      append(points, start);
      var i = raw.first.onCurve ? 1 : 0;
      while (i < raw.length) {
        final p = raw[i];
        if (p.onCurve) {
          append(points, point(p));
          i++;
        } else {
          final next = raw[(i + 1) % raw.length];
          final end = next.onCurve ? point(next) : midpoint(p, next);
          final control = point(p), begin = points.last;
          final distance =
              (begin.$1 - control.$1).abs() +
              (begin.$2 - control.$2).abs() +
              (end.$1 - control.$1).abs() +
              (end.$2 - control.$2).abs();
          final steps = (distance * 2).ceil().clamp(2, 128);
          for (var step = 1; step <= steps; step++) {
            final t = step / steps, u = 1 - step / steps;
            append(points, (
              u * u * begin.$1 + 2 * u * t * control.$1 + t * t * end.$1,
              u * u * begin.$2 + 2 * u * t * control.$2 + t * t * end.$2,
            ));
          }
          i += next.onCurve ? 2 : 1;
        }
      }
      if (points.length >= 3) contours.add(points);
    }
    if (contours.isEmpty) return _GlyphMask(0, 0, 0, 0, Uint8List(0));
    final all = contours.expand((points) => points);
    final left = all.map((p) => p.$1).reduce(math.min).floor();
    final right = all.map((p) => p.$1).reduce(math.max).ceil();
    final top = all.map((p) => p.$2).reduce(math.min).floor();
    final bottom = all.map((p) => p.$2).reduce(math.max).ceil();
    final width = right - left, height = bottom - top;
    if (width > 2048 ||
        height > 2048 ||
        width * height > 1000000 ||
        vertices * height * 4 > 16000000) {
      throw const FormatException('Glyph coverage exceeds raster limits');
    }
    final coverage = Uint8List(width * height);
    const samples = 4;
    for (var sy = 0; sy < height * samples; sy++) {
      final y = top + (sy + 0.5) / samples;
      final crossings = <(double, int)>[];
      for (final points in contours) {
        for (var i = 0; i < points.length; i++) {
          final a = points[i], b = points[(i + 1) % points.length];
          if ((a.$2 <= y && b.$2 > y) || (b.$2 <= y && a.$2 > y)) {
            crossings.add((
              a.$1 + (y - a.$2) * (b.$1 - a.$1) / (b.$2 - a.$2),
              b.$2 > a.$2 ? 1 : -1,
            ));
          }
        }
      }
      crossings.sort((a, b) => a.$1.compareTo(b.$1));
      var winding = 0;
      double start = 0;
      for (final crossing in crossings) {
        final previous = winding;
        winding += crossing.$2;
        if (previous == 0 && winding != 0) start = crossing.$1;
        if (previous != 0 && winding == 0) {
          final from = ((start - left) * samples - 0.5).ceil().clamp(
            0,
            width * samples,
          );
          final to = ((crossing.$1 - left) * samples - 0.5).ceil().clamp(
            0,
            width * samples,
          );
          for (var sx = from; sx < to; sx++) {
            coverage[(sy ~/ samples) * width + sx ~/ samples]++;
          }
        }
      }
    }
    for (var i = 0; i < coverage.length; i++) {
      coverage[i] = (coverage[i] * 255 / (samples * samples)).round();
    }
    return _GlyphMask(left, top, width, height, coverage);
  }
}
