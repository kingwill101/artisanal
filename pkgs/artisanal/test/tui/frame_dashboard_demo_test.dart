import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

import '../../example/tui/frame_dashboard_demo.dart' as example;

void main() {
  group('positioned-frame dashboard example', () {
    test('renders side-by-side panes on a wide terminal', () async {
      final renderer = await _render(width: 80, height: 20);
      final screen = renderer.screenBuffer!;

      expect(screen.cellAt(0, 2)?.content, '╭');
      expect(screen.cellAt(27, 2)?.content, '╮');
      expect(screen.cellAt(29, 2)?.content, '╭');
      expect(screen.cellAt(79, 2)?.content, '╮');
      expect(_line(renderer, 0), contains('ARTISANAL PROJECT STATUS'));
      expect(_line(renderer, 3), contains('PROJECTS'));
      expect(_line(renderer, 3), contains('DETAIL'));
      renderer.dispose();
    });

    test('stacks panes on a narrow terminal', () async {
      final renderer = await _render(width: 40, height: 20);
      final screen = renderer.screenBuffer!;

      expect(screen.cellAt(0, 2)?.content, '╭');
      expect(screen.cellAt(39, 2)?.content, '╮');
      expect(screen.cellAt(0, 11)?.content, '╭');
      expect(screen.cellAt(39, 11)?.content, '╮');
      expect(_line(renderer, 3), contains('PROJECTS'));
      expect(_line(renderer, 12), contains('DETAIL'));
      renderer.dispose();
    });

    test('selection changes only the model-owned state', () {
      final model = example.DashboardModel();

      model.update(const KeyMsg(Key(KeyType.down)));

      expect(model.selected, 1);
      expect(model.view(), isA<FrameView>());
    });
  });
}

Future<UltravioletTuiRenderer> _render({
  required int width,
  required int height,
}) async {
  final terminal = StringTerminal(terminalWidth: width, terminalHeight: height);
  final renderer = UltravioletTuiRenderer(
    terminal: terminal,
    options: const TuiRendererOptions(altScreen: false),
  );
  renderer.render(example.DashboardModel().view());
  await renderer.flush();
  return renderer;
}

String _line(UltravioletTuiRenderer renderer, int y) {
  final screen = renderer.screenBuffer!;
  final line = StringBuffer();
  for (var x = 0; x < screen.width(); x++) {
    line.write(screen.cellAt(x, y)?.content ?? ' ');
  }
  return line.toString();
}
