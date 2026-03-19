/// Adapts UV events to other TUI frameworks.
///
/// Provides a compatibility layer for translating Ultraviolet [Event]s into
/// message types used by the core `artisanal` TUI framework.
///
/// {@category Ultraviolet}
/// {@subCategory Compatibility}
///
/// {@macro artisanal_uv_compatibility}
library;

import '../../tui.dart';
import '../terminal/keys.dart' as term;
import '../unicode/grapheme.dart' as uni;
import 'decoder.dart';
import 'event.dart' as uvev;
import 'event_stream.dart';
import 'key.dart' as uvk;
import 'key_table.dart';
import 'mouse.dart' as uvm;

/// Adapts Ultraviolet-style input events to the current TUI message types.
///
/// This is an opt-in compatibility layer so the TUI runtime can consume the UV
/// decoder without rewriting the entire Msg/Key pipeline.
final class UvTuiInputParser {
  UvTuiInputParser({
    EventDecoder? decoder,
    LegacyKeyEncoding? legacy,
    String term = '',
    bool useTerminfo = false,
  }) : _decoder =
           decoder ??
           EventDecoder(
             legacy: legacy ?? const LegacyKeyEncoding(),
             useTerminfo: useTerminfo,
           ) {
    _events = UvEventStreamParser(decoder: _decoder);
    _table = buildKeysTable(
      _decoder.legacy,
      term,
      useTerminfo: _decoder.useTerminfo,
    );
  }

  final EventDecoder _decoder;
  late final UvEventStreamParser _events;
  late final Map<String, uvk.Key> _table;

  bool get hasPending => _events.hasPending;

  /// Parses raw input bytes and returns translated TUI [Msg] instances.
  ///
  /// The parser buffers incomplete sequences across calls.
  ///
  /// When [expired] is true, the parser flushes incomplete sequences (e.g. on
  /// EOF or after an escape timeout).
  List<Msg> parseAll(List<int> bytes, {bool expired = false}) {
    final out = <Msg>[];
    final evs = _events.parseAll(bytes, expired: expired);
    for (final ev in evs) {
      if (ev is uvev.UnknownEvent) {
        final mapped = _table[ev.value];
        if (mapped != null) {
          out.add(KeyMsg(_toTermKey(mapped)));
          continue;
        }
      }
      if (ev is uvev.PasteEvent) {
        out.add(PasteMsg(ev.content));
        continue;
      }
      final msgs = _eventToMsgs(ev);
      if (msgs.isEmpty) {
        out.add(UvEventMsg(ev));
      } else {
        out.addAll(msgs);
      }
    }

    return out;
  }

  void clear() {
    _events.clear();
  }
}

