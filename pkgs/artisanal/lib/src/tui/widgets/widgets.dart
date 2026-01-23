/// Widget system for composable TUI components.
///
/// This library provides a widget abstraction built on top of the Model pattern
/// with automatic message forwarding, theming, and layout primitives.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisanal/tui.dart';
///
/// class MyApp extends Widget {
///   @override
///   String get id => 'app';
///
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
library;

export 'widget.dart';
export 'theme.dart';
export 'layout_widgets.dart';
