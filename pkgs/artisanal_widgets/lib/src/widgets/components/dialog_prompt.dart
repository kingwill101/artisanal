import 'dart:async';

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal_widgets/widgets.dart';

import 'package:artisanal/tui.dart';

/// A dialog with a text input field.
///
/// Displays a title, optional description, a text input, and submit/cancel
/// via enter/esc.
///
/// Uses [DialogThemeData] for styling when available.
///
/// ```dart
/// DialogPrompt.show(
///   context,
///   title: 'Rename Session',
///   description: 'Enter a new name for this session.',
///   placeholder: 'Session name',
///   onSubmit: (value) => _rename(value),
/// );
/// ```
class DialogPrompt extends StatefulWidget {
  DialogPrompt({
    required this.title,
    this.description,
    this.placeholder,
    this.initialValue,
    this.onSubmit,
    this.onCancel,
    super.key,
  });

  /// The dialog title (displayed bold).
  final String title;

  /// Optional description shown below the title.
  final Widget? description;

  /// Placeholder text for the input field.
  final String? placeholder;

  /// Initial value for the input field.
  final String? initialValue;

  /// Called when the user submits (enter). Receives the input text.
  final void Function(String value)? onSubmit;

  /// Called when the user cancels (esc).
  final CmdCallback? onCancel;

  /// Show a text prompt dialog.
  ///
  /// Returns the submitted text, or `null` if cancelled.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    Widget? description,
    String? placeholder,
    String? initialValue,
  }) {
    return Navigator.of(context).showDialog<String>(
      builder: (ctx) => DialogPrompt(
        title: title,
        description: description,
        placeholder: placeholder,
        initialValue: initialValue,
        onSubmit: (value) {
          Navigator.of(ctx).pop(value);
        },
        onCancel: () {
          Navigator.of(ctx).pop();
          return null;
        },
      ),
    );
  }

  @override
  State createState() => _DialogPromptState();
}

class _DialogPromptState extends State<DialogPrompt> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is! KeyMsg) return null;
    final key = msg.key;

    switch (key.type) {
      case terminal_keys.KeyType.escape:
        return widget.onCancel?.call();
      case terminal_keys.KeyType.enter:
        widget.onSubmit?.call(_controller.text);
        return Cmd.none();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final dTheme = theme.dialogTheme;

    final bg = dTheme?.background ?? theme.surface;
    final fg = dTheme?.foreground ?? theme.onSurface;
    final hintFg = dTheme?.hintForeground ?? theme.muted;
    final searchBg =
        theme.commandPaletteTheme?.searchBackground ?? theme.background;
    final w = dTheme?.width ?? 60;

    final titleStyle = copyStyle(theme.titleMedium)..foreground(fg);
    final escStyle = copyStyle(theme.bodySmall)..foreground(hintFg);
    final hintStyle = copyStyle(theme.bodySmall)..foreground(hintFg);

    return SizedBox(
      width: w,
      child: Frame(
        background: bg,
        padding: const EdgeInsets.only(left: 2, right: 2, top: 1, bottom: 1),
        child: Column(
          gap: 1,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: titleStyle),
                GestureDetector(
                  onTap: widget.onCancel,
                  child: Text('esc', style: escStyle),
                ),
              ],
            ),
            // Description
            if (widget.description != null) widget.description!,
            // Text input
            Frame(
              background: searchBg,
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: TextField(
                controller: _controller,
                focusId: 'dialog-prompt-input',
                prompt: widget.placeholder ?? 'Enter text',
                autofocus: true,
                maxLines: 3,
              ),
            ),
            // Hint
            Text('enter submit', style: hintStyle),
          ],
        ),
      ),
    );
  }
}
