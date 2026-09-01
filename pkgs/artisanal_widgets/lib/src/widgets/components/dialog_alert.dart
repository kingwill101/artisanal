import 'dart:async';

import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal_widgets/widgets.dart';

import 'package:artisanal/runtime.dart';

/// A simple alert dialog with a title, message, and OK button.
///
/// Uses [DialogThemeData] for styling when available.
///
/// ```dart
/// DialogAlert.show(
///   context,
///   title: 'Connection Error',
///   message: 'Could not reach the server. Please try again.',
/// );
/// ```
class DialogAlert extends StatefulWidget {
  DialogAlert({
    required this.title,
    this.message,
    this.buttonLabel = 'OK',
    this.onDismiss,
    super.key,
  });

  /// The dialog title (displayed bold).
  final String title;

  /// Optional message body.
  final String? message;

  /// Label for the dismiss button.
  final String buttonLabel;

  /// Called when the dialog is dismissed (enter, esc, or button click).
  final CmdCallback? onDismiss;

  /// Show an alert dialog.
  ///
  /// The dialog is pushed via [Navigator.showDialog] and dismissed when
  /// the user presses Enter, Escape, or clicks the OK button.
  ///
  /// Returns a [Future] that completes when the dialog is dismissed.
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    String buttonLabel = 'OK',
    CmdCallback? onDismiss,
  }) {
    return Navigator.of(context)
        .showDialog<void>(
          builder: (ctx) => DialogAlert(
            title: title,
            message: message,
            buttonLabel: buttonLabel,
            onDismiss: () {
              Navigator.of(ctx).pop();
              onDismiss?.call();
              return null;
            },
          ),
        )
        .then((_) => null);
  }

  @override
  State createState() => _DialogAlertState();
}

class _DialogAlertState extends State<DialogAlert> {
  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is! KeyMsg) return null;
    final key = msg.key;

    if (key.type == terminal_keys.KeyType.escape ||
        key.type == terminal_keys.KeyType.enter) {
      return widget.onDismiss?.call();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final dTheme = theme.dialogTheme;

    final bg = dTheme?.background ?? theme.surface;
    final fg = dTheme?.foreground ?? theme.onSurface;
    final hintFg = dTheme?.hintForeground ?? theme.muted;
    final w = dTheme?.width ?? 60;

    final titleStyle = copyStyle(theme.titleMedium)..foreground(fg);
    final msgStyle = copyStyle(theme.bodyMedium)..foreground(hintFg);
    final escStyle = copyStyle(theme.bodySmall)..foreground(hintFg);

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
                  onTap: widget.onDismiss,
                  child: Text('esc', style: escStyle),
                ),
              ],
            ),
            // Message
            if (widget.message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(widget.message!, style: msgStyle),
              ),
            // OK button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionButton(
                  label: widget.buttonLabel,
                  isSelected: true,
                  onTap: widget.onDismiss,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
