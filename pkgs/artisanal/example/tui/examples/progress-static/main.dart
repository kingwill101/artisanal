/// Static progress bar example ported from Bubble Tea.
library;

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

const _padding = 2;
const _maxWidth = 80;

class TickMsg extends tui.Msg {
  const TickMsg(this.time);
  final DateTime time;
}

class ProgressStaticModel implements tui.Model {
  ProgressStaticModel({double percent = 0, tui.ProgressModel? progress})
    : percent = percent.clamp(0, 1),
      progress = progress ?? tui.ProgressModel(useGradient: true);

  final double percent;
  final tui.ProgressModel progress;

  @override
  tui.Cmd? init() => _tickCmd();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg():
        return (this, tui.Cmd.quit());

      case tui.WindowSizeMsg(:final width):
        final newWidth = (width - _padding * 2 - 4).clamp(0, _maxWidth).toInt();
        final updated = progress.copyWith(width: newWidth);
        return (copyWith(progress: updated), null);

      case TickMsg():
        final nextPercent = (percent + 0.25).clamp(0.0, 1.0);
        if (nextPercent >= 1.0) {
          return (copyWith(percent: 1.0), tui.Cmd.quit());
        }
        return (copyWith(percent: nextPercent), _tickCmd());

      default:
        return (this, null);
    }
  }

  ProgressStaticModel copyWith({double? percent, tui.ProgressModel? progress}) {
    return ProgressStaticModel(
      percent: percent ?? this.percent,
      progress: progress ?? this.progress,
    );
  }

  tui.Cmd _tickCmd() =>
      tui.Cmd.tick(const Duration(seconds: 1), (t) => TickMsg(t));

  @override
  String view() {
    final pad = ' ' * _padding;
    final bar = progress.viewAs(percent);
    final help = Style()
        .foreground(const AnsiColor(98))
        .render('Press any key to quit');
    return '\n$pad$bar\n\n$pad$help';
  }
}

Future<void> main() async {
  await tui.runProgram(
    ProgressStaticModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
