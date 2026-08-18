import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:args/args.dart';

import 'widget_catalog_support.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'showcase',
      abbr: 's',
      help: 'Render every ComponentTheme preset as a static showcase.',
    )
    ..addFlag(
      'list',
      abbr: 'l',
      help: 'List catalog entries without opening the interactive menu.',
    )
    ..addOption(
      'preset',
      abbr: 'p',
      allowed: componentThemePresetNames,
      help: 'Use one preset instead of the default dark theme.',
    )
    ..addFlag(
      'no-ansi',
      help: 'Disable ANSI colors for plain-text output and snapshots.',
    )
    ..addFlag(
      'ansi',
      help: 'Force ANSI colors for showcase output.',
      negatable: false,
    )
    ..addFlag('help', abbr: 'h', help: 'Show this help text.');

  late ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  if (options['help'] as bool) {
    stdout.writeln('Artisanal Widget Catalog');
    stdout.writeln(
      'Browse interactive Bubbles and display components, or render a theme showcase.',
    );
    stdout.writeln();
    stdout.writeln(
      'Usage: dart run pkgs/artisanal/example/widget_catalog.dart [options]',
    );
    stdout.writeln();
    stdout.writeln(parser.usage);
    return;
  }

  final preset = options['preset'] as String? ?? 'dark';
  final theme = componentThemeForName(preset);
  final plainText = (options['no-ansi'] as bool) && !(options['ansi'] as bool);
  final renderer = plainText
      ? StringRenderer(colorProfile: ColorProfile.ascii)
      : defaultRenderer;
  final io = Console(
    renderer: renderer,
    interactive: !(options['showcase'] as bool) && !(options['list'] as bool),
    componentTheme: theme,
  );

  if (options['list'] as bool) {
    _printCatalog(io);
    return;
  }

  if (options['showcase'] as bool) {
    final names = options.wasParsed('preset')
        ? [preset]
        : componentThemePresetNames;
    for (final name in names) {
      renderPresetShowcase(io, name, componentThemeForName(name));
    }
    return;
  }

  var activeTheme = theme;
  if (!options.wasParsed('preset')) {
    final selectedPreset = await io.selectChoice<String>(
      'Choose a ComponentTheme preset',
      choices: componentThemePresetNames,
    );
    if (selectedPreset == null) return;
    activeTheme = componentThemeForName(selectedPreset);
  }

  await runInteractiveCatalog(io, theme: activeTheme);
}

void _printCatalog(Console io) {
  io.title('Artisanal Widget Catalog');
  io.text('Use --showcase to render every ComponentTheme preset.');
  io.newLine();
  io.section('ComponentTheme presets');
  for (final name in componentThemePresetNames) {
    io.writeln('  $name');
  }
  io.newLine();

  final entries = widgetCatalogEntries;
  for (final category in widgetCatalogCategories) {
    io.section(category);
    for (final entry in entries.where((entry) => entry.category == category)) {
      io.writeln('  ${entry.name} — ${entry.description}');
    }
  }
}
