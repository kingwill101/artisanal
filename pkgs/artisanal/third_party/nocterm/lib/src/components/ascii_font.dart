/// Represents a single ASCII art character glyph.
class AsciiGlyph {
  const AsciiGlyph(this.lines);

  /// The lines that make up this glyph.
  /// Each line should have the same width for proper rendering.
  final List<String> lines;

  /// The width of this glyph in characters.
  int get width => lines.isEmpty ? 0 : lines.first.length;

  /// The height of this glyph in lines.
  int get height => lines.length;
}

/// Abstract base class for ASCII art fonts.
///
/// To create a custom font, extend this class and implement [glyphs]
/// and [height]. Optionally override [letterSpacing] for custom spacing.
///
/// Example:
/// ```dart
/// class MyCustomFont extends AsciiFont {
///   const MyCustomFont();
///
///   @override
///   int get height => 3;
///
///   @override
///   Map<String, AsciiGlyph> get glyphs => {
///     'A': AsciiGlyph([' /\\ ', '/  \\', '----']),
///     // ... more glyphs
///   };
/// }
/// ```
abstract class AsciiFont {
  const AsciiFont();

  /// The height in lines of glyphs in this font.
  int get height;

  /// The spacing between letters in characters.
  int get letterSpacing => 1;

  /// Map of characters to their ASCII art representations.
  Map<String, AsciiGlyph> get glyphs;

  /// Get the glyph for a character, or a fallback if not found.
  AsciiGlyph getGlyph(String char) {
    return glyphs[char.toUpperCase()] ??
        glyphs[char] ??
        _createFallbackGlyph(char);
  }

  /// Creates a simple fallback glyph for unsupported characters.
  AsciiGlyph _createFallbackGlyph(String char) {
    // For space, return empty glyph
    if (char == ' ') {
      return AsciiGlyph(List.generate(height, (_) => '   '));
    }
    // For unknown characters, show the character itself
    final lines = List.generate(height, (i) {
      if (i == height ~/ 2) return ' $char ';
      return '   ';
    });
    return AsciiGlyph(lines);
  }

  // Built-in fonts

  /// Standard block-style ASCII font (5 lines high).
  static const AsciiFont standard = _StandardFont();

  /// Banner-style font with larger characters (7 lines high).
  static const AsciiFont banner = _BannerFont();

  /// Block/shadow style font (6 lines high).
  static const AsciiFont block = _BlockFont();

  /// Slim/thin style font (5 lines high).
  static const AsciiFont slim = _SlimFont();
}

/// Standard ASCII art font - 5 lines high, clean block style.
class _StandardFont extends AsciiFont {
  const _StandardFont();

  @override
  int get height => 5;

