@experimental
library;

import 'package:meta/meta.dart' show experimental;

import '../core/framework.dart' show BuildContext, InheritedWidget;
import '../layout/geometry.dart' show Size;

class MediaQueryData {
  const MediaQueryData({required this.size});

  static const zero = MediaQueryData(size: Size.zero);

  final Size size;

  double get width => size.width;
  double get height => size.height;

  MediaQueryData copyWith({Size? size}) {
    return MediaQueryData(size: size ?? this.size);
  }

  @override
  bool operator ==(Object other) =>
      other is MediaQueryData &&
      other.size.width == size.width &&
      other.size.height == size.height;

  @override
  int get hashCode => Object.hash(size.width, size.height);

  @override
  String toString() => 'MediaQueryData(size: ${size.width}x${size.height})';
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

  @override
  bool updateShouldNotify(covariant MediaQuery oldWidget) {
    return oldWidget.data != data;
  }
}
