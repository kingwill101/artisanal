import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/uv.dart' as uv;
import 'package:artisanal_widgets/selection.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/text_style/main.dart' as example;

void main() {
  test('text style showcase renders every supported usage pattern', () async {
    // Keep this deliberately narrow so the example exercises the same
    // continuation-line behavior as a compact embedded terminal host.
    final tester = WidgetTester(screenWidth: 42, screenHeight: 120);
    addTearDown(tester.dispose);

    await tester.pumpWidget(
      w.ThemeScope(theme: w.Theme.light(), child: example.TextStyleShowcase()),
    );

    expect(tester.locateText('TextStyle Showcase'), isNotNull);
    expect(tester.locateText('base: primary + bold'), isNotNull);
    expect(tester.locateText('copyWith: warning + bold'), isNotNull);
    expect(tester.locateText('merge: inherited primary'), isNotNull);
    expect(tester.locateText('Style keeps block layout;'), isNotNull);
    expect(tester.locateText('TextStyle'), isNotNull);
    expect(tester.locateText('overlays text only'), isNotNull);
    expect(tester.locateText('child'), isNotNull);
    expect(tester.locateText('inherits'), isNotNull);
    expect(tester.locateText('normal italic, no'), isNotNull);
    expect(tester.locateText('inherit false starts'), isNotNull);
    expect(tester.locateText('from defaults'), isNotNull);
    expect(tester.locateText('SelectableText: drag across'), isNotNull);
    expect(tester.locateText('SelectableRichText: dim parent'), isNotNull);
    expect(tester.locateText('ASCII-art font catalog'), isNotNull);
    expect(tester.locateText('Standard Font:'), isNotNull);
    expect(tester.locateText('Banner Font:'), isNotNull);
    expect(tester.locateText('Block Font:'), isNotNull);
    expect(tester.locateText('Slim Font:'), isNotNull);
    expect(tester.locateText('Numbers:'), isNotNull);
    expect(tester.locateText('Punctuation:'), isNotNull);

    expect(_underlineActiveBefore(tester.view, 'Banner Font:'), isFalse);
    expect(_underlineActiveBefore(tester.view, 'Slim Font:'), isFalse);
    expect(_underlineActiveBefore(tester.view, '#'), isFalse);

    final target = uv.ScreenBuffer(112, 120);
    (uv.StyledString(tester.view)..wrap = true).draw(target, target.bounds());
    final decoratedHashes = <(int, int)>[];
    int? firstHashRow;
    for (var y = 0; y < target.height(); y++) {
      for (var x = 0; x < target.width(); x++) {
        final cell = target.cellAt(x, y);
        if (cell?.content == '#') firstHashRow ??= y;
        if (cell?.content == '#' &&
            cell?.style.underline != uv.UnderlineStyle.none) {
          decoratedHashes.add((x, y));
        }
      }
    }
    expect(decoratedHashes, isEmpty);
    final decoratedFontCells = <(int, int, String)>[];
    for (var y = firstHashRow!; y < target.height(); y++) {
      for (var x = 0; x < target.width(); x++) {
        final cell = target.cellAt(x, y);
        if (cell != null && cell.style.underline != uv.UnderlineStyle.none) {
          decoratedFontCells.add((x, y, cell.content));
        }
      }
    }
    expect(decoratedFontCells, isEmpty);

    expect(tester.view, contains('╭'));
    expect(tester.view, contains('╮'));
    expect(tester.view, contains('╰'));
    expect(tester.view, contains('╯'));

    expect(_hasSgrParameter(tester.view, '1'), isTrue);
    expect(_hasSgrParameter(tester.view, '3'), isTrue);
    expect(_hasSgrParameter(tester.view, '2'), isTrue);
  });

  test('scroll repaint clears decorations before ASCII font samples', () async {
    const width = 112;
    const height = 40;
    final tester = WidgetTester(screenWidth: width, screenHeight: height);
    addTearDown(tester.dispose);
    await tester.pumpWidget(
      w.ThemeScope(theme: w.Theme.light(), child: example.TextStyleShowcase()),
    );

    final output = StringBuffer();
    final renderer = uv.UvTerminalRenderer(
      output,
      env: const ['TERM=xterm-256color', 'TTY_FORCE=1'],
    )..setFullscreen(true);

    void renderFrame() {
      final screen = uv.ScreenBuffer(width, height);
      (uv.StyledString(tester.view)..wrap = true).draw(screen, screen.bounds());
      renderer.render(screen.buffer);
      renderer.flush();
    }

    const fontLabels = {
      'Standard Font:',
      'Banner Font:',
      'Block Font:',
      'Slim Font:',
      'Numbers:',
      'Punctuation:',
    };
    final seenLabels = <String>{};

    void inspectRepaint(String repaint) {
      expect(
        _decoratedStructuralCommands(repaint),
        isEmpty,
        reason: 'scroll commands must run with a reset decoration pen',
      );
      for (final label in fontLabels) {
        if (!repaint.contains(label)) continue;
        expect(_underlineActiveBefore(repaint, label), isFalse);
        seenLabels.add(label);
      }
    }

    renderFrame();
    inspectRepaint(output.toString());
    for (var i = 0; i < 120 && seenLabels.length < fontLabels.length; i++) {
      output.clear();
      tester.sendSpecialKey(KeyType.down);
      renderFrame();
      inspectRepaint(output.toString());
    }

    expect(seenLabels, containsAll(fontLabels));
  });

  test('narrow-to-wide resize leaves ASCII font cells undecorated', () async {
    const height = 40;
    final tester = WidgetTester(screenWidth: 42, screenHeight: height);
    addTearDown(tester.dispose);
    await tester.pumpWidget(
      w.ThemeScope(theme: w.Theme.light(), child: example.TextStyleShowcase()),
    );

    tester.sendSpecialKey(KeyType.end);
    tester.resize(112, height);

    final target = uv.ScreenBuffer(112, height);
    (uv.StyledString(tester.view)..wrap = true).draw(target, target.bounds());

    expect(_decoratedCellsAtOrBelow(target, 'Punctuation:'), isEmpty);

    final output = StringBuffer();
    final renderer = uv.UvTerminalRenderer(
      output,
      env: const ['TERM=xterm-256color', 'COLORTERM=truecolor', 'TTY_FORCE=1'],
    )..setFullscreen(true);
    renderer.resetForResize(112, height);
    renderer.render(target.buffer);
    renderer.flush();

    expect(output.toString(), contains(uv.UvAnsi.eraseEntireScreen));
    expect(_underlineActiveBefore(output.toString(), 'Punctuation:'), isFalse);
  });
}

