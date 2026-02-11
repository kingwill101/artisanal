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
  final w.ListViewController? scrollController;
  final bool showDiffContextBackground;

  @override
  w.Widget build(w.BuildContext context) {
    if (messages.isEmpty) {
      return _buildEmptyState(context);
    }

    final controller = scrollController ?? w.ListViewController();
    final messageWidgets = <w.Widget>[
      for (var i = 0; i < messages.length; i++)
        MessageWidget(
          key: w.ValueKey('message-${messages[i].id}'),
          message: messages[i],
          index: i,
          showDiffContextBackground: showDiffContextBackground,
          onExpandDelta: (delta) {
            controller.scrollBy(delta);
          },
        ),
    ];

    return w.Scrollbar(
      controller: controller,
      child: w.VirtualListView(
        controller: controller,
        variableHeight: true,
        estimatedItemExtent: 6,
        children: messageWidgets,
      ),
    );
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
