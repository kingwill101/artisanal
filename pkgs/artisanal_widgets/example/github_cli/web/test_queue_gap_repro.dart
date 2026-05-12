import 'package:artisanal/web.dart' show runWidgetAppInBrowser;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:github_cli/src/app/theme.dart';
import 'package:github_cli/src/models/display_item.dart';
import 'package:github_cli/src/models/overview.dart';
import 'package:github_cli/src/models/page.dart';
import 'package:github_cli/src/models/repository_label.dart';
import 'package:github_cli/src/ui/dashboard/work_queue_pane.dart';

void main() async {
  await runWidgetAppInBrowser(
    w.WidgetApp(
      w.ThemeScope(
        theme: githubDashboardThemes.first.theme(),
        child: _QueueGapRepro(),
      ),
    ),
  );
}

final class _QueueGapRepro extends w.StatefulWidget {
  _QueueGapRepro();

  @override
  w.State<_QueueGapRepro> createState() => _QueueGapReproState();
}

final class _QueueGapReproState extends w.State<_QueueGapRepro> {
  final _controller = w.WidgetScrollController();

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    return w.Container(
      color: theme.surface,
      child: w.Center(
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
                  items: const <GithubDisplayItem>[_item],
                  controller: _controller,
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
  }
}

const _item = GithubDisplayItem(
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

tui.Cmd? _noopOverviewFilterChanged(GithubOverviewFilter _) => null;

void _noopItemSelected(int _) {}
