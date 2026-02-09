import 'dart:typed_data';

import 'package:nocterm/src/style.dart';

/// Color quantizer using the median-cut algorithm.
///
/// Reduces the number of colors in an image to a limited palette,
/// which is required for Sixel encoding (max 256 colors).
///
/// The median-cut algorithm works by:
/// 1. Placing all unique colors in a single "box" in RGB color space
/// 2. Finding the box with the largest color range (or most pixels)
/// 3. Splitting it along its longest axis (R, G, or B) at the median
/// 4. Repeating until the desired number of boxes is reached
/// 5. Averaging colors in each box to create palette entries
/// 6. Mapping each pixel to its nearest palette color
class ColorQuantizer {
  /// Quantizes an image to a limited color palette.
  ///
  /// Parameters:
  /// - [rgbaPixels]: RGBA pixel data (4 bytes per pixel, row-major order)
  /// - [width]: Image width in pixels
  /// - [height]: Image height in pixels
  /// - [maxColors]: Maximum number of colors in palette (1-256, default 256)
  ///
  /// Returns a record containing:
  /// - `palette`: List of up to [maxColors] Color objects
  /// - `indexedPixels`: Uint8List where each byte is the palette index for that pixel
  ///
  /// Throws [ArgumentError] if:
  /// - [maxColors] is not between 1 and 256
  /// - [rgbaPixels] length doesn't match width * height * 4
  static (List<Color> palette, Uint8List indexedPixels) quantize({
    required Uint8List rgbaPixels,
    required int width,
    required int height,
    int maxColors = 256,
  }) {
    if (maxColors < 1 || maxColors > 256) {
      throw ArgumentError('maxColors must be between 1 and 256');
    }

    final pixelCount = width * height;
    if (rgbaPixels.length != pixelCount * 4) {
      throw ArgumentError(
        'rgbaPixels length (${rgbaPixels.length}) must be '
        'width * height * 4 ($width * $height * 4 = ${pixelCount * 4})',
      );
    }

    // Build map of unique colors to pixel indices
    final colorMap = <int, List<int>>{}; // RGB packed -> pixel indices

    for (int i = 0; i < pixelCount; i++) {
      final offset = i * 4;
      final r = rgbaPixels[offset];
      final g = rgbaPixels[offset + 1];
      final b = rgbaPixels[offset + 2];
      final a = rgbaPixels[offset + 3];

      // Skip fully transparent pixels
      if (a == 0) continue;

      final packed = _packRgb(r, g, b);
      (colorMap[packed] ??= []).add(i);
    }

    // Handle empty or nearly empty images
    if (colorMap.isEmpty) {
      return ([Colors.black], Uint8List(pixelCount));
    }

    // If we have fewer unique colors than maxColors, use them directly
    if (colorMap.length <= maxColors) {
      return _buildDirectPalette(colorMap, pixelCount);
    }

    // Apply median-cut algorithm
    final boxes = _medianCut(colorMap, maxColors);

    // Build palette from box averages
    final palette = <Color>[];
    final colorToPaletteIndex = <int, int>{};

    for (final box in boxes) {
      final avgColor = _averageColor(box);
      final paletteIndex = palette.length;
      palette.add(Color.fromRGB(
        _unpackR(avgColor),
        _unpackG(avgColor),
        _unpackB(avgColor),
      ));

      // Map all colors in this box to this palette index
      for (final color in box.keys) {
        colorToPaletteIndex[color] = paletteIndex;
      }
    }

    // Build indexed pixel array
    final indexedPixels = Uint8List(pixelCount);
    for (int i = 0; i < pixelCount; i++) {
      final offset = i * 4;
      final a = rgbaPixels[offset + 3];

      if (a == 0) {
        // Transparent pixel - map to first palette color
        indexedPixels[i] = 0;
        continue;
      }

      final r = rgbaPixels[offset];
      final g = rgbaPixels[offset + 1];
      final b = rgbaPixels[offset + 2];
      final packed = _packRgb(r, g, b);

      indexedPixels[i] = colorToPaletteIndex[packed] ?? 0;
    }

    return (palette, indexedPixels);
  }

  /// Finds the closest color in the palette to the given RGB values.
  ///
  /// Uses Euclidean distance in RGB space.
  static int findClosestPaletteIndex(
    int r,
    int g,
    int b,
    List<Color> palette,
  ) {
    int bestIndex = 0;
    int bestDistance = 0x7FFFFFFF; // Max int

    for (int i = 0; i < palette.length; i++) {
      final color = palette[i];
      final dr = r - color.red;
      final dg = g - color.green;
      final db = b - color.blue;
      final distance = dr * dr + dg * dg + db * db;

      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }

      if (distance == 0) break; // Exact match
    }

