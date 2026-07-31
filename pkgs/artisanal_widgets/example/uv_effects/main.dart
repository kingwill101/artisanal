// UV effects applied to regular Artisanal widgets.
//
// Run from `pkgs/artisanal_widgets`:
//   dart run example/uv_effects/main.dart

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/uv.dart' as uv;
import 'package:artisanal_widgets/widgets.dart' as w;

Future<void> main() async {
  await tui.runProgram(
    w.WidgetApp(UvEffectsDemo()),
    options: const tui.ProgramOptions(
      screenMode: tui.ScreenMode.fullScreen,
      fps: 30,
      frameTick: true,
      mouseMode: tui.MouseMode.none,
    ),
  );
}

class UvEffectsDemo extends w.StatefulWidget {
  UvEffectsDemo({super.key});

  @override
  w.State createState() => _UvEffectsDemoState();
}

class _UvEffectsDemoState extends w.State<UvEffectsDemo> {
  late final List<_EffectPreset> _effects;
  var _selected = 0;
  var _frameDelta = 1 / 30;

  @override
  void initState() {
    super.initState();
    _effects = [
      _EffectPreset('Grayscale', [uv.ColorMatrixFilter.grayscale()]),
      _EffectPreset('Invert', [uv.ColorMatrixFilter.invert()]),
      _EffectPreset('Vignette', [uv.VignetteFilter(strength: 0.55)]),
      _EffectPreset('Scanlines', [
        uv.ScanlineFilter(lineStrength: 0.18, barStrength: 0.12),
      ]),
      _EffectPreset('CRT', [uv.CrtFilter()]),
      _EffectPreset('Amber trail', [uv.AmberTrailFilter(persistence: 0.4)]),
      _EffectPreset('Custom stack', [
        uv.ColorMatrixFilter.tint(const uv.UvRgb(84, 211, 255), amount: 0.3),
        uv.VignetteFilter(strength: 0.35),
        uv.ScanlineFilter(lineStrength: 0.12),
      ]),
    ];
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.FrameTickMsg) {
      setState(() {
        _frameDelta = msg.delta.inMicroseconds / Duration.microsecondsPerSecond;
      });
      return null;
    }

    if (msg is! tui.KeyMsg) return null;
    if (msg.key.char == 'q' || msg.key.type == tui.KeyType.escape) {
      return tui.Cmd.quit();
    }
    if (msg.key.type == tui.KeyType.left || msg.key.type == tui.KeyType.up) {
      setState(() {
        _selected = (_selected - 1 + _effects.length) % _effects.length;
      });
    } else if (msg.key.type == tui.KeyType.right ||
        msg.key.type == tui.KeyType.down ||
        msg.key.type == tui.KeyType.tab) {
      setState(() => _selected = (_selected + 1) % _effects.length);
    } else {
      final number = int.tryParse(msg.key.char ?? '');
      if (number != null && number > 0 && number <= _effects.length) {
        setState(() => _selected = number - 1);
      }
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final selected = _effects[_selected];

    return w.Container(
      color: theme.background,
      padding: const w.EdgeInsets.all(1),
      child: w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.start,
        children: [
          w.Text('UV Effects for Widget Subtrees', style: theme.titleLarge),
          w.Text(
            'left/right or 1-${_effects.length} select · q quits',
            style: theme.labelSmall,
          ),
          w.Text(
            _effects.indexed
                .map(
                  (entry) => entry.$1 == _selected
                      ? '[${entry.$1 + 1}:${entry.$2.label}]'
                      : '${entry.$1 + 1}:${entry.$2.label}',
                )
                .join('  '),
            style: theme.bodySmall,
          ),
          w.LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 70;
              final sceneWidth = wide
                  ? ((constraints.maxWidth - 4) ~/ 2).clamp(28, 42)
                  : constraints.maxWidth.toInt().clamp(28, 52);
              final original = _LabeledScene(
                label: 'Original widgets',
                width: sceneWidth,
              );
              final filtered = w.Column(
                gap: 0,
                crossAxisAlignment: w.CrossAxisAlignment.start,
                children: [
                  w.Text(
                    'CellFilter · ${selected.label}',
                    style: theme.labelSmall,
                  ),
                  // CellFilter captures the child into a UV buffer, applies
                  // each filter in order, and paints the resulting cells.
                  w.CellFilter(
                    filters: selected.filters,
                    deltaTime: _frameDelta,
                    child: _DemoScene(width: sceneWidth),
                  ),
                ],
              );
              return wide
                  ? w.Row(gap: 3, children: [original, filtered])
                  : w.Column(gap: 1, children: [original, filtered]);
            },
          ),
          w.Text(
            'Compose effects by passing multiple BufferFilters in order.',
            style: theme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _LabeledScene extends w.StatelessWidget {
  _LabeledScene({required this.label, required this.width});

  final String label;
  final int width;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    return w.Column(
      gap: 0,
      crossAxisAlignment: w.CrossAxisAlignment.start,
      children: [
        w.Text(label, style: theme.labelSmall),
        _DemoScene(width: width),
      ],
    );
  }
}

class _DemoScene extends w.StatelessWidget {
  _DemoScene({required this.width});

  final int width;

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    return w.Frame(
      border: style.Border.rounded,
      borderColor: theme.border,
      child: w.Container(
        width: width - 2,
        height: 9,
        color: theme.surface,
        padding: const w.EdgeInsets.all(1),
        child: w.Column(
          gap: 1,
          crossAxisAlignment: w.CrossAxisAlignment.start,
          children: [
            w.Text('DEPLOYMENT', style: theme.titleMedium),
            w.Text('api       ████████████  ready', style: theme.bodyMedium),
            w.Text(
              'workers   █████████░░░  76%',
              style: style.Style()..foreground(theme.warning),
            ),
            w.Text(
              'database  ██████░░░░░░  52%',
              style: style.Style()..foreground(theme.error),
            ),
            w.Row(
              gap: 1,
              children: [
                w.Badge(
                  'LIVE',
                  background: theme.success,
                  foreground: theme.resolvedOnSuccess,
                ),
                w.Badge(
                  'UV',
                  background: theme.resolvedInfo,
                  foreground: theme.resolvedOnInfo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _EffectPreset {
  _EffectPreset(this.label, List<uv.BufferFilter> filters)
    : filters = List<uv.BufferFilter>.unmodifiable(filters);

  final String label;
  final List<uv.BufferFilter> filters;
}
