// TextStyle showcase
//
// Demonstrates immutable text declarations, Style composition, nested span
// inheritance and resets, selectable text, decorations, and ASCII-art fonts.
//
// Run from the workspace root with:
// dart run pkgs/artisanal_widgets/example/text_style/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/selection.dart' as w;

Future<void> main() async {
  final app = w.WidgetApp(TextStyleShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

/// A runnable catalog of Artisanal's immutable terminal text styling.
class TextStyleShowcase extends w.StatefulWidget {
  TextStyleShowcase({super.key});

  @override
  w.State createState() => _TextStyleShowcaseState();
}

class _TextStyleShowcaseState extends w.State<TextStyleShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final labelStyle = theme.labelSmall.copy()..foreground(theme.onBackground);
    final sectionStyle = theme.titleMedium.copy()
      ..foreground(theme.onBackground);

    final baseTextStyle = TextStyle(
      color: theme.primary,
      fontWeight: FontWeight.bold,
    );
    final copiedTextStyle = baseTextStyle.copyWith(
      color: theme.warning,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
    );
    final mergedTextStyle = baseTextStyle.merge(
      const TextStyle(fontStyle: FontStyle.italic),
    );
    final combinedDecoration = TextDecoration.combine(const [
      TextDecoration.underline,
      TextDecoration.lineThrough,
    ]);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        enableHover: true,
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Column(
            gap: 1,
            children: [
              w.Text('TextStyle Showcase', style: theme.titleLarge),
              w.Text(
                'Scroll to explore. Drag selectable text. Press q to quit.',
                style: labelStyle,
              ),
              w.Divider(width: 72),

              w.Text('Immutable declarations', style: sectionStyle),
              w.Text('base: primary + bold', textStyle: baseTextStyle),
              w.Text(
                'copyWith: warning + bold + wavy underline',
                textStyle: copiedTextStyle,
              ),
              w.Text(
                'merge: inherited primary + bold, child adds italic',
                textStyle: mergedTextStyle,
              ),
              w.Divider(width: 72),

              w.Text('Style composition', style: sectionStyle),
              w.Text(
                'Style keeps block layout; TextStyle overlays text only',
                style: Style()
                  ..padding(0, 1)
                  ..border(Border.rounded)
                  ..borderForeground(theme.primary),
                textStyle: TextStyle(
                  color: theme.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              w.Divider(width: 72),

              w.Text(
                'Nested inheritance and explicit resets',
                style: sectionStyle,
              ),
              w.Text.rich(
                w.TextSpan(
                  text: 'parent bold + underlined | ',
                  textStyle: TextStyle(
                    color: theme.secondary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  children: [
                    const w.TextSpan(text: 'child inherits | '),
                    const w.TextSpan(
                      text: 'normal italic, no underline | ',
                      textStyle: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    w.TextSpan(
                      text: 'inherit false starts from defaults',
                      textStyle: TextStyle(
                        inherit: false,
                        color: theme.success,
                      ),
                    ),
                  ],
                ),
              ),
              w.Divider(width: 72),

              w.Text(
                'Decorations and terminal attributes',
                style: sectionStyle,
              ),
              w.Text(
                'underline + line-through + reverse video',
                textStyle: TextStyle(
                  color: theme.info,
                  decoration: combinedDecoration,
                  decorationColor: theme.primary,
                  decorationStyle: TextDecorationStyle.double,
                  reverse: true,
                ),
              ),
              w.Divider(width: 72),

              w.Text('Selectable text uses the same API', style: sectionStyle),
              w.SelectionArea(
                child: w.Column(
                  children: [
                    w.SelectableText(
                      'SelectableText: drag across this styled sentence.',
                      textStyle: TextStyle(
                        color: theme.success,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    w.SelectableRichText(
                      textStyle: TextStyle(
                        color: theme.onBackground,
                        fontWeight: FontWeight.dim,
                      ),
                      text: const w.TextSpan(
                        text: 'SelectableRichText: dim parent, ',
                        children: [
                          w.TextSpan(
                            text: 'bold child.',
                            textStyle: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              w.Divider(width: 72),

              w.Text('ASCII-art font catalog', style: sectionStyle),
              w.Text(
                'Full words render at each font\'s native glyph width; the host '
                'still owns the terminal typeface and cell size.',
                style: labelStyle,
              ),
              w.Column(
                gap: 1,
                crossAxisAlignment: w.CrossAxisAlignment.start,
                children: [
                  _asciiFontSample(
                    'Standard Font:',
                    'HELLO',
                    w.AsciiFont.standard,
                    Colors.green,
                  ),
                  _asciiFontSample(
                    'Banner Font:',
                    'WORLD',
                    w.AsciiFont.banner,
                    Colors.magenta,
                  ),
                  _asciiFontSample(
                    'Block Font:',
                    'BOLD',
                    w.AsciiFont.block,
                    Colors.red,
                  ),
                  _asciiFontSample(
                    'Slim Font:',
                    'THIN',
                    w.AsciiFont.slim,
                    Colors.blue,
                  ),
                  _asciiFontSample(
                    'Numbers:',
                    '12345',
                    w.AsciiFont.standard,
                    Colors.white,
                  ),
                  _asciiFontSample(
                    'Punctuation:',
                    'HI!',
                    w.AsciiFont.block,
                    Colors.brightYellow,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  w.Widget _asciiFontSample(
    String name,
    String data,
    w.AsciiFont font,
    Color color,
  ) {
    return w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.start,
      children: [
        w.Text(name, textStyle: const TextStyle(color: Colors.yellow)),
        w.StyledAsciiText(
          data: data,
          font: font,
          style: Style()..foreground(color),
        ),
      ],
    );
  }
}
