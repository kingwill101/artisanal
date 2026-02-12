/// Data models for OpenCode chat messages.
///
/// Mirrors the real OpenCode message structure: each assistant message
/// is composed of parts (text, tool, reasoning) rather than generic
/// content blocks.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum MessageRole { user, assistant, system }

/// Part types within an assistant message.
enum PartType { text, tool, reasoning, diff }

/// Tool status for tool-use parts.
enum ToolStatus { pending, running, completed, error }

/// File attachment shown on user messages.
class UserFilePart {
  const UserFilePart({required this.mime, required this.filename});

  final String mime;
  final String filename;
}

// ─────────────────────────────────────────────────────────────────────────────
// Message parts (for assistant messages)
// ─────────────────────────────────────────────────────────────────────────────

/// A single part of an assistant response.
sealed class MessagePart {
  const MessagePart();
}

/// Plain text / markdown part.
class TextPart extends MessagePart {
  const TextPart(this.text);
  final String text;
}

/// Reasoning / thinking part (shown at reduced opacity).
class ReasoningPart extends MessagePart {
  const ReasoningPart(this.text);
  final String text;
}

/// Tool invocation part.
class ToolPart extends MessagePart {
  const ToolPart({
    required this.toolName,
    this.icon = '\u2699', // ⚙
    this.title = '',
    this.input = '',
    this.output = '',
    this.status = ToolStatus.completed,
    this.isBlock = false,
    this.filePath,
    this.error,
    this.diff,
  });

  final String toolName;
  final String icon;
  final String title;
  final String input;
  final String output;
  final ToolStatus status;

  /// Block tools show a bordered panel; inline tools show one line.
  final bool isBlock;

  /// Optional file path (for Read, Write, Edit, Glob, etc.).
  final String? filePath;

  /// Error message if tool failed.
  final String? error;

  /// Optional unified diff string (for Edit, Write, apply_patch).
  /// When set, the block tool renders an inline diff viewer.
  final String? diff;
}

/// A standalone file diff part — renders an inline diff viewer
/// in the chat, independent of a tool call.
class DiffPart extends MessagePart {
  const DiffPart({
    required this.filePath,
    required this.diff,
    this.additions = 0,
    this.deletions = 0,
    this.expanded = false,
  });

  /// Path of the modified file.
  final String filePath;

  /// Raw unified diff text.
  final String diff;

  /// Number of added lines.
  final int additions;

  /// Number of deleted lines.
  final int deletions;

  /// Legacy flag kept for sample-data compatibility.
  final bool expanded;
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat message
// ─────────────────────────────────────────────────────────────────────────────

/// A single chat message.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    this.text,
    this.parts = const [],
    this.files = const [],
    this.agent = 'code',
    this.modelId,
    this.duration,
    this.timestamp,
    this.queued = false,
    this.showCompaction = false,
    this.errorMessage,
    this.interrupted = false,
    this.isLast = false,
  });

  /// Convenience: user message with plain text.
  factory ChatMessage.user(
    String text, {
    String? id,
    DateTime? timestamp,
    List<UserFilePart> files = const [],
    bool queued = false,
    bool showCompaction = false,
    String agent = 'code',
  }) => ChatMessage(
    id: id ?? 'user-${text.hashCode}',
    role: MessageRole.user,
    text: text,
    files: files,
    timestamp: timestamp,
    queued: queued,
    showCompaction: showCompaction,
    agent: agent,
  );

  /// Convenience: system message with plain text.
  factory ChatMessage.system(String text, {String? id, DateTime? timestamp}) =>
      ChatMessage(
        id: id ?? 'system-${text.hashCode}',
        role: MessageRole.system,
        text: text,
        timestamp: timestamp,
        agent: 'system',
      );

  /// Convenience: assistant message from parts.
  factory ChatMessage.assistant(
    List<MessagePart> parts, {
    String? id,
    String agent = 'code',
    String? modelId,
    Duration? duration,
    String? errorMessage,
    bool interrupted = false,
    bool isLast = false,
  }) => ChatMessage(
    id: id ?? 'asst-${parts.hashCode}',
    role: MessageRole.assistant,
    parts: parts,
    agent: agent,
    modelId: modelId,
    duration: duration,
    errorMessage: errorMessage,
    interrupted: interrupted,
    isLast: isLast,
  );

  final String id;
  final MessageRole role;

  /// For user messages: the raw text.
  final String? text;

  /// For assistant messages: the response parts.
  final List<MessagePart> parts;

  /// For user messages: uploaded/attached files.
  final List<UserFilePart> files;

  /// Agent name (e.g., 'code', 'task').
  final String agent;

  /// Model identifier (e.g., 'claude-opus-4-20250514').
  final String? modelId;

  /// How long the response took.
  final Duration? duration;

  final DateTime? timestamp;

  /// For user messages: indicates queued state badge.
  final bool queued;

  /// For user messages: show compaction separator after this item.
  final bool showCompaction;

  /// For assistant messages: top-level model error shown in an error panel.
  final String? errorMessage;

  /// For assistant messages: message was interrupted/aborted.
  final bool interrupted;

  /// Whether this is the last message in the conversation.
  final bool isLast;
}
