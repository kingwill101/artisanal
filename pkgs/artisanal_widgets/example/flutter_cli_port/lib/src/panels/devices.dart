import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../model.dart';
import '../theme.dart';
import 'panel.dart';

class DevicesPanel extends w.StatelessWidget {
  DevicesPanel({required this.state, required this.flTheme, super.key});

  final FlutterCliState state;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    final rows = <w.Widget>[];
    if (state.activeSessions.isEmpty) {
      rows.add(w.Text('(aucun)', style: flTheme.dimmed));
    } else {
      for (final session in state.activeSessions) {
        final (glyph, color) = stateGlyph(session.state, flTheme);
        final connection = switch (session.connection) {
          FlutterCliConnectionKind.usb => '⚡ USB',
          FlutterCliConnectionKind.wifi => '🔗 WiFi',
        };
        final platform = session.platform ?? '';
        rows.add(
          w.RichText(
            text: w.TextSpan(
              children: [
                w.TextSpan(text: '$glyph ', style: flTheme.fgStyle(color)),
                w.TextSpan(text: session.displayName, style: flTheme.base),
                w.TextSpan(
                  text:
                      '  ${platformIcon(platform)}  ${platformLabel(platform).padRight(7)} $connection',
                  style: flTheme.dimmed,
                ),
              ],
            ),
            softWrap: false,
          ),
        );
      }
    }
    if (state.banner case final banner?
        when banner.persistent && banner.message.startsWith('Reconnecting')) {
      rows.add(w.Text('  ↻ ${banner.message}', style: flTheme.dimmed));
    }
    return FlutterCliPanel(
      title: 'Devices',
      flTheme: flTheme,
      child: w.Column(children: rows),
    );
  }
}

(String, style.Color) stateGlyph(
  FlutterCliSessionState state,
  FlutterCliTheme theme,
) {
  return switch (state) {
    FlutterCliSessionState.ready => ('●', theme.success),
    FlutterCliSessionState.reloading => ('⠋', theme.warn),
    FlutterCliSessionState.connecting => ('⠋', theme.warn),
    FlutterCliSessionState.stopped => ('○', theme.dim),
    FlutterCliSessionState.failed => ('✗', theme.error),
  };
}

String platformIcon(String platform) {
  final p = platform.toLowerCase();
  if (p.startsWith('ios') || p.contains('darwin') || p.contains('macos')) {
    return '🍎';
  }
  if (p.startsWith('android')) return '🤖';
  if (p.startsWith('web')) return '🌐';
  if (p.startsWith('linux')) return '🐧';
  if (p.startsWith('windows')) return '🪟';
  return '';
}

String platformLabel(String platform) {
  if (platform == 'ios-simulator') return 'ios-sim';
  return platform;
}
