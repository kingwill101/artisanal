part of 'layout_widgets.dart';

/// A widget that delegates its build to a callback.
///
/// Useful for obtaining a [BuildContext] inline or building widget trees
/// without creating a dedicated [StatelessWidget] subclass.
///
/// ```dart
/// Builder(
///   builder: (context) {
///     final theme = ThemeScope.of(context);
///     return Text('Hello', style: theme.titleLarge);
///   },
/// )
/// ```
class Builder extends StatelessWidget {
  Builder({required this.builder, super.key});

  /// Called to build the widget tree.
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) => builder(context);
}
