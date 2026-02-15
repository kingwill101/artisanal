/// Key code definitions and modifier constants.
///
/// Provides a comprehensive mapping of keyboard keys and modifiers,
/// supporting both standard ANSI and extended protocols like Kitty.
///
/// {@category Ultraviolet}
/// {@subCategory Input}
///
/// {@macro artisanal_uv_events_overview}
library;

import 'dart:math' as math;

import '../unicode/grapheme.dart' as uni;

/// Modifier keys.
///
/// Upstream: `third_party/ultraviolet/key.go` (`KeyMod`).
abstract final class KeyMod {
  static const int shift = 1 << 0;
  static const int alt = 1 << 1;
  static const int ctrl = 1 << 2;
  static const int meta = 1 << 3;

  // Kitty protocol modifiers (Meta/Super swapped upstream to match XTerm mods).
  static const int hyper = 1 << 4;
  static const int superKey = 1 << 5;

  // Lock states.
  static const int capsLock = 1 << 6;
  static const int numLock = 1 << 7;
  static const int scrollLock = 1 << 8;

  static bool contains(int mods, int subset) => (mods & subset) == subset;
}

/// Upstream: `third_party/ultraviolet/key.go` (`KeyExtended`).
const int keyExtended = 0x110000; // unicode.MaxRune + 1

// Special key symbols.
//
// Upstream: `third_party/ultraviolet/key.go` (special key constants).
const int keyUp = keyExtended + 1;
const int keyDown = keyExtended + 2;
const int keyRight = keyExtended + 3;
const int keyLeft = keyExtended + 4;
const int keyBegin = keyExtended + 5;
const int keyFind = keyExtended + 6;
const int keyInsert = keyExtended + 7;
const int keyDelete = keyExtended + 8;
const int keySelect = keyExtended + 9;
const int keyPgUp = keyExtended + 10;
const int keyPgDown = keyExtended + 11;
const int keyHome = keyExtended + 12;
const int keyEnd = keyExtended + 13;

// Keypad keys.
const int keyKpEnter = keyExtended + 14;
const int keyKpEqual = keyExtended + 15;
const int keyKpMultiply = keyExtended + 16;
const int keyKpPlus = keyExtended + 17;
const int keyKpComma = keyExtended + 18;
const int keyKpMinus = keyExtended + 19;
const int keyKpDecimal = keyExtended + 20;
const int keyKpDivide = keyExtended + 21;
const int keyKp0 = keyExtended + 22;
const int keyKp1 = keyExtended + 23;
const int keyKp2 = keyExtended + 24;
const int keyKp3 = keyExtended + 25;
const int keyKp4 = keyExtended + 26;
const int keyKp5 = keyExtended + 27;
const int keyKp6 = keyExtended + 28;
const int keyKp7 = keyExtended + 29;
const int keyKp8 = keyExtended + 30;
const int keyKp9 = keyExtended + 31;

// Kitty keyboard extension (keypad keys).
const int keyKpSep = keyExtended + 32;
const int keyKpUp = keyExtended + 33;
const int keyKpDown = keyExtended + 34;
const int keyKpLeft = keyExtended + 35;
const int keyKpRight = keyExtended + 36;
const int keyKpPgUp = keyExtended + 37;
const int keyKpPgDown = keyExtended + 38;
const int keyKpHome = keyExtended + 39;
const int keyKpEnd = keyExtended + 40;
const int keyKpInsert = keyExtended + 41;
const int keyKpDelete = keyExtended + 42;
const int keyKpBegin = keyExtended + 43;

