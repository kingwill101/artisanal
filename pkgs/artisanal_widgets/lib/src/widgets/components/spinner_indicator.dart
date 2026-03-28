part of 'components_widgets.dart';

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
  int _index = 0;
  final Object _tickToken = Object();
  late final String _tickCmdId = 'spinner:${identityHashCode(this)}';

  @override
  Cmd? handleInit() {
    if (!widget.active || widget.frames.isEmpty) return null;
    return every(
      widget.interval,
      (_) => _SpinnerTickMsg(_tickToken),
      id: _tickCmdId,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.frames.isNotEmpty) {
      _index = widget.startIndex % widget.frames.length;
    }
  }

  @override
  Cmd? didUpdateWidget(covariant SpinnerIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frames.isNotEmpty && _index >= widget.frames.length) {
      _index = 0;
    }
    if (!widget.active || widget.frames.isEmpty) return null;
    if (!oldWidget.active ||
        oldWidget.frames.isEmpty ||
        oldWidget.interval != widget.interval) {
      return every(
        widget.interval,
        (_) => _SpinnerTickMsg(_tickToken),
        id: _tickCmdId,
      );
    }
    return null;
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is _SpinnerTickMsg && identical(msg.token, _tickToken)) {
      if (!widget.active || widget.frames.isEmpty) return null;
      setState(() {
        _index = (_index + 1) % widget.frames.length;
      });
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) return SizedBox.shrink();
    final theme = ThemeScope.of(context);
    final style = _copyStyle(widget.textStyle ?? theme.bodyMedium)
      ..foreground(widget.color ?? theme.primary);
    final frame = widget.frames[_index % widget.frames.length];
    return Text(frame, style: style);
  }
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
    final style = _copyStyle(Style())..foreground(color ?? theme.primary);
    return Text(_determinateGlyphs[index], style: style);
  }
}

class _SpinnerTickMsg extends Msg {
  const _SpinnerTickMsg(this.token);

  final Object token;

  @override
  bool get dropWhenInputQueued => true;
}
