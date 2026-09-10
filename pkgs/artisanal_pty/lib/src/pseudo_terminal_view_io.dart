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
    this.quitOnExit = true,
    this.width,
    this.height,
    super.key,
  }) : assert(width == null || width > 0),
       assert(height == null || height > 0);

  final PseudoTerminal pty;
  final FocusController? focusController;
  final String? focusId;
  final bool autofocus;

  /// Whether exiting the child process should quit the widget application.
  final bool quitOnExit;

  /// Explicit PTY width, overriding inherited layout constraints.
  final int? width;

  /// Explicit PTY height, overriding inherited layout constraints.
  final int? height;

  @override
  State<PseudoTerminalView> createState() => _PseudoTerminalViewState();
}

class _PseudoTerminalViewState extends State<PseudoTerminalView> {
  late final VirtualTerminal _terminal = VirtualTerminal();
  Object _activeOwner = Object();
  StreamSubscription<String>? _subscription;
  final StreamController<_PtyEvent> _events = StreamController();
  int _width = 0;
  int _height = 0;
  bool _previousOutputWasCarriageReturn = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    final owner = Object();
    _activeOwner = owner;
    _previousOutputWasCarriageReturn = false;
    _subscription = widget.pty.out.listen(
      (data) => _addEvent(_PtyOutputEvent(owner, data)),
    );
    widget.pty.exitCode.then(
      (exitCode) => _addEvent(_PtyExitEvent(owner, exitCode)),
    );
  }

  void _addEvent(_PtyEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  @override
  runtime.Cmd? handleInit() => runtime.StreamCmd<_PtyEvent>(
    stream: _events.stream,
    onData: (event) => _PtyEventMsg(event),
  );

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg case _PtyEventMsg(
      :final event,
    ) when identical(event.owner, _activeOwner)) {
      switch (event) {
        case _PtyOutputEvent(:final data):
          try {
            _terminal.writeText(_normalizeLineFeeds(data));
            final responses = _terminal.takePendingResponses();
            if (responses.isNotEmpty) widget.pty.write(responses);
          } finally {
            widget.pty.ackProcessed();
          }
        case _PtyExitEvent():
          if (widget.quitOnExit) return runtime.Cmd.quit();
      }
    }
    return null;
  }

  String _normalizeLineFeeds(String data) {
    if (data.isEmpty) return data;
    if (!data.contains('\n')) {
      _previousOutputWasCarriageReturn = data.endsWith('\r');
      return data;
    }

    final normalized = StringBuffer();
    for (final codeUnit in data.codeUnits) {
      if (codeUnit == 0x0a && !_previousOutputWasCarriageReturn) {
        normalized.writeCharCode(0x0d);
      }
      normalized.writeCharCode(codeUnit);
      _previousOutputWasCarriageReturn = codeUnit == 0x0d;
    }
    return normalized.toString();
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
    _events.close();
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
      final width =
          widget.width ??
          (constraints.hasBoundedWidth
              ? constraints.maxWidth.toInt().clamp(1, 10000).toInt()
              : 80);
      final height =
          widget.height ??
          (constraints.hasBoundedHeight
              ? constraints.maxHeight.toInt().clamp(1, 10000).toInt()
              : 24);
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

sealed class _PtyEvent {
  const _PtyEvent(this.owner);

  final Object owner;
}

final class _PtyOutputEvent extends _PtyEvent {
  const _PtyOutputEvent(super.owner, this.data);

  final String data;
}

final class _PtyExitEvent extends _PtyEvent {
  const _PtyExitEvent(super.owner, this.exitCode);

  final int exitCode;
}

final class _PtyEventMsg extends runtime.Msg {
  const _PtyEventMsg(this.event);

  final _PtyEvent event;
}
