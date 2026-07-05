/// Application state for the OpenCode chat UI.
library;

import '../widgets/state/build_mode.dart';
import '../widgets/state/open_code_ui_state.dart';
import 'message.dart';


enum AppChord {
  sidebar('toggle-sidebar'),
  models('toggle-models');

  final String id;
  const AppChord(this.id);
}


/// Collapsible section expansion state.
class SidebarState {
  const SidebarState({
    this.mcpExpanded = true,
    this.lspExpanded = true,
    this.todoExpanded = true,
    this.filesExpanded = true,
  });

  final bool mcpExpanded;
  final bool lspExpanded;
  final bool todoExpanded;
  final bool filesExpanded;

  SidebarState copyWith({
    bool? mcpExpanded,
    bool? lspExpanded,
    bool? todoExpanded,
    bool? filesExpanded,
  }) {
    return SidebarState(
      mcpExpanded: mcpExpanded ?? this.mcpExpanded,
      lspExpanded: lspExpanded ?? this.lspExpanded,
      todoExpanded: todoExpanded ?? this.todoExpanded,
      filesExpanded: filesExpanded ?? this.filesExpanded,
    );
  }
}

/// Todo item for the sidebar.
class TodoItem {
  const TodoItem(this.label, {this.done = false, this.inProgress = false});
  final String label;
  final bool done;
  final bool inProgress;

  TodoItem copyWith({String? label, bool? done, bool? inProgress}) {
    return TodoItem(
      label ?? this.label,
      done: done ?? this.done,
      inProgress: inProgress ?? this.inProgress,
    );
  }
}

/// Modified file entry for the sidebar.
class ModifiedFile {
  const ModifiedFile(this.path, {this.additions = 0, this.deletions = 0});
  final String path;
  final int additions;
  final int deletions;

  ModifiedFile copyWith({String? path, int? additions, int? deletions}) {
    return ModifiedFile(
      path ?? this.path,
      additions: additions ?? this.additions,
      deletions: deletions ?? this.deletions,
    );
  }
}

/// MCP server entry.
class McpServer {
  const McpServer(this.name, {this.status = 'connected'});
  final String name;
  final String status;

  McpServer copyWith({String? name, String? status}) {
    return McpServer(name ?? this.name, status: status ?? this.status);
  }
}

/// LSP entry.
class LspServer {
  const LspServer(this.name, {this.status = 'connected'});
  final String name;
  final String status;

  LspServer copyWith({String? name, String? status}) {
    return LspServer(name ?? this.name, status: status ?? this.status);
  }
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

  SessionSummary copyWith({
    String? id,
    String? title,
    DateTime? lastUpdated,
    bool? isBusy,
    bool? isCurrent,
    int? messageCount,
  }) {
    return SessionSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isBusy: isBusy ?? this.isBusy,
      isCurrent: isCurrent ?? this.isCurrent,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}

/// A single item in the model list dialog.
class ModelOption {
  const ModelOption({
    required this.modelName,
    required this.providerName,
    this.displayName,
  });
  final String modelName;
  final String providerName;
  final String? displayName;

  ModelOption copyWith({
    String? modelName,
    String? providerName,
    String? displayName,
  }) {
    return ModelOption(
      modelName: modelName ?? this.modelName,
      providerName: providerName ?? this.providerName,
      displayName: displayName ?? this.displayName,
    );
  }
}

/// Full app state.
class ChatModel {
  ChatModel({
    this.route = AppRoute.home,
    this.messages = const [],
    this.inputText = '',
    this.modelName = 'claude-opus-4-20250514',
    this.providerName = 'anthropic',
    this.agentName = 'code',
    this.sessionTitle = '',
    this.contextTokens = 0,
    this.contextPercentage = 0,
    this.cost = 0.0,
    this.sidebar = const SidebarState(),
    this.sidebarOpen = true,
    this.todos = const [],
    this.modifiedFiles = const [],
    this.mcpServers = const [],
    this.lspServers = const [],
    this.workingDirectory = '~/code/my-project',
    this.commandPaletteOpen = false,
    this.mode = BuildMode.build,
    this.enterBehavior = EnterBehavior.send,
  });

  final AppRoute route;
  final List<ChatMessage> messages;
  final String inputText;
  final String modelName;
  final String providerName;
  final String agentName;
  final String sessionTitle;
  final int contextTokens;
  final int contextPercentage;
  final double cost;
  final SidebarState sidebar;
  final bool sidebarOpen;
  final List<TodoItem> todos;
  final List<ModifiedFile> modifiedFiles;
  final List<McpServer> mcpServers;
  final List<LspServer> lspServers;
  final String workingDirectory;
  final bool commandPaletteOpen;
  final BuildMode mode;

  final EnterBehavior enterBehavior;

  ChatModel copyWith({
    AppRoute? route,
    List<ChatMessage>? messages,
    String? inputText,
    String? modelName,
    String? providerName,
    String? sessionTitle,
    int? contextTokens,
    int? contextPercentage,
    double? cost,
    SidebarState? sidebar,
    bool? sidebarOpen,
    List<TodoItem>? todos,
    List<ModifiedFile>? modifiedFiles,
    List<McpServer>? mcpServers,
    List<LspServer>? lspServers,
    String? workingDirectory,
    bool? commandPaletteOpen,
    BuildMode? mode,
    EnterBehavior? enterBehavior,
  }) {
    return ChatModel(
      route: route ?? this.route,
      messages: messages ?? this.messages,
      inputText: inputText ?? this.inputText,
      modelName: modelName ?? this.modelName,
      providerName: providerName ?? this.providerName,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      contextTokens: contextTokens ?? this.contextTokens,
      contextPercentage: contextPercentage ?? this.contextPercentage,
      cost: cost ?? this.cost,
      sidebar: sidebar ?? this.sidebar,
      sidebarOpen: sidebarOpen ?? this.sidebarOpen,
      todos: todos ?? this.todos,
      modifiedFiles: modifiedFiles ?? this.modifiedFiles,
      mcpServers: mcpServers ?? this.mcpServers,
      lspServers: lspServers ?? this.lspServers,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      commandPaletteOpen: commandPaletteOpen ?? this.commandPaletteOpen,
      mode: mode ?? this.mode,
      enterBehavior: enterBehavior ?? this.enterBehavior,
    );
  }
}

enum AppRoute { home, session, agentOverview }
