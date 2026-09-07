// Full-pipeline wire tests: model → view → fullscreen UV renderer →
// captured bytes. These prove image escapes reach the wire intact,
// which no view-string assertion can (corruption happens downstream).
import 'package:artisanal/src/terminal/terminal_base.dart';
import 'package:artisanal/src/tui/renderer.dart';
import 'package:artisanal/markdown.dart' as md;
import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

import '../../../example/tui/examples/media-composer/main.dart' as composer;

tui.KeyMsg _ctrl(int rune) =>
    tui.KeyMsg(tui.Key(tui.KeyType.runes, runes: [rune], ctrl: true));

String _renderFullscreen(String view) {
  final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
  final renderer = UltravioletTuiRenderer(
    terminal: terminal,
    options: const TuiRendererOptions(),
  );
  renderer.initialize();
  renderer.render(view);
  return terminal.output;
}

/// First Kitty *display* escape (action transmit-and-display) in [output].
/// Skips lifecycle sequences such as delete-all, which share the APC
/// shape. Returns null unless structurally complete.
String? _firstKittyDisplay(String output) {
  final esc = String.fromCharCode(0x1b);
  var from = 0;
  while (true) {
    final start = output.indexOf('${esc}_G', from);
    if (start < 0) return null;
    final end = output.indexOf('$esc${String.fromCharCode(0x5c)}', start + 3);
    if (end < 0) return null;
    final span = output.substring(start, end + 2);
    if (span.contains('a=T')) return span;
    from = end + 2;
  }
}

void main() {
  test('kitty escape reaches the wire intact', () async {
    var model = composer.MediaComposerModel.initial();
    var (next, _) = model.update(_ctrl(0x76));
    model = next as composer.MediaComposerModel;
    final id = model.elements.ofKind('image').single.id;
    (next, _) = model.update(composer.ImagePreparedMsg(id));
    model = next as composer.MediaComposerModel;
    model.protocolOverride = md.ImageProtocol.kitty;
    (next, _) = model.update(tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    model = next as composer.MediaComposerModel;
    expect(model.viewer, isNotNull);

    final bytes = _renderFullscreen(model.view());
    final escape = _firstKittyDisplay(bytes);
    expect(escape, isNotNull, reason: 'kitty escape missing on wire');
    expect(escape, contains('a=T'));
    expect(escape, contains('f=100'));
    // Payload present and substantial (2x2 demo PNG re-encoded).
    final payload = escape!.split(';').last;
    expect(payload.length, greaterThan(50));
  });

  test('halfblock pixels reach the wire as cells', () async {
    var model = composer.MediaComposerModel.initial()
      ..protocolOverride = md.ImageProtocol.halfblock;
    var (next, _) = model.update(_ctrl(0x76));
    model = next as composer.MediaComposerModel;
    final id = model.elements.ofKind('image').single.id;
    (next, _) = model.update(composer.ImagePreparedMsg(id));
    model = next as composer.MediaComposerModel;
    (next, _) = model.update(tui.KeyMsg(tui.Key(tui.KeyType.enter)));
    model = next as composer.MediaComposerModel;
    expect(model.paintProtocol, md.ImageProtocol.halfblock);

    final bytes = _renderFullscreen(model.view());
    expect(bytes, contains('▀'));
  });
}
