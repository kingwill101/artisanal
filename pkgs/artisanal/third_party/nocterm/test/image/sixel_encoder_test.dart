import 'dart:typed_data';

import 'package:nocterm/src/image/sixel_encoder.dart';
import 'package:nocterm/src/image/color_quantizer.dart';
import 'package:nocterm/src/style.dart';
import 'package:test/test.dart';

void main() {
  group('SixelEncoder', () {
    test('encodes simple 1x6 single color image', () {
      // Create a simple 1x6 red image (one sixel column)
      final pixels = Uint8List(1 * 6 * 4);
      for (int i = 0; i < 6; i++) {
        pixels[i * 4] = 255; // R
        pixels[i * 4 + 1] = 0; // G
        pixels[i * 4 + 2] = 0; // B
        pixels[i * 4 + 3] = 255; // A
      }

      final palette = [const Color.fromRGB(255, 0, 0)];
      final indexedPixels = Uint8List(6)..fillRange(0, 6, 0);

      final sixel = SixelEncoder.encode(
        pixels: pixels,
        width: 1,
        height: 6,
        palette: palette,
        indexedPixels: indexedPixels,
      );

      // Should start with DCS and end with ST
      expect(sixel, startsWith('\x1bPq'));
      expect(sixel, endsWith('\x1b\\'));

      // Should contain color definition (red = 100% red, 0% green, 0% blue)
      expect(sixel, contains('#0;2;100;0;0'));

      // Should contain sixel data - all 6 bits set = 63 + 63 = 126 = '~'
      expect(sixel, contains('~'));
    });

    test('encodes 2x6 two-color image', () {
      // Create a 2x6 image: column 0 is red, column 1 is blue
      final pixels = Uint8List(2 * 6 * 4);
      for (int y = 0; y < 6; y++) {
        // Red pixel at x=0
        pixels[(y * 2 + 0) * 4] = 255;
        pixels[(y * 2 + 0) * 4 + 1] = 0;
        pixels[(y * 2 + 0) * 4 + 2] = 0;
        pixels[(y * 2 + 0) * 4 + 3] = 255;

        // Blue pixel at x=1
        pixels[(y * 2 + 1) * 4] = 0;
        pixels[(y * 2 + 1) * 4 + 1] = 0;
        pixels[(y * 2 + 1) * 4 + 2] = 255;
        pixels[(y * 2 + 1) * 4 + 3] = 255;
      }

      final palette = [
        const Color.fromRGB(255, 0, 0), // Red
        const Color.fromRGB(0, 0, 255), // Blue
      ];
      final indexedPixels = Uint8List(12);
      for (int y = 0; y < 6; y++) {
        indexedPixels[y * 2 + 0] = 0; // Red
        indexedPixels[y * 2 + 1] = 1; // Blue
      }

      final sixel = SixelEncoder.encode(
        pixels: pixels,
        width: 2,
        height: 6,
        palette: palette,
        indexedPixels: indexedPixels,
      );

      // Should contain both color definitions
      expect(sixel, contains('#0;2;100;0;0')); // Red
      expect(sixel, contains('#1;2;0;0;100')); // Blue
    });

    test('handles empty image', () {
      final sixel = SixelEncoder.encode(
        pixels: Uint8List(0),
        width: 0,
        height: 0,
        palette: [],
        indexedPixels: Uint8List(0),
      );

      expect(sixel, isEmpty);
    });

    test('applies RLE compression for repeated characters', () {
      // Create a 10x6 single color image - should trigger RLE
      final width = 10;
      final height = 6;
      final pixels = Uint8List(width * height * 4);
      for (int i = 0; i < width * height; i++) {
        pixels[i * 4] = 128;
        pixels[i * 4 + 1] = 128;
        pixels[i * 4 + 2] = 128;
        pixels[i * 4 + 3] = 255;
      }

      final palette = [const Color.fromRGB(128, 128, 128)];
      final indexedPixels = Uint8List(width * height)
        ..fillRange(0, width * height, 0);

      final sixel = SixelEncoder.encode(
        pixels: pixels,
        width: width,
        height: height,
        palette: palette,
        indexedPixels: indexedPixels,
      );

      // Should contain RLE: !10~ (repeat '~' 10 times)
      expect(sixel, contains('!10'));
    });

    test('encodeRgba convenience method works', () {
      // Create a simple 4x4 gradient image
      final width = 4;
      final height = 4;
      final pixels = Uint8List(width * height * 4);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final i = (y * width + x) * 4;
          pixels[i] = (x * 85).clamp(0, 255); // R gradient
          pixels[i + 1] = (y * 85).clamp(0, 255); // G gradient
          pixels[i + 2] = 128; // B constant
          pixels[i + 3] = 255; // A
        }
      }

      final sixel = SixelEncoder.encodeRgba(
        rgbaPixels: pixels,
        width: width,
        height: height,
        maxColors: 16,
      );

      expect(sixel, startsWith('\x1bPq'));
      expect(sixel, endsWith('\x1b\\'));
    });

    test('handles multi-band images (height > 6)', () {
      // Create a 2x12 image (2 bands of 6 rows each)
      final width = 2;
      final height = 12;
      final pixels = Uint8List(width * height * 4);
      for (int i = 0; i < width * height; i++) {
        pixels[i * 4] = 200;
        pixels[i * 4 + 1] = 100;
        pixels[i * 4 + 2] = 50;
        pixels[i * 4 + 3] = 255;
      }

      final palette = [const Color.fromRGB(200, 100, 50)];
      final indexedPixels = Uint8List(width * height)
        ..fillRange(0, width * height, 0);

      final sixel = SixelEncoder.encode(
        pixels: pixels,
        width: width,
        height: height,
        palette: palette,
        indexedPixels: indexedPixels,
      );

      // Should contain band separator '-'
      expect(sixel, contains('-'));
    });
  });

  group('ColorQuantizer', () {
    test('quantizes single color image to single palette entry', () {
      final width = 4;
      final height = 4;
      final pixels = Uint8List(width * height * 4);

      // Fill with solid red
      for (int i = 0; i < width * height; i++) {
        pixels[i * 4] = 255;
        pixels[i * 4 + 1] = 0;
        pixels[i * 4 + 2] = 0;
        pixels[i * 4 + 3] = 255;
      }

      final (palette, indexed) = ColorQuantizer.quantize(
        rgbaPixels: pixels,
        width: width,
        height: height,
        maxColors: 256,
      );

      expect(palette.length, equals(1));
      expect(palette[0].red, equals(255));
      expect(palette[0].green, equals(0));
      expect(palette[0].blue, equals(0));

      // All pixels should map to index 0
      expect(indexed.every((i) => i == 0), isTrue);
    });

    test('quantizes gradient to multiple palette entries', () {
      final width = 256;
      final height = 1;
      final pixels = Uint8List(width * height * 4);

      // Create red gradient
      for (int x = 0; x < width; x++) {
        pixels[x * 4] = x; // R gradient 0-255
        pixels[x * 4 + 1] = 0;
        pixels[x * 4 + 2] = 0;
        pixels[x * 4 + 3] = 255;
      }

      final (palette, indexed) = ColorQuantizer.quantize(
        rgbaPixels: pixels,
        width: width,
        height: height,
        maxColors: 16,
      );

      expect(palette.length, lessThanOrEqualTo(16));
      expect(palette.length, greaterThan(1));
      expect(indexed.length, equals(width * height));
    });

    test('respects maxColors limit', () {
      final width = 10;
      final height = 10;
      final pixels = Uint8List(width * height * 4);

      // Create many different colors
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final i = (y * width + x) * 4;
          pixels[i] = (x * 25) % 256;
          pixels[i + 1] = (y * 25) % 256;
          pixels[i + 2] = ((x + y) * 12) % 256;
          pixels[i + 3] = 255;
        }
      }

      final (palette, _) = ColorQuantizer.quantize(
        rgbaPixels: pixels,
        width: width,
        height: height,
        maxColors: 8,
      );

      expect(palette.length, lessThanOrEqualTo(8));
    });

    test('handles transparent pixels', () {
      final width = 2;
      final height = 2;
      final pixels = Uint8List(width * height * 4);

      // Pixel 0: opaque red
      pixels[0] = 255;
      pixels[1] = 0;
      pixels[2] = 0;
      pixels[3] = 255;

      // Pixel 1: transparent (should be treated as black or ignored)
      pixels[4] = 0;
      pixels[5] = 255;
      pixels[6] = 0;
      pixels[7] = 0; // Alpha = 0

      // Pixel 2: opaque blue
      pixels[8] = 0;
      pixels[9] = 0;
      pixels[10] = 255;
      pixels[11] = 255;

      // Pixel 3: semi-transparent
      pixels[12] = 255;
      pixels[13] = 255;
      pixels[14] = 0;
      pixels[15] = 128;

      final (palette, indexed) = ColorQuantizer.quantize(
        rgbaPixels: pixels,
        width: width,
        height: height,
        maxColors: 256,
      );

      expect(palette.isNotEmpty, isTrue);
      expect(indexed.length, equals(4));
    });
  });
}
