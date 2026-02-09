library;

import 'package:artisanal/style.dart';

enum DemoTheme { obsidian, aurora, monokai, dracula, nord }

final class DemoThemeData {
  const DemoThemeData({
    required this.id,
    required this.name,
    required this.palette,
    required this.chartA,
    required this.chartB,
    required this.chartC,
    required this.chartD,
    required this.glow,
  });

  final DemoTheme id;
  final String name;
  final ThemePalette palette;
  final Color chartA;
  final Color chartB;
  final Color chartC;
  final Color chartD;
  final Color glow;
}

const demoThemes = <DemoThemeData>[
  DemoThemeData(
    id: DemoTheme.obsidian,
    name: 'Obsidian',
    palette: ThemePalette.dark,
    chartA: Colors.cyan,
    chartB: Colors.green,
    chartC: Colors.yellow,
    chartD: Colors.magenta,
    glow: Colors.blue,
  ),
  DemoThemeData(
    id: DemoTheme.aurora,
    name: 'Aurora',
    palette: ThemePalette.ocean,
    chartA: Colors.cyan,
    chartB: Colors.blue,
    chartC: Colors.green,
    chartD: Colors.purple,
    glow: Colors.cyan,
  ),
  DemoThemeData(
    id: DemoTheme.monokai,
    name: 'Monokai',
    palette: ThemePalette.monokai,
    chartA: Colors.orange,
    chartB: Colors.yellow,
    chartC: Colors.green,
    chartD: Colors.purple,
    glow: Colors.orange,
  ),
  DemoThemeData(
    id: DemoTheme.dracula,
    name: 'Dracula',
    palette: ThemePalette.dracula,
    chartA: Colors.purple,
    chartB: Colors.cyan,
    chartC: Colors.pink,
    chartD: Colors.green,
    glow: Colors.magenta,
  ),
  DemoThemeData(
    id: DemoTheme.nord,
    name: 'Nord',
    palette: ThemePalette.nord,
    chartA: Colors.blue,
    chartB: Colors.cyan,
    chartC: Colors.green,
    chartD: Colors.white,
    glow: Colors.blue,
  ),
];

DemoThemeData themeData(DemoTheme theme) {
  return demoThemes.firstWhere((t) => t.id == theme);
}

DemoTheme nextTheme(DemoTheme theme) {
  final idx = demoThemes.indexWhere((t) => t.id == theme);
  final nextIdx = (idx + 1) % demoThemes.length;
  return demoThemes[nextIdx].id;
}
