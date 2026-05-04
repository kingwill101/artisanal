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
/// import 'package:artisanal/charting.dart';
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

import 'package:ultraviolet/ultraviolet.dart' show Canvas, Rectangle, UvColor, UvStyle, rect;

import 'package:artisanal/src/charting/core.dart' show putCell, putText;

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
      return UvColor.rgb(r, g, b);
    }
    return null;
  }

  final rgbMatch = RegExp(r'^rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)$').firstMatch(lower);
  if (rgbMatch != null) {
    return UvColor.rgb(
      int.parse(rgbMatch.group(1)!),
      int.parse(rgbMatch.group(2)!),
      int.parse(rgbMatch.group(3)!),
    );
  }

  final rgbaMatch = RegExp(r'^rgba\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)$').firstMatch(lower);
  if (rgbaMatch != null) {
    return UvColor.rgb(
      int.parse(rgbaMatch.group(1)!),
      int.parse(rgbaMatch.group(2)!),
      int.parse(rgbaMatch.group(3)!),
    );
  }

  return null;
}

// ─── Enums with UV style backing ──────────────────────────────────────────

/// Message arrow style with default UV style and arrow character.
enum SequenceMessageStyle {
  solid(
    defaultStyle: UvStyle(fg: UvColor.rgb(134, 225, 200)),
  ),
  dashed(
    defaultStyle: UvStyle(fg: UvColor.rgb(230, 177, 126)),
  );

  const SequenceMessageStyle({required this.defaultStyle});
  final UvStyle defaultStyle;
}

/// Arrow head shape.
enum SequenceArrowHead {
  open('>'),
  cross('✕'),
  async(')');

  const SequenceArrowHead(this.char);
  final String char;
}

/// Fragment/loop/alt block kind with default style.
enum SequenceFragmentKind {
  alt(
    prefix: 'alt',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(fg: UvColor.rgb(154, 184, 169), bg: UvColor.rgb(28, 43, 36)),
  ),
  elsePart(
    prefix: 'else',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(fg: UvColor.rgb(154, 184, 169), bg: UvColor.rgb(28, 43, 36)),
  ),
  loop(
    prefix: '↻ loop',
    defaultStyle: UvStyle(fg: UvColor.rgb(154, 184, 169)),
    defaultLabelStyle: UvStyle(fg: UvColor.rgb(154, 184, 169), bg: UvColor.rgb(28, 43, 36)),
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
  const SequenceParticipant({required this.id, required this.label, this.style});
  final String id;
  final String label;
  final UvStyle? style;
}

/// A group/box of participants.
class SequenceParticipantGroup {
  const SequenceParticipantGroup({required this.label, required this.ids, this.backgroundColor});
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
  });
  final UvColor backgroundColor;
  final UvColor? foregroundColor;
  final int startIndex;
  final int? endIndex;
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
}

/// A note displayed over participants.
class SequenceNote {
  const SequenceNote({required this.over, required this.label});
  final List<String> over;
  final String label;
}

/// Activation/deactivation bar marker.
class SequenceActivation {
  const SequenceActivation({required this.participant, required this.active});
  final String participant;
  final bool active;
}

/// A fragment block (alt/else/loop/end).
class SequenceFragment {
  const SequenceFragment({required this.kind, required this.label});
  final SequenceFragmentKind kind;
  final String label;
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
    fragmentLabel: UvStyle(fg: UvColor.rgb(154, 184, 169), bg: UvColor.rgb(28, 43, 36)),
    group: UvStyle(fg: UvColor.rgb(76, 99, 89)),
    rect: UvStyle(fg: UvColor.rgb(180, 180, 180), bg: UvColor.rgb(40, 40, 40)),
  );
}

// ─── Parsing ──────────────────────────────────────────────────────────────

