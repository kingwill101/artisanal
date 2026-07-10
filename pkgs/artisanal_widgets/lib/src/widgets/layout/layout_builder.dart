
// ignore_for_file: unused_shown_name
import 'geometry.dart';
import '../core/framework.dart'
    show BuildContext, StatelessWidget, StatefulWidget, State;
import '../core/widget.dart';
import '../media/media_query.dart' show MediaQuery;

/// A widget that provides its parent's constraints to a builder callback.
///
/// Use [LayoutBuilder] to build widget trees that depend on the available
/// space. The [builder] receives the [BoxConstraints] from the nearest
/// [MediaQuery] ancestor (falling back to unconstrained if none exists).
///
/// This is useful for responsive terminal UIs that adapt their layout
/// based on the terminal size.
///
/// ```dart
/// LayoutBuilder(
///   builder: (context, constraints) {
///     final theme = ThemeScope.of(context);
///     if (constraints.maxWidth > 80) {
///       return Row(children: [sidebar, content]);
///     }
///     return Column(children: [sidebar, content]);
///   },
/// )
/// ```
class LayoutBuilder extends StatelessWidget {
  LayoutBuilder({required this.builder, super.key});

  /// Called to build the widget tree with the available constraints.
  ///
  /// The constraints are derived from the nearest [MediaQuery] ancestor,
  /// providing the terminal width and height as max constraints.
  final Widget Function(BuildContext context, BoxConstraints constraints)
  builder;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final constraints = mediaQuery != null
        ? BoxConstraints(
            maxWidth: mediaQuery.width,
            maxHeight: mediaQuery.height,
          )
        : BoxConstraints();
    return builder(context, constraints);
  }
}
