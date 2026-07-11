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
  final tester = WidgetTester(screenWidth: 100, screenHeight: 12);
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
      repository: 'dart-lang/sdk',
      author: 'LemonTeatw1',
      status: 'pending',
      updatedAt: null,
      footer: '46 comments / review pending',
      labels: <String>['vm/io'],
      labelDetails: <GithubRepositoryLabel>[
        GithubRepositoryLabel(name: 'vm/io', color: '#808080'),
      ],
      commentCount: 46,
    );

    await tester.pumpWidget(
      w.ThemeScope(
        theme: theme,
        child: w.SizedBox(
          width: 100,
          height: 12,
          child: w.Row(
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Container(
                width: 58,
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
              w.VerticalDivider(
                height: 12,
                style: theme.bodySmall.copy()..foreground(theme.border),
              ),
              w.Expanded(
                child: w.Container(
                  padding: const w.EdgeInsets.only(left: 2),
                  child: w.Text(
                    'detail pane placeholder',
                    style: theme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final view = tester.view;
    print('VIEW');
    print(view);

    final screen = uv.ScreenBuffer(100, 12);
    final styled = uv.StyledString(view)..wrap = true;
    styled.draw(screen, screen.bounds());

    for (var y = 0; y < 6; y++) {
      final line = StringBuffer();
      for (var x = 0; x < 70; x++) {
        final cell = screen.cellAt(x, y);
        line.write(cell == null || cell.isZero ? ' ' : cell.content);
      }
      print('LINE $y: ${line.toString()}');
    }

    for (var y = 2; y <= 5; y++) {
      for (var x = 0; x < 58; x++) {
        final cell = screen.cellAt(x, y);
        if (cell == null || cell.isZero || cell.content != ' ') continue;
        if (cell.style.bg == null) {
          print(
            'left-pane space without bg at x=$x y=$y fg=${cell.style.fg} attrs=${cell.style.attrs}',
          );
        }
      }
    }

    for (final y in [2, 3, 4]) {
      for (var x = 0; x < 58; x++) {
        final cell = screen.cellAt(x, y);
        if (cell == null || cell.isZero) continue;
        if (cell.content != ' ') continue;
        final left = x > 0 ? screen.cellAt(x - 1, y) : null;
        final right = x < 57 ? screen.cellAt(x + 1, y) : null;
        if (left?.style.bg != null && left?.style.bg == right?.style.bg) {
          print(
            'bridge candidate x=$x y=$y leftBg=${left?.style.bg} selfBg=${cell.style.bg} rightBg=${right?.style.bg} left=${left?.content} right=${right?.content}',
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
