/// Reusable command-palette presentation for string-based TEA applications.
library;

import '../../command_palette.dart';
import '../../editor_core/editor_commands.dart';
import 'modal.dart';

/// Renders a [CommandPaletteController] as a scrolling modal overlay.
///
/// Matching, selection, and the visible window live on [controller]. This
/// view owns chrome and paints the shared body leaf produced by
/// [renderCommandPaletteBody].
final class CommandPaletteOverlay {
  const CommandPaletteOverlay({
    required this.controller,
    required this.isOpen,
    this.title = 'Command Palette',
    this.footer = const ['↑/↓ select  enter run  esc close'],
    this.viewportSize = 7,
    this.width = 72,
    this.emptyLabel = 'No matching commands',
  }) : assert(viewportSize > 0),
       assert(width > 0);

  final CommandPaletteController controller;
  final bool isOpen;
  final String title;
  final List<String> footer;
  final int viewportSize;
  final int width;
  final String emptyLabel;

  /// Items currently visible in the scrolling window.
  List<CommandPaletteItem> get visibleItems =>
      controller.visibleItems(viewportSize: viewportSize);

  /// Renders the open palette over [baseView].
  String render(
    String baseView, {
    required int screenWidth,
    required int screenHeight,
  }) {
    if (!isOpen) return baseView;
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
    final items = controller.filteredItems;
    return renderCommandPaletteBody(
      query: controller.query,
      items: items,
      selectedIndex: controller.selectedIndex,
      window: controller.visibleWindow(viewportSize: viewportSize),
      emptyLabel: emptyLabel,
    );
  }
}

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

  CommandPaletteOverlay get overlay {
    palette.visibleCommands;
    return CommandPaletteOverlay(
      controller: palette.controller,
      isOpen: palette.isOpen,
      title: title,
      footer: footer,
      viewportSize: viewportSize,
      width: width,
    );
  }

  /// Commands currently visible in the scrolling window.
  List<EditorCommand<T>> get visibleWindow {
    final commands = palette.visibleCommands;
    final window = palette.visibleWindow(viewportSize: viewportSize);
    return List<EditorCommand<T>>.unmodifiable(
      commands.sublist(window.start, window.end),
    );
  }

  /// Renders the open palette over [baseView].
  String render(
    String baseView, {
    required int screenWidth,
    required int screenHeight,
  }) {
    return overlay.render(
      baseView,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }
}
