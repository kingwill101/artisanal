library;

import 'dart:async';

import 'text_decorations.dart';
import 'workspace_edits.dart';

/// Context passed to a backend-neutral code-action provider.
final class EditorCodeActionRequest {
  const EditorCodeActionRequest({
    required this.documentText,
    required this.documentVersion,
    required this.startOffset,
    required this.endOffset,
    this.diagnostics = const <TextDiagnosticRange>[],
  });

  final String documentText;
  final int documentVersion;
  final int startOffset;
  final int endOffset;
  final List<TextDiagnosticRange> diagnostics;
}

/// A quick fix, refactor, or source action offered by tooling.
final class EditorCodeAction {
  const EditorCodeAction({
    required this.title,
    this.kind = '',
    this.preferred = false,
    this.edit = const WorkspaceEdit(),
    this.commandId,
    this.commandArguments = const <Object?>[],
  });

  final String title;
  final String kind;
  final bool preferred;
  final WorkspaceEdit edit;
  final String? commandId;
  final List<Object?> commandArguments;
}

/// Supplies code actions without coupling editor core to LSP or FFI.
abstract interface class EditorCodeActionProvider {
  FutureOr<List<EditorCodeAction>> provide(EditorCodeActionRequest request);
}

/// Rejects results superseded by another request or explicit cancellation.
final class EditorCodeActionSession {
  int _generation = 0;

  Future<List<EditorCodeAction>?> request(
    EditorCodeActionProvider provider,
    EditorCodeActionRequest request,
  ) async {
    final generation = ++_generation;
    final result = await provider.provide(request);
    if (generation != _generation) return null;
    return List<EditorCodeAction>.unmodifiable(result);
  }

  void cancel() => _generation++;
}