// Function keys.
const int keyF1 = keyExtended + 44;
const int keyF2 = keyExtended + 45;
const int keyF3 = keyExtended + 46;
const int keyF4 = keyExtended + 47;
const int keyF5 = keyExtended + 48;
const int keyF6 = keyExtended + 49;
const int keyF7 = keyExtended + 50;
const int keyF8 = keyExtended + 51;
const int keyF9 = keyExtended + 52;
const int keyF10 = keyExtended + 53;
const int keyF11 = keyExtended + 54;
const int keyF12 = keyExtended + 55;
const int keyF13 = keyExtended + 56;
const int keyF14 = keyExtended + 57;
const int keyF15 = keyExtended + 58;
const int keyF16 = keyExtended + 59;
const int keyF17 = keyExtended + 60;
const int keyF18 = keyExtended + 61;
const int keyF19 = keyExtended + 62;
const int keyF20 = keyExtended + 63;
const int keyF21 = keyExtended + 64;
const int keyF22 = keyExtended + 65;
const int keyF23 = keyExtended + 66;
const int keyF24 = keyExtended + 67;
const int keyF25 = keyExtended + 68;
const int keyF26 = keyExtended + 69;
const int keyF27 = keyExtended + 70;
const int keyF28 = keyExtended + 71;
const int keyF29 = keyExtended + 72;
const int keyF30 = keyExtended + 73;
const int keyF31 = keyExtended + 74;
const int keyF32 = keyExtended + 75;
const int keyF33 = keyExtended + 76;
const int keyF34 = keyExtended + 77;
const int keyF35 = keyExtended + 78;
const int keyF36 = keyExtended + 79;
const int keyF37 = keyExtended + 80;
const int keyF38 = keyExtended + 81;
const int keyF39 = keyExtended + 82;
const int keyF40 = keyExtended + 83;
const int keyF41 = keyExtended + 84;
const int keyF42 = keyExtended + 85;
const int keyF43 = keyExtended + 86;
const int keyF44 = keyExtended + 87;
const int keyF45 = keyExtended + 88;
const int keyF46 = keyExtended + 89;
const int keyF47 = keyExtended + 90;
const int keyF48 = keyExtended + 91;
const int keyF49 = keyExtended + 92;
const int keyF50 = keyExtended + 93;
const int keyF51 = keyExtended + 94;
const int keyF52 = keyExtended + 95;
const int keyF53 = keyExtended + 96;
const int keyF54 = keyExtended + 97;
const int keyF55 = keyExtended + 98;
const int keyF56 = keyExtended + 99;
const int keyF57 = keyExtended + 100;
const int keyF58 = keyExtended + 101;
const int keyF59 = keyExtended + 102;
const int keyF60 = keyExtended + 103;
const int keyF61 = keyExtended + 104;
const int keyF62 = keyExtended + 105;
const int keyF63 = keyExtended + 106;

// Kitty keyboard extension (misc keys).
const int keyCapsLock = keyExtended + 107;
const int keyScrollLock = keyExtended + 108;
const int keyNumLock = keyExtended + 109;
const int keyPrintScreen = keyExtended + 110;
const int keyPause = keyExtended + 111;
const int keyMenu = keyExtended + 112;

const int keyMediaPlay = keyExtended + 113;
const int keyMediaPause = keyExtended + 114;
const int keyMediaPlayPause = keyExtended + 115;
const int keyMediaReverse = keyExtended + 116;
const int keyMediaStop = keyExtended + 117;
const int keyMediaFastForward = keyExtended + 118;
const int keyMediaRewind = keyExtended + 119;
const int keyMediaNext = keyExtended + 120;
const int keyMediaPrev = keyExtended + 121;
const int keyMediaRecord = keyExtended + 122;

const int keyLowerVol = keyExtended + 123;
const int keyRaiseVol = keyExtended + 124;
const int keyMute = keyExtended + 125;

const int keyLeftShift = keyExtended + 126;
const int keyLeftAlt = keyExtended + 127;
const int keyLeftCtrl = keyExtended + 128;
const int keyLeftSuper = keyExtended + 129;
const int keyLeftHyper = keyExtended + 130;
const int keyLeftMeta = keyExtended + 131;
const int keyRightShift = keyExtended + 132;
const int keyRightAlt = keyExtended + 133;
const int keyRightCtrl = keyExtended + 134;
const int keyRightSuper = keyExtended + 135;
const int keyRightHyper = keyExtended + 136;
const int keyRightMeta = keyExtended + 137;
const int keyIsoLevel3Shift = keyExtended + 138;
const int keyIsoLevel5Shift = keyExtended + 139;

