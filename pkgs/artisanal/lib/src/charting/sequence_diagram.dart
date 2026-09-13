/// Mermaid sequence diagram renderer.
///
/// {@category Charting}
///
/// Parses Mermaid `sequenceDiagram` syntax and renders it as styled terminal art
/// using UV Canvas/Screen infrastructure. Supports participants, messages with
/// arrow variants, notes, control fragments (alt/else/loop), participant groups
/// (box/end), rect regions, autonumbering, and inline CSS color names.
///
/// ```dart
/// import 'package:artisanal/artisanal.dart';
///
/// void main() {
///   // String convenience API
///   final text = renderSequenceDiagram('''
///     sequenceDiagram
///       participant B as Browser
///       participant S as Server
///       B->>S: GET /
///       S-->>B: 401 WWW-Auth
///   ''');
///   print(text);
///
///   // Parsed data + UV rendering
///   final diagram = parseSequenceDiagram('...');
///   if (diagram != null) {
///     final canvas = Canvas(80, 20);
///     drawSequenceDiagram(
///       canvas,
///       rect(0, 0, 80, 20),
///       diagram,
///     );
///   }
/// }
/// ```
library;

import 'dart:math' as math;

import 'package:ultraviolet/ultraviolet.dart'
    show
        Canvas,
        Cell,
        Rectangle,
        UvColor,
        UvRgb,
        UvStyle,
        rect,
        wrapAnsiPreserving;

import 'package:artisanal/src/charting/core.dart' show putCell, putText;
import 'package:artisanal/style.dart';

// ─── CSS color name lookup ────────────────────────────────────────────────

const _cssColorNames = <String, (int, int, int)>{
  'black': (0, 0, 0),
  'silver': (192, 192, 192),
  'gray': (128, 128, 128),
  'grey': (128, 128, 128),
  'white': (255, 255, 255),
  'maroon': (128, 0, 0),
  'red': (255, 0, 0),
  'purple': (128, 0, 128),
  'fuchsia': (255, 0, 255),
  'green': (0, 128, 0),
  'lime': (0, 255, 0),
  'olive': (128, 128, 0),
  'yellow': (255, 255, 0),
  'navy': (0, 0, 128),
  'blue': (0, 0, 255),
  'teal': (0, 128, 128),
  'aqua': (0, 255, 255),
  'orange': (255, 165, 0),
  'aliceblue': (240, 248, 255),
  'antiquewhite': (250, 235, 215),
  'aquamarine': (127, 255, 212),
  'azure': (240, 255, 255),
  'beige': (245, 245, 220),
  'bisque': (255, 228, 196),
  'blanchedalmond': (255, 235, 205),
  'blueviolet': (138, 43, 226),
  'brown': (165, 42, 42),
  'burlywood': (222, 184, 135),
  'cadetblue': (95, 158, 160),
  'chartreuse': (127, 255, 0),
  'chocolate': (210, 105, 30),
  'coral': (255, 127, 80),
  'cornflowerblue': (100, 149, 237),
  'cornsilk': (255, 248, 220),
  'crimson': (220, 20, 60),
  'cyan': (0, 255, 255),
  'darkblue': (0, 0, 139),
  'darkcyan': (0, 139, 139),
  'darkgoldenrod': (184, 134, 11),
  'darkgray': (169, 169, 169),
  'darkgrey': (169, 169, 169),
  'darkgreen': (0, 100, 0),
  'darkkhaki': (189, 183, 107),
  'darkmagenta': (139, 0, 139),
  'darkolivegreen': (85, 107, 47),
  'darkorange': (255, 140, 0),
  'darkorchid': (153, 50, 204),
  'darkred': (139, 0, 0),
  'darksalmon': (233, 150, 122),
  'darkseagreen': (143, 205, 169),
  'darkslateblue': (72, 61, 139),
  'darkslategray': (47, 79, 79),
  'darkslategrey': (47, 79, 79),
  'darkturquoise': (0, 206, 209),
  'darkviolet': (148, 0, 211),
  'deeppink': (255, 20, 147),
  'deepskyblue': (0, 191, 255),
  'dimgray': (105, 105, 105),
  'dimgrey': (105, 105, 105),
  'dodgerblue': (30, 144, 255),
  'firebrick': (178, 34, 34),
  'floralwhite': (255, 250, 240),
  'forestgreen': (34, 139, 34),
  'gainsboro': (220, 220, 220),
  'ghostwhite': (248, 248, 255),
  'gold': (255, 215, 0),
  'goldenrod': (218, 165, 32),
  'greenyellow': (173, 255, 47),
  'honeydew': (240, 255, 240),
  'hotpink': (255, 105, 180),
  'indianred': (205, 92, 92),
  'indigo': (75, 0, 130),
  'ivory': (255, 255, 240),
  'khaki': (240, 230, 140),
  'lavender': (230, 230, 250),
  'lavenderblush': (255, 240, 245),
  'lawngreen': (124, 252, 0),
  'lemonchiffon': (255, 250, 205),
  'lightblue': (173, 216, 230),
  'lightcoral': (240, 128, 128),
  'lightcyan': (224, 255, 255),
  'lightgoldenrodyellow': (250, 250, 210),
  'lightgray': (211, 211, 211),
  'lightgrey': (211, 211, 211),
  'lightgreen': (144, 238, 144),
  'lightpink': (255, 182, 193),
  'lightsalmon': (255, 160, 122),
  'lightseagreen': (32, 178, 170),
  'lightskyblue': (135, 206, 250),
  'lightslategray': (119, 136, 153),
  'lightslategrey': (119, 136, 153),
  'lightsteelblue': (176, 196, 222),
  'lightyellow': (255, 255, 224),
  'limegreen': (50, 205, 50),
  'linen': (250, 240, 230),
  'magenta': (255, 0, 255),
  'mediumaquamarine': (102, 205, 170),
  'mediumblue': (0, 0, 205),
  'mediumorchid': (186, 85, 211),
  'mediumpurple': (147, 112, 219),
  'mediumseagreen': (60, 179, 113),
  'mediumslateblue': (123, 104, 238),
  'mediumspringgreen': (0, 250, 154),
  'mediumturquoise': (72, 209, 204),
  'mediumvioletred': (199, 21, 133),
  'midnightblue': (25, 25, 112),
  'mintcream': (245, 255, 250),
  'mistyrose': (255, 228, 225),
  'moccasin': (255, 228, 181),
  'navajowhite': (255, 222, 173),
  'oldlace': (253, 245, 230),
  'olivedrab': (107, 142, 35),
  'orangered': (255, 69, 0),
  'orchid': (218, 112, 214),
  'palegoldenrod': (238, 232, 170),
  'palegreen': (152, 251, 152),
  'paleturquoise': (175, 238, 238),
  'palevioletred': (219, 112, 147),
  'papayawhip': (255, 239, 213),
  'peachpuff': (255, 218, 185),
  'peru': (205, 133, 63),
  'pink': (255, 192, 203),
  'plum': (221, 160, 221),
  'powderblue': (176, 224, 230),
  'rebeccapurple': (102, 51, 153),
  'rosybrown': (188, 143, 143),
  'royalblue': (65, 105, 225),
  'saddlebrown': (139, 69, 19),
  'salmon': (250, 128, 114),
  'sandybrown': (244, 164, 96),
  'seagreen': (46, 139, 87),
  'seashell': (255, 245, 238),
  'sienna': (160, 82, 45),
  'skyblue': (135, 206, 235),
  'slateblue': (106, 90, 205),
  'slategray': (112, 128, 144),
  'slategrey': (112, 128, 144),
  'snow': (255, 250, 250),
  'springgreen': (0, 255, 127),
  'steelblue': (70, 130, 180),
  'tan': (210, 180, 140),
  'thistle': (216, 191, 216),
  'tomato': (255, 99, 71),
  'turquoise': (64, 224, 208),
  'violet': (238, 130, 238),
  'wheat': (245, 222, 179),
  'whitesmoke': (245, 245, 245),
  'yellowgreen': (154, 205, 50),
};

