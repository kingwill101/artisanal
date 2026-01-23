part of 'kitchen_sink.dart';

final class _LipglossPage extends _KitchenSinkPage {
  _LipglossPage()
    : _pane = tui.ViewportScrollPane(
        viewport: tui.ViewportModel(width: 0, height: 0, horizontalStep: 4),
      ),
      super(
        help:
            'tui.Tree/List/tui.Table: scroll with ↑/↓ j/k, PgUp/PgDn, mouse wheel • drag scrollbar',
      );

  final tui.ViewportScrollPane _pane;

  @override
  String view(_KitchenSinkModel m) {
    final title = m
        ._style(Style())
        .bold()
        .render('tui.Tree/List/tui.Table (lipgloss v2 parity)');

    final tree1 =
        (tui.Tree()
              ..root('Root')
              ..child('Foo')
              ..child(
                tui.Tree()
                  ..root('Bar')
                  ..child('Line 1\nLine 2\nLine 3')
                  ..child('Baz'),
              )
              ..child('Qux'))
            .enumerator(tui.TreeEnumerator.rounded)
            .render();

    final tree2 =
        (tui.Tree()
              ..root('Packages')
              ..child('🍞 bread')
              ..child('🥬 kale')
              ..child(
                tui.Tree()
                  ..root('Nested')
                  ..child('one')
                  ..child('two'),
              ))
            .enumerator(tui.TreeEnumerator.heavy)
            .rootStyle(
              m._style(Style())
                ..bold()
                ..foreground(Colors.sky),
            )
            .enumeratorStyle(m._style(Style()).dim())
            .indenterStyle(m._style(Style()).dim())
            .itemStyleFunc((children, index) {
              final v = children[index].value.toString();
              if (v.contains('🍞')) {
                return m._style(Style()).foreground(Colors.rose);
              }
              if (v.contains('🥬')) {
                return m._style(Style()).foreground(Colors.lime);
              }
              return m._style(Style());
            })
            .render();

    final tree3 =
        (tui.Tree()
              ..root('Offset + hidden (double-line)')
              ..child('trim-start')
              ..child(
                (tui.Tree()
                  ..root('hidden subtree')
                  ..hide(true)),
              )
              ..child('shown A')
              ..child('shown B')
              ..child('trim-end'))
            .offset(1, 1)
            .enumerator(tui.TreeEnumerator.doubleLine)
            .enumeratorStyle(m._style(Style()).dim())
            .indenterStyle(m._style(Style()).dim())
            .itemStyleFunc((children, index) {
              final v = children[index].value.toString();
              if (v.contains('shown A')) {
                return m._style(Style()).foreground(Colors.teal);
              }
              if (v.contains('shown B')) {
                return m._style(Style()).foreground(Colors.indigo);
              }
              return m._style(Style());
            })
            .render();

    final list1 = (LipList.create([
      'Foo',
      'Bar',
      LipList.create(['Hi', 'Hello', 'Halo']).enumerator(ListEnumerators.roman),
      'Qux',
    ])).render();

    final list2 = (LipList.create([
      m._style(Style()).foreground(Colors.teal).render('teal item'),
      m._style(Style()).foreground(Colors.indigo).render('indigo item'),
      m._style(Style()).foreground(Colors.rose).render('rose item'),
    ])..enumerator(ListEnumerators.bullet)).render();

    final table1 =
        (tui.Table()
              ..width(34)
              ..headers(['Pkg', 'Status', 'Notes'])
              ..row(['artisanal', 'OK', 'styled + uv'])
              ..row(['ultraviolet', 'WIP', 'decoder+renderer'])
              ..row(['lipgloss', 'v2', 'parity pass']))
            .border(Border.rounded)
            .padding(0)
            .styleFunc((row, col, data) {
              if (row == tui.Table.headerRow) {
                return m._style(Style()).bold().foreground(Colors.sky);
              }
              if (col == 1 && data == 'OK') {
                return m._style(Style()).foreground(Colors.lime);
              }
              if (col == 1 && data == 'WIP') {
                return m._style(Style()).foreground(Colors.rose);
              }
              if (row.isEven) return m._style(Style()).dim();
              return null;
            })
            .render();

    final table2 =
        (tui.Table()
              ..width(26)
              ..headers(['Key', 'Value'])
              ..row(['emoji', '🍕🍔🌮'])
              ..row(['wrap', 'a long cell that should truncate']))
            .border(Border.double)
            .borderRow(true)
            .padding(0)
            .render();

    final table3 =
        (tui.Table()
              ..width(34)
              ..height(7)
              ..offset(1)
              ..headers(['#', 'Step', 'Dur'])
              ..rows([
                ['1', 'decode', '2ms'],
                ['2', 'layout', '4ms'],
                ['3', 'diff', '1ms'],
                ['4', 'flush', '3ms'],
              ]))
            .border(Border.ascii)
            .borderColumn(false)
            .borderRow(true)
            .padding(0)
            .styleFunc((row, col, data) {
              if (row == tui.Table.headerRow) {
                return m._style(Style()).bold().foreground(Colors.sky);
              }
              return switch (col) {
                0 => m._style(Style()).dim(),
                2 =>
                  m
                      ._style(Style())
                      .width(4)
                      .alignRight()
                      .foreground(Colors.lime),
                _ => null,
              };
            })
            .render();

    final innerTable =
        (tui.Table()
              ..width(34)
              ..headers(['Col', 'Value'])
              ..row(['alpha', 'one'])
              ..row(['beta', 'two'])
              ..row(['gamma', 'three']))
            .border(Border.normal)
            .borderTop(false)
            .borderBottom(false)
            .borderLeft(false)
            .borderRight(false)
            .borderHeader(true)
            .borderRow(false)
            .padding(0)
            .styleFunc((row, col, data) {
              if (row == tui.Table.headerRow) {
                return m._style(Style()).bold().foreground(Colors.sky);
              }
              if (col == 0) return m._style(Style()).foreground(Colors.indigo);
              return null;
            })
            .render();

    final blendedBorderTable = m
        ._style(Style())
        .border(Border.rounded)
        .borderForegroundBlend([Colors.rose, Colors.indigo, Colors.teal])
        .borderForegroundBlendOffset(3)
        .padding(0, 1)
        .render(innerTable);

    final left = [
      m._style(Style()).dim().render('tui.Tree (rounded):'),
      tree1,
      '',
      m._style(Style()).dim().render('tui.Tree (heavy + styled):'),
      tree2,
      '',
      m
          ._style(Style())
          .dim()
          .render('tui.Tree (offset + hidden + double-line):'),
      tree3,
    ].join('\n');

    final right = [
      m._style(Style()).dim().render('List (nested):'),
      list1,
      '',
      m._style(Style()).dim().render('List (styled):'),
      list2,
      '',
      m._style(Style()).dim().render('tui.Table (styled + zebra):'),
      table1,
      '',
      m._style(Style()).dim().render('tui.Table (borders + row dividers):'),
      table2,
      '',
      m
          ._style(Style())
          .dim()
          .render('tui.Table (ascii + no columns + offset/height):'),
      table3,
      '',
      m
          ._style(Style())
          .dim()
          .render('tui.Table (blended outer border via Style.border):'),
      blendedBorderTable,
    ].join('\n');

    final columns = Layout.joinHorizontal(VerticalAlign.top, [
      left,
      '   ',
      right,
    ]);

    // Header can wrap when many tabs are present; use the measured line count.
    final topRow0 = m._headerLines + 2;
    final contentHeight = (m._height - m._headerLines - m._footerLines - 1)
        .clamp(0, 9999);
    final bodyHeight = (contentHeight - 2).clamp(1, 9999);

    final viewportWidth = (m._width - 2).clamp(10, 9999);
    _pane.viewport = _pane.viewport.copyWith(
      width: viewportWidth,
      height: bodyHeight,
    );
    _pane.viewport = _pane.viewport.setContent(columns);
    _pane.originX = 0;
    _pane.originY = topRow0;

    final pane = _pane.view();

    return [title, '', pane].join('\n');
  }

