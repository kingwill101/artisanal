// Text Widget Showcase
//
// Demonstrates Text, Text.rich, TextSpan, Label, TextAlign, TextOverflow,
// and styled text with theme typography.
//
// Run with: dart run example/text/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(TextShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class TextShowcase extends w.StatefulWidget {
  TextShowcase({super.key});

  @override
  w.State createState() => _TextShowcaseState();
}

class _TextShowcaseState extends w.State<TextShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Container(
        child: w.Scrollbar(
          controller: _scrollController,
          thickness: 1,
          gap: 1,
          enableHover: true,
          trackChar: ' ',
          thumbChar: ' ',
          trackUsesBackground: true,
          thumbUsesBackground: true,
          trackGradient: w.ScrollbarGradient.background(
            start: w.hasDarkBackground
                ? const BasicColor('#2f363d')
                : const BasicColor('#e3e7eb'),
            end: w.hasDarkBackground
                ? const BasicColor('#1f252a')
                : const BasicColor('#d3d9e0'),
          ),
          thumbGradient: w.ScrollbarGradient.background(
            start: w.hasDarkBackground
                ? const BasicColor('#3fb2ff')
                : const BasicColor('#2f7df6'),
            end: w.hasDarkBackground
                ? const BasicColor('#7c5cff')
                : const BasicColor('#6e55f5'),
          ),
          hoverThumbGradient: w.ScrollbarGradient.background(
            start: w.hasDarkBackground
                ? const BasicColor('#79ddff')
                : const BasicColor('#4f93ff'),
            end: w.hasDarkBackground
                ? const BasicColor('#b18bff')
                : const BasicColor('#836bff'),
          ),
          hoverThumbChar: ' ',
          child: w.ScrollView(
            controller: _scrollController,
            handleKeys: true,
            child: w.Column(
              gap: 1,
              children: [
                w.Text('Text Widget Showcase', style: theme.titleLarge),
                w.Text('Press q to quit.', style: label),
                w.Divider(width: 50),

                // -- Plain text with theme typography --
                w.Text('Theme Typography', style: theme.titleMedium),
                w.Text('titleLarge', style: theme.titleLarge),
                w.Text('titleMedium', style: theme.titleMedium),
                w.Text('titleSmall', style: theme.titleSmall),
                w.Text('bodyLarge', style: theme.bodyLarge),
                w.Text('bodyMedium', style: theme.bodyMedium),
                w.Text('bodySmall', style: theme.bodySmall),
                w.Text('labelLarge', style: theme.labelLarge),
                w.Text('labelMedium', style: theme.labelMedium),
                w.Text('labelSmall', style: theme.labelSmall),
                w.Divider(width: 50),

                // -- Styled text --
                w.Text('Custom Styles', style: theme.titleMedium),
                w.Text(
                  'Bold text',
                  style: Style().bold().foreground(theme.primary),
                ),
                w.Text(
                  'Italic text',
                  style: Style().italic().foreground(theme.secondary),
                ),
                w.Text(
                  'Underline',
                  style: Style().underline().foreground(theme.success),
                ),
                w.Text(
                  'Strikethrough',
                  style: Style().strikethrough().foreground(theme.error),
                ),
                w.Divider(width: 50),

                // -- Text.rich with TextSpan --
                w.Text('Rich Text (TextSpan)', style: theme.titleMedium),
                w.Text.rich(
                  w.TextSpan(
                    children: [
                      w.TextSpan(
                        text: 'Hello ',
                        style: Style().foreground(theme.primary),
                      ),
                      w.TextSpan(
                        text: 'colorful ',
                        style: Style().foreground(theme.warning).bold(),
                      ),
                      w.TextSpan(
                        text: 'world!',
                        style: Style().foreground(theme.success).italic(),
                      ),
                    ],
                  ),
                ),
                w.Divider(width: 50),

                // -- Text overflow with maxWidth --
                w.Text(
                  'Text Overflow (maxWidth: 25)',
                  style: theme.titleMedium,
                ),
                w.Text(
                  'This text is clipped at 25',
                  overflow: w.TextOverflow.clip,
                  maxWidth: 25,
                  style: label,
                ),
                w.Text(
                  'This text has ellipsis at 25',
                  overflow: w.TextOverflow.ellipsis,
                  maxWidth: 25,
                  style: label,
                ),
                w.Divider(width: 50),

                // -- Label (extends Text) --
                w.Text('Label Widget', style: theme.titleMedium),
                w.Label('A simple label', style: label),
                w.Label.styled(
                  'Styled label',
                  style: Style().bold().foreground(theme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }
}
