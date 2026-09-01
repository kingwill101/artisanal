import 'dart:math' as math;
import '_component_foundation.dart';

import 'package:artisanal/runtime.dart';
import 'package:artisanal/style.dart' show Color, Style;
import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/runtime.dart' show Cmd, KeyMsg;

/// An immutable pair of values used by [RangeSlider].
class RangeValues {
  const RangeValues(this.start, this.end) : assert(start <= end);

  final double start;
  final double end;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RangeValues && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'RangeValues($start, $end)';
}

/// Flutter-style slider for selecting a single value.
///
/// The slider renders a horizontal track with a draggable thumb that represents
/// a value within the range defined by [min] and [max]. Users can interact
/// via mouse clicks, drag gestures, or keyboard arrows.
///
/// The slider is disabled when [enabled] is `false` or when [onChanged] is `null`.
/// Use [divisions] to snap the value to discrete steps.
///
/// Example:
/// ```dart
/// Slider(
///   value: 0.5,
///   min: 0.0,
///   max: 1.0,
///   divisions: 10,
///   onChanged: (v) => print('value: $v'),
/// )
/// ```
class Slider extends StatefulWidget {
  Slider({
    required this.value,
    this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.width = 24,
    this.enabled = true,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.activeTrackChar = '=',
    this.inactiveTrackChar = '-',
    this.thumbChar = 'o',
    this.label,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  }) : assert(max >= min),
       assert(divisions == null || divisions > 0),
       assert(width > 0),
       assert(activeTrackChar.length == 1),
       assert(inactiveTrackChar.length == 1),
       assert(thumbChar.length == 1);

  final double value;
  final ValueCmdCallback<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final int width;
  final bool enabled;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final String activeTrackChar;
  final String inactiveTrackChar;
  final String thumbChar;
  final String? label;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;

  @override
  State createState() => _SliderState();
}

class _SliderState extends State<Slider> {
  bool _hovered = false;
  bool _focused = false;
  bool _dragging = false;

  bool get _enabled =>
      widget.enabled && widget.onChanged != null && widget.max > widget.min;

  double get _range => widget.max - widget.min;

  double _clampValue(double value) => value.clamp(widget.min, widget.max);

  double _snapValue(double value) {
    var next = _clampValue(value);
    final divisions = widget.divisions;
    if (divisions == null || divisions <= 0 || _range <= 0) {
      return next;
    }
    final step = _range / divisions;
    if (step <= 0) return next;
    final snapped = ((next - widget.min) / step).round() * step + widget.min;
    next = snapped;
    return _clampValue(next);
  }

  int _thumbIndexForValue(double value) {
    final width = math.max(1, widget.width);
    if (width == 1) return 0;
    final normalized = (_clampValue(value) - widget.min) / _range;
    return (normalized * (width - 1)).round().clamp(0, width - 1);
  }

  double _valueForLocalX(double x) {
    final width = math.max(1, widget.width);
    if (width == 1) return widget.min;
    final localX = x.clamp(0.0, (width - 1).toDouble());
    final t = localX / (width - 1);
    return _snapValue(widget.min + _range * t);
  }

