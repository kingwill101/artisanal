class Alignment {
  const Alignment(this.x, this.y);

  final double x;
  final double y;

  static const Alignment center = Alignment(0, 0);
  static const Alignment centerLeft = Alignment(-1, 0);
  static const Alignment centerRight = Alignment(1, 0);
  static const Alignment topLeft = Alignment(-1, -1);
  static const Alignment topCenter = Alignment(0, -1);
  static const Alignment topRight = Alignment(1, -1);
  static const Alignment bottomLeft = Alignment(-1, 1);
  static const Alignment bottomCenter = Alignment(0, 1);
  static const Alignment bottomRight = Alignment(1, 1);
}

class EdgeInsets {
  const EdgeInsets.all(num value)
    : top = value,
      right = value,
      bottom = value,
      left = value;

  const EdgeInsets.symmetric({num vertical = 0, num horizontal = 0})
    : top = vertical,
      right = horizontal,
      bottom = vertical,
      left = horizontal;

  const EdgeInsets.only({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  static const EdgeInsets zero = EdgeInsets.all(0);

  final num top;
  final num right;
  final num bottom;
  final num left;

  EdgeInsets copyWith({num? top, num? right, num? bottom, num? left}) {
    return EdgeInsets.only(
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
    );
  }

  EdgeInsets operator +(EdgeInsets other) => EdgeInsets.only(
    top: top + other.top,
    right: right + other.right,
    bottom: bottom + other.bottom,
    left: left + other.left,
  );

  EdgeInsets operator -(EdgeInsets other) => EdgeInsets.only(
    top: top - other.top,
    right: right - other.right,
    bottom: bottom - other.bottom,
    left: left - other.left,
  );

  bool get isZero => top == 0 && right == 0 && bottom == 0 && left == 0;
}
