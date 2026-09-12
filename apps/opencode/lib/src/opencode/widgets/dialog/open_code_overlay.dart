/// OpenCode-style modal overlays: stable Stack (never remounts the app child).
///
/// Unlike [Navigator.showDialog] / the deprecated [Modal] helper, toggling an
/// overlay keeps the navigator element tree intact so routes stay put.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../theme.dart';
import '../model_list_dialog.dart';
import '../session_list_dialog.dart';
import '../theme_list_dialog.dart';
import 'agent_list_dialog.dart';

/// Which OpenCode picker overlay is visible (mutual exclusion).
enum OpenCodeOverlayKind {
  none,
  commands,
  sessions,
  models,
  themes,
  agents,
}

/// Exclusive hub surface id while any overlay is open.
const openCodeOverlaySurfaceId = 'opencode-overlay';

/// Hub surface that blocks route chords while an overlay is open, but still
/// forwards keys to the widget tree (dialog handleIntercept / TextField).
tui.ShortcutSurface openCodeOverlaySurface() {
  return tui.ShortcutSurface(
    id: openCodeOverlaySurfaceId,
    exclusive: true,
    onMessage: (msg) {
      // Claim key messages so lower route surfaces never see leader chords,
      // but re-emit the same KeyMsg for dialog widgets to handle.
      if (msg is tui.KeyMsg) return tui.KeymapLayerClaim(msg);
      return const tui.KeymapLayerPass();
    },
  );
}

/// Stable overlay host: [child] is always the first stack slot.
class OpenCodeOverlayHost extends w.StatelessWidget {
  OpenCodeOverlayHost({
    required this.kind,
    required this.child,
    required this.onDismiss,
    this.commandPalette,
    this.sessionList,
    this.modelList,
    this.themeList,
    this.agentList,
    super.key,
  });

  final OpenCodeOverlayKind kind;
  final w.Widget child;
  final void Function() onDismiss;

  /// Full command palette widget when [kind] is commands (built by parent).
  final w.Widget? commandPalette;

  final SessionListDialog? sessionList;
  final ModelListDialog? modelList;
  final ThemeListDialog? themeList;
  final AgentListDialog? agentList;

  bool get _open => kind != OpenCodeOverlayKind.none;

  @override
  w.Widget build(w.BuildContext context) {
    final dialog = switch (kind) {
      OpenCodeOverlayKind.none => null,
      OpenCodeOverlayKind.commands => commandPalette,
      OpenCodeOverlayKind.sessions => sessionList,
      OpenCodeOverlayKind.models => modelList,
      OpenCodeOverlayKind.themes => themeList,
      OpenCodeOverlayKind.agents => agentList,
    };

    return w.Stack(
      fit: w.StackFit.expand,
      children: [
        w.Opacity(
          opacity: _open ? 0.4 : 1.0,
          child: w.IgnorePointer(
            ignoring: _open,
            child: child,
          ),
        ),
        if (_open && dialog != null) ...[
          w.Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: w.GestureDetector(
              onTap: () {
                onDismiss();
                return null;
              },
              child: w.Container(),
            ),
          ),
          w.Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: w.Center(
              child: w.FocusScope(
                isTrapped: true,
                child: dialog,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Shared OpenCode picker chrome (title, search, body, footer hints).
class OpenCodePickerShell extends w.StatelessWidget {
  OpenCodePickerShell({
    required this.title,
    required this.body,
    required this.footer,
    this.search,
    this.width = 64,
    this.height = 22,
    super.key,
  });

  final String title;
  final w.Widget body;
  final w.Widget footer;
  final w.Widget? search;
  final int width;
  final int height;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final cp = theme.commandPaletteTheme;
    final dialogBg = cp?.background ?? OC.backgroundPanel;
    final dialogFg = cp?.foreground ?? OC.text;
    final shortcutFg = cp?.shortcutForeground ?? OC.textMuted;

    return w.SizedBox(
      width: width.toDouble(),
      height: height.toDouble(),
      child: w.Container(
        color: dialogBg,
        child: w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Container(
              padding: const w.EdgeInsets.only(left: 4, right: 4, top: 1),
              child: w.Row(
                children: [
                  w.Text(
                    title,
                    style: style.Style()
                      ..foreground(dialogFg)
                      ..bold(),
                  ),
                  w.Spacer(),
                  w.Text(
                    'esc',
                    style: style.Style()
                      ..foreground(shortcutFg)
                      ..dim(),
                  ),
                ],
              ),
            ),
            w.SizedBox(height: 1),
            if (search != null) ...[
              search!,
              w.SizedBox(height: 1),
            ],
            w.Expanded(child: body),
            w.Container(
              padding: const w.EdgeInsets.only(left: 4, right: 4, bottom: 1),
              color: dialogBg,
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard footer hint bits for OpenCode pickers.
List<w.Widget> openCodePickerHints({
  required String countLabel,
}) {
  w.Widget key(String t) => w.Text(
        t,
        style: style.Style()
          ..foreground(OC.textMuted)
          ..dim(),
      );
  w.Widget label(String t) => w.Text(
        t,
        style: style.Style()
          ..foreground(OC.textMuted)
          ..dim(),
      );

  return [
    key('↑↓'),
    w.SizedBox(width: 1),
    label('navigate'),
    w.SizedBox(width: 2),
    key('⏎'),
    w.SizedBox(width: 1),
    label('select'),
    w.Spacer(),
    w.Text(
      countLabel,
      style: style.Style()
        ..foreground(OC.textMuted)
        ..dim(),
    ),
  ];
}
