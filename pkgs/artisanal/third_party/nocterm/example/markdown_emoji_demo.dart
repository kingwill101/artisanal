import 'package:nocterm/nocterm.dart';

void main() {
  runApp(const MarkdownEmojiDemo());
}

class MarkdownEmojiDemo extends StatelessComponent {
  const MarkdownEmojiDemo({super.key});

  @override
  Component build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.cyan, width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          width: 60,
          child: const MarkdownText(
            '# Emoji Rendering Test ✨\n\n'
            'This demonstrates **proper emoji handling** in markdown:\n\n'
            '## Features 🎯\n\n'
            '- 🚀 Rocket emoji\n'
            '- ✨ Sparkles emoji\n'
            '- 🎉 Party emoji\n'
            '- 🔥 Fire emoji\n\n'
            '## Mixed Content\n\n'
            'Text before 💻 and after emoji should align correctly.\n\n'
            '**Bold with emoji:** 🌟 This is bold\n\n'
            '*Italic with emoji:* 🎨 This is italic\n\n'
            '## Status Report\n\n'
            '✅ **Fixed:** Emoji width calculation\n'
            '✅ **Fixed:** Text alignment after emojis\n'
            '✅ **Fixed:** Multiple emojis in a row: 🎉 🎊 🎈\n\n'
            '---\n\n'
            'Emoji rendering now works correctly! 🎯',
          ),
        ),
      ),
    );
  }
}
