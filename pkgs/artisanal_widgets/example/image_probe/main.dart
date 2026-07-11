#!/usr/bin/env dart

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:artisanal/artisanal.dart' as artisanal;
import 'package:artisanal/src/terminal/report_probe.dart' as terminal_probe;
import 'package:artisanal/style.dart' hide Align, Padding;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/uv.dart' as uv;
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:image/image.dart' as img;

Future<void> main(List<String> arguments) async {
  final config = ImageProbeConfig.parse(arguments);
  if (config.help) {
    io.stdout.writeln(ImageProbeConfig.usage());
    return;
  }
  if (config.error != null) {
    io.stderr.writeln(config.error);
    io.stderr.writeln('');
    io.stderr.writeln(ImageProbeConfig.usage());
    io.exitCode = 64;
    return;
  }

  final bytes = _generateProbeImage(96, 64);
  final imageData = config.url == null
      ? w.ImageData(img.decodeImage(bytes)!)
      : await w.NetworkImage(config.url!).resolve();

  if (config.rawMode != null) {
    _writeRawProbe(imageData.image, config.rawMode!);
    return;
  }
  if (config.matrix) {
    _writeKittyMatrix(imageData.image);
    return;
  }

  final terminalProbe = await terminal_probe.TerminalReportProbe.probe();
  final initialCapabilities = uv.TerminalCapabilities(
    env: _environmentSnapshot(),
  );
  if (terminalProbe?.terminalVersion case final version?) {
    initialCapabilities.updateFromEvent(uv.TerminalVersionEvent(version));
  }
  if (terminalProbe != null && terminalProbe.primaryAttributes.isNotEmpty) {
    initialCapabilities.updateFromEvent(
      uv.PrimaryDeviceAttributesEvent(
        List<int>.from(terminalProbe.primaryAttributes),
      ),
    );
  }

  final app = w.WidgetApp(
    ImageProbeApp(
      sourceLabel: config.url ?? 'generated gradient',
      provider: config.url == null
          ? w.MemoryImage(bytes)
          : w.NetworkImage(config.url!),
      autoMode: config.autoMode,
      initialMode: config.renderMode,
      initialFit: config.fit,
      initialTerminalReport: terminalProbe,
      repaintLoop: config.repaintLoop,
    ),
    imageAutoMode: config.autoMode,
    initialImageCapabilities: initialCapabilities,
    initialImageCellPixelWidth: terminalProbe?.cellPixelWidth,
    initialImageCellPixelHeight: terminalProbe?.cellPixelHeight,
  );

  await artisanal.runWidgetApp(app, imageAutoMode: config.autoMode);
}

final class ImageProbeConfig {
  const ImageProbeConfig({
    required this.help,
    required this.url,
    required this.autoMode,
    required this.renderMode,
    required this.fit,
    required this.rawMode,
    required this.matrix,
    required this.repaintLoop,
    required this.error,
  });

  final bool help;
  final String? url;
  final w.ImageAutoMode autoMode;
  final w.ImageRenderMode renderMode;
  final w.BoxFit fit;
  final w.ImageRenderMode? rawMode;
  final bool matrix;
  final bool repaintLoop;
  final String? error;

