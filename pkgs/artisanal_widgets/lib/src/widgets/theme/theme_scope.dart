library;

import '../core/framework.dart' show BuildContext, InheritedWidget;
import 'theme.dart' show Theme, currentTheme;

/// Provides a theme to descendant widgets via the build context.
class ThemeScope extends InheritedWidget {
  ThemeScope({required this.theme, required super.child, super.key});

  @override
  final Theme theme;

  /// Returns the nearest theme from the context, or the global theme.
  static Theme of(BuildContext context) {
    return maybeOf(context) ?? currentTheme;
  }

  /// Returns the nearest theme from the context, if any.
  static Theme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.theme;
  }

  @override
  bool updateShouldNotify(covariant ThemeScope oldWidget) {
    return theme != oldWidget.theme;
  }
}

/// Convenience accessors for theme lookup on BuildContext.
extension ThemeContext on BuildContext {
  /// Returns the nearest theme from context, or the global theme.
  Theme get theme => ThemeScope.of(this);

  /// Returns the nearest theme from context, if any.
  Theme? get maybeTheme => ThemeScope.maybeOf(this);
}
