/// Generated OpenCode themes for the artisanal widget system.
///
/// These themes are auto-generated from the OpenCode TUI theme JSON files.
/// Each theme provides both dark and light color variants using [AdaptiveColor].
///
/// To use a specific theme:
/// ```dart
/// import 'package:artisanal_widgets/widgets.dart';
///
/// setTheme(OpenCodeThemes.dracula());
/// ```
library;

import 'package:artisanal/style.dart';
import 'theme.dart';

/// All 33 OpenCode themes, ported from the official JSON definitions.
///
/// Each factory method returns a [Theme] with [AdaptiveColor] values
/// that automatically adjust for light/dark terminal backgrounds.
class OpenCodeThemes {
  OpenCodeThemes._();

  /// All available theme names.
  static const names = [
    'aura',
    'ayu',
    'carbonfox',
    'catppuccinFrappe',
    'catppuccinMacchiato',
    'catppuccin',
    'cobalt2',
    'cursor',
    'dracula',
    'everforest',
    'flexoki',
    'github',
    'gruvbox',
    'kanagawa',
    'lucentOrng',
    'material',
    'matrix',
    'mercury',
    'monokai',
    'nightowl',
    'nord',
    'oneDark',
    'opencode',
    'orng',
    'osakaJade',
    'palenight',
    'rosepine',
    'solarized',
    'synthwave84',
    'tokyonight',
    'vercel',
    'vesper',
    'zenburn',
  ];

  /// Get a theme by name (case-insensitive).
  ///
  /// Returns [opencode] if name is not found.
  static Theme byName(String name) {
    final lower = name.toLowerCase();
    switch (lower) {
      case 'aura':
        return aura();
      case 'ayu':
        return ayu();
      case 'carbonfox':
        return carbonfox();
      case 'catppuccinfrappe':
        return catppuccinFrappe();
      case 'catppuccinmacchiato':
        return catppuccinMacchiato();
      case 'catppuccin':
        return catppuccin();
      case 'cobalt2':
        return cobalt2();
      case 'cursor':
        return cursor();
      case 'dracula':
        return dracula();
      case 'everforest':
        return everforest();
      case 'flexoki':
        return flexoki();
      case 'github':
        return github();
      case 'gruvbox':
        return gruvbox();
      case 'kanagawa':
        return kanagawa();
      case 'lucentorng':
        return lucentOrng();
      case 'material':
        return material();
      case 'matrix':
        return matrix();
      case 'mercury':
        return mercury();
      case 'monokai':
        return monokai();
      case 'nightowl':
        return nightowl();
      case 'nord':
        return nord();
      case 'onedark':
        return oneDark();
      case 'opencode':
        return opencode();
      case 'orng':
        return orng();
      case 'osakajade':
        return osakaJade();
      case 'palenight':
        return palenight();
      case 'rosepine':
        return rosepine();
      case 'solarized':
        return solarized();
      case 'synthwave84':
        return synthwave84();
      case 'tokyonight':
        return tokyonight();
      case 'vercel':
        return vercel();
      case 'vesper':
        return vesper();
      case 'zenburn':
        return zenburn();
      default:
        return opencode();
    }
  }

  /// aura theme.
  static Theme aura() {
    const primary = BasicColor('#a277ff');
    const secondary = BasicColor('#f694ff');
    const accent = BasicColor('#a277ff');
    const error = BasicColor('#ff6767');
    const warning = BasicColor('#ffca85');
    const success = BasicColor('#61ffca');
    const info = BasicColor('#a277ff');
    const text = BasicColor('#edecee');
    const textMuted = BasicColor('#6d6d6d');
    const background = BasicColor('#0f0f0f');
    const backgroundPanel = BasicColor('#15141b');
    const backgroundElement = BasicColor('#15141b');
    const border = BasicColor('#2d2d2d');
    const borderActive = BasicColor('#6d6d6d');
    const borderSubtle = BasicColor('#2d2d2d');

    return _withEditorThemeOverrides(
      _buildTheme(
        primary: primary,
        secondary: secondary,
        accent: accent,
        error: error,
        warning: warning,
        success: success,
        info: info,
        text: text,
        textMuted: textMuted,
        background: background,
        backgroundPanel: backgroundPanel,
        backgroundElement: backgroundElement,
        border: border,
        borderActive: borderActive,
        borderSubtle: borderSubtle,
      ),
      inactiveShellBackground: background,
    );
  }

  /// ayu theme.
  static Theme ayu() {
    const primary = BasicColor('#59C2FF');
    const secondary = BasicColor('#D2A6FF');
    const accent = BasicColor('#E6B450');
    const error = BasicColor('#D95757');
    const warning = BasicColor('#E6B673');
    const success = BasicColor('#7FD962');
    const info = BasicColor('#39BAE6');
    const text = BasicColor('#BFBDB6');
    const textMuted = BasicColor('#565B66');
    const background = BasicColor('#0B0E14');
    const backgroundPanel = BasicColor('#0F131A');
    const backgroundElement = BasicColor('#0D1017');
    const border = BasicColor('#6C7380');
    const borderActive = BasicColor('#6C7380');
    const borderSubtle = BasicColor('#11151C');

    return _withEditorThemeOverrides(
      _buildTheme(
        primary: primary,
        secondary: secondary,
        accent: accent,
        error: error,
        warning: warning,
        success: success,
        info: info,
        text: text,
        textMuted: textMuted,
        background: background,
        backgroundPanel: backgroundPanel,
        backgroundElement: backgroundElement,
        border: border,
        borderActive: borderActive,
        borderSubtle: borderSubtle,
      ),
      inactiveShellBorderColor: borderSubtle,
    );
  }

