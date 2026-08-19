import 'dart:math' as math;

import 'package:artisanal_widgets/widgets.dart' as w;

import '../model.dart';
import '../theme.dart';
import '../utils.dart';
import 'panel.dart';

class NetworkPanel extends w.StatelessWidget {
  NetworkPanel({
    required this.state,
    required this.flTheme,
    required this.panelWidth,
    super.key,
  });

  final FlutterCliState state;
  final FlutterCliTheme flTheme;
  final int panelWidth;

  @override
  w.Widget build(w.BuildContext context) {
    final width = panelWidth;
    final urlWidth = math.max(8, width - 31);
    final rows = <w.Widget>[
      w.Text(
        '${'method'.padRight(6)} ${'url'.padRight(urlWidth)} code     ms',
        style: flTheme.dimmed,
        softWrap: false,
      ),
    ];
    if (state.networkRequests.isEmpty) {
      rows.addAll([
        w.Text('No HTTP traffic captured yet.', style: flTheme.dimmed),
        w.Text(
          'Will populate as the app makes requests via `dart:io` or `package:http`.',
          style: flTheme.dimmed,
        ),
      ]);
    } else {
      for (final req in state.networkRequests) {
        final isError =
            req.error != null || (req.status == null && req.durationMs != null);
        final status = isError ? 'ERR' : req.status?.toString() ?? '…';
        final duration = req.durationMs == null ? '…' : '${req.durationMs}ms';
        rows.add(
          w.Text(
            '${req.method.padRight(6)} '
            '${truncate(req.url, urlWidth).padRight(urlWidth)} '
            '${status.padLeft(4)} ${duration.padLeft(6)}',
            style: flTheme.fgStyle(
              isError ? flTheme.error : statusColor(req.status, flTheme),
            ),
            softWrap: false,
          ),
        );
      }
    }
    return FlutterCliPanel(
      title: 'Network',
      flTheme: flTheme,
      child: w.Column(children: rows),
    );
  }
}
