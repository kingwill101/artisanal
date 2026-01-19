import 'package:artisanal/src/uv/decoder.dart';
import 'package:artisanal/src/uv/event.dart';
import 'package:artisanal/src/uv/key.dart';
import 'package:artisanal/src/uv/key_table.dart';
import 'package:test/test.dart';

void main() {
  group('Key table', () {
    group('C0 control codes with default flags', () {
      late Map<String, Key> table;

      setUp(() {
        table = buildKeysTable(const LegacyKeyEncoding(), '');
      });

      test('LF (0x0A) maps to Enter by default', () {
        final key = table['\x0a'];
        expect(key, isNotNull);
        expect(key!.code, keyEnter);
        expect(key.mod, 0); // No modifiers
      });

      test('CR (0x0D) maps to Enter by default', () {
        final key = table['\x0d'];
        expect(key, isNotNull);
        expect(key!.code, keyEnter);
        expect(key.mod, 0);
      });

      test('Tab (0x09) maps to Tab by default', () {
        final key = table['\x09'];
        expect(key, isNotNull);
        expect(key!.code, keyTab);
        expect(key.mod, 0);
      });

      test('ESC (0x1B) maps to Escape by default', () {
        final key = table['\x1b'];
        expect(key, isNotNull);
        expect(key!.code, keyEscape);
        expect(key.mod, 0);
      });

      test('DEL (0x7F) maps to Backspace by default', () {
        final key = table['\x7f'];
        expect(key, isNotNull);
        expect(key!.code, keyBackspace);
        expect(key.mod, 0);
      });

      test('plain j (0x6A) is not in C0 table', () {
        // Plain 'j' is a printable character, not a C0 control code
        final key = table['j'];
        expect(key, isNull);
      });
    });

    group('C0 control codes with legacy flags', () {
      test('LF (0x0A) maps to Ctrl+J when ctrlJ flag is set', () {
        final table = buildKeysTable(const LegacyKeyEncoding().ctrlJ(true), '');
        final key = table['\x0a'];
        expect(key, isNotNull);
        expect(key!.code, 'j'.codeUnitAt(0));
        expect(key.mod, KeyMod.ctrl);
      });

      test('CR (0x0D) maps to Ctrl+M when ctrlM flag is set', () {
        final table = buildKeysTable(const LegacyKeyEncoding().ctrlM(true), '');
        final key = table['\x0d'];
        expect(key, isNotNull);
        expect(key!.code, 'm'.codeUnitAt(0));
        expect(key.mod, KeyMod.ctrl);
      });

      test('Tab (0x09) maps to Ctrl+I when ctrlI flag is set', () {
        final table = buildKeysTable(const LegacyKeyEncoding().ctrlI(true), '');
        final key = table['\x09'];
        expect(key, isNotNull);
        expect(key!.code, 'i'.codeUnitAt(0));
        expect(key.mod, KeyMod.ctrl);
      });

      test('ESC (0x1B) maps to Ctrl+[ when ctrlOpenBracket flag is set', () {
        final table = buildKeysTable(
          const LegacyKeyEncoding().ctrlOpenBracket(true),
          '',
        );
        final key = table['\x1b'];
        expect(key, isNotNull);
        expect(key!.code, '['.codeUnitAt(0));
        expect(key.mod, KeyMod.ctrl);
      });
    });

    group('Consistency between key_table and decoder', () {
      test('LF produces same result from table and decoder (default)', () {
        final table = buildKeysTable(const LegacyKeyEncoding(), '');
        final decoder = EventDecoder();

        final tableKey = table['\x0a']!;
        final decoderEvent = decoder.parseControl(0x0a);
        final decoderKey = (decoderEvent as KeyPressEvent).key();

        expect(tableKey.code, decoderKey.code);
        expect(tableKey.mod, decoderKey.mod);
      });

      test('CR produces same result from table and decoder (default)', () {
        final table = buildKeysTable(const LegacyKeyEncoding(), '');
        final decoder = EventDecoder();

        final tableKey = table['\x0d']!;
        final decoderEvent = decoder.parseControl(0x0d);
        final decoderKey = (decoderEvent as KeyPressEvent).key();

        expect(tableKey.code, decoderKey.code);
        expect(tableKey.mod, decoderKey.mod);
      });

      test('LF produces same result from table and decoder (ctrlJ flag)', () {
        final legacy = const LegacyKeyEncoding().ctrlJ(true);
        final table = buildKeysTable(legacy, '');
        final decoder = EventDecoder(legacy: legacy);

        final tableKey = table['\x0a']!;
        final decoderEvent = decoder.parseControl(0x0a);
        final decoderKey = (decoderEvent as KeyPressEvent).key();

        expect(tableKey.code, decoderKey.code);
        expect(tableKey.mod, decoderKey.mod);
      });

      test('CR produces same result from table and decoder (ctrlM flag)', () {
        final legacy = const LegacyKeyEncoding().ctrlM(true);
        final table = buildKeysTable(legacy, '');
        final decoder = EventDecoder(legacy: legacy);

        final tableKey = table['\x0d']!;
        final decoderEvent = decoder.parseControl(0x0d);
        final decoderKey = (decoderEvent as KeyPressEvent).key();

        expect(tableKey.code, decoderKey.code);
        expect(tableKey.mod, decoderKey.mod);
      });

      test('Tab produces same result from table and decoder (default)', () {
        final table = buildKeysTable(const LegacyKeyEncoding(), '');
        final decoder = EventDecoder();

        final tableKey = table['\x09']!;
        final decoderEvent = decoder.parseControl(0x09);
        final decoderKey = (decoderEvent as KeyPressEvent).key();

        expect(tableKey.code, decoderKey.code);
        expect(tableKey.mod, decoderKey.mod);
      });
    });
  });
}