  double get _keyboardStep {
    final divisions = widget.divisions;
    if (divisions != null && divisions > 0 && _range > 0) {
      return _range / divisions;
    }
    if (widget.width <= 1 || _range <= 0) return 0.0;
    return _range / (widget.width - 1);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  void _setDragging(bool value) {
    if (_dragging == value) return;
    setState(() => _dragging = value);
  }

  Cmd? _emitValue(double value) {
    if (!_enabled) return null;
    final current = _snapValue(widget.value);
    final next = _snapValue(value);
    if ((next - current).abs() < 1e-9) return null;
    return widget.onChanged?.call(next);
  }

  Cmd? _handleKey(KeyMsg msg) {
    if (!_enabled) return null;

    final key = msg.key;
    switch (key.type) {
      case terminal_keys.KeyType.left:
      case terminal_keys.KeyType.down:
        return _emitValue(widget.value - _keyboardStep);
      case terminal_keys.KeyType.right:
      case terminal_keys.KeyType.up:
        return _emitValue(widget.value + _keyboardStep);
      case terminal_keys.KeyType.home:
        return _emitValue(widget.min);
      case terminal_keys.KeyType.end:
        return _emitValue(widget.max);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final width = math.max(1, widget.width);
    final thumbIndex = _thumbIndexForValue(widget.value);

    final activeStyle = copyStyle(Style())
      ..foreground(widget.activeColor ?? theme.primary);
    final inactiveStyle = copyStyle(Style())
      ..foreground(widget.inactiveColor ?? theme.border);
    final thumbStyle = copyStyle(Style())
      ..foreground(widget.thumbColor ?? widget.activeColor ?? theme.primary);

    if (_hovered || _focused || _dragging) {
      thumbStyle.bold();
    }
    if (!_enabled) {
      activeStyle.dim();
      inactiveStyle.dim();
      thumbStyle.dim();
    }

    final buffer = StringBuffer();
    for (var i = 0; i < width; i++) {
      if (i == thumbIndex) {
        buffer.write(thumbStyle.render(widget.thumbChar));
      } else if (i < thumbIndex) {
        buffer.write(activeStyle.render(widget.activeTrackChar));
      } else {
        buffer.write(inactiveStyle.render(widget.inactiveTrackChar));
      }
    }

    Widget result = Text(buffer.toString());
    if (widget.label != null && widget.label!.isNotEmpty) {
      final labelStyle = copyStyle(theme.labelSmall)..foreground(theme.muted);
      result = Row(
        gap: 1,
        children: [
          result,
          Text(widget.label!, style: labelStyle),
        ],
      );
    }

    if (_enabled) {
      result = GestureDetector(
        onTapDown: (details) {
          return _emitValue(_valueForLocalX(details.localPosition.dx));
        },
        onDragStart: (details) {
          _setDragging(true);
          return _emitValue(_valueForLocalX(details.localPosition.dx));
        },
        onDragUpdate: (details) {
          return _emitValue(_valueForLocalX(details.localPosition.dx));
        },
        onDragEnd: (_) {
          _setDragging(false);
          return null;
        },
        child: result,
      );
      result = MouseRegion(
        onEnter: (_) {
          _setHovered(true);
          return null;
        },
        onExit: (_) {
          _setHovered(false);
          _setDragging(false);
          return null;
        },
        child: result,
      );
      result = Focusable(
        controller: widget.focusController ?? FocusScope.of(context),
        focusId: widget.focusId,
        autofocus: widget.autofocus,
        onKey: _handleKey,
        onFocusChange: _setFocused,
        child: result,
      );
    }

    if (!_enabled) {
      result = Opacity(opacity: 0.7, child: result);
    }

    return result;
  }
}

/// Flutter-style range slider for selecting a start/end interval.
///
/// The [RangeSlider] displays two thumbs on a single track, allowing users
/// to select a range of values. Press `s` to select the start thumb and `e`
/// to select the end thumb when focused.
///
/// Like [Slider], it supports mouse and keyboard interaction. Use [divisions]
/// to snap values to discrete steps.
///
/// The slider is disabled when [enabled] is `false` or when [onChanged] is `null`.
///
/// Example:
/// ```dart
/// RangeSlider(
///   values: RangeValues(0.2, 0.8),
///   min: 0.0,
///   max: 1.0,
///   divisions: 10,
///   onChanged: (v) => print('range: ${v.start} - ${v.end}'),
/// )
/// ```
class RangeSlider extends StatefulWidget {
  RangeSlider({
    required this.values,
    this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.width = 28,
    this.enabled = true,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.rangeTrackChar = '=',
    this.inactiveTrackChar = '-',
    this.thumbChar = 'o',
    this.label,
    this.autofocus = false,
    this.focusId,
    this.focusController,
    super.key,
  }) : assert(max >= min),
       assert(divisions == null || divisions > 0),
       assert(width > 1),
       assert(rangeTrackChar.length == 1),
       assert(inactiveTrackChar.length == 1),
       assert(thumbChar.length == 1);

  final RangeValues values;
  final ValueCmdCallback<RangeValues>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final int width;
  final bool enabled;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final String rangeTrackChar;
  final String inactiveTrackChar;
  final String thumbChar;
  final String? label;
  final bool autofocus;
  final String? focusId;
  final FocusController? focusController;

  @override
  State createState() => _RangeSliderState();
}

class _RangeSliderState extends State<RangeSlider> {
  bool _hovered = false;
  bool _focused = false;
  bool _dragging = false;
  bool _activeStartThumb = true;
  bool _draggingStartThumb = true;

  bool get _enabled =>
      widget.enabled && widget.onChanged != null && widget.max > widget.min;

  double get _range => widget.max - widget.min;

  double _clampValue(double value) => value.clamp(widget.min, widget.max);

  double _snapValue(double value) {
    var next = _clampValue(value);
    final divisions = widget.divisions;
    if (divisions == null || divisions <= 0 || _range <= 0) {
      return next;
    }
    final step = _range / divisions;
    if (step <= 0) return next;
    final snapped = ((next - widget.min) / step).round() * step + widget.min;
    next = snapped;
    return _clampValue(next);
  }

  RangeValues _normalize(RangeValues values) {
    var start = _snapValue(values.start);
    var end = _snapValue(values.end);
    if (start > end) {
      final mid = _snapValue((start + end) / 2);
      start = mid;
      end = mid;
    }
    return RangeValues(start, end);
  }

  int _thumbIndexForValue(double value) {
    final width = math.max(2, widget.width);
    final normalized = (_clampValue(value) - widget.min) / _range;
    return (normalized * (width - 1)).round().clamp(0, width - 1);
  }

  double _valueForLocalX(double x) {
    final width = math.max(2, widget.width);
    final localX = x.clamp(0.0, (width - 1).toDouble());
    final t = localX / (width - 1);
    return _snapValue(widget.min + _range * t);
  }

  double get _keyboardStep {
    final divisions = widget.divisions;
    if (divisions != null && divisions > 0 && _range > 0) {
      return _range / divisions;
    }
    if (widget.width <= 1 || _range <= 0) return 0.0;
    return _range / (widget.width - 1);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  void _setDragging(bool value) {
    if (_dragging == value) return;
    setState(() => _dragging = value);
  }

  Cmd? _emitValues(RangeValues values) {
    if (!_enabled) return null;
    final current = _normalize(widget.values);
    final next = _normalize(values);
    final unchanged =
        (next.start - current.start).abs() < 1e-9 &&
        (next.end - current.end).abs() < 1e-9;
    if (unchanged) return null;
    return widget.onChanged?.call(next);
  }

  bool _pickStartThumb(double localX) {
    final values = _normalize(widget.values);
    final startIndex = _thumbIndexForValue(values.start);
    final endIndex = _thumbIndexForValue(values.end);
    final x = localX.round().clamp(0, widget.width - 1);
    final distToStart = (x - startIndex).abs();
    final distToEnd = (x - endIndex).abs();
    return distToStart <= distToEnd;
  }

  Cmd? _setThumbValue(bool startThumb, double value) {
    final current = _normalize(widget.values);
    if (startThumb) {
      final start = _snapValue(value).clamp(widget.min, current.end);
      return _emitValues(RangeValues(start, current.end));
    }
    final end = _snapValue(value).clamp(current.start, widget.max);
    return _emitValues(RangeValues(current.start, end));
  }

  Cmd? _handleKey(KeyMsg msg) {
    if (!_enabled) return null;

    final key = msg.key;
    if (key.char == 's') {
      if (!_activeStartThumb) {
        setState(() => _activeStartThumb = true);
      }
      return Cmd.none();
    }
    if (key.char == 'e') {
      if (_activeStartThumb) {
        setState(() => _activeStartThumb = false);
      }
      return Cmd.none();
    }

    final current = _normalize(widget.values);
    final currentValue = _activeStartThumb ? current.start : current.end;

    switch (key.type) {
      case terminal_keys.KeyType.left:
      case terminal_keys.KeyType.down:
        return _setThumbValue(_activeStartThumb, currentValue - _keyboardStep);
      case terminal_keys.KeyType.right:
      case terminal_keys.KeyType.up:
        return _setThumbValue(_activeStartThumb, currentValue + _keyboardStep);
      case terminal_keys.KeyType.home:
        return _setThumbValue(_activeStartThumb, widget.min);
      case terminal_keys.KeyType.end:
        return _setThumbValue(_activeStartThumb, widget.max);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final values = _normalize(widget.values);
    final width = math.max(2, widget.width);
    final startIndex = _thumbIndexForValue(values.start);
    final endIndex = _thumbIndexForValue(values.end);

    final activeStyle = copyStyle(Style())
      ..foreground(widget.activeColor ?? theme.primary);
    final inactiveStyle = copyStyle(Style())
      ..foreground(widget.inactiveColor ?? theme.border);
    final startThumbStyle = copyStyle(Style())
      ..foreground(widget.thumbColor ?? widget.activeColor ?? theme.primary);
    final endThumbStyle = copyStyle(Style())
      ..foreground(widget.thumbColor ?? widget.activeColor ?? theme.primary);

    if ((_hovered || _focused || _dragging) && _activeStartThumb) {
      startThumbStyle.bold();
    }
    if ((_hovered || _focused || _dragging) && !_activeStartThumb) {
      endThumbStyle.bold();
    }

    if (!_enabled) {
      activeStyle.dim();
      inactiveStyle.dim();
      startThumbStyle.dim();
      endThumbStyle.dim();
    }

    final buffer = StringBuffer();
    for (var i = 0; i < width; i++) {
      if (i == startIndex) {
        buffer.write(startThumbStyle.render(widget.thumbChar));
      } else if (i == endIndex) {
        buffer.write(endThumbStyle.render(widget.thumbChar));
      } else if (i > startIndex && i < endIndex) {
        buffer.write(activeStyle.render(widget.rangeTrackChar));
      } else {
        buffer.write(inactiveStyle.render(widget.inactiveTrackChar));
      }
    }

    Widget result = Text(buffer.toString());
    if (widget.label != null && widget.label!.isNotEmpty) {
      final labelStyle = copyStyle(theme.labelSmall)..foreground(theme.muted);
      result = Row(
        gap: 1,
        children: [
          result,
          Text(widget.label!, style: labelStyle),
        ],
      );
    }

    if (_enabled) {
      result = GestureDetector(
        onTapDown: (details) {
          final startThumb = _pickStartThumb(details.localPosition.dx);
          if (_activeStartThumb != startThumb) {
            setState(() => _activeStartThumb = startThumb);
          }
          return _setThumbValue(
            startThumb,
            _valueForLocalX(details.localPosition.dx),
          );
        },
        onDragStart: (details) {
          _setDragging(true);
          _draggingStartThumb = _pickStartThumb(details.localPosition.dx);
          if (_activeStartThumb != _draggingStartThumb) {
            setState(() => _activeStartThumb = _draggingStartThumb);
          }
          return _setThumbValue(
            _draggingStartThumb,
            _valueForLocalX(details.localPosition.dx),
          );
        },
        onDragUpdate: (details) {
          return _setThumbValue(
            _draggingStartThumb,
            _valueForLocalX(details.localPosition.dx),
          );
        },
        onDragEnd: (_) {
          _setDragging(false);
          return null;
        },
        child: result,
      );
      result = MouseRegion(
        onEnter: (_) {
          _setHovered(true);
          return null;
        },
        onExit: (_) {
          _setHovered(false);
          _setDragging(false);
          return null;
        },
        child: result,
      );
      result = Focusable(
        controller: widget.focusController ?? FocusScope.of(context),
        focusId: widget.focusId,
        autofocus: widget.autofocus,
        onKey: _handleKey,
        onFocusChange: _setFocused,
        child: result,
      );
    }

    if (!_enabled) {
      result = Opacity(opacity: 0.7, child: result);
    }

    return result;
  }
}
