/// Reusable command-palette presentation for string-based TEA applications.
library;

import '../../editor_core/editor_commands.dart';
import 'modal.dart';

/// Renders an [EditorCommandPalette] as a scrolling modal overlay.
///
/// State, filtering, navigation, and execution remain in
/// [EditorCommandPalette]. This component owns presentation and guarantees that
/// the selected command remains inside the visible window.
final class CommandPaletteComponent<T> {
  const CommandPaletteComponent({
    required this.palette,
    this.title = 'Command Palette',
    this.footer = const ['↑/↓ select  enter run  esc close'],
    this.viewportSize = 7,
    this.width = 72,
  }) : assert(viewportSize > 0),
       assert(width > 0);

  final EditorCommandPalette<T> palette;
  final String title;
  final List<String> footer;
  final int viewportSize;
  final int width;

  /// Commands currently visible in the scrolling window.
  List<EditorCommand<T>> get visibleWindow {
    final commands = palette.visibleCommands;
    final (:start, :end) = _window(commands.length);
    return List<EditorCommand<T>>.unmodifiable(commands.sublist(start, end));
  }

  /// Renders the open palette over [baseView].
  String render(
    String baseView, {
    required int screenWidth,
    required int screenHeight,
  }) {
    if (!palette.isOpen) return baseView;
    return renderModal(
      baseView,
      _body(),
      chrome: ModalChrome(
        title: title,
        footer: footer,
        width: width.clamp(4, screenWidth),
        maxHeight: screenHeight,
      ),
      screenW: screenWidth,
      screenH: screenHeight,
    );
  }

  List<String> _body() {
    final commands = palette.visibleCommands;
    final (:start, :end) = _window(commands.length);
    final lines = <String>['> ${palette.query}', ''];
    for (var index = start; index < end; index++) {
      final selected = index == palette.selectedIndex;
      lines.add('${selected ? '❯' : ' '} ${commands[index].label}');
    }
    if (commands.isEmpty) lines.add('  No matching commands');
    if (commands.length > viewportSize) {
      lines.add(
        '  ${palette.selectedIndex + 1}/${commands.length}'
        '${start > 0 ? '  ↑ more' : ''}'
        '${end < commands.length ? '  ↓ more' : ''}',
      );
    }
    return lines;
  }

  ({int start, int end}) _window(int commandCount) {
    final maxStart = (commandCount - viewportSize).clamp(0, commandCount);
    final start = (palette.selectedIndex - viewportSize ~/ 2).clamp(
      0,
      maxStart,
    );
    final end = (start + viewportSize).clamp(start, commandCount);
    return (start: start, end: end);
  }
}
