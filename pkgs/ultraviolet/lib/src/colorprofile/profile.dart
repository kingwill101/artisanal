library;

/// Internal terminal color profile representation.
///
/// This mirrors the upstream charmbracelet/colorprofile model:
/// - [noTty]: no ANSI output should be emitted (strip all escapes)
/// - [ascii]: no colors, but text decorations may be used
/// - [ansi]/[ansi256]/[trueColor]: progressively richer color support
enum Profile { unknown, noTty, ascii, ansi, ansi256, trueColor }

extension ProfileOrdering on Profile {
  bool operator <(Profile other) => index < other.index;
  bool operator <=(Profile other) => index <= other.index;
  bool operator >(Profile other) => index > other.index;
  bool operator >=(Profile other) => index >= other.index;

  static Profile max(Profile a, Profile b) => a >= b ? a : b;
}