final _messageRe = RegExp(r'^(.+?)\s*(-->>|->>|--x|-x|--\)|-\)|->\)|<->>|<->|<-->>|<-->|-->|->)([+-]?)\s*(.+?)\s*:\s*(.*)$');
final _noteRe = RegExp(r'^note\s+(right|left|over)\s+(.+?)\s*:\s*(.*)$', caseSensitive: false);
final _participantRe = RegExp(r'^(?:participant|actor)\s+(\S+)(?:\s+as\s+(.+))?$');
final _activationRe = RegExp(r'^(activate|deactivate)\s+(.+)$');
final _boxRe = RegExp(r'^box(?:\s+(.+))?$');
final _endRe = RegExp(r'^end$', caseSensitive: false);
final _altRe = RegExp(r'^alt\s+(.+)$');
final _elseRe = RegExp(r'^else(?:\s+(.+))?$');
final _loopRe = RegExp(r'^loop\s+(.+)$');
final _optRe = RegExp(r'^opt\s+(.+)$');
final _criticalRe = RegExp(r'^critical\s+(.+)$');
final _breakRe = RegExp(r'^break\s+(.+)?$');
final _parRe = RegExp(r'^par\s+(.+)?$');
final _andRe = RegExp(r'^and(?:\s+(.+))?$');
final _autonumberRe = RegExp(r'^autonumber(?:\s+(\d+)(?:\s+(\d+))?)?$');
final _rectRe = RegExp(r'^rect\s+(.+)$');
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
  if ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) {
    return t.substring(1, t.length - 1);
  }
  return t;
}

void _ensureParticipant(
  List<SequenceParticipant> participants,
  String id, {
  String? label,
  UvStyle? style,
}) {
  for (final p in participants) {
    if (p.id == id) return;
  }
  participants.add(SequenceParticipant(id: id, label: label ?? id, style: style));
}