  @override
  Map<String, AsciiGlyph> get glyphs => const {
        'A': AsciiGlyph([
          '  █████╗ ',
          ' ██╔══██╗',
          ' ███████║',
          ' ██╔══██║',
          ' ██║  ██║',
        ]),
        'B': AsciiGlyph([
          ' ██████╗ ',
          ' ██╔══██╗',
          ' ██████╔╝',
          ' ██╔══██╗',
          ' ██████╔╝',
        ]),
        'C': AsciiGlyph([
          '  ██████╗',
          ' ██╔════╝',
          ' ██║     ',
          ' ██║     ',
          '  ██████╗',
        ]),
        'D': AsciiGlyph([
          ' ██████╗ ',
          ' ██╔══██╗',
          ' ██║  ██║',
          ' ██║  ██║',
          ' ██████╔╝',
        ]),
        'E': AsciiGlyph([
          ' ███████╗',
          ' ██╔════╝',
          ' █████╗  ',
          ' ██╔══╝  ',
          ' ███████╗',
        ]),
        'F': AsciiGlyph([
          ' ███████╗',
          ' ██╔════╝',
          ' █████╗  ',
          ' ██╔══╝  ',
          ' ██║     ',
        ]),
        'G': AsciiGlyph([
          '  ██████╗ ',
          ' ██╔════╝ ',
          ' ██║  ███╗',
          ' ██║   ██║',
          '  ██████╔╝',
        ]),
        'H': AsciiGlyph([
          ' ██╗  ██╗',
          ' ██║  ██║',
          ' ███████║',
          ' ██╔══██║',
          ' ██║  ██║',
        ]),
        'I': AsciiGlyph([
          ' ██╗',
          ' ██║',
          ' ██║',
          ' ██║',
          ' ██║',
        ]),
        'J': AsciiGlyph([
          '      ██╗',
          '      ██║',
          '      ██║',
          ' ██   ██║',
          '  █████╔╝',
        ]),
        'K': AsciiGlyph([
          ' ██╗  ██╗',
          ' ██║ ██╔╝',
          ' █████╔╝ ',
          ' ██╔═██╗ ',
          ' ██║  ██╗',
        ]),
        'L': AsciiGlyph([
          ' ██╗     ',
          ' ██║     ',
          ' ██║     ',
          ' ██║     ',
          ' ███████╗',
        ]),
        'M': AsciiGlyph([
          ' ███╗   ███╗',
          ' ████╗ ████║',
          ' ██╔████╔██║',
          ' ██║╚██╔╝██║',
          ' ██║ ╚═╝ ██║',
        ]),
        'N': AsciiGlyph([
          ' ███╗   ██╗',
          ' ████╗  ██║',
          ' ██╔██╗ ██║',
          ' ██║╚██╗██║',
          ' ██║ ╚████║',
        ]),
        'O': AsciiGlyph([
          '  ██████╗ ',
          ' ██╔═══██╗',
          ' ██║   ██║',
          ' ██║   ██║',
          '  ██████╔╝',
        ]),
        'P': AsciiGlyph([
          ' ██████╗ ',
          ' ██╔══██╗',
          ' ██████╔╝',
          ' ██╔═══╝ ',
          ' ██║     ',
        ]),
        'Q': AsciiGlyph([
          '  ██████╗ ',
          ' ██╔═══██╗',
          ' ██║   ██║',
          ' ██║▄▄ ██║',
          '  ██████╔╝',
        ]),
        'R': AsciiGlyph([
          ' ██████╗ ',
          ' ██╔══██╗',
          ' ██████╔╝',
          ' ██╔══██╗',
          ' ██║  ██║',
        ]),
        'S': AsciiGlyph([
          ' ███████╗',
          ' ██╔════╝',
          ' ███████╗',
          ' ╚════██║',
          ' ███████║',
        ]),
        'T': AsciiGlyph([
          ' ████████╗',
          ' ╚══██╔══╝',
          '    ██║   ',
          '    ██║   ',
          '    ██║   ',
        ]),
        'U': AsciiGlyph([
          ' ██╗   ██╗',
          ' ██║   ██║',
          ' ██║   ██║',
          ' ██║   ██║',
          '  █████╔╝ ',
        ]),
        'V': AsciiGlyph([
          ' ██╗   ██╗',
          ' ██║   ██║',
          ' ██║   ██║',
          '  ██╗ ██╔╝',
          '   ╚██╔╝  ',
        ]),
        'W': AsciiGlyph([
          ' ██╗    ██╗',
          ' ██║    ██║',
          ' ██║ █╗ ██║',
          ' ██║███╗██║',
          '  ███╔███╔╝',
        ]),
        'X': AsciiGlyph([
          ' ██╗  ██╗',
          '  ██╗██╔╝',
          '   ███╔╝ ',
          '  ██╔██╗ ',
          ' ██╔╝ ██╗',
        ]),
        'Y': AsciiGlyph([
          ' ██╗   ██╗',
          '  ██╗ ██╔╝',
          '   ╚██╔╝  ',
          '    ██║   ',
          '    ██║   ',
        ]),
        'Z': AsciiGlyph([
          ' ███████╗',
          ' ╚════██║',
          '   ███╔═╝',
          '  ██╔══╝ ',
          ' ███████╗',
        ]),
        '0': AsciiGlyph([
          '  ██████╗ ',
          ' ██╔═████╗',
          ' ██║██╔██║',
          ' ████╔╝██║',
          '  ██████╔╝',
        ]),
        '1': AsciiGlyph([
          '  ██╗',
          ' ███║',
          ' ╚██║',
          '  ██║',
          '  ██║',
        ]),
        '2': AsciiGlyph([
          ' ██████╗ ',
          ' ╚════██╗',
          '  █████╔╝',
          ' ██╔═══╝ ',
          ' ███████╗',
        ]),
        '3': AsciiGlyph([
          ' ██████╗ ',
          ' ╚════██╗',
          '  █████╔╝',
          ' ╚════██╗',
          ' ██████╔╝',
        ]),
        '4': AsciiGlyph([
          ' ██╗  ██╗',
          ' ██║  ██║',
          ' ███████║',
          ' ╚════██║',
          '      ██║',
        ]),
        '5': AsciiGlyph([
          ' ███████╗',
          ' ██╔════╝',
          ' ███████╗',
          ' ╚════██║',
          ' ███████║',
        ]),
        '6': AsciiGlyph([
          '  ██████╗',
          ' ██╔════╝',
          ' ███████╗',
          ' ██╔══██║',
          '  █████╔╝',
        ]),
        '7': AsciiGlyph([
          ' ███████╗',
          ' ╚════██║',
          '     ██╔╝',
          '    ██╔╝ ',
          '    ██║  ',
        ]),
        '8': AsciiGlyph([
          '  █████╗ ',
          ' ██╔══██╗',
          '  █████╔╝',
          ' ██╔══██╗',
          '  █████╔╝',
        ]),
        '9': AsciiGlyph([
          '  █████╗ ',
          ' ██╔══██╗',
          '  ██████║',
          ' ╚════██║',
          '  █████╔╝',
        ]),
        '!': AsciiGlyph([
          ' ██╗',
          ' ██║',
          ' ██║',
          ' ╚═╝',
          ' ██╗',
        ]),
        '?': AsciiGlyph([
          ' ██████╗ ',
          ' ╚════██╗',
          '   ▄███╔╝',
          '   ▀▀══╝ ',
          '   ██╗   ',
        ]),
        '.': AsciiGlyph([
          '    ',
          '    ',
          '    ',
          '    ',
          ' ██╗',
        ]),
        ',': AsciiGlyph([
          '    ',
          '    ',
          '    ',
          ' ▄█╗',
          ' ▀═╝',
        ]),
        '-': AsciiGlyph([
          '      ',
          '      ',
          ' ████╗',
          ' ╚═══╝',
          '      ',
        ]),
        '_': AsciiGlyph([
          '        ',
          '        ',
          '        ',
          '        ',
          ' ██████╗',
        ]),
        ':': AsciiGlyph([
          '    ',
          ' ██╗',
          ' ╚═╝',
          ' ██╗',
          ' ╚═╝',
        ]),
        ';': AsciiGlyph([
          '    ',
          ' ██╗',
          ' ╚═╝',
          ' ▄█╗',
          ' ▀═╝',
        ]),
        '(': AsciiGlyph([
          '  ██╗',
          ' ██╔╝',
          ' ██║ ',
          ' ██╔╝',
          '  ██╗',
        ]),
        ')': AsciiGlyph([
          ' ██╗ ',
          ' ╚██╗',
          '  ██║',
          ' ╚██╗',
          ' ██╗ ',
        ]),
        '[': AsciiGlyph([
          ' ███╗',
          ' ██╔╝',
          ' ██║ ',
          ' ██║ ',
          ' ███╗',
        ]),
        ']': AsciiGlyph([
          ' ███╗',
          ' ╚██║',
          '  ██║',
          '  ██║',
          ' ███╗',
        ]),
        '/': AsciiGlyph([
          '     ██╗',
          '    ██╔╝',
          '   ██╔╝ ',
          '  ██╔╝  ',
          ' ██╔╝   ',
        ]),
        '\\': AsciiGlyph([
          ' ██╗    ',
          ' ╚██╗   ',
          '  ╚██╗  ',
          '   ╚██╗ ',
          '    ╚██╗',
        ]),
        '+': AsciiGlyph([
          '       ',
          '   █╗  ',
          ' █████╗',
          '   █╔╝ ',
          '       ',
        ]),
        '=': AsciiGlyph([
          '       ',
          ' █████╗',
          ' ╚════╝',
          ' █████╗',
          ' ╚════╝',
        ]),
        '*': AsciiGlyph([
          '      ',
          ' ╲ ╱ ',
          '  ╳  ',
          ' ╱ ╲ ',
          '      ',
        ]),
        '#': AsciiGlyph([
          '  █ █  ',
          ' █████ ',
          '  █ █  ',
          ' █████ ',
          '  █ █  ',
        ]),
        '@': AsciiGlyph([
          '  █████╗ ',
          ' ██╔══██╗',
          ' ██║████║',
          ' ██║╚═══╝',
          '  █████╗ ',
        ]),
        '&': AsciiGlyph([
          '  ███╗  ',
          ' ██╔═╝  ',
          '  ███╗██╗',
          ' ██╔███╔╝',
          '  ███╔═╝ ',
        ]),
        '%': AsciiGlyph([
          ' █╗  ██╗',
          ' ╚╝ ██╔╝',
          '   ██╔╝ ',
          '  ██╔╝█╗',
          ' ██╔╝ ╚╝',
        ]),
        '\$': AsciiGlyph([
          '   █╗   ',
          ' ██████╗',
          '  ████╔╝',
          ' ██████╗',
          '   █╔══╝',
        ]),
        '^': AsciiGlyph([
          '  ██╗ ',
          ' ██╔██╗',
          ' ╚╝ ╚═╝',
          '      ',
          '      ',
        ]),
        '~': AsciiGlyph([
          '       ',
          ' ██╗██╗',
          ' ╚███╔╝',
          '  ╚══╝ ',
          '       ',
        ]),
        '`': AsciiGlyph([
          ' ██╗',
          ' ╚█╝',
          '    ',
          '    ',
          '    ',
        ]),
        "'": AsciiGlyph([
          ' ██╗',
          ' ╚█╝',
          '    ',
          '    ',
          '    ',
        ]),
        '"': AsciiGlyph([
          ' ██╗██╗',
          ' ╚█╝╚█╝',
          '       ',
          '       ',
          '       ',
        ]),
        '<': AsciiGlyph([
          '   ██╗',
          '  ██╔╝',
          ' ██╔╝ ',
          '  ██╗ ',
          '   ██╗',
        ]),
        '>': AsciiGlyph([
          ' ██╗  ',
          ' ╚██╗ ',
          '  ╚██╗',
          '  ██╔╝',
          ' ██╔╝ ',
        ]),
        '{': AsciiGlyph([
          '   ██╗',
          '  ██╔╝',
          ' ██╔╝ ',
          '  ██╗ ',
          '   ██╗',
        ]),
        '}': AsciiGlyph([
          ' ██╗  ',
          ' ╚██╗ ',
          '  ╚██╗',
          '  ██╔╝',
          ' ██╔╝ ',
        ]),
        '|': AsciiGlyph([
          ' ██╗',
          ' ██║',
          ' ██║',
          ' ██║',
          ' ██║',
        ]),
      };
}

