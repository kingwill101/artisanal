import 'dart:async';

import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal_widgets/widgets.dart';
import 'package:pty2/pty2.dart';

import 'terminal_view.dart';
import 'virtual_terminal.dart';

/// Connects an existing [PseudoTerminal] to an Artisanal terminal view.
class PseudoTerminalView extends StatefulWidget {
  PseudoTerminalView({
    required this.pty,
    this.focusController,
    this.focusId,
    this.autofocus = true,
    super.key,
  });

  final PseudoTerminal pty;
  final FocusController? focusController;
  final String? focusId;
  final bool autofocus;

  @override
  State<PseudoTerminalView> createState() => _PseudoTerminalViewState();
}

class _PseudoTerminalViewState extends State<PseudoTerminalView> {
  late final VirtualTerminal _terminal = VirtualTerminal();
  final Object _messageOwner = Object();
  StreamSubscription<String>? _subscription;
  final StreamController<String> _output = StreamController();
  int _width = 0;
  int _height = 0;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _subscription = widget.pty.out.listen(_output.add);
  }

  @override
  runtime.Cmd? handleInit() => runtime.StreamCmd<String>(
    stream: _output.stream,
    onData: (data) => _PtyOutputMsg(_messageOwner, data),
  );

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg case _PtyOutputMsg(
      :final owner,
      :final data,
    ) when identical(owner, _messageOwner)) {
      _terminal.writeText(data);
    }
    return null;
  }

  @override
  runtime.Cmd? didUpdateWidget(covariant PseudoTerminalView oldWidget) {
    if (!identical(oldWidget.pty, widget.pty)) {
      _subscription?.cancel();
      _subscribe();
      if (_width > 0 && _height > 0) widget.pty.resize(_width, _height);
    }
    return super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _output.close();
    _terminal.dispose();
    super.dispose();
  }

  void _resize(int width, int height) {
    if (width == _width && height == _height) return;
    _width = width;
    _height = height;
    _terminal.resize(width, height);
    widget.pty.resize(width, height);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth.toInt().clamp(1, 10000).toInt()
          : 80;
      final height = constraints.hasBoundedHeight
          ? constraints.maxHeight.toInt().clamp(1, 10000).toInt()
          : 24;
      _resize(width, height);
      return TerminalView(
        terminal: _terminal,
        focusController: widget.focusController,
        focusId: widget.focusId,
        autofocus: widget.autofocus,
        onInput: widget.pty.write,
      );
    },
  );
}

final class _PtyOutputMsg extends runtime.Msg {
  const _PtyOutputMsg(this.owner, this.data);

  final Object owner;
  final String data;
}
