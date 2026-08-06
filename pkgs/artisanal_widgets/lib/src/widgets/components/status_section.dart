/// Collapsible sidebar status section (OpenCode MCP/LSP/todo pattern).
library;

import 'package:artisanal/style.dart' show Color;

import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../core/widget.dart';
import '../layout/layout.dart';
import '../theme/theme_scope.dart' show ThemeScope;

/// A titled, optionally collapsible block used in sidebars / status panels.
class StatusSection extends StatelessWidget {
  StatusSection({
    required this.title,
    required this.items,
    this.expanded = true,
    this.count,
    this.emptyLabel,
    this.onToggle,
    this.titleColor,
    this.mutedColor,
    this.showChevronWhenCountAbove = 0,
    super.key,
  });

  final String title;

  /// Rows under the header when expanded.
  final List<Widget> items;
  final bool expanded;

  /// Optional badge count shown after the title.
  final int? count;

  /// Shown when [expanded] and [items] is empty.
  final String? emptyLabel;

  /// Called when the header is activated. When null, the section is static.
  final void Function()? onToggle;

  final Color? titleColor;
  final Color? mutedColor;

  /// Show expand chevron when [count] is greater than this (OpenCode: >2 for MCP).
  final int showChevronWhenCountAbove;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final titleFg = titleColor ?? theme.onSurface;
    final muted = mutedColor ?? theme.muted;
    final n = count ?? items.length;
    final showChevron = onToggle != null && n > showChevronWhenCountAbove;

    final header = Row(
      gap: 1,
      children: [
        if (showChevron)
          Text(
            expanded ? '▼' : '▶',
            style: theme.labelSmall.copy()..foreground(titleFg),
          ),
        Text(
          title,
          style: theme.labelLarge.copy()
            ..foreground(titleFg)
            ..bold(),
        ),
        if (count != null)
          Text(
            '$count',
            style: theme.labelSmall.copy()..foreground(muted),
          ),
      ],
    );

    final headerWidget = onToggle == null
        ? header
        : GestureDetector(
            onTap: () {
              onToggle!();
              return null;
            },
            child: header,
          );

    final body = <Widget>[];
    if (expanded) {
      if (items.isEmpty) {
        if (emptyLabel != null && emptyLabel!.isNotEmpty) {
          body.add(
            Text(
              emptyLabel!,
              style: theme.bodySmall.copy()..foreground(muted),
            ),
          );
        }
      } else {
        body.addAll(items);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      gap: 0,
      children: [
        headerWidget,
        ...body,
      ],
    );
  }
}

/// Compact connection / status pill (connected · degraded · offline).
enum ConnectionStatus {
  connected,
  degraded,
  offline,
  disabled,
  unknown,
}

/// Colored bullet + label for connection state.
class ConnectionBadge extends StatelessWidget {
  ConnectionBadge({
    required this.label,
    this.status = ConnectionStatus.unknown,
    this.detail,
    this.connectedColor,
    this.degradedColor,
    this.offlineColor,
    this.mutedColor,
    super.key,
  });

  final String label;
  final ConnectionStatus status;
  final String? detail;
  final Color? connectedColor;
  final Color? degradedColor;
  final Color? offlineColor;
  final Color? mutedColor;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final color = switch (status) {
      ConnectionStatus.connected => connectedColor ?? theme.success,
      ConnectionStatus.degraded => degradedColor ?? theme.warning,
      ConnectionStatus.offline => offlineColor ?? theme.error,
      ConnectionStatus.disabled => mutedColor ?? theme.muted,
      ConnectionStatus.unknown => mutedColor ?? theme.muted,
    };
    final statusText = detail ??
        switch (status) {
          ConnectionStatus.connected => 'Connected',
          ConnectionStatus.degraded => 'Degraded',
          ConnectionStatus.offline => 'Offline',
          ConnectionStatus.disabled => 'Disabled',
          ConnectionStatus.unknown => '',
        };

    return Row(
      gap: 1,
      children: [
        Text('•', style: theme.labelSmall.copy()..foreground(color)),
        Text(
          label,
          style: theme.bodySmall.copy()..foreground(theme.onSurface),
          softWrap: false,
        ),
        if (statusText.isNotEmpty)
          Flexible(
            child: Text(
              statusText,
              style: theme.bodySmall.copy()..foreground(theme.muted),
              softWrap: false,
            ),
          ),
      ],
    );
  }
}