bool _hasSgrParameter(String output, String parameter) {
  final sgr = RegExp(r'\x1b\[([0-9;:]*)m');
  return sgr
      .allMatches(output)
      .map((match) => match.group(1)!.split(';'))
      .any((parameters) => parameters.contains(parameter));
}

bool _underlineActiveBefore(String output, String text) {
  final end = output.indexOf(text);
  expect(
    end,
    isNonNegative,
    reason: 'expected renderer output to contain $text',
  );
  var active = false;
  final sgr = RegExp(r'\x1b\[([0-9;:]*)m');
  for (final match in sgr.allMatches(output.substring(0, end))) {
    for (final parameter in match.group(1)!.split(';')) {
      if (parameter == '0' || parameter == '24' || parameter.isEmpty) {
        active = false;
      } else if (parameter == '4' || parameter.startsWith('4:')) {
        active = parameter != '4:0';
      }
    }
  }
  return active;
}

List<String> _decoratedStructuralCommands(String output) {
  final failures = <String>[];
  var underline = false;
  var strike = false;
  final token = RegExp(r'\x1b\[([0-9;:]*)?([@-~])|\x1bM');
  for (final match in token.allMatches(output)) {
    if (match.group(0) == '\x1bM') {
      if (underline || strike) failures.add('reverse-index');
      continue;
    }

    final finalByte = match.group(2);
    if (finalByte == 'm') {
      for (final parameter in (match.group(1) ?? '').split(';')) {
        if (parameter == '0' || parameter.isEmpty) {
          underline = false;
          strike = false;
        } else if (parameter == '24' || parameter == '4:0') {
          underline = false;
        } else if (parameter == '4' || parameter.startsWith('4:')) {
          underline = true;
        } else if (parameter == '29') {
          strike = false;
        } else if (parameter == '9') {
          strike = true;
        }
      }
      continue;
    }

    if (const {'L', 'M', 'S', 'T'}.contains(finalByte) &&
        (underline || strike)) {
      failures.add('CSI $finalByte');
    }
  }
  return failures;
}

List<(int, int, String)> _decoratedCellsAtOrBelow(
  uv.ScreenBuffer screen,
  String marker,
) {
  int? markerRow;
  for (var y = 0; y < screen.height(); y++) {
    final row = StringBuffer();
    for (var x = 0; x < screen.width(); x++) {
      final cell = screen.cellAt(x, y);
      if (cell != null && !cell.isZero) row.write(cell.content);
    }
    if (row.toString().contains(marker)) {
      markerRow = y;
      break;
    }
  }
  expect(markerRow, isNotNull, reason: 'expected $marker in resized frame');

  final decorated = <(int, int, String)>[];
  for (var y = markerRow!; y < screen.height(); y++) {
    for (var x = 0; x < screen.width(); x++) {
      final cell = screen.cellAt(x, y);
      if (cell != null && cell.style.underline != uv.UnderlineStyle.none) {
        decorated.add((x, y, cell.content));
      }
    }
  }
  return decorated;
}
