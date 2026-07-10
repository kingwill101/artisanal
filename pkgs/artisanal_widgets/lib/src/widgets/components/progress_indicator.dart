import 'dart:math' as math;

import 'package:artisanal/tui.dart' show Cmd;
import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart' show Color, Style;

/// Predefined fill/track character sets for [ProgressIndicator].
enum ProgressStyle {
  /// Hash fill, dash track: `[####----]`
  classic,

  /// Block fill, light shade track: `[████░░░░]`
  block,

  /// Arrow fill, dash track: `[>>>>----]`
  arrow,

  /// Dot fill, space track: `[●●●●○○○○]`
  dot,

  /// Braille-style thin bar: `[⣿⣿⣿⣀⣀⣀]`
  braille,
}

/// Where to display the percentage label relative to the bar.
enum ProgressLabelPosition {
  /// Label appears to the right of the bar.
  right,

  /// Label appears to the left of the bar.
  left,

  /// Label appears centered inside the bar.
  inside,
}

class ProgressIndicator extends StatelessWidget {
  ProgressIndicator({
    required this.value,
    this.width = 20,
    this.fillChar,
    this.trackChar,
    this.color,
    this.trackColor,
    this.showLabel = false,
    this.label,
    this.labelStyle,
    this.progressStyle = ProgressStyle.classic,
    this.labelPosition = ProgressLabelPosition.right,
    this.borderLeft = '[',
    this.borderRight = ']',
    this.showBorder = true,
    this.borderColor,
    this.labelFormat,
    super.key,
  });

  /// Progress value between 0.0 and 1.0.
  final double value;

  /// Width of the progress bar in columns (excluding borders and label).
  final int width;

  /// Custom fill character. Overrides [progressStyle].
  final String? fillChar;

  /// Custom track (unfilled) character. Overrides [progressStyle].
  final String? trackChar;

  /// Fill color. Defaults to theme primary.
  final Color? color;

  /// Track color. Defaults to theme border.
  final Color? trackColor;

  /// Whether to show a percentage label.
  final bool showLabel;

  /// Custom label text. When null and [showLabel] is true, shows percentage.
  final String? label;

  /// Style for the label text.
  final Style? labelStyle;

  /// Predefined fill/track character set.
  final ProgressStyle progressStyle;

  /// Where to display the label relative to the bar.
  final ProgressLabelPosition labelPosition;

  /// Left border character. Set to empty string to remove.
  final String borderLeft;

  /// Right border character. Set to empty string to remove.
  final String borderRight;

  /// Whether to show border characters around the bar.
  final bool showBorder;

  /// Border character color. Defaults to theme muted.
  final Color? borderColor;

  /// Custom label format function. Receives the clamped value (0.0–1.0).
  /// When provided, overrides [label] and the default percentage display.
  final String Function(double value)? labelFormat;

