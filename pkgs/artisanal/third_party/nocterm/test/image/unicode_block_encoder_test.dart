import 'dart:typed_data';
import 'package:nocterm/src/image/unicode_block_encoder.dart';
import 'package:nocterm/src/style.dart';
import 'package:test/test.dart';

void main() {
  group('UnicodeBlockEncoder', () {
    group('encode()', () {
      test('single color image produces spaces with background', () {
        // Create a 2x2 solid red image
        final pixels = Uint8List.fromList([
          255, 0, 0, 255, // (0,0) red
          255, 0, 0, 255, // (1,0) red
          255, 0, 0, 255, // (0,1) red
          255, 0, 0, 255, // (1,1) red
        ]);

        const encoder = UnicodeBlockEncoder();
        final result = encoder.encode(pixels: pixels, width: 2, height: 2);

        // Should produce 1 row (2 pixel rows -> 1 output row)
        expect(result.length, 1);
        // Should produce 2 columns
        expect(result[0].length, 2);

        // Both cells should be spaces with red background
        // (because top and bottom pixels are the same color)
        for (final cell in result[0]) {
          expect(cell.char, UnicodeBlockEncoder.space);
          expect(cell.background.red, 255);
          expect(cell.background.green, 0);
          expect(cell.background.blue, 0);
        }
      });

      test('two-color vertical stripe produces half blocks', () {
        // Create a 2x2 image with red top row, blue bottom row
        final pixels = Uint8List.fromList([
          255, 0, 0, 255, // (0,0) red
          255, 0, 0, 255, // (1,0) red
          0, 0, 255, 255, // (0,1) blue
          0, 0, 255, 255, // (1,1) blue
        ]);

        const encoder = UnicodeBlockEncoder();
        final result = encoder.encode(pixels: pixels, width: 2, height: 2);

        // Should produce 1 row
        expect(result.length, 1);
        expect(result[0].length, 2);

        // Both cells should be upper half blocks
        // with red foreground and blue background
        for (final cell in result[0]) {
          expect(cell.char, UnicodeBlockEncoder.upperHalf);
          expect(cell.foreground.red, 255);
          expect(cell.foreground.green, 0);
          expect(cell.foreground.blue, 0);
          expect(cell.background.red, 0);
          expect(cell.background.green, 0);
          expect(cell.background.blue, 255);
        }
      });

      test('output dimensions are correct (height / 2 rounded up)', () {
        const encoder = UnicodeBlockEncoder();

        // Even height: 4x4 -> 4x2
        final pixels4x4 = Uint8List(4 * 4 * 4);
        for (int i = 0; i < pixels4x4.length; i += 4) {
          pixels4x4[i] = 100;
          pixels4x4[i + 1] = 150;
          pixels4x4[i + 2] = 200;
          pixels4x4[i + 3] = 255;
        }
        final result4x4 =
            encoder.encode(pixels: pixels4x4, width: 4, height: 4);
        expect(result4x4.length, 2); // height 4 -> 2 rows
        expect(result4x4[0].length, 4); // width stays 4

        // Odd height: 4x5 -> 4x3
        final pixels4x5 = Uint8List(4 * 5 * 4);
        for (int i = 0; i < pixels4x5.length; i += 4) {
          pixels4x5[i] = 100;
          pixels4x5[i + 1] = 150;
          pixels4x5[i + 2] = 200;
          pixels4x5[i + 3] = 255;
        }
        final result4x5 =
            encoder.encode(pixels: pixels4x5, width: 4, height: 5);
        expect(result4x5.length, 3); // height 5 -> 3 rows (ceil(5/2))
        expect(result4x5[0].length, 4);

        // Height 1: 4x1 -> 4x1
        final pixels4x1 = Uint8List(4 * 1 * 4);
        for (int i = 0; i < pixels4x1.length; i += 4) {
          pixels4x1[i] = 100;
          pixels4x1[i + 1] = 150;
          pixels4x1[i + 2] = 200;
          pixels4x1[i + 3] = 255;
        }
        final result4x1 =
            encoder.encode(pixels: pixels4x1, width: 4, height: 1);
        expect(result4x1.length, 1); // height 1 -> 1 row
        expect(result4x1[0].length, 4);
      });

      test('handles transparent pixels', () {
        // Create a 2x2 image with transparent top row
        final pixels = Uint8List.fromList([
          255, 0, 0, 0, // (0,0) transparent (alpha=0)
          255, 0, 0, 0, // (1,0) transparent
          0, 255, 0, 255, // (0,1) green (opaque)
          0, 255, 0, 255, // (1,1) green
        ]);

        const encoder = UnicodeBlockEncoder();
        final result = encoder.encode(pixels: pixels, width: 2, height: 2);

        expect(result.length, 1);

        // Should use lower half block (▄) since top is transparent
        for (final cell in result[0]) {
          expect(cell.char, UnicodeBlockEncoder.lowerHalf);
          expect(cell.foreground.green, 255); // green for bottom pixels
          expect(
              cell.background.isDefault, true); // default for transparent top
        }
      });

      test('handles fully transparent image', () {
        final pixels = Uint8List.fromList([
          255, 0, 0, 0, // all transparent
          255, 0, 0, 0,
          255, 0, 0, 0,
          255, 0, 0, 0,
        ]);

        const encoder = UnicodeBlockEncoder();
        final result = encoder.encode(pixels: pixels, width: 2, height: 2);

        expect(result.length, 1);

        // Should use space with default colors
        for (final cell in result[0]) {
          expect(cell.char, UnicodeBlockEncoder.space);
          expect(cell.foreground.isDefault, true);
          expect(cell.background.isDefault, true);
        }
      });

      test('handles odd height (last row uses same color for top and bottom)',
          () {
        // Create a 1x3 image (odd height)
        final pixels = Uint8List.fromList([
          255, 0, 0, 255, // (0,0) red
          0, 255, 0, 255, // (0,1) green
          0, 0, 255, 255, // (0,2) blue
        ]);

        const encoder = UnicodeBlockEncoder();
        final result = encoder.encode(pixels: pixels, width: 1, height: 3);

        // Should produce 2 rows (ceil(3/2))
        expect(result.length, 2);

        // First row: red on top, green on bottom
        expect(result[0][0].char, UnicodeBlockEncoder.upperHalf);
        expect(result[0][0].foreground.red, 255); // red
        expect(result[0][0].background.green, 255); // green

        // Second row: blue only (uses blue for both since no bottom pixel)
        expect(result[1][0].char, UnicodeBlockEncoder.space);
        expect(result[1][0].background.blue, 255);
      });

      test('handles empty dimensions', () {
        const encoder = UnicodeBlockEncoder();

        expect(
            encoder.encode(pixels: Uint8List(0), width: 0, height: 0), isEmpty);
        expect(
            encoder.encode(pixels: Uint8List(0), width: 0, height: 5), isEmpty);
        expect(
            encoder.encode(pixels: Uint8List(0), width: 5, height: 0), isEmpty);
      });
    });

    group('encodeToAnsi()', () {
      test('produces valid ANSI escape sequences', () {
        // Create a simple 2x2 red/blue image
        final pixels = Uint8List.fromList([
          255, 0, 0, 255, // red
          255, 0, 0, 255, // red
          0, 0, 255, 255, // blue
          0, 0, 255, 255, // blue
        ]);

        const encoder = UnicodeBlockEncoder();
        final rows = encoder.encodeToAnsi(pixels: pixels, width: 2, height: 2);

        expect(rows.length, 1);

        // Should contain foreground color escape (either 24-bit or 256-color)
        // 24-bit: \x1b[38;2;R;G;Bm, 256-color: \x1b[38;5;Nm
        expect(rows[0], matches(RegExp(r'\x1b\[38;[25];')));
        // Should contain background color escape
        expect(rows[0], matches(RegExp(r'\x1b\[48;[25];')));
        // Should contain the half block character
        expect(rows[0], contains(UnicodeBlockEncoder.upperHalf));
        // Should end with reset
        expect(rows[0], endsWith('\x1b[0m'));
      });

      test('single color row uses space with background only', () {
        // Create a solid green 2x2 image
        final pixels = Uint8List.fromList([
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          255,
          0,
          255,
        ]);

        const encoder = UnicodeBlockEncoder();
        final rows = encoder.encodeToAnsi(pixels: pixels, width: 2, height: 2);

        expect(rows.length, 1);

        // Should contain background color (either 24-bit or 256-color)
        expect(rows[0], matches(RegExp(r'\x1b\[48;[25];')));
        // Should contain spaces
        expect(rows[0], contains('  ')); // two spaces
        // Should end with reset
        expect(rows[0], endsWith('\x1b[0m'));
      });

      test('optimizes color codes (does not repeat same colors)', () {
        // Create a 4x2 image with all same color
        final pixels = Uint8List(4 * 2 * 4);
        for (int i = 0; i < pixels.length; i += 4) {
          pixels[i] = 128; // R
          pixels[i + 1] = 64; // G
          pixels[i + 2] = 32; // B
          pixels[i + 3] = 255; // A
        }

        const encoder = UnicodeBlockEncoder();
        final rows = encoder.encodeToAnsi(pixels: pixels, width: 4, height: 2);

        expect(rows.length, 1);

        // Should only have one background color code, not 4
        // Match either 24-bit or 256-color format
        final bgMatches = RegExp(r'\x1b\[48;[25];').allMatches(rows[0]).length;
        expect(bgMatches, 1,
            reason: 'Background color should only be set once');
      });
    });

    group('static helpers', () {
      test('encodeSolidColor creates correct output', () {
        final rows = UnicodeBlockEncoder.encodeSolidColor(
          color: const Color.fromRGB(255, 128, 64),
          width: 3,
          height: 4,
        );

        expect(rows.length, 2); // height 4 -> 2 rows
        for (final row in rows) {
          // Each row should have background color set (24-bit or 256-color)
          expect(row, matches(RegExp(r'\x1b\[48;[25];')));
        }
      });

      test('encodeVerticalGradient creates gradient output', () {
        final rows = UnicodeBlockEncoder.encodeVerticalGradient(
          topColor: const Color.fromRGB(255, 0, 0),
          bottomColor: const Color.fromRGB(0, 0, 255),
          width: 2,
          height: 4,
        );

        expect(rows.length, 2);

        // Rows should contain color codes (either 24-bit or 256-color)
        expect(rows[0], matches(RegExp(r'\x1b\[[34]8;[25];')));
        expect(rows[1], matches(RegExp(r'\x1b\[[34]8;[25];')));
      });
    });

    group('BlockCell', () {
      test('equality works correctly', () {
        const cell1 = BlockCell(
          char: '▀',
          foreground: Color.fromRGB(255, 0, 0),
          background: Color.fromRGB(0, 0, 255),
        );
        const cell2 = BlockCell(
          char: '▀',
          foreground: Color.fromRGB(255, 0, 0),
          background: Color.fromRGB(0, 0, 255),
        );
        const cell3 = BlockCell(
          char: '▄',
          foreground: Color.fromRGB(255, 0, 0),
          background: Color.fromRGB(0, 0, 255),
        );

        expect(cell1, equals(cell2));
        expect(cell1, isNot(equals(cell3)));
      });

      test('hashCode is consistent with equality', () {
        const cell1 = BlockCell(
          char: '▀',
          foreground: Color.fromRGB(255, 0, 0),
          background: Color.fromRGB(0, 0, 255),
        );
        const cell2 = BlockCell(
          char: '▀',
          foreground: Color.fromRGB(255, 0, 0),
          background: Color.fromRGB(0, 0, 255),
        );

        expect(cell1.hashCode, equals(cell2.hashCode));
      });

      test('toString returns readable representation', () {
        const cell = BlockCell(
          char: '▀',
          foreground: Color.fromRGB(255, 0, 0),
          background: Color.fromRGB(0, 0, 255),
        );

        final str = cell.toString();
        expect(str, contains('BlockCell'));
        expect(str, contains('▀'));
      });
    });

    group('custom transparent color', () {
      test('uses provided transparent color instead of default', () {
        // Create a 2x2 image with transparent pixels
        final pixels = Uint8List.fromList([
          255, 0, 0, 0, // transparent
          255, 0, 0, 0, // transparent
          0, 255, 0, 255, // green
          0, 255, 0, 255, // green
        ]);

        final encoder = UnicodeBlockEncoder(
          transparentColor: const Color.fromRGB(30, 30, 30), // dark gray
        );
        final result = encoder.encode(pixels: pixels, width: 2, height: 2);

        // Top pixels should use the custom transparent color, not default
        for (final cell in result[0]) {
          expect(cell.char, UnicodeBlockEncoder.upperHalf);
          // Foreground should be the custom transparent color (dark gray)
          expect(cell.foreground.red, 30);
          expect(cell.foreground.green, 30);
          expect(cell.foreground.blue, 30);
          // Background should be green
          expect(cell.background.green, 255);
        }
      });

      test('custom alpha threshold works', () {
        // Create pixels with alpha = 100 (below default 128 threshold)
        final pixels = Uint8List.fromList([
          255, 0, 0, 100, // semi-transparent red
          255, 0, 0, 100,
          0, 255, 0, 255, // opaque green
          0, 255, 0, 255,
        ]);

        // With default threshold (128), red should be transparent
        const defaultEncoder = UnicodeBlockEncoder();
        final defaultResult =
            defaultEncoder.encode(pixels: pixels, width: 2, height: 2);
        expect(defaultResult[0][0].char, UnicodeBlockEncoder.lowerHalf);

        // With threshold of 50, red should be visible
        const lowThresholdEncoder = UnicodeBlockEncoder(alphaThreshold: 50);
        final lowResult =
            lowThresholdEncoder.encode(pixels: pixels, width: 2, height: 2);
        expect(lowResult[0][0].char, UnicodeBlockEncoder.upperHalf);
        expect(lowResult[0][0].foreground.red, 255); // red is now visible
      });
    });
  });
}
