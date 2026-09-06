import 'package:artisanal/runtime.dart';
import 'package:artisanal_widgets/widgets.dart';

import 'input_encoder.dart';
import 'virtual_terminal.dart';

/// Displays a [VirtualTerminal] and forwards focused keyboard input.
class TerminalView extends StatefulWidget {
  TerminalView({
    required this.terminal,
    this.onInput,
    this.focusController,
    this.focusId,
    this.autofocus = true,
    super.key,
  });

  final VirtualTerminal terminal;
  final void Function(String data)? onInput;
  final FocusController? focusController;
  final String? focusId;
  final bool autofocus;

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  @override
  void initState() {
    super.initState();
    widget.terminal.addListener(_changed);
  }

  @override
  Cmd? didUpdateWidget(covariant TerminalView oldWidget) {
    if (!identical(oldWidget.terminal, widget.terminal)) {
      oldWidget.terminal.removeListener(_changed);
      widget.terminal.addListener(_changed);
    }
    return super.didUpdateWidget(oldWidget);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.terminal.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focusable(
    controller: widget.focusController,
    focusId: widget.focusId,
    autofocus: widget.autofocus,
    onKey: (message) {
      final data = TerminalInputEncoder.encode(message.key);
      if (data.isNotEmpty) widget.onInput?.call(data);
      return null;
    },
    child: Text(widget.terminal.render()),
  );
}