/// Banner-style ASCII font - 7 lines high, prominent display.
class _BannerFont extends AsciiFont {
  const _BannerFont();

  @override
  int get height => 7;

  @override
  int get letterSpacing => 2;

  @override
  Map<String, AsciiGlyph> get glyphs => const {
        'A': AsciiGlyph([
          '   ###   ',
          '  ## ##  ',
          ' ##   ## ',
          ' ##   ## ',
          ' ####### ',
          ' ##   ## ',
          ' ##   ## ',
        ]),
        'B': AsciiGlyph([
          ' #####  ',
          ' ##  ## ',
          ' ##  ## ',
          ' #####  ',
          ' ##  ## ',
          ' ##  ## ',
          ' #####  ',
        ]),
        'C': AsciiGlyph([
          '  ##### ',
          ' ##   ##',
          ' ##     ',
          ' ##     ',
          ' ##     ',
          ' ##   ##',
          '  ##### ',
        ]),
        'D': AsciiGlyph([
          ' ####   ',
          ' ## ##  ',
          ' ##  ## ',
          ' ##  ## ',
          ' ##  ## ',
          ' ## ##  ',
          ' ####   ',
        ]),
        'E': AsciiGlyph([
          ' #######',
          ' ##     ',
          ' ##     ',
          ' #####  ',
          ' ##     ',
          ' ##     ',
          ' #######',
        ]),
        'F': AsciiGlyph([
          ' #######',
          ' ##     ',
          ' ##     ',
          ' #####  ',
          ' ##     ',
          ' ##     ',
          ' ##     ',
        ]),
        'G': AsciiGlyph([
          '  ##### ',
          ' ##   ##',
          ' ##     ',
          ' ## ####',
          ' ##   ##',
          ' ##   ##',
          '  ##### ',
        ]),
        'H': AsciiGlyph([
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          ' #######',
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
        ]),
        'I': AsciiGlyph([
          ' #####',
          '  ##  ',
          '  ##  ',
          '  ##  ',
          '  ##  ',
          '  ##  ',
          ' #####',
        ]),
        'J': AsciiGlyph([
          '   ####',
          '     ##',
          '     ##',
          '     ##',
          ' ##  ##',
          ' ##  ##',
          '  #### ',
        ]),
        'K': AsciiGlyph([
          ' ##   ##',
          ' ##  ## ',
          ' ## ##  ',
          ' ####   ',
          ' ## ##  ',
          ' ##  ## ',
          ' ##   ##',
        ]),
        'L': AsciiGlyph([
          ' ##     ',
          ' ##     ',
          ' ##     ',
          ' ##     ',
          ' ##     ',
          ' ##     ',
          ' #######',
        ]),
        'M': AsciiGlyph([
          ' ##    ##',
          ' ###  ###',
          ' ## ## ##',
          ' ##    ##',
          ' ##    ##',
          ' ##    ##',
          ' ##    ##',
        ]),
        'N': AsciiGlyph([
          ' ##   ##',
          ' ###  ##',
          ' #### ##',
          ' ## ####',
          ' ##  ###',
          ' ##   ##',
          ' ##   ##',
        ]),
        'O': AsciiGlyph([
          '  ##### ',
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          '  ##### ',
        ]),
        'P': AsciiGlyph([
          ' ###### ',
          ' ##   ##',
          ' ##   ##',
          ' ###### ',
          ' ##     ',
          ' ##     ',
          ' ##     ',
        ]),
        'Q': AsciiGlyph([
          '  ##### ',
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          ' ## # ##',
          ' ##  ## ',
          '  ### ##',
        ]),
        'R': AsciiGlyph([
          ' ###### ',
          ' ##   ##',
          ' ##   ##',
          ' ###### ',
          ' ## ##  ',
          ' ##  ## ',
          ' ##   ##',
        ]),
        'S': AsciiGlyph([
          '  ##### ',
          ' ##   ##',
          ' ##     ',
          '  ##### ',
          '      ##',
          ' ##   ##',
          '  ##### ',
        ]),
        'T': AsciiGlyph([
          ' #######',
          '   ##   ',
          '   ##   ',
          '   ##   ',
          '   ##   ',
          '   ##   ',
          '   ##   ',
        ]),
        'U': AsciiGlyph([
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          '  ##### ',
        ]),
        'V': AsciiGlyph([
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          ' ##   ##',
          '  ## ## ',
          '   ###  ',
          '    #   ',
        ]),
        'W': AsciiGlyph([
          ' ##    ##',
          ' ##    ##',
          ' ##    ##',
          ' ##    ##',
          ' ## ## ##',
          ' ###  ###',
          ' ##    ##',
        ]),
        'X': AsciiGlyph([
          ' ##   ##',
          '  ## ## ',
          '   ###  ',
          '   ###  ',
          '  ## ## ',
          ' ##   ##',
          ' ##   ##',
        ]),
        'Y': AsciiGlyph([
          ' ##   ##',
          '  ## ## ',
          '   ###  ',
          '   ##   ',
          '   ##   ',
          '   ##   ',
          '   ##   ',
        ]),
        'Z': AsciiGlyph([
          ' #######',
          '     ## ',
          '    ##  ',
          '   ##   ',
          '  ##    ',
          ' ##     ',
          ' #######',
        ]),
        '0': AsciiGlyph([
          '  ##### ',
          ' ##   ##',
          ' ##  ###',
          ' ## # ##',
          ' ###  ##',
          ' ##   ##',
          '  ##### ',
        ]),
        '1': AsciiGlyph([
          '   ##  ',
          '  ###  ',
          '   ##  ',
          '   ##  ',
          '   ##  ',
          '   ##  ',
          ' ######',
        ]),
        '2': AsciiGlyph([
          '  ##### ',
          ' ##   ##',
          '      ##',
          '   #### ',
          '  ##    ',
          ' ##     ',
          ' #######',
        ]),
        '3': AsciiGlyph([
          '  ##### ',
          ' ##   ##',
          '      ##',
          '   #### ',
          '      ##',
          ' ##   ##',
          '  ##### ',
        ]),
        '4': AsciiGlyph([
          '    ### ',
          '   # ## ',
          '  #  ## ',
          ' #   ## ',
          ' #######',
          '     ## ',
          '     ## ',
        ]),
        '5': AsciiGlyph([
          ' #######',
          ' ##     ',
          ' ###### ',
          '      ##',
          '      ##',
          ' ##   ##',
          '  ##### ',
        ]),
        '6': AsciiGlyph([
          '  ##### ',
          ' ##     ',
          ' ##     ',
          ' ###### ',
          ' ##   ##',
          ' ##   ##',
          '  ##### ',
        ]),
        '7': AsciiGlyph([
          ' #######',
          '      ##',
          '     ## ',
          '    ##  ',
          '   ##   ',
          '   ##   ',
          '   ##   ',
        ]),
        '8': AsciiGlyph([
          '  ##### ',
          ' ##   ##',
          ' ##   ##',
          '  ##### ',
          ' ##   ##',
          ' ##   ##',
          '  ##### ',
        ]),
        '9': AsciiGlyph([
          '  ##### ',
          ' ##   ##',
          ' ##   ##',
          '  ######',
          '      ##',
          '      ##',
          '  ##### ',
        ]),
        '!': AsciiGlyph([
          ' ## ',
          ' ## ',
          ' ## ',
          ' ## ',
          '    ',
          ' ## ',
          ' ## ',
        ]),
        '?': AsciiGlyph([
          ' ##### ',
          ' #   # ',
          '     # ',
          '   ##  ',
          '   ##  ',
          '       ',
          '   ##  ',
        ]),
        '.': AsciiGlyph([
          '    ',
          '    ',
          '    ',
          '    ',
          '    ',
          ' ## ',
          ' ## ',
        ]),
        ',': AsciiGlyph([
          '    ',
          '    ',
          '    ',
          '    ',
          ' ## ',
          ' ## ',
          '#   ',
        ]),
        '-': AsciiGlyph([
          '      ',
          '      ',
          '      ',
          ' #####',
          '      ',
          '      ',
          '      ',
        ]),
        ' ': AsciiGlyph([
          '    ',
          '    ',
          '    ',
          '    ',
          '    ',
          '    ',
          '    ',
        ]),
      };
}

