part of 'components_widgets.dart';

/// Signal level for a [DecisionCard].
///
/// Maps to a traffic-light color scheme:
/// - [green]: safe / proceed
/// - [yellow]: caution / review
/// - [red]: stop / alert
enum DecisionSignal {
  green,
  yellow,
  red;

  /// Display label for the signal badge.
  String get label => switch (this) {
    DecisionSignal.green => 'OK',
    DecisionSignal.yellow => 'WARN',
    DecisionSignal.red => 'ALERT',
  };
}

/// Progressive-disclosure level for a [DecisionCard].
///
/// Each level includes all information from lower levels.
enum DisclosureLevel {
  /// Level 0: traffic-light badge + action label only.
  trafficLight,

  /// Level 1: adds a one-sentence plain-English explanation.
  plainEnglish,

  /// Level 2: adds evidence terms with direction indicators.
  evidenceTerms,

  /// Level 3: adds full quantitative details (CI, loss, etc.).
  fullDetails,
}

/// Direction of an evidence term.
enum EvidenceDirection {
  /// Evidence supports the decision.
  supporting,

  /// Evidence opposes the decision.
  opposing,

  /// Evidence is neutral.
  neutral,
}

/// A single evidence term in a [DecisionCard].
class EvidenceTerm {
  const EvidenceTerm({
    required this.label,
    required this.factor,
    required this.direction,
  });

  /// Name of the evidence (e.g., "change_rate").
  final String label;

  /// Numeric factor or weight (e.g., Bayes factor).
  final double factor;

  /// Direction of the evidence.
  final EvidenceDirection direction;
}

/// Quantitative details for level-3 disclosure.
class DecisionDetails {
  const DecisionDetails({
    required this.logPosterior,
    required this.confidenceLow,
    required this.confidenceHigh,
    required this.expectedLoss,
    this.lossAvoided,
  });

  /// Log-posterior probability.
  final double logPosterior;

  /// Lower bound of confidence interval.
  final double confidenceLow;

  /// Upper bound of confidence interval.
  final double confidenceHigh;

  /// Expected loss of the chosen decision.
  final double expectedLoss;

  /// Loss avoided by choosing this over the next-best option.
  final double? lossAvoided;
}

/// Data for a [DecisionCard].
class DecisionData {
  const DecisionData({
    required this.signal,
    required this.actionLabel,
    this.level = DisclosureLevel.trafficLight,
    this.explanation,
    this.evidence,
    this.details,
  });

  /// Traffic-light signal.
  final DecisionSignal signal;

  /// Short label for the chosen action (e.g., "full_redraw").
  final String actionLabel;

  /// Disclosure level (controls which sections are visible).
  final DisclosureLevel level;

  /// Plain-English explanation (shown at level >= plainEnglish).
  final String? explanation;

  /// Evidence terms (shown at level >= evidenceTerms).
  final List<EvidenceTerm>? evidence;

  /// Quantitative details (shown at level >= fullDetails).
  final DecisionDetails? details;
}

/// A bordered card showing progressive-disclosure decision transparency.
///
/// Renders a traffic-light badge, action label, explanation, evidence terms,
/// and/or quantitative details depending on the [DisclosureLevel].
///
/// ```dart
/// DecisionCard(
///   data: DecisionData(
///     signal: DecisionSignal.green,
///     actionLabel: 'full_redraw',
///     level: DisclosureLevel.evidenceTerms,
///     explanation: 'High confidence in rendering strategy.',
///     evidence: [
///       EvidenceTerm(label: 'change_rate', factor: 3.5, direction: EvidenceDirection.supporting),
///     ],
///   ),
/// )
/// ```
class DecisionCard extends StatelessWidget {
  DecisionCard({
    required this.data,
    this.border = Border.rounded,
    this.padding,
    this.background,
    super.key,
  });

  /// The decision data to display.
  final DecisionData data;

  /// Border style for the card.
  final Border? border;

  /// Padding inside the card.
  final EdgeInsets? padding;

  /// Background color. Defaults to [Theme.surface].
  final Color? background;

