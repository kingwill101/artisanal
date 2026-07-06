/// Footer bar widget — matches the real OpenCode bottom status bar.
///
/// Shows: `{directory}  • {N} LSP  ⊙ {N} MCP  /status`
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:artisanal_widgets/src/widgets/animation/spinner_controller.dart';

import 'state/build_mode.dart';
import '../theme.dart';

class FooterBar extends w.StatelessWidget {
  FooterBar({
    this.workingDirectory = '~/code/my-project',
    this.lspCount = 0,
    this.mcpCount = 0,
    this.statusHint = '/status',
    this.scanner,
    this.tokenCount,
    this.mode = BuildMode.build,
    super.key,
  });

  final String workingDirectory;
  final int lspCount;
  final int mcpCount;
  final String statusHint;
  final SpinnerController? scanner;
  final int? tokenCount;
  final BuildMode mode;

  @override
  w.Widget build(w.BuildContext context) {
    final dir = workingDirectory.length > 30
        ? '...${workingDirectory.substring(workingDirectory.length - 27)}'
        : workingDirectory;

    final activeScanner = scanner;
    final scannerWidget = activeScanner != null && activeScanner.isRunning
        ? w.ValueListenableBuilder<String>(
            valueListenable: activeScanner,
            builder: (context, frame, child) {
              return w.Row(
                gap: 1,
                children: [
                  w.Text(
                    frame,
                    style: style.Style()..foreground(OC.warning),
                  ),
                  w.Text(
                    'Esc to interrupt',
                    style: style.Style()..foreground(OC.warning),
                  ),
                ],
              );
            },
          )
        : null;

    final tokensWidget = tokenCount != null
        ? w.Text(
            '${tokenCount!} tokens',
            style: style.Style()..foreground(OC.textMuted),
          )
        : null;

    return w.Container(
      color: OC.background,
      padding: const w.EdgeInsets.only(left: 2, right: 2),
      child: w.Row(
        children: [
          w.Text(dir, style: style.Style()..foreground(OC.textMuted)),

          w.SizedBox(width: 2),

          w.Expanded(child: w.SizedBox.shrink()),

          if (scannerWidget != null) ...[
            scannerWidget,
            w.SizedBox(width: 2),
          ],
          if (tokensWidget != null) ...[
            tokensWidget,
            w.SizedBox(width: 2),
          ],
          w.Text(mode.label, style: style.Style()..foreground(OC.info)),
          w.SizedBox(width: 2),

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

          w.Text(statusHint, style: style.Style()..foreground(OC.textMuted)),
        ],
      ),
    );
  }
}