/// Parses a Mermaid color token (CSS name, hex, rgb, rgba) into [UvColor].
UvColor? parseMermaidColor(String value) {
  final v = value.trim();
  if (v.isEmpty || v.toLowerCase() == 'transparent') return null;

  final lower = v.toLowerCase();
  final named = _cssColorNames[lower];
  if (named != null) return UvColor.rgb(named.$1, named.$2, named.$3);

  if (v.startsWith('#')) {
    final hex = v.substring(1);
    if ((hex.length == 3 || hex.length == 6 || hex.length == 8) &&
        !RegExp(r'^[0-9a-f]+$', caseSensitive: false).hasMatch(hex)) {
      return null;
    }
    if (hex.length == 3) {
      final r = int.parse(hex[0] * 2, radix: 16);
      final g = int.parse(hex[1] * 2, radix: 16);
      final b = int.parse(hex[2] * 2, radix: 16);
      return UvColor.rgb(r, g, b);
    }
    if (hex.length == 6) {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      return UvColor.rgb(r, g, b);
    }
    if (hex.length == 8) {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      return UvRgb(r, g, b, a: int.parse(hex.substring(6, 8), radix: 16));
    }
    return null;
  }

  final rgbMatch = RegExp(
    r'^rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)$',
  ).firstMatch(lower);
  if (rgbMatch != null) {
    final channels = [
      int.parse(rgbMatch.group(1)!),
      int.parse(rgbMatch.group(2)!),
      int.parse(rgbMatch.group(3)!),
    ];
    if (channels.any((channel) => channel > 255)) return null;
    return UvColor.rgb(channels[0], channels[1], channels[2]);
  }

  final rgbaMatch = RegExp(
    r'^rgba\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)$',
  ).firstMatch(lower);
  if (rgbaMatch != null) {
    final channels = [
      int.parse(rgbaMatch.group(1)!),
      int.parse(rgbaMatch.group(2)!),
      int.parse(rgbaMatch.group(3)!),
    ];
    final alpha = double.tryParse(rgbaMatch.group(4)!);
    if (channels.any((channel) => channel > 255) ||
        alpha == null ||
        alpha < 0 ||
        alpha > 1) {
      return null;
    }
    return UvRgb(
      channels[0],
      channels[1],
      channels[2],
      a: (alpha * 255).round(),
    );
  }

  return null;
}

// ─── Enums with UV style backing ──────────────────────────────────────────

/// Message arrow style with default UV style and arrow character.
enum SequenceMessageStyle {
  solid(defaultStyle: UvStyle(fg: UvColor.rgb(134, 225, 200))),
  dashed(defaultStyle: UvStyle(fg: UvColor.rgb(230, 177, 126)));

  const SequenceMessageStyle({required this.defaultStyle});
  final UvStyle defaultStyle;
}

/// Arrow head shape.
enum SequenceArrowHead {
  open('>'),
  cross(StatusChars.x),
  async(')');

  const SequenceArrowHead(this.char);
  final String char;
}

/// Fragment/loop/alt block kind with default style.
enum SequenceFragmentKind {
  alt(
    prefix: 'alt',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(
      fg: UvColor.rgb(154, 184, 169),
      bg: UvColor.rgb(28, 43, 36),
    ),
  ),
  elsePart(
    prefix: 'else',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(
      fg: UvColor.rgb(154, 184, 169),
      bg: UvColor.rgb(28, 43, 36),
    ),
  ),
  loop(
    prefix: '↻ loop',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(
      fg: UvColor.rgb(154, 184, 169),
      bg: UvColor.rgb(28, 43, 36),
    ),
  ),
  opt(
    prefix: 'opt',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(
      fg: UvColor.rgb(154, 184, 169),
      bg: UvColor.rgb(28, 43, 36),
    ),
  ),
  par(
    prefix: 'par',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(
      fg: UvColor.rgb(154, 184, 169),
      bg: UvColor.rgb(28, 43, 36),
    ),
  ),
  andPart(
    prefix: 'and',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(
      fg: UvColor.rgb(154, 184, 169),
      bg: UvColor.rgb(28, 43, 36),
    ),
  ),
  critical(
    prefix: 'critical',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(
      fg: UvColor.rgb(154, 184, 169),
      bg: UvColor.rgb(28, 43, 36),
    ),
  ),
  optionPart(
    prefix: 'option',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(
      fg: UvColor.rgb(154, 184, 169),
      bg: UvColor.rgb(28, 43, 36),
    ),
  ),
  breakPart(
    prefix: 'break',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(
      fg: UvColor.rgb(154, 184, 169),
      bg: UvColor.rgb(28, 43, 36),
    ),
  ),
  end;

  const SequenceFragmentKind({
    this.prefix = 'end',
    this.defaultStyle = const UvStyle(),
    this.defaultLabelStyle = const UvStyle(),
  });
  final String prefix;
  final UvStyle defaultStyle;
  final UvStyle defaultLabelStyle;
}

// ─── Data structures ──────────────────────────────────────────────────────

/// Immutable participant definition.
class SequenceParticipant {
  const SequenceParticipant({
    required this.id,
    required this.label,
    this.style,
    this.isActor = false,
  });
  final String id;
  final String label;
  final UvStyle? style;

  /// Whether Mermaid declared this participant with `actor`.
  final bool isActor;
}

/// A group/box of participants.
class SequenceParticipantGroup {
  const SequenceParticipantGroup({
    required this.label,
    required this.ids,
    this.backgroundColor,
  });
  final String label;
  final List<String> ids;
  final UvColor? backgroundColor;
}

/// A rect region wrapping messages with a background color.
class SequenceRect {
  const SequenceRect({
    required this.backgroundColor,
    this.foregroundColor,
    required this.startIndex,
    this.endIndex,
    this.depth = 0,
  });
  final UvColor backgroundColor;
  final UvColor? foregroundColor;
  final int startIndex;
  final int? endIndex;

  /// Nesting depth, used when nested regions share the same step boundaries.
  final int depth;
}

/// A message between participants.
class SequenceMessage {
  const SequenceMessage({
    required this.from,
    required this.to,
    required this.label,
    required this.style,
    this.head,
    this.number,
    this.activate,
    this.deactivate,
    this.styleOverride,
    this.bidirectional = false,
    this.reverse = false,
  });
  final String from;
  final String to;
  final String label;
  final SequenceMessageStyle style;
  final SequenceArrowHead? head;
  final int? number;
  final String? activate;
  final String? deactivate;
  final UvStyle? styleOverride;
  final bool bidirectional;
  final bool reverse;
}

/// A note displayed over participants.
class SequenceNote {
  const SequenceNote({
    required this.over,
    required this.label,
    this.position = SequenceNotePosition.over,
  });
  final List<String> over;
  final String label;

  /// Placement requested by Mermaid (`over`, `left of`, or `right of`).
  final SequenceNotePosition position;

  /// Mermaid uses `<br/>` for line breaks in notes and messages.
}

/// Placement of a sequence note.
enum SequenceNotePosition { over, left, right }

/// Activation/deactivation bar marker.
class SequenceActivation {
  const SequenceActivation({required this.participant, required this.active});
  final String participant;
  final bool active;
}

/// A fragment block (alt/else/loop/end).
class SequenceFragment {
  const SequenceFragment({
    required this.kind,
    required this.label,
    this.depth = 0,
  });
  final SequenceFragmentKind kind;
  final String label;
  final int depth;
}

/// A single step in the diagram timeline.
sealed class SequenceStep {
  const SequenceStep._();
}

final class SequenceStepMessage extends SequenceStep {
  const SequenceStepMessage(this.message) : super._();
  final SequenceMessage message;
}

final class SequenceStepNote extends SequenceStep {
  const SequenceStepNote(this.note) : super._();
  final SequenceNote note;
}

final class SequenceStepActivation extends SequenceStep {
  const SequenceStepActivation(this.activation) : super._();
  final SequenceActivation activation;
}

final class SequenceStepFragment extends SequenceStep {
  const SequenceStepFragment(this.fragment) : super._();
  final SequenceFragment fragment;
}

/// Parsed sequence diagram data.
typedef SequenceDiagram = ({
  List<SequenceParticipant> participants,
  List<SequenceMessage> messages,
  List<SequenceStep> steps,
  List<SequenceParticipantGroup> groups,
  List<SequenceRect> rects,
  Map<String, UvStyle> actorStyles,
});

/// Layout result with text lines and dimensions.
typedef LayoutResult = ({List<String> lines, int width, int height});

// ─── Theme ────────────────────────────────────────────────────────────────

/// Theming configuration for sequence diagram rendering.
///
/// Each field provides a default [UvStyle] for a visual element. The parser
/// may attach inline [UvStyle] overrides on individual elements (from Mermaid
/// `style`, `box Color`, `rect Color` syntax). During rendering the priority
/// is: parsed inline override > theme > enum default.
class SequenceDiagramTheme {
  const SequenceDiagramTheme({
    required this.participantBox,
    required this.participantLabel,
    required this.lifeline,
    required this.request,
    required this.response,
    required this.note,
    this.noteBackground,
    required this.fragment,
    required this.fragmentLabel,
    this.fragmentLabelBackground,
    required this.group,
    required this.rect,
  });

  /// Participant header box borders and lifelines.
  final UvStyle participantBox;

  /// Participant header label text.
  final UvStyle participantLabel;

  /// Vertical lifeline.
  final UvStyle lifeline;

  /// Solid arrow messages.
  final UvStyle request;

  /// Dashed arrow messages.
  final UvStyle response;

  /// Note text.
  final UvStyle note;

  /// Note background fill (optional).
  final UvStyle? noteBackground;

