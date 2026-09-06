import 'package:artisanal/tui.dart';
import 'package:artisanal/uv.dart' hide Key;

/// Immediate-mode TEA rendering without `artisanal_widgets`.
///
/// Run with:
///
/// ```sh
/// dart run example/tui/frame_view_demo.dart
/// ```
///
/// Use the arrow keys to change the counter and press `q` to quit.
Future<void> main() async {
  await runProgram(
    CounterModel(),
    options: const ProgramOptions(altScreen: true),
  );
}

final class CounterModel implements Model {
  int count = 0;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case KeyMsg(key: Key(type: KeyType.up || KeyType.right)):
        count++;
      case KeyMsg(key: Key(type: KeyType.down || KeyType.left)):
        count--;
      case KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])):
        return (this, Cmd.quit());
      case _:
        break;
    }
    return (this, null);
  }

  @override
  Object view() {
    return FrameView(
      content: 'Counter: $count\nArrow keys change the value; q quits.',
      windowTitle: 'Artisanal immediate-mode counter',
      paint: (frame) {
        frame.render(CounterPanel(count), frame.area);
      },
    );
  }
}

final class CounterPanel implements FrameRenderable {
  const CounterPanel(this.count);

  final int count;

  static const borderStyle = UvStyle(fg: UvColor.basic16(6, bright: true));
  static const titleStyle = UvStyle(
    fg: UvColor.basic16(3, bright: true),
    attrs: Attr.bold,
  );
  static const countStyle = UvStyle(
    fg: UvColor.basic16(2, bright: true),
    attrs: Attr.bold,
  );
  static const hintStyle = UvStyle(fg: UvColor.basic16(7));

  @override
  void render(Frame frame, Rectangle area) {
    final bounds = area;
    if (bounds.isEmpty) return;

    final width = bounds.width.clamp(1, 48);
    final height = bounds.height.clamp(1, 9);
    final panel = rect(
      bounds.minX + (bounds.width - width) ~/ 2,
      bounds.minY + (bounds.height - height) ~/ 2,
      width,
      height,
    );

    _drawBorder(frame.screen, panel);
    _writeCentered(
      frame.screen,
      panel,
      panel.minY + 2,
      'IMMEDIATE TEA',
      titleStyle,
    );
    _writeCentered(frame.screen, panel, panel.minY + 4, '$count', countStyle);
    _writeCentered(
      frame.screen,
      panel,
      panel.minY + 6,
      'arrow keys: change   q: quit',
      hintStyle,
    );
  }

  void _drawBorder(Screen screen, Rectangle area) {
    if (area.width < 2 || area.height < 2) return;
    final right = area.maxX - 1;
    final bottom = area.maxY - 1;

    for (var x = area.minX + 1; x < right; x++) {
      _set(screen, x, area.minY, '-', borderStyle);
      _set(screen, x, bottom, '-', borderStyle);
    }
    for (var y = area.minY + 1; y < bottom; y++) {
      _set(screen, area.minX, y, '|', borderStyle);
      _set(screen, right, y, '|', borderStyle);
    }
    _set(screen, area.minX, area.minY, '+', borderStyle);
    _set(screen, right, area.minY, '+', borderStyle);
    _set(screen, area.minX, bottom, '+', borderStyle);
    _set(screen, right, bottom, '+', borderStyle);
  }

  void _writeCentered(
    Screen screen,
    Rectangle area,
    int y,
    String text,
    UvStyle style,
  ) {
    if (y < area.minY || y >= area.maxY) return;
    final available = (area.width - 2).clamp(0, area.width);
    final visible = text.length <= available
        ? text
        : text.substring(0, available);
    final x = area.minX + (area.width - visible.length) ~/ 2;
    for (var i = 0; i < visible.length; i++) {
      _set(screen, x + i, y, visible[i], style);
    }
  }

  void _set(Screen screen, int x, int y, String content, UvStyle style) {
    screen.setCell(x, y, Cell(content: content, style: style));
  }
}
