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
    _state = widget.model.sidebar.copyWith();
  }

  @override
  tui.Cmd? didUpdateWidget(covariant SessionSidebarPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      _state = widget.model.sidebar.copyWith();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return SidebarWidget(
      model: widget.model,
      sidebarState: _state,
      onToggleMcp: () {
        setState(() {
          _state.copyWith(mcpExpanded: !_state.mcpExpanded);
        });
      },
      onToggleLsp: () {
        setState(() {
          _state.copyWith(lspExpanded: !_state.lspExpanded);
        });
      },
      onToggleTodo: () {
        setState(() {
          _state.copyWith(todoExpanded: !_state.todoExpanded);
        });
      },
      onToggleFiles: () {
        setState(() {
          _state.copyWith(filesExpanded: !_state.filesExpanded);
        });
      },
    );
  }
}
