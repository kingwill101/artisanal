import 'dart:math' as math;

import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/blending.dart' as blending;
import 'package:artisanal/src/tui/harmonica.dart' as hz;

import '../cmd.dart';
import '../component.dart';
import '../msg.dart';

/// Message indicating a progress bar animation frame should advance.
class ProgressFrameMsg extends Msg {
  const ProgressFrameMsg({required this.id, required this.tag});

  /// The ID of the progress bar this message belongs to.
  final int id;

  /// Tag to prevent duplicate frame messages.
  final int tag;
}

/// Global ID counter for progress bar instances.
int _lastProgressId = 0;

int _nextProgressId() => ++_lastProgressId;

const _fps = 60;
const _defaultWidth = 40;
const _defaultFrequency = 18.0;
const _defaultDamping = 1.0;

/// Default character used to fill the progress bar.
/// It is a half block, which allows more granular color blending control.
const String defaultFullCharHalfBlock = '▌';

/// Default character used to fill the progress bar (full block).
const String defaultFullCharFullBlock = '█';

/// Default character used to fill the empty portion of the progress bar.
const String defaultEmptyCharBlock = '░';

/// Function that can be used to dynamically fill the progress bar.
/// [total] is the total filled percentage, and [current] is the current
/// percentage that is actively being filled with a color.
typedef ColorFunc = Color Function(double total, double current);

/// A stable damped spring integrator matching charmbracelet/harmonica.
class _Spring {
  _Spring({this.frequency = _defaultFrequency, this.damping = _defaultDamping})
    : _inner = hz.Spring(1 / _fps, frequency * 2 * math.pi, damping);

  final double frequency;
  final double damping;
  final hz.Spring _inner;

  /// Updates the spring state and returns (newValue, newVelocity).
  (double, double) update(double current, double velocity, double target) {
    return _inner.update(current, velocity, target);
  }
}

/// A progress bar widget with optional animation support.
///
/// The progress bar can be rendered statically using [viewAs] or
/// animated using the [update] loop and [setPercent] commands.
///
/// ## Example (Static)
///
/// ```dart
/// // Simple static progress bar
/// final progress = ProgressModel(width: 40);
/// print(progress.viewAs(0.5)); // 50% complete
/// ```
///
/// ## Example (Animated)
///
/// ```dart
/// class DownloadModel implements Model {
///   final ProgressModel progress;
///   final double downloaded;
///
///   DownloadModel({ProgressModel? progress, this.downloaded = 0})
///       : progress = progress ?? ProgressModel();
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     // Handle progress animation frames
///     final (newProgress, cmd) = progress.update(msg);
///     if (newProgress != progress) {
///       return (
///         DownloadModel(progress: newProgress as ProgressModel, downloaded: downloaded),
///         cmd,
///       );
///     }
///
///     // Handle download progress updates
///     if (msg is DownloadProgressMsg) {
///       final newPercent = msg.bytes / msg.total;
///       final (updatedProgress, animCmd) = progress.setPercent(newPercent);
///       return (
///         DownloadModel(progress: updatedProgress, downloaded: newPercent),
///         animCmd,
///       );
///     }
///
///     return (this, null);
///   }
///
///   @override
///   String view() => progress.view();
/// }
/// ```
class ProgressModel extends ViewComponent {
  /// Creates a new progress bar model.
  ProgressModel({
    this.width = _defaultWidth,
    this.full = defaultFullCharHalfBlock,
    this.fullColor = '#7571F9',
    this.empty = defaultEmptyCharBlock,
    this.emptyColor = '#606060',
    this.showPercentage = true,
    this.percentFormat = ' %3.0f%%',
    Style? percentageStyle,
    this.frequency = _defaultFrequency,
    this.damping = _defaultDamping,
    this.useGradient = false,
    this.gradientColorA = '#5A56E0',
    this.gradientColorB = '#EE6FF8',
    this.blend = const [],
    this.colorFunc,
    this.scaleGradient = false,
    this.scaleBlend = false,
    this.indeterminate = false,
    this.pulseWidth = 0.2,
    this.startTime,
    double percentShown = 0,
    double targetPercent = 0,
    double velocity = 0,
    double pulseOffset = 0,
    int? id,
    int tag = 0,
  }) : percentageStyle = percentageStyle ?? Style(),
       _spring = _Spring(frequency: frequency, damping: damping),
       _percentShown = percentShown,
       _targetPercent = targetPercent,
       _velocity = velocity,
       _pulseOffset = pulseOffset,
       _id = id ?? _nextProgressId(),
       _tag = tag;

