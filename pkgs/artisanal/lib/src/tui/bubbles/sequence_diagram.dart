import 'package:artisanal/src/charting/charting.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/cmd.dart';

/// A TUI bubble that renders a Mermaid sequence diagram.
///
/// ## Example
///
/// ```dart
/// final diagram = SequenceDiagramModel(
///   mermaid: '''
///     sequenceDiagram
///       participant A as Alice
///       participant B as Bob
///       A->>B: Hello
///       B-->>A: Hi back!
///   ''',
///   width: 80,
/// );
/// print(diagram.view());
/// ```
class SequenceDiagramModel extends ViewComponent {
  SequenceDiagramModel({
    this.mermaid = '',
    this.width = 80,
    this.height = 24,
    SequenceDiagramTheme? theme,
  }) : theme = theme ?? SequenceDiagramTheme.defaultTheme;

  /// Mermaid sequence diagram source text.
  final String mermaid;

  /// Render width in cells.
  final int width;

  /// Render height in cells.
  final int height;

  /// Theme for rendering.
  final SequenceDiagramTheme theme;

  /// Parsed diagram (computed from [mermaid]).
  SequenceDiagram? get diagram =>
      mermaid.isNotEmpty ? parseSequenceDiagram(mermaid) : null;

  /// Creates a copy with the given fields replaced.
  SequenceDiagramModel copyWith({
    String? mermaid,
    int? width,
    int? height,
    SequenceDiagramTheme? theme,
  }) {
    return SequenceDiagramModel(
      mermaid: mermaid ?? this.mermaid,
      width: width ?? this.width,
      height: height ?? this.height,
      theme: theme ?? this.theme,
    );
  }

  /// Whether the diagram parsed successfully.
  bool get isValid => diagram != null;

  /// Number of participants.
  int get participantCount => diagram?.participants.length ?? 0;

  /// Number of messages.
  int get messageCount => diagram?.messages.length ?? 0;

  /// Number of steps in the timeline.
  int get stepCount => diagram?.steps.length ?? 0;

  @override
  Cmd? init() => null;

  @override
  (SequenceDiagramModel, Cmd?) update(Msg msg) => (this, null);

  @override
  String view() {
    final d = diagram;
    if (d == null || d.participants.isEmpty) {
      return _emptyView();
    }
    return renderSequenceDiagram(mermaid, theme: theme, maxWidth: width);
  }

  String _emptyView() {
    if (mermaid.isEmpty) {
      return 'No Mermaid source provided.';
    }
    return 'Failed to parse sequence diagram.\nSource: ${mermaid.split('\n').first}';
  }
}
