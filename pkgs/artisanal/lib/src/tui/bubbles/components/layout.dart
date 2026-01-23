import 'base.dart';

/// A component that composes multiple child components.
class CompositeComponent extends DisplayComponent {
  const CompositeComponent({required this.children});

  final List<DisplayComponent> children;

  @override
  String render() {
    final buffer = StringBuffer();
    for (final child in children) {
      buffer.write(child.render());
    }
    return buffer.toString();
  }
}

/// A component that renders with a newline after each child.
class ColumnComponent extends DisplayComponent {
  const ColumnComponent({required this.children, this.spacing = 0});

  final List<DisplayComponent> children;
  final int spacing;

  @override
  String render() {
    final buffer = StringBuffer();

    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        buffer.writeln();
        for (var s = 0; s < spacing; s++) {
          buffer.writeln();
        }
      }
      buffer.write(children[i].render());
    }

    return buffer.toString();
  }
}

/// A component that renders children horizontally with a separator.
class RowComponent extends DisplayComponent {
  const RowComponent({required this.children, this.separator = ' '});

  final List<DisplayComponent> children;
  final String separator;

  @override
  String render() => children.map((c) => c.render()).join(separator);
}
