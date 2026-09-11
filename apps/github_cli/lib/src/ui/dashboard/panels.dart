import 'package:artisanal_widgets/widgets.dart' as w;

w.Widget githubLoadingPanel(w.Theme theme) {
  return w.PanelBox(
    title: 'Loading',
    child: w.Row(
      gap: 1,
      children: [
        w.SpinnerIndicator(),
        w.Text('Running gh commands...', style: theme.bodyMedium),
      ],
    ),
  );
}

w.Widget githubErrorPanel(w.Theme theme, String error) {
  return w.PanelBox(
    title: 'gh error',
    borderColor: theme.error,
    child: w.Column(
      crossAxisAlignment: w.CrossAxisAlignment.start,
      gap: 1,
      children: [
        w.Text(error, style: theme.bodyMedium.copy()..foreground(theme.error)),
        w.Text('Press r to retry or q to quit.', style: theme.bodySmall),
      ],
    ),
  );
}

w.Widget githubEmptyPanel(w.Theme theme) {
  return w.PanelBox(
    title: 'No data',
    child: w.Text('No dashboard data loaded yet.', style: theme.bodyMedium),
  );
}

/// Lightweight placeholder shown in the detail pane while the user is
/// scrolling rapidly through the list.  Intentionally cheap to build so
/// that every keypress only costs the left-list render plus this widget.
/// Uses *static* text — no SpinnerIndicator — so no periodic EveryCmd
/// timer is created that would itself drive extra render cycles.
w.Widget githubNavigatingPanel(w.Theme theme) {
  return w.Column(
    mainAxisAlignment: w.MainAxisAlignment.center,
    crossAxisAlignment: w.CrossAxisAlignment.center,
    children: [
      w.Text(
        '↕  navigating…',
        style: theme.bodyMedium.copy()..foreground(theme.muted),
      ),
    ],
  );
}
