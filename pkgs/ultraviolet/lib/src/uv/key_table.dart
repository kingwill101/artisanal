/// Mapping of escape sequences to keys.
///
/// Contains the logic for building lookup tables that map raw terminal
/// escape sequences to high-level [Key] objects.
///
/// {@category Ultraviolet}
/// {@subCategory Input}
///
/// {@macro artisanal_uv_events_overview}
library;

import 'key.dart';
import 'decoder.dart';

/// Builds a table of key sequences and their corresponding key events.
///
Map<String, Key> buildKeysTable(
  LegacyKeyEncoding flags,
  String term, {
  bool useTerminfo = false,
}) {
  final nul = Key(code: keySpace, mod: KeyMod.ctrl); // ctrl+@ or ctrl+space
  final nulKey = flags.bits & 0x01 != 0
      ? Key(code: '@'.codeUnitAt(0), mod: KeyMod.ctrl)
      : nul;

  final tab = Key(code: keyTab); // ctrl+i or tab
  final tabKey = flags.bits & 0x02 != 0
      ? Key(code: 'i'.codeUnitAt(0), mod: KeyMod.ctrl)
      : tab;

  final enter = Key(code: keyEnter); // ctrl+m or enter
  final enterKey = flags.bits & 0x04 != 0
      ? Key(code: 'm'.codeUnitAt(0), mod: KeyMod.ctrl)
      : enter;

  // LF (0x0A) - ctrl+j or enter (newline)
  final lfKey = flags.bits & 0x100 != 0
      ? Key(code: 'j'.codeUnitAt(0), mod: KeyMod.ctrl)
      : enter;

  final esc = Key(code: keyEscape); // ctrl+[ or escape
  final escKey = flags.bits & 0x08 != 0
      ? Key(code: '['.codeUnitAt(0), mod: KeyMod.ctrl)
      : esc;

  var delCode = keyBackspace;
  if (flags.bits & 0x10 != 0) {
    delCode = keyDelete;
  }
  final del = Key(code: delCode);

  var findCode = keyHome;
  if (flags.bits & 0x20 != 0) {
    findCode = keyFind;
  }
  final find = Key(code: findCode);

  var selCode = keyEnd;
  if (flags.bits & 0x40 != 0) {
    selCode = keySelect;
  }
  final sel = Key(code: selCode);

  final table = <String, Key>{
    // C0 control characters (0x00-0x1F, 0x7F)
    //
    // NOTE: These entries are primarily for documentation and consistency.
    // The decoder (`decoder.dart`) handles all C0 bytes directly in
    // `parseControl()` and always returns a KeyPressEvent, never an
    // UnknownEvent. Since this table is only consulted for UnknownEvents
    // (see `tui_adapter.dart`), these C0 entries are not reached during
    // normal operation.
    //
    // They are retained for:
    // 1. Documentation of what each C0 byte represents
    // 2. Reference for `buildKeysTable()` when building Alt-modified variants
    // 3. Fallback consistency if decoder behavior ever changes
    '\x00': nulKey,
    '\x01': Key(code: 'a'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x02': Key(code: 'b'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x03': Key(code: 'c'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x04': Key(code: 'd'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x05': Key(code: 'e'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x06': Key(code: 'f'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x07': Key(code: 'g'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x08': Key(code: 'h'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x09': tabKey,
    '\x0a': lfKey,
    '\x0b': Key(code: 'k'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x0c': Key(code: 'l'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x0d': enterKey,
    '\x0e': Key(code: 'n'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x0f': Key(code: 'o'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x10': Key(code: 'p'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x11': Key(code: 'q'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x12': Key(code: 'r'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x13': Key(code: 's'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x14': Key(code: 't'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x15': Key(code: 'u'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x16': Key(code: 'v'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x17': Key(code: 'w'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x18': Key(code: 'x'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x19': Key(code: 'y'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x1a': Key(code: 'z'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x1b': escKey,
    '\x1c': Key(code: '\\'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x1d': Key(code: ']'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x1e': Key(code: '^'.codeUnitAt(0), mod: KeyMod.ctrl),
    '\x1f': Key(code: '_'.codeUnitAt(0), mod: KeyMod.ctrl),

    // Special keys in G0
    ' ': Key(code: keySpace, text: ' '),
    '\x7f': del,

    // Special keys
    '\x1b[Z': Key(code: keyTab, mod: KeyMod.shift),

    '\x1b[1~': find,
    '\x1b[2~': Key(code: keyInsert),
    '\x1b[3~': Key(code: keyDelete),
    '\x1b[4~': sel,
    '\x1b[5~': Key(code: keyPgUp),
    '\x1b[6~': Key(code: keyPgDown),
    '\x1b[7~': Key(code: keyHome),
    '\x1b[8~': Key(code: keyEnd),

    // Normal mode
    '\x1b[A': Key(code: keyUp),
    '\x1b[B': Key(code: keyDown),
    '\x1b[C': Key(code: keyRight),
    '\x1b[D': Key(code: keyLeft),
    '\x1b[E': Key(code: keyBegin),
    '\x1b[F': Key(code: keyEnd),
    '\x1b[H': Key(code: keyHome),
    '\x1b[P': Key(code: keyF1),
    '\x1b[Q': Key(code: keyF2),
    '\x1b[R': Key(code: keyF3),
    '\x1b[S': Key(code: keyF4),

    // Application Cursor Key Mode (DECCKM)
    '\x1bOA': Key(code: keyUp),
    '\x1bOB': Key(code: keyDown),
    '\x1bOC': Key(code: keyRight),
    '\x1bOD': Key(code: keyLeft),
    '\x1bOE': Key(code: keyBegin),
    '\x1bOF': Key(code: keyEnd),
    '\x1bOH': Key(code: keyHome),
    '\x1bOP': Key(code: keyF1),
    '\x1bOQ': Key(code: keyF2),
    '\x1bOR': Key(code: keyF3),
    '\x1bOS': Key(code: keyF4),

    // Keypad Application Mode (DECKPAM)
    '\x1bOM': Key(code: keyKpEnter),
    '\x1bOX': Key(code: keyKpEqual),
    '\x1bOj': Key(code: keyKpMultiply),
    '\x1bOk': Key(code: keyKpPlus),
    '\x1bOl': Key(code: keyKpComma),
    '\x1bOm': Key(code: keyKpMinus),
    '\x1bOn': Key(code: keyKpDecimal),
    '\x1bOo': Key(code: keyKpDivide),
    '\x1bOp': Key(code: keyKp0),
    '\x1bOq': Key(code: keyKp1),
    '\x1bOr': Key(code: keyKp2),
    '\x1bOs': Key(code: keyKp3),
    '\x1bOt': Key(code: keyKp4),
    '\x1bOu': Key(code: keyKp5),
    '\x1bOv': Key(code: keyKp6),
    '\x1bOw': Key(code: keyKp7),
    '\x1bOx': Key(code: keyKp8),
    '\x1bOy': Key(code: keyKp9),

    // Function keys
    '\x1b[11~': Key(code: keyF1),
    '\x1b[12~': Key(code: keyF2),
    '\x1b[13~': Key(code: keyF3),
    '\x1b[14~': Key(code: keyF4),
    '\x1b[15~': Key(code: keyF5),
    '\x1b[17~': Key(code: keyF6),
    '\x1b[18~': Key(code: keyF7),
    '\x1b[19~': Key(code: keyF8),
    '\x1b[20~': Key(code: keyF9),
    '\x1b[21~': Key(code: keyF10),
    '\x1b[23~': Key(code: keyF11),
    '\x1b[24~': Key(code: keyF12),
    '\x1b[25~': Key(code: keyF13),
    '\x1b[26~': Key(code: keyF14),
    '\x1b[28~': Key(code: keyF15),
    '\x1b[29~': Key(code: keyF16),
    '\x1b[31~': Key(code: keyF17),
    '\x1b[32~': Key(code: keyF18),
    '\x1b[33~': Key(code: keyF19),
    '\x1b[34~': Key(code: keyF20),
  };

  final csiTildeKeys = <String, Key>{
    '1': find,
    '2': Key(code: keyInsert),
    '3': Key(code: keyDelete),
    '4': sel,
    '5': Key(code: keyPgUp),
    '6': Key(code: keyPgDown),
    '7': Key(code: keyHome),
    '8': Key(code: keyEnd),
    '11': Key(code: keyF1),
    '12': Key(code: keyF2),
    '13': Key(code: keyF3),
    '14': Key(code: keyF4),
    '15': Key(code: keyF5),
    '17': Key(code: keyF6),
    '18': Key(code: keyF7),
    '19': Key(code: keyF8),
    '20': Key(code: keyF9),
    '21': Key(code: keyF10),
    '23': Key(code: keyF11),
    '24': Key(code: keyF12),
    '25': Key(code: keyF13),
    '26': Key(code: keyF14),
    '28': Key(code: keyF15),
    '29': Key(code: keyF16),
    '31': Key(code: keyF17),
    '32': Key(code: keyF18),
    '33': Key(code: keyF19),
    '34': Key(code: keyF20),
  };

  // URxvt keys
  table['\x1b[a'] = Key(code: keyUp, mod: KeyMod.shift);
  table['\x1b[b'] = Key(code: keyDown, mod: KeyMod.shift);
  table['\x1b[c'] = Key(code: keyRight, mod: KeyMod.shift);
  table['\x1b[d'] = Key(code: keyLeft, mod: KeyMod.shift);
  table['\x1bOa'] = Key(code: keyUp, mod: KeyMod.ctrl);
  table['\x1bOb'] = Key(code: keyDown, mod: KeyMod.ctrl);
  table['\x1bOc'] = Key(code: keyRight, mod: KeyMod.ctrl);
  table['\x1bOd'] = Key(code: keyLeft, mod: KeyMod.ctrl);

  for (final entry in csiTildeKeys.entries) {
    final k = entry.key;
    final v = entry.value;

    table['\x1b[$k\$'] = Key(code: v.code, mod: KeyMod.shift);
    table['\x1b[$k^'] = Key(code: v.code, mod: KeyMod.ctrl);
    table['\x1b[$k@'] = Key(code: v.code, mod: KeyMod.shift | KeyMod.ctrl);
  }

  table['\x1b[23\$'] = Key(code: keyF11, mod: KeyMod.shift);
  table['\x1b[24\$'] = Key(code: keyF12, mod: KeyMod.shift);
  table['\x1b[25\$'] = Key(code: keyF13, mod: KeyMod.shift);
  table['\x1b[26\$'] = Key(code: keyF14, mod: KeyMod.shift);
  table['\x1b[28\$'] = Key(code: keyF15, mod: KeyMod.shift);
  table['\x1b[29\$'] = Key(code: keyF16, mod: KeyMod.shift);
  table['\x1b[31\$'] = Key(code: keyF17, mod: KeyMod.shift);
  table['\x1b[32\$'] = Key(code: keyF18, mod: KeyMod.shift);
  table['\x1b[33\$'] = Key(code: keyF19, mod: KeyMod.shift);
  table['\x1b[34\$'] = Key(code: keyF20, mod: KeyMod.shift);

  table['\x1b[11^'] = Key(code: keyF1, mod: KeyMod.ctrl);
  table['\x1b[12^'] = Key(code: keyF2, mod: KeyMod.ctrl);
  table['\x1b[13^'] = Key(code: keyF3, mod: KeyMod.ctrl);
  table['\x1b[14^'] = Key(code: keyF4, mod: KeyMod.ctrl);
  table['\x1b[15^'] = Key(code: keyF5, mod: KeyMod.ctrl);
  table['\x1b[17^'] = Key(code: keyF6, mod: KeyMod.ctrl);
  table['\x1b[18^'] = Key(code: keyF7, mod: KeyMod.ctrl);
  table['\x1b[19^'] = Key(code: keyF8, mod: KeyMod.ctrl);
  table['\x1b[20^'] = Key(code: keyF9, mod: KeyMod.ctrl);
  table['\x1b[21^'] = Key(code: keyF10, mod: KeyMod.ctrl);
  table['\x1b[23^'] = Key(code: keyF11, mod: KeyMod.ctrl);
  table['\x1b[24^'] = Key(code: keyF12, mod: KeyMod.ctrl);
  table['\x1b[25^'] = Key(code: keyF13, mod: KeyMod.ctrl);
  table['\x1b[26^'] = Key(code: keyF14, mod: KeyMod.ctrl);
  table['\x1b[28^'] = Key(code: keyF15, mod: KeyMod.ctrl);
  table['\x1b[29^'] = Key(code: keyF16, mod: KeyMod.ctrl);
  table['\x1b[31^'] = Key(code: keyF17, mod: KeyMod.ctrl);
  table['\x1b[32^'] = Key(code: keyF18, mod: KeyMod.ctrl);
  table['\x1b[33^'] = Key(code: keyF19, mod: KeyMod.ctrl);
  table['\x1b[34^'] = Key(code: keyF20, mod: KeyMod.ctrl);

  table['\x1b[23@'] = Key(code: keyF11, mod: KeyMod.shift | KeyMod.ctrl);
  table['\x1b[24@'] = Key(code: keyF12, mod: KeyMod.shift | KeyMod.ctrl);
  table['\x1b[25@'] = Key(code: keyF13, mod: KeyMod.shift | KeyMod.ctrl);
  table['\x1b[26@'] = Key(code: keyF14, mod: KeyMod.shift | KeyMod.ctrl);
  table['\x1b[28@'] = Key(code: keyF15, mod: KeyMod.shift | KeyMod.ctrl);
  table['\x1b[29@'] = Key(code: keyF16, mod: KeyMod.shift | KeyMod.ctrl);
  table['\x1b[31@'] = Key(code: keyF17, mod: KeyMod.shift | KeyMod.ctrl);
  table['\x1b[32@'] = Key(code: keyF18, mod: KeyMod.shift | KeyMod.ctrl);
  table['\x1b[33@'] = Key(code: keyF19, mod: KeyMod.shift | KeyMod.ctrl);
  table['\x1b[34@'] = Key(code: keyF20, mod: KeyMod.shift | KeyMod.ctrl);

  final tmap = <String, Key>{};
  for (final entry in table.entries) {
    final seq = entry.key;
    final key = entry.value;
    tmap['\x1b$seq'] = Key(code: key.code, mod: key.mod | KeyMod.alt);
  }
  table.addAll(tmap);

  final modifiers = [
    KeyMod.shift, // 1
    KeyMod.alt, // 2
    KeyMod.shift | KeyMod.alt, // 3
    KeyMod.ctrl, // 4
    KeyMod.shift | KeyMod.ctrl, // 5
    KeyMod.alt | KeyMod.ctrl, // 6
    KeyMod.shift | KeyMod.alt | KeyMod.ctrl, // 7
    KeyMod.meta, // 8
    KeyMod.meta | KeyMod.shift, // 9
    KeyMod.meta | KeyMod.alt, // 10
    KeyMod.meta | KeyMod.shift | KeyMod.alt, // 11
    KeyMod.meta | KeyMod.ctrl, // 12
    KeyMod.meta | KeyMod.shift | KeyMod.ctrl, // 13
    KeyMod.meta | KeyMod.alt | KeyMod.ctrl, // 14
    KeyMod.meta | KeyMod.shift | KeyMod.alt | KeyMod.ctrl, // 15
  ];

  final ss3FuncKeys = <String, Key>{
    'M': Key(code: keyKpEnter),
    'X': Key(code: keyKpEqual),
    'j': Key(code: keyKpMultiply),
    'k': Key(code: keyKpPlus),
    'l': Key(code: keyKpComma),
    'm': Key(code: keyKpMinus),
    'n': Key(code: keyKpDecimal),
    'o': Key(code: keyKpDivide),
    'p': Key(code: keyKp0),
    'q': Key(code: keyKp1),
    'r': Key(code: keyKp2),
    's': Key(code: keyKp3),
    't': Key(code: keyKp4),
    'u': Key(code: keyKp5),
    'v': Key(code: keyKp6),
    'w': Key(code: keyKp7),
    'x': Key(code: keyKp8),
    'y': Key(code: keyKp9),
  };

  final csiFuncKeys = <String, Key>{
    'A': Key(code: keyUp),
    'B': Key(code: keyDown),
    'C': Key(code: keyRight),
    'D': Key(code: keyLeft),
    'E': Key(code: keyBegin),
    'F': Key(code: keyEnd),
    'H': Key(code: keyHome),
    'P': Key(code: keyF1),
    'Q': Key(code: keyF2),
    'R': Key(code: keyF3),
    'S': Key(code: keyF4),
  };

  final modifyOtherKeys = <int, Key>{
    0x08: Key(code: keyBackspace), // BS
    0x09: Key(code: keyTab), // HT
    0x0d: Key(code: keyEnter), // CR
    0x1b: Key(code: keyEscape), // ESC
    0x7f: Key(code: keyBackspace), // DEL
  };

  for (var i = 0; i < modifiers.length; i++) {
    final m = modifiers[i];
    final xtermMod = (i + 2).toString();

    for (final entry in csiFuncKeys.entries) {
      table['\x1b[1;$xtermMod${entry.key}'] = Key(
        code: entry.value.code,
        mod: m,
      );
    }
    for (final entry in ss3FuncKeys.entries) {
      table['\x1bO$xtermMod${entry.key}'] = Key(code: entry.value.code, mod: m);
    }
    for (final entry in csiTildeKeys.entries) {
      table['\x1b[${entry.key};$xtermMod~'] = Key(
        code: entry.value.code,
        mod: m,
      );
    }
    for (final entry in modifyOtherKeys.entries) {
      table['\x1b[27;$xtermMod;${entry.key}~'] = Key(
        code: entry.value.code,
        mod: m,
      );
    }
  }

  return table;
}