  /// Minimum height needed to render all content.
  int get minHeight {
    var h = 3; // top border + signal row + bottom border
    if (data.level.index >= DisclosureLevel.plainEnglish.index &&
        data.explanation != null) {
      h += 1;
    }
    if (data.level.index >= DisclosureLevel.evidenceTerms.index &&
        data.evidence != null &&
        data.evidence!.isNotEmpty) {
      h += 1; // header
      h += data.evidence!.length;
    }
    if (data.level.index >= DisclosureLevel.fullDetails.index &&
        data.details != null) {
      h += 2; // separator + stats line
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final bg = background ?? theme.surface;
    final accent = _accentColor(theme);

    final badgeStyle = _copyStyle(theme.labelMedium)
      ..foreground(_badgeFgColor(theme))
      ..background(_badgeBgColor(theme))
      ..bold();
    final titleStyle = _copyStyle(theme.titleSmall)
      ..foreground(theme.onSurface)
      ..bold();
    final dimStyle = _copyStyle(theme.bodySmall)..foreground(theme.muted);
    final headerStyle = _copyStyle(theme.labelSmall)
      ..foreground(theme.border)
      ..bold();
    final detailStyle = _copyStyle(theme.bodySmall)..foreground(theme.border);

    final children = <Widget>[];

    // Row 1: traffic-light badge + action label
    children.add(
      Row(
        gap: 1,
        children: [
          Text(' ${data.signal.label} ', style: badgeStyle),
          Text(data.actionLabel, style: titleStyle),
        ],
      ),
    );

    // Row 2: explanation (level >= plainEnglish)
    if (data.level.index >= DisclosureLevel.plainEnglish.index &&
        data.explanation != null) {
      children.add(Text(data.explanation!, style: dimStyle));
    }

    // Evidence terms (level >= evidenceTerms)
    if (data.level.index >= DisclosureLevel.evidenceTerms.index &&
        data.evidence != null &&
        data.evidence!.isNotEmpty) {
      children.add(Text('Evidence:', style: headerStyle));
      for (final term in data.evidence!) {
        final dirChar = switch (term.direction) {
          EvidenceDirection.supporting => '+',
          EvidenceDirection.opposing => '-',
          EvidenceDirection.neutral => '~',
        };
        final dirStyle = _copyStyle(theme.bodySmall)
          ..foreground(_evidenceFgColor(theme, term.direction));
        children.add(
          Text(
            '  $dirChar ${term.label}: BF=${term.factor.toStringAsFixed(2)}',
            style: dirStyle,
          ),
        );
      }
    }

    // Full details (level >= fullDetails)
    if (data.level.index >= DisclosureLevel.fullDetails.index &&
        data.details != null) {
      final d = data.details!;
      children.add(Text('─' * 20, style: dimStyle));
      final lossStr = d.lossAvoided != null
          ? ' loss=${d.expectedLoss.toStringAsFixed(4)} avoided=${d.lossAvoided!.toStringAsFixed(4)}'
          : ' loss=${d.expectedLoss.toStringAsFixed(4)}';
      children.add(
        Text(
          'log_post=${d.logPosterior.toStringAsFixed(3)} CI=[${d.confidenceLow.toStringAsFixed(3)},${d.confidenceHigh.toStringAsFixed(3)}]$lossStr',
          style: detailStyle,
        ),
      );
    }

    return Frame(
      padding: padding ?? const EdgeInsets.all(1),
      background: bg,
      border: border ?? Border.rounded,
      borderColor: accent,
      child: Column(gap: 0, children: children),
    );
  }

  Color _accentColor(Theme theme) => switch (data.signal) {
    DecisionSignal.green => theme.success,
    DecisionSignal.yellow => theme.warning,
    DecisionSignal.red => theme.error,
  };

  Color _badgeFgColor(Theme theme) => switch (data.signal) {
    DecisionSignal.green => theme.success,
    DecisionSignal.yellow => theme.warning,
    DecisionSignal.red => theme.error,
  };

  Color _badgeBgColor(Theme theme) => switch (data.signal) {
    DecisionSignal.green => theme.surface,
    DecisionSignal.yellow => theme.surface,
    DecisionSignal.red => theme.surface,
  };

  Color _evidenceFgColor(Theme theme, EvidenceDirection dir) => switch (dir) {
    EvidenceDirection.supporting => theme.success,
    EvidenceDirection.opposing => theme.error,
    EvidenceDirection.neutral => theme.muted,
  };
}
