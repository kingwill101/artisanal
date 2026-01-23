library;

import 'dart:io';

import 'environ.dart';
import 'profile.dart';

const _dumbTerm = 'dumb';

/// Detect the terminal color profile from an "is TTY?" signal and environment.
///
/// This is a Dart port of charmbracelet/colorprofile's env/tty rules (minus
/// terminfo probing in the initial version).
Profile detect({
  required bool isTty,
  required Map<String, String> env,
  bool isWindows = false,
}) {
  final term = env['TERM'];
  final isDumb =
      ((term == null || term.isEmpty) && !isWindows) || term == _dumbTerm;

  final envp = _envColorProfile(env: env, isWindows: isWindows);

  var p = (!isTty || isDumb) ? Profile.noTty : envp;

  // NO_COLOR disables colors (but not decoration) when output is a TTY.
  if (isTty && envNoColor(env)) {
    if (p > Profile.ascii) p = Profile.ascii;
    return p;
  }

  // CLICOLOR_FORCE forces colors, even when we would otherwise be NoTTY/dumb.
  if (cliColorForced(env)) {
    if (p < Profile.ansi) p = Profile.ansi;
    if (envp > p) p = envp;
    return p;
  }

  // CLICOLOR enables at least ANSI colors when TERM is not defined.
  if (cliColor(env)) {
    if (isTty && !isDumb && p < Profile.ansi) {
      p = Profile.ansi;
    }
  }

  return p;
}

Profile detectForSink(
  IOSink sink, {
  Map<String, String>? env,
  bool? forceIsTty,
}) {
  final environment = env ?? Platform.environment;

  final isTty = forceIsTty ?? (sink is Stdout ? sink.hasTerminal : false);

  return detect(isTty: isTty, env: environment, isWindows: Platform.isWindows);
}

Profile _envColorProfile({
  required Map<String, String> env,
  required bool isWindows,
}) {
  final term = env['TERM'];

  var p = Profile.noTty;
  if (term != null && term.isNotEmpty && term != _dumbTerm) {
    p = Profile.ansi;
  } else if (isWindows) {
    // Best-effort Windows heuristics (similar to prior TerminalRenderer logic).
    final wtSession = env['WT_SESSION'];
    if (wtSession != null && wtSession.isNotEmpty) {
      return Profile.trueColor;
    }
    final conEmu = env['ConEmuANSI'];
    if ((conEmu ?? '').toUpperCase() == 'ON') {
      return Profile.trueColor;
    }
    // Modern Windows consoles typically support ANSI colors.
    return Profile.ansi256;
  } else {
    return Profile.noTty;
  }

  final t = term.toLowerCase();

  // Terminals that generally imply TrueColor.
  if (t.contains('alacritty') ||
      t.contains('contour') ||
      t.contains('foot') ||
      t.contains('ghostty') ||
      t.contains('kitty') ||
      t.contains('rio') ||
      t.contains('st') ||
      t.contains('wezterm')) {
    return Profile.trueColor;
  }

  if (t.startsWith('tmux') || t.startsWith('screen')) {
    if (p < Profile.ansi256) p = Profile.ansi256;
  } else if (t.startsWith('xterm')) {
    if (p < Profile.ansi) p = Profile.ansi;
  }

  if (_parseBool(env['GOOGLE_CLOUD_SHELL'])) {
    return Profile.trueColor;
  }

  // GNU Screen doesn't support TrueColor; tmux doesn't support $COLORTERM.
  if (colorTerm(env) && !t.startsWith('screen') && !t.startsWith('tmux')) {
    return Profile.trueColor;
  }

  if (t.endsWith('256color') && p < Profile.ansi256) {
    p = Profile.ansi256;
  }

  if (t.endsWith('direct')) {
    return Profile.trueColor;
  }

  return p;
}

bool _parseBool(String? value) {
  if (value == null) return false;
  final v = value.trim().toLowerCase();
  if (v.isEmpty) return false;
  return switch (v) {
    '1' || 't' || 'true' || 'y' || 'yes' || 'on' => true,
    _ => false,
  };
}
