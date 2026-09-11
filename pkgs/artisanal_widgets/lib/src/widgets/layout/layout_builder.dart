import 'geometry.dart';
import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../core/widget.dart';
import '../media/media_query.dart' show MediaQuery;

/// A widget that provides viewport constraints to a builder callback.
///
/// Use [LayoutBuilder] to build widget trees that depend on the terminal
/// viewport. The [builder] receives the [BoxConstraints] from the nearest
/// [MediaQuery] ancestor (falling back to unconstrained if none exists).
/// These are not the containing render object's constraints: a narrower
/// parent does not change the values delivered to this builder.
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
