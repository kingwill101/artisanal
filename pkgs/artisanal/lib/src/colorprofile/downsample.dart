library;

import 'convert.dart';
import 'profile.dart';

final _sgrPattern = RegExp(r'\x1B\[([0-9;:]*)m');

/// Downsample ANSI SGR color sequences in [input] to match [profile].
///
/// - [Profile.noTty]: strips all ANSI escape sequences (CSI SGR only)
/// - [Profile.ascii]: strips color sequences but keeps non-color SGR params
/// - [Profile.ansi]: converts 24-bit/256-color to ANSI16
/// - [Profile.ansi256]: converts 24-bit to 256-color
/// - [Profile.trueColor]: leaves sequences unchanged
String downsampleSgr(String input, Profile profile) {
  if (input.isEmpty) return input;

  if (profile == Profile.trueColor) return input;

  return input.replaceAllMapped(_sgrPattern, (m) {
    if (profile == Profile.noTty) return '';

    final paramsRaw = m.group(1) ?? '';
    if (paramsRaw.isEmpty) {
      return '\x1B[m';
    }

    // Preserve empty parameters (e.g. ESC[;1m) and normalize separators to ';'.
    final tokens = paramsRaw.split(RegExp(r'[;:]'));
    final out = <String>[];

    for (var i = 0; i < tokens.length; i++) {
      final tok = tokens[i];
      final code = int.tryParse(tok);

      if (code == null) {
        // Preserve empty/malformed tokens verbatim.
        out.add(tok);
        continue;
      }

      if (code == 38 || code == 48) {
        final isBg = code == 48;
        final mode = (i + 1 < tokens.length)
            ? int.tryParse(tokens[i + 1])
            : null;

        // 24-bit (semicolon or colon forms; may include colorspace fields).
        if (mode == 2) {
          final nums = <({int pos, int value})>[];
          for (var j = i + 2; j < tokens.length && nums.length < 4; j++) {
            final v = int.tryParse(tokens[j]);
            if (v != null) nums.add((pos: j, value: v));
          }

          if (nums.length < 3) {
            // Can't parse; keep sequence as-is unless ascii (drops colors).
            if (profile != Profile.ascii) out.add(tok);
            continue;
          }

          final rgb = nums.length >= 4
              ? (nums[1].value, nums[2].value, nums[3].value)
              : (nums[0].value, nums[1].value, nums[2].value);

          // Advance i to the last consumed numeric token.
          i = nums.last.pos;

          if (profile == Profile.ascii) {
            continue;
          }
          if (profile == Profile.ansi256) {
            out.add(tok);
            out.add('5');
            out.add('${rgbToAnsi256(rgb.$1, rgb.$2, rgb.$3)}');
            continue;
          }
          if (profile == Profile.ansi) {
            out.add(
              '${_ansi16SgrCode(rgbToAnsi16(rgb.$1, rgb.$2, rgb.$3), background: isBg)}',
            );
            continue;
          }
        }

        // 256-color (semicolon or colon forms).
        if (mode == 5) {
          int? idx;
          var lastPos = i + 1;
          for (var j = i + 2; j < tokens.length; j++) {
            final v = int.tryParse(tokens[j]);
            if (v == null) continue;
            idx = v;
            lastPos = j;
            break;
          }

          if (idx == null) {
            if (profile != Profile.ascii) out.add(tok);
            continue;
          }

          i = lastPos;

          if (profile == Profile.ascii) {
            continue;
          }
          if (profile == Profile.ansi256) {
            out.add(tok);
            out.add('5');
            out.add('$idx');
            continue;
          }
          if (profile == Profile.ansi) {
            out.add(
              '${_ansi16SgrCode(ansi256ToAnsi16(idx), background: isBg)}',
            );
            continue;
          }
        }

        // Unknown 38/48 forms: drop in ascii, keep otherwise.
        if (profile != Profile.ascii) {
          out.add(tok);
        }
        continue;
      }

      // Strip 4-bit colors and default fg/bg in ascii mode.
      if (profile == Profile.ascii && _isAnsiColorCode(code)) {
        continue;
      }

      // Keep non-color codes.
      out.add(tok);
    }

    // If all params were stripped (e.g., colors-only on ascii), use reset.
    if (out.isEmpty) {
      return '\x1B[m';
    }

    return '\x1B[${out.join(';')}m';
  });
}

int _ansi16SgrCode(int idx16, {required bool background}) {
  final i = idx16.clamp(0, 15);
  if (i < 8) {
    return (background ? 40 : 30) + i;
  }
  return (background ? 100 : 90) + (i - 8);
}

bool _isAnsiColorCode(int code) {
  // 4-bit colors.
  if (code >= 30 && code <= 37) return true;
  if (code >= 40 && code <= 47) return true;
  if (code >= 90 && code <= 97) return true;
  if (code >= 100 && code <= 107) return true;
  // Default fg/bg.
  if (code == 39 || code == 49) return true;
  // Extended colors.
  if (code == 38 || code == 48) return true;
  return false;
}
