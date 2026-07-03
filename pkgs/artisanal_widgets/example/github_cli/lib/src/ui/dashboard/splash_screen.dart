import 'package:artisanal/style.dart' show Border, HorizontalAlign, VerticalAlign;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

const _splashFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

final class GithubSplashScreen extends w.StatefulWidget {
  GithubSplashScreen({required this.repository, super.key});

  final String? repository;

  @override
  w.State<GithubSplashScreen> createState() => _GithubSplashScreenState();
}

final class _GithubSplashScreenState extends w.State<GithubSplashScreen> {
  final Object _tickToken = Object();
  late final String _tickId = 'github-splash:${identityHashCode(this)}';
  var _frame = 0;

  @override
  tui.Cmd? handleInit() {
    return tui.every(
      const Duration(milliseconds: 120),
      (_) => _GithubSplashTickMsg(_tickToken),
      id: _tickId,
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _GithubSplashTickMsg && identical(msg.token, _tickToken)) {
      setState(() => _frame = (_frame + 1) % 240);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final media = w.MediaQuery.maybeOf(context);
    final width = (media?.size.width.toInt() ?? 96).clamp(52, 96).toInt();
    final panelWidth = (width - 8).clamp(44, 76).toInt();
    final phase = _frame % _splashFrames.length;
    final progress = ((_frame % 36) + 1) / 36;
    final repository = widget.repository ?? 'current repository';

    return w.Center(
      child: w.Frame(
        background: theme.surface,
        border: Border.rounded,
        borderColor: theme.border,
        padding: const w.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: w.Container(
          width: panelWidth,
          child: w.Column(
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            gap: 1,
            children: [
              _logo(theme, phase),
              w.Text(
                'GitHub from inside your terminal',
                style: theme.bodySmall.copy()..foreground(theme.muted),
              ),
              w.Divider(
                width: panelWidth,
                style: theme.bodySmall.copy()..foreground(theme.border),
              ),
              w.Row(
                children: [
                  w.Text(
                    _splashFrames[phase],
                    style: theme.titleMedium.copy()..foreground(theme.warning),
                  ),
                  w.Spacer(size: 1),
                  w.Expanded(
                    child: w.Text(
                      'Loading $repository',
                      style: theme.bodyMedium,
                      overflow: w.TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              w.ProgressIndicator(
                value: progress,
                width: panelWidth - 16,
                progressStyle: w.ProgressStyle.block,
                color: theme.primary,
                trackColor: theme.border,
                showLabel: true,
                label: 'gh',
              ),
              w.Text(
                _scanLine(panelWidth - 2, _frame),
                style: theme.bodySmall.copy()..foreground(theme.primary),
                overflow: w.TextOverflow.clip,
              ),
              w.Wrap(
                spacing: 1,
                runSpacing: 1,
                children: [
                  _chip(theme, 'issues', phase, 0),
                  _chip(theme, 'pull requests', phase, 1),
                  _chip(theme, 'checks', phase, 2),
                  _chip(theme, 'diffs', phase, 3),
                  _chip(theme, 'actions', phase, 4),
                ],
              ),
              w.Text(
                'Running gh commands...',
                style: theme.bodySmall.copy()..foreground(theme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

w.Widget _logo(w.Theme theme, int phase) {
  final active = phase.isEven ? theme.primary : theme.warning;
  return w.Row(
    children: [
      w.Container(
        width: 6,
        height: 3,
        background: active,
        align: HorizontalAlign.center,
        verticalAlign: VerticalAlign.center,
        child: w.Text(
          'GH',
          style: theme.titleMedium.copy()..foreground(theme.onPrimary),
        ),
      ),
      w.Spacer(size: 1),
      w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Text('GHUI', style: theme.titleLarge.copy()..foreground(active)),
          w.Text(
            'queue · inspect · act',
            style: theme.bodySmall.copy()..foreground(theme.muted),
          ),
        ],
      ),
    ],
  );
}

w.Widget _chip(w.Theme theme, String label, int phase, int index) {
  final active = phase == index || phase == index + 5;
  return w.Badge(
    label,
    background: active ? theme.primary : theme.surfaceVariant ?? theme.surface,
    foreground: active ? theme.onPrimary : theme.muted,
    paddingLeft: 1,
    paddingRight: 1,
  );
}

String _scanLine(int width, int frame) {
  final safeWidth = width.clamp(8, 80).toInt();
  final highlight = frame % safeWidth;
  final chars = List<String>.filled(safeWidth, '·');
  chars[highlight] = '◆';
  if (highlight > 0) chars[highlight - 1] = '•';
  if (highlight + 1 < safeWidth) chars[highlight + 1] = '•';
  return chars.join();
}

final class _GithubSplashTickMsg extends tui.Msg {
  const _GithubSplashTickMsg(this.token);

  final Object token;
}