// C0 / G0 named keys.
const int keyBackspace = 0x7F; // DEL
const int keyTab = 0x09; // HT
const int keyEnter = 0x0D; // CR
const int keyEscape = 0x1B; // ESC
const int keySpace = 0x20; // SP

final Map<int, String> _keyTypeString = <int, String>{
  keyEnter: 'enter',
  keyTab: 'tab',
  keyBackspace: 'backspace',
  keyEscape: 'esc',
  keySpace: 'space',
  keyUp: 'up',
  keyDown: 'down',
  keyLeft: 'left',
  keyRight: 'right',
  keyBegin: 'begin',
  keyFind: 'find',
  keyInsert: 'insert',
  keyDelete: 'delete',
  keySelect: 'select',
  keyPgUp: 'pgup',
  keyPgDown: 'pgdown',
  keyHome: 'home',
  keyEnd: 'end',
  keyKpEnter: 'enter',
  keyKpEqual: 'equal',
  keyKpMultiply: 'mul',
  keyKpPlus: 'plus',
  keyKpComma: 'comma',
  keyKpMinus: 'minus',
  keyKpDecimal: 'period',
  keyKpDivide: 'div',
  keyKp0: '0',
  keyKp1: '1',
  keyKp2: '2',
  keyKp3: '3',
  keyKp4: '4',
  keyKp5: '5',
  keyKp6: '6',
  keyKp7: '7',
  keyKp8: '8',
  keyKp9: '9',

  // Kitty keyboard extension (keypad keys).
  keyKpSep: 'sep',
  keyKpUp: 'up',
  keyKpDown: 'down',
  keyKpLeft: 'left',
  keyKpRight: 'right',
  keyKpPgUp: 'pgup',
  keyKpPgDown: 'pgdown',
  keyKpHome: 'home',
  keyKpEnd: 'end',
  keyKpInsert: 'insert',
  keyKpDelete: 'delete',
  keyKpBegin: 'begin',

  keyF1: 'f1',
  keyF2: 'f2',
  keyF3: 'f3',
  keyF4: 'f4',
  keyF5: 'f5',
  keyF6: 'f6',
  keyF7: 'f7',
  keyF8: 'f8',
  keyF9: 'f9',
  keyF10: 'f10',
  keyF11: 'f11',
  keyF12: 'f12',
  keyF13: 'f13',
  keyF14: 'f14',
  keyF15: 'f15',
  keyF16: 'f16',
  keyF17: 'f17',
  keyF18: 'f18',
  keyF19: 'f19',
  keyF20: 'f20',
  keyF21: 'f21',
  keyF22: 'f22',
  keyF23: 'f23',
  keyF24: 'f24',
  keyF25: 'f25',
  keyF26: 'f26',
  keyF27: 'f27',
  keyF28: 'f28',
  keyF29: 'f29',
  keyF30: 'f30',
  keyF31: 'f31',
  keyF32: 'f32',
  keyF33: 'f33',
  keyF34: 'f34',
  keyF35: 'f35',
  keyF36: 'f36',
  keyF37: 'f37',
  keyF38: 'f38',
  keyF39: 'f39',
  keyF40: 'f40',
  keyF41: 'f41',
  keyF42: 'f42',
  keyF43: 'f43',
  keyF44: 'f44',
  keyF45: 'f45',
  keyF46: 'f46',
  keyF47: 'f47',
  keyF48: 'f48',
  keyF49: 'f49',
  keyF50: 'f50',
  keyF51: 'f51',
  keyF52: 'f52',
  keyF53: 'f53',
  keyF54: 'f54',
  keyF55: 'f55',
  keyF56: 'f56',
  keyF57: 'f57',
  keyF58: 'f58',
  keyF59: 'f59',
  keyF60: 'f60',
  keyF61: 'f61',
  keyF62: 'f62',
  keyF63: 'f63',

  // Kitty keyboard extension (misc keys).
  keyCapsLock: 'capslock',
  keyScrollLock: 'scrolllock',
  keyNumLock: 'numlock',
  keyPrintScreen: 'printscreen',
  keyPause: 'pause',
  keyMenu: 'menu',
  keyMediaPlay: 'mediaplay',
  keyMediaPause: 'mediapause',
  keyMediaPlayPause: 'mediaplaypause',
  keyMediaReverse: 'mediareverse',
  keyMediaStop: 'mediastop',
  keyMediaFastForward: 'mediafastforward',
  keyMediaRewind: 'mediarewind',
  keyMediaNext: 'medianext',
  keyMediaPrev: 'mediaprev',
  keyMediaRecord: 'mediarecord',
  keyLowerVol: 'lowervol',
  keyRaiseVol: 'raisevol',
  keyMute: 'mute',
  keyLeftShift: 'leftshift',
  keyLeftAlt: 'leftalt',
  keyLeftCtrl: 'leftctrl',
  keyLeftSuper: 'leftsuper',
  keyLeftHyper: 'lefthyper',
  keyLeftMeta: 'leftmeta',
  keyRightShift: 'rightshift',
  keyRightAlt: 'rightalt',
  keyRightCtrl: 'rightctrl',
  keyRightSuper: 'rightsuper',
  keyRightHyper: 'righthyper',
  keyRightMeta: 'rightmeta',
  keyIsoLevel3Shift: 'isolevel3shift',
  keyIsoLevel5Shift: 'isolevel5shift',
};