  /// Total width of the progress bar, including percentage.
  final int width;

  /// Character for filled sections.
  final String full;

  /// Color for filled sections.
  final String fullColor;

  /// Character for empty sections.
  final String empty;

  /// Color for empty sections.
  final String emptyColor;

  /// Whether to show the percentage text.
  final bool showPercentage;

  /// Format string for the percentage (e.g., " %3.0f%%").
  final String percentFormat;

  /// Style for the percentage text.
  final Style percentageStyle;

  /// Spring frequency (speed).
  final double frequency;

  /// Spring damping (bounciness).
  final double damping;

  /// Whether to use a gradient fill.
  final bool useGradient;

  /// First color of the gradient.
  final String gradientColorA;

  /// Second color of the gradient.
  final String gradientColorB;

  /// Blend of colors to use. When provided, overrides [fullColor] and [useGradient].
  final List<String> blend;

  /// Function to dynamically color the progress bar.
  /// Overrides [blend], [fullColor], and [useGradient].
  final ColorFunc? colorFunc;

  /// Whether to scale the gradient to the filled portion.
  final bool scaleGradient;

  /// Whether to scale the blend to the filled portion.
  final bool scaleBlend;

  /// Whether the progress bar is in indeterminate mode.
  final bool indeterminate;

  /// Width of the pulse in indeterminate mode (as a fraction of total width).
  final double pulseWidth;

  /// When the progress started (for ETA calculation).
  final DateTime? startTime;

  final _Spring _spring;
  final double _percentShown;
  final double _targetPercent;
  final double _velocity;
  final double _pulseOffset;
  final int _id;
  final int _tag;

  /// The current visible percentage (for animation).
  double get percentShown => _percentShown;

  /// The target percentage.
  double get percent => _targetPercent;

  /// The current pulse offset (for indeterminate mode).
  double get pulseOffset => _pulseOffset;

  /// The progress bar's unique ID.
  int get id => _id;

  /// Current frame tag (exposed for testing/inspection).
  int get tag => _tag;

  /// Creates a new progress bar with the default blend of colors (purple to pink).
  static ProgressModel withDefaultBlend({int width = _defaultWidth}) {
    return ProgressModel(width: width, blend: ['#5A56E0', '#EE6FF8']);
  }

  /// Returns a copy of the model with the given colors.
  /// - 0 colors: resets to default full color.
  /// - 1 color: uses a solid fill with the given color.
  /// - 2+ colors: uses a blend of the provided colors.
  ProgressModel withColors(List<String> colors) {
    if (colors.isEmpty) {
      return copyWith(fullColor: '#7571F9', blend: [], colorFunc: null);
    }
    if (colors.length == 1) {
      return copyWith(fullColor: colors[0], blend: [], colorFunc: null);
    }
    return copyWith(blend: colors, colorFunc: null);
  }

  /// Returns a copy of the model with the given color function.
  ProgressModel withColorFunc(ColorFunc fn) {
    return copyWith(colorFunc: fn, blend: []);
  }

  /// Whether the progress bar is currently animating.
  bool get isAnimating {
    if (indeterminate) return true;
    final dist = (_percentShown - _targetPercent).abs();
    return !(dist < 0.001 && _velocity < 0.01);
  }

