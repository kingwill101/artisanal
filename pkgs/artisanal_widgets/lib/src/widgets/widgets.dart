/// Widget system for composable TUI components.
///
/// This library provides a widget abstraction built on top of the Model pattern
/// with automatic message forwarding, theming, and layout primitives.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisanal_widgets/artisanal_widgets.dart';
///
/// class MyApp extends Widget {
///   @override
///   Object view() {
///     return Column(
///       gap: 1,
///       children: [
///         Text('Hello', style: theme.titleLarge),
///         Row(
///           gap: 2,
///           children: [
///             Text('Left'),
///             Text('Right'),
///           ],
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// ## Key Concepts
///
/// - **Widget**: Base class that implements Model with auto child forwarding
/// - **Theme**: Global theme with semantic colors and text styles
/// - **Layout Widgets**: Row, Column, Container, Text, Divider, Spacer
///
/// {@category TUI}
@experimental
library;

import 'package:meta/meta.dart' show experimental;

export 'core/key.dart';
export 'core/widget.dart';
export 'core/framework.dart';
export 'core/element.dart';
export 'focus/focus.dart';
export 'app/widget_app.dart';
export 'app/artisanal_app.dart';
export 'app/run_app.dart';
export 'app/reload.dart';
export 'app/reload_watcher.dart';
export 'app/performance.dart';
export 'app/render_metrics_provider.dart';
export 'rendering/render_object.dart';
export 'rendering/render_layout.dart';
export 'layout/geometry.dart';
export 'media/media_query.dart';
export 'theme/theme.dart';
export 'theme/theme_scope.dart';
export 'theme/opencode_themes.dart';
export 'gestures/gestures.dart';
export 'layout/layout_widgets.dart';
export 'layout/keyboard_listener.dart';
export 'layout/block_focus.dart';
export 'components/components_widgets.dart';
export 'input/input_widgets.dart';
export 'scroll/scroll_widgets.dart';
export 'animation/animations.dart';
export 'components/overlay.dart';
export 'navigation/navigation.dart';
export 'selection/selection_widgets.dart';
export 'charting/chart_widgets.dart';
