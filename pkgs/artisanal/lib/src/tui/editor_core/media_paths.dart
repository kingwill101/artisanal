library;

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// File-path recognition for pasted and dropped paths.
///
/// Terminals deliver file drops as bracketed pastes of paths (often quoted
/// or shell-escaped), so drops and path-pastes share one pipeline: extract
/// candidates here (pure strings, no I/O), let the host check existence,
/// then attach survivors as media. Formats stay renderable-only: extensions
/// the overlay cannot decode must not become chips.

/// Whether [path] names an image our subsystem can decode, probed via
/// `package:image` (the same decoders the terminal pixel pipeline uses).
///
/// This is the single source of truth — no hand-maintained extension list.
/// Formats `package:image` cannot decode (SVG, HEIC/AVIF) never become
/// chips, since the overlay could not render them.
bool isImagePath(String path) {
  return img.findDecoderForNamedImage(p.basename(path)) != null;
}

/// Whether [bytes] decode as an image (magic-byte probe, not extension).
///
/// Use this for pasted clipboard bytes before creating a chip.
bool isDecodableImageBytes(List<int> bytes) {
  if (bytes.isEmpty) return false;
  try {
    return img.findDecoderForData(bytes) != null;
  } catch (_) {
    return false;
  }
}

/// Extracts file-path candidates from pasted or dropped text.
///
/// Tries the whole payload first (covers quoted paths containing spaces),
/// then falls back to per-line candidates. Handles `file://` URLs, surrounding
/// quotes, shell backslash escapes, and the Windows `\\?\` verbatim prefix.
/// Returns candidates in order, deduplicated. Existence is the host's job.
List<String> extractPastedFilePaths(String text) {
  final trimmed = text.trim();
  // Whole-payload fast path is single-line only: paths never contain raw
  // newlines, and multi-line payloads go per-line below.
  if (!trimmed.contains('\n')) {
    final whole = _candidateFromToken(trimmed);
    if (whole != null && whole.isNotEmpty) return [whole];
  }
  final found = <String>[];
  for (final line in text.split('\n')) {
    final candidate = _candidateFromToken(line.trim());
    if (candidate != null &&
        candidate.isNotEmpty &&
        !found.contains(candidate)) {
      found.add(candidate);
    }
  }
  return found;
}

/// Splits [candidates] into image paths and everything else.
({List<String> images, List<String> other}) partitionImagePaths(
  Iterable<String> candidates,
) {
  final images = <String>[];
  final other = <String>[];
  for (final candidate in candidates) {
    if (isImagePath(candidate)) {
      images.add(candidate);
    } else {
      other.add(candidate);
    }
  }
  return (images: images, other: other);
}

String? _candidateFromToken(String token) {
  if (token.isEmpty) return null;
  // Verbatim prefix first: it contains backslashes that escape handling
  // would otherwise mangle.
  var value = _stripVerbatimPrefix(_stripSurroundingQuotes(token));
  if (value.startsWith('file://')) {
    // package:path decodes percent-escapes and drive letters; it throws
    // on non-file schemes.
    try {
      value = p.fromUri(value);
    } catch (_) {
      return null;
    }
  } else if (!_usesWindowsSeparators(value)) {
    // Shell-layer escapes only apply to portable/posix spellings;
    // backslashes in Windows spellings are separators, not escapes.
    value = _shellUnescape(value);
  }
  if (value.isEmpty) return null;
  // Heuristic: must look like a path (separator or extension), otherwise
  // this is just pasted prose.
  if (!value.contains('/') &&
      !value.contains('\\') &&
      !value.contains('.')) {
    return null;
  }
  return value;
}

/// Strips one layer of surrounding quotes. Terminals quote dropped paths
/// containing spaces; quoting is shell presentation, not path syntax, so
/// package:path has no equivalent and this stays here.
String _stripSurroundingQuotes(String value) {
  if (value.length >= 2) {
    final first = value[0];
    final last = value[value.length - 1];
    if ((first == "'" && last == "'") || (first == '"' && last == '"')) {
      return value.substring(1, value.length - 1);
    }
  }
  return value;
}

/// Whether backslashes in [value] read as separators (drive-letter or
/// UNC spellings). Separator ambiguity is inherent — a relative `a\b` is
/// unknowable without platform context — so only explicit Windows
/// spellings opt out of shell unescaping.
bool _usesWindowsSeparators(String value) {
  if (value.startsWith('\\\\')) return true;
  return RegExp(r'^[A-Za-z]:[\\\\/]').hasMatch(value);
}

/// Collapses shell backslash escapes (`\X` → `X`) in posix spellings.
String _shellUnescape(String value) {
  if (!value.contains('\\')) return value;
  return value.replaceAllMapped(RegExp(r'\\(.)', dotAll: true), (m) => m[1]!);
}

String _stripVerbatimPrefix(String value) {
  // package:path preserves the verbatim prefix by design; pasted paths
  // must resolve like their plain form to hit the disk.
  const unc = r'\\?\UNC\';
  const disk = r'\\?\';
  if (value.startsWith(unc)) return '\\\\${value.substring(unc.length)}';
  if (value.startsWith(disk)) return value.substring(disk.length);
  return value;
}
