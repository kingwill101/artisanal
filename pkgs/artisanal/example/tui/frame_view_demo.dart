import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';

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

  @override
  void render(Frame frame, FrameArea area) {
    final rows = FrameLayout.vertical(area, const [
      FrameFill(),
      FrameLength(9),
      FrameFill(),
    ]);
    final columns = FrameLayout.horizontal(rows[1], const [
      FrameFill(),
      FrameLength(48),
      FrameFill(),
    ]);
    final panel = columns[1];
    if (panel.isEmpty) return;

    final border = Style()
        .foreground(Colors.cyan)
        .border(Border.rounded)
        // Style dimensions describe the content box. Leave one cell on each
        // horizontal edge for the border so the final output fits the area.
        .width((panel.width - 2).clamp(0, panel.width))
        .height(panel.height)
        .alignHorizontal(HorizontalAlign.center)
        .alignVertical(VerticalAlign.center);
    final title = Style()
        .foreground(Colors.yellow)
        .bold()
        .render('IMMEDIATE TEA');
    final value = Style().foreground(Colors.green).bold().render('$count');
    final hint = Style()
        .foreground(Colors.gray)
        .render('arrow keys: change   q: quit');

    frame.write(
      border.render('$title\n\n$value\n\n$hint'),
      target: panel,
      wrap: false,
    );
  }
}
