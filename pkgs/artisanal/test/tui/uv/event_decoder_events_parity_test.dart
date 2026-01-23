import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/event_test.go`
// - `third_party/ultraviolet/event.go`

void main() {
  group('UV events parity', () {
    test('unknown event String()', () {
      expect(const UnknownEvent('test').toString(), '"test"');
      expect(const UnknownCsiEvent('csi').toString(), '"csi"');
      expect(const UnknownSs3Event('ss3').toString(), '"ss3"');
      expect(const UnknownOscEvent('osc').toString(), '"osc"');
      expect(const UnknownDcsEvent('dcs').toString(), '"dcs"');
      expect(const UnknownSosEvent('sos').toString(), '"sos"');
      expect(const UnknownPmEvent('pm').toString(), '"pm"');
      expect(const UnknownApcEvent('apc').toString(), '"apc"');
    });

    test('MultiEvent String()', () {
      final events = MultiEvent([
        const KeyPressEvent(Key(code: 0x61 /* a */)),
        const KeyPressEvent(Key(code: 0x62 /* b */)),
        const KeyPressEvent(Key(code: 0x63 /* c */)),
      ]);
      expect(events.toString(), 'a\nb\nc\n');
    });

    test('Size bounds', () {
      expect(
        const Size(width: 80, height: 24).bounds(),
        const Rectangle(minX: 0, minY: 0, maxX: 80, maxY: 24),
      );
      expect(
        const WindowSizeEvent(width: 100, height: 50).bounds(),
        const Rectangle(minX: 0, minY: 0, maxX: 100, maxY: 50),
      );
      expect(
        const WindowPixelSizeEvent(width: 1920, height: 1080).bounds(),
        const Rectangle(minX: 0, minY: 0, maxX: 1920, maxY: 1080),
      );
      expect(
        const CellSizeEvent(width: 10, height: 20).bounds(),
        const Rectangle(minX: 0, minY: 0, maxX: 10, maxY: 20),
      );
    });

    test('KeyPressEvent methods', () {
      const ev = KeyPressEvent(Key(code: 0x61 /* a */, mod: KeyMod.ctrl));
      expect(ev.matchString('ctrl+a'), true);
      expect(ev.matchString('ctrl+b'), false);
      expect(ev.matchString('ctrl+b', 'ctrl+a', 'ctrl+c'), true);
      expect(ev.matchString('ctrl+b', 'ctrl+c'), false);
      expect(ev.toString(), 'ctrl+a');
      expect(ev.keystroke(), 'ctrl+a');
      expect(ev.key(), const Key(code: 0x61 /* a */, mod: KeyMod.ctrl));
    });

    test('KeyReleaseEvent methods', () {
      const ev = KeyReleaseEvent(Key(code: 0x62 /* b */, mod: KeyMod.alt));
      expect(ev.matchString('alt+b'), true);
      expect(ev.matchString('alt+a'), false);
      expect(ev.matchString('alt+a', 'alt+b', 'alt+c'), true);
      expect(ev.matchString('alt+a', 'alt+c'), false);
      expect(ev.toString(), 'alt+b');
      expect(ev.keystroke(), 'alt+b');
      expect(ev.key(), const Key(code: 0x62 /* b */, mod: KeyMod.alt));
    });

    test('Mouse event methods', () {
      const mouse = Mouse(x: 10, y: 20, button: MouseButton.left);

      final click = const MouseClickEvent(mouse);
      expect(click.toString(), 'left');
      expect(click.mouse(), mouse);

      final rel = const MouseReleaseEvent(mouse);
      expect(rel.toString(), 'left');
      expect(rel.mouse(), mouse);

      final wheel = const MouseWheelEvent(
        Mouse(x: 10, y: 20, button: MouseButton.wheelUp),
      );
      expect(wheel.toString(), 'wheelup');
      expect(wheel.mouse().button, MouseButton.wheelUp);

      final motion = const MouseMotionEvent(mouse);
      expect(motion.toString(), 'left+motion');
      expect(motion.mouse(), mouse);

      final motion2 = const MouseMotionEvent(
        Mouse(x: 10, y: 20, button: MouseButton.none),
      );
      expect(motion2.toString(), 'motion');
    });

    test('KeyboardEnhancementsEvent.contains', () {
      const e = KeyboardEnhancementsEvent(0x07);
      expect(e.contains(0x01), true);
      expect(e.contains(0x03), true);
      expect(e.contains(0x07), true);
      expect(e.contains(0x08), false);
      expect(e.contains(0x0b), false);
    });

    test('Color events', () {
      const red = UvRgb(255, 0, 0);
      const black = UvRgb(0, 0, 0);
      const white = UvRgb(255, 255, 255);

      final fg = const ForegroundColorEvent(red);
      expect(fg.toString(), '#ff0000');
      expect(fg.isDark(), false);
      expect(const ForegroundColorEvent(black).isDark(), true);

      final bg = const BackgroundColorEvent(white);
      expect(bg.toString(), '#ffffff');
      expect(bg.isDark(), false);
      expect(const BackgroundColorEvent(black).isDark(), true);

      final cur = const CursorColorEvent(red);
      expect(cur.toString(), '#ff0000');
      expect(cur.isDark(), false);
      expect(const CursorColorEvent(black).isDark(), true);
    });

    test('ClipboardEvent String()', () {
      const e = ClipboardEvent(
        content: 'test content',
        selection: ClipboardSelection.system,
      );
      expect(e.toString(), 'test content');
    });

    test('Types exist / construct', () {
      const _ = CursorPositionEvent(x: 10, y: 20);
      const _ = FocusEvent();
      const _ = BlurEvent();
      const _ = DarkColorSchemeEvent();
      const _ = LightColorSchemeEvent();
      const _ = PasteEvent('pasted text');
      const _ = PasteStartEvent();
      const _ = PasteEndEvent();
      const _ = TerminalVersionEvent('1.0.0');
      const _ = ModifyOtherKeysEvent(1);
      const _ = KittyGraphicsEvent(options: KittyOptions(), payload: [1, 2, 3]);
      const _ = PrimaryDeviceAttributesEvent([1, 2, 3]);
      const _ = SecondaryDeviceAttributesEvent([1, 2, 3]);
      const _ = TertiaryDeviceAttributesEvent('test');
      const _ = ModeReportEvent(mode: 1000, value: ModeSetting.set);
      const _ = WindowOpEvent(op: 1, args: [100, 200]);
      const _ = CapabilityEvent('RGB');
      const _ = IgnoredEvent('ignored');
    });
  });
}
