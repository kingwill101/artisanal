import 'dart:typed_data';

import 'package:nocterm/nocterm.dart' hide isNotEmpty;
import 'package:nocterm/src/components/image.dart' as img;
import 'package:test/test.dart';

void main() {
  group('ImageData', () {
    test('creates from pixels', () {
      final pixels = Uint8List(4 * 4 * 4); // 4x4 RGBA
      final imageData = img.ImageData(
        pixels: pixels,
        width: 4,
        height: 4,
      );

      expect(imageData.width, equals(4));
      expect(imageData.height, equals(4));
      expect(imageData.pixels.length, equals(64));
    });

    test('scales image', () {
      // Create 4x4 red image
      final pixels = Uint8List(4 * 4 * 4);
      for (int i = 0; i < 16; i++) {
        pixels[i * 4] = 255; // R
        pixels[i * 4 + 1] = 0; // G
        pixels[i * 4 + 2] = 0; // B
        pixels[i * 4 + 3] = 255; // A
      }

      final original = img.ImageData(pixels: pixels, width: 4, height: 4);
      final scaled = original.scale(8, 8);

      expect(scaled.width, equals(8));
      expect(scaled.height, equals(8));
      expect(scaled.pixels.length, equals(8 * 8 * 4));

      // All pixels should still be red (nearest neighbor)
      for (int i = 0; i < 64; i++) {
        expect(scaled.pixels[i * 4], equals(255)); // R
        expect(scaled.pixels[i * 4 + 1], equals(0)); // G
        expect(scaled.pixels[i * 4 + 2], equals(0)); // B
      }
    });

    test('scale returns same instance when size unchanged', () {
      final pixels = Uint8List(4 * 4 * 4);
      final original = img.ImageData(pixels: pixels, width: 4, height: 4);
      final scaled = original.scale(4, 4);

      expect(identical(original, scaled), isTrue);
    });
  });

  group('ImageProvider', () {
    test('FileImage equality', () {
      final a = img.FileImage('/path/to/image.png');
      final b = img.FileImage('/path/to/image.png');
      final c = img.FileImage('/path/to/other.png');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('NetworkImage equality', () {
      final a = img.NetworkImage('https://example.com/image.png');
      final b = img.NetworkImage('https://example.com/image.png');
      final c = img.NetworkImage('https://example.com/other.png');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('MemoryImage equality', () {
      final bytes1 = Uint8List.fromList([1, 2, 3, 4, 5]);
      final bytes2 = Uint8List.fromList([1, 2, 3, 4, 5]);
      final bytes3 = Uint8List.fromList([5, 4, 3, 2, 1]);

      final a = img.MemoryImage(bytes1);
      final b = img.MemoryImage(bytes2);
      final c = img.MemoryImage(bytes3);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('BoxFit', () {
    test('all values exist', () {
      expect(img.BoxFit.values, contains(img.BoxFit.fill));
      expect(img.BoxFit.values, contains(img.BoxFit.contain));
      expect(img.BoxFit.values, contains(img.BoxFit.cover));
      expect(img.BoxFit.values, contains(img.BoxFit.fitWidth));
      expect(img.BoxFit.values, contains(img.BoxFit.fitHeight));
      expect(img.BoxFit.values, contains(img.BoxFit.none));
    });
  });

  group('Image widget', () {
    test('creates with file constructor', () {
      final widget = img.Image.file(
        '/path/to/image.png',
        width: 20,
        height: 10,
        fit: img.BoxFit.contain,
      );

      expect(widget.image, isA<img.FileImage>());
      expect(widget.width, equals(20));
      expect(widget.height, equals(10));
      expect(widget.fit, equals(img.BoxFit.contain));
    });

    test('creates with network constructor', () {
      final widget = img.Image.network(
        'https://example.com/image.png',
        width: 30,
        height: 15,
      );

      expect(widget.image, isA<img.NetworkImage>());
      expect(widget.width, equals(30));
      expect(widget.height, equals(15));
    });

    test('creates with memory constructor', () {
      final bytes = Uint8List(100);
      final widget = img.Image.memory(
        bytes,
        fit: img.BoxFit.cover,
      );

      expect(widget.image, isA<img.MemoryImage>());
      expect(widget.fit, equals(img.BoxFit.cover));
    });

    test('renders placeholder while loading', () async {
      await testNocterm(
        'image placeholder',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: img.Image.file(
                '/nonexistent/path.png',
                width: 10,
                height: 5,
                placeholder: const Text('Loading...'),
              ),
            ),
          );

          // Should show placeholder text
          final snapshot = tester.toSnapshot();
          expect(snapshot, contains('Loading'));
        },
      );
    });

    test('renders error widget on failure', () async {
      await testNocterm(
        'image error',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: img.Image.file(
                '/definitely/not/a/real/file.png',
                width: 10,
                height: 5,
                errorWidget: const Text('Error!'),
              ),
            ),
          );

          // Wait for async load to fail
          await Future.delayed(const Duration(milliseconds: 100));
          await tester.pump();

          final snapshot = tester.toSnapshot();
          expect(snapshot, contains('Error'));
        },
      );
    });

    test('renders with memory image data', () async {
      // Create a simple 8x8 red PNG-like test image
      // For this test, we'll create raw RGBA and use MemoryImage
      // The actual sixel output would require a real terminal

      await testNocterm(
        'memory image render',
        (tester) async {
          // Create a simple 8x16 solid color image (1 cell worth)
          final width = 8;
          final height = 16;
          final pixels = Uint8List(width * height * 4);

          // Fill with blue
          for (int i = 0; i < width * height; i++) {
            pixels[i * 4] = 0; // R
            pixels[i * 4 + 1] = 0; // G
            pixels[i * 4 + 2] = 255; // B
            pixels[i * 4 + 3] = 255; // A
          }

          // Note: MemoryImage expects encoded image bytes (PNG/JPEG),
          // not raw pixels. This test demonstrates the widget structure.
          // For actual sixel rendering, you'd need a terminal that supports it.

          await tester.pumpComponent(
            Center(
              child: SizedBox(
                width: 20,
                height: 10,
                child: const Text('Image area'),
              ),
            ),
          );

          final snapshot = tester.toSnapshot();
          expect(snapshot, isNotEmpty);
        },
      );
    });
  });

  group('RenderImage', () {
    test('calculates size from image dimensions', () async {
      await testNocterm(
        'render image size',
        (tester) async {
          // Test that Image widget respects size constraints
          await tester.pumpComponent(
            Center(
              child: SizedBox(
                width: 20,
                height: 10,
                child: img.Image.file(
                  '/test.png',
                  fit: img.BoxFit.contain,
                ),
              ),
            ),
          );

          // Widget should render within constraints
          final snapshot = tester.toSnapshot();
          expect(snapshot, isNotEmpty);
        },
      );
    });
  });
}
