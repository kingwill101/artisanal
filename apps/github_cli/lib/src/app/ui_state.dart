import 'package:artisanal_widgets/widgets.dart' as w;

import 'layout_mode.dart';
import 'theme.dart';

final class GithubDashboardUiState {
  GithubDashboardLayoutMode layoutMode = GithubDashboardLayoutMode.split;
  int themeIndex = 0;
  w.DiffViewMode diffViewMode = w.DiffViewMode.unified;
  bool commandPaletteOpen = false;

  GithubDashboardThemeChoice get themeChoice =>
      githubDashboardThemes[themeIndex];
}
