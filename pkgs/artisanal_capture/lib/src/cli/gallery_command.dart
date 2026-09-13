import 'dart:convert';
import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:artisanal/markdown.dart';
import 'package:ultraviolet/core.dart';

import '../capture.dart';
import '../export.dart';
import 'bounded_file.dart';
import 'end_markers.dart';
import 'gallery_html.dart';
import 'raster_options.dart';

/// Generates a reviewable width matrix using the same capture path as `render`.
final class GalleryCommand extends Command<void> {
  /// Creates the gallery command with the runner's exit-code callback.
  GalleryCommand({required this.onFailure}) {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        mandatory: true,
        help: 'Gallery directory; must be empty unless --force is supplied.',
      )
      ..addOption(
        'widths',
        defaultsTo: '32,64,96',
        help: 'Comma-separated terminal widths (1–1000), up to 10 variants.',
      )
      ..addFlag(
        'force',
        negatable: false,
        help: 'Replace generated gallery files in an existing directory.',
      );
    addRasterOptions(argParser);
  }

  /// Marks a completed gallery containing failed renders with a nonzero status.
  final void Function() onFailure;

  @override
  String get name => 'gallery';

  @override
  String get description =>
      'Render a Markdown directory at multiple widths with an HTML index.';

  @override
  String get invocation =>
      '${runner!.executableName} gallery <scenario-directory> --output <directory> [options]';

  @override
  Future<void> run() async {
    final args = argResults!;
    if (args.rest.length != 1) {
      usageException('Provide one scenario directory.');
    }
    final widths = <int>[];
    for (final raw in (args['widths'] as String).split(',')) {
      final width = int.tryParse(raw.trim());
      if (width == null || width < 1 || width > terminalCaptureMaxColumns) {
        usageException('--widths must contain integers between 1 and 1000.');
      }
      if (!widths.contains(width)) widths.add(width);
    }
    if (widths.length > 10) usageException('At most 10 widths are supported.');
    final input = Directory(args.rest.single);
    final output = Directory(args['output'] as String);
    if (!await input.exists()) {
      usageException('Scenario directory does not exist.');
    }
    if (await output.exists()) {
      if (await input.resolveSymbolicLinks() ==
          await output.resolveSymbolicLinks()) {
        usageException(
          'Gallery output must differ from the scenario directory.',
        );
      }
      if (!(args['force'] as bool) && !await output.list().isEmpty) {
        usageException(
          'Gallery directory is not empty; pass --force to replace generated files.',
        );
      }
    }
    final files = <File>[];
    await for (final entity in input.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last.toLowerCase();
      if (name.endsWith('.md') && name != 'readme.md') files.add(entity);
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    if (files.isEmpty) {
      usageException('No Markdown scenarios found (README.md is excluded).');
    }
    if (files.length > 200) {
      usageException('At most 200 scenarios are supported.');
    }

    late CaptureRasterizer rasterizer;
    try {
      rasterizer = await rasterizerFromArgs(args);
    } on FormatException catch (error) {
      usageException(error.message);
    } on ArgumentError catch (error) {
      usageException(error.message.toString());
    }
    await output.create(recursive: true);
    File destination(String name) => File.fromUri(output.uri.resolve(name));
    final entries = <GalleryEntry>[];
    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final name = file.uri.pathSegments.last;
      final slug = name
          .substring(0, name.length - 3)
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-');
      final id = '${index.toString().padLeft(3, '0')}-$slug';
      String? source;
      String? inputError;
      EndMarkerMatcher? markerMatcher;
      try {
        source = await readBoundedString(
          file,
          maxCaptureSourceBytes,
          'Scenario',
        );
        markerMatcher = EndMarkerMatcher.fromSource(source);
      } on FormatException catch (error) {
        inputError = 'Cannot prepare source: ${error.message}';
      }
      if (source != null) await destination('$id.md').writeAsString(source);
      for (final width in widths) {
        final stem = '$id-$width';
        final warnings = <String>[];
        final overflow = <int>[];
        String? error = inputError;
        CaptureImage? image;
        TerminalCapture? capture;
        String? ansi;
        if (source != null && markerMatcher != null) {
          try {
            ansi = MarkdownRenderer(
              options: AnsiRendererOptions(width: width),
            ).renderToAnsi(source);
            final lines =
                (ansi.endsWith('\n')
                        ? ansi.substring(0, ansi.length - 1)
                        : ansi)
                    .split('\n');
            for (var row = 0; row < lines.length; row++) {
              if (StyledString(lines[row]).bounds().width > width) {
                overflow.add(row + 1);
              }
            }
            if (overflow.isNotEmpty) {
              warnings.add(
                'Rendered lines exceed $width columns and are clipped: '
                '${overflow.join(', ')}. Inspect the ANSI output for the full lines.',
              );
            }
            capture = TerminalCapture.fromAnsi(
              ansi,
              columns: width,
              rows: lines.length,
            );
            final buffer = capture.toBuffer();
            final plain = StringBuffer();
            try {
              for (var y = 0; y < capture.rows; y++) {
                for (var x = 0; x < capture.columns; x++) {
                  plain.write(buffer.cellAt(x, y)?.content ?? '');
                }
                plain.writeln();
              }
            } finally {
              buffer.dispose();
            }
            final plainText = plain.toString();
            final foundMarkers = markerMatcher.findIn(plainText);
            for (final marker in markerMatcher.markers) {
              if (!foundMarkers.contains(marker)) {
                warnings.add('End marker missing from captured cells: $marker');
              }
            }
            image = rasterizer.render(capture);
            warnings.addAll(image.diagnostics);
          } on FormatException catch (failure) {
            error = failure.message;
          } on ArgumentError catch (failure) {
            error = failure.message?.toString() ?? failure.toString();
          } on StateError catch (failure) {
            error = failure.message;
          } on UnsupportedError catch (failure) {
            error = failure.message;
          }
        }
        // Keep underlying evidence even when the strict rasterizer rejects it.
        if (ansi != null) await destination('$stem.ansi').writeAsString(ansi);
        if (capture != null) {
          await destination(
            '$stem.json',
          ).writeAsString(jsonEncode(capture.toJson()));
        }
        if (image != null) {
          await destination('$stem.png').writeAsBytes(image.png);
          await destination(
            '$stem.html',
          ).writeAsString(image.toHtml(title: '$name · $width columns'));
        }
        entries.add(
          GalleryEntry(
            scenario: name,
            sourceFile: source == null ? null : '$id.md',
            stem: stem,
            columns: width,
            rows: capture?.rows,
            imageWidth: image?.width,
            imageHeight: image?.height,
            hasAnsi: ansi != null,
            hasCapture: capture != null,
            warnings: warnings,
            overflowRows: overflow,
            error: error,
          ),
        );
        io.line(
          '$name @ $width: ${error != null
              ? 'FAILED: $error'
              : warnings.isEmpty
              ? 'rendered'
              : '${warnings.length} diagnostics'}',
        );
      }
    }
    final failures = entries.where((entry) => entry.error != null).length;
    final flagged = entries.where((entry) => entry.warnings.isNotEmpty).length;
    await destination('manifest.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert({
        'version': 1,
        'scenarioCount': files.length,
        'widths': widths,
        'failedRenders': failures,
        'flaggedRenders': flagged,
        'profile': {
          for (final option in ['font', 'font-bold', 'font-italic', 'font-bold-italic', 'font-size', 'cell-width', 'cell-height', 'padding', 'foreground', 'background', 'strict']) option: args[option],
        },
        'entries': entries.map((entry) => entry.toJson()).toList(),
      })}\n',
    );
    await destination('index.html').writeAsString(galleryHtml(entries));
    io.line(
      'Gallery: ${destination('index.html').path} '
      '(${entries.length} renders; $flagged flagged; $failures failed).',
    );
    if (failures > 0) onFailure();
  }
}