List<Msg> _eventToMsgs(uvev.Event ev) {
  if (ev is uvev.IgnoredEvent) return const [];
  if (ev is uvev.MultiEvent) {
    final out = <Msg>[];
    for (final e in ev.events) {
      out.addAll(_eventToMsgs(e));
    }
    return out;
  }

  if (ev is uvev.KeyPressEvent) {
    return [KeyMsg(_toTermKey(ev.key()))];
  }

  if (ev is uvev.FocusEvent) return const [FocusMsg(true)];
  if (ev is uvev.BlurEvent) return const [FocusMsg(false)];
  if (ev is uvev.DarkColorSchemeEvent) {
    return const [ColorSchemeMsg(dark: true)];
  }
  if (ev is uvev.LightColorSchemeEvent) {
    return const [ColorSchemeMsg(dark: false)];
  }

  if (ev is uvev.WindowSizeEvent) {
    return [WindowSizeMsg(ev.width, ev.height)];
  }
  if (ev is uvev.Size) return [WindowSizeMsg(ev.width, ev.height)];
  if (ev is uvev.CursorPositionEvent) {
    return [CursorPositionMsg(ev.x, ev.y)];
  }
  if (ev is uvev.WindowPixelSizeEvent) {
    return [WindowPixelSizeMsg(ev.width, ev.height)];
  }
  if (ev is uvev.CellSizeEvent) {
    return [CellSizeMsg(ev.width, ev.height)];
  }
  if (ev is uvev.PrimaryDeviceAttributesEvent) {
    return [PrimaryDeviceAttributesMsg(List<int>.unmodifiable(ev.attrs))];
  }
  if (ev is uvev.SecondaryDeviceAttributesEvent) {
    return [SecondaryDeviceAttributesMsg(List<int>.unmodifiable(ev.attrs))];
  }
  if (ev is uvev.TertiaryDeviceAttributesEvent) {
    return [TertiaryDeviceAttributesMsg(ev.value)];
  }

  if (ev is uvev.PasteEvent) return [PasteMsg(ev.content)];

  if (ev is uvev.ClipboardEvent) {
    final sel = switch (ev.selection) {
      0x63 /* 'c' */ => ClipboardSelection.system,
      0x70 /* 'p' */ => ClipboardSelection.primary,
      _ => ClipboardSelection.unknown,
    };
    return [ClipboardMsg(selection: sel, content: ev.content)];
  }

  if (ev is uvev.TerminalVersionEvent) {
    return [TerminalVersionMsg(ev.name)];
  }

  if (ev is uvev.CapabilityEvent) {
    return [CapabilityMsg(ev.content)];
  }

  if (ev is uvev.KeyboardEnhancementsEvent) {
    return [KeyboardEnhancementsMsg(reportEventTypes: ev.supportsKeyReleases)];
  }
  if (ev is uvev.ModifyOtherKeysEvent) {
    return [ModifyOtherKeysMsg(ev.mode)];
  }
  if (ev is uvev.ModeReportEvent) {
    return [
      ModeReportMsg(
        mode: ev.mode,
        value: switch (ev.value) {
          uvev.ModeSetting.notRecognized => ModeReportValue.notRecognized,
          uvev.ModeSetting.reset => ModeReportValue.reset,
          uvev.ModeSetting.set => ModeReportValue.set,
          uvev.ModeSetting.permanentlySet => ModeReportValue.permanentlySet,
          uvev.ModeSetting.permanentlyReset =>
            ModeReportValue.permanentlyReset,
        },
      ),
    ];
  }

  if (ev is uvev.ForegroundColorEvent) {
    final hex = ev.toString();
    return [ForegroundColorMsg(hex: hex)];
  }

  if (ev is uvev.BackgroundColorEvent) {
    final hex = ev.toString();
    return [BackgroundColorMsg(hex: hex)];
  }

  if (ev is uvev.CursorColorEvent) {
    final hex = ev.toString();
    return [CursorColorMsg(hex: hex)];
  }

  if (ev is uvev.ColorPaletteEvent && ev.color != null) {
    final hex =
        '#'
        '${ev.color!.r.toRadixString(16).padLeft(2, '0')}'
        '${ev.color!.g.toRadixString(16).padLeft(2, '0')}'
        '${ev.color!.b.toRadixString(16).padLeft(2, '0')}';
    return [ColorPaletteMsg(index: ev.index, hex: hex)];
  }

  if (ev is uvev.MouseClickEvent) {
    return [_mouseMsg(MouseAction.press, ev.mouse())];
  }
  if (ev is uvev.MouseReleaseEvent) {
    return [_mouseMsg(MouseAction.release, ev.mouse())];
  }
  if (ev is uvev.MouseMotionEvent) {
    return [_mouseMsg(MouseAction.motion, ev.mouse())];
  }
  if (ev is uvev.MouseWheelEvent) {
    return [_mouseMsg(MouseAction.wheel, ev.mouse())];
  }

  // Remaining UV events fall back to UvEventMsg in parseAll().
  return const [];
}

