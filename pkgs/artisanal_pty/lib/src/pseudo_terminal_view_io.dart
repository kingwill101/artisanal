import 'dart:async';

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
  StreamSubscription<String>? _subscription;
  int _width = 0;
  int _height = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.pty.out.listen(_terminal.writeText);
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
          ? constraints.maxWidth.toInt().clamp(1, 10000)
          : 80;
      final height = constraints.hasBoundedHeight
          ? constraints.maxHeight.toInt().clamp(1, 10000)
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
