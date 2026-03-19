import 'dart:async';
import 'dart:io';

import 'package:artisanal/app.dart' as app;
import 'package:artisanal/widgets.dart' as w;

Future<void> main(List<String> args) async {
  final config = _parseArgs(args);
  final controller = app.ReloadController();
  final watchedHost = config.watchRoots.isEmpty
      ? null
      : await app.serveWatchedArtisanalAppInBrowser(
          port: config.port,
          browserTitle: 'Artisanal Widgets Browser Host',
          title: 'Browser Host Demo',
          controller: controller,
          watchRoots: config.watchRoots,
          watchMode: config.watchMode,
          homeBuilder: (context, revision) => _BrowserHostScreen(
            revision: revision,
            watchRoots: config.watchRoots,
            watchMode: config.watchMode,
          ),
        );
  final host =
      watchedHost?.server ??
      await app.serveReloadableArtisanalAppInBrowser(
        port: config.port,
        browserTitle: 'Artisanal Widgets Browser Host',
        title: 'Browser Host Demo',
        controller: controller,
        homeBuilder: (context, revision) => _BrowserHostScreen(
          revision: revision,
          watchRoots: config.watchRoots,
          watchMode: config.watchMode,
        ),
      );

  stdout.writeln('Browser host listening on ${host.pageUri}');
  stdout.writeln('WebSocket endpoint: ${host.webSocketUri}');
  if (config.watchRoots.isNotEmpty) {
    stdout.writeln(
      'Watching ${config.watchRoots.join(", ")} (${config.watchMode.name})',
    );
  }
  stdout.writeln('Press Ctrl+C to stop.');

  StreamSubscription<ProcessSignal>? sigintSubscription;
  try {
    final done = Completer<void>();
    sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
      if (!done.isCompleted) {
        done.complete();
      }
    });
    await done.future;
  } finally {
    await sigintSubscription?.cancel();
    if (watchedHost != null) {
      await watchedHost.close(force: true);
    } else {
      await host.close(force: true);
      await controller.dispose();
    }
  }
}

class _BrowserHostScreen extends w.StatelessWidget {
  _BrowserHostScreen({
    required this.revision,
    required this.watchRoots,
    required this.watchMode,
  });

  final int revision;
  final List<String> watchRoots;
  final app.ReloadMode watchMode;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final subtle = theme.bodySmall.copy()..foreground(theme.muted);

    return w.Container(
      color: theme.background,
      padding: const w.EdgeInsets.all(2),
      child: w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Text('Artisanal Widgets Browser Host', style: theme.titleLarge),
          w.Text('Revision: $revision', style: theme.titleMedium),
          if (watchRoots.isEmpty)
            w.Text(
              'Manual reload host. Pair this with a ReloadController trigger to push updates to every connected browser session.',
              style: subtle,
            )
          else
            w.Text(
              'Watching: ${watchRoots.join(", ")} (${watchMode.name})',
              style: subtle,
              overflow: w.TextOverflow.ellipsis,
              maxWidth: 90,
            ),
          w.Divider(width: 72),
          w.Text(
            'Open the printed URL in a browser to connect through the xterm.js host.',
            style: subtle,
          ),
        ],
      ),
    );
  }
}

final class _BrowserHostExampleConfig {
  const _BrowserHostExampleConfig({
    required this.port,
    required this.watchRoots,
    required this.watchMode,
  });

  final int port;
  final List<String> watchRoots;
  final app.ReloadMode watchMode;
}

_BrowserHostExampleConfig _parseArgs(List<String> args) {
  var port = 8080;
  final watchRoots = <String>[];
  var watchMode = app.ReloadMode.reload;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[++i]) ?? port;
      continue;
    }
    if (arg.startsWith('--port=')) {
      port = int.tryParse(arg.substring('--port='.length)) ?? port;
      continue;
    }
    if (arg == '--watch' && i + 1 < args.length) {
      watchRoots.add(args[++i]);
      continue;
    }
    if (arg.startsWith('--watch=')) {
      watchRoots.add(arg.substring('--watch='.length));
      continue;
    }
    if (arg == '--restart') {
      watchMode = app.ReloadMode.restart;
    }
  }

  return _BrowserHostExampleConfig(
    port: port,
    watchRoots: watchRoots,
    watchMode: watchMode,
  );
}
