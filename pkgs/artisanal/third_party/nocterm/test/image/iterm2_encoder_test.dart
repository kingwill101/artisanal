import 'dart:convert';
import 'dart:typed_data';

import 'package:nocterm/src/image/iterm2_encoder.dart';
import 'package:test/test.dart';

void main() {
  group('ITerm2Encoder', () {
    group('encode', () {
      test('produces valid escape sequence format with BEL terminator', () {
        final imageBytes =
            Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header bytes

        final result = ITerm2Encoder.encode(imageBytes: imageBytes);

        // Should start with OSC 1337
        expect(result, startsWith('\x1b]1337;File='));
        // Should end with BEL
        expect(result, endsWith('\x07'));
        // Should contain inline=1
        expect(result, contains('inline=1'));
        // Should contain size
        expect(result, contains('size=4'));
      });

      test('produces valid escape sequence format with ST terminator', () {
        final imageBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

        final result =
            ITerm2Encoder.encode(imageBytes: imageBytes, useST: true);

        // Should end with ST (ESC \)
        expect(result, endsWith('\x1b\\'));
      });

      test('arguments are correctly formatted', () {
        final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

        final result = ITerm2Encoder.encode(
          imageBytes: imageBytes,
          width: '20',
          height: '10',
          preserveAspectRatio: false,
          filename: 'test.png',
        );

        // Should contain all arguments
        expect(result, contains('inline=1'));
        expect(result, contains('size=5'));
        expect(result, contains('width=20'));
        expect(result, contains('height=10'));
        expect(result, contains('preserveAspectRatio=0'));

        // Filename should be base64 encoded
        final encodedFilename = base64Encode(utf8.encode('test.png'));
        expect(result, contains('name=$encodedFilename'));
      });

      test('base64 data is valid', () {
        final imageBytes =
            Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]); // "Hello"

        final result = ITerm2Encoder.encode(imageBytes: imageBytes);

        // Extract base64 data (after : and before terminator)
        final colonIndex = result.indexOf(':');
        final base64Data = result.substring(colonIndex + 1, result.length - 1);

        // Should be valid base64
        expect(() => base64Decode(base64Data), returnsNormally);

        // Should decode back to original bytes
        final decoded = base64Decode(base64Data);
        expect(decoded, equals(imageBytes));
      });

      test('width and height accept different formats', () {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        // Cells
        var result = ITerm2Encoder.encode(
          imageBytes: imageBytes,
          width: '20',
          height: '10',
        );
        expect(result, contains('width=20'));
        expect(result, contains('height=10'));

        // Pixels
        result = ITerm2Encoder.encode(
          imageBytes: imageBytes,
          width: '100px',
          height: '50px',
        );
        expect(result, contains('width=100px'));
        expect(result, contains('height=50px'));

        // Percentage
        result = ITerm2Encoder.encode(
          imageBytes: imageBytes,
          width: '50%',
          height: '25%',
        );
        expect(result, contains('width=50%'));
        expect(result, contains('height=25%'));

        // Auto
        result = ITerm2Encoder.encode(
          imageBytes: imageBytes,
          width: 'auto',
          height: 'auto',
        );
        expect(result, contains('width=auto'));
        expect(result, contains('height=auto'));
      });

      test('preserveAspectRatio defaults to true (not in output)', () {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        final result = ITerm2Encoder.encode(imageBytes: imageBytes);

        // Should not contain preserveAspectRatio (default is 1)
        expect(result, isNot(contains('preserveAspectRatio')));
      });

      test('preserveAspectRatio=0 when set to false', () {
        final imageBytes = Uint8List.fromList([1, 2, 3]);

        final result = ITerm2Encoder.encode(
          imageBytes: imageBytes,
          preserveAspectRatio: false,
        );

        expect(result, contains('preserveAspectRatio=0'));
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

        final result = ITerm2Encoder.encodeRgba(
          rgbaPixels: pixels,
          width: width,
          height: height,
        );

        // Should have valid iTerm2 format
        expect(result, startsWith('\x1b]1337;File='));
        expect(result, endsWith('\x07'));
        expect(result, contains('inline=1'));
        expect(result, contains('size='));
      });

      test('returns empty string for zero dimensions', () {
        expect(
          ITerm2Encoder.encodeRgba(
            rgbaPixels: Uint8List(0),
            width: 0,
            height: 0,
          ),
          isEmpty,
        );

        expect(
          ITerm2Encoder.encodeRgba(
            rgbaPixels: Uint8List(0),
            width: 0,
            height: 10,
          ),
          isEmpty,
        );

        expect(
          ITerm2Encoder.encodeRgba(
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
          () => ITerm2Encoder.encodeRgba(
            rgbaPixels: pixels,
            width: 4,
            height: 4, // Expects 4*4*4 = 64 bytes
          ),
          throwsArgumentError,
        );
      });

      test('passes display dimensions correctly', () {
        final width = 2;
        final height = 2;
        final pixels = Uint8List(width * height * 4);
        for (int i = 0; i < width * height * 4; i++) {
          pixels[i] = 128;
        }

        final result = ITerm2Encoder.encodeRgba(
          rgbaPixels: pixels,
          width: width,
          height: height,
          displayWidth: '10',
          displayHeight: '5',
        );

        expect(result, contains('width=10'));
        expect(result, contains('height=5'));
      });

      test('passes preserveAspectRatio correctly', () {
        final width = 2;
        final height = 2;
        final pixels = Uint8List(width * height * 4);
        for (int i = 0; i < width * height * 4; i++) {
          pixels[i] = 128;
        }

        final result = ITerm2Encoder.encodeRgba(
          rgbaPixels: pixels,
          width: width,
          height: height,
          preserveAspectRatio: false,
        );

        expect(result, contains('preserveAspectRatio=0'));
      });

      test('produces PNG data that can be decoded from base64', () {
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

        final result = ITerm2Encoder.encodeRgba(
          rgbaPixels: pixels,
          width: width,
          height: height,
        );

        // Extract base64 data
        final colonIndex = result.indexOf(':');
        final base64Data = result.substring(colonIndex + 1, result.length - 1);

        // Should be valid base64
        final decoded = base64Decode(base64Data);

        // Should be valid PNG (starts with PNG magic bytes)
        expect(decoded[0], equals(0x89));
        expect(decoded[1], equals(0x50)); // P
        expect(decoded[2], equals(0x4E)); // N
        expect(decoded[3], equals(0x47)); // G
      });
    });
  });
}