/// Block-style ASCII font - 6 lines high, bold appearance.
class _BlockFont extends AsciiFont {
  const _BlockFont();

  @override
  int get height => 6;

  @override
  int get letterSpacing => 1;

  @override
  Map<String, AsciiGlyph> get glyphs => const {
        'A': AsciiGlyph([
          ' ████ ',
          '██  ██',
          '██████',
          '██  ██',
          '██  ██',
          '██  ██',
        ]),
        'B': AsciiGlyph([
          '█████ ',
          '██  ██',
          '█████ ',
          '██  ██',
          '██  ██',
          '█████ ',
        ]),
        'C': AsciiGlyph([
          ' █████',
          '██    ',
          '██    ',
          '██    ',
          '██    ',
          ' █████',
        ]),
        'D': AsciiGlyph([
          '████  ',
          '██  ██',
          '██  ██',
          '██  ██',
          '██  ██',
          '████  ',
        ]),
        'E': AsciiGlyph([
          '██████',
          '██    ',
          '████  ',
          '██    ',
          '██    ',
          '██████',
        ]),
        'F': AsciiGlyph([
          '██████',
          '██    ',
          '████  ',
          '██    ',
          '██    ',
          '██    ',
        ]),
        'G': AsciiGlyph([
          ' █████',
          '██    ',
          '██ ███',
          '██  ██',
          '██  ██',
          ' █████',
        ]),
        'H': AsciiGlyph([
          '██  ██',
          '██  ██',
          '██████',
          '██  ██',
          '██  ██',
          '██  ██',
        ]),
        'I': AsciiGlyph([
          '████',
          ' ██ ',
          ' ██ ',
          ' ██ ',
          ' ██ ',
          '████',
        ]),
        'J': AsciiGlyph([
          '   ██',
          '   ██',
          '   ██',
          '   ██',
          '██ ██',
          ' ███ ',
        ]),
        'K': AsciiGlyph([
          '██  ██',
          '██ ██ ',
          '████  ',
          '██ ██ ',
          '██  ██',
          '██  ██',
        ]),
        'L': AsciiGlyph([
          '██    ',
          '██    ',
          '██    ',
          '██    ',
          '██    ',
          '██████',
        ]),
        'M': AsciiGlyph([
          '██   ██',
          '███ ███',
          '███████',
          '██ █ ██',
          '██   ██',
          '██   ██',
        ]),
        'N': AsciiGlyph([
          '██  ██',
          '███ ██',
          '██████',
          '██ ███',
          '██  ██',
          '██  ██',
        ]),
        'O': AsciiGlyph([
          ' ████ ',
          '██  ██',
          '██  ██',
          '██  ██',
          '██  ██',
          ' ████ ',
        ]),
        'P': AsciiGlyph([
          '█████ ',
          '██  ██',
          '█████ ',
          '██    ',
          '██    ',
          '██    ',
        ]),
        'Q': AsciiGlyph([
          ' ████ ',
          '██  ██',
          '██  ██',
          '██ ███',
          '██  █ ',
          ' ██ ██',
        ]),
        'R': AsciiGlyph([
          '█████ ',
          '██  ██',
          '█████ ',
          '██ ██ ',
          '██  ██',
          '██  ██',
        ]),
        'S': AsciiGlyph([
          ' █████',
          '██    ',
          ' ████ ',
          '    ██',
          '    ██',
          '█████ ',
        ]),
        'T': AsciiGlyph([
          '██████',
          '  ██  ',
          '  ██  ',
          '  ██  ',
          '  ██  ',
          '  ██  ',
        ]),
        'U': AsciiGlyph([
          '██  ██',
          '██  ██',
          '██  ██',
          '██  ██',
          '██  ██',
          ' ████ ',
        ]),
        'V': AsciiGlyph([
          '██  ██',
          '██  ██',
          '██  ██',
          '██  ██',
          ' ████ ',
          '  ██  ',
        ]),
        'W': AsciiGlyph([
          '██   ██',
          '██   ██',
          '██ █ ██',
          '███████',
          '███ ███',
          '██   ██',
        ]),
        'X': AsciiGlyph([
          '██  ██',
          ' ████ ',
          '  ██  ',
          ' ████ ',
          '██  ██',
          '██  ██',
        ]),
        'Y': AsciiGlyph([
          '██  ██',
          ' ████ ',
          '  ██  ',
          '  ██  ',
          '  ██  ',
          '  ██  ',
        ]),
        'Z': AsciiGlyph([
          '██████',
          '   ██ ',
          '  ██  ',
          ' ██   ',
          '██    ',
          '██████',
        ]),
        '0': AsciiGlyph([
          ' ████ ',
          '██  ██',
          '██ ███',
          '███ ██',
          '██  ██',
          ' ████ ',
        ]),
        '1': AsciiGlyph([
          ' ██ ',
          '███ ',
          ' ██ ',
          ' ██ ',
          ' ██ ',
          '████',
        ]),
        '2': AsciiGlyph([
          ' ████ ',
          '██  ██',
          '   ██ ',
          '  ██  ',
          ' ██   ',
          '██████',
        ]),
        '3': AsciiGlyph([
          ' ████ ',
          '██  ██',
          '   ██ ',
          '   ██ ',
          '██  ██',
          ' ████ ',
        ]),
        '4': AsciiGlyph([
          '██  ██',
          '██  ██',
          '██████',
          '    ██',
          '    ██',
          '    ██',
        ]),
        '5': AsciiGlyph([
          '██████',
          '██    ',
          '█████ ',
          '    ██',
          '    ██',
          '█████ ',
        ]),
        '6': AsciiGlyph([
          ' ████ ',
          '██    ',
          '█████ ',
          '██  ██',
          '██  ██',
          ' ████ ',
        ]),
        '7': AsciiGlyph([
          '██████',
          '    ██',
          '   ██ ',
          '  ██  ',
          '  ██  ',
          '  ██  ',
        ]),
        '8': AsciiGlyph([
          ' ████ ',
          '██  ██',
          ' ████ ',
          '██  ██',
          '██  ██',
          ' ████ ',
        ]),
        '9': AsciiGlyph([
          ' ████ ',
          '██  ██',
          ' █████',
          '    ██',
          '    ██',
          ' ████ ',
        ]),
        '!': AsciiGlyph([
          '██',
          '██',
          '██',
          '██',
          '  ',
          '██',
        ]),
        '?': AsciiGlyph([
          ' ████ ',
          '██  ██',
          '   ██ ',
          '  ██  ',
          '      ',
          '  ██  ',
        ]),
        '.': AsciiGlyph([
          '  ',
          '  ',
          '  ',
          '  ',
          '  ',
          '██',
        ]),
        ',': AsciiGlyph([
          '  ',
          '  ',
          '  ',
          '  ',
          '██',
          '█ ',
        ]),
        '-': AsciiGlyph([
          '    ',
          '    ',
          '████',
          '    ',
          '    ',
          '    ',
        ]),
        ' ': AsciiGlyph([
          '   ',
          '   ',
          '   ',
          '   ',
          '   ',
          '   ',
        ]),
      };
}

