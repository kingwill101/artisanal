import 'package:artisanal_widgets/widgets.dart' as w;

final class GithubDashboardThemeChoice {
  GithubDashboardThemeChoice({
    required this.label,
    required w.Theme Function() theme,
  }) : _themeFactory = theme;

  final String label;
  final w.Theme Function() _themeFactory;
  w.Theme? _cachedTheme;

  w.Theme theme() => _cachedTheme ??= _themeFactory();
}

final githubDashboardThemes = <GithubDashboardThemeChoice>[
  GithubDashboardThemeChoice(
    label: 'opencode',
    theme: w.OpenCodeThemes.opencode,
  ),
  GithubDashboardThemeChoice(label: 'github', theme: w.OpenCodeThemes.github),
  GithubDashboardThemeChoice(
    label: 'tokyonight',
    theme: w.OpenCodeThemes.tokyonight,
  ),
  GithubDashboardThemeChoice(label: 'gruvbox', theme: w.OpenCodeThemes.gruvbox),
  GithubDashboardThemeChoice(
    label: 'rosepine',
    theme: w.OpenCodeThemes.rosepine,
  ),
  GithubDashboardThemeChoice(label: 'matrix', theme: w.OpenCodeThemes.matrix),
];
