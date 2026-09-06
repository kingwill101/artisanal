import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

const _width = 80;
const _height = 20;
const _iterations = 1000;

Future<void> main() async {
  final composed = await _measure('single composed string', _composedView);
  final positioned = await _measure('two positioned regions', _positionedView);

  print('');
  print('single composed string: ${_micros(composed.elapsed)} µs/frame');
  print('two positioned regions: ${_micros(positioned.elapsed)} µs/frame');
  print(
    'positioned/composed:     '
    '${(positioned.elapsed.inMicroseconds / composed.elapsed.inMicroseconds).toStringAsFixed(2)}x',
  );
  print('single output:           ${_bytes(composed.outputBytes)} bytes/frame');
  print(
    'positioned output:       ${_bytes(positioned.outputBytes)} bytes/frame',
  );
  print('');
  print(
    'This measures view construction, styled-string parsing, cell drawing,',
  );
  print('buffer diffing, and StringTerminal output. It does not imply fewer');
  print('physical terminal updates; both paths use the same UV buffer diff.');
}

Future<({Duration elapsed, int outputBytes})> _measure(
  String name,
  Object Function(int selected) buildView,
) async {
  final terminal = StringTerminal(
    terminalWidth: _width,
    terminalHeight: _height,
  );
  final renderer = UltravioletTuiRenderer(
    terminal: terminal,
    options: const TuiRendererOptions(altScreen: false, fps: 120),
  );

  for (var i = 0; i < 100; i++) {
    renderer.render(buildView(i & 1));
  }

  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < _iterations; i++) {
    renderer.render(buildView(i & 1));
  }
  stopwatch.stop();
  await renderer.flush();

  if (renderer.screenBuffer == null) {
    throw StateError('$name did not produce a frame');
  }
  final outputBytes = terminal.output.codeUnits.length;
  renderer.dispose();
  return (elapsed: stopwatch.elapsed, outputBytes: outputBytes);
}

Object _composedView(int selected) {
  final left = _panel('PROJECTS', _projectRows(selected), 39);
  final right = _panel('DETAIL', _detailRows(selected), 40);
  return Layout.joinHorizontal(VerticalAlign.top, [left, ' ', right]);
}

Object _positionedView(int selected) {
  return FrameView(
    paint: (frame) {
      final panes = FrameLayout.horizontal(frame.area, const [
        FrameLength(39),
        FrameFill(),
      ], gap: 1);
      frame.write(
        _panel('PROJECTS', _projectRows(selected), panes[0].width),
        target: panes[0],
        wrap: false,
      );
      frame.write(
        _panel('DETAIL', _detailRows(selected), panes[1].width),
        target: panes[1],
        wrap: false,
      );
    },
  );
}

List<String> _projectRows(int selected) {
  const projects = ['renderer', 'runtime', 'markdown', 'charts', 'editor'];
  return [
    for (var i = 0; i < projects.length; i++)
      i == selected
          ? Style()
                .foreground(Colors.black)
                .background(Colors.cyan)
                .bold()
                .render('› ${projects[i]}')
          : '  ${projects[i]}',
  ];
}

List<String> _detailRows(int selected) {
  final name = selected == 0 ? 'renderer' : 'runtime';
  return [
    Style().foreground(Colors.yellow).bold().render(name),
    '',
    Style().foreground(Colors.green).render('● healthy'),
    '',
    selected == 0
        ? 'Cell-buffer rendering and terminal diff output.'
        : 'TEA message loop, commands, replay, and tracing.',
  ];
}

String _panel(String title, List<String> content, int width) {
  final innerWidth = (width - 2).clamp(0, width);
  final rows = <String>[
    Style().foreground(Colors.yellow).bold().render(title),
    ...content,
  ];
  while (rows.length < _height - 2) {
    rows.add('');
  }
  return Style()
      .border(Border.rounded)
      .width(innerWidth)
      .render(rows.take(_height - 2).join('\n'));
}

String _micros(Duration elapsed) =>
    (elapsed.inMicroseconds / _iterations).toStringAsFixed(1);

String _bytes(int bytes) => (bytes / (_iterations + 100)).toStringAsFixed(1);
