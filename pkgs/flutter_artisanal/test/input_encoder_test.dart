import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_artisanal/src/input_encoder.dart';

void main() {
  group('InputEncoder', () {
    group('encodeSpecialKey', () {
      test('encodes Escape', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.escape),
          equals(const [0x1b]),
        );
      });

      test('encodes Enter as CR', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.enter),
          equals(const [0x0d]),
        );
      });

      test('encodes Backspace as DEL (0x7f)', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.backspace),
          equals(const [0x7f]),
        );
      });

      test('encodes Tab', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.tab),
          equals(const [0x09]),
        );
      });

      test('encodes arrow keys as CSI sequences', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.arrowUp),
          equals(const [0x1b, 0x5b, 0x41]),
        );
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.arrowDown),
          equals(const [0x1b, 0x5b, 0x42]),
        );
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.arrowRight),
          equals(const [0x1b, 0x5b, 0x43]),
        );
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.arrowLeft),
          equals(const [0x1b, 0x5b, 0x44]),
        );
      });

      test('encodes Home and End', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.home),
          equals(const [0x1b, 0x5b, 0x48]),
        );
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.end),
          equals(const [0x1b, 0x5b, 0x46]),
        );
      });

      test('encodes Delete and Insert', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.delete),
          equals(const [0x1b, 0x5b, 0x33, 0x7e]),
        );
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.insert),
          equals(const [0x1b, 0x5b, 0x32, 0x7e]),
        );
      });

      test('encodes PageUp and PageDown', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.pageUp),
          equals(const [0x1b, 0x5b, 0x35, 0x7e]),
        );
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.pageDown),
          equals(const [0x1b, 0x5b, 0x36, 0x7e]),
        );
      });

      test('encodes F1-F4 as SS3 sequences', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.f1),
          equals(const [0x1b, 0x4f, 0x50]),
        );
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.f2),
          equals(const [0x1b, 0x4f, 0x51]),
        );
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.f3),
          equals(const [0x1b, 0x4f, 0x52]),
        );
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.f4),
          equals(const [0x1b, 0x4f, 0x53]),
        );
      });

      test('encodes F5-F12 as CSI ~ sequences', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.f5),
          equals(const [0x1b, 0x5b, 0x31, 0x35, 0x7e]),
        );
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.f12),
          equals(const [0x1b, 0x5b, 0x32, 0x34, 0x7e]),
        );
      });

      test('returns empty list for unmapped keys', () {
        expect(
          InputEncoder.encodeSpecialKey(LogicalKeyboardKey.keyA),
          equals(<int>[]),
        );
      });
    });

    group('encodeSgrMouse', () {
      test('encodes press at 1-based coordinates', () {
        final bytes = InputEncoder.encodeSgrMouse(
          x: 0,
          y: 0,
          button: 0,
          press: true,
        );
        expect(bytes, equals(const [0x1b, 0x5b, 0x3c, 0x30, 0x3b, 0x31, 0x3b, 0x31, 0x4d]));
      });

      test('encodes release with m terminator', () {
        final bytes = InputEncoder.encodeSgrMouse(
          x: 5,
          y: 10,
          button: 0,
          press: false,
        );
        expect(bytes, equals(const [0x1b, 0x5b, 0x3c, 0x30, 0x3b, 0x36, 0x3b, 0x31, 0x31, 0x6d]));
      });

      test('adds motion bit', () {
        final bytes = InputEncoder.encodeSgrMouse(
          x: 1,
          y: 1,
          button: 0,
          press: false,
          motion: true,
        );
        expect(bytes, equals(const [0x1b, 0x5b, 0x3c, 0x33, 0x32, 0x3b, 0x32, 0x3b, 0x32, 0x6d]));
      });

      test('adds modifier bits', () {
        final bytes = InputEncoder.encodeSgrMouse(
          x: 2,
          y: 3,
          button: 1,
          press: true,
          shift: true,
          alt: true,
          ctrl: true,
        );
        expect(bytes, equals(const [0x1b, 0x5b, 0x3c, 0x32, 0x39, 0x3b, 0x33, 0x3b, 0x34, 0x4d]));
      });
    });

    group('isPrintable', () {
      test('returns true for printable ASCII', () {
        expect(InputEncoder.isPrintable('a'), isTrue);
        expect(InputEncoder.isPrintable('5'), isTrue);
        expect(InputEncoder.isPrintable(' '), isTrue);
      });

      test('returns false for null or empty', () {
        expect(InputEncoder.isPrintable(null), isFalse);
        expect(InputEncoder.isPrintable(''), isFalse);
      });

      test('returns false for DEL', () {
        expect(InputEncoder.isPrintable('\x7f'), isFalse);
      });
    });

    group('encodePrintable', () {
      test('encodes ASCII as UTF-8', () {
        expect(InputEncoder.encodePrintable('a'), equals(const [0x61]));
        expect(InputEncoder.encodePrintable('Z'), equals(const [0x5a]));
      });

      test('encodes multi-byte UTF-8', () {
        expect(InputEncoder.encodePrintable('\u00e9'), equals(const [0xc3, 0xa9]));
      });
    });
  });
}