/// Slim/thin ASCII art font - 5 lines high, minimalist style.
class _SlimFont extends AsciiFont {
  const _SlimFont();

  @override
  int get height => 5;

  @override
  int get letterSpacing => 1;

  @override
  Map<String, AsciiGlyph> get glyphs => const {
        'A': AsciiGlyph([
          ' ▄▀▄ ',
          '█▀▀▀█',
          '█   █',
          '█   █',
          '▀   ▀',
        ]),
        'B': AsciiGlyph([
          '█▀▀▄',
          '█▀▀▄',
          '█  █',
          '█▄▄▀',
          '    ',
        ]),
        'C': AsciiGlyph([
          ' ▄▀▀',
          '█   ',
          '█   ',
          ' ▀▄▄',
          '    ',
        ]),
        'D': AsciiGlyph([
          '█▀▀▄',
          '█  █',
          '█  █',
          '█▄▄▀',
          '    ',
        ]),
        'E': AsciiGlyph([
          '█▀▀▀',
          '█▀▀ ',
          '█   ',
          '█▄▄▄',
          '    ',
        ]),
        'F': AsciiGlyph([
          '█▀▀▀',
          '█▀▀ ',
          '█   ',
          '█   ',
          '    ',
        ]),
        'G': AsciiGlyph([
          ' ▄▀▀ ',
          '█    ',
          '█  ▀█',
          ' ▀▀▀ ',
          '     ',
        ]),
        'H': AsciiGlyph([
          '█  █',
          '█▀▀█',
          '█  █',
          '▀  ▀',
          '    ',
        ]),
        'I': AsciiGlyph([
          '▀█▀',
          ' █ ',
          ' █ ',
          '▄█▄',
          '   ',
        ]),
        'J': AsciiGlyph([
          '   █',
          '   █',
          '▄  █',
          ' ▀▀ ',
          '    ',
        ]),
        'K': AsciiGlyph([
          '█ ▄▀',
          '██  ',
          '█ ▀▄',
          '▀   ',
          '    ',
        ]),
        'L': AsciiGlyph([
          '█   ',
          '█   ',
          '█   ',
          '█▄▄▄',
          '    ',
        ]),
        'M': AsciiGlyph([
          '█▄ ▄█',
          '█ ▀ █',
          '█   █',
          '▀   ▀',
          '     ',
        ]),
        'N': AsciiGlyph([
          '█▄  █',
          '█ █ █',
          '█  ▀█',
          '▀   ▀',
          '     ',
        ]),
        'O': AsciiGlyph([
          ' ▄▀▄ ',
          '█   █',
          '█   █',
          ' ▀▄▀ ',
          '     ',
        ]),
        'P': AsciiGlyph([
          '█▀▀▄',
          '█▄▄▀',
          '█   ',
          '▀   ',
          '    ',
        ]),
        'Q': AsciiGlyph([
          ' ▄▀▄ ',
          '█   █',
          '█  ▄█',
          ' ▀▄▀▄',
          '     ',
        ]),
        'R': AsciiGlyph([
          '█▀▀▄',
          '█▄▄▀',
          '█  █',
          '▀  ▀',
          '    ',
        ]),
        'S': AsciiGlyph([
          ' ▄▀▀',
          ' ▀▄ ',
          '   █',
          '▀▀▀ ',
          '    ',
        ]),
        'T': AsciiGlyph([
          '▀▀█▀▀',
          '  █  ',
          '  █  ',
          '  ▀  ',
          '     ',
        ]),
        'U': AsciiGlyph([
          '█   █',
          '█   █',
          '█   █',
          ' ▀▀▀ ',
          '     ',
        ]),
        'V': AsciiGlyph([
          '█   █',
          '█   █',
          ' █ █ ',
          '  ▀  ',
          '     ',
        ]),
        'W': AsciiGlyph([
          '█   █',
          '█ ▄ █',
          '█▀ ▀█',
          '▀   ▀',
          '     ',
        ]),
        'X': AsciiGlyph([
          '█   █',
          ' ▀▄▀ ',
          ' ▄▀▄ ',
          '▀   ▀',
          '     ',
        ]),
        'Y': AsciiGlyph([
          '█   █',
          ' ▀▄▀ ',
          '  █  ',
          '  ▀  ',
          '     ',
        ]),
        'Z': AsciiGlyph([
          '▀▀▀█',
          '  █ ',
          ' █  ',
          '█▄▄▄',
          '    ',
        ]),
        '0': AsciiGlyph([
          ' ▄▀▄ ',
          '█ ▄ █',
          '█ ▀ █',
          ' ▀▄▀ ',
          '     ',
        ]),
        '1': AsciiGlyph([
          ' ▄█',
          '  █',
          '  █',
          ' ▄█▄',
          '   ',
        ]),
        '2': AsciiGlyph([
          '▀▀▄',
          ' ▄▀',
          '▄▀ ',
          '▀▀▀',
          '   ',
        ]),
        '3': AsciiGlyph([
          '▀▀▄',
          ' ▀▄',
          '  █',
          '▀▀ ',
          '   ',
        ]),
        '4': AsciiGlyph([
          '█  █',
          '▀▀▀█',
          '   █',
          '   ▀',
          '    ',
        ]),
        '5': AsciiGlyph([
          '█▀▀',
          '▀▀▄',
          '  █',
          '▀▀ ',
          '   ',
        ]),
        '6': AsciiGlyph([
          ' ▄▀',
          '█▀▄',
          '█ █',
          ' ▀ ',
          '   ',
        ]),
        '7': AsciiGlyph([
          '▀▀█',
          ' ▄▀',
          ' █ ',
          ' ▀ ',
          '   ',
        ]),
        '8': AsciiGlyph([
          ' ▄▀▄',
          ' ▄▀▄',
          '█   █',
          ' ▀▄▀',
          '    ',
        ]),
        '9': AsciiGlyph([
          ' ▄▀▄',
          '█  █',
          ' ▀▀█',
          '▀▀▀ ',
          '    ',
        ]),
        '!': AsciiGlyph([
          '█',
          '█',
          ' ',
          '▀',
          ' ',
        ]),
        '?': AsciiGlyph([
          '▀▀▄',
          ' ▄▀',
          '   ',
          ' ▀ ',
          '   ',
        ]),
        '.': AsciiGlyph([
          ' ',
          ' ',
          ' ',
          '▀',
          ' ',
        ]),
        ',': AsciiGlyph([
          ' ',
          ' ',
          '▄',
          '▀',
          ' ',
        ]),
        '-': AsciiGlyph([
          '   ',
          '▀▀▀',
          '   ',
          '   ',
          '   ',
        ]),
        ' ': AsciiGlyph([
          '  ',
          '  ',
          '  ',
          '  ',
          '  ',
        ]),
      };
}