  /// Returns the estimated time remaining as a string (MM:SS).
  String get eta {
    final start = startTime;
    if (start == null || _targetPercent <= 0) return '--:--';
    final elapsed = DateTime.now().difference(start);
    if (_targetPercent >= 1.0) return '00:00';

    final totalEstimatedMs = elapsed.inMilliseconds / _targetPercent;
    final remainingMs = totalEstimatedMs - elapsed.inMilliseconds;

    final duration = Duration(milliseconds: remainingMs.round());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Creates a copy with the given fields replaced.
  ProgressModel copyWith({
    int? width,
    String? full,
    String? fullColor,
    String? empty,
    String? emptyColor,
    bool? showPercentage,
    String? percentFormat,
    Style? percentageStyle,
    bool? useGradient,
    String? gradientColorA,
    String? gradientColorB,
    List<String>? blend,
    ColorFunc? colorFunc,
    bool? scaleGradient,
    bool? scaleBlend,
    bool? indeterminate,
    double? pulseWidth,
    DateTime? startTime,
    double? percentShown,
    double? targetPercent,
    double? velocity,
    double? pulseOffset,
    int? tag,
    double? frequency,
    double? damping,
  }) {
    return ProgressModel(
      width: width ?? this.width,
      full: full ?? this.full,
      fullColor: fullColor ?? this.fullColor,
      empty: empty ?? this.empty,
      emptyColor: emptyColor ?? this.emptyColor,
      showPercentage: showPercentage ?? this.showPercentage,
      percentFormat: percentFormat ?? this.percentFormat,
      percentageStyle: percentageStyle ?? this.percentageStyle,
      useGradient: useGradient ?? this.useGradient,
      gradientColorA: gradientColorA ?? this.gradientColorA,
      gradientColorB: gradientColorB ?? this.gradientColorB,
      blend: blend ?? this.blend,
      colorFunc: colorFunc ?? this.colorFunc,
      scaleGradient: scaleGradient ?? this.scaleGradient,
      scaleBlend: scaleBlend ?? this.scaleBlend,
      indeterminate: indeterminate ?? this.indeterminate,
      pulseWidth: pulseWidth ?? this.pulseWidth,
      startTime: startTime ?? this.startTime,
      percentShown: percentShown ?? _percentShown,
      targetPercent: targetPercent ?? _targetPercent,
      velocity: velocity ?? _velocity,
      pulseOffset: pulseOffset ?? _pulseOffset,
      id: _id,
      tag: tag ?? _tag,
      frequency: frequency ?? this.frequency,
      damping: damping ?? this.damping,
    );
  }

  /// Sets the target percentage and returns a command for animation.
  (ProgressModel, Cmd?) setPercent(double p, {bool animate = true}) {
    final clamped = p.clamp(0.0, 1.0);
    final newModel = copyWith(targetPercent: clamped, tag: _tag + 1);
    if (!animate) {
      return (newModel.copyWith(percentShown: clamped, velocity: 0), null);
    }
    return (newModel, newModel._nextFrame());
  }

  /// Increments the percentage by the given amount.
  (ProgressModel, Cmd?) incrPercent(double v) {
    return setPercent(_targetPercent + v);
  }

  /// Decrements the percentage by the given amount.
  (ProgressModel, Cmd?) decrPercent(double v) {
    return setPercent(_targetPercent - v);
  }

  Cmd _nextFrame() {
    final id = _id;
    final tag = _tag;
    return Cmd.tick(
      Duration(milliseconds: 1000 ~/ _fps),
      (_) => ProgressFrameMsg(id: id, tag: tag),
    );
  }

  @override
  Cmd? init() => null;

  @override
  (ProgressModel, Cmd?) update(Msg msg) {
    if (msg is! ProgressFrameMsg) {
      return (this, null);
    }

    if (msg.id != _id || msg.tag != _tag) {
      return (this, null);
    }

    // Stop animating if we've reached equilibrium
    if (!isAnimating) {
      return (this, null);
    }

    if (indeterminate) {
      // Update pulse offset
      final nextOffset = (_pulseOffset + 0.02) % 1.0;
      final newModel = copyWith(pulseOffset: nextOffset, tag: _tag);
      return (newModel, newModel._nextFrame());
    }

    // Update spring animation
    final (newPercent, newVelocity) = _spring.update(
      _percentShown,
      _velocity,
      _targetPercent,
    );

    final newModel = copyWith(percentShown: newPercent, velocity: newVelocity);

    return (newModel, newModel._nextFrame());
  }

  @override
  String view() => viewAs(indeterminate ? _pulseOffset : _percentShown);

  /// Renders the progress bar at the given percentage (static rendering).
  String viewAs(double percent) {
    final sb = StringBuffer();
    final percentView = indeterminate ? '' : _percentageView(percent);
    _barView(sb, percent, Style.visibleLength(percentView));
    sb.write(percentView);
    return sb.toString();
  }

  void _barView(StringBuffer b, double percent, int textWidth) {
    final tw = math.max(0, width - textWidth);
    if (tw <= 0) return;

    if (indeterminate) {
      _renderIndeterminate(b, tw, percent);
      return;
    }

    var fw = (tw * percent).round();
    fw = math.max(0, math.min(tw, fw));

    final isHalfBlock = full == defaultFullCharHalfBlock;

    if (colorFunc != null) {
      final halfBlockPerc = 0.5 / tw;
      for (var i = 0; i < fw; i++) {
        final current = i / tw;
        var style = Style().foreground(colorFunc!(percent, current));
        if (isHalfBlock) {
          style = style.background(
            colorFunc!(percent, math.min(current + halfBlockPerc, 1.0)),
          );
        }
        b.write(style.render(full));
      }
    } else if (blend.isNotEmpty || useGradient) {
      final colors = blend.isNotEmpty
          ? blend.map((c) => BasicColor(c)).toList()
          : [BasicColor(gradientColorA), BasicColor(gradientColorB)];

      final multiplier = isHalfBlock ? 2 : 1;
      final scale = blend.isNotEmpty ? scaleBlend : scaleGradient;
      final blendCount = scale ? fw * multiplier : tw * multiplier;

      final blended = blending.blend1D(
        math.max(1, blendCount),
        colors,
        hasDarkBackground: true,
      );

      var blendIndex = 0;
      for (var i = 0; i < fw; i++) {
        if (!isHalfBlock) {
          b.write(Style().foreground(blended[i]).render(full));
          continue;
        }

        b.write(
          Style()
              .foreground(blended[blendIndex])
              .background(blended[blendIndex + 1])
              .render(full),
        );
        blendIndex += 2;
      }
    } else {
      // Solid fill
      b.write(Style().foreground(BasicColor(fullColor)).render(full * fw));
    }

    // Empty fill
    final n = math.max(0, tw - fw);
    if (n > 0) {
      b.write(Style().foreground(BasicColor(emptyColor)).render(empty * n));
    }
  }

  void _renderIndeterminate(StringBuffer b, int tw, double offset) {
    final pw = (tw * pulseWidth).round().clamp(1, tw);
    final start = (tw * offset).round();
    final isHalfBlock = full == defaultFullCharHalfBlock;

    for (var i = 0; i < tw; i++) {
      // Check if i is within the pulse (wrapping around)
      var inPulse = false;
      if (start + pw <= tw) {
        inPulse = i >= start && i < start + pw;
      } else {
        inPulse = i >= start || i < (start + pw) % tw;
      }

      if (inPulse) {
        if (colorFunc != null) {
          final current = i / tw;
          var style = Style().foreground(colorFunc!(1.0, current));
          if (isHalfBlock) {
            style = style.background(
              colorFunc!(1.0, math.min(current + 0.5 / tw, 1.0)),
            );
          }
          b.write(style.render(full));
        } else if (blend.isNotEmpty || useGradient) {
          final colors = blend.isNotEmpty
              ? blend.map((c) => BasicColor(c)).toList()
              : [BasicColor(gradientColorA), BasicColor(gradientColorB)];
          // Calculate relative position in pulse for gradient
          var rel = 0.0;
          if (i >= start) {
            rel = (i - start) / (pw - 1);
          } else {
            rel = (tw - start + i) / (pw - 1);
          }

          if (!isHalfBlock) {
            final blended = blending.blend1D(
              pw,
              colors,
              hasDarkBackground: true,
            );
            final idx = (rel * (pw - 1)).round().clamp(0, pw - 1);
            b.write(Style().foreground(blended[idx]).render(full));
          } else {
            final blended = blending.blend1D(
              pw * 2,
              colors,
              hasDarkBackground: true,
            );
            final idx = (rel * (pw * 2 - 1)).round().clamp(0, pw * 2 - 2);
            b.write(
              Style()
                  .foreground(blended[idx])
                  .background(blended[idx + 1])
                  .render(full),
            );
          }
        } else {
          b.write(Style().foreground(BasicColor(fullColor)).render(full));
        }
      } else {
        b.write(Style().foreground(BasicColor(emptyColor)).render(empty));
      }
    }
  }

  String _percentageView(double percent) {
    if (!showPercentage) return '';
    final clamped = percent.clamp(0.0, 1.0);
    // Simple format replacement
    var result = percentFormat;
    final value = (clamped * 100).toStringAsFixed(0);
    result = result.replaceFirst('%3.0f', value.padLeft(3));
    return percentageStyle.inline(true).render(result);
  }
}

/// A model for managing multiple progress bars simultaneously.
class MultiProgressModel extends ViewComponent {
  /// Creates a new multi-progress model.
  MultiProgressModel({
    Map<String, ProgressModel>? bars,
    this.width = _defaultWidth,
  }) : bars = bars ?? {};

