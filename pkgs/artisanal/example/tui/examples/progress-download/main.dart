/// Download progress example ported from Bubble Tea.
library;

import 'dart:math';

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

class DownloadProgressMsg extends tui.Msg {
  const DownloadProgressMsg(this.bytes, this.total);
  final int bytes;
  final int total;
}

class DownloadModel implements tui.Model {
  DownloadModel({
    required this.totalBytes,
    this.downloaded = 0,
    tui.ProgressModel? progress,
    Random? rand,
  }) : progress =
           progress ??
           tui.ProgressModel(
             width: 60,
             useGradient: true,
             gradientColorA: '#5A56E0',
             gradientColorB: '#EE6FF8',
           ),
       _rand = rand ?? Random();

  final int totalBytes;
  final int downloaded;
  final tui.ProgressModel progress;
  final Random _rand;

  @override
  tui.Cmd? init() => _startDownload();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg():
        return (this, tui.Cmd.quit());

      case DownloadProgressMsg(:final bytes, :final total):
        final pct = bytes / total;
        final (newProgress, animCmd) = progress.setPercent(pct);
        final cmds = <tui.Cmd?>[animCmd];
        if (bytes < total) {
          cmds.add(_nextChunk(bytes));
        } else {
          cmds.add(tui.Cmd.quit());
        }
        return (
          copyWith(downloaded: bytes, progress: newProgress),
          tui.Cmd.batch(cmds.whereType<tui.Cmd>().toList()),
        );

      case tui.ProgressFrameMsg():
        final (newProgress, cmd) = progress.update(msg);
        return (copyWith(progress: newProgress), cmd);

      default:
        return (this, null);
    }
  }

  DownloadModel copyWith({
    int? downloaded,
    tui.ProgressModel? progress,
    Random? rand,
  }) {
    return DownloadModel(
      totalBytes: totalBytes,
      downloaded: downloaded ?? this.downloaded,
      progress: progress ?? this.progress,
      rand: rand ?? _rand,
    );
  }

  tui.Cmd _startDownload() => _nextChunk(downloaded);

  tui.Cmd _nextChunk(int current) {
    return tui.Cmd.tick(const Duration(milliseconds: 120), (_) {
      final remaining = totalBytes - current;
      final step = _rand.nextInt((totalBytes / 40).ceil()).clamp(0, remaining);
      final next = (current + step).clamp(0, totalBytes);
      return DownloadProgressMsg(next, totalBytes);
    });
  }

  @override
  String view() {
    final pct = (downloaded / totalBytes * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);
    final kb = (totalBytes / 1024).toStringAsFixed(0);
    final info = Style()
        .foreground(const AnsiColor(98))
        .render('Downloading... $pct% of $kb KB (press any key to quit)');
    return '\n${progress.view()}\n\n$info\n';
  }
}

Future<void> main() async {
  await tui.runProgram(
    DownloadModel(totalBytes: 500_000),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
