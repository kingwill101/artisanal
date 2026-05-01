/// Syntax highlighting for code blocks.
///
/// Provides Chroma-style syntax highlighting using the highlight.dart package,
/// with support for custom color themes using artisanal's Style system.
library;

import 'package:highlight/highlight.dart' show highlight, Node;

import '../../style/style.dart';
import '../../style/color.dart' show BasicColor;
import '../../unicode/grapheme.dart' as uni;
import 'fence_language_resolver.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chroma-Style Color Theme
// ─────────────────────────────────────────────────────────────────────────────

/// Configuration for syntax highlighting colors.
///
/// Inspired by Glamour's Chroma integration, this provides granular control
/// over token colors for syntax highlighting using artisanal's Style system.
///
/// ```dart
/// final theme = ChromaTheme.dark;
///
/// // Or create a custom theme
/// final customTheme = ChromaTheme(
///   keyword: Style().foreground(Colors.blue).bold(),
///   string: Style().foreground(Colors.green),
///   comment: Style().foreground(Colors.gray).italic(),
/// );
/// ```
class ChromaTheme {
  const ChromaTheme({
    this.text,
    this.error,
    this.comment,
    this.commentPreproc,
    this.keyword,
    this.keywordReserved,
    this.keywordNamespace,
    this.keywordType,
    this.operator,
    this.punctuation,
    this.name,
    this.nameBuiltin,
    this.nameTag,
    this.nameAttribute,
    this.nameClass,
    this.nameConstant,
    this.nameDecorator,
    this.nameException,
    this.nameFunction,
    this.nameOther,
    this.literal,
    this.literalNumber,
    this.literalDate,
    this.literalString,
    this.literalStringEscape,
    this.genericDeleted,
    this.genericEmph,
    this.genericInserted,
    this.genericStrong,
    this.genericSubheading,
    this.background,
  });

  final Style? text;
  final Style? error;
  final Style? comment;
  final Style? commentPreproc;
  final Style? keyword;
  final Style? keywordReserved;
  final Style? keywordNamespace;
  final Style? keywordType;
  final Style? operator;
  final Style? punctuation;
  final Style? name;
  final Style? nameBuiltin;
  final Style? nameTag;
  final Style? nameAttribute;
  final Style? nameClass;
  final Style? nameConstant;
  final Style? nameDecorator;
  final Style? nameException;
  final Style? nameFunction;
  final Style? nameOther;
  final Style? literal;
  final Style? literalNumber;
  final Style? literalDate;
  final Style? literalString;
  final Style? literalStringEscape;
  final Style? genericDeleted;
  final Style? genericEmph;
  final Style? genericInserted;
  final Style? genericStrong;
  final Style? genericSubheading;
  final Style? background;

