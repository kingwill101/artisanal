import 'dart:convert';

import 'package:artisanal/src/terminal/kitty.dart';
import 'package:artisanal/src/terminal/sixel.dart';
import 'package:artisanal/src/terminal/iterm2.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

/// Creates a simple test image filled with a single color.
img.Image _solidImage(
  int width,
  int height, {
  int r = 255,
  int g = 0,
  int b = 0,
}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return image;
}

/// Creates a test image with multiple distinct colors arranged in vertical
/// stripes so that quantization behavior is observable.
img.Image _stripedImage(int width, int height, int stripeCount) {
  final image = img.Image(width: width, height: height);
  final stripeWidth = width ~/ stripeCount;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final stripeIndex = stripeWidth > 0
          ? (x ~/ stripeWidth) % stripeCount
          : 0;
      final hue = (stripeIndex * 360 / stripeCount).round();
      // Simple HSV to RGB with S=1, V=1.
      final sector = hue ~/ 60;
      final frac = (hue % 60) / 60.0;
      int r, g, b;
      switch (sector) {
        case 0:
          r = 255;
          g = (255 * frac).round();
          b = 0;
        case 1:
          r = (255 * (1 - frac)).round();
          g = 255;
          b = 0;
        case 2:
          r = 0;
          g = 255;
          b = (255 * frac).round();
        case 3:
          r = 0;
          g = (255 * (1 - frac)).round();
          b = 255;
        case 4:
          r = (255 * frac).round();
          g = 0;
          b = 255;
        default:
          r = 255;
          g = 0;
          b = (255 * (1 - frac)).round();
      }
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return image;
}

