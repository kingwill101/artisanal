/// Animated progress bar example ported from Bubble Tea.
library;

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

class DownloadMsg extends tui.Msg {
  const DownloadMsg(this.percent);
  final double percent;
}

// #region progress_usage
class ProgressAnimatedModel implements tui.Model {
  ProgressAnimatedModel({double percent = 0, tui.ProgressModel? progress})
    : percent = percent.clamp(0, 1),
      progress =
          progress ??
          tui.ProgressModel(
            useGradient: true,
            gradientColorA: '#FF7CCB',
            gradientColorB: '#FDFF8C',
          );

  final double percent;
  final tui.ProgressModel progress;

  @override
  tui.Cmd? init() => _tick();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg():
        return (this, tui.Cmd.quit());

      case tui.WindowSizeMsg(:final width):
        final newWidth = (width - 4).clamp(10, 80).toInt();
        final updated = progress.copyWith(width: newWidth);
        return (copyWith(progress: updated), null);

      case DownloadMsg(:final percent):
        final (newProgress, animCmd) = progress.setPercent(percent);
        final cmds = <tui.Cmd?>[animCmd];
        if (percent < 1.0) {
          cmds.add(_tick());
        } else {
          cmds.add(tui.Cmd.quit());
        }
        return (
          copyWith(percent: percent, progress: newProgress),
          tui.Cmd.batch(cmds.whereType<tui.Cmd>().toList()),
        );

      case tui.ProgressFrameMsg():
        final (newProgress, cmd) = progress.update(msg);
        return (copyWith(progress: newProgress), cmd);

      default:
        return (this, null);
    }
  }

  ProgressAnimatedModel copyWith({
    double? percent,
    tui.ProgressModel? progress,
  }) {
    return ProgressAnimatedModel(
      percent: percent ?? this.percent,
      progress: progress ?? this.progress,
    );
  }

  tui.Cmd _tick() {
    return tui.Cmd.tick(const Duration(milliseconds: 400), (_) {
      final next = (percent + 0.05).clamp(0.0, 1.0);
      return DownloadMsg(next);
    });
  }

  @override
  String view() {
    final bar = progress.view();
    final help = Style()
        .foreground(const AnsiColor(98))
        .render('Press any key to quit');
    return '\n$bar\n\n$help';
  }
}
// #endregion

Future<void> main() async {
  await tui.runProgram(
    ProgressAnimatedModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