  /// Fragment (alt/loop) borders.
  final UvStyle fragment;

  /// Fragment label text.
  final UvStyle fragmentLabel;

  /// Fragment label background fill (optional).
  final UvStyle? fragmentLabelBackground;

  /// Group/box borders.
  final UvStyle group;

  /// Rect region fill.
  final UvStyle rect;

  /// Default dark-mode theme (opentui-inspired green/teal palette).
  static const defaultTheme = SequenceDiagramTheme(
    participantBox: UvStyle(fg: UvColor.rgb(111, 138, 126)),
    participantLabel: UvStyle(fg: UvColor.rgb(228, 239, 232)),
    lifeline: UvStyle(fg: UvColor.rgb(111, 138, 126)),
    request: UvStyle(fg: UvColor.rgb(134, 225, 200)),
    response: UvStyle(fg: UvColor.rgb(230, 177, 126)),
    note: UvStyle(fg: UvColor.rgb(215, 229, 221), bg: UvColor.rgb(36, 56, 47)),
    fragment: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    fragmentLabel: UvStyle(
      fg: UvColor.rgb(154, 184, 169),
      bg: UvColor.rgb(28, 43, 36),
    ),
    group: UvStyle(fg: UvColor.rgb(76, 99, 89)),
    rect: UvStyle(fg: UvColor.rgb(180, 180, 180), bg: UvColor.rgb(40, 40, 40)),
  );
}

// ─── Parsing ──────────────────────────────────────────────────────────────

final _messageRe = RegExp(
  r'^(.+?)\s*(<<-->>|<<->>|-->>|->>|--x|-x|--\)|-\)|->\)|<->>|<->|<-->>|<-->|-->|->)([+-]?)\s*(.+?)\s*:\s*(.*)$',
);
final _noteRe = RegExp(
  r'^note\s+(right|left|over)\s+(.+?)\s*:\s*(.*)$',
  caseSensitive: false,
);
final _participantRe = RegExp(
  r'^(?:participant|actor)\s+(\S+)(?:\s+as\s+(.+))?$',
);
final _activationRe = RegExp(
  r'^(activate|deactivate)\s+(.+)$',
  caseSensitive: false,
);
final _boxRe = RegExp(r'^box(?:\s+(.+))?$');
final _endRe = RegExp(r'^end$', caseSensitive: false);
final _altRe = RegExp(r'^alt\s+(.+)$', caseSensitive: false);
final _elseRe = RegExp(r'^else(?:\s+(.+))?$', caseSensitive: false);
final _loopRe = RegExp(r'^loop\s+(.+)$', caseSensitive: false);
final _optRe = RegExp(r'^opt\s+(.+)$', caseSensitive: false);
final _criticalRe = RegExp(r'^critical\s+(.+)$', caseSensitive: false);
final _breakRe = RegExp(r'^break\s+(.+)?$', caseSensitive: false);
final _parRe = RegExp(r'^par\s+(.+)?$', caseSensitive: false);
final _andRe = RegExp(r'^and(?:\s+(.+))?$', caseSensitive: false);
final _optionRe = RegExp(r'^option(?:\s+(.+))?$', caseSensitive: false);
final _autonumberRe = RegExp(r'^autonumber(?:\s+(\d+)(?:\s+(\d+))?)?$');
final _rectRe = RegExp(r'^rect\s+(.+)$', caseSensitive: false);
final _styleRe = RegExp(r'^style\s+(\S+)\s+(.+)$');
final _classDefRe = RegExp(r'^classDef\s+(\S+)\s+(.+)$');

/// Returns true if the content starts with `sequenceDiagram`.
bool isSequenceDiagram(String content) {
  for (final line in content.split('\n')) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('%%')) continue;
    return t.toLowerCase() == 'sequencediagram';
  }
  return false;
}

String _stripQuotes(String value) {
  final t = value.trim();
  if ((t.startsWith('"') && t.endsWith('"')) ||
      (t.startsWith("'") && t.endsWith("'"))) {
    return t.substring(1, t.length - 1);
  }
  return t;
}

void _ensureParticipant(
  List<SequenceParticipant> participants,
  String id, {
  String? label,
  UvStyle? style,
  bool isActor = false,
}) {
  for (final p in participants) {
    if (p.id == id) return;
  }
  participants.add(
    SequenceParticipant(
      id: id,
      label: label ?? id,
      style: style,
      isActor: isActor,
    ),
  );
}

SequenceArrowHead? _arrowHeadForSyntax(String arrow) {
  if (arrow.contains('x')) return SequenceArrowHead.cross;
  if (arrow.contains(')')) return SequenceArrowHead.async;
  if (arrow.contains('>>') || arrow.contains('<<')) {
    return SequenceArrowHead.open;
  }
  return null;
}

String? _nearestFragment(List<({String type, int stepIndex})> stack) {
  return stack.isEmpty ? null : stack.last.type;
}

int _fragmentDepth(List<({String type, int stepIndex})> stack) =>
    stack.where((block) => block.type != 'box' && block.type != 'rect').length -
    1;

String _decodeMermaidText(String value) =>
    value.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

