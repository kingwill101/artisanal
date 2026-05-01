part of 'components_widgets.dart';

class ReplayEventPanel extends StatelessWidget {
  ReplayEventPanel({
    required this.presentation,
    this.title = 'Replay Event',
    this.maxDetailLines = 4,
    super.key,
  });

  final ReplayEventPresentation presentation;
  final String title;
  final int maxDetailLines;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final detailLines = presentation.detailLines
        .take(maxDetailLines)
        .toList(growable: false);

    return PanelBox(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        gap: 1,
        children: [
          Text(presentation.summary, style: theme.bodyMedium),
          Text(presentation.statusHint, style: theme.labelMedium),
          if (detailLines.isNotEmpty)
            ...detailLines.map((line) => Text(line, style: theme.bodySmall)),
        ],
      ),
    );
  }
}
