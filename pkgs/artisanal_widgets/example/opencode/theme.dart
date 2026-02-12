library;

import 'dart:io';

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

import 'models/opencode_theme.dart';

class OpenCodePalette {
  const OpenCodePalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.error,
    required this.warning,
    required this.success,
    required this.info,
    required this.text,
    required this.textMuted,
    required this.background,
    required this.backgroundPanel,
    required this.backgroundElement,
    required this.border,
    required this.borderActive,
    required this.borderSubtle,
    required this.diffAdded,
    required this.diffRemoved,
    required this.shadow,
  });

  final style.Color primary;
  final style.Color secondary;
  final style.Color accent;
  final style.Color error;
  final style.Color warning;
  final style.Color success;
  final style.Color info;
  final style.Color text;
  final style.Color textMuted;
  final style.Color background;
  final style.Color backgroundPanel;
  final style.Color backgroundElement;
  final style.Color border;
  final style.Color borderActive;
  final style.Color borderSubtle;
  final style.Color diffAdded;
  final style.Color diffRemoved;
  final style.Color shadow;

  factory OpenCodePalette.fromDocument(OpenCodeThemeDocument document) {
    final colors = document.resolveThemeColors();

    style.Color requiredColor(String key) {
      final color = colors[key];
      if (color == null) {
        throw FormatException('Missing required theme color: $key');
      }
      return color;
    }

    style.Color optionalColor(String key, style.Color fallback) {
      return colors[key] ?? fallback;
    }

    return OpenCodePalette(
      primary: requiredColor('primary'),
      secondary: requiredColor('secondary'),
      accent: requiredColor('accent'),
      error: optionalColor('error', requiredColor('primary')),
      warning: optionalColor('warning', requiredColor('primary')),
      success: optionalColor('success', requiredColor('primary')),
      info: optionalColor('info', requiredColor('secondary')),
      text: requiredColor('text'),
      textMuted: requiredColor('textMuted'),
      background: requiredColor('background'),
      backgroundPanel: optionalColor(
        'backgroundPanel',
        requiredColor('background'),
      ),
      backgroundElement: optionalColor(
        'backgroundElement',
        optionalColor('backgroundPanel', requiredColor('background')),
      ),
      border: optionalColor('border', requiredColor('textMuted')),
      borderActive: optionalColor(
        'borderActive',
        optionalColor('border', requiredColor('textMuted')),
      ),
      borderSubtle: optionalColor(
        'borderSubtle',
        optionalColor('border', requiredColor('textMuted')),
      ),
      diffAdded: optionalColor('diffAdded', requiredColor('success')),
      diffRemoved: optionalColor('diffRemoved', requiredColor('error')),
      shadow: optionalColor('backgroundPanel', requiredColor('background')),
    );
  }

  static const fallback = OpenCodePalette(
    primary: style.BasicColor('#fab283'),
    secondary: style.BasicColor('#5c9cf5'),
    accent: style.BasicColor('#9d7cd8'),
    error: style.BasicColor('#e06c75'),
    warning: style.BasicColor('#f5a742'),
    success: style.BasicColor('#7fd88f'),
    info: style.BasicColor('#56b6c2'),
    text: style.BasicColor('#eeeeee'),
    textMuted: style.BasicColor('#808080'),
    background: style.BasicColor('#0a0a0a'),
    backgroundPanel: style.BasicColor('#141414'),
    backgroundElement: style.BasicColor('#1e1e1e'),
    border: style.BasicColor('#484848'),
    borderActive: style.BasicColor('#606060'),
    borderSubtle: style.BasicColor('#3c3c3c'),
    diffAdded: style.BasicColor('#7fd88f'),
    diffRemoved: style.BasicColor('#e06c75'),
    shadow: style.BasicColor('#1a1a1a'),
  );
}

class OC {
  OC._();

  static OpenCodePalette _palette = OpenCodePalette.fallback;

  static style.Color get primary => _palette.primary;
  static style.Color get secondary => _palette.secondary;
  static style.Color get accent => _palette.accent;
  static style.Color get error => _palette.error;
  static style.Color get warning => _palette.warning;
  static style.Color get success => _palette.success;
  static style.Color get info => _palette.info;
  static style.Color get text => _palette.text;
  static style.Color get textMuted => _palette.textMuted;
  static style.Color get background => _palette.background;
  static style.Color get backgroundPanel => _palette.backgroundPanel;
  static style.Color get backgroundElement => _palette.backgroundElement;
  static style.Color get border => _palette.border;
  static style.Color get borderActive => _palette.borderActive;
  static style.Color get borderSubtle => _palette.borderSubtle;
  static style.Color get diffAdded => _palette.diffAdded;
  static style.Color get diffRemoved => _palette.diffRemoved;
  static style.Color get shadow => _palette.shadow;
}

OpenCodePalette _activePalette = OpenCodePalette.fallback;
w.Theme _activeTheme = _buildTheme(_activePalette);
String _activeThemeName = 'default';
Map<String, style.Color> _activeThemeColors = const <String, style.Color>{};
style.Color _activeRouteBackground = OpenCodePalette.fallback.background;

const openCodeDefaultThemeName = 'default';

w.Theme openCodeTheme() => _activeTheme;

style.Color openCodeThemeColor(String key, {required style.Color fallback}) {
  return _activeThemeColors[key] ?? fallback;
}

style.Color currentOpenCodeRouteBackground() => _activeRouteBackground;

void setOpenCodeRouteBackground(style.Color color) {
  _activeRouteBackground = color;
}

String currentOpenCodeThemeName() => _activeThemeName;