/// Parses Mermaid sequence diagram content into a [SequenceDiagram] record.
/// Returns null if content does not start with `sequenceDiagram`.
SequenceDiagram? parseSequenceDiagram(String content) {
  if (!isSequenceDiagram(content)) return null;

  final participants = <SequenceParticipant>[];
  final messages = <SequenceMessage>[];
  final steps = <SequenceStep>[];
  final groups = <SequenceParticipantGroup>[];
  final rects = <SequenceRect>[];
  final actorStyles = <String, UvStyle>{};

  final blockStack = <({String type, int stepIndex})>[];
  final groupStack = <List<String>>[];
  final rectStack = <({int stepIndex, UvColor? color})>[];
  // Mermaid permits an activation to remain open until the implicit end of
  // the sequence; only deactivations need a matching active bar.
  final activationCounts = <String, int>{};

  int? nextMessageNumber;
  var messageNumberIncrement = 1;

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty ||
        line.startsWith('%%') ||
        line.toLowerCase() == 'sequencediagram') {
      continue;
    }

    // autonumber
    var m = _autonumberRe.firstMatch(line);
    if (m != null) {
      nextMessageNumber = int.tryParse(m.group(1) ?? '1') ?? 1;
      messageNumberIncrement = int.tryParse(m.group(2) ?? '1') ?? 1;
      continue;
    }

    // style
    m = _styleRe.firstMatch(line);
    if (m != null) {
      final actorId = _stripQuotes(m.group(1)!);
      final styleText = m.group(2)!.trim();
      final style = _parseStyleDeclaration(styleText);
      if (style != null) actorStyles[actorId] = style;
      continue;
    }

    // classDef (parse but ignore for now, just record)
    m = _classDefRe.firstMatch(line);
    if (m != null) {
      final name = m.group(1)!;
      final styleText = m.group(2)!.trim();
      final style = _parseStyleDeclaration(styleText);
      if (style != null) actorStyles['classDef:$name'] = style;
      continue;
    }

    // box
    m = _boxRe.firstMatch(line);
    if (m != null) {
      final (color, label) = _parseBoxContent(m.group(1));
      final ids = <String>[];
      groups.add(
        SequenceParticipantGroup(
          label: label,
          ids: ids,
          backgroundColor: color,
        ),
      );
      groupStack.add(ids);
      blockStack.add((type: 'box', stepIndex: steps.length));
      continue;
    }

    // rect
    m = _rectRe.firstMatch(line);
    if (m != null) {
      final colorToken = m.group(1)!.trim();
      final color = parseMermaidColor(colorToken);
      if (color == null && colorToken.toLowerCase() != 'transparent') {
        throw FormatException('Invalid rect color: $colorToken');
      }
      rectStack.add((stepIndex: steps.length, color: color));
      blockStack.add((type: 'rect', stepIndex: steps.length));
      continue;
    }

    // participant
    m = _participantRe.firstMatch(line);
    if (m != null) {
      final id = _stripQuotes(m.group(1)!);
      if (id.contains('@{')) {
        throw const FormatException(
          'Participant JSON configuration is not supported',
        );
      }
      final label = _decodeMermaidText(_stripQuotes(m.group(2) ?? id));
      final existingStyle = actorStyles[id];
      _ensureParticipant(
        participants,
        id,
        label: label,
        style: existingStyle,
        isActor: line.toLowerCase().startsWith('actor '),
      );
      if (groupStack.isNotEmpty && !groupStack.last.contains(id)) {
        groupStack.last.add(id);
      }
      continue;
    }

    // note
    m = _noteRe.firstMatch(line);
    if (m != null) {
      final side = m.group(1)!.toLowerCase();
      final over = _parseNoteTarget(side, m.group(2)!);
      final label = _decodeMermaidText(_stripQuotes(m.group(3)!));
      for (final p in over) {
        _ensureParticipant(participants, p);
      }
      steps.add(
        SequenceStepNote(
          SequenceNote(
            over: over,
            label: label,
            position: switch (side) {
              'left' => SequenceNotePosition.left,
              'right' => SequenceNotePosition.right,
              _ => SequenceNotePosition.over,
            },
          ),
        ),
      );
      continue;
    }

    // activation
    m = _activationRe.firstMatch(line);
    if (m != null) {
      final participant = _stripQuotes(m.group(2)!);
      _ensureParticipant(participants, participant);
      final active = m.group(1)!.toLowerCase() == 'activate';
      final count = activationCounts[participant] ?? 0;
      if (!active && count == 0) {
        throw FormatException(
          'Cannot deactivate inactive participant: $participant',
        );
      }
      activationCounts[participant] = active ? count + 1 : count - 1;
      steps.add(
        SequenceStepActivation(
          SequenceActivation(participant: participant, active: active),
        ),
      );
      continue;
    }

    // alt
    m = _altRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'alt', stepIndex: steps.length));
      steps.add(
        SequenceStepFragment(
          SequenceFragment(
            kind: SequenceFragmentKind.alt,
            label: _decodeMermaidText(_stripQuotes(m.group(1)!)),
            depth: _fragmentDepth(blockStack),
          ),
        ),
      );
      continue;
    }

    // Optional block.
    m = _optRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'opt', stepIndex: steps.length));
      steps.add(
        SequenceStepFragment(
          SequenceFragment(
            kind: SequenceFragmentKind.opt,
            label: _decodeMermaidText(_stripQuotes(m.group(1)!)),
            depth: _fragmentDepth(blockStack),
          ),
        ),
      );
      continue;
    }

    // loop
    m = _loopRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'loop', stepIndex: steps.length));
      steps.add(
        SequenceStepFragment(
          SequenceFragment(
            kind: SequenceFragmentKind.loop,
            label: _decodeMermaidText(_stripQuotes(m.group(1)!)),
            depth: _fragmentDepth(blockStack),
          ),
        ),
      );
      continue;
    }

    // Critical block.
    m = _criticalRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'critical', stepIndex: steps.length));
      steps.add(
        SequenceStepFragment(
          SequenceFragment(
            kind: SequenceFragmentKind.critical,
            label: _decodeMermaidText(_stripQuotes(m.group(1)!)),
            depth: _fragmentDepth(blockStack),
          ),
        ),
      );
      continue;
    }

    // Parallel block.
    m = _parRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'par', stepIndex: steps.length));
      steps.add(
        SequenceStepFragment(
          SequenceFragment(
            kind: SequenceFragmentKind.par,
            label: _decodeMermaidText(_stripQuotes(m.group(1)!)),
            depth: _fragmentDepth(blockStack),
          ),
        ),
      );
      continue;
    }

    // Break branch.
    m = _breakRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'break', stepIndex: steps.length));
      steps.add(
        SequenceStepFragment(
          SequenceFragment(
            kind: SequenceFragmentKind.breakPart,
            label: _decodeMermaidText(_stripQuotes(m.group(1)!)),
            depth: _fragmentDepth(blockStack),
          ),
        ),
      );
      continue;
    }

    // else
    m = _elseRe.firstMatch(line);
    if (m != null) {
      if (_nearestFragment(blockStack) != 'alt') {
        throw FormatException('else is only valid inside an alt block');
      }
      steps.add(
        SequenceStepFragment(
          SequenceFragment(
            kind: SequenceFragmentKind.elsePart,
            label: _decodeMermaidText(_stripQuotes(m.group(1) ?? '')),
          ),
        ),
      );
      continue;
    }

    // and (for par)
    m = _andRe.firstMatch(line);
    if (m != null) {
      if (_nearestFragment(blockStack) != 'par') {
        throw FormatException('and is only valid inside a par block');
      }
      steps.add(
        SequenceStepFragment(
          SequenceFragment(
            kind: SequenceFragmentKind.andPart,
            label: _decodeMermaidText(_stripQuotes(m.group(1) ?? '')),
          ),
        ),
      );
      continue;
    }

    // option (for critical)
    m = _optionRe.firstMatch(line);
    if (m != null) {
      if (_nearestFragment(blockStack) != 'critical') {
        throw FormatException('option is only valid inside a critical block');
      }
      steps.add(
        SequenceStepFragment(
          SequenceFragment(
            kind: SequenceFragmentKind.optionPart,
            label: _decodeMermaidText(_stripQuotes(m.group(1) ?? '')),
          ),
        ),
      );
      continue;
    }

    // end
    if (_endRe.hasMatch(line)) {
      final block = blockStack.isEmpty ? null : blockStack.removeLast();
      if (block == null) {
        throw FormatException('Unexpected end without an open block');
      }
      if (block.type == 'box') {
        groupStack.removeLast();
        continue;
      }
      if (block.type == 'rect') {
        final rect = rectStack.isEmpty
            ? (stepIndex: 0, color: null)
            : rectStack.removeLast();
        rects.add(
          SequenceRect(
            backgroundColor: rect.color ?? const UvRgb(0, 0, 0, a: 0),
            startIndex: rect.stepIndex,
            endIndex: steps.length,
            depth: rectStack.length,
          ),
        );
        continue;
      }
      final kind = switch (block.type) {
        'alt' || 'opt' || 'critical' || 'par' => SequenceFragmentKind.end,
        'loop' => SequenceFragmentKind.end,
        _ => SequenceFragmentKind.end,
      };
      steps.add(
        SequenceStepFragment(SequenceFragment(kind: kind, label: block.type)),
      );
      continue;
    }

    // message
    m = _messageRe.firstMatch(line);
    if (m != null) {
      final from = _stripQuotes(m.group(1)!);
      final arrow = m.group(2)!;
      final activation = m.group(3)!;
      final to = _stripQuotes(m.group(4)!);
      if (from.endsWith('()') || to.startsWith('()')) {
        throw const FormatException(
          'Central lifeline connections are not supported',
        );
      }
      final label = _decodeMermaidText(_stripQuotes(m.group(5)!));

      _ensureParticipant(participants, from);
      _ensureParticipant(participants, to);
      if (groupStack.isNotEmpty) {
        if (!groupStack.last.contains(from)) groupStack.last.add(from);
        if (!groupStack.last.contains(to)) groupStack.last.add(to);
      }

      final style = arrow.contains('--')
          ? SequenceMessageStyle.dashed
          : SequenceMessageStyle.solid;
      final head = _arrowHeadForSyntax(arrow);
      if (activation.contains('+')) {
        activationCounts[to] = (activationCounts[to] ?? 0) + 1;
      } else if (activation.contains('-')) {
        final count = activationCounts[from] ?? 0;
        if (count == 0) {
          throw FormatException(
            'Cannot deactivate inactive participant: $from',
          );
        }
        activationCounts[from] = count - 1;
      }

      final msg = SequenceMessage(
        from: from,
        to: to,
        label: label,
        style: style,
        head: head,
        number: nextMessageNumber,
        activate: activation.contains('+') ? to : null,
        deactivate: activation.contains('-') ? from : null,
        styleOverride: actorStyles[from] ?? actorStyles[to],
        bidirectional: arrow.startsWith('<'),
        reverse: arrow.startsWith('<') && !arrow.startsWith('<->'),
      );

      messages.add(msg);
      steps.add(SequenceStepMessage(msg));

      if (nextMessageNumber != null) {
        nextMessageNumber = nextMessageNumber + messageNumberIncrement;
      }
      continue;
    }

    if (RegExp(r'^(?:create|destroy)\b', caseSensitive: false).hasMatch(line)) {
      throw FormatException(
        'create/destroy participant lifecycles are not supported yet',
      );
    }
    // Do not silently discard syntax: a typo in a diagram must be visible to
    // callers rather than producing a convincing but incomplete picture.
    throw FormatException('Unsupported sequence diagram syntax: $line');
  }

  if (blockStack.isNotEmpty) {
    throw FormatException(
      'Unclosed sequence diagram block: ${blockStack.last.type}',
    );
  }

  return (
    participants: participants,
    messages: messages,
    steps: steps,
    groups: groups,
    rects: rects,
    actorStyles: actorStyles,
  );
}

List<String> _parseNoteTarget(String side, String participants) {
  // For 'right of X' or 'left of X', strip the 'of ' prefix
  String cleaned = participants.trim();
  if ((side.toLowerCase() == 'right' || side.toLowerCase() == 'left') &&
      cleaned.toLowerCase().startsWith('of ')) {
    cleaned = cleaned.substring(3).trim();
  }
  final list = cleaned
      .split(',')
      .map((p) => _stripQuotes(p.trim()))
      .where((p) => p.isNotEmpty)
      .toList();
  if (list.isEmpty) {
    throw FormatException('Note must have at least one participant target');
  }
  return list;
}

