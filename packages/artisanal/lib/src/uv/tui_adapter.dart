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

  if (ev is uvev.WindowSizeEvent) {
    return [WindowSizeMsg(ev.width, ev.height)];
  }
  if (ev is uvev.Size) return [WindowSizeMsg(ev.width, ev.height)];

  if (ev is uvev.PasteEvent) return [PasteMsg(ev.content)];

  if (ev is uvev.ClipboardEvent) {
    final sel = switch (ev.selection) {
      0x63 /* 'c' */ => ClipboardSelection.system,
      0x70 /* 'p' */ => ClipboardSelection.primary,
      _ => ClipboardSelection.unknown,
    };
    return [ClipboardMsg(selection: sel, content: ev.content)];
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

  // Unknown/unsupported UV events are currently dropped.
  return const [];
}

term.Key _toTermKey(uvk.Key key) {
  final alt = uvk.KeyMod.contains(key.mod, uvk.KeyMod.alt);
  final ctrl = uvk.KeyMod.contains(key.mod, uvk.KeyMod.ctrl);
  final shift = uvk.KeyMod.contains(key.mod, uvk.KeyMod.shift);

  // Printable keys (including multi-codepoint grapheme clusters).
  if (key.text.isNotEmpty) {
    return term.Key(
      term.KeyType.runes,
      runes: uni.codePoints(key.text),
      alt: alt,
      ctrl: ctrl,
    );
  }

  // Common control/special keys (represented as ASCII codes in UV).
  switch (key.code) {
    case uvk.keyEnter:
      return term.Key(term.KeyType.enter, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyTab:
      return term.Key(term.KeyType.tab, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyBackspace:
      return term.Key(
        term.KeyType.backspace,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
      );
    case uvk.keyEscape:
      return term.Key(term.KeyType.escape, alt: alt, ctrl: ctrl, shift: shift);
  }

  // Keypad keys (Kitty protocol / application mode).
  // These are common in modern terminals and should round-trip into the
  // existing TUI key model so components can use them without bespoke mapping.
  switch (key.code) {
    case uvk.keyKpEnter:
      return term.Key(term.KeyType.enter, alt: alt, ctrl: ctrl, shift: shift);

    // Keypad arrows/navigation (Kitty keypad keys).
    case uvk.keyKpUp:
      return term.Key(term.KeyType.up, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyKpDown:
      return term.Key(term.KeyType.down, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyKpLeft:
      return term.Key(term.KeyType.left, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyKpRight:
      return term.Key(term.KeyType.right, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyKpHome:
      return term.Key(term.KeyType.home, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyKpEnd:
      return term.Key(term.KeyType.end, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyKpPgUp:
      return term.Key(term.KeyType.pageUp, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyKpPgDown:
      return term.Key(
        term.KeyType.pageDown,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
      );
    case uvk.keyKpInsert:
      return term.Key(term.KeyType.insert, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyKpDelete:
      return term.Key(term.KeyType.delete, alt: alt, ctrl: ctrl, shift: shift);

    // Keypad operators/digits: map to printable runes.
    case uvk.keyKpPlus:
      return term.Key(term.KeyType.runes, runes: [0x2b], alt: alt, ctrl: ctrl);
    case uvk.keyKpMinus:
      return term.Key(term.KeyType.runes, runes: [0x2d], alt: alt, ctrl: ctrl);
    case uvk.keyKpMultiply:
      return term.Key(term.KeyType.runes, runes: [0x2a], alt: alt, ctrl: ctrl);
    case uvk.keyKpDivide:
      return term.Key(term.KeyType.runes, runes: [0x2f], alt: alt, ctrl: ctrl);
    case uvk.keyKpEqual:
      return term.Key(term.KeyType.runes, runes: [0x3d], alt: alt, ctrl: ctrl);
    case uvk.keyKpComma:
    case uvk.keyKpSep:
      return term.Key(term.KeyType.runes, runes: [0x2c], alt: alt, ctrl: ctrl);
    case uvk.keyKpDecimal:
      return term.Key(term.KeyType.runes, runes: [0x2e], alt: alt, ctrl: ctrl);
  }

  if (key.code >= uvk.keyKp0 && key.code <= uvk.keyKp9) {
    final digit = key.code - uvk.keyKp0;
    return term.Key(
      term.KeyType.runes,
      runes: [0x30 + digit],
      alt: alt,
      ctrl: ctrl,
    );
  }

  // C0/C1 mapped to ctrl+<letter> in UV (code points in ASCII range).
  if (key.code < uvk.keyExtended) {
    return term.Key(
      term.KeyType.runes,
      runes: [key.code],
      alt: alt,
      ctrl: ctrl,
    );
  }

  // Special keys.
  final (type, keepShift) = _toKeyType(key.code);
  return term.Key(type, alt: alt, ctrl: ctrl, shift: keepShift ? shift : false);
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
  }

  if (code >= uvk.keyF1 && code <= uvk.keyF20) {
    return (
      term.KeyType.values[term.KeyType.f1.index + (code - uvk.keyF1)],
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
