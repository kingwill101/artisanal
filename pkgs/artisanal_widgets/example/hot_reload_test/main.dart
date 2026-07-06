/// Minimal WidgetApp hot reload test.
///
/// Run with:
///   dart --enable-vm-service run example/hot_reload_test/main.dart
///
/// Then edit the `_title` string below and save to trigger hot reload.
/// The screen should update automatically without a keypress.
library;

import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal/widgets.dart' as tui;

// ── Change this string and save to test hot reload ──────────────────────
const _title = 'WidgetApp Hot Reload Test (v1)';
// ────────────────────────────────────────────────────────────────────────

void main() async {
  final app = tui.WidgetApp(_HotReloadRoot(), debugRebuilds: true);
  await runtime.runProgram(
    app,
    options: const runtime.ProgramOptions(altScreen: true, hotReload: true),
  );
}

class _HotReloadRoot extends tui.StatelessWidget {
  _HotReloadRoot();

  @override
  (tui.Widget, runtime.Cmd?) handleUpdate(runtime.Msg msg) {
    if (msg is runtime.KeyMsg && msg.key.char == 'q') {
      return (this, runtime.Cmd.quit());
    }

    return (this, null);
  }

  @override
  tui.Widget build(tui.BuildContext context) {
    final theme = tui.ThemeScope.of(context);
    return tui.Container(
      padding: const tui.EdgeInsets.all(2),
      color: theme.background,
      child: tui.Column(
        gap: 1,
        crossAxisAlignment: tui.CrossAxisAlignment.start,
        children: [
          tui.Text(_title, style: theme.titleLarge),
          tui.Divider(width: 50),
          tui.Text(
            'Edit the _title string in this file and save.',
            style: theme.bodyMedium,
          ),
          tui.Text(
            'The title above should update automatically.',
            style: theme.bodySmall,
          ),
          tui.Text('Press q to quit.', style: theme.bodySmall),
        ],
      ),
    );
  }
}