  /// Default dark theme inspired by Glamour/Charm.
  ///
  /// Colors are chosen to work well on dark terminal backgrounds.
  static ChromaTheme get dark => ChromaTheme(
    text: Style().foreground(BasicColor('#C4C4C4')),
    error: Style()
        .foreground(BasicColor('#F1F1F1'))
        .background(BasicColor('#F05B5B')),
    comment: Style().foreground(BasicColor('#676767')),
    commentPreproc: Style().foreground(BasicColor('#FF875F')),
    keyword: Style().foreground(BasicColor('#00AAFF')),
    keywordReserved: Style().foreground(BasicColor('#FF5FD2')),
    keywordNamespace: Style().foreground(BasicColor('#FF5F87')),
    keywordType: Style().foreground(BasicColor('#6E6ED8')),
    operator: Style().foreground(BasicColor('#EF8080')),
    punctuation: Style().foreground(BasicColor('#E8E8A8')),
    name: Style().foreground(BasicColor('#C4C4C4')),
    nameBuiltin: Style().foreground(BasicColor('#FF8EC7')),
    nameTag: Style().foreground(BasicColor('#B083EA')),
    nameAttribute: Style().foreground(BasicColor('#7A7AE6')),
    nameClass: Style().foreground(BasicColor('#F1F1F1')).underline().bold(),
    nameConstant: Style().foreground(BasicColor('#C4C4C4')),
    nameDecorator: Style().foreground(BasicColor('#FFFF87')),
    nameException: Style().foreground(BasicColor('#FF5F87')),
    nameFunction: Style().foreground(BasicColor('#00D787')),
    nameOther: Style().foreground(BasicColor('#C4C4C4')),
    literal: Style().foreground(BasicColor('#C4C4C4')),
    literalNumber: Style().foreground(BasicColor('#6EEFC0')),
    literalDate: Style().foreground(BasicColor('#C4C4C4')),
    literalString: Style().foreground(BasicColor('#C69669')),
    literalStringEscape: Style().foreground(BasicColor('#AFFFD7')),
    genericDeleted: Style().foreground(BasicColor('#FD5B5B')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#00D787')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#777777')),
    background: Style().background(BasicColor('#373737')),
  );

  /// Creates a theme from a JSON map.
  factory ChromaTheme.fromJson(Map<String, dynamic> json) {
    Style? parse(String key) {
      if (!json.containsKey(key)) return null;
      final val = json[key];
      if (val is Map<String, dynamic>) {
        return _parseStyle(val);
      }
      return null;
    }

    return ChromaTheme(
      text: parse('text'),
      error: parse('error'),
      comment: parse('comment'),
      commentPreproc: parse('comment_preproc'),
      keyword: parse('keyword'),
      keywordReserved: parse('keyword_reserved'),
      keywordNamespace: parse('keyword_namespace'),
      keywordType: parse('keyword_type'),
      operator: parse('operator'),
      punctuation: parse('punctuation'),
      name: parse('name'),
      nameBuiltin: parse('name_builtin'),
      nameTag: parse('name_tag'),
      nameAttribute: parse('name_attribute'),
      nameClass: parse('name_class'),
      nameConstant: parse('name_constant'),
      nameDecorator: parse('name_decorator'),
      nameException: parse('name_exception'),
      nameFunction: parse('name_function'),
      nameOther: parse('name_other'),
      literal: parse('literal'),
      literalNumber: parse('literal_number'),
      literalDate: parse('literal_date'),
      literalString: parse('literal_string'),
      literalStringEscape: parse('literal_string_escape'),
      genericDeleted: parse('generic_deleted'),
      genericEmph: parse('generic_emph'),
      genericInserted: parse('generic_inserted'),
      genericStrong: parse('generic_strong'),
      genericSubheading: parse('generic_subheading'),
      background: parse('background'),
    );
  }

  /// Light theme for light terminal backgrounds.
  static ChromaTheme get light => ChromaTheme(
    text: Style().foreground(BasicColor('#333333')),
    error: Style()
        .foreground(BasicColor('#FFFFFF'))
        .background(BasicColor('#CC0000')),
    comment: Style().foreground(BasicColor('#888888')),
    commentPreproc: Style().foreground(BasicColor('#CC6600')),
    keyword: Style().foreground(BasicColor('#0066CC')),
    keywordReserved: Style().foreground(BasicColor('#CC0099')),
    keywordNamespace: Style().foreground(BasicColor('#CC3366')),
    keywordType: Style().foreground(BasicColor('#5533CC')),
    operator: Style().foreground(BasicColor('#CC4444')),
    punctuation: Style().foreground(BasicColor('#666600')),
    name: Style().foreground(BasicColor('#333333')),
    nameBuiltin: Style().foreground(BasicColor('#CC6699')),
    nameTag: Style().foreground(BasicColor('#9933CC')),
    nameAttribute: Style().foreground(BasicColor('#5555CC')),
    nameClass: Style().foreground(BasicColor('#000000')).underline().bold(),
    nameConstant: Style().foreground(BasicColor('#333333')),
    nameDecorator: Style().foreground(BasicColor('#999900')),
    nameException: Style().foreground(BasicColor('#CC3366')),
    nameFunction: Style().foreground(BasicColor('#009966')),
    nameOther: Style().foreground(BasicColor('#333333')),
    literal: Style().foreground(BasicColor('#333333')),
    literalNumber: Style().foreground(BasicColor('#009999')),
    literalDate: Style().foreground(BasicColor('#333333')),
    literalString: Style().foreground(BasicColor('#996633')),
    literalStringEscape: Style().foreground(BasicColor('#339966')),
    genericDeleted: Style().foreground(BasicColor('#CC0000')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#009900')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#666666')),
    background: Style().background(BasicColor('#F5F5F5')),
  );

  /// Monokai-inspired theme.
  static ChromaTheme get monokai => ChromaTheme(
    text: Style().foreground(BasicColor('#F8F8F2')),
    error: Style().foreground(BasicColor('#960050')),
    comment: Style().foreground(BasicColor('#75715E')),
    commentPreproc: Style().foreground(BasicColor('#75715E')),
    keyword: Style().foreground(BasicColor('#F92672')),
    keywordReserved: Style().foreground(BasicColor('#F92672')),
    keywordNamespace: Style().foreground(BasicColor('#F92672')),
    keywordType: Style().foreground(BasicColor('#66D9EF')).italic(),
    operator: Style().foreground(BasicColor('#F92672')),
    punctuation: Style().foreground(BasicColor('#F8F8F2')),
    name: Style().foreground(BasicColor('#F8F8F2')),
    nameBuiltin: Style().foreground(BasicColor('#66D9EF')),
    nameTag: Style().foreground(BasicColor('#F92672')),
    nameAttribute: Style().foreground(BasicColor('#A6E22E')),
    nameClass: Style().foreground(BasicColor('#A6E22E')).bold(),
    nameConstant: Style().foreground(BasicColor('#66D9EF')),
    nameDecorator: Style().foreground(BasicColor('#A6E22E')),
    nameException: Style().foreground(BasicColor('#A6E22E')),
    nameFunction: Style().foreground(BasicColor('#A6E22E')),
    nameOther: Style().foreground(BasicColor('#A6E22E')),
    literal: Style().foreground(BasicColor('#AE81FF')),
    literalNumber: Style().foreground(BasicColor('#AE81FF')),
    literalDate: Style().foreground(BasicColor('#E6DB74')),
    literalString: Style().foreground(BasicColor('#E6DB74')),
    literalStringEscape: Style().foreground(BasicColor('#AE81FF')),
    genericDeleted: Style().foreground(BasicColor('#F92672')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#A6E22E')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#75715E')),
    background: Style().background(BasicColor('#272822')),
  );

  /// Dracula-inspired theme.
  static ChromaTheme get dracula => ChromaTheme(
    text: Style().foreground(BasicColor('#F8F8F2')),
    error: Style().foreground(BasicColor('#FF5555')),
    comment: Style().foreground(BasicColor('#6272A4')),
    commentPreproc: Style().foreground(BasicColor('#FF79C6')),
    keyword: Style().foreground(BasicColor('#FF79C6')),
    keywordReserved: Style().foreground(BasicColor('#FF79C6')),
    keywordNamespace: Style().foreground(BasicColor('#FF79C6')),
    keywordType: Style().foreground(BasicColor('#8BE9FD')).italic(),
    operator: Style().foreground(BasicColor('#FF79C6')),
    punctuation: Style().foreground(BasicColor('#F8F8F2')),
    name: Style().foreground(BasicColor('#F8F8F2')),
    nameBuiltin: Style().foreground(BasicColor('#8BE9FD')).italic(),
    nameTag: Style().foreground(BasicColor('#FF79C6')),
    nameAttribute: Style().foreground(BasicColor('#50FA7B')),
    nameClass: Style().foreground(BasicColor('#8BE9FD')),
    nameConstant: Style().foreground(BasicColor('#BD93F9')),
    nameDecorator: Style().foreground(BasicColor('#50FA7B')),
    nameException: Style().foreground(BasicColor('#50FA7B')),
    nameFunction: Style().foreground(BasicColor('#50FA7B')),
    nameOther: Style().foreground(BasicColor('#F8F8F2')),
    literal: Style().foreground(BasicColor('#BD93F9')),
    literalNumber: Style().foreground(BasicColor('#BD93F9')),
    literalDate: Style().foreground(BasicColor('#F1FA8C')),
    literalString: Style().foreground(BasicColor('#F1FA8C')),
    literalStringEscape: Style().foreground(BasicColor('#FF79C6')),
    genericDeleted: Style().foreground(BasicColor('#FF5555')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#50FA7B')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#6272A4')),
    background: Style().background(BasicColor('#282A36')),
  );

  /// GitHub-inspired theme (light).
  static ChromaTheme get github => ChromaTheme(
    text: Style().foreground(BasicColor('#24292e')),
    error: Style().foreground(BasicColor('#cb2431')),
    comment: Style().foreground(BasicColor('#6a737d')),
    commentPreproc: Style().foreground(BasicColor('#6a737d')),
    keyword: Style().foreground(BasicColor('#d73a49')),
    keywordReserved: Style().foreground(BasicColor('#d73a49')),
    keywordNamespace: Style().foreground(BasicColor('#d73a49')),
    keywordType: Style().foreground(BasicColor('#d73a49')),
    operator: Style().foreground(BasicColor('#d73a49')),
    punctuation: Style().foreground(BasicColor('#24292e')),
    name: Style().foreground(BasicColor('#24292e')),
    nameBuiltin: Style().foreground(BasicColor('#005cc5')),
    nameTag: Style().foreground(BasicColor('#22863a')),
    nameAttribute: Style().foreground(BasicColor('#6f42c1')),
    nameClass: Style().foreground(BasicColor('#6f42c1')),
    nameConstant: Style().foreground(BasicColor('#005cc5')),
    nameDecorator: Style().foreground(BasicColor('#6f42c1')),
    nameException: Style().foreground(BasicColor('#005cc5')),
    nameFunction: Style().foreground(BasicColor('#6f42c1')),
    nameOther: Style().foreground(BasicColor('#005cc5')),
    literal: Style().foreground(BasicColor('#005cc5')),
    literalNumber: Style().foreground(BasicColor('#005cc5')),
    literalDate: Style().foreground(BasicColor('#032f62')),
    literalString: Style().foreground(BasicColor('#032f62')),
    literalStringEscape: Style().foreground(BasicColor('#005cc5')),
    genericDeleted: Style()
        .foreground(BasicColor('#cb2431'))
        .background(BasicColor('#ffeef0')),
    genericEmph: Style().italic(),
    genericInserted: Style()
        .foreground(BasicColor('#22863a'))
        .background(BasicColor('#f0fff4')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#005cc5')),
  );

  /// Solarized Dark theme.
  static ChromaTheme get solarizedDark => ChromaTheme(
    text: Style().foreground(BasicColor('#839496')),
    error: Style().foreground(BasicColor('#dc322f')),
    comment: Style().foreground(BasicColor('#586e75')),
    commentPreproc: Style().foreground(BasicColor('#cb4b16')),
    keyword: Style().foreground(BasicColor('#859900')),
    keywordReserved: Style().foreground(BasicColor('#cb4b16')),
    keywordNamespace: Style().foreground(BasicColor('#cb4b16')),
    keywordType: Style().foreground(BasicColor('#b58900')),
    operator: Style().foreground(BasicColor('#859900')),
    punctuation: Style().foreground(BasicColor('#839496')),
    name: Style().foreground(BasicColor('#839496')),
    nameBuiltin: Style().foreground(BasicColor('#268bd2')),
    nameTag: Style().foreground(BasicColor('#268bd2')),
    nameAttribute: Style().foreground(BasicColor('#839496')),
    nameClass: Style().foreground(BasicColor('#268bd2')),
    nameConstant: Style().foreground(BasicColor('#2aa198')),
    nameDecorator: Style().foreground(BasicColor('#cb4b16')),
    nameException: Style().foreground(BasicColor('#cb4b16')),
    nameFunction: Style().foreground(BasicColor('#268bd2')),
    nameOther: Style().foreground(BasicColor('#839496')),
    literal: Style().foreground(BasicColor('#2aa198')),
    literalNumber: Style().foreground(BasicColor('#2aa198')),
    literalDate: Style().foreground(BasicColor('#2aa198')),
    literalString: Style().foreground(BasicColor('#2aa198')),
    literalStringEscape: Style().foreground(BasicColor('#cb4b16')),
    genericDeleted: Style().foreground(BasicColor('#dc322f')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#859900')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#268bd2')),
    background: Style().background(BasicColor('#002b36')),
  );

  /// Solarized Light theme.
  static ChromaTheme get solarizedLight => ChromaTheme(
    text: Style().foreground(BasicColor('#657b83')),
    error: Style().foreground(BasicColor('#dc322f')),
    comment: Style().foreground(BasicColor('#93a1a1')),
    commentPreproc: Style().foreground(BasicColor('#cb4b16')),
    keyword: Style().foreground(BasicColor('#859900')),
    keywordReserved: Style().foreground(BasicColor('#cb4b16')),
    keywordNamespace: Style().foreground(BasicColor('#cb4b16')),
    keywordType: Style().foreground(BasicColor('#b58900')),
    operator: Style().foreground(BasicColor('#859900')),
    punctuation: Style().foreground(BasicColor('#657b83')),
    name: Style().foreground(BasicColor('#657b83')),
    nameBuiltin: Style().foreground(BasicColor('#268bd2')),
    nameTag: Style().foreground(BasicColor('#268bd2')),
    nameAttribute: Style().foreground(BasicColor('#657b83')),
    nameClass: Style().foreground(BasicColor('#268bd2')),
    nameConstant: Style().foreground(BasicColor('#2aa198')),
    nameDecorator: Style().foreground(BasicColor('#cb4b16')),
    nameException: Style().foreground(BasicColor('#cb4b16')),
    nameFunction: Style().foreground(BasicColor('#268bd2')),
    nameOther: Style().foreground(BasicColor('#657b83')),
    literal: Style().foreground(BasicColor('#2aa198')),
    literalNumber: Style().foreground(BasicColor('#2aa198')),
    literalDate: Style().foreground(BasicColor('#2aa198')),
    literalString: Style().foreground(BasicColor('#2aa198')),
    literalStringEscape: Style().foreground(BasicColor('#cb4b16')),
    genericDeleted: Style().foreground(BasicColor('#dc322f')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#859900')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#268bd2')),
    background: Style().background(BasicColor('#fdf6e3')),
  );

  /// Nord theme (dark, inspired by arctic colors).
  static ChromaTheme get nord => ChromaTheme(
    text: Style().foreground(BasicColor('#D8DEE9')),
    error: Style().foreground(BasicColor('#BF616A')),
    comment: Style().foreground(BasicColor('#616E88')),
    commentPreproc: Style().foreground(BasicColor('#5E81AC')),
    keyword: Style().foreground(BasicColor('#81A1C1')),
    keywordReserved: Style().foreground(BasicColor('#81A1C1')),
    keywordNamespace: Style().foreground(BasicColor('#81A1C1')),
    keywordType: Style().foreground(BasicColor('#8FBCBB')),
    operator: Style().foreground(BasicColor('#81A1C1')),
    punctuation: Style().foreground(BasicColor('#ECEFF4')),
    name: Style().foreground(BasicColor('#D8DEE9')),
    nameBuiltin: Style().foreground(BasicColor('#88C0D0')),
    nameTag: Style().foreground(BasicColor('#81A1C1')),
    nameAttribute: Style().foreground(BasicColor('#8FBCBB')),
    nameClass: Style().foreground(BasicColor('#8FBCBB')),
    nameConstant: Style().foreground(BasicColor('#D8DEE9')),
    nameDecorator: Style().foreground(BasicColor('#D08770')),
    nameException: Style().foreground(BasicColor('#BF616A')),
    nameFunction: Style().foreground(BasicColor('#88C0D0')),
    nameOther: Style().foreground(BasicColor('#D8DEE9')),
    literal: Style().foreground(BasicColor('#B48EAD')),
    literalNumber: Style().foreground(BasicColor('#B48EAD')),
    literalDate: Style().foreground(BasicColor('#EBCB8B')),
    literalString: Style().foreground(BasicColor('#A3BE8C')),
    literalStringEscape: Style().foreground(BasicColor('#EBCB8B')),
    genericDeleted: Style().foreground(BasicColor('#BF616A')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#A3BE8C')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#88C0D0')),
    background: Style().background(BasicColor('#2E3440')),
  );

  /// Gruvbox Dark theme.
  static ChromaTheme get gruvboxDark => ChromaTheme(
    text: Style().foreground(BasicColor('#EBDBB2')),
    error: Style().foreground(BasicColor('#FB4934')),
    comment: Style().foreground(BasicColor('#928374')),
    commentPreproc: Style().foreground(BasicColor('#8EC07C')),
    keyword: Style().foreground(BasicColor('#FB4934')),
    keywordReserved: Style().foreground(BasicColor('#FB4934')),
    keywordNamespace: Style().foreground(BasicColor('#FB4934')),
    keywordType: Style().foreground(BasicColor('#FABD2F')),
    operator: Style().foreground(BasicColor('#FE8019')),
    punctuation: Style().foreground(BasicColor('#EBDBB2')),
    name: Style().foreground(BasicColor('#EBDBB2')),
    nameBuiltin: Style().foreground(BasicColor('#FABD2F')),
    nameTag: Style().foreground(BasicColor('#8EC07C')),
    nameAttribute: Style().foreground(BasicColor('#B8BB26')),
    nameClass: Style().foreground(BasicColor('#FABD2F')),
    nameConstant: Style().foreground(BasicColor('#D3869B')),
    nameDecorator: Style().foreground(BasicColor('#8EC07C')),
    nameException: Style().foreground(BasicColor('#FB4934')),
    nameFunction: Style().foreground(BasicColor('#B8BB26')),
    nameOther: Style().foreground(BasicColor('#EBDBB2')),
    literal: Style().foreground(BasicColor('#D3869B')),
    literalNumber: Style().foreground(BasicColor('#D3869B')),
    literalDate: Style().foreground(BasicColor('#FABD2F')),
    literalString: Style().foreground(BasicColor('#B8BB26')),
    literalStringEscape: Style().foreground(BasicColor('#FE8019')),
    genericDeleted: Style().foreground(BasicColor('#FB4934')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#B8BB26')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#83A598')),
    background: Style().background(BasicColor('#282828')),
  );

  /// Gruvbox Light theme.
  static ChromaTheme get gruvboxLight => ChromaTheme(
    text: Style().foreground(BasicColor('#3C3836')),
    error: Style().foreground(BasicColor('#9D0006')),
    comment: Style().foreground(BasicColor('#928374')),
    commentPreproc: Style().foreground(BasicColor('#427B58')),
    keyword: Style().foreground(BasicColor('#9D0006')),
    keywordReserved: Style().foreground(BasicColor('#9D0006')),
    keywordNamespace: Style().foreground(BasicColor('#9D0006')),
    keywordType: Style().foreground(BasicColor('#B57614')),
    operator: Style().foreground(BasicColor('#AF3A03')),
    punctuation: Style().foreground(BasicColor('#3C3836')),
    name: Style().foreground(BasicColor('#3C3836')),
    nameBuiltin: Style().foreground(BasicColor('#B57614')),
    nameTag: Style().foreground(BasicColor('#427B58')),
    nameAttribute: Style().foreground(BasicColor('#79740E')),
    nameClass: Style().foreground(BasicColor('#B57614')),
    nameConstant: Style().foreground(BasicColor('#8F3F71')),
    nameDecorator: Style().foreground(BasicColor('#427B58')),
    nameException: Style().foreground(BasicColor('#9D0006')),
    nameFunction: Style().foreground(BasicColor('#79740E')),
    nameOther: Style().foreground(BasicColor('#3C3836')),
    literal: Style().foreground(BasicColor('#8F3F71')),
    literalNumber: Style().foreground(BasicColor('#8F3F71')),
    literalDate: Style().foreground(BasicColor('#B57614')),
    literalString: Style().foreground(BasicColor('#79740E')),
    literalStringEscape: Style().foreground(BasicColor('#AF3A03')),
    genericDeleted: Style().foreground(BasicColor('#9D0006')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#79740E')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#076678')),
    background: Style().background(BasicColor('#FBF1C7')),
  );

  /// One Dark theme (Atom-inspired).
  static ChromaTheme get oneDark => ChromaTheme(
    text: Style().foreground(BasicColor('#ABB2BF')),
    error: Style().foreground(BasicColor('#E06C75')),
    comment: Style().foreground(BasicColor('#5C6370')),
    commentPreproc: Style().foreground(BasicColor('#C678DD')),
    keyword: Style().foreground(BasicColor('#C678DD')),
    keywordReserved: Style().foreground(BasicColor('#C678DD')),
    keywordNamespace: Style().foreground(BasicColor('#C678DD')),
    keywordType: Style().foreground(BasicColor('#E5C07B')),
    operator: Style().foreground(BasicColor('#56B6C2')),
    punctuation: Style().foreground(BasicColor('#ABB2BF')),
    name: Style().foreground(BasicColor('#ABB2BF')),
    nameBuiltin: Style().foreground(BasicColor('#E5C07B')),
    nameTag: Style().foreground(BasicColor('#E06C75')),
    nameAttribute: Style().foreground(BasicColor('#D19A66')),
    nameClass: Style().foreground(BasicColor('#E5C07B')),
    nameConstant: Style().foreground(BasicColor('#D19A66')),
    nameDecorator: Style().foreground(BasicColor('#61AFEF')),
    nameException: Style().foreground(BasicColor('#E06C75')),
    nameFunction: Style().foreground(BasicColor('#61AFEF')),
    nameOther: Style().foreground(BasicColor('#ABB2BF')),
    literal: Style().foreground(BasicColor('#D19A66')),
    literalNumber: Style().foreground(BasicColor('#D19A66')),
    literalDate: Style().foreground(BasicColor('#98C379')),
    literalString: Style().foreground(BasicColor('#98C379')),
    literalStringEscape: Style().foreground(BasicColor('#56B6C2')),
    genericDeleted: Style().foreground(BasicColor('#E06C75')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#98C379')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#61AFEF')),
    background: Style().background(BasicColor('#282C34')),
  );

  /// One Light theme (Atom-inspired).
  static ChromaTheme get oneLight => ChromaTheme(
    text: Style().foreground(BasicColor('#383A42')),
    error: Style().foreground(BasicColor('#E45649')),
    comment: Style().foreground(BasicColor('#A0A1A7')),
    commentPreproc: Style().foreground(BasicColor('#A626A4')),
    keyword: Style().foreground(BasicColor('#A626A4')),
    keywordReserved: Style().foreground(BasicColor('#A626A4')),
    keywordNamespace: Style().foreground(BasicColor('#A626A4')),
    keywordType: Style().foreground(BasicColor('#C18401')),
    operator: Style().foreground(BasicColor('#0184BC')),
    punctuation: Style().foreground(BasicColor('#383A42')),
    name: Style().foreground(BasicColor('#383A42')),
    nameBuiltin: Style().foreground(BasicColor('#C18401')),
    nameTag: Style().foreground(BasicColor('#E45649')),
    nameAttribute: Style().foreground(BasicColor('#986801')),
    nameClass: Style().foreground(BasicColor('#C18401')),
    nameConstant: Style().foreground(BasicColor('#986801')),
    nameDecorator: Style().foreground(BasicColor('#4078F2')),
    nameException: Style().foreground(BasicColor('#E45649')),
    nameFunction: Style().foreground(BasicColor('#4078F2')),
    nameOther: Style().foreground(BasicColor('#383A42')),
    literal: Style().foreground(BasicColor('#986801')),
    literalNumber: Style().foreground(BasicColor('#986801')),
    literalDate: Style().foreground(BasicColor('#50A14F')),
    literalString: Style().foreground(BasicColor('#50A14F')),
    literalStringEscape: Style().foreground(BasicColor('#0184BC')),
    genericDeleted: Style().foreground(BasicColor('#E45649')),
    genericEmph: Style().italic(),
    genericInserted: Style().foreground(BasicColor('#50A14F')),
    genericStrong: Style().bold(),
    genericSubheading: Style().foreground(BasicColor('#4078F2')),
    background: Style().background(BasicColor('#FAFAFA')),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Adaptive Theme
// ─────────────────────────────────────────────────────────────────────────────

/// An adaptive syntax highlighting theme that selects between light and dark
/// variants based on terminal background.
///
/// Similar to [AdaptiveColor], this allows themes to automatically adapt to
/// the terminal's color scheme.
///
/// ```dart
/// // Create an adaptive theme
/// final theme = AdaptiveChromaTheme(
///   light: ChromaTheme.github,
///   dark: ChromaTheme.dracula,
/// );
///
/// // Use with SyntaxHighlighter
/// final highlighter = SyntaxHighlighter.adaptive(
///   theme: theme,
///   hasDarkBackground: terminalTheme.hasDarkBackground ?? true,
/// );
/// ```
class AdaptiveChromaTheme {
  /// Creates an adaptive theme with light and dark variants.
  const AdaptiveChromaTheme({required this.light, required this.dark});

  /// Theme to use on light terminal backgrounds.
  final ChromaTheme light;

  /// Theme to use on dark terminal backgrounds.
  final ChromaTheme dark;

  /// Selects the appropriate theme based on background.
  ChromaTheme resolve({required bool hasDarkBackground}) {
    return hasDarkBackground ? dark : light;
  }

  /// Default adaptive theme using dark/light presets.
  static AdaptiveChromaTheme get defaultTheme =>
      AdaptiveChromaTheme(light: ChromaTheme.light, dark: ChromaTheme.dark);

  /// Monokai (dark) / GitHub (light) pairing.
  static AdaptiveChromaTheme get monokaiGithub =>
      AdaptiveChromaTheme(light: ChromaTheme.github, dark: ChromaTheme.monokai);

  /// Dracula (dark) / GitHub (light) pairing.
  static AdaptiveChromaTheme get draculaGithub =>
      AdaptiveChromaTheme(light: ChromaTheme.github, dark: ChromaTheme.dracula);

  /// Solarized dark/light pairing.
  static AdaptiveChromaTheme get solarized => AdaptiveChromaTheme(
    light: ChromaTheme.solarizedLight,
    dark: ChromaTheme.solarizedDark,
  );

  /// Nord (dark) / GitHub (light) pairing.
  ///
  /// Nord doesn't have an official light variant, so GitHub is a good match.
  static AdaptiveChromaTheme get nordGithub =>
      AdaptiveChromaTheme(light: ChromaTheme.github, dark: ChromaTheme.nord);

  /// Gruvbox dark/light pairing.
  static AdaptiveChromaTheme get gruvbox => AdaptiveChromaTheme(
    light: ChromaTheme.gruvboxLight,
    dark: ChromaTheme.gruvboxDark,
  );

  /// One Dark/Light pairing (Atom-inspired).
  static AdaptiveChromaTheme get oneDarkLight => AdaptiveChromaTheme(
    light: ChromaTheme.oneLight,
    dark: ChromaTheme.oneDark,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Syntax Highlighter
// ─────────────────────────────────────────────────────────────────────────────

/// Syntax highlighter that converts code to ANSI-styled terminal output.
///
/// Uses the highlight.dart package for parsing and artisanal's Style system
/// for rendering.
///
/// ```dart
/// final highlighter = SyntaxHighlighter(theme: ChromaTheme.dark);
/// final highlighted = highlighter.highlight(
///   'void main() { print("Hello"); }',
///   language: 'dart',
/// );
/// print(highlighted);
/// ```
const String codeSyntaxDecorationPrefix = 'syntax';

String codeSyntaxDecorationStyleKey(
  String slot, {
  String prefix = codeSyntaxDecorationPrefix,
}) {
  return '$prefix.$slot';
}

final class SyntaxHighlightSpan {
  const SyntaxHighlightSpan({
    required this.startOffset,
    required this.endOffset,
    required this.styleKey,
  });

  final int startOffset;
  final int endOffset;
  final String styleKey;

  int get length => endOffset - startOffset;
  bool get isEmpty => startOffset >= endOffset;

  SyntaxHighlightSpan copyWith({
    int? startOffset,
    int? endOffset,
    String? styleKey,
  }) {
    return SyntaxHighlightSpan(
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      styleKey: styleKey ?? this.styleKey,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SyntaxHighlightSpan &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.styleKey == styleKey;
  }

  @override
  int get hashCode => Object.hash(startOffset, endOffset, styleKey);

  @override
  String toString() {
    return 'SyntaxHighlightSpan($startOffset, $endOffset, $styleKey)';
  }
}

class SyntaxHighlighter {
  /// Creates a syntax highlighter with the given theme.
  SyntaxHighlighter({ChromaTheme? theme}) : theme = theme ?? ChromaTheme.dark;

  /// Creates a syntax highlighter that adapts to terminal background.
  ///
  /// Uses [adaptiveTheme] to select between light and dark themes based on
  /// [hasDarkBackground].
  ///
  /// ```dart
  /// final highlighter = SyntaxHighlighter.adaptive(
  ///   adaptiveTheme: AdaptiveChromaTheme.draculaGithub,
  ///   hasDarkBackground: terminalTheme.hasDarkBackground ?? true,
  /// );
  /// ```
  factory SyntaxHighlighter.adaptive({
    AdaptiveChromaTheme? adaptiveTheme,
    bool hasDarkBackground = true,
  }) {
    final theme = (adaptiveTheme ?? AdaptiveChromaTheme.defaultTheme).resolve(
      hasDarkBackground: hasDarkBackground,
    );
    return SyntaxHighlighter(theme: theme);
  }

  /// The color theme to use for highlighting.
  final ChromaTheme theme;

  /// Highlights code and returns grapheme-aware decoration spans.
  ///
  /// Spans use theme-independent style keys that can be resolved later through
  /// [decorationStyles].
  List<SyntaxHighlightSpan> highlightSpans(String code, {String? language}) {
    final nodes = _parseHighlightedNodes(code, language: language);
    if (nodes == null || nodes.isEmpty) {
      return const [];
    }
    return _nodesToSpans(nodes);
  }

  /// Returns decoration styles keyed for use with editable code overlays.
  Map<String, Style> decorationStyles({
    String prefix = codeSyntaxDecorationPrefix,
  }) {
    return Map<String, Style>.unmodifiable({
      if (theme.comment != null)
        codeSyntaxDecorationStyleKey('comment', prefix: prefix): theme.comment!,
      if (theme.commentPreproc != null)
        codeSyntaxDecorationStyleKey('comment.preproc', prefix: prefix):
            theme.commentPreproc!,
      if (theme.keyword != null)
        codeSyntaxDecorationStyleKey('keyword', prefix: prefix): theme.keyword!,
      if (theme.keywordType != null)
        codeSyntaxDecorationStyleKey('keyword.type', prefix: prefix):
            theme.keywordType!,
      if (theme.literal != null)
        codeSyntaxDecorationStyleKey('literal', prefix: prefix): theme.literal!,
      if (theme.literalNumber != null)
        codeSyntaxDecorationStyleKey('literal.number', prefix: prefix):
            theme.literalNumber!,
      if (theme.literalString != null)
        codeSyntaxDecorationStyleKey('literal.string', prefix: prefix):
            theme.literalString!,
      if (theme.name != null)
        codeSyntaxDecorationStyleKey('name', prefix: prefix): theme.name!,
      if (theme.nameAttribute != null)
        codeSyntaxDecorationStyleKey('name.attribute', prefix: prefix):
            theme.nameAttribute!,
      if (theme.nameBuiltin != null)
        codeSyntaxDecorationStyleKey('name.builtin', prefix: prefix):
            theme.nameBuiltin!,
      if (theme.nameClass != null)
        codeSyntaxDecorationStyleKey('name.class', prefix: prefix):
            theme.nameClass!,
      if (theme.nameConstant != null)
        codeSyntaxDecorationStyleKey('name.constant', prefix: prefix):
            theme.nameConstant!,
      if (theme.nameFunction != null)
        codeSyntaxDecorationStyleKey('name.function', prefix: prefix):
            theme.nameFunction!,
      if (theme.nameTag != null)
        codeSyntaxDecorationStyleKey('name.tag', prefix: prefix):
            theme.nameTag!,
      if (theme.operator != null)
        codeSyntaxDecorationStyleKey('operator', prefix: prefix):
            theme.operator!,
      if (theme.punctuation != null)
        codeSyntaxDecorationStyleKey('punctuation', prefix: prefix):
            theme.punctuation!,
      if (theme.genericDeleted != null)
        codeSyntaxDecorationStyleKey('generic.deleted', prefix: prefix):
            theme.genericDeleted!,
      if (theme.genericEmph != null)
        codeSyntaxDecorationStyleKey('generic.emphasis', prefix: prefix):
            theme.genericEmph!,
      if (theme.genericInserted != null)
        codeSyntaxDecorationStyleKey('generic.inserted', prefix: prefix):
            theme.genericInserted!,
      if (theme.genericStrong != null)
        codeSyntaxDecorationStyleKey('generic.strong', prefix: prefix):
            theme.genericStrong!,
      if (theme.genericSubheading != null)
        codeSyntaxDecorationStyleKey('generic.subheading', prefix: prefix):
            theme.genericSubheading!,
    });
  }

  /// Highlights code and returns ANSI-styled output.
  ///
  /// If [language] is not specified or not recognized, attempts auto-detection.
  /// Falls back to plain text styling if highlighting fails.
  String highlightCode(String code, {String? language}) {
    final nodes = _parseHighlightedNodes(code, language: language);
    if (nodes != null && nodes.isNotEmpty) {
      return _nodesToAnsi(nodes);
    }

    // Default: return with text style
    final textStyle = theme.text;
    if (textStyle != null) {
      return textStyle.inline(true).render(code);
    }
    return code;
  }

  List<Node>? _parseHighlightedNodes(String code, {String? language}) {
    final lang = FenceLanguageResolver.resolve(language);

    // Try to highlight with the specified language
    if (lang != null && lang.isNotEmpty) {
      try {
        final result = highlight.parse(code, language: lang);
        if (result.nodes != null && result.nodes!.isNotEmpty) {
          return result.nodes!;
        }
      } catch (e) {
        // Language not recognized, fall through to auto-detection
      }
    }

    // Try auto-detection
    try {
      final result = highlight.parse(code, autoDetection: true);
      if (result.nodes != null &&
          result.nodes!.isNotEmpty &&
          result.language != null &&
          result.language != 'plaintext') {
        return result.nodes!;
      }
    } catch (e) {
      // Auto-detection failed
    }

    return null;
  }

  /// Converts highlight.dart nodes to ANSI-styled string.
  String _nodesToAnsi(List<Node> nodes) {
    final buffer = StringBuffer();

    for (final node in nodes) {
      _renderNode(node, buffer);
    }

    return buffer.toString();
  }

  List<SyntaxHighlightSpan> _nodesToSpans(List<Node> nodes) {
    final spans = <SyntaxHighlightSpan>[];
    var offset = 0;
    for (final node in nodes) {
      offset = _collectNodeSpans(node, spans, offset: offset);
    }
    return List<SyntaxHighlightSpan>.unmodifiable(spans);
  }

  int _collectNodeSpans(
    Node node,
    List<SyntaxHighlightSpan> spans, {
    required int offset,
    String? parentClass,
  }) {
    final effectiveClass = node.className ?? parentClass;

    if (node.value != null) {
      final value = node.value!;
      final length = uni.graphemes(value).length;
      final styleKey = _getDecorationStyleKeyForClass(effectiveClass);
      if (styleKey != null && length > 0) {
        if (spans.isNotEmpty &&
            spans.last.styleKey == styleKey &&
            spans.last.endOffset == offset) {
          spans[spans.length - 1] = spans.last.copyWith(
            endOffset: offset + length,
          );
        } else {
          spans.add(
            SyntaxHighlightSpan(
              startOffset: offset,
              endOffset: offset + length,
              styleKey: styleKey,
            ),
          );
        }
      }
      return offset + length;
    }

    if (node.children != null) {
      var currentOffset = offset;
      for (final child in node.children!) {
        currentOffset = _collectNodeSpans(
          child,
          spans,
          offset: currentOffset,
          parentClass: effectiveClass,
        );
      }
      return currentOffset;
    }

    return offset;
  }

  /// Renders a single node to the buffer.
  ///
  /// [parentClass] is passed down from parent nodes so that children
  /// of styled containers (like `keyword` nodes) inherit the parent's style.
  void _renderNode(Node node, StringBuffer buffer, {String? parentClass}) {
    // Determine the effective class - prefer node's own class, then parent's
    final effectiveClass = node.className ?? parentClass;

    if (node.value != null) {
      // Text node - apply styling based on effective class
      final style = _getStyleForClass(effectiveClass);
      if (style != null) {
        buffer.write(style.inline(true).render(node.value!));
      } else {
        buffer.write(node.value);
      }
    } else if (node.children != null) {
      // Container node with children - pass down the effective class
      for (final child in node.children!) {
        _renderNode(child, buffer, parentClass: effectiveClass);
      }
    }
  }

  /// Maps highlight.js class names to our theme styles.
  Style? _getStyleForClass(String? className) {
    if (className == null) return theme.text;

    // Handle compound classes (e.g., 'hljs-keyword hljs-type')
    final classes = className.split(' ');
    for (final cls in classes) {
      final style = _getStyleForSingleClass(cls);
      if (style != null) return style;
    }
    return theme.text;
  }

  String? _getDecorationStyleKeyForClass(String? className) {
    if (className == null) {
      return null;
    }

    final classes = className.split(' ');
    for (final cls in classes) {
      final styleKey = _getDecorationStyleKeyForSingleClass(cls);
      if (styleKey != null) {
        return styleKey;
      }
    }
    return null;
  }

  /// Maps a single class name to a style.
  Style? _getStyleForSingleClass(String className) {
    return switch (className) {
      // Comments
      'hljs-comment' || 'comment' => theme.comment,
      'hljs-doctag' => theme.comment,
      'hljs-meta' || 'meta' => theme.commentPreproc,

      // Keywords
      'hljs-keyword' || 'keyword' => theme.keyword,
      'hljs-type' || 'type' => theme.keywordType,
      'hljs-selector-tag' => theme.keyword,

      // Literals
      'hljs-string' || 'string' => theme.literalString,
      'hljs-number' || 'number' => theme.literalNumber,
      'hljs-literal' || 'literal' => theme.literal,
      'hljs-regexp' => theme.literalString,

      // Names
      'hljs-title' || 'title' => theme.nameFunction,
      'hljs-title.function_' || 'title function_' => theme.nameFunction,
      'hljs-title.class_' || 'title class_' => theme.nameClass,
      'hljs-function' || 'function' => theme.nameFunction,
      'hljs-class' || 'class' => theme.nameClass,
      'hljs-params' || 'params' => theme.name,
      'hljs-variable' || 'variable' => theme.name,
      'hljs-attr' || 'attr' => theme.nameAttribute,
      'hljs-attribute' || 'attribute' => theme.nameAttribute,
      'hljs-name' || 'name' => theme.nameTag,
      'hljs-tag' || 'tag' => theme.nameTag,
      'hljs-built_in' || 'built_in' => theme.nameBuiltin,
      'hljs-builtin-name' => theme.nameBuiltin,
      'hljs-symbol' || 'symbol' => theme.nameConstant,

      // Operators and punctuation
      'hljs-operator' || 'operator' => theme.operator,
      'hljs-punctuation' || 'punctuation' => theme.punctuation,

      // Template literals
      'hljs-template-variable' => theme.name,
      'hljs-template-tag' => theme.nameTag,
      'hljs-subst' => theme.name,

      // Diff
      'hljs-addition' || 'addition' => theme.genericInserted,
      'hljs-deletion' || 'deletion' => theme.genericDeleted,

      // Emphasis
      'hljs-emphasis' || 'emphasis' => theme.genericEmph,
      'hljs-strong' || 'strong' => theme.genericStrong,

      // Section
      'hljs-section' || 'section' => theme.genericSubheading,

      // Quote
      'hljs-quote' || 'quote' => theme.comment,

      // Selector
      'hljs-selector-class' => theme.nameClass,
      'hljs-selector-id' => theme.nameConstant,
      'hljs-selector-attr' => theme.nameAttribute,
      'hljs-selector-pseudo' => theme.nameBuiltin,

      // Links/references
      'hljs-link' || 'link' => theme.literalString,

      _ => null,
    };
  }

  String? _getDecorationStyleKeyForSingleClass(String className) {
    return switch (className) {
      'hljs-comment' ||
      'comment' ||
      'hljs-doctag' => codeSyntaxDecorationStyleKey('comment'),
      'hljs-meta' || 'meta' => codeSyntaxDecorationStyleKey('comment.preproc'),
      'hljs-keyword' ||
      'keyword' ||
      'hljs-selector-tag' => codeSyntaxDecorationStyleKey('keyword'),
      'hljs-type' || 'type' => codeSyntaxDecorationStyleKey('keyword.type'),
      'hljs-string' ||
      'string' ||
      'hljs-regexp' ||
      'hljs-link' ||
      'link' => codeSyntaxDecorationStyleKey('literal.string'),
      'hljs-number' ||
      'number' => codeSyntaxDecorationStyleKey('literal.number'),
      'hljs-literal' || 'literal' => codeSyntaxDecorationStyleKey('literal'),
      'hljs-title' ||
      'title' ||
      'hljs-title.function_' ||
      'title function_' ||
      'hljs-function' ||
      'function' => codeSyntaxDecorationStyleKey('name.function'),
      'hljs-title.class_' ||
      'title class_' ||
      'hljs-class' ||
      'class' => codeSyntaxDecorationStyleKey('name.class'),
      'hljs-params' ||
      'params' ||
      'hljs-variable' ||
      'variable' ||
      'hljs-template-variable' ||
      'hljs-subst' => codeSyntaxDecorationStyleKey('name'),
      'hljs-attr' ||
      'attr' ||
      'hljs-attribute' ||
      'attribute' => codeSyntaxDecorationStyleKey('name.attribute'),
      'hljs-name' ||
      'name' ||
      'hljs-tag' ||
      'tag' ||
      'hljs-template-tag' => codeSyntaxDecorationStyleKey('name.tag'),
      'hljs-built_in' ||
      'built_in' ||
      'hljs-builtin-name' => codeSyntaxDecorationStyleKey('name.builtin'),
      'hljs-symbol' ||
      'symbol' ||
      'hljs-selector-id' => codeSyntaxDecorationStyleKey('name.constant'),
      'hljs-selector-class' => codeSyntaxDecorationStyleKey('name.class'),
      'hljs-selector-attr' => codeSyntaxDecorationStyleKey('name.attribute'),
      'hljs-selector-pseudo' => codeSyntaxDecorationStyleKey('name.builtin'),
      'hljs-operator' || 'operator' => codeSyntaxDecorationStyleKey('operator'),
      'hljs-punctuation' ||
      'punctuation' => codeSyntaxDecorationStyleKey('punctuation'),
      'hljs-addition' ||
      'addition' => codeSyntaxDecorationStyleKey('generic.inserted'),
      'hljs-deletion' ||
      'deletion' => codeSyntaxDecorationStyleKey('generic.deleted'),
      'hljs-emphasis' ||
      'emphasis' => codeSyntaxDecorationStyleKey('generic.emphasis'),
      'hljs-strong' ||
      'strong' => codeSyntaxDecorationStyleKey('generic.strong'),
      'hljs-section' ||
      'section' => codeSyntaxDecorationStyleKey('generic.subheading'),
      'hljs-quote' || 'quote' => codeSyntaxDecorationStyleKey('comment'),
      _ => null,
    };
  }
}

Style? _parseStyle(Map<String, dynamic> json) {
  var style = Style();
  var hasStyle = false;

  if (json.containsKey('color')) {
    style = style.foreground(BasicColor(json['color'].toString()));
    hasStyle = true;
  }
  if (json.containsKey('background_color')) {
    style = style.background(BasicColor(json['background_color'].toString()));
    hasStyle = true;
  }
  if (json.containsKey('bold')) {
    if (json['bold'] == true) {
      style = style.bold();
      hasStyle = true;
    }
  }
  if (json.containsKey('italic')) {
    if (json['italic'] == true) {
      style = style.italic();
      hasStyle = true;
    }
  }
  if (json.containsKey('underline')) {
    if (json['underline'] == true) {
      style = style.underline();
      hasStyle = true;
    }
  }

  return hasStyle ? style : null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience Function
// ─────────────────────────────────────────────────────────────────────────────

/// Highlights code and returns ANSI-styled output.
///
/// ```dart
/// final highlighted = highlightCode(
///   'void main() { print("Hello"); }',
///   language: 'dart',
/// );
/// print(highlighted);
/// ```
String highlightCodeString(
  String code, {
  String? language,
  ChromaTheme? theme,
}) {
  return SyntaxHighlighter(
    theme: theme,
  ).highlightCode(code, language: language);
}
