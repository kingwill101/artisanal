import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/chat_model.dart';
import '../../widgets/sidebar_widget.dart';

class SessionSidebarPane extends w.StatefulWidget {
  SessionSidebarPane({required this.model, super.key});

  final ChatModel model;

  @override
  w.State createState() => _SessionSidebarPaneState();
}

class _SessionSidebarPaneState extends w.State<SessionSidebarPane> {
  late SidebarState _state;

  @override
  void initState() {
    super.initState();
    _state = _copySidebarState(widget.model.sidebar);
  }

  @override
  tui.Cmd? didUpdateWidget(covariant SessionSidebarPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      _state = _copySidebarState(widget.model.sidebar);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return SidebarWidget(
      model: widget.model,
      sidebarState: _state,
      onToggleMcp: () {
        setState(() => _state.mcpExpanded = !_state.mcpExpanded);
      },
      onToggleLsp: () {
        setState(() => _state.lspExpanded = !_state.lspExpanded);
      },
      onToggleTodo: () {
        setState(() => _state.todoExpanded = !_state.todoExpanded);
      },
      onToggleFiles: () {
        setState(() => _state.filesExpanded = !_state.filesExpanded);
      },
    );
  }
}

SidebarState _copySidebarState(SidebarState source) {
  final state = SidebarState();
  state.mcpExpanded = source.mcpExpanded;
  state.lspExpanded = source.lspExpanded;
  state.todoExpanded = source.todoExpanded;
  state.filesExpanded = source.filesExpanded;
  return state;
}
