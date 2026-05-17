part of 'components_widgets.dart';

/// A compact, styled button designed for use in dialog footers and inline
/// prompt panels.
///
/// Unlike [Button], which is a full-featured button with multiple variants
/// and sizes, [ActionButton] is intentionally simple: a text label wrapped
/// in a colored container that responds to hover, selection, and tap.
///
/// Uses [DialogThemeData] for colors when available, falling back to
/// semantic theme colors.
///
/// ```dart
/// ActionButton(
///   label: 'Allow once',
///   isSelected: _selectedIndex == 0,
///   onTap: () => _handleAllow(),
/// )
/// ```
class ActionButton extends StatefulWidget {
  ActionButton({
    required this.label,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
    this.background,
    this.selectedBackground,
    this.foreground,
    this.selectedForeground,
    this.padding,
    super.key,
  });

  /// The button label text.
  final String label;

  /// Whether this button is currently selected/active.
  final bool isSelected;

  /// Whether the button is disabled and non-interactive.
  final bool isDisabled;

  /// Called when the button is tapped.
  final CmdCallback? onTap;

  /// Background color override (default state).
  final Color? background;

  /// Background color override (selected state).
  final Color? selectedBackground;

  /// Text color override (default state).
  final Color? foreground;

  /// Text color override (selected state).
  final Color? selectedForeground;

  /// Padding inside the button.
  /// Defaults to horizontal: 1, vertical: 0.
  final EdgeInsets? padding;

  @override
  State createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() {
      _hovered = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final dTheme = theme.dialogTheme;

    final defaultBg =
        widget.background ??
        dTheme?.buttonBackground ??
        theme.resolvedSurfaceVariant;
    final selectedBg =
        widget.selectedBackground ??
        dTheme?.buttonSelectedBackground ??
        theme.resolvedHighlight;
    final defaultFg =
        widget.foreground ?? dTheme?.buttonForeground ?? theme.onSurface;
    final selectedFg =
        widget.selectedForeground ??
        dTheme?.buttonSelectedForeground ??
        theme.resolvedOnHighlight;

    final isActive = widget.isSelected || _hovered;
    final bg = widget.isDisabled
        ? theme.muted
        : isActive
        ? selectedBg
        : defaultBg;
    final fg = widget.isDisabled
        ? theme.onSurface
        : isActive
        ? selectedFg
        : defaultFg;

    final pad =
        widget.padding ??
        const EdgeInsets.symmetric(horizontal: 1, vertical: 0);

    final style = copyStyle(theme.labelMedium)..foreground(fg);

    Widget button = Frame(
      padding: pad,
      background: bg,
      child: Text(widget.label, style: style),
    );

    if (!widget.isDisabled && widget.onTap != null) {
      button = GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) {
            _setHovered(true);
            return Cmd.none();
          },
          onExit: (_) {
            _setHovered(false);
            return Cmd.none();
          },
          child: button,
        ),
      );
    }

    return button;
  }
}
