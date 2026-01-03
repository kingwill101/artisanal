/// Package manager demo ported from Bubble Tea.
///
/// Options:
///   --uv-renderer    Use the UV cell-buffer diff renderer
///   --uv-input       Use the UV input decoder
library;

import 'dart:math';

import 'package:artisanal/artisanal.dart' show AnsiColor, Layout, Style;
import 'package:artisanal/tui.dart' as tui;

final _currentPkgNameStyle = Style().foreground(const AnsiColor(211));
final _doneStyle = Style().margin(1, 2);
final _checkMark = Style().foreground(const AnsiColor(42)).render('✓');

final _spinnerStyle = Style().foreground(const AnsiColor(63));

final _rand = Random();

class InstalledPkgMsg extends tui.Msg {
  const InstalledPkgMsg(this.pkg);
  final String pkg;
}

class PackageManagerModel implements tui.Model {
  PackageManagerModel({
    required this.packages,
    this.index = 0,
    this.width = 0,
    this.height = 0,
    tui.SpinnerModel? spinner,
    tui.ProgressModel? progress,
    this.done = false,
  }) : spinner = spinner ?? tui.SpinnerModel(),
       progress =
           progress ??
           tui.ProgressModel(
             width: 40,
             showPercentage: false,
             useGradient: true,
           );

  factory PackageManagerModel.initial() {
    return PackageManagerModel(packages: _getPackages());
  }

  final List<String> packages;
  final int index;
  final int width;
  final int height;
  final tui.SpinnerModel spinner;
  final tui.ProgressModel progress;
  final bool done;

  @override
  tui.Cmd? init() =>
      tui.Cmd.batch([_downloadAndInstall(packages[index]), spinner.tick()]);

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.WindowSizeMsg(width: final w, height: final h):
        final prog = progress.copyWith(width: w > 10 ? w ~/ 2 : progress.width);
        return (copyWith(width: w, height: h, progress: prog), null);

      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        if (rune == 0x71 ||
            key.type == tui.KeyType.escape ||
            (key.ctrl && rune == 0x63)) {
          return (this, tui.Cmd.quit());
        }

      case InstalledPkgMsg(:final pkg):
        if (index >= packages.length - 1) {
          final (newProg, progCmd) = progress.setPercent(1);
          return (
            copyWith(done: true, progress: newProg),
            _batch([
              progCmd,
              tui.Cmd.printf('%s %s', [_checkMark, pkg]),
              tui.Cmd.quit(),
            ]),
          );
        }

        final nextIndex = index + 1;
        final percent = nextIndex / packages.length;
        final (newProg, progCmd) = progress.setPercent(percent);
        return (
          copyWith(index: nextIndex, progress: newProg),
          _batch([
            progCmd,
            tui.Cmd.printf('%s %s', [_checkMark, pkg]),
            _downloadAndInstall(packages[nextIndex]),
          ]),
        );

      case tui.SpinnerTickMsg():
        final (newSpin, cmd) = spinner.update(msg);
        return (copyWith(spinner: newSpin), cmd);

      case tui.ProgressFrameMsg():
        final (newProg, cmd) = progress.update(msg);
        return (copyWith(progress: newProg), cmd);
    }

    return (this, null);
  }

  PackageManagerModel copyWith({
    List<String>? packages,
    int? index,
    int? width,
    int? height,
    tui.SpinnerModel? spinner,
    tui.ProgressModel? progress,
    bool? done,
  }) {
    return PackageManagerModel(
      packages: packages ?? this.packages,
      index: index ?? this.index,
      width: width ?? this.width,
      height: height ?? this.height,
      spinner: spinner ?? this.spinner,
      progress: progress ?? this.progress,
      done: done ?? this.done,
    );
  }

  @override
  String view() {
    final n = packages.length;
    final w = n.toString().length;

    if (done) {
      return _doneStyle.render('Done! Installed $n packages.\n');
    }

    final pkgCount =
        ' ${index.toString().padLeft(w)}/${n.toString().padLeft(w)}';
    final spin = '${_spinnerStyle.render(spinner.view())} ';
    final prog = progress.view();

    final pkgName = _currentPkgNameStyle.render(packages[index]);
    final info = 'Installing $pkgName';

    final cellsAvail = width > 0
        ? _max(0, width - _stringWidth('$spin$prog$pkgCount'))
        : 0;
    final infoRendered = Style()
        .maxWidth(cellsAvail > 0 ? cellsAvail : info.length)
        .render(info);

    final cellsRemaining = width > 0
        ? _max(0, width - _stringWidth('$spin$infoRendered$prog$pkgCount'))
        : 0;
    final gap = ' ' * cellsRemaining;

    return '$spin$infoRendered$gap$prog$pkgCount';
  }
}

int _max(int a, int b) => a > b ? a : b;

int _stringWidth(String s) => Layout.visibleLength(s);

tui.Cmd? _batch(List<tui.Cmd?> cmds) {
  final filtered = cmds.whereType<tui.Cmd>().toList();
  return filtered.isEmpty ? null : tui.Cmd.batch(filtered);
}

List<String> _getPackages() {
  final pkgs = List<String>.from(_packages);
  pkgs.shuffle(_rand);
  for (var i = 0; i < pkgs.length; i++) {
    pkgs[i] =
        '${pkgs[i]}-${_rand.nextInt(10)}.${_rand.nextInt(10)}.${_rand.nextInt(10)}';
  }
  return pkgs;
}

tui.Cmd _downloadAndInstall(String pkg) {
  final d = Duration(milliseconds: _rand.nextInt(500) + 50);
  return tui.Cmd.tick(d, (_) => InstalledPkgMsg(pkg));
}

const _packages = [
  'vegeutils',
  'libgardening',
  'currykit',
  'spicerack',
  'fullenglish',
  'eggy',
  'bad-kitty',
  'chai',
  'hojicha',
  'libtacos',
  'babys-monads',
  'libpurring',
  'currywurst-devel',
  'xmodmeow',
  'licorice-utils',
  'cashew-apple',
  'rock-lobster',
  'standmixer',
  'coffee-CUPS',
  'libesszet',
  'zeichenorientierte-benutzerschnittstellen',
  'schnurrkit',
  'old-socks-devel',
  'jalapeño',
  'molasses-utils',
  'xkohlrabi',
  'party-gherkin',
  'snow-peas',
  'libyuzu',
];

Future<void> main(List<String> args) async {
  final useUvRenderer = args.contains('--uv-renderer');
  final useUvInput = args.contains('--uv-input');

  await tui.runProgram(
    PackageManagerModel.initial(),
    options: tui.ProgramOptions(
      altScreen: false,
      hideCursor: false,
      useUltravioletRenderer: useUvRenderer,
      useUltravioletInputDecoder: useUvInput,
    ),
  );
}
