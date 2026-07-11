import 'package:artisanal/style.dart' as uv;
import 'package:flutter/material.dart';
import 'package:flutter_artisanal/flutter_artisanal.dart' as uv;

class CounterModel implements uv.Model {
  const CounterModel([this.count = 0]);

  final int count;

  @override
  uv.Cmd? init() => null;

  @override
  (uv.Model, uv.Cmd?) update(uv.Msg msg) {
    return switch (msg) {
      uv.KeyMsg(key: uv.Key(type: uv.KeyType.up)) ||
      uv.KeyMsg(
        key: uv.Key(type: uv.KeyType.runes, runes: [0x2b]),
      ) => (CounterModel(count + 1), null),
      uv.KeyMsg(key: uv.Key(type: uv.KeyType.down)) ||
      uv.KeyMsg(
        key: uv.Key(type: uv.KeyType.runes, runes: [0x2d]),
      ) => (CounterModel(count - 1), null),
      _ => (this, null),
    };
  }

  @override
  String view() {
    final style = uv.Style()
        .bold()
        .foreground(uv.Colors.green)
        .padding(1, 2)
        .border(uv.Border.rounded)
        .width(40);
    return style.render('Count: $count\n\nControls: +/-');
  }
}

class TuiExample extends StatefulWidget {
  const TuiExample({super.key, this.controller});

  final uv.TuiController<CounterModel>? controller;

  @override
  State<TuiExample> createState() => _TuiExampleState();
}

class _TuiExampleState extends State<TuiExample> {
  late final uv.TuiController<CounterModel> _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        uv.TuiController<CounterModel>(
          model: const CounterModel(),
          options: const uv.ProgramOptions(altScreen: true, hotReload: false),
        );
    if (widget.controller == null) {
      _controller.start();
    }
    _controller.repaint.addListener(_onRepaint);
  }

  @override
  void dispose() {
    _controller.repaint.removeListener(_onRepaint);
    _controller.dispose();
    super.dispose();
  }

  void _onRepaint() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return uv.TerminalWidget(
      buffer: _controller.buffer,
      repaint: _controller.repaint,
      onKey: _controller.addInput,
    );
  }
}