SequenceArrowHead? _arrowHeadForSyntax(String arrow) {
  if (arrow.contains('x')) return SequenceArrowHead.cross;
  if (arrow.contains(')')) return SequenceArrowHead.async;
  if (arrow.contains('>')) return SequenceArrowHead.open;
  return null;
}

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
  final rectStack = <int>[]; // step index where rect started

  int? nextMessageNumber;
  var messageNumberIncrement = 1;

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('%%') || line.toLowerCase() == 'sequencediagram') continue;

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
      groups.add(SequenceParticipantGroup(label: label, ids: ids, backgroundColor: color));
      groupStack.add(ids);
      blockStack.add((type: 'box', stepIndex: steps.length));
      continue;
    }

    // rect
    m = _rectRe.firstMatch(line);
    if (m != null) {
      parseMermaidColor(m.group(1)!.trim());
      rectStack.add(steps.length);
      blockStack.add((type: 'rect', stepIndex: steps.length));
      continue;
    }

    // participant
    m = _participantRe.firstMatch(line);
    if (m != null) {
      final id = _stripQuotes(m.group(1)!);
      final label = _stripQuotes(m.group(2) ?? id);
      final existingStyle = actorStyles[id];
      _ensureParticipant(participants, id, label: label, style: existingStyle);
      if (groupStack.isNotEmpty) groupStack.last.add(id);
      continue;
    }

    // note
    m = _noteRe.firstMatch(line);
    if (m != null) {
      final over = _parseNoteTarget(m.group(1)!, m.group(2)!);
      final label = _stripQuotes(m.group(3)!);
      for (final p in over) _ensureParticipant(participants, p);
      steps.add(SequenceStepNote(SequenceNote(over: over, label: label)));
      continue;
    }

    // activation
    m = _activationRe.firstMatch(line);
    if (m != null) {
      final participant = _stripQuotes(m.group(2)!);
      _ensureParticipant(participants, participant);
      steps.add(SequenceStepActivation(
        SequenceActivation(participant: participant, active: m.group(1)!.toLowerCase() == 'activate'),
      ));
      continue;
    }

    // alt
    m = _altRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'alt', stepIndex: steps.length));
      steps.add(SequenceStepFragment(SequenceFragment(kind: SequenceFragmentKind.alt, label: _stripQuotes(m.group(1)!))));
      continue;
    }

    // opt → becomes alt with empty else
    m = _optRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'opt', stepIndex: steps.length));
      steps.add(SequenceStepFragment(SequenceFragment(kind: SequenceFragmentKind.alt, label: _stripQuotes(m.group(1)!))));
      continue;
    }

    // loop
    m = _loopRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'loop', stepIndex: steps.length));
      steps.add(SequenceStepFragment(SequenceFragment(kind: SequenceFragmentKind.loop, label: _stripQuotes(m.group(1)!))));
      continue;
    }

    // critical
    m = _criticalRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'critical', stepIndex: steps.length));
      steps.add(SequenceStepFragment(SequenceFragment(kind: SequenceFragmentKind.alt, label: _stripQuotes(m.group(1)!))));
      continue;
    }

    // par
    m = _parRe.firstMatch(line);
    if (m != null) {
      blockStack.add((type: 'par', stepIndex: steps.length));
      steps.add(SequenceStepFragment(SequenceFragment(kind: SequenceFragmentKind.alt, label: _stripQuotes(m.group(1)!))));
      continue;
    }

    // break
    m = _breakRe.firstMatch(line);
    if (m != null) {
      steps.add(SequenceStepFragment(SequenceFragment(kind: SequenceFragmentKind.elsePart, label: _stripQuotes(m.group(1)!))));
      continue;
    }

    // else
    m = _elseRe.firstMatch(line);
    if (m != null) {
      steps.add(SequenceStepFragment(SequenceFragment(kind: SequenceFragmentKind.elsePart, label: _stripQuotes(m.group(1) ?? ''))));
      continue;
    }

    // and (for par)
    m = _andRe.firstMatch(line);
    if (m != null) {
      steps.add(SequenceStepFragment(SequenceFragment(kind: SequenceFragmentKind.elsePart, label: _stripQuotes(m.group(1) ?? ''))));
      continue;
    }

    // end
    if (_endRe.hasMatch(line)) {
      final block = blockStack.isEmpty ? null : blockStack.removeLast();
      if (block == null) continue;
      if (block.type == 'box') {
        groupStack.removeLast();
        continue;
      }
      if (block.type == 'rect') {
        final startIdx = rectStack.isEmpty ? 0 : rectStack.removeLast();
        rects.add(SequenceRect(
          backgroundColor: UvColor.rgb(40, 40, 40),
          startIndex: startIdx,
          endIndex: steps.length,
        ));
        continue;
      }
      final kind = switch (block.type) {
        'alt' || 'opt' || 'critical' || 'par' => SequenceFragmentKind.end,
        'loop' => SequenceFragmentKind.end,
        _ => SequenceFragmentKind.end,
      };
      steps.add(SequenceStepFragment(SequenceFragment(kind: kind, label: block.type)));
      continue;
    }

    // message
    m = _messageRe.firstMatch(line);
    if (m != null) {
      final from = _stripQuotes(m.group(1)!);
      final arrow = m.group(2)!;
      final activation = m.group(3)!;
      final to = _stripQuotes(m.group(4)!);
      final label = _stripQuotes(m.group(5)!);

      _ensureParticipant(participants, from);
      _ensureParticipant(participants, to);
      if (groupStack.isNotEmpty) {
        groupStack.last.add(from);
        groupStack.last.add(to);
      }

      final style = arrow.contains('--') ? SequenceMessageStyle.dashed : SequenceMessageStyle.solid;
      final head = _arrowHeadForSyntax(arrow);

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
      );

      messages.add(msg);
      steps.add(SequenceStepMessage(msg));

      if (nextMessageNumber != null) {
        nextMessageNumber = nextMessageNumber + messageNumberIncrement;
      }
    }
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
  final list = cleaned.split(',').map((p) => _stripQuotes(p.trim())).where((p) => p.isNotEmpty).toList();
  return list.isEmpty ? [_stripQuotes(cleaned)] : list;
}