(UvColor? color, String label) _parseBoxContent(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return (null, '');
  if (RegExp(r'^hsla?\s*\(', caseSensitive: false).hasMatch(text)) {
    throw const FormatException('HSL box colors are not supported');
  }
  String? token;
  var rest = '';
  final function = RegExp(
    r'^(rgba?|hsla?)\s*\([^)]*\)',
    caseSensitive: false,
  ).firstMatch(text);
  if (function != null) {
    token = function.group(0);
    rest = text.substring(function.end).trim();
  } else {
    final first = text.split(RegExp(r'\s+')).first;
    if (first.startsWith('#') ||
        first.toLowerCase() == 'transparent' ||
        _cssColorNames.containsKey(first.toLowerCase())) {
      token = first;
      rest = text.substring(first.length).trim();
    }
  }
  if (token == null) return (null, _stripQuotes(text));
  final color = parseMermaidColor(token);
  if (color == null && token.toLowerCase() != 'transparent') {
    throw FormatException('Invalid box color: $token');
  }
  return (color, _stripQuotes(rest));
}

UvStyle? _parseStyleDeclaration(String text) {
  // Parse `fill:#xxx,stroke:#yyy` style declarations
  UvColor? fill;
  UvColor? stroke;

  for (final part in text.split(',')) {
    final trimmed = part.trim();
    if (trimmed.startsWith('fill:')) {
      fill = parseMermaidColor(trimmed.substring(5).trim());
    } else if (trimmed.startsWith('stroke:')) {
      stroke = parseMermaidColor(trimmed.substring(7).trim());
    }
  }

  if (fill == null && stroke == null) return null;
  return UvStyle(fg: stroke, bg: fill);
}

// ─── Layout & Rendering ───────────────────────────────────────────────────

const _defaultMinGap = 18;
const _noteHPadding = 1;

int _stringWidth(String s) {
  var w = 0;
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    w += c > 127 ? 2 : 1;
  }
  return w;
}

int _participantWidth(String label) =>
    math.max(5, _labelWidth(_messageLabelLines(label)) + 4);

String _noteLabelText(String label) =>
    '${' ' * _noteHPadding}$label${' ' * _noteHPadding}';

String _messageLabelText(SequenceMessage m) =>
    m.number == null ? m.label : '${m.number}. ${m.label}';

List<String> _messageLabelLines(String label) {
  final lines = label.split('\n').map((l) => l.trimRight()).toList();
  return lines.isEmpty ? [''] : lines;
}

int _labelWidth(List<String> lines) {
  var w = 0;
  for (final l in lines) {
    w = math.max(w, _stringWidth(l));
  }
  return w;
}

int _messageWidth(SequenceMessage m) =>
    _labelWidth(_messageLabelLines(_messageLabelText(m)));

int _diagramWidth(
  List<SequenceParticipant> participants,
  List<SequenceMessage> messages,
  List<int> centers,
  Map<String, int> idx,
) {
  var maxX = 1;
  for (var i = 0; i < participants.length; i++) {
    final half = _participantWidth(participants[i].label) ~/ 2;
    maxX = math.max(maxX, centers[i] + half + 1);
  }
  for (final msg in messages) {
    final fi = idx[msg.from] ?? -1;
    final ti = idx[msg.to] ?? -1;
    if (fi < 0 || ti < 0) continue;
    if (fi == ti) {
      maxX = math.max(maxX, centers[fi] + _selfMessageWidth(msg) + 1);
    } else {
      maxX = math.max(maxX, math.max(centers[fi], centers[ti]) + 2);
    }
  }
  return maxX + 2;
}

int _selfMessageWidth(SequenceMessage m) =>
    math.max(10, _labelWidth(_messageLabelLines(_messageLabelText(m))) + 4);

int _stepHeight(SequenceStep step) {
  return switch (step) {
    SequenceStepNote(:final note) => 2 + _messageLabelLines(note.label).length,
    SequenceStepActivation() => 0,
    SequenceStepFragment(:final fragment) => math.max(
      2,
      _messageLabelLines(fragment.label).length + 1,
    ),
    SequenceStepMessage(:final message) =>
      _messageLabelLines(_messageLabelText(message)).length +
          (message.from == message.to ? 3 : 2),
  };
}

int _headerHeight(List<SequenceParticipant> participants) {
  var labelLines = 1;
  var actor = false;
  for (final participant in participants) {
    labelLines = math.max(
      labelLines,
      _messageLabelLines(participant.label).length,
    );
    actor = actor || participant.isActor;
  }
  return math.max(4, labelLines + 3 + (actor ? 1 : 0));
}

({int left, int width})? _noteExtent(
  SequenceNote note,
  List<int> centers,
  Map<String, int> indices,
) {
  final targets = [
    for (final id in note.over)
      if (indices.containsKey(id)) centers[indices[id]!],
  ];
  if (targets.isEmpty) return null;
  final left = targets.reduce(math.min);
  final right = targets.reduce(math.max);
  final width = _labelWidth(_messageLabelLines(note.label)) + _noteHPadding * 2;
  return (
    left: switch (note.position) {
      SequenceNotePosition.left => left - width - 2,
      SequenceNotePosition.right => right + 2,
      SequenceNotePosition.over => (left + right) ~/ 2 - width ~/ 2,
    },
    width: width,
  );
}

({int left, int right, int last})? _groupExtent(
  SequenceParticipantGroup group,
  List<SequenceParticipant> participants,
  List<int> centers,
  Map<String, int> indices,
) {
  final members = [
    for (final id in group.ids)
      if (indices.containsKey(id)) indices[id]!,
  ];
  if (members.isEmpty) return null;
  final first = members.reduce(math.min);
  final last = members.reduce(math.max);
  final left =
      centers[first] - _participantWidth(participants[first].label) ~/ 2;
  final right = math.max(
    centers[last] + _participantWidth(participants[last].label) ~/ 2,
    left + _labelWidth(_messageLabelLines(group.label)) + 4,
  );
  return (left: left, right: right, last: last);
}

/// Shared measurement for both the Canvas and string rendering paths.
({
  Map<String, int> indices,
  List<int> centers,
  int width,
  int height,
  int headerHeight,
})
_sequenceGeometry(SequenceDiagram diagram, SequenceDiagramOptions? options) {
  final indices = <String, int>{
    for (var i = 0; i < diagram.participants.length; i++)
      diagram.participants[i].id: i,
  };
  final centers = _resolveCenters(
    diagram.participants,
    diagram.messages,
    indices,
    options?.minParticipantGap ?? _defaultMinGap,
  );
  for (final group in diagram.groups) {
    final extent = _groupExtent(group, diagram.participants, centers, indices);
    if (extent == null) continue;
    final headerRight =
        centers[extent.last] +
        _participantWidth(diagram.participants[extent.last].label) ~/ 2;
    final expansion = math.max(0, extent.right - headerRight);
    for (var i = extent.last + 1; i < centers.length; i++) {
      centers[i] += expansion;
    }
  }
  var minLeft = 0;
  var gutter = 0;
  for (final step in diagram.steps) {
    if (step case SequenceStepNote(:final note)) {
      final extent = _noteExtent(note, centers, indices);
      if (extent != null) minLeft = math.min(minLeft, extent.left);
    } else if (step case SequenceStepFragment(:final fragment)) {
      gutter = math.max(gutter, fragment.depth + 1);
    }
  }
  final shift = -minLeft + gutter;
  for (var i = 0; i < centers.length; i++) {
    centers[i] += shift;
  }
  var width =
      _diagramWidth(diagram.participants, diagram.messages, centers, indices) +
      gutter;
  for (final group in diagram.groups) {
    final extent = _groupExtent(group, diagram.participants, centers, indices);
    if (extent != null) width = math.max(width, extent.right + gutter + 2);
  }
  for (final step in diagram.steps) {
    if (step case SequenceStepNote(:final note)) {
      final extent = _noteExtent(note, centers, indices);
      if (extent != null) {
        width = math.max(width, extent.left + extent.width + gutter + 2);
      }
    } else if (step case SequenceStepFragment(:final fragment)) {
      width = math.max(
        width,
        _labelWidth(_messageLabelLines(fragment.label)) +
            fragment.kind.prefix.length +
            6 +
            2 * fragment.depth,
      );
    }
  }
  final headerHeight = _headerHeight(diagram.participants);
  final height = diagram.steps.fold<int>(
    headerHeight,
    (height, step) => height + _stepHeight(step),
  );
  return (
    indices: indices,
    centers: centers,
    width: width,
    height: height,
    headerHeight: headerHeight,
  );
}

