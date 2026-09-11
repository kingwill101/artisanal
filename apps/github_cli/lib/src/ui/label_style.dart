import 'package:artisanal/style.dart' show BasicColor, Color, Colors;

import '../models/repository_label.dart';

Color labelBackgroundColor(
  GithubRepositoryLabel label, {
  Color fallback = Colors.cyan,
}) {
  final value = label.color.trim();
  return value.isEmpty ? fallback : BasicColor(value);
}

Color labelForegroundColor(GithubRepositoryLabel label) {
  final value = label.color.trim().replaceFirst('#', '');
  if (value.length != 6) return Colors.black;

  final red = int.tryParse(value.substring(0, 2), radix: 16);
  final green = int.tryParse(value.substring(2, 4), radix: 16);
  final blue = int.tryParse(value.substring(4, 6), radix: 16);
  if (red == null || green == null || blue == null) return Colors.black;

  final luminance = (0.299 * red + 0.587 * green + 0.114 * blue) / 255;
  return luminance > 0.58 ? Colors.black : Colors.white;
}