  @override
  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) {
    final (_, cmd) = _pane.update(tui.KeyMsg(key));
    if (cmd != null) cmds.add(cmd);
    return false;
  }

  @override
  void onMsg(_KitchenSinkModel m, tui.Msg msg, List<tui.Cmd> cmds) {
    if (msg is! tui.MouseMsg) return;
    final (_, cmd) = _pane.update(msg);
    if (cmd != null) cmds.add(cmd);
  }
}

final class _ColorsPage extends _KitchenSinkPage {
  const _ColorsPage()
    : super(
        help:
            'Colors: shows background detection + adaptive colors + gradients',
      );

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Colors + theme detection');
    final bg = m.capabilities.backgroundColor;
    final bgStr = bg != null ? 'rgb(${bg.r},${bg.g},${bg.b})' : '(unknown)';
    final detected = m
        ._style(Style())
        .dim()
        .render(
          'background=${m._theme.backgroundHex ?? '(unknown)'} (UV: $bgStr)  dark=${m._theme.hasDarkBackground ?? '(unknown)'}',
        );

    final adaptive = m._style(Style())
      ..foreground(AdaptiveColor(light: Colors.black, dark: Colors.white));
    final adaptiveChip = adaptive
        .background(AdaptiveColor(light: Colors.white, dark: Colors.black))
        .padding(0, 1)
        .render('AdaptiveColor chip');