void resetOpenCodeThemeToDefault() {
  _activePalette = OpenCodePalette.fallback;
  OC._palette = _activePalette;
  _activeTheme = _buildTheme(_activePalette);
  _activeThemeName = openCodeDefaultThemeName;
  _activeThemeColors = const <String, style.Color>{};
  _activeRouteBackground = _activePalette.background;
}

Future<w.Theme> loadOpenCodeThemeAtLaunch({
  String themeName = 'opencode',
}) async {
  final path = await _resolveThemePath(themeName);
  if (path == null) {
    stderr.writeln(
      '[opencode] Theme "$themeName" not found. Using fallback palette.',
    );
    return _activeTheme;
  }

  try {
    final document = await OpenCodeThemeDocument.loadFromFile(path);
    _activeThemeColors = document.resolveThemeColors();
    final palette = OpenCodePalette.fromDocument(document);
    _activePalette = palette;
    OC._palette = palette;
    _activeTheme = _buildTheme(palette);
    _activeThemeName = _normalizeThemeName(themeName);
    _activeRouteBackground = palette.background;
    return _activeTheme;
  } catch (error) {
    stderr.writeln(
      '[opencode] Failed to load theme "$themeName" from $path: $error',
    );
    return _activeTheme;
  }
}

Future<bool> applyOpenCodeThemeOverride(String themeName) async {
  if (themeName == openCodeDefaultThemeName) {
    resetOpenCodeThemeToDefault();
    return true;
  }
  final before = _activeThemeName;
  await loadOpenCodeThemeAtLaunch(themeName: themeName);
  return _activeThemeName != before || themeName == _activeThemeName;
}

Future<List<String>> discoverOpenCodeThemeNames() async {
  final names = <String>{openCodeDefaultThemeName};
  for (final directory in _candidateThemeDirectories()) {
    final dir = Directory(directory);
    if (!await dir.exists()) continue;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!path.endsWith('.json')) continue;
      final fileName = path.split(Platform.pathSeparator).last;
      names.add(_normalizeThemeName(fileName));
    }
  }

  final sorted = names.toList()..sort();
  if (sorted.remove(openCodeDefaultThemeName)) {
    sorted.insert(0, openCodeDefaultThemeName);
  }
  return sorted;
}

Future<String?> _resolveThemePath(String themeName) async {
  final fileName = themeName.endsWith('.json') ? themeName : '$themeName.json';

  final direct = File(themeName);
  if (await direct.exists()) {
    return direct.path;
  }

  final directWithExt = File(fileName);
  if (await directWithExt.exists()) {
    return directWithExt.path;
  }

  for (final directory in _candidateThemeDirectories()) {
    final candidate = File('$directory/$fileName');
    if (await candidate.exists()) {
      return candidate.path;
    }
  }

  return null;
}

String _normalizeThemeName(String themeName) {
  final trimmed = themeName.trim();
  if (trimmed.endsWith('.json')) {
    return trimmed.substring(0, trimmed.length - '.json'.length);
  }
  return trimmed;
}

Iterable<String> _candidateThemeDirectories() sync* {
  final cwd = Directory.current.path;
  yield '$cwd/pkgs/artisanal_widgets/example/opencode/themes';
  yield '$cwd/example/opencode/themes';
  yield '$cwd/themes';

  if (Platform.script.scheme == 'file') {
    final scriptDir = File.fromUri(Platform.script).parent.path;
    yield '$scriptDir/themes';
  }
}

w.Theme _buildTheme(OpenCodePalette palette) {
  return w.Theme(
    primary: palette.primary,
    secondary: palette.secondary,
    surface: palette.backgroundPanel,
    background: palette.background,
    error: palette.error,
    success: palette.success,
    warning: palette.warning,
    onPrimary: palette.background,
    onSecondary: palette.background,
    onSurface: palette.text,
    onBackground: palette.text,
    onError: palette.background,
    muted: palette.textMuted,
    border: palette.border,
    surfaceVariant: palette.backgroundElement,
    onSurfaceVariant: palette.text,
    outline: palette.borderSubtle,
    info: palette.info,
    onSuccess: palette.background,
    onWarning: palette.background,
    onInfo: palette.background,
    highlight: palette.borderActive,
    onHighlight: palette.text,
    shadow: palette.shadow,
    titleLarge: style.Style().bold().foreground(palette.text),
    titleMedium: style.Style().bold().foreground(palette.text),
    titleSmall: style.Style().bold().foreground(palette.textMuted),
    bodyLarge: style.Style().foreground(palette.text),
    bodyMedium: style.Style().foreground(palette.text),
    bodySmall: style.Style().foreground(palette.textMuted),
    labelLarge: style.Style().foreground(palette.text),
    labelMedium: style.Style().foreground(palette.textMuted),
    labelSmall: style.Style().dim().foreground(palette.textMuted),
    statusBarTheme: w.StatusBarThemeData(
      background: palette.background,
      foreground: palette.textMuted,
      keyBackground: palette.backgroundElement,
      keyForeground: palette.text,
    ),
    accentPanelTheme: w.AccentPanelThemeData(
      accentColor: palette.primary,
      background: palette.backgroundPanel,
    ),
    commandPaletteTheme: w.CommandPaletteThemeData(
      background: palette.backgroundPanel,
      selectedBackground: palette.primary,
      selectedForeground: palette.background,
      headerForeground: palette.secondary,
      searchBackground: palette.backgroundElement,
      searchForeground: palette.textMuted,
      shortcutForeground: palette.textMuted,
    ),
  );
}
