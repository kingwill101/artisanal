import 'dart:io';
import 'dart:typed_data';

import 'package:artisanal/args.dart';
import 'package:ultraviolet/core.dart';
import 'package:ultraviolet/raster.dart';

import '../export.dart';
import 'bounded_file.dart';

/// Registers the common raster profile for single captures and galleries.
void addRasterOptions(ArgParser parser) {
  parser
    ..addOption('font', help: 'Regular static monospace TrueType font file.')
    ..addOption('font-bold', help: 'Matching bold TrueType font file.')
    ..addOption(
      'font-italic',
      help: 'Matching italic/oblique TrueType font file.',
    )
    ..addOption(
      'font-bold-italic',
      help: 'Matching bold italic TrueType font file.',
    )
    ..addOption(
      'font-size',
      defaultsTo: '14',
      help: 'Font size in pixels (1–256).',
    )
    ..addOption('cell-width', help: 'Explicit cell width in pixels.')
    ..addOption('cell-height', help: 'Explicit cell height in pixels.')
    ..addOption(
      'padding',
      defaultsTo: '0',
      help: 'Image padding in pixels (0–1024).',
    )
    ..addOption(
      'foreground',
      defaultsTo: '#cccccc',
      help: 'Default text color (#RRGGBB).',
    )
    ..addOption(
      'background',
      defaultsTo: '#000000',
      help: 'Default background (#RRGGBB).',
    )
    ..addFlag(
      'strict',
      defaultsTo: true,
      help: 'Reject unsupported glyphs, font variants, or terminal graphics.',
    );
}

/// Loads a caller-supplied font and validates a common raster profile.
Future<CaptureRasterizer> rasterizerFromArgs(ArgResults args) async {
  final path = args['font'] as String?;
  if (path == null) {
    throw const FormatException(
      'PNG and HTML exports require --font <monospace.ttf>.',
    );
  }
  final size = double.tryParse(args['font-size'] as String);
  if (size == null || !size.isFinite || size < 1 || size > 256) {
    throw const FormatException('--font-size must be between 1 and 256.');
  }
  final options = RasterRenderOptions(
    fontSize: size,
    cellWidth: integerOption(args, 'cell-width', max: 1024),
    cellHeight: integerOption(args, 'cell-height', max: 1024),
    padding: integerOption(args, 'padding', min: 0, max: 1024)!,
    foreground: _color(args, 'foreground'),
    background: _color(args, 'background'),
    strict: args['strict'] as bool,
  );
  final font = RasterFont.fromTtf(
    (await _fontBytes(path))!,
    bold: await _fontBytes(args['font-bold'] as String?),
    italic: await _fontBytes(args['font-italic'] as String?),
    boldItalic: await _fontBytes(args['font-bold-italic'] as String?),
  );
  return CaptureRasterizer(font: font, options: options);
}

/// Reads a bounded optional integer, reporting errors consistently.
int? integerOption(
  ArgResults args,
  String name, {
  int min = 1,
  required int max,
}) {
  final raw = args[name] as String?;
  if (raw == null) return null;
  final value = int.tryParse(raw);
  if (value == null || value < min || value > max) {
    throw FormatException('--$name must be an integer between $min and $max.');
  }
  return value;
}

UvRgb _color(ArgResults args, String name) {
  final value = args[name] as String;
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
    throw FormatException('--$name must use #RRGGBB notation.');
  }
  final rgb = int.parse(value.substring(1), radix: 16);
  return UvRgb(rgb >> 16, (rgb >> 8) & 255, rgb & 255);
}

Future<Uint8List?> _fontBytes(String? path) async {
  if (path == null) return null;
  return readBoundedBytes(File(path), maxCaptureFontBytes, 'Font');
}