  static ImageProbeConfig parse(List<String> args) {
    var help = false;
    String? url;
    var autoMode = w.ImageAutoMode.sessionCapabilities;
    var renderMode = w.ImageRenderMode.auto;
    var fit = w.BoxFit.contain;
    w.ImageRenderMode? rawMode;
    var matrix = false;
    var repaintLoop = false;
    String? error;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      String? readValue(String name) {
        if (i + 1 >= args.length) {
          error = 'Missing value for $name.';
          return null;
        }
        return args[++i];
      }

      if (arg == '-h' || arg == '--help') {
        help = true;
      } else if (arg == '--matrix') {
        matrix = true;
      } else if (arg == '--repaint-loop') {
        repaintLoop = true;
      } else if (arg == '--url') {
        url = readValue(arg);
      } else if (arg == '--auto') {
        final value = readValue(arg);
        if (value == null) continue;
        final parsed = _parseAutoMode(value);
        if (parsed == null) {
          error = 'Unknown auto mode "$value".';
        } else {
          autoMode = parsed;
        }
      } else if (arg == '--mode') {
        final value = readValue(arg);
        if (value == null) continue;
        final parsed = _parseRenderMode(value);
        if (parsed == null) {
          error = 'Unknown render mode "$value".';
        } else {
          renderMode = parsed;
        }
      } else if (arg == '--fit') {
        final value = readValue(arg);
        if (value == null) continue;
        final parsed = _parseFit(value);
        if (parsed == null) {
          error = 'Unknown fit "$value".';
        } else {
          fit = parsed;
        }
      } else if (arg == '--raw') {
        final value = readValue(arg);
        if (value == null) continue;
        final parsed = _parseRenderMode(value);
        if (parsed == null || parsed == w.ImageRenderMode.auto) {
          error = 'Raw mode must be kitty, sixel, iterm2, or unicode.';
        } else {
          rawMode = parsed;
        }
      } else if (arg.startsWith('--url=')) {
        url = arg.substring('--url='.length);
      } else if (arg.startsWith('--auto=')) {
        final value = arg.substring('--auto='.length);
        final parsed = _parseAutoMode(value);
        if (parsed == null) {
          error = 'Unknown auto mode "$value".';
        } else {
          autoMode = parsed;
        }
      } else if (arg.startsWith('--mode=')) {
        final value = arg.substring('--mode='.length);
        final parsed = _parseRenderMode(value);
        if (parsed == null) {
          error = 'Unknown render mode "$value".';
        } else {
          renderMode = parsed;
        }
      } else if (arg.startsWith('--raw=')) {
        final value = arg.substring('--raw='.length);
        final parsed = _parseRenderMode(value);
        if (parsed == null || parsed == w.ImageRenderMode.auto) {
          error = 'Raw mode must be kitty, sixel, iterm2, or unicode.';
        } else {
          rawMode = parsed;
        }
      } else if (url == null && Uri.tryParse(arg)?.hasAbsolutePath == true) {
        url = arg;
      } else {
        error = 'Unknown argument "$arg".';
      }
    }

    return ImageProbeConfig(
      help: help,
      url: url,
      autoMode: autoMode,
      renderMode: renderMode,
      fit: fit,
      rawMode: rawMode,
      matrix: matrix,
      repaintLoop: repaintLoop,
      error: error,
    );
  }

  static String usage() {
    return '''
Image Protocol Probe

Usage:
  dart run example/image_probe/main.dart
  dart run example/image_probe/main.dart --mode kitty
  dart run example/image_probe/main.dart --raw kitty
  dart run example/image_probe/main.dart --matrix
  dart run example/image_probe/main.dart --mode kitty --repaint-loop
  dart run example/image_probe/main.dart --url https://example.com/avatar.png

Options:
  --mode <mode>  Initial widget render mode: auto, kitty, sixel, iterm2, unicode.
  --auto <mode>  Auto selection source: session, environment, portable.
  --fit <fit>    contain, cover, fill, fitWidth, fitHeight, none.
  --raw <mode>   Bypass widgets and write one raw protocol image to stdout.
  --matrix       Bypass widgets and print raw Kitty variants for cat -v checks.
  --repaint-loop Generate delayed repaint frames without changing the image.
  --url <url>    Load a network image instead of the generated probe image.
  -h, --help     Show this help.

Keys:
  m              Cycle render mode.
  f              Cycle BoxFit.
  q              Quit.
''';
  }
}

class ImageProbeApp extends w.StatefulWidget {
  ImageProbeApp({
    required this.sourceLabel,
    required this.provider,
    required this.autoMode,
    required this.initialMode,
    required this.initialFit,
    required this.initialTerminalReport,
    required this.repaintLoop,
    super.key,
  });

  final String sourceLabel;
  final w.ImageProvider provider;
  final w.ImageAutoMode autoMode;
  final w.ImageRenderMode initialMode;
  final w.BoxFit initialFit;
  final terminal_probe.TerminalReportSnapshot? initialTerminalReport;
  final bool repaintLoop;

  @override
  w.State<ImageProbeApp> createState() => _ImageProbeAppState();
}

