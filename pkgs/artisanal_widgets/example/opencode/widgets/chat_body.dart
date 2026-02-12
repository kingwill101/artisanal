/// Chat body widget for the OpenCode chat UI.
///
/// Scrollable column of [MessageWidget] items with auto-scroll
/// to the latest message.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

import '../models/message.dart';
import '../theme.dart';
import 'message_widget.dart';

/// A scrollable list of chat messages.
class ChatBody extends w.StatelessWidget {
  ChatBody({
    required this.messages,
    this.scrollController,
    this.showDiffContextBackground = false,
    super.key,
  });

  final List<ChatMessage> messages;
  final w.WidgetScrollController? scrollController;
  final bool showDiffContextBackground;

  @override
  w.Widget build(w.BuildContext context) {
    if (messages.isEmpty) {
      return _buildEmptyState(context);
    }

    final controller = scrollController ?? w.WidgetScrollController();
    final estimatedItemExtent = _estimatedItemExtent(messages);
    final messageWidgets = <w.Widget>[
      for (var i = 0; i < messages.length; i++)
        MessageWidget(
          key: w.ValueKey('message-${messages[i].id}'),
          message: messages[i],
          index: i,
          showDiffContextBackground: showDiffContextBackground,
        ),
    ];

    return w.Scrollbar(
      controller: controller,
      gap: 1,
      trackStyle: style.Style()..foreground(OC.border),
      thumbStyle: style.Style()..foreground(OC.textMuted),
      child: w.VirtualListView(
        controller: controller,
        variableHeight: true,
        estimatedItemExtent: estimatedItemExtent,
        mouseWheelDelta: 3,
        enableSelection: true,
        autoCopySelectionOnMouseUp: true,
        autoCopySelectionOnExit: true,
        clearSelectionAfterAutoCopy: true,
        children: messageWidgets,
      ),
    );
  }

  int _estimatedItemExtent(List<ChatMessage> messages) {
    if (messages.isEmpty) return 6;

    var diffBlocks = 0;
    for (final message in messages) {
      if (message.role != MessageRole.assistant) continue;
      for (final part in message.parts) {
        switch (part) {
          case DiffPart():
            diffBlocks++;
          case ToolPart():
            final hasDiff = part.diff != null && part.diff!.isNotEmpty;
            if (hasDiff) diffBlocks++;
          default:
            break;
        }
      }
    }

    if (diffBlocks == 0) return 6;
    final diffDensity = diffBlocks / messages.length;
    if (diffDensity >= 1.0) return 14;
    if (diffDensity >= 0.5) return 11;
    return 9;
  }

  w.Widget _buildEmptyState(w.BuildContext context) {
    return w.Center(
      child: w.Column(
        mainAxisAlignment: w.MainAxisAlignment.center,
        children: [
          w.Text(
            'What can I help you with?',
            style: style.Style()
              ..foreground(OC.textMuted)
              ..bold(),
          ),
        ],
      ),
    );
  }
}
