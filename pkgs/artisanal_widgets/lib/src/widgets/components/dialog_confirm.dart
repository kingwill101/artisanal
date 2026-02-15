part of 'components_widgets.dart';

/// A simple yes/no confirmation dialog.
///
/// Displays a title, message, and two buttons (Cancel / Confirm) with
/// left/right arrow navigation to select between them.
///
/// Uses [DialogThemeData] for styling when available.
///
/// ```dart
/// final confirmed = await DialogConfirm.show(
///   context,
///   title: 'Delete session?',
///   message: 'This action cannot be undone.',
/// );
/// ```
class DialogConfirm extends StatefulWidget {
  DialogConfirm({
    required this.title,
    this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    super.key,
  });

  /// The dialog title (displayed bold).
  final String title;

  /// Optional message body (displayed in muted color).
  final String? message;

  /// Label for the confirm button.
  final String confirmLabel;

  /// Label for the cancel button.
  final String cancelLabel;

  /// Called when confirm is selected.
  final CmdCallback? onConfirm;

  /// Called when cancel is selected or esc is pressed.
  final CmdCallback? onCancel;

  /// Show a confirmation dialog via [DialogStack].
  ///
  /// Pushes a [DialogConfirm] onto the nearest [DialogStack] and waits
  /// for the user's response.
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    void Function(bool confirmed)? onResult,
  }) {
    final stack = DialogStack.of(context);
    stack.push(
      DialogConfirm(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: () {
          stack.pop();
          onResult?.call(true);
          return null;
        },
        onCancel: () {
          stack.pop();
          onResult?.call(false);
          return null;
        },
      ),
    );
  }

  @override
  State createState() => _DialogConfirmState();
}

class _DialogConfirmState extends State<DialogConfirm> {
  // 0 = cancel, 1 = confirm
  int _selectedIndex = 1;

  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is! KeyMsg) return null;
    final key = msg.key;

    switch (key.type) {
      case terminal_keys.KeyType.escape:
        return widget.onCancel?.call();
      case terminal_keys.KeyType.enter:
        return _selectedIndex == 1
            ? widget.onConfirm?.call()
            : widget.onCancel?.call();
      case terminal_keys.KeyType.left:
        setState(() => _selectedIndex = 0);
        return Cmd.none();
      case terminal_keys.KeyType.right:
        setState(() => _selectedIndex = 1);
        return Cmd.none();
      case terminal_keys.KeyType.tab:
        setState(() => _selectedIndex = (_selectedIndex + 1) % 2);
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
    final w = dTheme?.width ?? 60;

    final titleStyle = _copyStyle(theme.titleMedium)..foreground(fg);
    final msgStyle = _copyStyle(theme.bodyMedium)..foreground(hintFg);
    final escStyle = _copyStyle(theme.bodySmall)..foreground(hintFg);

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
            // Message
            if (widget.message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(widget.message!, style: msgStyle),
              ),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              gap: 1,
              children: [
                ActionButton(
                  label: widget.cancelLabel,
                  isSelected: _selectedIndex == 0,
                  onTap: widget.onCancel,
                ),
                ActionButton(
                  label: widget.confirmLabel,
                  isSelected: _selectedIndex == 1,
                  onTap: widget.onConfirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
