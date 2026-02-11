/// Footer bar widget — matches the real OpenCode bottom status bar.
///
/// Shows: `{directory}  • {N} LSP  ⊙ {N} MCP  /status`
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

import '../theme.dart';

class FooterBar extends w.StatelessWidget {
  FooterBar({
    this.workingDirectory = '~/code/my-project',
    this.lspCount = 0,
    this.mcpCount = 0,
    this.statusHint = '/status',
    super.key,
  });

  final String workingDirectory;
  final int lspCount;
  final int mcpCount;
  final String statusHint;

  @override
  w.Widget build(w.BuildContext context) {
    // Shorten directory for display
    final dir = workingDirectory.length > 30
        ? '...${workingDirectory.substring(workingDirectory.length - 27)}'
        : workingDirectory;

    return w.Container(
      color: OC.background,
      padding: const w.EdgeInsets.only(left: 2, right: 2),
      child: w.Row(
        children: [
          // Directory
          w.Text(dir, style: style.Style()..foreground(OC.textMuted)),

          w.Spacer(),

          // LSP indicator
          w.Row(
            gap: 1,
            children: [
              w.Text('\u2022', style: style.Style()..foreground(OC.success)),
              w.Text(
                '$lspCount LSP',
                style: style.Style()..foreground(OC.textMuted),
              ),
            ],
          ),

          w.SizedBox(width: 2),

          // MCP indicator
          w.Row(
            gap: 1,
            children: [
              w.Text('\u2299', style: style.Style()..foreground(OC.success)),
              w.Text(
                '$mcpCount MCP',
                style: style.Style()..foreground(OC.textMuted),
              ),
            ],
          ),

          w.SizedBox(width: 2),

          // Status hint
          w.Text(statusHint, style: style.Style()..foreground(OC.textMuted)),
        ],
      ),
    );
  }
}
