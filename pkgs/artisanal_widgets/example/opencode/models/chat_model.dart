/// Application state for the OpenCode chat UI.
library;

import 'message.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar state
// ─────────────────────────────────────────────────────────────────────────────

/// Collapsible section expansion state.
class SidebarState {
  bool mcpExpanded = true;
  bool lspExpanded = true;
  bool todoExpanded = true;
  bool filesExpanded = true;
}

/// Todo item for the sidebar.
class TodoItem {
  const TodoItem(this.label, {this.done = false, this.inProgress = false});
  final String label;
  final bool done;
  final bool inProgress;
}

/// Modified file entry for the sidebar.
class ModifiedFile {
  const ModifiedFile(this.path, {this.additions = 0, this.deletions = 0});
  final String path;
  final int additions;
  final int deletions;
}

/// MCP server entry.
class McpServer {
  const McpServer(this.name, {this.status = 'connected'});
  final String name;
  final String status; // connected, failed, disabled
}

/// LSP entry.
class LspServer {
  const LspServer(this.name, {this.status = 'connected'});
  final String name;
  final String status; // connected, error
}

/// A summary of a session, for the session list.
class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.title,
    required this.lastUpdated,
    this.isBusy = false,
    this.isCurrent = false,
    this.messageCount = 0,
  });

  final String id;
  final String title;
  final DateTime lastUpdated;
  final bool isBusy;
  final bool isCurrent;
  final int messageCount;

  /// Friendly time string (e.g. "2 hours ago", "Yesterday").
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(lastUpdated);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastUpdated.month}/${lastUpdated.day}';
  }

  /// Date group label (e.g. "Today", "Yesterday", "Feb 8").
  String get dateGroup {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(
      lastUpdated.year,
      lastUpdated.month,
      lastUpdated.day,
    );
    final diff = today.difference(sessionDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[lastUpdated.month - 1]} ${lastUpdated.day}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Application state
// ─────────────────────────────────────────────────────────────────────────────

/// Which route is active.
enum AppRoute { home, session }

/// Full app state.
class ChatModel {
  ChatModel({
    this.route = AppRoute.home,
    List<ChatMessage>? messages,
    this.inputText = '',
    this.modelName = 'claude-opus-4-20250514',
    this.providerName = 'anthropic',
    this.agentName = 'code',
    this.sessionTitle = '',
    this.contextTokens = 0,
    this.contextPercentage = 0,
    this.cost = 0.0,
    SidebarState? sidebar,
    this.sidebarOpen = true,
    List<TodoItem>? todos,
    List<ModifiedFile>? modifiedFiles,
    List<McpServer>? mcpServers,
    List<LspServer>? lspServers,
    this.workingDirectory = '~/code/my-project',
    this.commandPaletteOpen = false,
  }) : messages = messages ?? [],
       sidebar = sidebar ?? SidebarState(),
       todos = todos ?? const [],
       modifiedFiles = modifiedFiles ?? const [],
       mcpServers = mcpServers ?? const [],
       lspServers = lspServers ?? const [];

  final AppRoute route;
  final List<ChatMessage> messages;
  final String inputText;
  final String modelName;
  final String providerName;
  final String agentName;
  final String sessionTitle;
  final int contextTokens;
  final int contextPercentage; // 0-100
  final double cost;
  final SidebarState sidebar;
  final bool sidebarOpen;
  final List<TodoItem> todos;
  final List<ModifiedFile> modifiedFiles;
  final List<McpServer> mcpServers;
  final List<LspServer> lspServers;
  final String workingDirectory;
  final bool commandPaletteOpen;

  /// Short model display name.
  String get modelDisplayName {
    // "claude-opus-4-20250514" -> "Claude Opus 4"
    final parts = modelName.split('-');
    if (parts.length >= 3) {
      return parts
          .take(3)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' ');
    }
    return modelName;
  }
}