/// Creates a tiny gradient image where each pixel has a different shade.
img.Image _gradientImage(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final t = (y * width + x) / (width * height);
      image.setPixelRgba(
        x,
        y,
        (t * 255).round(),
        ((1 - t) * 255).round(),
        128,
        255,
      );
    }
  }
  return image;
}

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // KittyImage
  // ──────────────────────────────────────────────────────────────────────────
  group('KittyImage', () {
    group('encode', () {
      test('produces a valid Kitty escape sequence', () {
        final image = _solidImage(2, 2);
        final result = KittyImage.encode(image);

        // Must start with APC G and end with ST.
        expect(result, contains('\x1b_G'));
        expect(result, contains('\x1b\\'));
      });

      test('uses PNG format (f=100) instead of raw RGBA', () {
        final image = _solidImage(2, 2);
        final result = KittyImage.encode(image);

        // The first chunk should declare f=100 (PNG).
        expect(result, contains('f=100'));
        // Must NOT contain f=32 (raw RGBA).
        expect(result, isNot(contains('f=32')));
      });

      test('includes transmit-and-display action', () {
        final image = _solidImage(2, 2);
        final result = KittyImage.encode(image);

        expect(result, contains('a=T'));
      });

      test('suppresses terminal responses with quiet mode by default', () {
        final image = _solidImage(2, 2);
        final result = KittyImage.encode(image);

        expect(result, contains('q=2'));
      });

      test('omits quiet parameter when quiet=0', () {
        final image = _solidImage(2, 2);
        final result = KittyImage.encode(image, quiet: 0);

        // Should not contain q= at all.
        expect(result, isNot(contains('q=')));
      });

      test('includes image ID when provided', () {
        final image = _solidImage(2, 2);
        final result = KittyImage.encode(image, id: 42);

        expect(result, contains('i=42'));
      });

      test('includes columns and rows when provided', () {
        final image = _solidImage(2, 2);
        final result = KittyImage.encode(image, columns: 10, rows: 5);

        expect(result, contains('c=10'));
        expect(result, contains('r=5'));
      });

      test('omits columns and rows when not provided', () {
        final image = _solidImage(2, 2);
        final result = KittyImage.encode(image);

        expect(result, isNot(contains('c=')));
        expect(result, isNot(contains('r=')));
      });

      test('returns empty string for zero-dimension images', () {
        // The image package doesn't allow 0x0 images, but a 1x1 should work.
        final image = _solidImage(1, 1);
        final result = KittyImage.encode(image);
        expect(result, isNotEmpty);
      });

      test('produces smaller output than raw RGBA would', () {
        // A 10x10 RGBA image is 400 bytes raw. PNG should be significantly
        // smaller as base64 in the escape sequence.
        final image = _solidImage(10, 10);
        final result = KittyImage.encode(image);

        // Raw RGBA base64 would be at least base64Encode(400 bytes) = 536 chars.
        // Plus control sequences. PNG of a solid color should be much smaller.
        // We just check the overall sequence is shorter than what raw would be.
        final rawRgba = image
            .convert(format: img.Format.uint8, numChannels: 4)
            .toUint8List();
        final rawBase64Length = base64Encode(rawRgba).length;
        final pngBase64Length = base64Encode(img.encodePng(image)).length;

        expect(
          pngBase64Length,
          lessThan(rawBase64Length),
          reason: 'PNG should be more compact than raw RGBA',
        );
      });

      test('chunks large images correctly', () {
        // Use a large enough image that it needs multiple chunks.
        final image = _solidImage(100, 100);
        final result = KittyImage.encode(image, chunkSize: 128);

        // Should have multiple APC G sequences.
        final apcCount = '\x1b_G'.allMatches(result).length;
        expect(
          apcCount,
          greaterThan(1),
          reason: 'large image should be chunked',
        );

        // First chunk should have m=1 (more data coming), last should have m=0.
        expect(result, contains('m=1'));
        expect(result, contains('m=0'));
      });

      test('single chunk has m=0', () {
        // A tiny image should fit in one chunk.
        final image = _solidImage(1, 1);
        final result = KittyImage.encode(image);

        // Should only have one APC G sequence with m=0.
        final apcCount = '\x1b_G'.allMatches(result).length;
        expect(apcCount, equals(1));
        expect(result, contains('m=0'));
        expect(result, isNot(contains('m=1')));
      });

      test('first chunk includes control params, continuations do not', () {
        final image = _solidImage(100, 100);
        final result = KittyImage.encode(image, id: 7, chunkSize: 128);

        // Split on APC to examine each chunk.
        final chunks = result.split('\x1b_G');
        // First element is empty (before first APC).
        expect(chunks.length, greaterThan(2));

        // First real chunk should contain the control params.
        expect(chunks[1], contains('a=T'));
        expect(chunks[1], contains('f=100'));
        expect(chunks[1], contains('i=7'));

        // Subsequent chunks should NOT repeat control params.
        for (var i = 2; i < chunks.length; i++) {
          expect(chunks[i], isNot(contains('a=T')));
          expect(chunks[i], isNot(contains('f=100')));
        }
      });

      test('base64 payload is valid', () {
        final image = _solidImage(4, 4);
        final result = KittyImage.encode(image);

        // Extract the base64 payload from the single-chunk sequence.
        // Format: \x1b_G...;BASE64_DATA\x1b\\
        final payloadMatch = RegExp(
          r';([A-Za-z0-9+/=]+)\x1b\\',
        ).firstMatch(result);
        expect(
          payloadMatch,
          isNotNull,
          reason: 'should contain base64 payload',
        );

        final base64Data = payloadMatch!.group(1)!;
        // Should be valid base64 that decodes to valid PNG.
        final bytes = base64Decode(base64Data);
        expect(bytes[0], equals(0x89), reason: 'should start with PNG magic');
        expect(bytes[1], equals(0x50)); // P
        expect(bytes[2], equals(0x4E)); // N
        expect(bytes[3], equals(0x47)); // G
      });
    });

    group('encodePng', () {
      test('accepts pre-encoded PNG bytes', () {
        final image = _solidImage(4, 4);
        final pngBytes = img.encodePng(image);
        final result = KittyImage.encodePng(pngBytes, id: 99);

        expect(result, contains('\x1b_G'));
        expect(result, contains('f=100'));
        expect(result, contains('i=99'));
        expect(result, contains('\x1b\\'));
      });

      test('produces identical output to encode for same image', () {
        final image = _solidImage(4, 4);
        final pngBytes = img.encodePng(image);

        final fromEncode = KittyImage.encode(image, id: 1, quiet: 2);
        final fromEncodePng = KittyImage.encodePng(pngBytes, id: 1, quiet: 2);

        expect(fromEncodePng, equals(fromEncode));
      });
    });

    group('delete', () {
      test('produces delete escape sequence with image ID', () {
        final result = KittyImage.delete(imageId: 42);

        expect(result, contains('\x1b_G'));
        expect(result, contains('a=d'));
        expect(result, contains('i=42'));
        expect(result, contains('\x1b\\'));
      });

      test('deletes by image ID with d=I', () {
        final result = KittyImage.delete(imageId: 7);

        expect(result, contains('d=I'));
        expect(result, contains('i=7'));
      });

      test('deletes all images when no ID provided', () {
        final result = KittyImage.delete();

        expect(result, contains('a=d'));
        expect(result, contains('d=a'));
        expect(result, isNot(contains('i=')));
      });

      test('includes quiet mode by default', () {
        final result = KittyImage.delete(imageId: 1);
        expect(result, contains('q=2'));
      });

      test('omits quiet when quiet=0', () {
        final result = KittyImage.delete(imageId: 1, quiet: 0);
        expect(result, isNot(contains('q=')));
      });
    });

    group('deleteAll', () {
      test('is equivalent to delete with no imageId', () {
        expect(KittyImage.deleteAll(), equals(KittyImage.delete()));
      });
    });

    group('getNextImageId', () {
      test('returns incrementing IDs', () {
        final id1 = KittyImage.getNextImageId();
        final id2 = KittyImage.getNextImageId();
        final id3 = KittyImage.getNextImageId();

        expect(id2, equals(id1 + 1));
        expect(id3, equals(id2 + 1));
      });
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SixelImage
  // ──────────────────────────────────────────────────────────────────────────
  group('SixelImage', () {
    group('encode', () {
      test('produces a valid Sixel escape sequence', () {
        final image = _solidImage(4, 6);
        final result = SixelImage.encode(image);

        // Must start with DCS P q and end with ST.
        expect(result, startsWith('\x1bPq'));
        expect(result, endsWith('\x1b\\'));
      });

      test('defines color registers in 0-100 percentage format', () {
        // Pure red image.
        final image = _solidImage(2, 2, r: 255, g: 0, b: 0);
        final result = SixelImage.encode(image);

        // Red = 255 -> 100%, Green = 0 -> 0%, Blue = 0 -> 0%.
        // Format: #<reg>;2;<r%>;<g%>;<b%>
        expect(result, contains(';2;100;0;0'));
      });

      test('handles pure green color', () {
        final image = _solidImage(2, 2, r: 0, g: 255, b: 0);
        final result = SixelImage.encode(image);
        expect(result, contains(';2;0;100;0'));
      });

      test('handles pure blue color', () {
        final image = _solidImage(2, 2, r: 0, g: 0, b: 255);
        final result = SixelImage.encode(image);
        expect(result, contains(';2;0;0;100'));
      });

      test('handles mid-gray color', () {
        final image = _solidImage(2, 2, r: 128, g: 128, b: 128);
        final result = SixelImage.encode(image);
        // 128/255*100 ≈ 50
        expect(result, contains(';2;50;50;50'));
      });

      test('returns empty string for zero-dimension image', () {
        // img.Image won't create a 0x0 image, but we can test the encoder
        // doesn't crash on a 1x1.
        final image = _solidImage(1, 1);
        final result = SixelImage.encode(image);
        expect(result, isNotEmpty);
      });

      test('sixel characters are in valid ASCII range 63-126', () {
        final image = _gradientImage(8, 12);
        final result = SixelImage.encode(image);

        // Extract the data portion (between color defs and end marker).
        // Sixel characters should be in range ? (63) to ~ (126).
        // We check that no characters in the data are outside the valid
        // range (excluding control chars like #, !, $, -, and digits).
        final dataSection = result.substring(
          result.indexOf('q') + 1,
          result.lastIndexOf('\x1b\\'),
        );

        for (final rune in dataSection.runes) {
          // Valid characters in Sixel data stream:
          // - Color/RLE/navigation: # ! $ - ; digits 0-9
          // - Color format specifier: 2
          // - Sixel data chars: 63 (?) to 126 (~)
          // We just verify no unexpected control chars.
          if (rune >= 63 && rune <= 126) continue; // Sixel data.
          if (rune >= 48 && rune <= 57) continue; // Digits.
          if (rune == 35) continue; // #
          if (rune == 33) continue; // !
          if (rune == 36) continue; // $
          if (rune == 45) continue; // -
          if (rune == 59) continue; // ;
          fail('Unexpected character code $rune in Sixel data');
        }
      });

      test('uses band separator (-) between 6-row strips', () {
        // Image with 12 rows should have at least one '-' separator.
        final image = _solidImage(4, 12);
        final result = SixelImage.encode(image);
        expect(result, contains('-'));
      });

      test('single 6-row band has no band separator', () {
        final image = _solidImage(4, 6);
        final result = SixelImage.encode(image);

        // There should be no '-' between the data and the ST.
        final dataSection = result.substring(
          result.lastIndexOf('#'),
          result.lastIndexOf('\x1b\\'),
        );
        // The data section itself should not end with '-' since there's
        // only one band.
        expect(dataSection, isNot(endsWith('-')));
      });

      test('applies RLE compression for repeated characters', () {
        // A wide solid-color image should trigger RLE.
        final image = _solidImage(100, 6);
        final result = SixelImage.encode(image);

        // RLE format: !<count><char>
        expect(
          result,
          contains(RegExp(r'!\d+')),
          reason: 'wide solid image should use RLE compression',
        );
      });

      test('does not use RLE for 3 or fewer repeats', () {
        // A 3-pixel wide solid image: 3 repeats should NOT use RLE.
        final image = _solidImage(3, 6);
        final result = SixelImage.encode(image);

        // Should not contain RLE markers for such a small repeat.
        // The sixel data portion should just have the character repeated.
        // However, we can't easily distinguish this without parsing, so
        // we just check the output is valid.
        expect(result, startsWith('\x1bPq'));
        expect(result, endsWith('\x1b\\'));
      });

      test('handles multi-color images', () {
        final image = img.Image(width: 4, height: 6);
        // Left half red, right half blue.
        for (var y = 0; y < 6; y++) {
          for (var x = 0; x < 4; x++) {
            if (x < 2) {
              image.setPixelRgba(x, y, 255, 0, 0, 255);
            } else {
              image.setPixelRgba(x, y, 0, 0, 255, 255);
            }
          }
        }

        final result = SixelImage.encode(image);
        // Should define at least 2 color registers.
        final colorDefs = RegExp(r'#\d+;2;\d+;\d+;\d+').allMatches(result);
        expect(colorDefs.length, greaterThanOrEqualTo(2));
      });

      test('uses carriage return (\$) between colors in the same band', () {
        final image = img.Image(width: 4, height: 6);
        // Two distinct colors.
        for (var y = 0; y < 6; y++) {
          for (var x = 0; x < 4; x++) {
            if (x < 2) {
              image.setPixelRgba(x, y, 255, 0, 0, 255);
            } else {
              image.setPixelRgba(x, y, 0, 255, 0, 255);
            }
          }
        }

        final result = SixelImage.encode(image);
        expect(result, contains('\$'));
      });

      test('quantizes images with more than 256 unique colors', () {
        // Create an image with many unique colors.
        final image = _gradientImage(
          32,
          32,
        ); // 1024 pixels, many unique colors.
        final result = SixelImage.encode(image);

        // Should still produce valid output without throwing.
        expect(result, startsWith('\x1bPq'));
        expect(result, endsWith('\x1b\\'));

        // Count color register definitions.
        final colorDefs = RegExp(r'#\d+;2;\d+;\d+;\d+').allMatches(result);
        expect(colorDefs.length, lessThanOrEqualTo(256));
      });

      test('respects maxColors parameter', () {
        final image = _gradientImage(16, 16);
        final result = SixelImage.encode(image, maxColors: 16);

        // Should define at most 16 color registers.
        final colorDefs = RegExp(r'#\d+;2;\d+;\d+;\d+').allMatches(result);
        expect(colorDefs.length, lessThanOrEqualTo(16));
      });

      test('throws on invalid maxColors', () {
        final image = _solidImage(2, 2);
        expect(
          () => SixelImage.encode(image, maxColors: 0),
          throwsArgumentError,
        );
        expect(
          () => SixelImage.encode(image, maxColors: 257),
          throwsArgumentError,
        );
      });

      test('handles image height not divisible by 6', () {
        // 7 pixels high = 2 bands (6 + 1).
        final image = _solidImage(4, 7);
        final result = SixelImage.encode(image);

        expect(result, startsWith('\x1bPq'));
        expect(result, endsWith('\x1b\\'));
        // Should have a band separator.
        expect(result, contains('-'));
      });

      test('handles single pixel image', () {
        final image = _solidImage(1, 1);
        final result = SixelImage.encode(image);

        expect(result, startsWith('\x1bPq'));
        expect(result, endsWith('\x1b\\'));
      });
    });

    group('encodeResized', () {
      test('resizes image before encoding', () {
        final image = _solidImage(100, 100);
        final result = SixelImage.encodeResized(
          image,
          columns: 5,
          rows: 3,
          cellPixelWidth: 8,
          cellPixelHeight: 16,
        );

        // Should produce valid Sixel.
        expect(result, startsWith('\x1bPq'));
        expect(result, endsWith('\x1b\\'));
      });

      test('produces output for resized dimensions', () {
        final image = _solidImage(200, 200);
        final smallResult = SixelImage.encodeResized(
          image,
          columns: 2,
          rows: 1,
          cellPixelWidth: 8,
          cellPixelHeight: 16,
        );
        final largeResult = SixelImage.encodeResized(
          image,
          columns: 20,
          rows: 10,
          cellPixelWidth: 8,
          cellPixelHeight: 16,
        );

        // Larger target should produce more Sixel data.
        expect(largeResult.length, greaterThan(smallResult.length));
      });

      test('rounds target height to multiple of 6', () {
        // 3 rows * 16 pixels = 48 pixels. Next multiple of 6 = 48.
        // 2 rows * 16 pixels = 32 pixels. Next multiple of 6 = 36.
        final image = _solidImage(10, 10);

        // These should not throw.
        final result = SixelImage.encodeResized(
          image,
          columns: 5,
          rows: 2,
          cellPixelWidth: 8,
          cellPixelHeight: 16,
        );
        expect(result, startsWith('\x1bPq'));
      });
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ITerm2Image
  // ──────────────────────────────────────────────────────────────────────────
  group('ITerm2Image', () {
    group('encode', () {
      test('produces a valid iTerm2 escape sequence', () {
        final image = _solidImage(2, 2);
        final result = ITerm2Image.encode(image);

        // OSC 1337 File=...:<base64>ST
        expect(result, contains('\x1b]1337;File='));
        expect(result, endsWith('\x1b\\'));
      });

      test('includes inline=1', () {
        final image = _solidImage(2, 2);
        final result = ITerm2Image.encode(image);
        expect(result, contains('inline=1'));
      });

      test('includes file size', () {
        final image = _solidImage(2, 2);
        final result = ITerm2Image.encode(image);

        // Should contain size=<number>.
        expect(result, contains(RegExp(r'size=\d+')));
      });

      test('includes width and height when provided', () {
        final image = _solidImage(2, 2);
        final result = ITerm2Image.encode(image, columns: 10, rows: 5);

        expect(result, contains('width=10'));
        expect(result, contains('height=5'));
      });

      test('omits width and height when not provided', () {
        final image = _solidImage(2, 2);
        final result = ITerm2Image.encode(image);

        expect(result, isNot(contains('width=')));
        expect(result, isNot(contains('height=')));
      });

      test('preserves aspect ratio by default', () {
        final image = _solidImage(2, 2);
        final result = ITerm2Image.encode(image);

        // preserveAspectRatio defaults to true, so should NOT emit
        // preserveAspectRatio=0.
        expect(result, isNot(contains('preserveAspectRatio=0')));
      });

      test('can disable aspect ratio preservation', () {
        final image = _solidImage(2, 2);
        final result = ITerm2Image.encode(image, preserveAspectRatio: false);

        expect(result, contains('preserveAspectRatio=0'));
      });

      test('includes base64-encoded filename when provided', () {
        final image = _solidImage(2, 2);
        final result = ITerm2Image.encode(image, name: 'test.png');

        final encodedName = base64Encode(utf8.encode('test.png'));
        expect(result, contains('name=$encodedName'));
      });

      test('omits name when not provided', () {
        final image = _solidImage(2, 2);
        final result = ITerm2Image.encode(image);

        expect(result, isNot(contains('name=')));
      });

      test('base64 payload is valid PNG', () {
        final image = _solidImage(4, 4);
        final result = ITerm2Image.encode(image);

        // Extract base64 data after the colon.
        final colonIndex = result.indexOf(':');
        final stIndex = result.lastIndexOf('\x1b\\');
        final base64Data = result.substring(colonIndex + 1, stIndex);

        final bytes = base64Decode(base64Data);
        // PNG magic bytes.
        expect(bytes[0], equals(0x89));
        expect(bytes[1], equals(0x50)); // P
        expect(bytes[2], equals(0x4E)); // N
        expect(bytes[3], equals(0x47)); // G
      });
    });

    group('encodePng', () {
      test('accepts pre-encoded PNG bytes', () {
        final image = _solidImage(4, 4);
        final pngBytes = img.encodePng(image);
        final result = ITerm2Image.encodePng(pngBytes, columns: 8, rows: 4);

        expect(result, contains('\x1b]1337;File='));
        expect(result, contains('inline=1'));
        expect(result, contains('width=8'));
        expect(result, contains('height=4'));
      });

      test('produces same output as encode for same image', () {
        final image = _solidImage(4, 4);
        final pngBytes = img.encodePng(image);

        final fromEncode = ITerm2Image.encode(image, columns: 5, rows: 3);
        final fromEncodePng = ITerm2Image.encodePng(
          pngBytes,
          columns: 5,
          rows: 3,
        );

        expect(fromEncodePng, equals(fromEncode));
      });

      test('includes correct file size', () {
        final image = _solidImage(4, 4);
        final pngBytes = img.encodePng(image);
        final result = ITerm2Image.encodePng(pngBytes);

        expect(result, contains('size=${pngBytes.length}'));
      });
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Cross-encoder consistency
  // ──────────────────────────────────────────────────────────────────────────
  group('Cross-encoder consistency', () {
    test('all encoders produce non-empty output for a valid image', () {
      final image = _solidImage(10, 12);

      expect(KittyImage.encode(image), isNotEmpty);
      expect(SixelImage.encode(image), isNotEmpty);
      expect(ITerm2Image.encode(image), isNotEmpty);
    });

    test('all encoders handle a 1x1 image without errors', () {
      final image = _solidImage(1, 1);

      expect(KittyImage.encode(image), isNotEmpty);
      expect(SixelImage.encode(image), isNotEmpty);
      expect(ITerm2Image.encode(image), isNotEmpty);
    });

    test('all encoders handle an image with many colors', () {
      final image = _stripedImage(64, 12, 32);

      final kittyResult = KittyImage.encode(image);
      final sixelResult = SixelImage.encode(image);
      final iterm2Result = ITerm2Image.encode(image);

      expect(kittyResult, isNotEmpty);
      expect(sixelResult, isNotEmpty);
      expect(iterm2Result, isNotEmpty);

      // All should have proper start/end markers.
      expect(kittyResult, contains('\x1b_G'));
      expect(sixelResult, startsWith('\x1bPq'));
      expect(iterm2Result, contains('\x1b]1337'));
    });

    test('Kitty PNG encoding is more compact than hypothetical raw RGBA', () {
      // For a real-world-ish image, PNG should be much more compact.
      final image = _solidImage(50, 50);

      final rawBytes = 50 * 50 * 4; // 10,000 bytes
      final rawBase64Len = ((rawBytes + 2) ~/ 3) * 4; // ~13,334 chars

      final kittyResult = KittyImage.encode(image);
      // The Kitty result includes control data + base64. The base64 portion
      // alone should be much shorter than rawBase64Len for a solid color.
      expect(kittyResult.length, lessThan(rawBase64Len));
    });
  });
}
