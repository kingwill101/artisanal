import 'dart:math' as math;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/widgets.dart' as w;

import 'model.dart';
import 'panels/devices.dart';
import 'panels/network.dart';
import 'panels/performance.dart';
import 'theme.dart';
import 'utils.dart';

class FlutterCliRender extends w.StatelessWidget {
  FlutterCliRender({
    required this.state,
    required this.flTheme,
    required this.brightnessMode,
    super.key,
  });

  final FlutterCliState state;
  final FlutterCliTheme flTheme;
  final int brightnessMode;

  @override
  w.Widget build(w.BuildContext context) {
    final media = w.MediaQuery.of(context);
    final width = media.size.width.round();
    final height = media.size.height.round();
    if (width < minWidth || height < minHeight) {
      return _TooSmall(width: width, height: height, flTheme: flTheme);
    }
    return w.Container(
      width: width,
      height: height,
      background: flTheme.bg,
      child: w.Column(
        width: width,
        height: height,
        children: [
          _Header(
            state: state,
            flTheme: flTheme,
            brightnessMode: brightnessMode,
          ),
          w.Expanded(
            child: _StatusPanels(state: state, flTheme: flTheme),
          ),
          _Footer(state: state, flTheme: flTheme),
        ],
      ),
    );
  }
}

class _TooSmall extends w.StatelessWidget {
  _TooSmall({required this.width, required this.height, required this.flTheme});

  final int width;
  final int height;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Container(
      width: width,
      height: math.max(1, height),
      background: flTheme.bg,
      alignment: const w.Alignment(0, 0),
      child: w.Text(
        'Terminal too small (${width}x$height). Need at least '
        '${minWidth}x$minHeight.',
        style: flTheme.fgStyle(flTheme.warn),
        textAlign: w.TextAlign.center,
      ),
    );
  }
}

class _Header extends w.StatelessWidget {
  _Header({
    required this.state,
    required this.flTheme,
    required this.brightnessMode,
  });

  final FlutterCliState state;
  final FlutterCliTheme flTheme;
  final int brightnessMode;

  @override
  w.Widget build(w.BuildContext context) {
    final width = w.MediaQuery.of(context).size.width.round();
    final device = switch (state.activeSessions.length) {
      0 => 'no device',
      1 => state.activeSessions.first.displayName,
      final n => '$n devices',
    };
    final chronoIcon = state.compileFinished == null ? '⏱' : '✓';
    final brightness = switch (brightnessMode) {
      1 => '☀️',
      2 => '🌙',
      _ => '⚙️',
    };
    final title = truncate(
      ' $brightness  flutter-cli ── ${state.appName} · ${state.mode} · $device',
      math.max(1, width - 22),
    );
    final elapsed = '$chronoIcon ${formatElapsed(state.elapsed)} ';
    return w.Frame(
      border: style.Border.normal,
      borderColor: flTheme.accent,
      background: flTheme.bg,
      foreground: flTheme.fg,
      padding: const w.EdgeInsets.symmetric(horizontal: 1),
      child: w.Row(
        width: width,
        mainAxisAlignment: w.MainAxisAlignment.spaceBetween,
        children: [
          w.Text(title, style: flTheme.header, overflow: w.TextOverflow.clip),
          w.Text(elapsed, style: flTheme.fgStyle(flTheme.success)),
        ],
      ),
    );
  }
}

class _StatusPanels extends w.StatelessWidget {
  _StatusPanels({required this.state, required this.flTheme});

  final FlutterCliState state;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    final width = w.MediaQuery.of(context).size.width.round();
    final left = state.showNetwork
        ? NetworkPanel(state: state, flTheme: flTheme)
        : PerformancePanel(state: state, flTheme: flTheme);
    final devices = DevicesPanel(state: state, flTheme: flTheme);
    if (width < narrowWidth) {
      return w.Column(
        children: [
          w.Expanded(flex: 3, child: left),
          w.Expanded(flex: 2, child: devices),
        ],
      );
    }
    return w.Row(
      children: [
        w.Expanded(flex: 3, child: left),
        w.Expanded(flex: 2, child: devices),
      ],
    );
  }
}

class _Footer extends w.StatelessWidget {
  _Footer({required this.state, required this.flTheme});

  final FlutterCliState state;
  final FlutterCliTheme flTheme;

  @override
  w.Widget build(w.BuildContext context) {
    final width = w.MediaQuery.of(context).size.width.round();
    if (state.appReady) {
      return w.Container(
        width: width,
        height: 1,
        background: flTheme.bg,
        child: w.Text(_packFooterBinds(width), style: flTheme.dimmed),
      );
    }
    final pct = estimatedPercentage(state);
    final suffix = width >= 90
        ? ' [e] error ↗  [/] filter  [c] copy 📋  [q] quit '
        : width >= 60
        ? ' [e] err  [q] quit '
        : '· e err · q quit ';
    final label = ' ⏳ ${pct.toString().padLeft(2)}% ';
    final budget = math.max(0, width - label.length - suffix.length - 1);
    final bar = buildBar(math.min(60, budget), pct);
    return w.Container(
      width: width,
      height: 1,
      background: flTheme.bg,
      child: w.RichText(
        text: w.TextSpan(
          children: [
            w.TextSpan(text: label, style: flTheme.base),
            w.TextSpan(text: bar, style: flTheme.fgStyle(flTheme.accent)),
            w.TextSpan(text: ' ', style: flTheme.base),
            w.TextSpan(text: suffix, style: flTheme.dimmed),
          ],
        ),
        softWrap: false,
      ),
    );
  }
}

String _packFooterBinds(int width) {
  const binds = [
    '[r] reload',
    '[R] restart',
    '[q] quit',
    '[e] error ↗',
    '[c] copy 📋',
    '[/] filter',
    '[s] snap 📸',
    '[b] theme',
    '[n] net',
    '[d] devtools',
    '[o] platform',
    '[p] paint',
    '[P] perf',
  ];
  final out = StringBuffer(' ');
  for (final bind in binds) {
    final next = out.length == 1 ? bind : '  $bind';
    if (out.length + next.length + 1 > width) break;
    out.write(next);
  }
  if (out.length == 1) return ' r reload · q quit ';
  out.write(' ');
  return out.toString();
}
