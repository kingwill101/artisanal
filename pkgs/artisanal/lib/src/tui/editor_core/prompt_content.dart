library;

/// Prompt-composer content helpers.
///
/// These are pure functions with no I/O: the `$EDITOR` process handling
/// itself goes through `Cmd.exec` / `Cmd.openEditor`, which already release
/// and restore the terminal around the child process.

/// Normalizes composer content for submission.
///
/// Strips a single trailing newline (`\n` or `\r\n`) from one-line prompts
/// — the artifact external editors append on save — while preserving
/// multiline prompts that end with a newline.
String normalizePromptContent(String content) {
  if (content.endsWith('\r\n')) {
    final body = content.substring(0, content.length - 2);
    if (!body.contains('\n') && !body.contains('\r')) return body;
    return content;
  }
  if (content.endsWith('\n')) {
    final body = content.substring(0, content.length - 1);
    if (!body.contains('\n') && !body.contains('\r')) return body;
    return content;
  }
  return content;
}

/// Resolves the external editor executable from environment variables.
///
/// Mirrors `Cmd.openEditor` precedence (`VISUAL`, then `EDITOR`) without
/// touching `dart:io`, so the rule stays testable: pass
/// `Platform.environment` in app code. Falls back to `vi` on Unix and
/// `notepad` on Windows. Returns `null` when no editor is configured and no
/// fallback applies (only when [allowFallback] is false).
String? resolveExternalEditorExecutable(
  Map<String, String> environment, {
  bool isWindows = false,
  bool allowFallback = true,
}) {
  final visual = (environment['VISUAL'] ?? '').trim();
  if (visual.isNotEmpty) return visual.split(' ').first;
  final editor = (environment['EDITOR'] ?? '').trim();
  if (editor.isNotEmpty) return editor.split(' ').first;
  if (!allowFallback) return null;
  return isWindows ? 'notepad' : 'vi';
}
