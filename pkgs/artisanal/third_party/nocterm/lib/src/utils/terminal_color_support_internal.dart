import 'package:nocterm/src/utils/truthiness.dart';

bool detectTruecolorFromEnv(Map<String, String> env) {
  final override = env['NOCTERM_TRUECOLOR']?.toLowerCase();
  if (override != null && override.isNotEmpty) {
    if (truthy(override)) return true;
    if (falsey(override)) return false;
  }

  final colorterm = env['COLORTERM']?.toLowerCase() ?? '';
  if (colorterm.contains('truecolor') || colorterm.contains('24bit')) {
    return true;
  }

  final term = env['TERM']?.toLowerCase() ?? '';
  if (term.contains('truecolor') || term.contains('24bit')) {
    return true;
  }

  return false;
}