final Map<String, int> _stringKeyType = <String, int>{
  'enter': keyEnter,
  'tab': keyTab,
  'backspace': keyBackspace,
  'escape': keyEscape,
  'esc': keyEscape,
  'space': keySpace,
  'up': keyUp,
  'down': keyDown,
  'left': keyLeft,
  'right': keyRight,
  'begin': keyBegin,
  'find': keyFind,
  'insert': keyInsert,
  'delete': keyDelete,
  'select': keySelect,
  'pgup': keyPgUp,
  'pgdown': keyPgDown,
  'home': keyHome,
  'end': keyEnd,
  'kpenter': keyKpEnter,
  'kpequal': keyKpEqual,
  'kpmul': keyKpMultiply,
  'kpplus': keyKpPlus,
  'kpcomma': keyKpComma,
  'kpminus': keyKpMinus,
  'kpperiod': keyKpDecimal,
  'kpdiv': keyKpDivide,
  'kp0': keyKp0,
  'kp1': keyKp1,
  'kp2': keyKp2,
  'kp3': keyKp3,
  'kp4': keyKp4,
  'kp5': keyKp5,
  'kp6': keyKp6,
  'kp7': keyKp7,
  'kp8': keyKp8,
  'kp9': keyKp9,

  // Kitty keyboard extension (keypad keys).
  'kpsep': keyKpSep,
  'kpup': keyKpUp,
  'kpdown': keyKpDown,
  'kpleft': keyKpLeft,
  'kpright': keyKpRight,
  'kppgup': keyKpPgUp,
  'kppgdown': keyKpPgDown,
  'kphome': keyKpHome,
  'kpend': keyKpEnd,
  'kpinsert': keyKpInsert,
  'kpdelete': keyKpDelete,
  'kpbegin': keyKpBegin,

  'f1': keyF1,
  'f2': keyF2,
  'f3': keyF3,
  'f4': keyF4,
  'f5': keyF5,
  'f6': keyF6,
  'f7': keyF7,
  'f8': keyF8,
  'f9': keyF9,
  'f10': keyF10,
  'f11': keyF11,
  'f12': keyF12,
  'f13': keyF13,
  'f14': keyF14,
  'f15': keyF15,
  'f16': keyF16,
  'f17': keyF17,
  'f18': keyF18,
  'f19': keyF19,
  'f20': keyF20,
  'f21': keyF21,
  'f22': keyF22,
  'f23': keyF23,
  'f24': keyF24,
  'f25': keyF25,
  'f26': keyF26,
  'f27': keyF27,
  'f28': keyF28,
  'f29': keyF29,
  'f30': keyF30,
  'f31': keyF31,
  'f32': keyF32,
  'f33': keyF33,
  'f34': keyF34,
  'f35': keyF35,
  'f36': keyF36,
  'f37': keyF37,
  'f38': keyF38,
  'f39': keyF39,
  'f40': keyF40,
  'f41': keyF41,
  'f42': keyF42,
  'f43': keyF43,
  'f44': keyF44,
  'f45': keyF45,
  'f46': keyF46,
  'f47': keyF47,
  'f48': keyF48,
  'f49': keyF49,
  'f50': keyF50,
  'f51': keyF51,
  'f52': keyF52,
  'f53': keyF53,
  'f54': keyF54,
  'f55': keyF55,
  'f56': keyF56,
  'f57': keyF57,
  'f58': keyF58,
  'f59': keyF59,
  'f60': keyF60,
  'f61': keyF61,
  'f62': keyF62,
  'f63': keyF63,

  // Kitty keyboard extension (misc keys).
  'capslock': keyCapsLock,
  'scrolllock': keyScrollLock,
  'numlock': keyNumLock,
  'printscreen': keyPrintScreen,
  'pause': keyPause,
  'menu': keyMenu,
  'mediaplay': keyMediaPlay,
  'mediapause': keyMediaPause,
  'mediaplaypause': keyMediaPlayPause,
  'mediareverse': keyMediaReverse,
  'mediastop': keyMediaStop,
  'mediafastforward': keyMediaFastForward,
  'mediarewind': keyMediaRewind,
  'medianext': keyMediaNext,
  'mediaprev': keyMediaPrev,
  'mediarecord': keyMediaRecord,
  'lowervol': keyLowerVol,
  'raisevol': keyRaiseVol,
  'mute': keyMute,
  'leftshift': keyLeftShift,
  'leftalt': keyLeftAlt,
  'leftctrl': keyLeftCtrl,
  'leftsuper': keyLeftSuper,
  'lefthyper': keyLeftHyper,
  'leftmeta': keyLeftMeta,
  'rightshift': keyRightShift,
  'rightalt': keyRightAlt,
  'rightctrl': keyRightCtrl,
  'rightsuper': keyRightSuper,
  'righthyper': keyRightHyper,
  'rightmeta': keyRightMeta,
  'isolevel3shift': keyIsoLevel3Shift,
  'isolevel5shift': keyIsoLevel5Shift,
};

