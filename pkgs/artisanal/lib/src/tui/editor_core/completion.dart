library;

import 'dart:async';

import 'workspace_edits.dart';

/// Broad category used to decorate and rank a completion.
enum EditorCompletionKind {
  text,
  method,
  function,
  constructor,
  field,
  variable,
  type,
  module,
  property,
  keyword,
  snippet,
  file,
}

/// Immutable completion request in grapheme/document coordinates.
final class EditorCompletionRequest {
  const EditorCompletionRequest({
    required this.documentText,
    required this.cursorOffset,
    required this.documentVersion,
    this.trigger,
  });

  final String documentText;
  final int cursorOffset;

  /// Host-controlled revision used to reject stale asynchronous results.
  final int documentVersion;

  /// Trigger character, or null for an explicitly requested completion.
  final String? trigger;
}

/// One completion candidate and the edits needed to accept it.
final class EditorCompletionItem {
  const EditorCompletionItem({
    required this.label,
    required this.insertText,
    this.kind = EditorCompletionKind.text,
    this.detail = '',
    this.documentation = '',
    this.filterText,
    this.sortText,
    this.replacementStart,
    this.replacementEnd,
    this.additionalEdits = const WorkspaceEdit(),
  });

  final String label;
  final String insertText;
  final EditorCompletionKind kind;
  final String detail;
  final String documentation;
  final String? filterText;
  final String? sortText;

  /// Optional replacement range. Null means insert at the request cursor.
  final int? replacementStart;
  final int? replacementEnd;

  /// Import or cross-file edits applied with the primary insertion.
  final WorkspaceEdit additionalEdits;
}

/// Result returned by an [EditorCompletionProvider].
final class EditorCompletionResult {
  const EditorCompletionResult({
    this.items = const <EditorCompletionItem>[],
    this.isIncomplete = false,
  });

  final List<EditorCompletionItem> items;
  final bool isIncomplete;
}

/// Backend-neutral source of editor completions.
abstract interface class EditorCompletionProvider {
  FutureOr<EditorCompletionResult> provide(EditorCompletionRequest request);
}

/// Coordinates asynchronous completion requests and rejects stale responses.
///
/// Starting another request or calling [cancel] invalidates every earlier
/// response, even when its provider cannot cancel the underlying operation.
final class EditorCompletionSession {
  int _generation = 0;
  EditorCompletionRequest? _activeRequest;

  EditorCompletionRequest? get activeRequest => _activeRequest;
  bool get isActive => _activeRequest != null;

  Future<EditorCompletionResult?> request(
    EditorCompletionProvider provider,
    EditorCompletionRequest request,
  ) async {
    final generation = ++_generation;
    _activeRequest = request;
    final result = await provider.provide(request);
    if (generation != _generation ||
        _activeRequest?.documentVersion != request.documentVersion) {
      return null;
    }
    return result;
  }

  void cancel() {
    _generation++;
    _activeRequest = null;
  }
}

/// Deterministically filters and sorts [items] for a command palette or popup.
List<EditorCompletionItem> filterEditorCompletions(
  Iterable<EditorCompletionItem> items,
  String query,
) {
  final needle = query.toLowerCase();
  final scored = <({EditorCompletionItem item, int score})>[];
  for (final item in items) {
    final candidate = (item.filterText ?? item.label).toLowerCase();
    final score = _subsequenceScore(candidate, needle);
    if (score != null) scored.add((item: item, score: score));
  }
  scored.sort((a, b) {
    final byScore = a.score.compareTo(b.score);
    if (byScore != 0) return byScore;
    final bySortText = (a.item.sortText ?? a.item.label).compareTo(
      b.item.sortText ?? b.item.label,
    );
    return bySortText != 0 ? bySortText : a.item.label.compareTo(b.item.label);
  });
  return List<EditorCompletionItem>.unmodifiable(
    scored.map((entry) => entry.item),
  );
}

int? _subsequenceScore(String candidate, String query) {
  if (query.isEmpty) return 0;
  var from = 0;
  var score = 0;
  for (final unit in query.codeUnits) {
    final index = candidate.indexOf(String.fromCharCode(unit), from);
    if (index < 0) return null;
    score += index - from;
    from = index + 1;
  }
  return score + candidate.length - query.length;
}
