import 'dart:async';
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

class GoldenDemoModel implements tui.Model {
  GoldenDemoModel({required this.useUvRenderer, required this.useUvInput})
    : progress = tui.ProgressModel(width: 40);

  bool useUvRenderer;
  bool useUvInput;
  bool shouldQuit = false;
  bool shouldRestart = false;
  tui.ProgressModel progress;
  final List<String> logs = [];
  int width = 0;
  int height = 0;

  @override
  tui.Cmd? init() {
    return tui.Cmd.batch([
      tui.Cmd.tick(const Duration(milliseconds: 100), (_) => const TickMsg()),
      tui.Cmd.enableReportFocus(),
    ]);
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        if (key.isChar('q') || key.type == tui.KeyType.escape) {
          shouldQuit = true;
          return (this, tui.Cmd.quit());
        }
        if (key.isChar('r')) {
          useUvRenderer = !useUvRenderer;
          shouldRestart = true;
          return (this, tui.Cmd.quit());
        }
        if (key.isChar('i')) {
          useUvInput = !useUvInput;
          shouldRestart = true;
          return (this, tui.Cmd.quit());
        }
        if (key.isChar('l')) {
          return (
            this,
            tui.Cmd.println('Manual log entry at ${DateTime.now()}'),
          );
        }
        break;

      case tui.WindowSizeMsg(:final width, :final height):
        this.width = width;
        this.height = height;
        break;

      case TickMsg():
        var nextPercent = progress.percent + 0.01;
        if (nextPercent > 1.0) {
          nextPercent = 0.0;
          return (
            this,
            tui.Cmd.batch([
              tui.Cmd.println('Progress reset!'),
              tui.Cmd.tick(
                const Duration(milliseconds: 100),
                (_) => const TickMsg(),
              ),
            ]),
          );
        }
        progress.setPercent(nextPercent);
        return (
          this,
          tui.Cmd.tick(
            const Duration(milliseconds: 100),
            (_) => const TickMsg(),
          ),
        );
    }

    return (this, null);
  }

  @override
  String view() {
    final headerStyle = Style().bold().foreground(Colors.cyan);
    final labelStyle = Style().foreground(Colors.gray);
    final valueStyle = Style().foreground(Colors.green);

    final buffer = StringBuffer();
    buffer.writeln(headerStyle.render('--- ARTESANAL ARGS GOLDEN DEMO ---'));
    buffer.writeln();
    buffer.writeln(
      '${labelStyle.render('TuiRenderer:')} ${valueStyle.render(useUvRenderer ? "Ultraviolet (Cell Buffer)" : "Standard (String)")} ${labelStyle.render('(Press "r" to toggle)')}',
    );
    buffer.writeln(
      '${labelStyle.render('Input:')}    ${valueStyle.render(useUvInput ? "Ultraviolet (Byte Stream)" : "Standard (KeyParser)")} ${labelStyle.render('(Press "i" to toggle)')}',
    );
    buffer.writeln();
    buffer.writeln('${labelStyle.render('Terminal Size:')} ${width}x$height');
    buffer.writeln();
    buffer.writeln(
      '${labelStyle.render('Progress:')} ${progress.view()} ${(progress.percent * 100).toInt()}%',
    );
    buffer.writeln();

    final link = Style()
        .foreground(Colors.blue)
        .underline()
        .hyperlink('https://github.com/charmbracelet/lipgloss')
        .render('Lipgloss v2 Parity');
    buffer.writeln('${labelStyle.render('Hyperlink:')} $link');
    buffer.writeln();

    buffer.writeln(headerStyle.render('Controls:'));
    buffer.writeln('  r: Toggle TuiRenderer');
    buffer.writeln('  i: Toggle Input Decoder');
    buffer.writeln('  l: Add Log Line');
    buffer.writeln('  q: Quit');

    return buffer.toString();
  }
}

class TickMsg extends tui.Msg {
  const TickMsg();
}

void main(List<String> args) async {
  var useUvRenderer = args.contains('--uv') || args.contains('--uv-renderer');
  var useUvInput = args.contains('--uv') || args.contains('--uv-input');

  while (true) {
    final model = GoldenDemoModel(
      useUvRenderer: useUvRenderer,
      useUvInput: useUvInput,
    );

    final result = await tui.runProgramWithResult(
      model,
      options: tui.ProgramOptions(
        altScreen: true,
        useUltravioletRenderer: useUvRenderer,
        useUltravioletInputDecoder: useUvInput,
      ),
    );

    if (result.shouldQuit) break;

    useUvRenderer = result.useUvRenderer;
    useUvInput = result.useUvInput;

    // Small delay to allow terminal to settle between restarts
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
