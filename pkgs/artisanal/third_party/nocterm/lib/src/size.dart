class Size {
  const Size(this.width, this.height);

  final double width;
  final double height;

  static const Size zero = Size(0, 0);
  static const Size infinite = Size(double.infinity, double.infinity);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Size && other.width == width && other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'Size($width, $height)';
}
