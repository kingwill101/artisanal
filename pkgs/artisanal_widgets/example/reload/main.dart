import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main(List<String> args) async {
  final config = _parseArgs(args);
  final controller = w.ReloadController();

  try {
    if (config.watchRoots.isEmpty) {
      await w.runReloadableArtisanalApp(
        title: 'Reload Host Showcase',
        controller: controller,
        homeBuilder: (context, revision) => ReloadShowcaseScreen(
          revision: revision,
          watchRoots: config.watchRoots,
          watchMode: config.watchMode,
        ),
      );
    } else {
      await w.runWatchedArtisanalApp(
        title: 'Reload Host Showcase',
        controller: controller,
        watchRoots: config.watchRoots,
        watchMode: config.watchMode,
        homeBuilder: (context, revision) => ReloadShowcaseScreen(
          revision: revision,
          watchRoots: config.watchRoots,
          watchMode: config.watchMode,
        ),
      );
    }
  } finally {
    await controller.dispose();
  }
}

class ReloadShowcaseScreen extends w.StatefulWidget {
  ReloadShowcaseScreen({
    required this.revision,
    this.watchRoots = const <String>[],
    this.watchMode = w.ReloadMode.reload,
    super.key,
  });

  final int revision;
  final List<String> watchRoots;
  final w.ReloadMode watchMode;

  @override
  w.State<ReloadShowcaseScreen> createState() => _ReloadShowcaseScreenState();
}

class _ReloadShowcaseScreenState extends w.State<ReloadShowcaseScreen> {
  static int _mountCounter = 0;
  late final int _instanceId;

  @override
  void initState() {
    super.initState();
    _mountCounter++;
    _instanceId = _mountCounter;
  }

  w.ReloadController get _reload => w.ReloadScope.of(context);

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;
    if (msg.key.char == 'q') return tui.Cmd.quit();
    if (msg.key.type == KeyType.f5) {
      _reload.reload();
      return tui.Cmd.none();
    }
    if (msg.key.type == KeyType.f6) {
      _reload.restart();
      return tui.Cmd.none();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final subtle = theme.bodySmall.copy()..foreground(theme.muted);

    return w.Container(
      padding: const w.EdgeInsets.all(2),
      color: theme.background,
      child: w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Text('Reload Host Showcase', style: theme.titleLarge),
          w.Text('F5 reload | F6 restart | q quit', style: subtle),
          w.Divider(width: 60),
          w.Text('Revision: ${widget.revision}', style: theme.titleMedium),
          w.Text('Mounted instance: $_instanceId', style: theme.bodyMedium),
          if (widget.watchRoots.isNotEmpty)
            w.Text(
              'Watching: ${widget.watchRoots.join(", ")} (${widget.watchMode.name})',
              style: subtle,
              overflow: w.TextOverflow.ellipsis,
              maxWidth: 72,
            ),
          w.Text(
            'Reload reruns the builder while preserving compatible state. Restart forces a fresh mount.',
            style: subtle,
          ),
        ],
      ),
    );
  }
}

final class _ReloadExampleConfig {
  const _ReloadExampleConfig({
    required this.watchRoots,
    required this.watchMode,
  });

  final List<String> watchRoots;
  final w.ReloadMode watchMode;
}

_ReloadExampleConfig _parseArgs(List<String> args) {
  final watchRoots = <String>[];
  var watchMode = w.ReloadMode.reload;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--watch' && i + 1 < args.length) {
      watchRoots.add(args[++i]);
      continue;
    }
    if (arg.startsWith('--watch=')) {
      watchRoots.add(arg.substring('--watch='.length));
      continue;
    }
    if (arg == '--restart') {
      watchMode = w.ReloadMode.restart;
    }
  }

  return _ReloadExampleConfig(
    watchRoots: watchRoots,
    watchMode: watchMode,
  );
}
