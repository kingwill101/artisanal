import 'package:artisanal/runtime.dart';

import '_component_foundation.dart';

import 'package:artisanal/style.dart' show Color, Style;

/// An animated spinner indicator for loading states.
///
/// The [SpinnerIndicator] cycles through [frames] at the specified [interval].
/// Set [active] to false to pause the animation. Customize the appearance with
/// [color] and [textStyle].
///
/// Example:
/// ```dart
/// SpinnerIndicator(
///   frames: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧'],
///   interval: Duration(milliseconds: 100),
/// )
/// ```
class SpinnerIndicator extends StatefulWidget {
  SpinnerIndicator({
    this.frames = const ['|', '/', '-', '\\'],
    this.interval = const Duration(milliseconds: 120),
    this.active = true,
    this.color,
    this.textStyle,
    this.startIndex = 0,
    super.key,
  });

  final List<String> frames;
  final Duration interval;
  final bool active;
  final Color? color;
  final Style? textStyle;
  final int startIndex;

  @override
  State createState() => _SpinnerIndicatorState();
}

class _SpinnerIndicatorState extends State<SpinnerIndicator> {
  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) return SizedBox.shrink();
    final theme = ThemeScope.of(context);
    final style = copyStyle(widget.textStyle ?? theme.bodyMedium)
      ..foreground(widget.color ?? theme.primary);
    if (!widget.active || MediaQuery.disableAnimationsOf(context)) {
      final index = widget.startIndex % widget.frames.length;
      return Text(widget.frames[index], style: style);
    }
    return _AnimatedSpinnerIndicator(
      frames: widget.frames,
      interval: widget.interval,
      startIndex: widget.startIndex,
      style: style,
    );
  }
}

class _AnimatedSpinnerIndicator extends StatefulWidget {
  _AnimatedSpinnerIndicator({
    required this.frames,
    required this.interval,
    required this.startIndex,
    required this.style,
  });

  final List<String> frames;
  final Duration interval;
  final int startIndex;
  final Style style;

  @override
  State createState() => _AnimatedSpinnerIndicatorState();
}

class _AnimatedSpinnerIndicatorState extends State<_AnimatedSpinnerIndicator> {
  late int _index;
  Object _tickToken = Object();

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex % widget.frames.length;
  }

  Cmd _scheduleTick() {
    final token = _tickToken;
    return Cmd.tick(widget.interval, (_) => _SpinnerTickMsg(token));
  }

  @override
  Cmd? handleInit() => _scheduleTick();

  @override
  Cmd? didUpdateWidget(covariant _AnimatedSpinnerIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frames.isNotEmpty && _index >= widget.frames.length) {
      _index = 0;
    }
    if (oldWidget.interval != widget.interval ||
        !_sameFrames(oldWidget.frames, widget.frames)) {
      _tickToken = Object();
      return _scheduleTick();
    }
    return null;
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is _SpinnerTickMsg && identical(msg.token, _tickToken)) {
      setState(() {
        _index = (_index + 1) % widget.frames.length;
      });
      return _scheduleTick();
    }
    return null;
  }

  static bool _sameFrames(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) =>
      Text(widget.frames[_index % widget.frames.length], style: widget.style);
}

/// Flutter-style circular progress indicator.
///
/// When [value] is non-null, renders a determinate glyph.
/// When [value] is null, renders an animated spinner.
class CircularProgressIndicator extends StatelessWidget {
  CircularProgressIndicator({
    this.value,
    this.color,
    this.interval = const Duration(milliseconds: 90),
    this.active = true,
    super.key,
  });

  final double? value;
  final Color? color;
  final Duration interval;
  final bool active;

  static const List<String> _spinnerFrames = ['◜', '◠', '◝', '◞', '◡', '◟'];
  static const List<String> _determinateGlyphs = ['○', '◔', '◑', '◕', '●'];

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return SpinnerIndicator(
        frames: _spinnerFrames,
        interval: interval,
        active: active,
        color: color,
      );
    }

    final theme = ThemeScope.of(context);
    final clamped = value!.clamp(0.0, 1.0);
    final index = (clamped * (_determinateGlyphs.length - 1)).round();
    final style = copyStyle(Style())..foreground(color ?? theme.primary);
    return Text(_determinateGlyphs[index], style: style);
  }
}

class _SpinnerTickMsg extends Msg {
  const _SpinnerTickMsg(this.token);

  final Object token;

  @override
  bool get dropWhenInputQueued => false;
}