(UvColor? color, String label) _parseBoxContent(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return (null, '');

  // Try to extract leading color
  final color = parseMermaidColor(text);
  if (color != null) {
    // Check if there's a label after the color
    final rest = text.substring(text.indexOf(text.startsWith('#') ? '#' : text[0]) +
        (text.startsWith('rgb(') ? text.indexOf(')') + 1 : text.startsWith('rgba(') ? text.indexOf(')') + 1 : text.split(' ').first.length));
    final trimmedRest = rest.trim();
    if (trimmedRest.isEmpty) return (color, '');
    return (color, _stripQuotes(trimmedRest));
  }

  return (null, _stripQuotes(text));
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

int _participantWidth(String label) => math.max(5, _stringWidth(label) + 4);

String _noteLabelText(String label) => '${' ' * _noteHPadding}$label${' ' * _noteHPadding}';

String _messageLabelText(SequenceMessage m) => m.number == null ? m.label : '${m.number}. ${m.label}';

List<String> _messageLabelLines(String label) {
  final lines = label.split('\n').map((l) => l.trimRight()).toList();
  return lines.isEmpty ? [''] : lines;
}

int _labelWidth(List<String> lines) {
  var w = 0;
  for (final l in lines) w = math.max(w, _stringWidth(l));
  return w;
}

int _messageWidth(SequenceMessage m) => _labelWidth(_messageLabelLines(_messageLabelText(m)));

int _selfMessageWidth(SequenceMessage m) => math.max(10, _labelWidth(_messageLabelLines(_messageLabelText(m))) + 4);

int _stepHeight(SequenceStep step) {
  return switch (step) {
    SequenceStepNote() => 3,
    SequenceStepActivation() => 0,
    SequenceStepFragment() => 2,
    SequenceStepMessage(:final message) =>
      _messageLabelLines(_messageLabelText(message)).length + (message.from == message.to ? 3 : 2),
  };
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
    gaps[i] = math.max(minGap, _participantWidth(participants[i].label) ~/ 2 + _participantWidth(participants[i + 1].label) ~/ 2 + 6);
  }
  for (final msg in messages) {
    final fi = idx[msg.from] ?? -1;
    final ti = idx[msg.to] ?? -1;
    if (fi == ti && fi >= 0 && fi < participants.length - 1) {
      gaps[fi] = math.max(gaps[fi], _selfMessageWidth(msg) + _stringWidth(participants[fi + 1].label) ~/ 2 + 2);
    } else if (fi >= 0 && ti >= 0 && (fi - ti).abs() == 1) {
      gaps[math.min(fi, ti)] = math.max(gaps[math.min(fi, ti)], _messageWidth(msg) + 6);
    }
  }
  final centers = List<int>.filled(participants.length, 0);
  centers[0] = math.max(1, _participantWidth(participants[0].label) ~/ 2);
  for (var i = 1; i < participants.length; i++) centers[i] = centers[i - 1] + gaps[i - 1];
  return centers;
}