    final demoWidth = (m._width - 8).clamp(10, 80);
    final stops = <Color>[Colors.red, Colors.blue, Colors.green];
    final grad = blend1D(
      demoWidth,
      stops,
      hasDarkBackground: m._theme.hasDarkBackground ?? true,
    );
    final bar = grad
        .map((c) => m._style(Style())..background(c))
        .map((s) => s.render(' '))
        .join();

    final box = m
        ._style(Style())
        .border(Border.rounded)
        .borderForegroundBlend([Colors.red, Colors.blue])
        .borderForegroundBlendOffset(2)
        .padding(0, 1)
        .render('Border foreground blend');

    final grid = m._render2dGradient();

    return [
      title,
      detected,
      '',
      adaptiveChip,
      '',
      m._style(Style()).dim().render('1D gradient (blend1D):'),
      bar,
      '',
      m._style(Style()).dim().render('Border blend + offset:'),
      box,
      '',
      m._style(Style()).dim().render('2D gradient (blend2D):'),
      grid,
    ].join('\n');
  }
}

final class _WriterPage extends _KitchenSinkPage {
  const _WriterPage()
    : super(
        help:
            'Writer: downsampling (trueColor→ansi256/ansi/noColor/ascii) demos',
      );

  @override
  String view(_KitchenSinkModel m) {
    final title = m
        ._style(Style())
        .bold()
        .render('Writer (downsampling demos)');
    final hint = m
        ._style(Style())
        .dim()
        .render(
          'These show how our v2-style Writer can downsample ANSI sequences for different terminal profiles.',
        );

    final sample = m
        ._style(Style())
        .bold()
        .foreground(Colors.rose)
        .background(Colors.black)
        .padding(0, 1)
        .render('Who wants marmalade? 🍊');

    String sim(ColorProfile p) => stringForProfile(sample, p);

    final rows = <String>[
      m._style(Style()).dim().render('trueColor:'),
      sim(ColorProfile.trueColor),
      '',
      m._style(Style()).dim().render('ansi256:'),
      sim(ColorProfile.ansi256),
      '',
      m._style(Style()).dim().render('ansi16:'),
      sim(ColorProfile.ansi),
      '',
      m._style(Style()).dim().render('noColor (keep attrs):'),
      sim(ColorProfile.noColor),
      '',
      m._style(Style()).dim().render('ascii (strip all):'),
      sim(ColorProfile.ascii),
    ];

    return [title, '', hint, '', ...rows].join('\n');
  }
}

final class _UnicodePage extends _KitchenSinkPage {
  const _UnicodePage()
    : super(help: 'Unicode: width + grapheme clipping samples');

  @override
  String view(_KitchenSinkModel m) {
    final title = m
        ._style(Style())
        .bold()
        .render('Unicode width + grapheme clusters');
    final hint = m
        ._style(Style())
        .dim()
        .render(
          'If you see boxes, your terminal font lacks emoji glyphs. Press "e" to toggle emoji samples.',
        );
    final samples = <String>[
      'ASCII: hello',
      'CJK: 漢字かなカナ',
      'Emoji: ${m.emoji('🍕🍔🌮', '[pizza][burger][taco]')}',
      'Flags: ${m.emoji('🇺🇸🇯🇵🇫🇷', '[US][JP][FR]')}',
      'ZWJ: ${m.emoji('👩‍💻👨‍👩‍👧‍👦', '[coder][family]')}',
      'Combining: e\u0301  a\u0308  n\u0303',
    ];

    final rows = <String>[];
    for (final s in samples) {
      final graphemes = uni.graphemes(s).toList(growable: false);
      rows.add(
        '${m._style(Style()).dim().render('w=${Style.visibleLength(s).toString().padLeft(2)}  g=${graphemes.length.toString().padLeft(2)}')}  ${_clipToWidth(s, m._width - 10)}',
      );
    }

    final explain = m
        ._style(Style())
        .dim()
        .render(
          'The widths above use ANSI-aware display width and grapheme iteration; compare with resize + renderer.',
        );

    return [title, hint, '', ...rows, '', explain].join('\n');
  }
}