  /// carbonfox theme.
  static Theme carbonfox() {
    const primary = AdaptiveColor(
      dark: BasicColor('#33b1ff'),
      light: BasicColor('#0043ce'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#78a9ff'),
      light: BasicColor('#0043ce'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#ff7eb6'),
      light: BasicColor('#9f1853'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#ee5396'),
      light: BasicColor('#9f1853'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#f1c21b'),
      light: BasicColor('#007d79'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#25be6a'),
      light: BasicColor('#198038'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#78a9ff'),
      light: BasicColor('#0043ce'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#f2f4f8'),
      light: BasicColor('#161616'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#7d848f'),
      light: BasicColor('#6f6f6f'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#161616'),
      light: BasicColor('#ffffff'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#1a1a1a'),
      light: BasicColor('#f4f4f4'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#1e1e1e'),
      light: BasicColor('#f4f4f4'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#303030'),
      light: BasicColor('#dcdcdc'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#33b1ff'),
      light: BasicColor('#0043ce'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#262626'),
      light: BasicColor('#e8e8e8'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// catppuccinFrappe theme.
  static Theme catppuccinFrappe() {
    const primary = BasicColor('#8da4e2');
    const secondary = BasicColor('#ca9ee6');
    const accent = BasicColor('#f4b8e4');
    const error = BasicColor('#e78284');
    const warning = BasicColor('#e5c890');
    const success = BasicColor('#a6d189');
    const info = BasicColor('#81c8be');
    const text = BasicColor('#c6d0f5');
    const textMuted = BasicColor('#b5bfe2');
    const background = BasicColor('#303446');
    const backgroundPanel = BasicColor('#292c3c');
    const backgroundElement = BasicColor('#232634');
    const border = BasicColor('#414559');
    const borderActive = BasicColor('#51576d');
    const borderSubtle = BasicColor('#626880');

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// catppuccinMacchiato theme.
  static Theme catppuccinMacchiato() {
    const primary = BasicColor('#8aadf4');
    const secondary = BasicColor('#c6a0f6');
    const accent = BasicColor('#f5bde6');
    const error = BasicColor('#ed8796');
    const warning = BasicColor('#eed49f');
    const success = BasicColor('#a6da95');
    const info = BasicColor('#8bd5ca');
    const text = BasicColor('#cad3f5');
    const textMuted = BasicColor('#b8c0e0');
    const background = BasicColor('#24273a');
    const backgroundPanel = BasicColor('#1e2030');
    const backgroundElement = BasicColor('#181926');
    const border = BasicColor('#363a4f');
    const borderActive = BasicColor('#494d64');
    const borderSubtle = BasicColor('#5b6078');

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// catppuccin theme.
  static Theme catppuccin() {
    const primary = AdaptiveColor(
      dark: BasicColor('#89b4fa'),
      light: BasicColor('#1e66f5'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#cba6f7'),
      light: BasicColor('#8839ef'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#f5c2e7'),
      light: BasicColor('#ea76cb'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#f38ba8'),
      light: BasicColor('#d20f39'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#f9e2af'),
      light: BasicColor('#df8e1d'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#a6e3a1'),
      light: BasicColor('#40a02b'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#94e2d5'),
      light: BasicColor('#179299'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#cdd6f4'),
      light: BasicColor('#4c4f69'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#bac2de'),
      light: BasicColor('#5c5f77'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#1e1e2e'),
      light: BasicColor('#eff1f5'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#181825'),
      light: BasicColor('#e6e9ef'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#11111b'),
      light: BasicColor('#dce0e8'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#313244'),
      light: BasicColor('#ccd0da'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#45475a'),
      light: BasicColor('#bcc0cc'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#585b70'),
      light: BasicColor('#acb0be'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// cobalt2 theme.
  static Theme cobalt2() {
    const primary = AdaptiveColor(
      dark: BasicColor('#0088ff'),
      light: BasicColor('#0066cc'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#9a5feb'),
      light: BasicColor('#7c4dff'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#2affdf'),
      light: BasicColor('#00acc1'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#ff0088'),
      light: BasicColor('#e91e63'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#ffc600'),
      light: BasicColor('#ff9800'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#9eff80'),
      light: BasicColor('#4caf50'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#ff9d00'),
      light: BasicColor('#ff5722'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#ffffff'),
      light: BasicColor('#193549'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#adb7c9'),
      light: BasicColor('#5c6b7d'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#193549'),
      light: BasicColor('#ffffff'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#122738'),
      light: BasicColor('#f5f7fa'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#1f4662'),
      light: BasicColor('#e8ecf1'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#1f4662'),
      light: BasicColor('#d3dae3'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#0088ff'),
      light: BasicColor('#0066cc'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#0e1e2e'),
      light: BasicColor('#e8ecf1'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// cursor theme.
  static Theme cursor() {
    const primary = AdaptiveColor(
      dark: BasicColor('#88c0d0'),
      light: BasicColor('#6f9ba6'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#81a1c1'),
      light: BasicColor('#3c7cab'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#88c0d0'),
      light: BasicColor('#6f9ba6'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#e34671'),
      light: BasicColor('#cf2d56'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#f1b467'),
      light: BasicColor('#db704b'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#3fa266'),
      light: BasicColor('#1f8a65'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#81a1c1'),
      light: BasicColor('#3c7cab'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#e4e4e4'),
      light: BasicColor('#141414'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#e4e4e4'),
      light: BasicColor('#141414'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#181818'),
      light: BasicColor('#fcfcfc'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#141414'),
      light: BasicColor('#f3f3f3'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#262626'),
      light: BasicColor('#ededed'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#e4e4e4'),
      light: BasicColor('#141414'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#88c0d0'),
      light: BasicColor('#6f9ba6'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#0f0f0f'),
      light: BasicColor('#e0e0e0'),
    );

    return _withEditorThemeOverrides(
      _buildTheme(
        primary: primary,
        secondary: secondary,
        accent: accent,
        error: error,
        warning: warning,
        success: success,
        info: info,
        text: text,
        textMuted: textMuted,
        background: background,
        backgroundPanel: backgroundPanel,
        backgroundElement: backgroundElement,
        border: border,
        borderActive: borderActive,
        borderSubtle: borderSubtle,
      ),
      inactiveShellBackground: background,
      inactiveShellBorderColor: borderSubtle,
      utilityBackground: backgroundElement,
      blurredTextForeground: text.dim,
      blurredPromptForeground: text.dim,
      blurredPlaceholderForeground: text.dim,
      blurredLineNumberForeground: text.dim,
      blurredCursorLineNumberForeground: text.dim,
    );
  }

  /// dracula theme.
  static Theme dracula() {
    const primary = BasicColor('#bd93f9');
    const secondary = BasicColor('#ff79c6');
    const accent = BasicColor('#8be9fd');
    const error = BasicColor('#ff5555');
    const warning = BasicColor('#f1fa8c');
    const success = BasicColor('#50fa7b');
    const info = BasicColor('#ffb86c');
    const text = AdaptiveColor(
      dark: BasicColor('#f8f8f2'),
      light: BasicColor('#282a36'),
    );
    const textMuted = BasicColor('#6272a4');
    const background = AdaptiveColor(
      dark: BasicColor('#282a36'),
      light: BasicColor('#f8f8f2'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#21222c'),
      light: BasicColor('#e8e8e2'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#44475a'),
      light: BasicColor('#d8d8d2'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#44475a'),
      light: BasicColor('#c8c8c2'),
    );
    const borderActive = BasicColor('#bd93f9');
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#191a21'),
      light: BasicColor('#e0e0e0'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// everforest theme.
  static Theme everforest() {
    const primary = AdaptiveColor(
      dark: BasicColor('#a7c080'),
      light: BasicColor('#8da101'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#7fbbb3'),
      light: BasicColor('#3a94c5'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#d699b6'),
      light: BasicColor('#df69ba'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#e67e80'),
      light: BasicColor('#f85552'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#e69875'),
      light: BasicColor('#f57d26'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#a7c080'),
      light: BasicColor('#8da101'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#83c092'),
      light: BasicColor('#35a77c'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#d3c6aa'),
      light: BasicColor('#5c6a72'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#7a8478'),
      light: BasicColor('#a6b0a0'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#2d353b'),
      light: BasicColor('#fdf6e3'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#333c43'),
      light: BasicColor('#efebd4'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#343f44'),
      light: BasicColor('#f4f0d9'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#859289'),
      light: BasicColor('#939f91'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#9da9a0'),
      light: BasicColor('#829181'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#7a8478'),
      light: BasicColor('#a6b0a0'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// flexoki theme.
  static Theme flexoki() {
    const primary = AdaptiveColor(
      dark: BasicColor('#DA702C'),
      light: BasicColor('#205EA6'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#4385BE'),
      light: BasicColor('#5E409D'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#8B7EC8'),
      light: BasicColor('#BC5215'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#D14D41'),
      light: BasicColor('#AF3029'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#DA702C'),
      light: BasicColor('#BC5215'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#879A39'),
      light: BasicColor('#66800B'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#3AA99F'),
      light: BasicColor('#24837B'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#CECDC3'),
      light: BasicColor('#100F0F'),
    );
    const textMuted = BasicColor('#6F6E69');
    const background = AdaptiveColor(
      dark: BasicColor('#100F0F'),
      light: BasicColor('#FFFCF0'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#1C1B1A'),
      light: BasicColor('#F2F0E5'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#282726'),
      light: BasicColor('#E6E4D9'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#575653'),
      light: BasicColor('#B7B5AC'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#6F6E69'),
      light: BasicColor('#878580'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#403E3C'),
      light: BasicColor('#CECDC3'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// github theme.
  static Theme github() {
    const primary = AdaptiveColor(
      dark: BasicColor('#58a6ff'),
      light: BasicColor('#0969da'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#bc8cff'),
      light: BasicColor('#8250df'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#39c5cf'),
      light: BasicColor('#1b7c83'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#f85149'),
      light: BasicColor('#cf222e'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#e3b341'),
      light: BasicColor('#9a6700'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#3fb950'),
      light: BasicColor('#1a7f37'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#d29922'),
      light: BasicColor('#bc4c00'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#c9d1d9'),
      light: BasicColor('#24292f'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#8b949e'),
      light: BasicColor('#57606a'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#0d1117'),
      light: BasicColor('#ffffff'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#010409'),
      light: BasicColor('#f6f8fa'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#161b22'),
      light: BasicColor('#f0f3f6'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#30363d'),
      light: BasicColor('#d0d7de'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#58a6ff'),
      light: BasicColor('#0969da'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#21262d'),
      light: BasicColor('#d8dee4'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// gruvbox theme.
  static Theme gruvbox() {
    const primary = AdaptiveColor(
      dark: BasicColor('#83a598'),
      light: BasicColor('#076678'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#d3869b'),
      light: BasicColor('#8f3f71'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#8ec07c'),
      light: BasicColor('#427b58'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#fb4934'),
      light: BasicColor('#9d0006'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#fe8019'),
      light: BasicColor('#af3a03'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#b8bb26'),
      light: BasicColor('#79740e'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#fabd2f'),
      light: BasicColor('#b57614'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#ebdbb2'),
      light: BasicColor('#3c3836'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#928374'),
      light: BasicColor('#7c6f64'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#282828'),
      light: BasicColor('#fbf1c7'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#3c3836'),
      light: BasicColor('#ebdbb2'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#504945'),
      light: BasicColor('#d5c4a1'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#665c54'),
      light: BasicColor('#bdae93'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#ebdbb2'),
      light: BasicColor('#3c3836'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#504945'),
      light: BasicColor('#d5c4a1'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// kanagawa theme.
  static Theme kanagawa() {
    const primary = AdaptiveColor(
      dark: BasicColor('#7E9CD8'),
      light: BasicColor('#2D4F67'),
    );
    const secondary = BasicColor('#957FB8');
    const accent = BasicColor('#D27E99');
    const error = BasicColor('#E82424');
    const warning = BasicColor('#D7A657');
    const success = BasicColor('#98BB6C');
    const info = BasicColor('#76946A');
    const text = AdaptiveColor(
      dark: BasicColor('#DCD7BA'),
      light: BasicColor('#54433A'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#727169'),
      light: BasicColor('#9E9389'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#1F1F28'),
      light: BasicColor('#F2E9DE'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#2A2A37'),
      light: BasicColor('#EAE4D7'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#363646'),
      light: BasicColor('#E3DCD2'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#54546D'),
      light: BasicColor('#D4CBBF'),
    );
    const borderActive = BasicColor('#C38D9D');
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#363646'),
      light: BasicColor('#DCD4C9'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// lucentOrng theme.
  static Theme lucentOrng() {
    const primary = BasicColor('#EC5B2B');
    const secondary = BasicColor('#EE7948');
    const accent = AdaptiveColor(
      dark: BasicColor('#FFF7F1'),
      light: BasicColor('#c94d24'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#e06c75'),
      light: BasicColor('#d1383d'),
    );
    const warning = BasicColor('#EC5B2B');
    const success = AdaptiveColor(
      dark: BasicColor('#6ba1e6'),
      light: BasicColor('#0062d1'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#56b6c2'),
      light: BasicColor('#318795'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#eeeeee'),
      light: BasicColor('#1a1a1a'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#808080'),
      light: BasicColor('#8a8a8a'),
    );
    const background = NoColor();
    const backgroundPanel = NoColor();
    const backgroundElement = NoColor();
    const border = BasicColor('#EC5B2B');
    const borderActive = AdaptiveColor(
      dark: BasicColor('#EE7948'),
      light: BasicColor('#c94d24'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#3c3c3c'),
      light: BasicColor('#d4d4d4'),
    );

    const editorShellBackground = AdaptiveColor(
      dark: BasicColor('#161210'),
      light: BasicColor('#fff4ec'),
    );
    const editorInactiveShellBackground = AdaptiveColor(
      dark: BasicColor('#100d0b'),
      light: BasicColor('#fffaf6'),
    );
    const editorBodyBackground = AdaptiveColor(
      dark: BasicColor('#1d1714'),
      light: BasicColor('#fffdfb'),
    );
    const editorInactiveBodyBackground = AdaptiveColor(
      dark: BasicColor('#171210'),
      light: BasicColor('#fff7f1'),
    );
    const editorUtilityBackground = AdaptiveColor(
      dark: BasicColor('#241b16'),
      light: BasicColor('#fff0e6'),
    );

    return _withEditorThemeOverrides(
      _buildTheme(
        primary: primary,
        secondary: secondary,
        accent: accent,
        error: error,
        warning: warning,
        success: success,
        info: info,
        text: text,
        textMuted: textMuted,
        background: background,
        backgroundPanel: backgroundPanel,
        backgroundElement: backgroundElement,
        border: border,
        borderActive: borderActive,
        borderSubtle: borderSubtle,
      ),
      shellBackground: editorShellBackground,
      inactiveShellBackground: editorInactiveShellBackground,
      bodyBackground: editorBodyBackground,
      inactiveBodyBackground: editorInactiveBodyBackground,
      utilityBackground: editorUtilityBackground,
    );
  }

  /// material theme.
  static Theme material() {
    const primary = AdaptiveColor(
      dark: BasicColor('#82aaff'),
      light: BasicColor('#6182b8'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#c792ea'),
      light: BasicColor('#7c4dff'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#89ddff'),
      light: BasicColor('#39adb5'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#f07178'),
      light: BasicColor('#e53935'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#ffcb6b'),
      light: BasicColor('#ffb300'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#c3e88d'),
      light: BasicColor('#91b859'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#ffcb6b'),
      light: BasicColor('#f4511e'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#eeffff'),
      light: BasicColor('#263238'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#546e7a'),
      light: BasicColor('#90a4ae'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#263238'),
      light: BasicColor('#fafafa'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#1e272c'),
      light: BasicColor('#f5f5f5'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#37474f'),
      light: BasicColor('#e7e7e8'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#37474f'),
      light: BasicColor('#e0e0e0'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#82aaff'),
      light: BasicColor('#6182b8'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#1e272c'),
      light: BasicColor('#eeeeee'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// matrix theme.
  static Theme matrix() {
    const primary = AdaptiveColor(
      dark: BasicColor('#2eff6a'),
      light: BasicColor('#1cc24b'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#00efff'),
      light: BasicColor('#24f6d9'),
    );
    const accent = BasicColor('#c770ff');
    const error = BasicColor('#ff4b4b');
    const warning = BasicColor('#e6ff57');
    const success = AdaptiveColor(
      dark: BasicColor('#62ff94'),
      light: BasicColor('#1cc24b'),
    );
    const info = BasicColor('#30b3ff');
    const text = AdaptiveColor(
      dark: BasicColor('#62ff94'),
      light: BasicColor('#203022'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#8ca391'),
      light: BasicColor('#748476'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#0a0e0a'),
      light: BasicColor('#eef3ea'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#0e130d'),
      light: BasicColor('#e4ebe1'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#141c12'),
      light: BasicColor('#dae1d7'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#1e2a1b'),
      light: BasicColor('#748476'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#2eff6a'),
      light: BasicColor('#1cc24b'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#141c12'),
      light: BasicColor('#dae1d7'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// mercury theme.
  static Theme mercury() {
    const primary = AdaptiveColor(
      dark: BasicColor('#8da4f5'),
      light: BasicColor('#5266eb'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#a7b6f8'),
      light: BasicColor('#465bd1'),
    );
    const accent = BasicColor('#8da4f5');
    const error = AdaptiveColor(
      dark: BasicColor('#fc92b4'),
      light: BasicColor('#b0175f'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#fc9b6f'),
      light: BasicColor('#a44200'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#77c599'),
      light: BasicColor('#036e43'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#77becf'),
      light: BasicColor('#007f95'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#dddde5'),
      light: BasicColor('#363644'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#9d9da8'),
      light: BasicColor('#70707d'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#171721'),
      light: BasicColor('#ffffff'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#10101a'),
      light: BasicColor('#fbfcfd'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#272735'),
      light: BasicColor('#f4f5f9'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#b4b7c8'),
      light: BasicColor('#707393'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#8da4f5'),
      light: BasicColor('#5266eb'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#b4b7c8'),
      light: BasicColor('#707393'),
    );

    return _withEditorThemeOverrides(
      _buildTheme(
        primary: primary,
        secondary: secondary,
        accent: accent,
        error: error,
        warning: warning,
        success: success,
        info: info,
        text: text,
        textMuted: textMuted,
        background: background,
        backgroundPanel: backgroundPanel,
        backgroundElement: backgroundElement,
        border: border,
        borderActive: borderActive,
        borderSubtle: borderSubtle,
      ),
      inactiveShellBorderColor: textMuted,
      inactiveBodyBorderColor: backgroundElement,
      utilityBackground: backgroundElement,
      inactiveMetaForeground: textMuted,
      blurredPromptForeground: textMuted,
      blurredTextForeground: textMuted,
      blurredPlaceholderForeground: textMuted,
      focusedLineNumberForeground: text,
      blurredLineNumberForeground: textMuted,
      blurredCursorLineNumberForeground: textMuted,
    );
  }

  /// monokai theme.
  static Theme monokai() {
    const primary = BasicColor('#66d9ef');
    const secondary = BasicColor('#ae81ff');
    const accent = BasicColor('#a6e22e');
    const error = BasicColor('#f92672');
    const warning = AdaptiveColor(
      dark: BasicColor('#e6db74'),
      light: BasicColor('#fd971f'),
    );
    const success = BasicColor('#a6e22e');
    const info = BasicColor('#fd971f');
    const text = AdaptiveColor(
      dark: BasicColor('#f8f8f2'),
      light: BasicColor('#272822'),
    );
    const textMuted = BasicColor('#75715e');
    const background = AdaptiveColor(
      dark: BasicColor('#272822'),
      light: BasicColor('#fafafa'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#1e1f1c'),
      light: BasicColor('#f0f0f0'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#3e3d32'),
      light: BasicColor('#e0e0e0'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#3e3d32'),
      light: BasicColor('#d0d0d0'),
    );
    const borderActive = BasicColor('#66d9ef');
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#1e1f1c'),
      light: BasicColor('#e8e8e8'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// nightowl theme.
  static Theme nightowl() {
    const primary = BasicColor('#82AAFF');
    const secondary = BasicColor('#7fdbca');
    const accent = BasicColor('#c792ea');
    const error = BasicColor('#EF5350');
    const warning = BasicColor('#ecc48d');
    const success = BasicColor('#c5e478');
    const info = BasicColor('#82AAFF');
    const text = BasicColor('#d6deeb');
    const textMuted = BasicColor('#5f7e97');
    const background = BasicColor('#011627');
    const backgroundPanel = BasicColor('#0b253a');
    const backgroundElement = BasicColor('#0b253a');
    const border = BasicColor('#5f7e97');
    const borderActive = BasicColor('#82AAFF');
    const borderSubtle = BasicColor('#5f7e97');

    return _withEditorThemeOverrides(
      _buildTheme(
        primary: primary,
        secondary: secondary,
        accent: accent,
        error: error,
        warning: warning,
        success: success,
        info: info,
        text: text,
        textMuted: textMuted,
        background: background,
        backgroundPanel: backgroundPanel,
        backgroundElement: backgroundElement,
        border: border,
        borderActive: borderActive,
        borderSubtle: borderSubtle,
      ),
      inactiveShellBackground: background,
      inactiveShellBorderColor: backgroundPanel,
      inactiveBodyBorderColor: backgroundPanel,
      blurredTextForeground: textMuted,
      blurredPromptForeground: textMuted,
      blurredPlaceholderForeground: textMuted,
      focusedLineNumberForeground: text,
      blurredLineNumberForeground: textMuted,
      blurredCursorLineBackground: background,
      blurredCursorLineNumberForeground: textMuted,
    );
  }

  /// nord theme.
  static Theme nord() {
    const primary = AdaptiveColor(
      dark: BasicColor('#88C0D0'),
      light: BasicColor('#5E81AC'),
    );
    const secondary = BasicColor('#81A1C1');
    const accent = BasicColor('#8FBCBB');
    const error = BasicColor('#BF616A');
    const warning = BasicColor('#D08770');
    const success = BasicColor('#A3BE8C');
    const info = AdaptiveColor(
      dark: BasicColor('#88C0D0'),
      light: BasicColor('#5E81AC'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#ECEFF4'),
      light: BasicColor('#2E3440'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#8B95A7'),
      light: BasicColor('#3B4252'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#2E3440'),
      light: BasicColor('#ECEFF4'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#3B4252'),
      light: BasicColor('#E5E9F0'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#434C5E'),
      light: BasicColor('#D8DEE9'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#434C5E'),
      light: BasicColor('#4C566A'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#4C566A'),
      light: BasicColor('#434C5E'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#434C5E'),
      light: BasicColor('#4C566A'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// oneDark theme.
  static Theme oneDark() {
    const primary = AdaptiveColor(
      dark: BasicColor('#61afef'),
      light: BasicColor('#4078f2'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#c678dd'),
      light: BasicColor('#a626a4'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#56b6c2'),
      light: BasicColor('#0184bc'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#e06c75'),
      light: BasicColor('#e45649'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#e5c07b'),
      light: BasicColor('#c18401'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#98c379'),
      light: BasicColor('#50a14f'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#d19a66'),
      light: BasicColor('#986801'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#abb2bf'),
      light: BasicColor('#383a42'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#5c6370'),
      light: BasicColor('#a0a1a7'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#282c34'),
      light: BasicColor('#fafafa'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#21252b'),
      light: BasicColor('#f0f0f1'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#353b45'),
      light: BasicColor('#eaeaeb'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#393f4a'),
      light: BasicColor('#d1d1d2'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#61afef'),
      light: BasicColor('#4078f2'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#2c313a'),
      light: BasicColor('#e0e0e1'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// opencode theme.
  static Theme opencode() {
    const primary = AdaptiveColor(
      dark: BasicColor('#fab283'),
      light: BasicColor('#3b7dd8'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#5c9cf5'),
      light: BasicColor('#7b5bb6'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#9d7cd8'),
      light: BasicColor('#d68c27'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#e06c75'),
      light: BasicColor('#d1383d'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#f5a742'),
      light: BasicColor('#d68c27'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#7fd88f'),
      light: BasicColor('#3d9a57'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#56b6c2'),
      light: BasicColor('#318795'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#eeeeee'),
      light: BasicColor('#1a1a1a'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#808080'),
      light: BasicColor('#8a8a8a'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#0a0a0a'),
      light: BasicColor('#ffffff'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#141414'),
      light: BasicColor('#fafafa'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#1e1e1e'),
      light: BasicColor('#f5f5f5'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#484848'),
      light: BasicColor('#b8b8b8'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#606060'),
      light: BasicColor('#a0a0a0'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#3c3c3c'),
      light: BasicColor('#d4d4d4'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// orng theme.
  static Theme orng() {
    const primary = BasicColor('#EC5B2B');
    const secondary = BasicColor('#EE7948');
    const accent = AdaptiveColor(
      dark: BasicColor('#FFF7F1'),
      light: BasicColor('#c94d24'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#e06c75'),
      light: BasicColor('#d1383d'),
    );
    const warning = BasicColor('#EC5B2B');
    const success = AdaptiveColor(
      dark: BasicColor('#6ba1e6'),
      light: BasicColor('#0062d1'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#56b6c2'),
      light: BasicColor('#318795'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#eeeeee'),
      light: BasicColor('#1a1a1a'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#808080'),
      light: BasicColor('#8a8a8a'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#0a0a0a'),
      light: BasicColor('#ffffff'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#141414'),
      light: BasicColor('#FFF7F1'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#1e1e1e'),
      light: BasicColor('#f5f0eb'),
    );
    const border = BasicColor('#EC5B2B');
    const borderActive = AdaptiveColor(
      dark: BasicColor('#EE7948'),
      light: BasicColor('#c94d24'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#3c3c3c'),
      light: BasicColor('#d4d4d4'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// osakaJade theme.
  static Theme osakaJade() {
    const primary = AdaptiveColor(
      dark: BasicColor('#2DD5B7'),
      light: BasicColor('#1faa90'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#D2689C'),
      light: BasicColor('#a8527a'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#549e6a'),
      light: BasicColor('#3d7a52'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#FF5345'),
      light: BasicColor('#c7392d'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#E5C736'),
      light: BasicColor('#b5a020'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#549e6a'),
      light: BasicColor('#3d7a52'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#2DD5B7'),
      light: BasicColor('#1faa90'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#C1C497'),
      light: BasicColor('#111c18'),
    );
    const textMuted = BasicColor('#53685B');
    const background = AdaptiveColor(
      dark: BasicColor('#111c18'),
      light: BasicColor('#F6F5DD'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#1a2520'),
      light: BasicColor('#E8E7CC'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#23372B'),
      light: BasicColor('#D5D4B8'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#3d4a44'),
      light: BasicColor('#A8A78C'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#2DD5B7'),
      light: BasicColor('#1faa90'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#23372B'),
      light: BasicColor('#D5D4B8'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// palenight theme.
  static Theme palenight() {
    const primary = AdaptiveColor(
      dark: BasicColor('#82aaff'),
      light: BasicColor('#4976eb'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#c792ea'),
      light: BasicColor('#a854f2'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#89ddff'),
      light: BasicColor('#00acc1'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#f07178'),
      light: BasicColor('#e53935'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#ffcb6b'),
      light: BasicColor('#ffb300'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#c3e88d'),
      light: BasicColor('#91b859'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#f78c6c'),
      light: BasicColor('#f4511e'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#a6accd'),
      light: BasicColor('#292d3e'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#676e95'),
      light: BasicColor('#8796b0'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#292d3e'),
      light: BasicColor('#fafafa'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#1e2132'),
      light: BasicColor('#f5f5f5'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#32364a'),
      light: BasicColor('#e7e7e8'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#32364a'),
      light: BasicColor('#e0e0e0'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#82aaff'),
      light: BasicColor('#4976eb'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#1e2132'),
      light: BasicColor('#eeeeee'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// rosepine theme.
  static Theme rosepine() {
    const primary = AdaptiveColor(
      dark: BasicColor('#9ccfd8'),
      light: BasicColor('#31748f'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#c4a7e7'),
      light: BasicColor('#907aa9'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#ebbcba'),
      light: BasicColor('#d7827e'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#eb6f92'),
      light: BasicColor('#b4637a'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#f6c177'),
      light: BasicColor('#ea9d34'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#31748f'),
      light: BasicColor('#286983'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#9ccfd8'),
      light: BasicColor('#56949f'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#e0def4'),
      light: BasicColor('#575279'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#6e6a86'),
      light: BasicColor('#9893a5'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#191724'),
      light: BasicColor('#faf4ed'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#1f1d2e'),
      light: BasicColor('#fffaf3'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#26233a'),
      light: BasicColor('#f2e9e1'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#403d52'),
      light: BasicColor('#dfdad9'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#9ccfd8'),
      light: BasicColor('#31748f'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#21202e'),
      light: BasicColor('#f4ede8'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// solarized theme.
  static Theme solarized() {
    const primary = BasicColor('#268bd2');
    const secondary = BasicColor('#6c71c4');
    const accent = BasicColor('#2aa198');
    const error = BasicColor('#dc322f');
    const warning = BasicColor('#b58900');
    const success = BasicColor('#859900');
    const info = BasicColor('#cb4b16');
    const text = AdaptiveColor(
      dark: BasicColor('#839496'),
      light: BasicColor('#657b83'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#586e75'),
      light: BasicColor('#93a1a1'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#002b36'),
      light: BasicColor('#fdf6e3'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#073642'),
      light: BasicColor('#eee8d5'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#073642'),
      light: BasicColor('#eee8d5'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#073642'),
      light: BasicColor('#eee8d5'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#586e75'),
      light: BasicColor('#93a1a1'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#073642'),
      light: BasicColor('#eee8d5'),
    );

    return _withEditorThemeOverrides(
      _buildTheme(
        primary: primary,
        secondary: secondary,
        accent: accent,
        error: error,
        warning: warning,
        success: success,
        info: info,
        text: text,
        textMuted: textMuted,
        background: background,
        backgroundPanel: backgroundPanel,
        backgroundElement: backgroundElement,
        border: border,
        borderActive: borderActive,
        borderSubtle: borderSubtle,
      ),
      inactiveShellBackground: background,
      inactiveShellBorderColor: backgroundPanel,
      inactiveBodyBorderColor: backgroundPanel,
      blurredTextForeground: textMuted,
      blurredPromptForeground: textMuted,
      blurredPlaceholderForeground: textMuted,
      focusedLineNumberForeground: text,
      blurredLineNumberForeground: textMuted,
      blurredCursorLineBackground: background,
      blurredCursorLineNumberForeground: textMuted,
    );
  }

  /// synthwave84 theme.
  static Theme synthwave84() {
    const primary = AdaptiveColor(
      dark: BasicColor('#36f9f6'),
      light: BasicColor('#00bcd4'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#ff7edb'),
      light: BasicColor('#e91e63'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#b084eb'),
      light: BasicColor('#9c27b0'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#fe4450'),
      light: BasicColor('#f44336'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#fede5d'),
      light: BasicColor('#ff9800'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#72f1b8'),
      light: BasicColor('#4caf50'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#ff8b39'),
      light: BasicColor('#ff5722'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#ffffff'),
      light: BasicColor('#262335'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#848bbd'),
      light: BasicColor('#5c5c8a'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#262335'),
      light: BasicColor('#fafafa'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#1e1a29'),
      light: BasicColor('#f5f5f5'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#2a2139'),
      light: BasicColor('#eeeeee'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#495495'),
      light: BasicColor('#e0e0e0'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#36f9f6'),
      light: BasicColor('#00bcd4'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#241b2f'),
      light: BasicColor('#f0f0f0'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// tokyonight theme.
  static Theme tokyonight() {
    const primary = AdaptiveColor(
      dark: BasicColor('#82aaff'),
      light: BasicColor('#2e7de9'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#c099ff'),
      light: BasicColor('#9854f1'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#ff966c'),
      light: BasicColor('#b15c00'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#ff757f'),
      light: BasicColor('#f52a65'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#ff966c'),
      light: BasicColor('#b15c00'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#c3e88d'),
      light: BasicColor('#587539'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#82aaff'),
      light: BasicColor('#2e7de9'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#c8d3f5'),
      light: BasicColor('#3760bf'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#828bb8'),
      light: BasicColor('#8990a3'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#1a1b26'),
      light: BasicColor('#e1e2e7'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#1e2030'),
      light: BasicColor('#d5d6db'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#222436'),
      light: BasicColor('#c8c9ce'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#737aa2'),
      light: BasicColor('#737a8c'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#9099b2'),
      light: BasicColor('#5a607d'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#545c7e'),
      light: BasicColor('#9699a8'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// vercel theme.
  static Theme vercel() {
    const primary = BasicColor('#0070F3');
    const secondary = AdaptiveColor(
      dark: BasicColor('#52A8FF'),
      light: BasicColor('#0062D1'),
    );
    const accent = BasicColor('#8E4EC6');
    const error = AdaptiveColor(
      dark: BasicColor('#E5484D'),
      light: BasicColor('#DC3545'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#FFB224'),
      light: BasicColor('#FF9500'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#46A758'),
      light: BasicColor('#388E3C'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#52A8FF'),
      light: BasicColor('#0070F3'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#EDEDED'),
      light: BasicColor('#171717'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#878787'),
      light: BasicColor('#666666'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#000000'),
      light: BasicColor('#FFFFFF'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#1A1A1A'),
      light: BasicColor('#FAFAFA'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#292929'),
      light: BasicColor('#EAEAEA'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#1F1F1F'),
      light: BasicColor('#EAEAEA'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#454545'),
      light: BasicColor('#999999'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#1A1A1A'),
      light: BasicColor('#EAEAEA'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// vesper theme.
  static Theme vesper() {
    const primary = BasicColor('#FFC799');
    const secondary = BasicColor('#99FFE4');
    const accent = BasicColor('#FFC799');
    const error = BasicColor('#FF8080');
    const warning = BasicColor('#FFC799');
    const success = BasicColor('#99FFE4');
    const info = BasicColor('#FFC799');
    const text = AdaptiveColor(
      dark: BasicColor('#FFF'),
      light: BasicColor('#101010'),
    );
    const textMuted = BasicColor('#A0A0A0');
    const background = AdaptiveColor(
      dark: BasicColor('#101010'),
      light: BasicColor('#FFF'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#101010'),
      light: BasicColor('#F0F0F0'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#101010'),
      light: BasicColor('#E0E0E0'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#282828'),
      light: BasicColor('#D0D0D0'),
    );
    const borderActive = BasicColor('#FFC799');
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#1C1C1C'),
      light: BasicColor('#E8E8E8'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// zenburn theme.
  static Theme zenburn() {
    const primary = AdaptiveColor(
      dark: BasicColor('#8cd0d3'),
      light: BasicColor('#5f7f8f'),
    );
    const secondary = AdaptiveColor(
      dark: BasicColor('#dc8cc3'),
      light: BasicColor('#8f5f8f'),
    );
    const accent = AdaptiveColor(
      dark: BasicColor('#93e0e3'),
      light: BasicColor('#5f8f8f'),
    );
    const error = AdaptiveColor(
      dark: BasicColor('#cc9393'),
      light: BasicColor('#8f5f5f'),
    );
    const warning = AdaptiveColor(
      dark: BasicColor('#f0dfaf'),
      light: BasicColor('#8f8f5f'),
    );
    const success = AdaptiveColor(
      dark: BasicColor('#7f9f7f'),
      light: BasicColor('#5f8f5f'),
    );
    const info = AdaptiveColor(
      dark: BasicColor('#dfaf8f'),
      light: BasicColor('#8f7f5f'),
    );
    const text = AdaptiveColor(
      dark: BasicColor('#dcdccc'),
      light: BasicColor('#3f3f3f'),
    );
    const textMuted = AdaptiveColor(
      dark: BasicColor('#9f9f9f'),
      light: BasicColor('#6f6f6f'),
    );
    const background = AdaptiveColor(
      dark: BasicColor('#3f3f3f'),
      light: BasicColor('#ffffef'),
    );
    const backgroundPanel = AdaptiveColor(
      dark: BasicColor('#4f4f4f'),
      light: BasicColor('#f5f5e5'),
    );
    const backgroundElement = AdaptiveColor(
      dark: BasicColor('#5f5f5f'),
      light: BasicColor('#ebebdb'),
    );
    const border = AdaptiveColor(
      dark: BasicColor('#5f5f5f'),
      light: BasicColor('#d0d0c0'),
    );
    const borderActive = AdaptiveColor(
      dark: BasicColor('#8cd0d3'),
      light: BasicColor('#5f7f8f'),
    );
    const borderSubtle = AdaptiveColor(
      dark: BasicColor('#4f4f4f'),
      light: BasicColor('#e0e0d0'),
    );

    return _buildTheme(
      primary: primary,
      secondary: secondary,
      accent: accent,
      error: error,
      warning: warning,
      success: success,
      info: info,
      text: text,
      textMuted: textMuted,
      background: background,
      backgroundPanel: backgroundPanel,
      backgroundElement: backgroundElement,
      border: border,
      borderActive: borderActive,
      borderSubtle: borderSubtle,
    );
  }

  /// Builds a [Theme] from OpenCode semantic color tokens.
  static Theme _buildTheme({
    required Color primary,
    required Color secondary,
    required Color accent,
    required Color error,
    required Color warning,
    required Color success,
    required Color info,
    required Color text,
    required Color textMuted,
    required Color background,
    required Color backgroundPanel,
    required Color backgroundElement,
    required Color border,
    required Color borderActive,
    required Color borderSubtle,
  }) {
    final textDim = text.dim;
    final mutedDim = textMuted.dim;

    return Theme(
      primary: primary,
      secondary: secondary,
      surface: backgroundPanel,
      background: background,
      error: error,
      success: success,
      warning: warning,
      onPrimary: background,
      onSecondary: background,
      onSurface: text,
      onBackground: text,
      onError: background,
      muted: textMuted,
      border: border,
      // Extended colors
      surfaceVariant: backgroundElement,
      onSurfaceVariant: text,
      outline: borderSubtle,
      info: info,
      onSuccess: background,
      onWarning: background,
      onInfo: background,
      highlight: borderActive,
      onHighlight: text,
      // Text styles
      titleLarge: Style().bold().foreground(text),
      titleMedium: Style().bold().foreground(text),
      titleSmall: Style().bold().foreground(textMuted),
      bodyLarge: Style().foreground(text),
      bodyMedium: Style().foreground(text),
      bodySmall: Style().foreground(textMuted),
      labelLarge: Style().foreground(text),
      labelMedium: Style().foreground(textMuted),
      labelSmall: Style().dim().foreground(textMuted),
      // Component themes
      statusBarTheme: StatusBarThemeData(
        background: background,
        foreground: textMuted,
        keyBackground: backgroundElement,
        keyForeground: text,
      ),
      accentPanelTheme: AccentPanelThemeData(
        accentColor: primary,
        background: backgroundPanel,
      ),
      commandPaletteTheme: CommandPaletteThemeData(
        background: backgroundPanel,
        selectedBackground: borderActive,
        selectedForeground: text,
        headerForeground: textMuted,
        shortcutForeground: textMuted,
        borderColor: border,
      ),
      listRowTheme: ListRowThemeData(
        background: backgroundPanel,
        alternateBackground: backgroundElement,
        foreground: text,
        mutedForeground: textMuted,
        accentForeground: primary,
        markerForeground: primary,
        separatorForeground: borderSubtle,
        selectedBackground: borderActive,
        selectedForeground: text,
        selectedMutedForeground: text,
        selectedAccentForeground: text,
        selectedMarkerForeground: text,
        selectedSeparatorForeground: text,
      ),
      editorTheme: EditorThemeData(
        shellBackground: backgroundElement,
        inactiveShellBackground: backgroundPanel,
        activeShellBorderColor: borderActive,
        inactiveShellBorderColor: border,
        bodyBackground: background,
        inactiveBodyBackground: backgroundPanel,
        activeBodyBorderColor: border,
        inactiveBodyBorderColor: borderSubtle,
        utilityBackground: backgroundPanel,
        utilityBorderColor: border,
        titleForeground: text,
        inactiveTitleForeground: textDim,
        metaForeground: textMuted,
        inactiveMetaForeground: mutedDim,
        focusedPromptForeground: text,
        blurredPromptForeground: textMuted,
        focusedTextForeground: text,
        blurredTextForeground: textDim,
        focusedPlaceholderForeground: textMuted,
        blurredPlaceholderForeground: mutedDim,
        focusedLineNumberForeground: textMuted,
        blurredLineNumberForeground: mutedDim,
        focusedCursorLineBackground: backgroundElement,
        blurredCursorLineBackground: backgroundPanel,
        focusedCursorLineNumberForeground: primary,
        blurredCursorLineNumberForeground: textMuted,
        searchMatchBackground: backgroundPanel,
        searchMatchUnderlineColor: primary,
      ),
    );
  }

  static Theme _withEditorThemeOverrides(
    Theme theme, {
    Color? shellBackground,
    Color? inactiveShellBackground,
    Color? bodyBackground,
    Color? inactiveBodyBackground,
    Color? inactiveShellBorderColor,
    Color? inactiveBodyBorderColor,
    Color? utilityBackground,
    Color? inactiveMetaForeground,
    Color? blurredPromptForeground,
    Color? blurredTextForeground,
    Color? blurredPlaceholderForeground,
    Color? focusedLineNumberForeground,
    Color? blurredLineNumberForeground,
    Color? blurredCursorLineBackground,
    Color? blurredCursorLineNumberForeground,
  }) {
    return theme.copyWith(
      editorTheme: theme.editorTheme?.copyWith(
        shellBackground: shellBackground,
        inactiveShellBackground: inactiveShellBackground,
        bodyBackground: bodyBackground,
        inactiveBodyBackground: inactiveBodyBackground,
        inactiveShellBorderColor: inactiveShellBorderColor,
        inactiveBodyBorderColor: inactiveBodyBorderColor,
        utilityBackground: utilityBackground,
        inactiveMetaForeground: inactiveMetaForeground,
        blurredPromptForeground: blurredPromptForeground,
        blurredTextForeground: blurredTextForeground,
        blurredPlaceholderForeground: blurredPlaceholderForeground,
        focusedLineNumberForeground: focusedLineNumberForeground,
        blurredLineNumberForeground: blurredLineNumberForeground,
        blurredCursorLineBackground: blurredCursorLineBackground,
        blurredCursorLineNumberForeground: blurredCursorLineNumberForeground,
      ),
    );
  }
}
