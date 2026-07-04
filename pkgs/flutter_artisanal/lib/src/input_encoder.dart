import 'dart:convert';

import 'package:flutter/services.dart';

class InputEncoder {
  static List<int> encodeSpecialKey(LogicalKeyboardKey key) {
    return _specialKeyMap[key] ?? <int>[];
  }

  static bool isPrintable(String? character) {
    if (character == null || character.isEmpty) return false;
    final codeUnit = character.codeUnitAt(0);
    return codeUnit >= 0x20 && codeUnit != 0x7f;
  }

  static List<int> encodePrintable(String character) {
    return utf8.encode(character);
  }

  static List<int> encodeSgrMouse({
    required int x,
    required int y,
    required int button,
    required bool press,
    bool motion = false,
    bool shift = false,
    bool alt = false,
    bool ctrl = false,
  }) {
    var b = button;
    if (shift) b |= 4;
    if (alt) b |= 8;
    if (ctrl) b |= 16;
    if (motion) b |= 32;

    final terminator = press ? 0x4d : 0x6d;
    final encoded = <int>[
      0x1b,
      0x5b,
      ...'<$b;${x + 1};${y + 1}'.codeUnits,
      terminator,
    ];
    return encoded;
  }

  static final _specialKeyMap = <LogicalKeyboardKey, List<int>>{
    LogicalKeyboardKey.escape: [0x1b],
    LogicalKeyboardKey.enter: [0x0d],
    LogicalKeyboardKey.backspace: [0x7f],
    LogicalKeyboardKey.tab: [0x09],
    LogicalKeyboardKey.arrowUp: [0x1b, 0x5b, 0x41],
    LogicalKeyboardKey.arrowDown: [0x1b, 0x5b, 0x42],
    LogicalKeyboardKey.arrowRight: [0x1b, 0x5b, 0x43],
    LogicalKeyboardKey.arrowLeft: [0x1b, 0x5b, 0x44],
    LogicalKeyboardKey.home: [0x1b, 0x5b, 0x48],
    LogicalKeyboardKey.end: [0x1b, 0x5b, 0x46],
    LogicalKeyboardKey.delete: [0x1b, 0x5b, 0x33, 0x7e],
    LogicalKeyboardKey.insert: [0x1b, 0x5b, 0x32, 0x7e],
    LogicalKeyboardKey.pageUp: [0x1b, 0x5b, 0x35, 0x7e],
    LogicalKeyboardKey.pageDown: [0x1b, 0x5b, 0x36, 0x7e],
    LogicalKeyboardKey.f1: [0x1b, 0x4f, 0x50],
    LogicalKeyboardKey.f2: [0x1b, 0x4f, 0x51],
    LogicalKeyboardKey.f3: [0x1b, 0x4f, 0x52],
    LogicalKeyboardKey.f4: [0x1b, 0x4f, 0x53],
    LogicalKeyboardKey.f5: [0x1b, 0x5b, 0x31, 0x35, 0x7e],
    LogicalKeyboardKey.f6: [0x1b, 0x5b, 0x31, 0x37, 0x7e],
    LogicalKeyboardKey.f7: [0x1b, 0x5b, 0x31, 0x38, 0x7e],
    LogicalKeyboardKey.f8: [0x1b, 0x5b, 0x31, 0x39, 0x7e],
    LogicalKeyboardKey.f9: [0x1b, 0x5b, 0x32, 0x30, 0x7e],
    LogicalKeyboardKey.f10: [0x1b, 0x5b, 0x32, 0x31, 0x7e],
    LogicalKeyboardKey.f11: [0x1b, 0x5b, 0x32, 0x33, 0x7e],
    LogicalKeyboardKey.f12: [0x1b, 0x5b, 0x32, 0x34, 0x7e],
  };
}
