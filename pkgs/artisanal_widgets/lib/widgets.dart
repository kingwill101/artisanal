/// Stable high-level widget framework for building terminal UIs.
///
/// Prefer this library when you want the supported widget surface:
/// app shells, runners, themes, layout/input primitives, scrolling,
/// navigation, animations, and the higher-level component set.
///
/// Additional stable entrypoints are available for focused modules:
///
/// - `package:artisanal_widgets/charting.dart`
/// - `package:artisanal_widgets/selection.dart`
/// - `package:artisanal_widgets/testing.dart`
///
/// The legacy `package:artisanal_widgets/artisanal_widgets.dart` entrypoint
/// remains available for backward compatibility and still exposes additional
/// experimental internals and modules.
library;

export 'src/widgets/core/key.dart';
export 'src/widgets/core/widget.dart';
export 'src/widgets/core/framework.dart' hide StateSetter;
export 'src/widgets/focus/focus.dart';
export 'src/widgets/app/widget_app.dart';
export 'src/widgets/app/artisanal_app.dart';
export 'src/widgets/app/run_app.dart';
export 'src/widgets/app/reload.dart';
export 'src/widgets/app/render_metrics_provider.dart';
export 'src/widgets/media/media_query.dart';
export 'src/widgets/theme/theme.dart';
export 'src/widgets/theme/theme_scope.dart';
export 'src/widgets/theme/opencode_themes.dart';
export 'src/widgets/gestures/gestures.dart';
export 'src/widgets/layout/geometry.dart';
export 'src/widgets/layout/layout_widgets.dart';
export 'src/widgets/layout/keyboard_listener.dart';
export 'src/widgets/layout/block_focus.dart';
export 'src/widgets/plugins/slots.dart';
export 'src/widgets/components/components_widgets.dart';
export 'src/widgets/components/overlay.dart';
export 'package:artisanal/runtime.dart' show ZoneInBoundsMsg;
export 'package:artisanal/tui.dart' show KeyBinding, KeyMap;
export 'src/widgets/input/input_widgets.dart';
export 'src/widgets/input/text_decoration_binding.dart';
export 'src/widgets/input/text_diagnostics_binding.dart';
export 'src/widgets/input/text_diagnostics_source.dart';
export 'src/widgets/scroll/scroll_widgets.dart';
export 'src/widgets/animation/animations.dart';
export 'src/widgets/navigation/navigation.dart';
