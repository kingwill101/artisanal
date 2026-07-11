import 'package:artisanal/uv.dart' as uv;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:github_cli/src/app/theme.dart';
import 'package:github_cli/src/models/display_item.dart';
import 'package:github_cli/src/models/overview.dart';
import 'package:github_cli/src/models/page.dart';
import 'package:github_cli/src/models/repository_label.dart';
import 'package:github_cli/src/ui/dashboard/work_queue_pane.dart';

Future<void> main() async {
  final tester = WidgetTester(screenWidth: 58, screenHeight: 12);
  try {
    final theme = githubDashboardThemes.first.theme();
    final controller = w.WidgetScrollController();
    const item = GithubDisplayItem(
      target: GithubDisplayTarget.pullRequest,
      kind: 'pr',
      number: 63358,
      title: '[vm/io] Range check SynchronousSocket_WriteList arguments',
      body: '',
      url: 'https://github.com/dart-lang/sdk/pull/63358',
      repository: '',
      author: 'LemonTeatw1',
      status: 'checks 2/2',
      updatedAt: null,
      footer: '46 comments / review pending',
      labels: <String>[],
      labelDetails: <GithubRepositoryLabel>[],
      commentCount: 46,
    );

    await tester.pumpWidget(
      w.ThemeScope(
        theme: theme,
        child: w.SizedBox(
          width: 58,
          height: 12,
          child: githubWorkQueuePane(
            theme: theme,
            tabIndex: 0,
            overviewFilter: GithubOverviewFilter.assigned,
            selectedIndex: 0,
            pageStatus: const GithubPageStatus(
              loaded: 1,
              totalCount: 1,
              hasNextPage: false,
              loading: false,
              error: null,
            ),
            items: const <GithubDisplayItem>[item],
            controller: controller,
            width: 58,
            onOverviewFilterChanged: _noopOverviewFilterChanged,
            onItemSelected: _noopItemSelected,
          ),
        ),
      ),
    );

    final view = tester.view;
    print('VIEW');
    print(view);

    final screen = uv.ScreenBuffer(58, 12);
    final styled = uv.StyledString(view)..wrap = true;
    styled.draw(screen, screen.bounds());

    for (var y = 0; y < 12; y++) {
      final line = StringBuffer();
      for (var x = 0; x < 58; x++) {
        final cell = screen.cellAt(x, y);
        line.write(cell == null || cell.isZero ? ' ' : cell.content);
      }
      print('LINE $y: ${line.toString()}');
    }

    for (var y = 0; y < 12; y++) {
      for (var x = 0; x < 58; x++) {
        final cell = screen.cellAt(x, y);
        if (cell == null || cell.isZero || cell.content != ' ') continue;
        if (cell.style.bg == null) {
          print(
            'space without bg at x=$x y=$y fg=${cell.style.fg} attrs=${cell.style.attrs}',
          );
        }
      }
    }
  } finally {
    await tester.dispose();
  }
}

tui.Cmd? _noopOverviewFilterChanged(GithubOverviewFilter _) => null;

void _noopItemSelected(int _) {}