  (String, String) _resolveChars() {
    if (fillChar != null || trackChar != null) {
      return (fillChar ?? '#', trackChar ?? '-');
    }
    return switch (progressStyle) {
      ProgressStyle.classic => ('#', '-'),
      ProgressStyle.block => ('█', '░'),
      ProgressStyle.arrow => ('>', '-'),
      ProgressStyle.dot => ('●', '○'),
      ProgressStyle.braille => ('⣿', '⣀'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final clamped = value.clamp(0.0, 1.0);
    final (fill, track) = _resolveChars();
    final filledCount = (clamped * width).round().clamp(0, width);
    final fillStr = fill * filledCount;
    final trackStr = track * (width - filledCount);

    final fillStyle = copyStyle(Style())..foreground(color ?? theme.primary);
    final trackStyle = copyStyle(Style())
      ..foreground(trackColor ?? theme.border);

    final barContent =
        '${fillStyle.render(fillStr)}${trackStyle.render(trackStr)}';

    // Build border-wrapped bar.
    String bar;
    if (showBorder && (borderLeft.isNotEmpty || borderRight.isNotEmpty)) {
      final bStyle = copyStyle(Style())..foreground(borderColor ?? theme.muted);
      final left = borderLeft.isNotEmpty ? bStyle.render(borderLeft) : '';
      final right = borderRight.isNotEmpty ? bStyle.render(borderRight) : '';
      bar = '$left$barContent$right';
    } else {
      bar = barContent;
    }

    // Resolve label text.
    final bool needsLabel = showLabel || label != null || labelFormat != null;
    if (!needsLabel) {
      return Text(bar);
    }

    final labelText = labelFormat != null
        ? labelFormat!(clamped)
        : label ?? '${(clamped * 100).round()}%';
    final resolvedLabelStyle = copyStyle(labelStyle ?? theme.labelSmall)
      ..foreground(theme.muted);

    if (labelPosition == ProgressLabelPosition.inside) {
      // Overlay label centered inside the bar. For simplicity, render
      // the bar then show the label as a separate right-aligned piece.
      // In terminal mode, we just append — true overlay would need canvas.
      return Row(
        gap: 0,
        children: [Text(bar), Text(' ${resolvedLabelStyle.render(labelText)}')],
      );
    }

    final labelWidget = Text(labelText, style: resolvedLabelStyle);
    if (labelPosition == ProgressLabelPosition.left) {
      return Row(gap: 1, children: [labelWidget, Text(bar)]);
    }
    // Default: right
    return Row(gap: 1, children: [Text(bar), labelWidget]);
  }
}

/// Flutter-style linear progress indicator.
///
/// When [value] is non-null, renders a determinate bar.
/// When [value] is null, animates an indeterminate segment.
class LinearProgressIndicator extends StatefulWidget {
  LinearProgressIndicator({
    this.value,
    this.width = 20,
    this.color,
    this.backgroundColor,
    this.interval = const Duration(milliseconds: 90),
    this.indeterminateChunkSize = 4,
    super.key,
  });

  final double? value;
  final int width;
  final Color? color;
  final Color? backgroundColor;
  final Duration interval;
  final int indeterminateChunkSize;

  @override
  State createState() => _LinearProgressIndicatorState();
}

class _LinearProgressIndicatorState extends State<LinearProgressIndicator>
    with AnimationMixin {
  late AnimationController _controller;

  bool get _isIndeterminate => widget.value == null && widget.width > 0;

  Duration get _cycleDuration {
    final width = math.max(1, widget.width);
    return widget.interval * width;
  }

  @override
  void initState() {
    super.initState();
    _controller = createAnimationController(
      duration: _cycleDuration,
      value: 0.0,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  Cmd? handleInit() {
    if (!_isIndeterminate) return null;
    return _startIndeterminateAnimation();
  }

  @override
  Cmd? didUpdateWidget(covariant LinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasIndeterminate = oldWidget.value == null && oldWidget.width > 0;
    if (_isIndeterminate) {
      final needsRestart =
          !wasIndeterminate ||
          oldWidget.width != widget.width ||
          oldWidget.interval != widget.interval;
      if (needsRestart) {
        return _startIndeterminateAnimation();
      }
    } else if (wasIndeterminate) {
      _controller.stop();
      _controller.reset();
    }
    return null;
  }

  Cmd? _startIndeterminateAnimation() {
    return _controller.repeat(period: _cycleDuration);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != null) {
      return ProgressIndicator(
        value: widget.value!,
        width: widget.width,
        color: widget.color,
        trackColor: widget.backgroundColor,
        progressStyle: ProgressStyle.block,
        showBorder: false,
      );
    }

    final width = math.max(1, widget.width);
    final chunk = widget.indeterminateChunkSize.clamp(1, width);
    final theme = ThemeScope.of(context);
    final fill = copyStyle(Style())..foreground(widget.color ?? theme.primary);
    final track = copyStyle(Style())
      ..foreground(widget.backgroundColor ?? theme.border);

    final activeCells = List<bool>.filled(width, false);
    final offset = (_controller.value * width).floor() % width;
    for (var i = 0; i < chunk; i++) {
      activeCells[(offset + i) % width] = true;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < width; i++) {
      buffer.write(activeCells[i] ? fill.render('█') : track.render('░'));
    }

    return Text(buffer.toString());
  }
}
