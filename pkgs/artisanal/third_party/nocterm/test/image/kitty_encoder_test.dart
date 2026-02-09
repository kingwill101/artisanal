import 'dart:convert';
import 'dart:typed_data';

import 'package:nocterm/src/image/kitty_encoder.dart';
import 'package:test/test.dart';

void main() {
  group('KittyEncoder', () {
    group('encodePng', () {
      test('produces valid escape sequence format', () {
        final imageBytes =
            Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header bytes

        final result = KittyEncoder.encodePng(imageBytes: imageBytes);

        // Should start with APC (ESC _ G)
        expect(result, startsWith('\x1b_G'));
        // Should end with ST (ESC \)
        expect(result, endsWith('\x1b\\'));
        // Should contain action=T (transmit and display)
        expect(result, contains('a=T'));
        // Should contain format=100 (PNG)
        expect(result, contains('f=100'));
        // Should contain quiet mode
        expect(result, contains('q=2'));
      });

      test('base64 data is valid', () {
        final imageBytes =
            Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]); // "Hello"

        final result = KittyEncoder.encodePng(imageBytes: imageBytes);

        // Extract base64 data (after ; and before ST)
        final semicolonIndex = result.indexOf(';');
        final stIndex = result.indexOf('\x1b\\');
        final base64Data = result.substring(semicolonIndex + 1, stIndex);

        // Should be valid base64
        expect(() => base64Decode(base64Data), returnsNormally);

        // Should decode back to original bytes
        final decoded = base64Decode(base64Data);
        expect(decoded, equals(imageBytes));
      });

      test('sets quiet mode correctly', () {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        var result = KittyEncoder.encodePng(imageBytes: imageBytes, quiet: 0);
        expect(result, contains('q=0'));

        result = KittyEncoder.encodePng(imageBytes: imageBytes, quiet: 1);
        expect(result, contains('q=1'));

        result = KittyEncoder.encodePng(imageBytes: imageBytes, quiet: 2);
        expect(result, contains('q=2'));
      });

      test('includes image ID when provided', () {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        final result =
            KittyEncoder.encodePng(imageBytes: imageBytes, imageId: 42);

        expect(result, contains('i=42'));
      });

      test('does not include image ID when not provided', () {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        final result = KittyEncoder.encodePng(imageBytes: imageBytes);

        expect(result, isNot(contains('i=')));
      });

      test('final chunk has m=0', () {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        final result = KittyEncoder.encodePng(imageBytes: imageBytes);

        // Should contain m=0 (final chunk)
        expect(result, contains('m=0'));
        // For small data, should not contain m=1
        expect(result, isNot(contains('m=1')));
      });
    });

    group('chunking', () {
      test('chunks large data correctly', () {
        // Create data larger than max chunk size (4096 bytes)
        final largeData = Uint8List(5000);
        for (int i = 0; i < largeData.length; i++) {
          largeData[i] = i % 256;
        }

        final result = KittyEncoder.encodePng(imageBytes: largeData);

        // Should have multiple chunks
        final chunks = result.split('\x1b\\');
        // Remove empty string from split
        final nonEmptyChunks = chunks.where((c) => c.isNotEmpty).toList();

        // Large data should produce multiple chunks
        expect(nonEmptyChunks.length, greaterThan(1));

        // First chunks should have m=1, last should have m=0
        for (int i = 0; i < nonEmptyChunks.length - 1; i++) {
          expect(nonEmptyChunks[i], contains('m=1'));
        }
        expect(nonEmptyChunks.last, contains('m=0'));
      });

      test('first chunk includes all parameters', () {
        final largeData = Uint8List(5000);
        for (int i = 0; i < largeData.length; i++) {
          largeData[i] = i % 256;
        }

        final result =
            KittyEncoder.encodePng(imageBytes: largeData, imageId: 123);

        // Split into chunks
        final chunks = result.split('\x1b\\');
        final firstChunk = chunks[0];

        // First chunk should have all params
        expect(firstChunk, contains('a=T'));
        expect(firstChunk, contains('f=100'));
        expect(firstChunk, contains('q=2'));
        expect(firstChunk, contains('i=123'));

        // Continuation chunks should not repeat params (except m)
        if (chunks.length > 2) {
          final secondChunk = chunks[1];
          expect(secondChunk, isNot(contains('a=T')));
          expect(secondChunk, isNot(contains('f=100')));
        }
      });

      test('chunk sizes are multiples of 4 except last', () {
        // Create data that will require multiple chunks
        final largeData = Uint8List(10000);
        for (int i = 0; i < largeData.length; i++) {
          largeData[i] = i % 256;
        }

        final result = KittyEncoder.encodePng(imageBytes: largeData);

        // Split into chunks and extract base64 data from each
        final chunks = result.split('\x1b\\');
        final nonEmptyChunks = chunks.where((c) => c.isNotEmpty).toList();

        for (int i = 0; i < nonEmptyChunks.length - 1; i++) {
          final chunk = nonEmptyChunks[i];
          final semicolonIndex = chunk.indexOf(';');
          if (semicolonIndex >= 0) {
            final base64Part = chunk.substring(semicolonIndex + 1);
            // Non-final chunks should be multiple of 4
            expect(base64Part.length % 4, equals(0),
                reason: 'Chunk $i base64 length should be multiple of 4');
          }
        }
      });

      test('reassembled base64 decodes to original data', () {
        final originalData = Uint8List(6000);
        for (int i = 0; i < originalData.length; i++) {
          originalData[i] = i % 256;
        }

        final result = KittyEncoder.encodePng(imageBytes: originalData);

        // Extract and reassemble all base64 data
        final reassembled = StringBuffer();
        final chunks = result.split('\x1b\\');

        for (final chunk in chunks) {
          if (chunk.isEmpty) continue;
          final semicolonIndex = chunk.indexOf(';');
          if (semicolonIndex >= 0) {
            reassembled.write(chunk.substring(semicolonIndex + 1));
          }
        }

        // Decode reassembled base64
        final decoded = base64Decode(reassembled.toString());
        expect(decoded, equals(originalData));
      });
    });

    group('encodeRgba', () {
      test('encodes RGBA pixels to valid escape sequence', () {
        // Create a simple 2x2 red image
        final width = 2;
        final height = 2;
        final pixels = Uint8List(width * height * 4);
        for (int i = 0; i < width * height; i++) {
          pixels[i * 4] = 255; // R
          pixels[i * 4 + 1] = 0; // G
          pixels[i * 4 + 2] = 0; // B
          pixels[i * 4 + 3] = 255; // A
        }

        final result = KittyEncoder.encodeRgba(
          rgbaPixels: pixels,
          width: width,
          height: height,
        );

        // Should have valid Kitty format
        expect(result, startsWith('\x1b_G'));
        expect(result, endsWith('\x1b\\'));
        expect(result, contains('a=T'));
        expect(result, contains('f=100')); // PNG format (converted)
      });

      test('returns empty string for zero dimensions', () {
        expect(
          KittyEncoder.encodeRgba(
            rgbaPixels: Uint8List(0),
            width: 0,
            height: 0,
          ),
          isEmpty,
        );

        expect(
          KittyEncoder.encodeRgba(
            rgbaPixels: Uint8List(0),
            width: 0,
            height: 10,
          ),
          isEmpty,
        );

        expect(
          KittyEncoder.encodeRgba(
            rgbaPixels: Uint8List(0),
            width: 10,
            height: 0,
          ),
          isEmpty,
        );
      });

      test('throws on mismatched pixel data length', () {
        final pixels = Uint8List(10); // Wrong length

        expect(
          () => KittyEncoder.encodeRgba(
            rgbaPixels: pixels,
            width: 4,
            height: 4, // Expects 4*4*4 = 64 bytes
          ),
          throwsArgumentError,
        );
      });

      test('produces PNG data in base64', () {
        final width = 4;
        final height = 4;
        final pixels = Uint8List(width * height * 4);

        // Create a gradient pattern
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final i = (y * width + x) * 4;
            pixels[i] = (x * 64).clamp(0, 255); // R
            pixels[i + 1] = (y * 64).clamp(0, 255); // G
            pixels[i + 2] = 128; // B
            pixels[i + 3] = 255; // A
          }
        }

        final result = KittyEncoder.encodeRgba(
          rgbaPixels: pixels,
          width: width,
          height: height,
        );

        // Extract base64 data
        final semicolonIndex = result.indexOf(';');
        final stIndex = result.indexOf('\x1b\\');
        final base64Data = result.substring(semicolonIndex + 1, stIndex);

        // Should be valid base64
        final decoded = base64Decode(base64Data);

        // Should be valid PNG (starts with PNG magic bytes)
        expect(decoded[0], equals(0x89));
        expect(decoded[1], equals(0x50)); // P
        expect(decoded[2], equals(0x4E)); // N
        expect(decoded[3], equals(0x47)); // G
      });
    });

    group('encodeRgb', () {
      test('encodes RGB pixels to valid escape sequence', () {
        // Create a simple 2x2 blue image
        final width = 2;
        final height = 2;
        final pixels = Uint8List(width * height * 3);
        for (int i = 0; i < width * height; i++) {
          pixels[i * 3] = 0; // R
          pixels[i * 3 + 1] = 0; // G
          pixels[i * 3 + 2] = 255; // B
        }

        final result = KittyEncoder.encodeRgb(
          rgbPixels: pixels,
          width: width,
          height: height,
        );

        // Should have valid Kitty format
        expect(result, startsWith('\x1b_G'));
        expect(result, endsWith('\x1b\\'));
        expect(result, contains('a=T'));
        expect(result, contains('f=100')); // PNG format (converted)
      });

      test('returns empty string for zero dimensions', () {
        expect(
          KittyEncoder.encodeRgb(
            rgbPixels: Uint8List(0),
            width: 0,
            height: 0,
          ),
          isEmpty,
        );
      });

      test('throws on mismatched pixel data length', () {
        final pixels = Uint8List(10); // Wrong length

        expect(
          () => KittyEncoder.encodeRgb(
            rgbPixels: pixels,
            width: 4,
            height: 4, // Expects 4*4*3 = 48 bytes
          ),
          throwsArgumentError,
        );
      });

      test('produces PNG data in base64', () {
        final width = 3;
        final height = 3;
        final pixels = Uint8List(width * height * 3);

        // Fill with green
        for (int i = 0; i < width * height; i++) {
          pixels[i * 3] = 0; // R
          pixels[i * 3 + 1] = 255; // G
          pixels[i * 3 + 2] = 0; // B
        }

        final result = KittyEncoder.encodeRgb(
          rgbPixels: pixels,
          width: width,
          height: height,
        );

        // Extract base64 data
        final semicolonIndex = result.indexOf(';');
        final stIndex = result.indexOf('\x1b\\');
        final base64Data = result.substring(semicolonIndex + 1, stIndex);

        // Should be valid base64
        final decoded = base64Decode(base64Data);

        // Should be valid PNG (starts with PNG magic bytes)
        expect(decoded[0], equals(0x89));
        expect(decoded[1], equals(0x50)); // P
        expect(decoded[2], equals(0x4E)); // N
        expect(decoded[3], equals(0x47)); // G
      });
    });

    group('parameters formatting', () {
      test('parameters are correctly formatted as key=value pairs', () {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        final result = KittyEncoder.encodePng(
          imageBytes: imageBytes,
          quiet: 1,
          imageId: 99,
        );

        // Check parameter format
        expect(result, contains('a=T'));
        expect(result, contains('f=100'));
        expect(result, contains('q=1'));
        expect(result, contains('i=99'));
        expect(result, contains('m=0'));
      });
    });
  });
}
