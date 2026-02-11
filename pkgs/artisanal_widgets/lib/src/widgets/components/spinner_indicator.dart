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

  @override
  Cmd? handleInit() {
    if (!active || frames.isEmpty) return null;
    return every(interval, (_) => _SpinnerTickMsg(id), id: id);
  }
}

class _SpinnerIndicatorState extends State<SpinnerIndicator> {
  int _index = 0;

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
    return null;
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is _SpinnerTickMsg && msg.id == widget.id) {
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

class _SpinnerTickMsg extends Msg {
  const _SpinnerTickMsg(this.id);

  final String id;
}
