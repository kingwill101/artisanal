/// Pager example ported from Bubble Tea using viewport bubble.
library;

import 'dart:io' as io;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';
import 'package:artisanal/tui.dart' as tui;

// #region viewport_usage
class PagerModel implements tui.Model {
  PagerModel({
    required this.content,
    tui.ViewportModel? viewport,
    this.ready = false,
  }) : viewport = viewport ?? tui.ViewportModel();

  final String content;
  final tui.ViewportModel viewport;
  final bool ready;

  PagerModel copyWith({
    String? content,
    tui.ViewportModel? viewport,
    bool? ready,
  }) {
    return PagerModel(
      content: content ?? this.content,
      viewport: viewport ?? this.viewport,
      ready: ready ?? this.ready,
    );
  }

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        if (key.matchesSingle(tui.CommonKeyBindings.quit)) {
          return (this, tui.Cmd.quit());
        }

      case tui.WindowSizeMsg(:final width, :final height):
        final headerHeight = _headerHeight();
        final footerHeight = _footerHeight();
        final margin = headerHeight + footerHeight;

        if (!ready) {
          final vp = tui.ViewportModel(
            width: width,
            height: height - margin,
          ).setContent(content);
          return (copyWith(viewport: vp, ready: true), null);
        }

        final vp = viewport.copyWith(width: width, height: height - margin);
        return (copyWith(viewport: vp, ready: true), null);
    }

    final (newViewport, cmd) = viewport.update(msg);
    return (copyWith(viewport: newViewport), cmd);
  }

  int _headerHeight() => 1; // computed in view
  int _footerHeight() => 1; // computed in view

  String _headerView() {
    final title = Style()
        .border(Border.rounded)
        .padding(0, 1)
        .render('Mr. Pager');
    final line = _hLine(viewport.width - _widthOf(title));
    return '$title$line';
  }

  String _footerView() {
    final percent = (viewport.scrollPercent * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);
    final info = Style()
        .border(Border.rounded)
        .padding(0, 1)
        .render('$percent%');
    final line = _hLine(viewport.width - _widthOf(info));
    return '$line$info';
  }

  @override
  String view() {
    if (!ready) {
      return '\n  Initializing...';
    }
    return '${_headerView()}\n${viewport.view()}\n${_footerView()}';
  }
}
// #endregion

String _hLine(int width) => width <= 0 ? '' : '─' * width;
int _widthOf(String text) => Style.visibleLength(text);

Future<void> main() async {
  final content = await io.File('README.md').readAsString();
  await tui.runProgram(
    PagerModel(content: content),
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      hideCursor: true,
    ),
  );
}