/// Renders a parsed sequence diagram onto a UV [Canvas].
void drawSequenceDiagram(
  Canvas canvas,
  Rectangle area,
  SequenceDiagram diagram, {
  SequenceDiagramTheme theme = SequenceDiagramTheme.defaultTheme,
}) {
  if (diagram.participants.isEmpty) return;

  final participants = diagram.participants;
  final messages = diagram.messages;
  final steps = diagram.steps;

  final idx = <String, int>{};
  for (var i = 0; i < participants.length; i++) idx[participants[i].id] = i;

  final centers = _resolveCenters(participants, messages, idx, _defaultMinGap);

  // Calculate width
  var maxX = 40;
  for (final msg in messages) {
    final fi = idx[msg.from] ?? -1;
    final ti = idx[msg.to] ?? -1;
    if (fi < 0 || ti < 0) continue;
    if (fi == ti) {
      maxX = math.max(maxX, centers[fi] + _selfMessageWidth(msg) + 2);
    } else {
      final left = math.min(centers[fi], centers[ti]);
      maxX = math.max(maxX, left + _messageWidth(msg) + 4);
    }
  }
  final width = math.min(maxX + 4, area.maxX - area.minX);

  // Calculate height
  var h = 6;
  for (final step in steps) h += _stepHeight(step);
  final height = math.min(h, area.maxY - area.minY);

  // Render participant headers
  for (var i = 0; i < participants.length; i++) {
    final p = participants[i];
    final cx = centers[i];
    final hw = _participantWidth(p.label);
    final sx = cx - hw ~/ 2;

    final boxStyle = p.style ?? theme.participantBox;
    final labelStyle = p.style != null ? p.style! : theme.participantLabel;

    for (var x = sx; x < sx + hw; x++) {
      putCell(canvas, area.minX + x, area.minY, '─', boxStyle);
      putCell(canvas, area.minX + x, area.minY + 2, '─', boxStyle);
    }
    putCell(canvas, area.minX + sx, area.minY, '┌', boxStyle);
    putCell(canvas, area.minX + sx + hw - 1, area.minY, '┐', boxStyle);
    putCell(canvas, area.minX + sx, area.minY + 1, '│', boxStyle);
    putCell(canvas, area.minX + sx + hw - 1, area.minY + 1, '│', boxStyle);
    putCell(canvas, area.minX + sx, area.minY + 2, '└', boxStyle);
    putCell(canvas, area.minX + sx + hw - 1, area.minY + 2, '┘', boxStyle);
    putCell(canvas, area.minX + cx, area.minY + 2, '┬', boxStyle);

    final labelX = cx - _stringWidth(p.label) ~/ 2;
    putText(canvas, area, area.minX + labelX, area.minY + 1, p.label, labelStyle);

    for (var y = 3; y < height - 1; y++) {
      putCell(canvas, area.minX + cx, area.minY + y, '│', theme.lifeline);
    }
  }

  // Render steps
  var stepY = 4;
  for (final step in steps) {
    switch (step) {
      case SequenceStepMessage(:final message):
        _drawMessage(canvas, area, message, stepY, centers, idx, theme, width);
        stepY += _stepHeight(step);
      case SequenceStepNote(:final note):
        _drawNote(canvas, area, note, stepY, centers, idx, theme);
        stepY += 3;
      case SequenceStepFragment(:final fragment):
        _drawFragment(canvas, area, fragment, stepY, theme, width);
        stepY += 2;
      case SequenceStepActivation():
        // Activation bars not rendered in ASCII output
    }
  }
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
  final style = msg.styleOverride ?? (msg.style == SequenceMessageStyle.dashed ? theme.response : theme.request);

  if (fi == ti) {
    _drawSelfMessage(canvas, area, fromX, y, msg, style, theme);
    return;
  }

  final left = math.min(fromX, toX);
  final right = math.max(fromX, toX);
  final lines = _messageLabelLines(_messageLabelText(msg));
  final arrowY = y + lines.length;

  for (var i = 0; i < lines.length; i++) {
    putText(canvas, area, area.minX + left + 2, area.minY + y + i, lines[i], style);
  }

  final headChar = msg.head?.char ?? (toX > fromX ? '▶' : '◀');
  for (var x = left + 1; x < right; x++) {
    putCell(canvas, area.minX + x, area.minY + arrowY, msg.style == SequenceMessageStyle.dashed ? '┄' : '─', style);
  }
  putCell(canvas, area.minX + right, area.minY + arrowY, headChar, style);
}

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
  final arrowY = y + lines.length;

  putCell(canvas, area.minX + centerX, area.minY + y, '├', style);
  for (var x = centerX + 1; x < centerX + w - 1; x++) {
    putCell(canvas, area.minX + x, area.minY + y, '─', style);
  }
  putCell(canvas, area.minX + centerX + w - 1, area.minY + y, '┐', style);

  for (var i = 0; i < lines.length; i++) {
    putCell(canvas, area.minX + centerX, area.minY + y + 1 + i, '│', theme.lifeline);
    putText(canvas, area, area.minX + centerX + 2, area.minY + y + 1 + i, lines[i], style);
    putCell(canvas, area.minX + centerX + w - 1, area.minY + y + 1 + i, '│', style);
  }

  for (var x = centerX + 1; x < centerX + w - 1; x++) {
    putCell(canvas, area.minX + x, area.minY + arrowY, '─', theme.response);
  }
  final headChar = msg.head?.char ?? '◀';
  putCell(canvas, area.minX + centerX, area.minY + arrowY, '└', theme.response);
  putCell(canvas, area.minX + centerX + w - 1, area.minY + arrowY, '┘', theme.response);
  putCell(canvas, area.minX + centerX, area.minY + arrowY, headChar, theme.response);
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
  final indexes = note.over.map((p) => idx[p] ?? -1).where((i) => i >= 0).toList();
  if (indexes.isEmpty) return;

  final leftX = centers[indexes.reduce(math.min)];
  final rightX = centers[indexes.reduce(math.max)];
  final cx = (leftX + rightX) ~/ 2;
  final text = _noteLabelText(note.label);
  final textWidth = _stringWidth(text);
  var tx = cx - textWidth ~/ 2;

  // Clamp to area bounds
  if (tx < 0) tx = 0;
  if (tx + textWidth > area.maxX - area.minX) {
    tx = math.max(0, area.maxX - area.minX - textWidth);
  }

  putText(canvas, area, area.minX + tx, area.minY + y + 1, text, theme.note);
}

