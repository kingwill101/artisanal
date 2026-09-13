import 'dart:convert';
import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:artisanal/markdown.dart';

import '../capture.dart';
import 'gallery_command.dart';
import 'raster_options.dart';
import 'bounded_file.dart';

/// Command runner for portable cell snapshots and native PNG/HTML exports.
///
/// {@category Capture}
final class CaptureCommandRunner extends CommandRunner<void> {
  /// Creates a runner with injectable console output and exit-code handling.
  CaptureCommandRunner({
    String executableName = 'artisanal_capture',
    super.out,
    super.err,
    void Function(int)? setExitCode,
  }) : super(
         executableName,
         'Capture terminal cells and export images without a browser.',
         setExitCode: setExitCode,
       ) {
    addCommand(_RenderCommand());
    addCommand(
      GalleryCommand(
        onFailure: () => (setExitCode ?? (value) => exitCode = value)(1),
      ),
    );
  }
}

final class _RenderCommand extends Command<void> {
  _RenderCommand() {
    argParser
      ..addOption(
        'input-format',
        allowed: ['markdown', 'ansi', 'capture'],
        defaultsTo: 'markdown',
        help: 'Source format. ANSI means a styled view, not a VT session.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        mandatory: true,
        help: 'Destination file.',
      )
      ..addOption(
        'format',
        allowed: ['png', 'html', 'capture'],
        defaultsTo: 'png',
        help:
            'Output format. Capture writes lossless cell JSON and needs no font.',
      )
      ..addOption(
        'columns',
        defaultsTo: '80',
        help: 'Terminal columns (1–1000).',
      )
      ..addOption(
        'rows',
        help: 'Terminal rows (1–10000); defaults to all source lines.',
      )
      ..addFlag(
        'force',
        negatable: false,
        help: 'Replace an existing output file.',
      );
    addRasterOptions(argParser);
  }

  @override
  String get name => 'render';

  @override
  String get description =>
      'Render a Markdown file, ANSI-styled view, or saved capture.';

  @override
  String get invocation =>
      '${runner!.executableName} render <input-file> --output <file> [options]';

  @override
  Future<void> run() async {
    final args = argResults!;
    if (args.rest.length != 1) {
      usageException('Provide exactly one input file.');
    }
    final input = File(args.rest.single);
    final output = File(args['output'] as String);
    final format = args['format'] as String;
    if (input.absolute.uri.normalizePath() ==
        output.absolute.uri.normalizePath()) {
      usageException('Input and output must be different files.');
    }
    if (await output.exists() &&
        (await FileSystemEntity.identical(input.path, output.path) ||
            await input.resolveSymbolicLinks() ==
                await output.resolveSymbolicLinks())) {
      usageException('Input and output must be different files.');
    }
    if (await output.exists() && !(args['force'] as bool)) {
      usageException('Output already exists; pass --force to replace it.');
    }
    if (format != 'capture' && args['font'] == null) {
      usageException('PNG and HTML exports require --font <monospace.ttf>.');
    }

    try {
      // Bound untrusted file input before decoding a cell grid or Markdown AST.
      final source = await readBoundedString(
        input,
        maxCaptureSourceBytes,
        'Input',
      );
      final capture = _readCapture(source);
      if (format == 'capture') {
        await output.writeAsString(
          '${const JsonEncoder.withIndent('  ').convert(capture.toJson())}\n',
        );
      } else {
        final image = (await rasterizerFromArgs(args)).render(capture);
        if (format == 'html') {
          await output.writeAsString(
            image.toHtml(title: input.uri.pathSegments.last),
          );
        } else {
          await output.writeAsBytes(image.png);
        }
        for (final diagnostic in image.diagnostics) {
          io.warn(diagnostic);
        }
      }
      io.success(
        'Wrote ${output.path} (${capture.columns} × ${capture.rows} cells).',
      );
    } on FormatException catch (error) {
      usageException(error.message);
    } on ArgumentError catch (error) {
      usageException(error.message?.toString() ?? error.toString());
    }
  }

  TerminalCapture _readCapture(String source) {
    final args = argResults!;
    if (args['input-format'] == 'capture') {
      if (args.wasParsed('columns') || args.wasParsed('rows')) {
        usageException('Saved captures carry their own dimensions.');
      }
      final json = jsonDecode(source);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Capture must be a JSON object.');
      }
      return TerminalCapture.fromJson(json);
    }
    final columns = _integer('columns', max: 1000)!;
    final ansi = args['input-format'] == 'markdown'
        ? MarkdownRenderer(
            options: AnsiRendererOptions(width: columns),
          ).renderToAnsi(source)
        : source;
    final withoutTerminator = ansi.endsWith('\n')
        ? ansi.substring(0, ansi.length - 1)
        : ansi;
    final rows =
        _integer('rows', max: 10000) ?? withoutTerminator.split('\n').length;
    return TerminalCapture.fromAnsi(ansi, columns: columns, rows: rows);
  }

  int? _integer(String name, {int min = 1, required int max}) {
    return integerOption(argResults!, name, min: min, max: max);
  }
}