class _ImageProbeAppState extends w.State<ImageProbeApp> {
  static const _repaintDelay = Duration(milliseconds: 900);

  final _scrollController = w.WidgetScrollController();
  late w.ImageRenderMode _mode;
  late w.BoxFit _fit;
  String _terminalVersion = 'not reported';
  List<int> _primaryAttributes = const <int>[];
  int? _windowPixelWidth;
  int? _windowPixelHeight;
  int? _cellPixelWidth;
  int? _cellPixelHeight;
  int _repaintTick = 0;

  static const _renderModes = <w.ImageRenderMode>[
    w.ImageRenderMode.auto,
    w.ImageRenderMode.kitty,
    w.ImageRenderMode.sixel,
    w.ImageRenderMode.iterm2,
    w.ImageRenderMode.unicodeBlocks,
  ];

  static const _fits = <w.BoxFit>[
    w.BoxFit.contain,
    w.BoxFit.cover,
    w.BoxFit.fill,
    w.BoxFit.fitWidth,
    w.BoxFit.fitHeight,
    w.BoxFit.none,
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _fit = widget.initialFit;
    _seedFromTerminalReport(widget.initialTerminalReport);
  }

  @override
  tui.Cmd? handleInit() {
    return tui.Cmd.batch(<tui.Cmd>[
      tui.Cmd.requestPrimaryDeviceAttributesReport(),
      tui.Cmd.requestTerminalVersionReport(),
      tui.Cmd.requestWindowPixelSizeReport(),
      tui.Cmd.requestCellSizeReport(),
      if (widget.repaintLoop) _scheduleRepaintTick(),
    ]);
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.TerminalVersionMsg) {
      setState(() => _terminalVersion = msg.version);
      return tui.Cmd.none();
    }
    if (msg is tui.PrimaryDeviceAttributesMsg) {
      setState(() => _primaryAttributes = msg.attrs);
      return tui.Cmd.none();
    }
    if (msg is tui.WindowPixelSizeMsg) {
      setState(() {
        _windowPixelWidth = msg.width;
        _windowPixelHeight = msg.height;
      });
      return tui.Cmd.none();
    }
    if (msg is tui.CellSizeMsg) {
      setState(() {
        _cellPixelWidth = msg.width;
        _cellPixelHeight = msg.height;
      });
      return tui.Cmd.none();
    }
    if (msg is _ImageProbeRepaintTickMsg) {
      setState(() => _repaintTick++);
      return tui.Cmd.batch(<tui.Cmd>[
        tui.Cmd.repaint(),
        if (widget.repaintLoop) _scheduleRepaintTick(),
      ]);
    }
    if (msg is tui.KeyMsg) {
      if (msg.key.char == 'q') return tui.Cmd.quit();
      if (msg.key.char == 'm') {
        setState(() {
          _mode = _nextIn(_renderModes, _mode);
        });
        return tui.Cmd.none();
      }
      if (msg.key.char == 'f') {
        setState(() {
          _fit = _nextIn(_fits, _fit);
        });
        return tui.Cmd.none();
      }
    }
    return null;
  }

  tui.Cmd _scheduleRepaintTick() {
    return tui.Cmd.delayed(
      _repaintDelay,
      () => const _ImageProbeRepaintTickMsg(),
    );
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final muted = theme.bodyMedium.copy()..foreground(theme.muted);
    final accent = theme.bodyMedium.copy()..foreground(theme.primary);

    return w.Container(
      color: theme.background,
      padding: const w.EdgeInsets.all(1),
      child: w.Scrollbar(
        controller: _scrollController,
        thickness: 1,
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Column(
            crossAxisAlignment: w.CrossAxisAlignment.start,
            gap: 1,
            children: [
              w.Text('Image Protocol Probe', style: theme.titleLarge),
              w.Text('m mode | f fit | q quit', style: muted),
              w.Divider(width: 88),
              _row(theme, 'source', widget.sourceLabel),
              _row(theme, 'render mode', _mode.name),
              _row(theme, 'auto mode', widget.autoMode.name),
              _row(theme, 'fit', _fit.name),
              _row(
                theme,
                'repaint loop',
                widget.repaintLoop ? 'tick $_repaintTick' : 'off',
              ),
              _row(theme, 'terminal version', _terminalVersion),
              _row(
                theme,
                'primary DA',
                _primaryAttributes.isEmpty
                    ? 'not reported'
                    : _primaryAttributes.join(', '),
              ),
              _row(
                theme,
                'window px',
                _windowPixelWidth == null || _windowPixelHeight == null
                    ? 'not reported'
                    : '$_windowPixelWidth x $_windowPixelHeight',
              ),
              _row(
                theme,
                'cell px',
                _cellPixelWidth == null || _cellPixelHeight == null
                    ? 'not reported'
                    : '$_cellPixelWidth x $_cellPixelHeight',
              ),
              w.Text(
                'If forced kitty shows "_Ga=T,f=100" text, the active terminal path is not rendering Kitty APC images.',
                style: accent,
              ),
              w.Row(
                gap: 2,
                children: [
                  _imageCard(theme, 'current', _mode, widget.provider),
                  _imageCard(
                    theme,
                    'unicode control',
                    w.ImageRenderMode.unicodeBlocks,
                    widget.provider,
                  ),
                ],
              ),
              w.Text('Raw checks:', style: theme.titleMedium),
              w.Text(
                'dart run example/image_probe/main.dart --raw kitty',
                style: muted,
              ),
              w.Text(
                'dart run example/image_probe/main.dart --raw sixel',
                style: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _seedFromTerminalReport(terminal_probe.TerminalReportSnapshot? report) {
    if (report == null) return;
    if (report.terminalVersion != null && report.terminalVersion!.isNotEmpty) {
      _terminalVersion = report.terminalVersion!;
    }
    if (report.primaryAttributes.isNotEmpty) {
      _primaryAttributes = report.primaryAttributes;
    }
    _windowPixelWidth = report.windowPixelWidth;
    _windowPixelHeight = report.windowPixelHeight;
    _cellPixelWidth = report.cellPixelWidth;
    _cellPixelHeight = report.cellPixelHeight;
  }
}

List<String> _environmentSnapshot() {
  return io.Platform.environment.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .toList(growable: false);
}

final class _ImageProbeRepaintTickMsg extends tui.Msg {
  const _ImageProbeRepaintTickMsg();
}

w.Widget _row(w.Theme theme, String label, String value) {
  return w.Row(
    gap: 1,
    children: [
      w.Container(
        width: 18,
        child: w.Text(
          label,
          style: theme.bodySmall.copy()..foreground(theme.muted),
        ),
      ),
      w.Text(value, style: theme.bodyMedium),
    ],
  );
}

w.Widget _imageCard(
  w.Theme theme,
  String title,
  w.ImageRenderMode mode,
  w.ImageProvider provider,
) {
  final hint = theme.bodySmall.copy()..foreground(theme.muted);
  return w.Container(
    padding: const w.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
    decoration: w.BoxDecoration(border: Border.normal, color: theme.surface),
    child: w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.start,
      gap: 1,
      children: [
        w.Text('$title (${mode.name})', style: theme.titleMedium),
        w.Image(
          image: provider,
          width: 32,
          height: 12,
          fit: w.BoxFit.contain,
          renderMode: mode,
          placeholder: w.Text('loading image...', style: hint),
          errorWidget: w.Text(
            'image failed to load',
            style: theme.bodyMedium.copy()..foreground(theme.error),
          ),
        ),
      ],
    ),
  );
}

Uint8List _generateProbeImage(int width, int height) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final checker = ((x ~/ 8) + (y ~/ 8)).isEven;
      final r = checker ? 30 + (x * 180 ~/ width) : 240;
      final g = checker ? 80 + (y * 150 ~/ height) : 90;
      final b = checker ? 230 : 40 + (x * 120 ~/ width);
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void _writeRawProbe(img.Image image, w.ImageRenderMode mode) {
  if (mode == w.ImageRenderMode.kitty) {
    io.stdout.writeln('raw kitty probe (direct protocol; cursor moves):');
    io.stdout.write(
      artisanal.KittyImage.encode(image, id: 1, columns: 32, rows: 12),
    );
    io.stdout.writeln();
    return;
  }

  final canvas = uv.Canvas(32, 12);
  final drawable = switch (mode) {
    w.ImageRenderMode.sixel => uv.SixelImageDrawable(
      image,
      columns: 32,
      rows: 12,
    ),
    w.ImageRenderMode.iterm2 => uv.ITerm2ImageDrawable(
      image,
      columns: 32,
      rows: 12,
    ),
    w.ImageRenderMode.unicodeBlocks => uv.HalfBlockImageDrawable(
      image,
      columns: 32,
      rows: 12,
    ),
    w.ImageRenderMode.auto || w.ImageRenderMode.kitty =>
      uv.HalfBlockImageDrawable(image, columns: 32, rows: 12),
  };
  drawable.draw(canvas, canvas.bounds());
  io.stdout.writeln('raw ${mode.name} probe:');
  io.stdout.write(canvas.render());
  io.stdout.writeln();
}

void _writeKittyMatrix(img.Image image) {
  const columns = 32;
  const rows = 12;
  const cursorForward = '\x1b[32C';

  String drawableRender({required bool explicitCursorForward}) {
    final canvas = uv.Canvas(columns, rows);
    uv.KittyImageDrawable(
      image,
      id: explicitCursorForward ? 202 : 201,
      columns: columns,
      rows: rows,
    ).draw(canvas, canvas.bounds());
    final rendered = canvas.render();
    if (!explicitCursorForward) return rendered;
    final newline = rendered.indexOf('\n');
    if (newline == -1) return '$rendered$cursorForward';
    return '${rendered.substring(0, newline)}$cursorForward'
        '${rendered.substring(newline)}';
  }

  io.stdout.write('\x1b[2J\x1b[H');
  io.stdout.writeln('Kitty raw matrix');
  io.stdout.writeln(
    'Use: dart run example/image_probe/main.dart --matrix | cat -v',
  );
  io.stdout.writeln('');
  io.stdout.writeln('A direct protocol: no C=1');
  io.stdout.write(
    artisanal.KittyImage.encode(image, id: 101, columns: columns, rows: rows),
  );
  io.stdout.writeln('\n');
  io.stdout.writeln('B UV drawable/canvas: C=1, no explicit cursor move');
  io.stdout.write(drawableRender(explicitCursorForward: false));
  io.stdout.writeln('\n');
  io.stdout.writeln('C UV drawable/canvas: C=1 plus explicit CUF $columns');
  io.stdout.write(drawableRender(explicitCursorForward: true));
  io.stdout.writeln('\n');
  io.stdout.writeln('End matrix');
}

w.ImageAutoMode? _parseAutoMode(String value) {
  return switch (value.toLowerCase()) {
    'session' || 'sessioncapabilities' => w.ImageAutoMode.sessionCapabilities,
    'environment' || 'env' => w.ImageAutoMode.environment,
    'portable' || 'fallback' || 'unicode' => w.ImageAutoMode.portableFallback,
    _ => null,
  };
}

w.ImageRenderMode? _parseRenderMode(String value) {
  return switch (value.toLowerCase()) {
    'auto' => w.ImageRenderMode.auto,
    'kitty' => w.ImageRenderMode.kitty,
    'sixel' => w.ImageRenderMode.sixel,
    'iterm2' || 'iterm' => w.ImageRenderMode.iterm2,
    'unicode' || 'blocks' || 'unicodeblocks' => w.ImageRenderMode.unicodeBlocks,
    _ => null,
  };
}

w.BoxFit? _parseFit(String value) {
  return switch (value.toLowerCase()) {
    'contain' => w.BoxFit.contain,
    'cover' => w.BoxFit.cover,
    'fill' => w.BoxFit.fill,
    'fitwidth' || 'width' => w.BoxFit.fitWidth,
    'fitheight' || 'height' => w.BoxFit.fitHeight,
    'none' => w.BoxFit.none,
    _ => null,
  };
}

T _nextIn<T>(List<T> values, T current) {
  final index = values.indexOf(current);
  return values[(index + 1) % values.length];
}
