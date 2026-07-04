/// InheritedWidget provider for [OpenCodeUIState].
library;

import 'package:artisanal_widgets/widgets.dart' as w;

import 'open_code_ui_state.dart';

class OpenCodeUIStateInherited extends w.InheritedWidget {
  OpenCodeUIStateInherited({
    required this.uiState,
    required super.child,
    super.key,
  });

  final OpenCodeUIState uiState;

  static OpenCodeUIState of(w.BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<OpenCodeUIStateInherited>()!
        .uiState;
  }

  @override
  bool updateShouldNotify(covariant OpenCodeUIStateInherited oldWidget) {
    return uiState != oldWidget.uiState;
  }
}