List<int> _resolveCenters(
  List<SequenceParticipant> participants,
  List<SequenceMessage> messages,
  Map<String, int> idx,
  int minGap,
) {
  if (participants.isEmpty) return [];
  final gaps = List<int>.filled(participants.length - 1, 0);
  for (var i = 0; i < participants.length - 1; i++) {
    gaps[i] = math.max(
      minGap,
      _participantWidth(participants[i].label) ~/ 2 +
          _participantWidth(participants[i + 1].label) ~/ 2 +
          2,
    );
  }
  for (final msg in messages) {
    final fi = idx[msg.from] ?? -1;
    final ti = idx[msg.to] ?? -1;
    if (fi == ti && fi >= 0 && fi < participants.length - 1) {
      gaps[fi] = math.max(
        gaps[fi],
        _selfMessageWidth(msg) +
            _stringWidth(participants[fi + 1].label) ~/ 2 +
            2,
      );
    } else if (fi >= 0 && ti >= 0 && (fi - ti).abs() == 1) {
      gaps[math.min(fi, ti)] = math.max(
        gaps[math.min(fi, ti)],
        _messageWidth(msg) + 2,
      );
    }
  }
  final centers = List<int>.filled(participants.length, 0);
  centers[0] = math.max(1, _participantWidth(participants[0].label) ~/ 2);
  for (var i = 1; i < participants.length; i++) {
    centers[i] = centers[i - 1] + gaps[i - 1];
  }
  return centers;
}

/// Renders a parsed sequence diagram onto a UV [Canvas].
void drawSequenceDiagram(
  Canvas canvas,
  Rectangle area,
  SequenceDiagram diagram, {
  SequenceDiagramTheme theme = SequenceDiagramTheme.defaultTheme,
  SequenceDiagramOptions? options,
}) {
  if (diagram.participants.isEmpty) return;

  final participants = diagram.participants;
  final steps = diagram.steps;
  final geometry = _sequenceGeometry(diagram, options);
  final idx = geometry.indices;
  final centers = geometry.centers;

  // Calculate width
  final naturalWidth = geometry.width;
  final availableWidth = area.maxX - area.minX;
  if (naturalWidth > availableWidth) {
    _drawDiagnostic(
      canvas,
      area,
      'sequence diagram needs $naturalWidth columns; available $availableWidth',
    );
    return;
  }
  final width = naturalWidth;

  // Calculate height. Header labels may occupy several physical rows.
  final headerHeight = geometry.headerHeight;
  final h = geometry.height;
  final availableHeight = area.maxY - area.minY;
  if (h > availableHeight) {
    _drawDiagnostic(
      canvas,
      area,
      'sequence diagram needs $h rows; available $availableHeight',
    );
    return;
  }
  final height = h;
  final backgrounds =
      <({Rectangle area, UvColor color, UvColor? foreground})>[];

  // Render participant headers
  for (var i = 0; i < participants.length; i++) {
    final p = participants[i];
    final cx = centers[i];
    final hw = _participantWidth(p.label);
    final sx = cx - hw ~/ 2;

    final boxStyle = p.style ?? theme.participantBox;
    final labelStyle = p.style != null ? p.style! : theme.participantLabel;
    final labelLines = _messageLabelLines(p.label);
    if (p.isActor) {
      putCell(canvas, area.minX + cx, area.minY, '○', boxStyle);
      putText(
        canvas,
        area,
        area.minX + cx - 1,
        area.minY + 1,
        '/|\\',
        boxStyle,
      );
      putText(
        canvas,
        area,
        area.minX + cx - 1,
        area.minY + 2,
        '/ \\',
        boxStyle,
      );
      for (var line = 0; line < labelLines.length; line++) {
        putText(
          canvas,
          area,
          area.minX + cx - _stringWidth(labelLines[line]) ~/ 2,
          area.minY + 3 + line,
          labelLines[line],
          labelStyle,
        );
      }
      for (var y = 3 + labelLines.length; y < height; y++) {
        putCell(canvas, area.minX + cx, area.minY + y, '│', theme.lifeline);
      }
      continue;
    }
    final boxBottom = math.max(2, labelLines.length + 1);

    for (var x = sx; x < sx + hw; x++) {
      putCell(canvas, area.minX + x, area.minY, '─', boxStyle);
      putCell(canvas, area.minX + x, area.minY + boxBottom, '─', boxStyle);
    }
    putCell(canvas, area.minX + sx, area.minY, '┌', boxStyle);
    putCell(canvas, area.minX + sx + hw - 1, area.minY, '┐', boxStyle);
    for (var y = 1; y < boxBottom; y++) {
      putCell(canvas, area.minX + sx, area.minY + y, '│', boxStyle);
      putCell(canvas, area.minX + sx + hw - 1, area.minY + y, '│', boxStyle);
    }
    putCell(canvas, area.minX + sx, area.minY + boxBottom, '└', boxStyle);
    putCell(
      canvas,
      area.minX + sx + hw - 1,
      area.minY + boxBottom,
      '┘',
      boxStyle,
    );
    putCell(canvas, area.minX + cx, area.minY + boxBottom, '┬', boxStyle);
    for (var line = 0; line < labelLines.length; line++) {
      final labelX = cx - _stringWidth(labelLines[line]) ~/ 2;
      putText(
        canvas,
        area,
        area.minX + labelX,
        area.minY + 1 + line,
        labelLines[line],
        labelStyle,
      );
    }

    for (var y = boxBottom + 1; y < height; y++) {
      putCell(canvas, area.minX + cx, area.minY + y, '│', theme.lifeline);
    }
  }

  // Mermaid `box` groups are part of the diagram, not parser-only metadata.
  for (final group in diagram.groups) {
    final extent = _groupExtent(group, participants, centers, idx);
    if (extent == null || height <= headerHeight - 1) continue;
    final left = extent.left;
    final right = extent.right;
    final groupStyle = theme.group;
    if (group.backgroundColor != null) {
      backgrounds.add((
        area: rect(area.minX + left, area.minY, right - left + 1, height),
        color: group.backgroundColor!,
        foreground: null,
      ));
    }
    for (var x = left; x <= right; x++) {
      putCell(
        canvas,
        area.minX + x,
        area.minY + headerHeight - 1,
        '─',
        groupStyle,
      );
    }
    putCell(
      canvas,
      area.minX + left,
      area.minY + headerHeight - 1,
      '┌',
      groupStyle,
    );
    putCell(
      canvas,
      area.minX + right,
      area.minY + headerHeight - 1,
      '┐',
      groupStyle,
    );
    for (var y = headerHeight; y < height - 1; y++) {
      putCell(canvas, area.minX + left, area.minY + y, '│', groupStyle);
      putCell(canvas, area.minX + right, area.minY + y, '│', groupStyle);
    }
    for (var x = left + 1; x < right; x++) {
      putCell(canvas, area.minX + x, area.minY + height - 1, '─', groupStyle);
    }
    putCell(canvas, area.minX + left, area.minY + height - 1, '└', groupStyle);
    putCell(canvas, area.minX + right, area.minY + height - 1, '┘', groupStyle);
    if (group.label.isNotEmpty) {
      putText(
        canvas,
        area,
        area.minX + left + 2,
        area.minY + headerHeight - 1,
        ' ${group.label} ',
        groupStyle,
      );
    }
  }

  // A rect is a background layer, not a second drawing pass.  In particular,
  // never replace an arrow, label, or lifeline with a blank cell merely to
  // paint its background.
  final regions = diagram.rects.toList()
    ..sort((a, b) {
      final startOrder = a.startIndex.compareTo(b.startIndex);
      if (startOrder != 0) return startOrder;
      final endOrder = (b.endIndex ?? steps.length).compareTo(
        a.endIndex ?? steps.length,
      );
      return endOrder != 0 ? endOrder : a.depth.compareTo(b.depth);
    });
  for (final region in regions) {
    var top = headerHeight;
    var bottom = top;
    for (var i = 0; i < steps.length; i++) {
      if (i < region.startIndex) {
        top += _stepHeight(steps[i]);
      }
      if (i < (region.endIndex ?? steps.length)) {
        bottom += _stepHeight(steps[i]);
      }
    }
    backgrounds.add((
      area: rect(area.minX, area.minY + top, width, math.max(0, bottom - top)),
      color: region.backgroundColor,
      foreground: region.foregroundColor,
    ));
  }

  // Fragments are regions, not unrelated header lines. Pair starts and ends
  // here; because source order is preserved this also handles nesting.
  final fragmentStack = <({int y, SequenceFragment fragment})>[];
  var regionY = headerHeight;
  for (final step in steps) {
    if (step case SequenceStepFragment(:final fragment)) {
      if (fragment.kind == SequenceFragmentKind.end) {
        if (fragmentStack.isNotEmpty) {
          final open = fragmentStack.removeLast();
          _drawFragmentRegion(
            canvas,
            area,
            open.y,
            regionY + 1,
            open.fragment,
            theme,
            width,
          );
        }
      } else if (!_isBranchKind(fragment.kind)) {
        fragmentStack.add((y: regionY, fragment: fragment));
      }
    }
    regionY += _stepHeight(step);
  }

  // Render steps
  // Resolve activations against physical rows before drawing messages.  This
  // deliberately uses arrow rows (rather than the start of a message label):
  // Mermaid's `+` starts at the initiating arrow and `-` ends at the returning
  // arrow.  A stack per participant also makes nested bars deterministic.
  final activationStacks = List.generate(participants.length, (_) => <int>[]);
  final activationIntervals =
      <({int participant, int start, int end, int depth})>[];
  var activationY = headerHeight;
  for (final step in steps) {
    if (step case SequenceStepMessage(:final message)) {
      final fi = idx[message.deactivate] ?? -1;
      final ti = idx[message.activate] ?? -1;
      final lines = _messageLabelLines(_messageLabelText(message));
      final arrowY =
          activationY + lines.length + (message.from == message.to ? 1 : 0);
      if (message.activate != null && ti >= 0) {
        final stack = activationStacks[ti];
        stack.add(arrowY);
      }
      if (message.deactivate != null && fi >= 0) {
        final stack = activationStacks[fi];
        if (stack.isNotEmpty) {
          final start = stack.removeLast();
          activationIntervals.add((
            participant: fi,
            start: start,
            end: arrowY,
            depth: stack.length,
          ));
        }
      }
      activationY += _stepHeight(step);
    } else if (step case SequenceStepActivation(:final activation)) {
      final pi = idx[activation.participant] ?? -1;
      if (pi >= 0) {
        final stack = activationStacks[pi];
        if (activation.active) {
          stack.add(activationY);
        } else if (stack.isNotEmpty) {
          final start = stack.removeLast();
          activationIntervals.add((
            participant: pi,
            start: start,
            end: activationY,
            depth: stack.length,
          ));
        }
      }
    } else {
      activationY += _stepHeight(step);
    }
  }
  for (var pi = 0; pi < activationStacks.length; pi++) {
    for (var depth = 0; depth < activationStacks[pi].length; depth++) {
      activationIntervals.add((
        participant: pi,
        start: activationStacks[pi][depth],
        end: height,
        depth: depth,
      ));
    }
  }
  for (final interval in activationIntervals) {
    final x = centers[interval.participant] + 1 + interval.depth;
    for (var row = interval.start; row < interval.end && row < height; row++) {
      if (row >= headerHeight) {
        putCell(canvas, area.minX + x, area.minY + row, '┃', theme.lifeline);
      }
    }
  }

  var stepY = headerHeight;
  for (final step in steps) {
    switch (step) {
      case SequenceStepMessage(:final message):
        _drawMessage(canvas, area, message, stepY, centers, idx, theme, width);
        stepY += _stepHeight(step);
      case SequenceStepNote(:final note):
        _drawNote(canvas, area, note, stepY, centers, idx, theme);
        stepY += _stepHeight(step);
      case SequenceStepFragment(:final fragment):
        _drawFragment(canvas, area, fragment, stepY, theme, width);
        stepY += _stepHeight(step);
      case SequenceStepActivation():
      // Activation markers are resolved into intervals above.  They do not
      // consume a row and must not overwrite the message content at this
      // coordinate.
    }
  }
  // Apply colors after foreground painting without rebuilding glyphs as
  // width-one cells or erasing the background beneath labels and arrows.
  for (final background in backgrounds) {
    _paintSequenceBackground(
      canvas,
      background.area,
      background.color,
      background.foreground,
    );
  }
}

