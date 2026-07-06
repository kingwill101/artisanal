/// Navigation system for artisanal_widgets.
///
/// Provides a Flutter-like navigator with route stack management,
/// named routing, modal dialogs, and keyboard-triggered pop behavior.
///
/// ## Quick Start
///
/// ```dart
/// // Create a navigator with a home screen
/// Navigator(
///   home: HomeScreen(),
/// )
///
/// // Push a new route from within a widget
/// Navigator.of(context).push(PageRoute(
///   builder: (context) => DetailScreen(),
/// ));
///
/// // Pop back
/// Navigator.of(context).pop();
/// ```
library;

export 'animation_style.dart';
export 'dialog_route.dart' show DialogRoute, showDialog;
export 'navigator.dart';
export 'navigator_observer.dart';
export 'pop_behavior.dart';
export 'route.dart';
export 'route_settings.dart';
