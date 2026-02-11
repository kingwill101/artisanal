// Text Selection Showcase
//
// Demonstrates SelectableText and SelectionArea for in-app text selection
// with click-drag highlighting and Ctrl+C copy support.
//
// Run with: dart run example/selection/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(SelectionShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class SelectionShowcase extends w.StatefulWidget {
  SelectionShowcase({super.key});

  @override
  w.State createState() => _SelectionShowcaseState();
}

class _SelectionShowcaseState extends w.State<SelectionShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);
    final bodyStyle = theme.bodyMedium.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
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
              w.Text('Text Selection Showcase', style: theme.titleLarge),
              w.Text(
                'Click and drag to select text. Ctrl+C to copy. Press q to quit.',
                style: label,
              ),
              w.Divider(width: 60),

              // -- Section 1: Standalone SelectableText --
              w.Text('1. Standalone SelectableText', style: theme.titleMedium),
              w.Text(
                'Each widget has its own selection controller:',
                style: label,
              ),
              w.Container(
                padding: const w.EdgeInsets.symmetric(horizontal: 2),
                child: w.Column(
                  gap: 0,
                  children: [
                    w.SelectableText(
                      'Click and drag to select this text. '
                      'Release to finalize selection.',
                      style: bodyStyle,
                    ),
                    w.SelectableText(
                      'This is a separate SelectableText with its own controller.',
                      style: bodyStyle,
                    ),
                  ],
                ),
              ),
              w.Divider(width: 60),

              // -- Section 2: SelectionArea (shared controller) --
              w.Text(
                '2. SelectionArea (Shared Controller)',
                style: theme.titleMedium,
              ),
              w.Text(
                'All SelectableText widgets below share one controller:',
                style: label,
              ),
              w.Container(
                padding: const w.EdgeInsets.symmetric(horizontal: 2),
                child: w.SelectionArea(
                  child: w.Column(
                    gap: 0,
                    children: [
                      w.SelectableText(
                        'First paragraph in the selection area. '
                        'Click here to start selecting.',
                        style: bodyStyle,
                      ),
                      w.SelectableText(
                        'Second paragraph sharing the same controller. '
                        'Clicking here clears the previous selection.',
                        style: bodyStyle,
                      ),
                      w.SelectableText(
                        'Third paragraph. All three paragraphs share '
                        'a single SelectionController via SelectionArea.',
                        style: bodyStyle,
                      ),
                    ],
                  ),
                ),
              ),
              w.Divider(width: 60),

              // -- Section 3: Styled SelectableText --
              w.Text('3. Styled SelectableText', style: theme.titleMedium),
              w.Text(
                'SelectableText supports the same style options as Text:',
                style: label,
              ),
              w.Container(
                padding: const w.EdgeInsets.symmetric(horizontal: 2),
                child: w.Column(
                  gap: 0,
                  children: [
                    w.SelectableText(
                      'Bold selectable text',
                      style: Style().bold().foreground(theme.primary),
                    ),
                    w.SelectableText(
                      'Italic selectable text',
                      style: Style().italic().foreground(theme.secondary),
                    ),
                    w.SelectableText(
                      'Underlined selectable text',
                      style: Style().underline().foreground(theme.success),
                    ),
                  ],
                ),
              ),
              w.Divider(width: 60),

              // -- Section 4: Multi-line SelectableText --
              w.Text('4. Multi-line SelectableText', style: theme.titleMedium),
              w.Text(
                'Drag across lines to select multiple lines:',
                style: label,
              ),
              w.Container(
                padding: const w.EdgeInsets.symmetric(horizontal: 2),
                child: w.SelectableText(
                  'Line 1: The quick brown fox jumps over the lazy dog.\n'
                  'Line 2: Pack my box with five dozen liquor jugs.\n'
                  'Line 3: How vexingly quick daft zebras jump.\n'
                  'Line 4: The five boxing wizards jump quickly.',
                  style: bodyStyle,
                ),
              ),
              w.Divider(width: 60),

              // -- Section 5: Double-click word selection --
              w.Text(
                '5. Double-click Word Selection',
                style: theme.titleMedium,
              ),
              w.Text('Double-click on a word to select it:', style: label),
              w.Container(
                padding: const w.EdgeInsets.symmetric(horizontal: 2),
                child: w.SelectableText(
                  'Double-click any word here to select it instantly.',
                  style: bodyStyle,
                ),
              ),
            ],
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