void _paintSequenceBackground(
  Canvas canvas,
  Rectangle area,
  UvColor color,
  UvColor? foreground,
) {
  if (color is UvRgb && color.a == 0) return;
  for (var y = area.minY; y < area.maxY; y++) {
    UvStyle? originStyle;
    var originEnd = area.minX;
    for (var x = area.minX; x < area.maxX; x++) {
      final old = canvas.cellAt(x, y);
      // Replacing a continuation would split the glyph. Its origin was just
      // updated (invalidating this row), so apply the resolved background to
      // the existing continuation metadata without replacing its content.
      if (old != null && old.width == 0 && old.content.isEmpty) {
        old.style = old.style.copyWith(
          bg: x < originEnd ? originStyle?.bg : color,
          fg: foreground ?? old.style.fg,
        );
        continue;
      }
      final cell = old?.clone() ?? Cell(content: ' ');
      cell.style = cell.style.copyWith(
        bg: color,
        fg: foreground ?? cell.style.fg,
      );
      originEnd = x + cell.width;
      canvas.setCellOwned(x, y, cell);
      originStyle = canvas.cellAt(x, y)?.style;
    }
  }
}

void _drawDiagnostic(Canvas canvas, Rectangle area, String message) {
  final lines = _wrapText(message, math.max(1, area.maxX - area.minX));
  for (var i = 0; i < lines.length && area.minY + i < area.maxY; i++) {
    putText(canvas, area, area.minX, area.minY + i, lines[i], const UvStyle());
  }
}

void _drawFragmentRegion(
  Canvas canvas,
  Rectangle area,
  int top,
  int bottom,
  SequenceFragment fragment,
  SequenceDiagramTheme theme,
  int width,
) {
  if (bottom <= top || width < 2) return;
  final style = fragment.kind.defaultStyle;
  final inset = math.min(fragment.depth, math.max(0, width ~/ 4));
  final left = inset;
  final right = width - 1 - inset;
  if (right <= left) return;
  for (var y = top + 1; y < bottom; y++) {
    putCell(canvas, area.minX + left, area.minY + y, '│', style);
    putCell(canvas, area.minX + right, area.minY + y, '│', style);
  }
  for (var x = left + 1; x < right; x++) {
    putCell(canvas, area.minX + x, area.minY + bottom, '─', style);
  }
  putCell(canvas, area.minX + left, area.minY + bottom, '└', style);
  putCell(canvas, area.minX + right, area.minY + bottom, '┘', style);
}

void _drawMessage(
  Canvas canvas,
  Rectangle area,
  SequenceMessage msg,
  int y,
  List<int> centers,
  Map<String, int> idx,
  SequenceDiagramTheme theme,
  int width,
) {
  final fi = idx[msg.from] ?? -1;
  final ti = idx[msg.to] ?? -1;
  if (fi < 0 || ti < 0) return;

  final fromX = centers[fi];
  final toX = centers[ti];
  final style =
      msg.styleOverride ??
      (msg.style == SequenceMessageStyle.dashed
          ? theme.response
          : theme.request);

  if (fi == ti) {
    _drawSelfMessage(canvas, area, fromX, y, msg, style, theme);
    return;
  }

  final left = math.min(fromX, toX);
  final right = math.max(fromX, toX);
  final lines = _messageLabelLines(_messageLabelText(msg));
  final arrowY = y + lines.length;

  for (var i = 0; i < lines.length; i++) {
    putText(
      canvas,
      area,
      area.minX + left + 2,
      area.minY + y + i,
      lines[i],
      style,
    );
  }

  final head = msg.head;
  for (var x = left + 1; x < right; x++) {
    putCell(
      canvas,
      area.minX + x,
      area.minY + arrowY,
      msg.style == SequenceMessageStyle.dashed ? '┄' : '─',
      style,
    );
  }
  if (head != null) {
    final headX = msg.reverse ? fromX : toX;
    putCell(
      canvas,
      area.minX + headX,
      area.minY + arrowY,
      _arrowHeadGlyph(head, pointsRight: headX == right),
      style,
    );
    if (msg.bidirectional) {
      putCell(
        canvas,
        area.minX + (headX == right ? left : right),
        area.minY + arrowY,
        _arrowHeadGlyph(head, pointsRight: headX != right),
        style,
      );
    }
  }
}

String _arrowHeadGlyph(SequenceArrowHead head, {required bool pointsRight}) =>
    switch (head) {
      SequenceArrowHead.open => pointsRight ? '>' : '<',
      SequenceArrowHead.async => pointsRight ? ')' : '(',
      SequenceArrowHead.cross => head.char,
    };

void _drawSelfMessage(
  Canvas canvas,
  Rectangle area,
  int centerX,
  int y,
  SequenceMessage msg,
  UvStyle style,
  SequenceDiagramTheme theme,
) {
  final lines = _messageLabelLines(_messageLabelText(msg));
  final w = _selfMessageWidth(msg);
  final arrowY = y + lines.length + 1;
  final stroke = msg.style == SequenceMessageStyle.dashed ? '┄' : '─';

  putCell(canvas, area.minX + centerX, area.minY + y, '├', style);
  for (var x = centerX + 1; x < centerX + w - 1; x++) {
    putCell(canvas, area.minX + x, area.minY + y, stroke, style);
  }
  putCell(canvas, area.minX + centerX + w - 1, area.minY + y, '┐', style);

  for (var i = 0; i < lines.length; i++) {
    putCell(
      canvas,
      area.minX + centerX,
      area.minY + y + 1 + i,
      '│',
      theme.lifeline,
    );
    putText(
      canvas,
      area,
      area.minX + centerX + 2,
      area.minY + y + 1 + i,
      lines[i],
      style,
    );
    putCell(
      canvas,
      area.minX + centerX + w - 1,
      area.minY + y + 1 + i,
      '│',
      style,
    );
  }

  for (var x = centerX + 1; x < centerX + w - 1; x++) {
    putCell(canvas, area.minX + x, area.minY + arrowY, stroke, style);
  }
  final headChar = msg.head == null
      ? '│'
      : _arrowHeadGlyph(msg.head!, pointsRight: false);
  putCell(canvas, area.minX + centerX, area.minY + arrowY, '└', style);
  putCell(canvas, area.minX + centerX + w - 1, area.minY + arrowY, '┘', style);
  putCell(canvas, area.minX + centerX, area.minY + arrowY, headChar, style);
}

