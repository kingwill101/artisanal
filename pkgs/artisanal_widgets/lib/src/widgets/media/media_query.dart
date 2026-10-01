library;

import '../core/framework.dart'
    show BuildContext, InheritedWidget, StatelessWidget;
import '../layout/geometry.dart' show Size;
import '../core/widget.dart' show Widget;

class MediaQueryData {
  const MediaQueryData({required this.size, this.disableAnimations = false});

  static const zero = MediaQueryData(size: Size.zero);

  final Size size;

  /// Whether decorative motion should be reduced for this subtree.
  final bool disableAnimations;

  double get width => size.width;
  double get height => size.height;

  MediaQueryData copyWith({Size? size, bool? disableAnimations}) {
    return MediaQueryData(
      size: size ?? this.size,
      disableAnimations: disableAnimations ?? this.disableAnimations,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MediaQueryData &&
      other.size.width == size.width &&
      other.size.height == size.height &&
      other.disableAnimations == disableAnimations;

  @override
  int get hashCode => Object.hash(size.width, size.height, disableAnimations);

  @override
  String toString() =>
      'MediaQueryData(size: ${size.width}x${size.height}, '
      'disableAnimations: $disableAnimations)';
}

class MediaQuery extends InheritedWidget {
  MediaQuery({required this.data, required super.child, super.key});

  final MediaQueryData data;

  static MediaQueryData of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<MediaQuery>();
    if (widget == null) {
      throw StateError('MediaQuery.of() called with no MediaQuery ancestor.');
    }
    return widget.data;
  }

  static MediaQueryData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MediaQuery>()?.data;
  }

  /// Whether decorative motion is disabled for the nearest media scope.
  ///
  /// Returns `false` when no [MediaQuery] is present.
  static bool disableAnimationsOf(BuildContext context) =>
      (_MotionPolicyScope.maybeOf(context) ?? false) ||
      (maybeOf(context)?.disableAnimations ?? false);

  @override
  bool updateShouldNotify(covariant MediaQuery oldWidget) {
    return oldWidget.data != data;
  }
}

/// Applies an app-level animation preference without overriding an ancestor's
/// reduced-motion request.
///
/// This scope can further reduce motion when [enabled] is `false`. An ancestor
/// that already disables animations remains authoritative when [enabled] is
/// `true`, allowing applications to preserve system accessibility preferences.
class MotionScope extends StatelessWidget {
  /// Creates a scope that combines [enabled] with the nearest media policy.
  MotionScope({required this.enabled, required this.child, super.key});

  /// Whether the application allows decorative animations in this subtree.
  final bool enabled;

  /// The widgets that inherit the resulting motion policy.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _MotionPolicyScope(
      disableAnimations: MediaQuery.disableAnimationsOf(context) || !enabled,
      child: child,
    );
  }
}

class _MotionPolicyScope extends InheritedWidget {
  _MotionPolicyScope({required this.disableAnimations, required super.child});

  final bool disableAnimations;

  static bool? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_MotionPolicyScope>()
      ?.disableAnimations;

  @override
  bool updateShouldNotify(_MotionPolicyScope oldWidget) =>
      oldWidget.disableAnimations != disableAnimations;
}
