// ignore_for_file: non_constant_identifier_names
library;

import 'dart:io' as io;

import '../colorprofile/downsample.dart' as cp_downsample;
import '../colorprofile/profile.dart' as cp;
import '../renderer/renderer.dart' as r;
import '../terminal/ansi.dart' show Ansi;
import 'color.dart' show ColorProfile;

/// Lipgloss v2-style writer that automatically downsamples ANSI color sequences.
///
/// Upstream: `third_party/lipgloss/writer.go`.
///
/// Note: This writer is intended for non-TUI output. Do not write directly to
/// stdout while a `tui.Program` is running with the UV renderer.
r.Renderer _writer = r.TerminalRenderer();

/// Global writer used by [Print]/[Println]/[Printf], defaulting to stdout.
r.Renderer get Writer => _writer;
set Writer(r.Renderer value) => _writer = value;

/// Resets [Writer] back to a new terminal writer targeting stdout.
void resetWriter() {
  _writer = r.TerminalRenderer();
}

/// Returns [input] processed for the given [profile].
///
/// This mirrors the behavior of the upstream colorprofile writer:
/// - [ColorProfile.ascii]: strip all ANSI escape sequences
/// - [ColorProfile.noColor]/[ansi]/[ansi256]: downsample SGR colors
/// - [ColorProfile.trueColor]: unchanged
String stringForProfile(String input, ColorProfile profile) {
  final p = _toInternalProfile(profile);
  if (p == cp.Profile.noTty) return Ansi.stripAnsi(input);
  if (p == cp.Profile.trueColor) return input;
  return cp_downsample.downsampleSgr(input, p);
}

int Print(
  Object? v1, [
  Object? v2,
  Object? v3,
  Object? v4,
  Object? v5,
  Object? v6,
]) => PrintAll([v1, v2, v3, v4, v5, v6].where((it) => it != null));

int Println([
  Object? v1,
  Object? v2,
  Object? v3,
  Object? v4,
  Object? v5,
  Object? v6,
]) => PrintlnAll([v1, v2, v3, v4, v5, v6].where((it) => it != null));

int Printf(
  String format, [
  Object? v1,
  Object? v2,
  Object? v3,
  Object? v4,
  Object? v5,
  Object? v6,
]) => PrintfAll(
  format,
  [v1, v2, v3, v4, v5, v6].where((it) => it != null).toList(),
);

String Sprint(
  Object? v1, [
  Object? v2,
  Object? v3,
  Object? v4,
  Object? v5,
  Object? v6,
]) => SprintAll([v1, v2, v3, v4, v5, v6].where((it) => it != null));

String Sprintln([
  Object? v1,
  Object? v2,
  Object? v3,
  Object? v4,
  Object? v5,
  Object? v6,
]) => SprintlnAll([v1, v2, v3, v4, v5, v6].where((it) => it != null));

String Sprintf(
  String format, [
  Object? v1,
  Object? v2,
  Object? v3,
  Object? v4,
  Object? v5,
  Object? v6,
]) => SprintfAll(
  format,
  [v1, v2, v3, v4, v5, v6].where((it) => it != null).toList(),
);

int PrintAll(Iterable<Object?> values) {
  final out = _join(values, sep: '');
  Writer.write(stringForProfile(out, Writer.colorProfile));
  return out.length;
}

int PrintlnAll(Iterable<Object?> values) {
  final out = _join(values, sep: ' ');
  Writer.writeln(stringForProfile(out, Writer.colorProfile));
  return out.length + 1;
}

int PrintfAll(String format, List<Object?> args) {
  final out = _sprintf(format, args);
  Writer.write(stringForProfile(out, Writer.colorProfile));
  return out.length;
}

String SprintAll(Iterable<Object?> values) =>
    stringForProfile(_join(values, sep: ''), Writer.colorProfile);

String SprintlnAll(Iterable<Object?> values) =>
    stringForProfile('${_join(values, sep: ' ')}\n', Writer.colorProfile);

String SprintfAll(String format, List<Object?> args) =>
    stringForProfile(_sprintf(format, args), Writer.colorProfile);

int Fprint(io.IOSink sink, Iterable<Object?> values) {
  final out = _join(values, sep: '');
  final tr = r.TerminalRenderer(output: sink);
  tr.write(stringForProfile(out, tr.colorProfile));
  return out.length;
}

int Fprintln(io.IOSink sink, Iterable<Object?> values) {
  final out = _join(values, sep: ' ');
  final tr = r.TerminalRenderer(output: sink);
  tr.writeln(stringForProfile(out, tr.colorProfile));
  return out.length + 1;
}

int Fprintf(io.IOSink sink, String format, List<Object?> args) {
  final out = _sprintf(format, args);
  final tr = r.TerminalRenderer(output: sink);
  tr.write(stringForProfile(out, tr.colorProfile));
  return out.length;
}

String _join(Iterable<Object?> values, {required String sep}) {
  final buf = StringBuffer();
  var first = true;
  for (final v in values) {
    if (!first) buf.write(sep);
    first = false;
    buf.write(v?.toString() ?? 'null');
  }
  return buf.toString();
}

String _sprintf(String format, List<Object?> args) {
  // Minimal printf-style formatting:
  // - supports common %<char> tokens
  // - supports %% escaping
  // Everything else passes through unchanged.
  var out = StringBuffer();
  var argIndex = 0;

  for (var i = 0; i < format.length; i++) {
    final ch = format.codeUnitAt(i);
    if (ch != 0x25 /* % */ ) {
      out.writeCharCode(ch);
      continue;
    }

    if (i + 1 >= format.length) {
      out.write('%');
      continue;
    }

    final next = format.codeUnitAt(i + 1);
    if (next == 0x25 /* % */ ) {
      out.write('%');
      i++;
      continue;
    }

    // Consume a single-letter specifier.
    final spec = String.fromCharCode(next);
    if (RegExp(r'^[sdifxXobeEgGaAcsp]$').hasMatch(spec)) {
      final v = argIndex < args.length ? args[argIndex++] : null;
      out.write(v?.toString() ?? 'null');
      i++;
      continue;
    }

    // Unknown format: keep as literal.
    out.write('%');
  }

  return out.toString();
}

cp.Profile _toInternalProfile(ColorProfile profile) {
  return switch (profile) {
    ColorProfile.trueColor => cp.Profile.trueColor,
    ColorProfile.ansi256 => cp.Profile.ansi256,
    ColorProfile.ansi => cp.Profile.ansi,
    ColorProfile.noColor => cp.Profile.ascii,
    ColorProfile.ascii => cp.Profile.noTty,
  };
}