void _drawNote(
  Canvas canvas,
  Rectangle area,
  SequenceNote note,
  int y,
  List<int> centers,
  Map<String, int> idx,
  SequenceDiagramTheme theme,
) {
  final extent = _noteExtent(note, centers, idx);
  if (extent == null) return;
  final lines = _messageLabelLines(note.label);

  for (var i = 0; i < lines.length; i++) {
    putText(
      canvas,
      area,
      area.minX + extent.left,
      area.minY + y + 1 + i,
      _noteLabelText(lines[i]),
      theme.note,
    );
  }
}

void _drawFragment(
  Canvas canvas,
  Rectangle area,
  SequenceFragment frag,
  int y,
  SequenceDiagramTheme theme,
  int width,
) {
  if (frag.kind == SequenceFragmentKind.end) return;
  final labels = _messageLabelLines(
    '${frag.kind.prefix}${frag.label.isNotEmpty ? ': ${frag.label}' : ''}',
  );
  final borderStyle = frag.kind.defaultStyle;
  final inset = math.min(frag.depth, math.max(0, width ~/ 4));
  final left = inset;
  final right = width - 1 - inset;
  if (right <= left) return;

  putCell(canvas, area.minX + left, area.minY + y, '├', borderStyle);
  for (var x = left + 1; x < right; x++) {
    putCell(
      canvas,
      area.minX + x,
      area.minY + y,
      _isBranchKind(frag.kind) ? '┄' : '─',
      borderStyle,
    );
  }
  putCell(canvas, area.minX + right, area.minY + y, '┤', borderStyle);
  for (var i = 0; i < labels.length; i++) {
    putText(
      canvas,
      area,
      area.minX + left + 2,
      area.minY + y + i,
      ' ${labels[i]} ',
      theme.fragmentLabel,
    );
  }
}

bool _isBranchKind(SequenceFragmentKind kind) =>
    kind == SequenceFragmentKind.elsePart ||
    kind == SequenceFragmentKind.andPart ||
    kind == SequenceFragmentKind.optionPart;

/// Convenience: renders a Mermaid sequence diagram string to text.
String renderSequenceDiagram(
  String content, {
  SequenceDiagramOptions? options,
  SequenceDiagramTheme? theme,
  int? maxWidth,
}) {
  final diagram = parseSequenceDiagram(content);
  if (diagram == null || diagram.participants.isEmpty) return '';

  SequenceDiagram renderedDiagram = diagram;
  SequenceDiagramOptions? layoutOptions = options;
  if (maxWidth != null) {
    final fitWidth = math.max(1, maxWidth);
    layoutOptions = SequenceDiagramOptions(
      minParticipantGap: options?.minParticipantGap ?? 1,
    );
    renderedDiagram = _fitSequenceDiagramToWidth(
      diagram,
      fitWidth,
      layoutOptions,
    );
    final layout = layoutSequenceDiagram(
      renderedDiagram,
      options: layoutOptions,
    );
    if (layout.width <= maxWidth) {
      _checkSequenceCanvasSize(layout.width, layout.height);
      final canvas = Canvas(layout.width, layout.height);
      try {
        drawSequenceDiagram(
          canvas,
          rect(0, 0, layout.width, layout.height),
          renderedDiagram,
          theme: theme ?? SequenceDiagramTheme.defaultTheme,
          options: layoutOptions,
        );
        return canvas.render();
      } finally {
        canvas.dispose();
      }
    }
    return _sequenceDiagnostic(
      'sequence diagram needs ${layout.width} columns; available $maxWidth',
      maxWidth,
    );
  }
  final layout = layoutSequenceDiagram(renderedDiagram, options: layoutOptions);
  _checkSequenceCanvasSize(layout.width, layout.height);
  final canvas = Canvas(layout.width, layout.height);
  try {
    final resolvedTheme = theme ?? SequenceDiagramTheme.defaultTheme;
    drawSequenceDiagram(
      canvas,
      rect(0, 0, layout.width, layout.height),
      renderedDiagram,
      theme: resolvedTheme,
      options: layoutOptions,
    );
    return canvas.render();
  } finally {
    canvas.dispose();
  }
}

void _checkSequenceCanvasSize(int width, int height) {
  const maxCells = 1000000;
  if (height > 0 && width > maxCells ~/ height) {
    throw const FormatException(
      'Sequence diagram exceeds the rendering limit of 1000000 cells',
    );
  }
}

/// Renders a parsed diagram to text lines.
LayoutResult layoutSequenceDiagram(
  SequenceDiagram diagram, {
  SequenceDiagramOptions? options,
}) {
  if (diagram.participants.isEmpty) {
    return (lines: <String>[], width: 0, height: 0);
  }

  final geometry = _sequenceGeometry(diagram, options);
  return (
    lines: List.filled(geometry.height, ''),
    width: geometry.width,
    height: geometry.height,
  );
}

SequenceDiagram _fitSequenceDiagramToWidth(
  SequenceDiagram diagram,
  int maxWidth,
  SequenceDiagramOptions options,
) {
  if (_sequenceGeometry(diagram, options).width <= maxWidth) return diagram;
  var best = _wrapSequenceLabels(diagram, 1, maxWidth);
  var low = 2;
  var high = maxWidth;
  while (low <= high) {
    final budget = (low + high) ~/ 2;
    final candidate = _wrapSequenceLabels(diagram, budget, maxWidth);
    if (_sequenceGeometry(candidate, options).width <= maxWidth) {
      best = candidate;
      low = budget + 1;
    } else {
      high = budget - 1;
    }
  }
  return best;
}

SequenceDiagram _wrapSequenceLabels(
  SequenceDiagram diagram,
  int participantBudget,
  int maxWidth,
) {
  final textBudget = participantBudget;
  final participants = [
    for (final p in diagram.participants)
      SequenceParticipant(
        id: p.id,
        label: _wrapText(p.label, participantBudget).join('\n'),
        style: p.style,
        isActor: p.isActor,
      ),
  ];
  final messages = [
    for (final m in diagram.messages)
      SequenceMessage(
        from: m.from,
        to: m.to,
        label: _wrapText(m.label, textBudget).join('\n'),
        style: m.style,
        head: m.head,
        number: m.number,
        activate: m.activate,
        deactivate: m.deactivate,
        styleOverride: m.styleOverride,
        bidirectional: m.bidirectional,
        reverse: m.reverse,
      ),
  ];
  var messageIndex = 0;
  final steps = <SequenceStep>[];
  for (final step in diagram.steps) {
    switch (step) {
      case SequenceStepMessage():
        steps.add(SequenceStepMessage(messages[messageIndex++]));
      case SequenceStepNote(:final note):
        steps.add(
          SequenceStepNote(
            SequenceNote(
              over: note.over,
              label: _wrapText(note.label, textBudget).join('\n'),
              position: note.position,
            ),
          ),
        );
      case SequenceStepActivation():
        steps.add(step);
      case SequenceStepFragment(:final fragment):
        steps.add(
          SequenceStepFragment(
            SequenceFragment(
              kind: fragment.kind,
              depth: fragment.depth,
              label: _wrapText(
                fragment.label,
                math.max(
                  1,
                  maxWidth -
                      fragment.kind.prefix.length -
                      6 -
                      2 * fragment.depth,
                ),
              ).join('\n'),
            ),
          ),
        );
    }
  }
  return (
    participants: participants,
    messages: messages,
    steps: steps,
    groups: diagram.groups,
    rects: diagram.rects,
    actorStyles: diagram.actorStyles,
  );
}

String _sequenceDiagnostic(String message, int maxWidth) {
  final text = 'sequence diagram diagnostic: $message';
  return _wrapText(text, math.max(1, maxWidth)).join('\n');
}

List<String> _wrapText(String text, int width) {
  return wrapAnsiPreserving(text, math.max(1, width)).split('\n');
}

/// Rendering options.
class SequenceDiagramOptions {
  const SequenceDiagramOptions({this.minParticipantGap = _defaultMinGap});
  final int minParticipantGap;
}