    return bestIndex;
  }

  // ============ Private helper methods ============

  /// Packs RGB values into a single integer.
  static int _packRgb(int r, int g, int b) => (r << 16) | (g << 8) | b;

  /// Unpacks red component from packed RGB.
  static int _unpackR(int packed) => (packed >> 16) & 0xFF;

  /// Unpacks green component from packed RGB.
  static int _unpackG(int packed) => (packed >> 8) & 0xFF;

  /// Unpacks blue component from packed RGB.
  static int _unpackB(int packed) => packed & 0xFF;

  /// Builds palette directly when unique colors <= maxColors.
  static (List<Color>, Uint8List) _buildDirectPalette(
    Map<int, List<int>> colorMap,
    int pixelCount,
  ) {
    final palette = <Color>[];
    final indexedPixels = Uint8List(pixelCount);
    final colorToIndex = <int, int>{};

    for (final entry in colorMap.entries) {
      final packed = entry.key;
      final paletteIndex = palette.length;

      palette.add(Color.fromRGB(
        _unpackR(packed),
        _unpackG(packed),
        _unpackB(packed),
      ));

      colorToIndex[packed] = paletteIndex;

      for (final pixelIndex in entry.value) {
        indexedPixels[pixelIndex] = paletteIndex;
      }
    }

    return (palette, indexedPixels);
  }

  /// Performs median-cut color quantization.
  ///
  /// Splits color space recursively until we have [targetCount] boxes.
  static List<Map<int, List<int>>> _medianCut(
    Map<int, List<int>> colorMap,
    int targetCount,
  ) {
    var boxes = [colorMap];

    while (boxes.length < targetCount) {
      // Find box with largest range (weighted by pixel count)
      int bestBoxIndex = 0;
      int bestScore = 0;

      for (int i = 0; i < boxes.length; i++) {
        final box = boxes[i];
        if (box.length < 2) continue; // Can't split a box with < 2 colors

        final range = _getColorRange(box);
        final pixelCount =
            box.values.fold<int>(0, (sum, list) => sum + list.length);
        final score = range * pixelCount;

        if (score > bestScore) {
          bestScore = score;
          bestBoxIndex = i;
        }
      }

      if (bestScore == 0) break; // No more splits possible

      // Split the best box
      final boxToSplit = boxes.removeAt(bestBoxIndex);
      final (box1, box2) = _splitBox(boxToSplit);

      if (box1.isNotEmpty) boxes.add(box1);
      if (box2.isNotEmpty) boxes.add(box2);
    }

    return boxes;
  }

  /// Gets the maximum color range across R, G, B channels.
  static int _getColorRange(Map<int, List<int>> box) {
    int minR = 255, maxR = 0;
    int minG = 255, maxG = 0;
    int minB = 255, maxB = 0;

    for (final color in box.keys) {
      final r = _unpackR(color);
      final g = _unpackG(color);
      final b = _unpackB(color);

      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      if (g < minG) minG = g;
      if (g > maxG) maxG = g;
      if (b < minB) minB = b;
      if (b > maxB) maxB = b;
    }

    final rangeR = maxR - minR;
    final rangeG = maxG - minG;
    final rangeB = maxB - minB;

    return rangeR > rangeG
        ? (rangeR > rangeB ? rangeR : rangeB)
        : (rangeG > rangeB ? rangeG : rangeB);
  }

  /// Splits a color box along its longest axis at the median.
  static (Map<int, List<int>>, Map<int, List<int>>) _splitBox(
    Map<int, List<int>> box,
  ) {
    // Find the channel with the largest range
    int minR = 255, maxR = 0;
    int minG = 255, maxG = 0;
    int minB = 255, maxB = 0;

    for (final color in box.keys) {
      final r = _unpackR(color);
      final g = _unpackG(color);
      final b = _unpackB(color);

      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      if (g < minG) minG = g;
      if (g > maxG) maxG = g;
      if (b < minB) minB = b;
      if (b > maxB) maxB = b;
    }

    final rangeR = maxR - minR;
    final rangeG = maxG - minG;
    final rangeB = maxB - minB;

    // Determine split channel (0=R, 1=G, 2=B)
    final int splitChannel;
    if (rangeR >= rangeG && rangeR >= rangeB) {
      splitChannel = 0; // Red
    } else if (rangeG >= rangeB) {
      splitChannel = 1; // Green
    } else {
      splitChannel = 2; // Blue
    }

    // Sort colors by the split channel
    final sortedColors = box.entries.toList()
      ..sort((a, b) {
        final colorA = a.key;
        final colorB = b.key;
        final int valA, valB;

        switch (splitChannel) {
          case 0:
            valA = _unpackR(colorA);
            valB = _unpackR(colorB);
          case 1:
            valA = _unpackG(colorA);
            valB = _unpackG(colorB);
          default:
            valA = _unpackB(colorA);
            valB = _unpackB(colorB);
        }

        return valA.compareTo(valB);
      });

    // Split at median (by pixel count, not color count)
    int totalPixels = 0;
    for (final entry in sortedColors) {
      totalPixels += entry.value.length;
    }

    final halfPixels = totalPixels ~/ 2;
    int runningCount = 0;
    int splitIndex = sortedColors.length ~/ 2; // Default to middle

    for (int i = 0; i < sortedColors.length; i++) {
      runningCount += sortedColors[i].value.length;
      if (runningCount >= halfPixels) {
        splitIndex = i + 1;
        break;
      }
    }

    // Ensure we actually split
    if (splitIndex == 0) splitIndex = 1;
    if (splitIndex >= sortedColors.length) splitIndex = sortedColors.length - 1;

    // Create two new boxes
    final box1 = <int, List<int>>{};
    final box2 = <int, List<int>>{};

    for (int i = 0; i < sortedColors.length; i++) {
      if (i < splitIndex) {
        box1[sortedColors[i].key] = sortedColors[i].value;
      } else {
        box2[sortedColors[i].key] = sortedColors[i].value;
      }
    }

    return (box1, box2);
  }

  /// Computes the average color of a box, weighted by pixel count.
  static int _averageColor(Map<int, List<int>> box) {
    int totalR = 0, totalG = 0, totalB = 0;
    int totalPixels = 0;

    for (final entry in box.entries) {
      final color = entry.key;
      final count = entry.value.length;

      totalR += _unpackR(color) * count;
      totalG += _unpackG(color) * count;
      totalB += _unpackB(color) * count;
      totalPixels += count;
    }

    if (totalPixels == 0) return 0;

    final avgR = (totalR / totalPixels).round();
    final avgG = (totalG / totalPixels).round();
    final avgB = (totalB / totalPixels).round();

    return _packRgb(avgR, avgG, avgB);
  }
}