/// UV-style key event.
///
/// Upstream: `third_party/ultraviolet/key.go` (`Key`).
final class Key {
  const Key({
    this.text = '',
    this.mod = 0,
    required this.code,
    this.shiftedCode = 0,
    this.baseCode = 0,
    this.isRepeat = false,
  });

  final String text;
  final int mod;
  final int code;
  final int shiftedCode;
  final int baseCode;
  final bool isRepeat;

  bool matchString(
    String s, [
    String? s2,
    String? s3,
    String? s4,
    String? s5,
  ]) => matchStrings([
    s,
    if (s2 != null) s2,
    if (s3 != null) s3,
    if (s4 != null) s4,
    if (s5 != null) s5,
  ]);

  bool matchStrings(Iterable<String> patterns) {
    for (final p in patterns) {
      if (_keyMatchString(this, p)) return true;
    }
    return false;
  }

  String keystroke() {
    final sb = StringBuffer();

    if (KeyMod.contains(mod, KeyMod.ctrl) &&
        code != keyLeftCtrl &&
        code != keyRightCtrl) {
      sb.write('ctrl+');
    }
    if (KeyMod.contains(mod, KeyMod.alt) &&
        code != keyLeftAlt &&
        code != keyRightAlt) {
      sb.write('alt+');
    }
    if (KeyMod.contains(mod, KeyMod.shift) &&
        code != keyLeftShift &&
        code != keyRightShift) {
      sb.write('shift+');
    }
    if (KeyMod.contains(mod, KeyMod.meta) &&
        code != keyLeftMeta &&
        code != keyRightMeta) {
      sb.write('meta+');
    }
    if (KeyMod.contains(mod, KeyMod.hyper) &&
        code != keyLeftHyper &&
        code != keyRightHyper) {
      sb.write('hyper+');
    }
    if (KeyMod.contains(mod, KeyMod.superKey) &&
        code != keyLeftSuper &&
        code != keyRightSuper) {
      sb.write('super+');
    }

    final name = _keyTypeString[code];
    if (name != null) {
      sb.write(name);
      return sb.toString();
    }

    var c = code;
    if (baseCode != 0) c = baseCode;

    switch (c) {
      case keySpace:
        sb.write('space');
      case keyExtended:
        sb.write(text);
      default:
        sb.write(String.fromCharCode(c));
    }
    return sb.toString();
  }

