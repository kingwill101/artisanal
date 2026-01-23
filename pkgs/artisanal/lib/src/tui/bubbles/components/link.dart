import 'dart:io' as io;

import '../../../style/color.dart';
import '../../../style/style.dart';
import 'base.dart';

/// A clickable hyperlink component (OSC 8).
///
/// ```dart
/// LinkComponent(
///   url: 'https://dart.dev',
///   text: 'Visit Dart',
/// ).render();
/// ```
class LinkComponent extends DisplayComponent {
  const LinkComponent({
    required this.url,
    this.text,
    this.id,
    this.styled = false,
    this.renderConfig = const RenderConfig(),
  });

  final String url;
  final String? text;
  final String? id;
  final bool styled;
  final RenderConfig renderConfig;

  @override
  String render() {
    final displayText = text ?? url;

    if (renderConfig.colorProfile == ColorProfile.ascii) {
      return displayText;
    }

    final params = id != null ? 'id=$id' : '';
    final linkText = '\x1B]8;$params;$url\x07$displayText\x1B]8;;\x07';

    if (styled) {
      // Apply underline and blue color
      return '\x1B[4;34m$linkText\x1B[0m';
    }

    return linkText;
  }

  /// Whether the terminal likely supports OSC 8 links.
  static bool get isSupported {
    final term = io.Platform.environment['TERM'] ?? '';
    final termProgram = io.Platform.environment['TERM_PROGRAM'] ?? '';
    final wtSession = io.Platform.environment['WT_SESSION'];
    final conemu = io.Platform.environment['ConEmuANSI'];

    if (termProgram == 'iTerm.app') return true;
    if (termProgram == 'vscode') return true;
    if (termProgram == 'Hyper') return true;
    if (termProgram == 'WezTerm') return true;
    if (wtSession != null) return true;
    if (conemu == 'ON') return true;
    if (term.contains('xterm') || term.contains('256color')) return true;

    return io.stdout.supportsAnsiEscapes;
  }
}

/// A group of related links component.
///
/// Collects links and renders them as a numbered list of footnotes.
///
/// ```dart
/// final links = LinkGroupComponent();
/// final ref1 = links.add('https://dart.dev', text: 'Dart');
/// final ref2 = links.add('https://flutter.dev', text: 'Flutter');
/// print('See $ref1 and $ref2');
/// links.renderln(context); // Renders: [1] https://dart.dev  [2] https://flutter.dev
/// ```
class LinkGroupComponent extends DisplayComponent {
  LinkGroupComponent({
    this.prefix = 'link',
    this.renderConfig = const RenderConfig(),
  });

  final String prefix;
  final RenderConfig renderConfig;
  int _counter = 0;
  final List<_LinkEntry> _links = [];

  /// Adds a link to the group and returns a reference string.
  String add(String url, {String? text, bool styled = false}) {
    final id = '$prefix-${_counter++}';
    final displayText = text ?? url;
    final refNumber = _links.length + 1;

    _links.add(_LinkEntry(url: url, text: displayText, id: id));

    if (renderConfig.colorProfile == ColorProfile.ascii) {
      return '$displayText[$refNumber]';
    }

    final params = 'id=$id';
    final linkText = '\x1B]8;$params;$url\x07$displayText\x1B]8;;\x07';

    if (styled) {
      return '\x1B[4;34m$linkText\x1B[0m';
    }

    return linkText;
  }

  /// Creates a link string without adding to the group (for inline use).
  String createLink(String url, {String? text, bool styled = false}) {
    final id = '$prefix-inline-${_counter++}';
    final displayText = text ?? url;

    if (renderConfig.colorProfile == ColorProfile.ascii) {
      return displayText;
    }

    final params = 'id=$id';
    final linkText = '\x1B]8;$params;$url\x07$displayText\x1B]8;;\x07';

    if (styled) {
      return '\x1B[4;34m$linkText\x1B[0m';
    }

    return linkText;
  }

  @override
  String render() {
    if (_links.isEmpty) return '';

    final buffer = StringBuffer();
    final dim = renderConfig.configureStyle(Style().dim());
    for (var i = 0; i < _links.length; i++) {
      final link = _links[i];
      final refNumber = i + 1;

      if (i > 0) buffer.writeln();

      if (renderConfig.colorProfile != ColorProfile.ascii) {
        final params = 'id=${link.id}';
        final linkText =
            '\x1B]8;$params;${link.url}\x07${link.url}\x1B]8;;\x07';
        buffer.write('${dim.render('[$refNumber]')} $linkText');
      } else {
        buffer.write('[$refNumber] ${link.url}');
      }
    }

    return buffer.toString();
  }

  /// Clears all collected links.
  void clear() {
    _links.clear();
    _counter = 0;
  }
}

class _LinkEntry {
  _LinkEntry({required this.url, required this.text, required this.id});

  final String url;
  final String text;
  final String id;
}