  /// The map of progress bars, keyed by a unique identifier.
  final Map<String, ProgressModel> bars;

  /// Default width for new progress bars.
  final int width;

  /// Adds a new progress bar with the given key.
  MultiProgressModel add(String key, {ProgressModel? model}) {
    final newBars = Map<String, ProgressModel>.from(bars);
    newBars[key] = model ?? ProgressModel(width: width);
    return MultiProgressModel(bars: newBars, width: width);
  }

  /// Removes the progress bar with the given key.
  MultiProgressModel remove(String key) {
    final newBars = Map<String, ProgressModel>.from(bars);
    newBars.remove(key);
    return MultiProgressModel(bars: newBars, width: width);
  }

  /// Updates the percentage for a specific bar.
  (MultiProgressModel, Cmd?) setPercent(
    String key,
    double p, {
    bool animate = true,
  }) {
    final bar = bars[key];
    if (bar == null) return (this, null);

    final (newBar, cmd) = bar.setPercent(p, animate: animate);
    final newBars = Map<String, ProgressModel>.from(bars);
    newBars[key] = newBar;
    return (MultiProgressModel(bars: newBars, width: width), cmd);
  }

  @override
  Cmd? init() => null;

  @override
  (MultiProgressModel, Cmd?) update(Msg msg) {
    if (msg is! ProgressFrameMsg) return (this, null);

    final cmds = <Cmd>[];
    final newBars = Map<String, ProgressModel>.from(bars);
    var changed = false;

    for (final entry in bars.entries) {
      final (newBar, cmd) = entry.value.update(msg);
      if (newBar != entry.value) {
        newBars[entry.key] = newBar;
        changed = true;
      }
      if (cmd != null) cmds.add(cmd);
    }

    if (!changed && cmds.isEmpty) return (this, null);
    return (
      MultiProgressModel(bars: newBars, width: width),
      cmds.isEmpty ? null : Cmd.batch(cmds),
    );
  }

  @override
  String view() {
    return bars.entries.map((e) => '${e.key}: ${e.value.view()}').join('\n');
  }
}