  @override
  String toString() {
    if (text.isNotEmpty && text != ' ') return text;
    return keystroke();
  }

  @override
  bool operator ==(Object other) =>
      other is Key &&
      other.text == text &&
      other.mod == mod &&
      other.code == code &&
      other.shiftedCode == shiftedCode &&
      other.baseCode == baseCode &&
      other.isRepeat == isRepeat;

  @override
  int get hashCode =>
      Object.hash(text, mod, code, shiftedCode, baseCode, isRepeat);
}

bool _keyMatchString(Key k, String s) {
  var mod = 0;
  var code = 0;
  var text = '';

  final parts = s.split('+');
  for (final part in parts) {
    switch (part) {
      case 'ctrl':
        mod |= KeyMod.ctrl;
      case 'alt':
        mod |= KeyMod.alt;
      case 'shift':
        mod |= KeyMod.shift;
      case 'meta':
        mod |= KeyMod.meta;
      case 'hyper':
        mod |= KeyMod.hyper;
      case 'super':
        mod |= KeyMod.superKey;
      case 'capslock':
        mod |= KeyMod.capsLock;
      case 'scrolllock':
        mod |= KeyMod.scrollLock;
      case 'numlock':
        mod |= KeyMod.numLock;
      default:
        final kt = _stringKeyType[part];
        if (kt != null) {
          code = kt;
        } else {
          final cps = uni.codePoints(part);
          if (cps.length == 1) {
            code = cps[0];
          } else {
            code = keyExtended;
            text = part;
          }
        }
    }
  }

  // Printable character matching.
  final smod = mod & ~(KeyMod.shift | KeyMod.capsLock);
  if (smod == 0 && text.isEmpty && _isPrintable(code)) {
    if ((mod & (KeyMod.shift | KeyMod.capsLock)) != 0) {
      text = String.fromCharCode(code).toUpperCase();
    } else {
      text = String.fromCharCode(code);
    }
  }

  return (k.mod == mod && k.code == code) ||
      (k.text.isNotEmpty && k.text == text);
}

bool _isPrintable(int codePoint) {
  if (codePoint <= 0) return false;
  if (codePoint > 0x10ffff) return false;
  // Surrogates are never valid scalar values.
  if (codePoint >= 0xD800 && codePoint <= 0xDFFF) return false;
  // Treat all non-control code points as printable (best-effort).
  if (codePoint < 0x20) return false;
  if (codePoint == 0x7F) return false;
  return true;
}

/// Converts a 1-based XTerm modifier value to a UV `KeyMod` bitmask.
///
/// Upstream: `third_party/ultraviolet/decoder.go` (`KeyMod(mod-1)`).
int keyModFromXTerm(int xtermModMinus1) {
  // XTerm modifier bits: 1=shift, 2=alt, 4=ctrl, 8=meta, 16=... etc.
  var m = 0;
  final v = math.max(0, xtermModMinus1);
  if ((v & 1) != 0) m |= KeyMod.shift;
  if ((v & 2) != 0) m |= KeyMod.alt;
  if ((v & 4) != 0) m |= KeyMod.ctrl;
  if ((v & 8) != 0) m |= KeyMod.meta;
  if ((v & 16) != 0) m |= KeyMod.superKey;
  if ((v & 32) != 0) m |= KeyMod.hyper;
  return m;
}