void _drawFragment(
  Canvas canvas,
  Rectangle area,
  SequenceFragment frag,
  int y,
  SequenceDiagramTheme theme,
  int width,
) {
  final label = ' ${frag.kind.prefix}${frag.label.isNotEmpty ? ': ${frag.label}' : ''} ';
  final borderStyle = frag.kind.defaultStyle;

  putCell(canvas, area.minX, area.minY + y, '├', borderStyle);
  for (var x = 1; x < width - 1; x++) {
    putCell(canvas, area.minX + x, area.minY + y, '─', borderStyle);
  }
  putCell(canvas, area.minX + width - 1, area.minY + y, '┤', borderStyle);
  putText(canvas, area, area.minX + 2, area.minY + y, label, theme.fragmentLabel);
}

/// Convenience: renders a Mermaid sequence diagram string to text.
String renderSequenceDiagram(
  String content, {
  SequenceDiagramOptions? options,
  SequenceDiagramTheme? theme,
}) {
  final diagram = parseSequenceDiagram(content);
  if (diagram == null || diagram.participants.isEmpty) return '';

  final layout = layoutSequenceDiagram(diagram, options: options);
  final canvas = Canvas(layout.width, layout.height);
  final resolvedTheme = theme ?? SequenceDiagramTheme.defaultTheme;
  drawSequenceDiagram(canvas, rect(0, 0, layout.width, layout.height), diagram, theme: resolvedTheme);

  return canvas.render();
}

/// Renders a parsed diagram to text lines.
LayoutResult layoutSequenceDiagram(
  SequenceDiagram diagram, {
  SequenceDiagramOptions? options,
}) {
  if (diagram.participants.isEmpty) return (lines: <String>[], width: 0, height: 0);

  final participants = diagram.participants;
  final messages = diagram.messages;
  final steps = diagram.steps;
  final idx = <String, int>{};
  for (var i = 0; i < participants.length; i++) idx[participants[i].id] = i;

  final centers = _resolveCenters(participants, messages, idx, options?.minParticipantGap ?? _defaultMinGap);

  var maxX = 40;
  for (final msg in messages) {
    final fi = idx[msg.from] ?? -1;
    final ti = idx[msg.to] ?? -1;
    if (fi < 0 || ti < 0) continue;
    if (fi == ti) {
      maxX = math.max(maxX, centers[fi] + _selfMessageWidth(msg) + 2);
    } else {
      final left = math.min(centers[fi], centers[ti]);
      maxX = math.max(maxX, left + _messageWidth(msg) + 4);
    }
  }
  final width = maxX + 4;

  var h = 6;
  for (final step in steps) h += _stepHeight(step);

  return (lines: List.filled(h, ''), width: width, height: h);
}

/// Rendering options.
class SequenceDiagramOptions {
  const SequenceDiagramOptions({this.minParticipantGap = _defaultMinGap});
  final int minParticipantGap;
}
