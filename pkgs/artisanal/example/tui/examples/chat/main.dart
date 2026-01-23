/// Chat textarea + viewport example ported from Bubble Tea.
library;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/artisanal.dart' show AnsiColor, Style;

const _gap = '\n\n';

class ChatModel implements tui.Model {
  ChatModel({
    required this.viewport,
    required this.textarea,
    List<String>? messages,
    this.senderStyle,
    this.error,
  }) : messages = messages ?? [];

  final tui.ViewportModel viewport;
  final tui.TextAreaModel textarea;
  final List<String> messages;
  final Style? senderStyle;
  final Object? error;

  ChatModel copyWith({
    tui.ViewportModel? viewport,
    tui.TextAreaModel? textarea,
    List<String>? messages,
    Style? senderStyle,
    Object? error,
  }) {
    return ChatModel(
      viewport: viewport ?? this.viewport,
      textarea: textarea ?? this.textarea,
      messages: messages ?? this.messages,
      senderStyle: senderStyle ?? this.senderStyle,
      error: error ?? this.error,
    );
  }

  @override
  tui.Cmd? init() => textarea.focus();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    var cmds = <tui.Cmd>[];

    // Update textarea and viewport first
    final (newTa, taCmd) = textarea.update(msg);
    final (newVp, vpCmd) = viewport.update(msg);
    if (taCmd != null) cmds.add(taCmd);
    if (vpCmd != null) cmds.add(vpCmd);

    switch (msg) {
      case tui.WindowSizeMsg(:final width, :final height):
        final vpWidth = width;
        final taHeight = textarea.height;
        final vpHeight = (height - taHeight - Style.visibleLength(_gap)).clamp(
          1,
          height,
        );

        final resizedTa = newTa
          ..setWidth(vpWidth)
          ..setHeight(taHeight);
        final resizedVp = (newVp).copyWith(width: vpWidth, height: vpHeight);

        final wrapped = Style().width(vpWidth).render(messages.join('\n'));
        final updatedVp = resizedVp.setContent(wrapped).gotoBottom();
        return (
          copyWith(textarea: resizedTa, viewport: updatedVp),
          cmds.isEmpty ? null : tui.Cmd.batch(cmds),
        );

      case tui.KeyMsg(key: final key):
        if (key.ctrl && key.runes.isNotEmpty && key.runes.first == 0x63 ||
            key.type == tui.KeyType.escape) {
          // Print textarea contents on exit, like Bubble Tea.
          return (
            this,
            tui.Cmd.sequence([tui.Cmd.println(textarea.value), tui.Cmd.quit()]),
          );
        }

        if (key.type == tui.KeyType.enter &&
            !key.alt &&
            !key.ctrl &&
            !key.shift &&
            !textarea.keyMap.insertNewline.enabled) {
          final you = (senderStyle ?? Style().foreground(const AnsiColor(5)))
              .render('You: ');
          final updatedMessages = [...messages, '$you${textarea.value}'];

          final content = Style()
              .width(viewport.width)
              .render(updatedMessages.join('\n'));

          final newViewport = viewport.setContent(content).gotoBottom();
          textarea.reset();

          return (
            copyWith(
              messages: updatedMessages,
              viewport: newViewport,
              textarea: textarea,
            ),
            cmds.isEmpty ? null : tui.Cmd.batch(cmds),
          );
        }
    }

    return (
      copyWith(textarea: newTa, viewport: newVp),
      cmds.isEmpty ? null : tui.Cmd.batch(cmds),
    );
  }

  @override
  String view() => '${viewport.view()}$_gap${textarea.view()}';
}

ChatModel _initialModel() {
  final ta =
      tui.TextAreaModel(
          placeholder: 'Send a message...',
          prompt: '┃ ',
          charLimit: 280,
          showLineNumbers: false,
        )
        ..setWidth(30)
        ..setHeight(3);

  // Disable insert-newline to match Bubble Tea (Enter submits).
  ta.keyMap.insertNewline.enabled = false;

  // Remove cursor line styling
  // (Styling kept default)

  final vp = tui.ViewportModel(width: 30, height: 5).setContent(
    'Welcome to the chat room!\n'
    'Type a message and press Enter to send.',
  );

  return ChatModel(
    textarea: ta,
    viewport: vp,
    messages: const [],
    senderStyle: Style().foreground(const AnsiColor(5)),
  );
}

Future<void> main() async {
  await tui.runProgram(
    _initialModel(),
    options: const tui.ProgramOptions(
      altScreen: false,
      hideCursor: false,
      mouse: false,
    ),
  );
}
