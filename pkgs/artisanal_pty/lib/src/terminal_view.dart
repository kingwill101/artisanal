import 'package:artisanal/runtime.dart' as runtime;
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
  late _TerminalScrollController _scrollController = _TerminalScrollController(
    widget.terminal,
  );

  @override
  void initState() {
    super.initState();
    widget.terminal.addListener(_changed);
  }

  @override
  runtime.Cmd? didUpdateWidget(covariant TerminalView oldWidget) {
    if (!identical(oldWidget.terminal, widget.terminal)) {
      oldWidget.terminal.removeListener(_changed);
      widget.terminal.addListener(_changed);
      _scrollController = _TerminalScrollController(widget.terminal);
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
  Widget build(BuildContext context) {
    final terminalText = Text(widget.terminal.render(showCursor: true));
    final content =
        widget.terminal.width <= 1 ||
            widget.terminal.scrollbackLength == 0 ||
            widget.terminal.mouseTracking != TerminalMouseTracking.none
        ? terminalText
        : Scrollbar(
            controller: _scrollController,
            overlay: true,
            enableHover: true,
            mouseWheelDelta: 3,
            child: terminalText,
          );
    return Focusable(
      controller: widget.focusController,
      focusId: widget.focusId,
      autofocus: widget.autofocus,
      onKey: (message) {
        final data = TerminalInputEncoder.encode(
          message.key,
          applicationCursorKeys: widget.terminal.applicationCursorKeys,
          keyboardEnhancementFlags: widget.terminal.keyboardEnhancementFlags,
        );
        if (data.isEmpty) return null;
        widget.onInput?.call(data);
        return runtime.Cmd.none();
      },
      child: content,
    );
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg case runtime.HitTestMouseMsg(
      :final event,
      :final localX,
      :final localY,
    )) {
      final data = TerminalInputEncoder.encodeMouse(
        event,
        x: localX.floor(),
        y: localY.floor(),
        tracking: widget.terminal.mouseTracking,
        sgrCoordinates: widget.terminal.sgrMouseCoordinates,
        urxvtCoordinates: widget.terminal.urxvtMouseCoordinates,
      );
      if (data.isEmpty) return null;
      final focusId = widget.focusId;
      if (focusId != null) widget.focusController?.requestFocus(focusId);
      widget.onInput?.call(data);
      return runtime.Cmd.none();
    }
    return null;
  }
}

final class _TerminalScrollController implements ScrollController {
  const _TerminalScrollController(this.terminal);

  final VirtualTerminal terminal;

  @override
  int get offset => maxOffset - terminal.scrollOffset;

  @override
  int get viewportExtent => terminal.height;

  @override
  int get contentExtent => terminal.height + terminal.scrollbackLength;

  @override
  int get maxOffset => terminal.scrollbackLength;

  @override
  double get scrollPercent => maxOffset == 0 ? 0 : offset / maxOffset;

  @override
  bool jumpTo(int offset) {
    if (terminal.mouseTracking != TerminalMouseTracking.none) return false;
    final target = offset.clamp(0, maxOffset);
    return terminal.scrollBy(maxOffset - target - terminal.scrollOffset);
  }

  @override
  bool scrollBy(int delta) => jumpTo(offset + delta);

  @override
  void addListener(void Function() listener) => terminal.addListener(listener);

  @override
  void removeListener(void Function() listener) =>
      terminal.removeListener(listener);
}
