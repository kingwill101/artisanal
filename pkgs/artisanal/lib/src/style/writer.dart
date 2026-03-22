// ignore_for_file: non_constant_identifier_names
/// Lipgloss-style writer utilities for styled terminal output.
///
/// Provides Go-like print functions ([Print], [Println], [Printf]) that
/// automatically downsample ANSI colors based on terminal capabilities.
///
/// The global [Writer] controls output destination and color profile.
/// Use [Sprint]/[Sprintln]/[Sprintf] for string-returning variants.
///
/// ## Usage
///
/// ```dart
/// import 'package:artisanal/style.dart';
///
/// // Print styled text (auto-downsampled for terminal)
/// final style = Style().foreground(Colors.red).bold();
/// Println(style.render('Error: Something went wrong'));
///
/// // Printf-style formatting
/// Printf('Hello, %s! You have %d messages.\n', 'Alice', 5);
///
/// // Get styled string without printing
/// final msg = Sprint(style.render('Warning'));
/// ```
///
/// ## Color Downsampling
///
/// Output is automatically adjusted for terminal capabilities:
/// - [ColorProfile.trueColor]: Full 24-bit color (unchanged)
/// - [ColorProfile.ansi256]: Downsample to 256 colors
/// - [ColorProfile.ansi]: Downsample to 16 colors
/// - [ColorProfile.noColor]: Strip color codes, keep text
/// - [ColorProfile.ascii]: Strip all ANSI escape sequences
///
/// ## Note
///
/// These functions are for non-TUI output. Do not write directly to stdout
/// while a `tui.Program` is running with the UV renderer.
///
/// {@category Style}
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
/// - [ColorProfile.noColor]/`ansi`/`ansi256`: downsample SGR colors
/// - [ColorProfile.trueColor]: unchanged
String stringForProfile(String input, ColorProfile profile) {
  final p = _toInternalProfile(profile);
  if (p == cp.Profile.noTty) return Ansi.stripAnsi(input);
  if (p == cp.Profile.trueColor) return input;
  return cp_downsample.downsampleSgr(input, p);
}

/// Prints values to [Writer] without a trailing newline.
///
/// Concatenates all non-null values without separators.
/// Returns the number of characters written.
///
/// ```dart
/// Print('Hello, ', 'world'); // Outputs: Hello, world
/// ```
int Print(
  Object? v1, [
  Object? v2,
  Object? v3,
  Object? v4,
  Object? v5,
  Object? v6,
]) => PrintAll([v1, v2, v3, v4, v5, v6].where((it) => it != null));

/// Prints values to [Writer] with a trailing newline.
///
/// Concatenates all non-null values with space separators.
/// Returns the number of characters written (including newline).
///
/// ```dart
/// Println('Hello,', 'world'); // Outputs: Hello, world\n
/// ```
int Println([
  Object? v1,
  Object? v2,
  Object? v3,
  Object? v4,
  Object? v5,
  Object? v6,
]) => PrintlnAll([v1, v2, v3, v4, v5, v6].where((it) => it != null));

/// Prints formatted output to [Writer].
///
/// Supports common printf format specifiers: %s, %d, %i, %f, %x, %X, %o, %b,
/// %e, %E, %g, %G, %a, %A, %c, %p. Use %% for a literal percent sign.
/// Returns the number of characters written.
///
/// ```dart
/// Printf('Name: %s, Age: %d\n', 'Alice', 30);
/// ```
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

/// Returns concatenated values as a string (no trailing newline).
///
/// Like [Print] but returns the string instead of printing.
///
/// ```dart
/// final s = Sprint('Hello, ', 'world'); // 'Hello, world'
/// ```
String Sprint(
  Object? v1, [
  Object? v2,
  Object? v3,
  Object? v4,
  Object? v5,
  Object? v6,
]) => SprintAll([v1, v2, v3, v4, v5, v6].where((it) => it != null));

/// Returns concatenated values as a string with trailing newline.
///
/// Like [Println] but returns the string instead of printing.
///
/// ```dart
/// final s = Sprintln('Hello,', 'world'); // 'Hello, world\n'
/// ```
String Sprintln([
  Object? v1,
  Object? v2,
  Object? v3,
  Object? v4,
  Object? v5,
  Object? v6,
]) => SprintlnAll([v1, v2, v3, v4, v5, v6].where((it) => it != null));

/// Returns formatted string.
///
/// Like [Printf] but returns the string instead of printing.
///
/// ```dart
/// final s = Sprintf('Name: %s, Age: %d', 'Alice', 30);
/// ```
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

/// Prints all values in [values] without separators or newline.
int PrintAll(Iterable<Object?> values) {
  final out = _join(values, sep: '');
  Writer.write(stringForProfile(out, Writer.colorProfile));
  return out.length;
}

/// Prints all values in [values] with space separators and trailing newline.
int PrintlnAll(Iterable<Object?> values) {
  final out = _join(values, sep: ' ');
  Writer.writeln(stringForProfile(out, Writer.colorProfile));
  return out.length + 1;
}

/// Prints formatted output using all [args].
int PrintfAll(String format, List<Object?> args) {
  final out = _sprintf(format, args);
  Writer.write(stringForProfile(out, Writer.colorProfile));
  return out.length;
}

/// Returns all values in [values] concatenated without separators.
String SprintAll(Iterable<Object?> values) =>
    stringForProfile(_join(values, sep: ''), Writer.colorProfile);

/// Returns all values in [values] concatenated with spaces and newline.
String SprintlnAll(Iterable<Object?> values) =>
    stringForProfile('${_join(values, sep: ' ')}\n', Writer.colorProfile);

/// Returns formatted string using all [args].
String SprintfAll(String format, List<Object?> args) =>
    stringForProfile(_sprintf(format, args), Writer.colorProfile);

/// Prints values to a specific [sink] without trailing newline.
int Fprint(io.IOSink sink, Iterable<Object?> values) {
  final out = _join(values, sep: '');
  final tr = r.TerminalRenderer(output: sink);
  tr.write(stringForProfile(out, tr.colorProfile));
  return out.length;
}

/// Prints values to a specific [sink] with trailing newline.
int Fprintln(io.IOSink sink, Iterable<Object?> values) {
  final out = _join(values, sep: ' ');
  final tr = r.TerminalRenderer(output: sink);
  tr.writeln(stringForProfile(out, tr.colorProfile));
  return out.length + 1;
}

/// Prints formatted output to a specific [sink].
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
