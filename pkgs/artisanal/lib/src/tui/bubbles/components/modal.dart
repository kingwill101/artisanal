/// Modal popup for TEA string views.
///
/// Centers a bordered dialog over an existing view using ANSI-aware line
/// splicing — the Bubble Tea counterpart to the widget-framework `Modal`.
/// `artisanal` must not depend on `artisanal_widgets`, so this lives here
/// instead of re-exporting that layer. Chrome is pure data ([ModalChrome]);
/// the host owns open/close state and input routing.
///
/// ```dart
/// view = renderModal(
///   composerView,
///   ['Image: shot.png', '320x240'],
///   chrome: const ModalChrome(title: 'Preview', footer: ['esc close']),
///   screenW: 80,
///   screenH: 24,
/// );
/// ```
///
/// {@category TUI}
/// {@category Components}
library;

import '../../../style/style.dart' show Style;
import 'package:ultraviolet/rendering.dart'
    show cutAnsiByCells, truncateLeftAnsiByCells;
import 'base.dart' show RenderConfig;
import 'panel.dart' show PanelComponent;

/// Pure-data modal chrome. Stored by the caller alongside domain state.
final class ModalChrome {
  const ModalChrome({
    this.title = '',
    this.footer = const <String>[],
    this.width = 0,
    this.maxHeight = 0,
    this.padding = 1,
  });

  final String title;
  final List<String> footer;

  /// Fixed box width; `0` sizes to content.
  final int width;

  /// Maximum box height including chrome; `0` means unbounded.
  final int maxHeight;
  final int padding;
}

/// Renders [body] as a centered bordered dialog over [baseView].
///
/// Lines wider than the box are cut (never wrapped); the box is clamped
/// to the screen. ANSI SGR sequences pass through width accounting.
String renderModal(
  String baseView,
  List<String> body, {
  ModalChrome chrome = const ModalChrome(),
  required int screenW,
  required int screenH,
}) {
  if (screenW < 10 || screenH < 5) return baseView;
  final padding = chrome.padding < 0 ? 0 : chrome.padding;
  var contentWidth = 0;
  for (final line in [...body, ...chrome.footer]) {
    final width = Style.visibleLength(line);
    if (width > contentWidth) contentWidth = width;
  }
  var boxWidth = chrome.width > 0
      ? chrome.width
      : contentWidth + padding * 2 + 2; // content + padding + borders
  boxWidth = boxWidth.clamp(4, screenW - 2);
  final innerWidth = boxWidth - 2;
  final usableWidth = (innerWidth - padding * 2).clamp(1, innerWidth);

  final content = <String>[
    for (final line in body) _cut(line, usableWidth),
    if (chrome.footer.isNotEmpty) ...[
      _rule(usableWidth),
      for (final line in chrome.footer) _cut(line, usableWidth),
    ],
  ];
  // Box chrome (borders, title, padding) comes from the Style-driven
  // PanelComponent — never hand-drawn here.
  var boxLines = PanelComponent(
    content: content.join('\n'),
    title: chrome.title.isEmpty ? null : chrome.title,
    padding: padding,
    width: innerWidth + 2,
    renderConfig: RenderConfig(terminalWidth: screenW),
  ).render().split('\n');
  if (chrome.maxHeight > 0 && boxLines.length > chrome.maxHeight) {
    boxLines = boxLines.sublist(0, chrome.maxHeight);
  }
  if (boxLines.length > screenH) {
    boxLines = boxLines.sublist(0, screenH);
  }
  final x = ((screenW - Style.visibleLength(boxLines.first)) ~/ 2).clamp(0, screenW);
  var y = ((screenH - boxLines.length) ~/ 2).clamp(0, screenH);
  final base = baseView.split('\n');
  while (base.length < screenH) {
    base.add('');
  }
  for (var i = 0; i < boxLines.length && y + i < base.length; i++) {
    if (y + i < 0) continue;
    base[y + i] = _overlayLine(base[y + i], boxLines[i], x, screenW);
  }
  return base.join('\n');
}

String _rule(int width) => '─' * width;

String _overlayLine(String base, String overlay, int x, int screenW) {
  if (x >= screenW) return base;
  final baseWidth = Style.visibleLength(base);
  final overlayWidth = Style.visibleLength(overlay);
  final buffer = StringBuffer();
  if (x > 0) {
    buffer.write(
      baseWidth <= x ? '$base${' ' * (x - baseWidth)}' : _cut(base, x),
    );
  }
  buffer.write(overlay);
  final endX = x + overlayWidth;
  if (baseWidth > endX) buffer.write(_drop(base, endX));
  return buffer.toString();
}

/// Prefix with exactly [width] visible cells, preserving SGR/OSC8 pen
/// state at the cut via ultraviolet's ANSI slicer.
String _cut(String text, int width) {
  if (width <= 0) return '';
  return cutAnsiByCells(text, 0, width);
}

/// Suffix after dropping [width] visible cells (pen state preserved).
String _drop(String text, int width) {
  if (width <= 0) return text;
  return truncateLeftAnsiByCells(text, width);
}
