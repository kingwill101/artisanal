/// Shortcuts discovery UI over [tui.ShortcutBinding] / [tui.KeymapHub].
library;

import 'package:artisanal/style.dart' as style show Border, Color;
import 'package:artisanal/runtime.dart' as tui;

import '../components/frame.dart';
import '../components/help_view.dart';
import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../core/widget.dart' show Widget;
import '../layout/column.dart';
import '../layout/enums.dart' show CrossAxisAlignment, MainAxisSize;
import '../core/key.dart' show Key;
import '../layout/sized_box.dart';
import '../layout/spacing.dart' show EdgeInsets;
import '../layout/text.dart';
import '../theme/theme_scope.dart' show ThemeScope;
import 'keymap_hub_scope.dart';

/// Modal-friendly panel listing shortcuts for the active surface (and
/// optionally reachable parents).
///
/// Built from the same [tui.ShortcutBinding] catalog used for dispatch — not a
/// second hand-maintained help list.
///
/// ```dart
/// ShortcutsSheet.forHub(hub)
/// ShortcutsSheet(bindings: sessionBindings, title: 'Session')
/// ```
class ShortcutsSheet extends StatelessWidget {
  ShortcutsSheet({
    required this.bindings,
    this.title = 'Shortcuts',
    this.subtitle,
    this.footerHint = 'esc close',
    this.maxWidth = 72,
    this.background,
    this.borderColor,
    this.titleColor,
    this.mutedColor,
    super.key,
  });

  /// Catalog to display.
  final List<tui.ShortcutBinding> bindings;

  /// Header title.
  final String title;

  /// Optional line under the title (e.g. surface id).
  final String? subtitle;

  /// Footer hint (dismiss instruction).
  final String footerHint;

  final int maxWidth;
  final style.Color? background;
  final style.Color? borderColor;
  final style.Color? titleColor;
  final style.Color? mutedColor;

  /// Sheet for the hub's active shortcuts.
  factory ShortcutsSheet.forHub(
    tui.KeymapHub hub, {
    bool includeReachable = false,
    String title = 'Shortcuts',
    String? subtitle,
    String footerHint = 'esc close',
    int maxWidth = 72,
    style.Color? background,
    style.Color? borderColor,
    Key? key,
  }) {
    final top = hub.top;
    return ShortcutsSheet(
      key: key,
      bindings: hub.activeShortcuts(includeReachable: includeReachable),
      title: title,
      subtitle: subtitle ??
          (top == null
              ? null
              : (includeReachable ? 'this view + reachable' : top.id)),
      footerHint: footerHint,
      maxWidth: maxWidth,
      background: background,
      borderColor: borderColor,
    );
  }

  /// Sheet for the nearest [KeymapHubScope], or empty bindings if none.
  factory ShortcutsSheet.of(
    BuildContext context, {
    bool includeReachable = false,
    String title = 'Shortcuts',
  }) {
    final hub = KeymapHubScope.maybeOf(context);
    if (hub == null) {
      return ShortcutsSheet(bindings: const [], title: title);
    }
    return ShortcutsSheet.forHub(
      hub,
      includeReachable: includeReachable,
      title: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = background ?? theme.surface;
    final border = borderColor ?? theme.border;
    final titleStyle = theme.labelLarge.copy()
      ..foreground(titleColor ?? theme.primary)
      ..bold();
    final mutedStyle = theme.bodySmall.copy()
      ..foreground(mutedColor ?? theme.muted);

    final keyMap = tui.keyMapFromShortcutBindings(bindings);

    return SizedBox(
      width: maxWidth.toDouble(),
      child: Frame(
        padding: const EdgeInsets.all(1),
        background: bg,
        border: style.Border.rounded,
        borderColor: border,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          gap: 1,
          children: [
            Text(title, style: titleStyle),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(subtitle!, style: mutedStyle),
            if (bindings.isEmpty)
              Text('No shortcuts for this view', style: mutedStyle)
            else
              HelpView(
                keyMap: keyMap,
                showAll: true,
                columnGap: 3,
                rowGap: 0,
              ),
            Text(footerHint, style: mutedStyle),
          ],
        ),
      ),
    );
  }
}