term.Key _toTermKey(uvk.Key key) {
  final alt = uvk.KeyMod.contains(key.mod, uvk.KeyMod.alt);
  final ctrl = uvk.KeyMod.contains(key.mod, uvk.KeyMod.ctrl);
  final shift = uvk.KeyMod.contains(key.mod, uvk.KeyMod.shift);
  final meta = uvk.KeyMod.contains(key.mod, uvk.KeyMod.meta);
  final hyper = uvk.KeyMod.contains(key.mod, uvk.KeyMod.hyper);
  final superKey = uvk.KeyMod.contains(key.mod, uvk.KeyMod.superKey);

  // Printable keys (including multi-codepoint grapheme clusters).
  if (key.text.isNotEmpty) {
    return term.Key(
      term.KeyType.runes,
      runes: uni.codePoints(key.text),
      alt: alt,
      ctrl: ctrl,
      meta: meta,
      hyper: hyper,
      superKey: superKey,
    );
  }

  // Common control/special keys (represented as ASCII codes in UV).
  switch (key.code) {
    case uvk.keyEnter: // 0x0D (CR)
      return term.Key(
        term.KeyType.enter,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case 0x0A: // 0x0A (LF)
      return term.Key(
        term.KeyType.enter,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyTab: // 0x09 (HT)
      return term.Key(
        term.KeyType.tab,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyBackspace: // 0x7F (DEL)
      return term.Key(
        term.KeyType.backspace,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyEscape: // 0x1B (ESC)
      return term.Key(
        term.KeyType.escape,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case 0x08: // 0x08 (BS / Ctrl+H)
      return term.Key(
        term.KeyType.backspace,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
  }

  // Keypad keys (Kitty protocol / application mode).
  // These are common in modern terminals and should round-trip into the
  // existing TUI key model so components can use them without bespoke mapping.
  switch (key.code) {
    case uvk.keyKpEnter:
      return term.Key(
        term.KeyType.enter,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );

    // Keypad arrows/navigation (Kitty keypad keys).
    case uvk.keyKpUp:
      return term.Key(
        term.KeyType.up,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpDown:
      return term.Key(
        term.KeyType.down,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpLeft:
      return term.Key(
        term.KeyType.left,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpRight:
      return term.Key(
        term.KeyType.right,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpHome:
      return term.Key(
        term.KeyType.home,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpEnd:
      return term.Key(
        term.KeyType.end,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpPgUp:
      return term.Key(
        term.KeyType.pageUp,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpPgDown:
      return term.Key(
        term.KeyType.pageDown,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpInsert:
      return term.Key(
        term.KeyType.insert,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpDelete:
      return term.Key(
        term.KeyType.delete,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );

    // Keypad operators/digits: map to printable runes.
    case uvk.keyKpPlus:
      return term.Key(
        term.KeyType.runes,
        runes: [0x2b],
        alt: alt,
        ctrl: ctrl,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpMinus:
      return term.Key(
        term.KeyType.runes,
        runes: [0x2d],
        alt: alt,
        ctrl: ctrl,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpMultiply:
      return term.Key(
        term.KeyType.runes,
        runes: [0x2a],
        alt: alt,
        ctrl: ctrl,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpDivide:
      return term.Key(
        term.KeyType.runes,
        runes: [0x2f],
        alt: alt,
        ctrl: ctrl,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpEqual:
      return term.Key(
        term.KeyType.runes,
        runes: [0x3d],
        alt: alt,
        ctrl: ctrl,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpComma:
    case uvk.keyKpSep:
      return term.Key(
        term.KeyType.runes,
        runes: [0x2c],
        alt: alt,
        ctrl: ctrl,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    case uvk.keyKpDecimal:
      return term.Key(
        term.KeyType.runes,
        runes: [0x2e],
        alt: alt,
        ctrl: ctrl,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
  }

  if (key.code >= uvk.keyKp0 && key.code <= uvk.keyKp9) {
    final digit = key.code - uvk.keyKp0;
    return term.Key(
      term.KeyType.runes,
      runes: [0x30 + digit],
      alt: alt,
      ctrl: ctrl,
      meta: meta,
      hyper: hyper,
      superKey: superKey,
    );
  }

  // C0/C1 mapped to ctrl+<letter> in UV (code points in ASCII range).
  // UV decoder transforms control codes into Ctrl+<letter> form, so we need
  // to recognize these patterns and map them to the appropriate key types.
  if (key.code < uvk.keyExtended) {
    var code = key.code;
    var finalCtrl = ctrl;

    // Handle Ctrl+<letter> combinations that map to special keys.
    // The UV decoder transforms:
    //   0x08 (BS) -> Ctrl+H (code=0x68)
    //   0x09 (HT) -> Tab or Ctrl+I (code=0x69)
    //   0x0A (LF) -> Enter or Ctrl+J (code=0x6A)
    //   0x0D (CR) -> Enter or Ctrl+M (code=0x6D)
    // Note: Tab/Enter cases are handled earlier via keyTab/keyEnter/0x0A
    // but Ctrl+H for backspace needs to be detected here.
    if (ctrl && code == 0x68) {
      // Ctrl+H -> Backspace (matches TUI parser behavior)
      return term.Key(
        term.KeyType.backspace,
        alt: alt,
        ctrl: false, // Don't mark as ctrl, it's just backspace
        shift: shift,
        meta: meta,
        hyper: hyper,
        superKey: superKey,
      );
    }

    if (code == 0) {
      code = 0x20; // Space
      finalCtrl = true;
    } else if (code >= 1 && code <= 26) {
      code += 96; // 1 -> 'a' (97)
      finalCtrl = true;
    }
    return term.Key(
      term.KeyType.runes,
      runes: [code],
      alt: alt,
      ctrl: finalCtrl,
      meta: meta,
      hyper: hyper,
      superKey: superKey,
    );
  }

  // Special keys.
  final (type, keepShift) = _toKeyType(key.code);
  return term.Key(
    type,
    alt: alt,
    ctrl: ctrl,
    shift: keepShift ? shift : false,
    meta: meta,
    hyper: hyper,
    superKey: superKey,
  );
}

(term.KeyType, bool keepShift) _toKeyType(int code) {
  switch (code) {
    case uvk.keyUp:
      return (term.KeyType.up, true);
    case uvk.keyDown:
      return (term.KeyType.down, true);
    case uvk.keyLeft:
      return (term.KeyType.left, true);
    case uvk.keyRight:
      return (term.KeyType.right, true);
    case uvk.keyHome:
      return (term.KeyType.home, true);
    case uvk.keyEnd:
      return (term.KeyType.end, true);
    case uvk.keyPgUp:
      return (term.KeyType.pageUp, true);
    case uvk.keyPgDown:
      return (term.KeyType.pageDown, true);
    case uvk.keyInsert:
      return (term.KeyType.insert, true);
    case uvk.keyDelete:
      return (term.KeyType.delete, true);
    case uvk.keyBackspace:
      return (term.KeyType.backspace, true);
    case uvk.keyTab:
      return (term.KeyType.tab, true);
    case uvk.keyEnter:
      return (term.KeyType.enter, true);
    case uvk.keyEscape:
      return (term.KeyType.escape, true);
    case uvk.keySpace:
      return (term.KeyType.space, true);

    // Lock keys (Kitty protocol)
    case uvk.keyCapsLock:
      return (term.KeyType.capsLock, true);
    case uvk.keyScrollLock:
      return (term.KeyType.scrollLock, true);
    case uvk.keyNumLock:
      return (term.KeyType.numLock, true);
    case uvk.keyPrintScreen:
      return (term.KeyType.printScreen, true);
    case uvk.keyPause:
      return (term.KeyType.pause, true);
    case uvk.keyMenu:
      return (term.KeyType.menu, true);

    // Media keys (Kitty protocol)
    case uvk.keyMediaPlay:
      return (term.KeyType.mediaPlay, true);
    case uvk.keyMediaPause:
      return (term.KeyType.mediaPause, true);
    case uvk.keyMediaPlayPause:
      return (term.KeyType.mediaPlayPause, true);
    case uvk.keyMediaReverse:
      return (term.KeyType.mediaReverse, true);
    case uvk.keyMediaStop:
      return (term.KeyType.mediaStop, true);
    case uvk.keyMediaFastForward:
      return (term.KeyType.mediaFastForward, true);
    case uvk.keyMediaRewind:
      return (term.KeyType.mediaRewind, true);
    case uvk.keyMediaNext:
      return (term.KeyType.mediaNext, true);
    case uvk.keyMediaPrev:
      return (term.KeyType.mediaPrev, true);
    case uvk.keyMediaRecord:
      return (term.KeyType.mediaRecord, true);

    // Volume keys (Kitty protocol)
    case uvk.keyLowerVol:
      return (term.KeyType.volumeDown, true);
    case uvk.keyRaiseVol:
      return (term.KeyType.volumeUp, true);
    case uvk.keyMute:
      return (term.KeyType.mute, true);

    // Modifier keys as standalone presses (Kitty protocol)
    case uvk.keyLeftShift:
      return (term.KeyType.leftShift, true);
    case uvk.keyLeftAlt:
      return (term.KeyType.leftAlt, true);
    case uvk.keyLeftCtrl:
      return (term.KeyType.leftCtrl, true);
    case uvk.keyLeftSuper:
      return (term.KeyType.leftSuper, true);
    case uvk.keyLeftHyper:
      return (term.KeyType.leftHyper, true);
    case uvk.keyLeftMeta:
      return (term.KeyType.leftMeta, true);
    case uvk.keyRightShift:
      return (term.KeyType.rightShift, true);
    case uvk.keyRightAlt:
      return (term.KeyType.rightAlt, true);
    case uvk.keyRightCtrl:
      return (term.KeyType.rightCtrl, true);
    case uvk.keyRightSuper:
      return (term.KeyType.rightSuper, true);
    case uvk.keyRightHyper:
      return (term.KeyType.rightHyper, true);
    case uvk.keyRightMeta:
      return (term.KeyType.rightMeta, true);
    case uvk.keyIsoLevel3Shift:
      return (term.KeyType.isoLevel3Shift, true);
    case uvk.keyIsoLevel5Shift:
      return (term.KeyType.isoLevel5Shift, true);
  }

  // Function keys F1-F20
  if (code >= uvk.keyF1 && code <= uvk.keyF20) {
    return (
      term.KeyType.values[term.KeyType.f1.index + (code - uvk.keyF1)],
      true,
    );
  }

  // Extended function keys F21-F63 (Kitty protocol)
  if (code >= uvk.keyF21 && code <= uvk.keyF63) {
    return (
      term.KeyType.values[term.KeyType.f21.index + (code - uvk.keyF21)],
      true,
    );
  }

  return (term.KeyType.unknown, true);
}

MouseMsg _mouseMsg(MouseAction action, uvm.Mouse m) {
  return MouseMsg(
    action: action,
    button: _toMouseButton(m.button),
    x: m.x,
    y: m.y,
    ctrl: uvk.KeyMod.contains(m.mod, uvk.KeyMod.ctrl),
    alt: uvk.KeyMod.contains(m.mod, uvk.KeyMod.alt),
    shift: uvk.KeyMod.contains(m.mod, uvk.KeyMod.shift),
  );
}

MouseButton _toMouseButton(int button) {
  switch (button) {
    case uvm.MouseButton.left:
      return MouseButton.left;
    case uvm.MouseButton.middle:
      return MouseButton.middle;
    case uvm.MouseButton.right:
      return MouseButton.right;
    case uvm.MouseButton.wheelUp:
      return MouseButton.wheelUp;
    case uvm.MouseButton.wheelDown:
      return MouseButton.wheelDown;
    case uvm.MouseButton.wheelLeft:
      return MouseButton.wheelLeft;
    case uvm.MouseButton.wheelRight:
      return MouseButton.wheelRight;
    case uvm.MouseButton.backward:
      return MouseButton.button4;
    case uvm.MouseButton.forward:
      return MouseButton.button5;
    default:
      return MouseButton.none;
  }
}
