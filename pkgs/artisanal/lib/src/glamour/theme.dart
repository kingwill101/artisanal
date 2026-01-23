import '../style/color.dart';
import '../style/style.dart';
import '../tui/markdown/syntax_highlighter.dart';

/// Configuration for Glamour markdown rendering.
///
/// mirrors `glamour`'s `StyleConfig` struct.
class GlamourTheme {
  const GlamourTheme({
    this.document = const GlamourBlockStyle(),
    this.blockQuote = const GlamourBlockStyle(),
    this.paragraph = const GlamourBlockStyle(),
    this.list = const GlamourListStyle(),
    this.heading = const GlamourBlockStyle(),
    this.h1 = const GlamourBlockStyle(),
    this.h2 = const GlamourBlockStyle(),
    this.h3 = const GlamourBlockStyle(),
    this.h4 = const GlamourBlockStyle(),
    this.h5 = const GlamourBlockStyle(),
    this.h6 = const GlamourBlockStyle(),
    this.text = const GlamourPrimitiveStyle(),
    this.strikethrough = const GlamourPrimitiveStyle(),
    this.emph = const GlamourPrimitiveStyle(),
    this.strong = const GlamourPrimitiveStyle(),
    this.horizontalRule = const GlamourPrimitiveStyle(),
    this.item = const GlamourPrimitiveStyle(),
    this.enumeration = const GlamourPrimitiveStyle(),
    this.task = const GlamourTaskStyle(),
    this.link = const GlamourPrimitiveStyle(),
    this.linkText = const GlamourPrimitiveStyle(),
    this.image = const GlamourPrimitiveStyle(),
    this.imageText = const GlamourPrimitiveStyle(),
    this.code = const GlamourBlockStyle(),
    this.codeBlock = const GlamourCodeBlockStyle(),
    this.table = const GlamourTableStyle(),
    this.definitionList = const GlamourBlockStyle(),
    this.definitionTerm = const GlamourPrimitiveStyle(),
    this.definitionDescription = const GlamourPrimitiveStyle(),
    this.htmlBlock = const GlamourBlockStyle(),
    this.htmlSpan =
        const GlamourBlockStyle(), // Uses BlockStyle for consistency
  });

  final GlamourBlockStyle document;
  final GlamourBlockStyle blockQuote;
  final GlamourBlockStyle paragraph;
  final GlamourListStyle list;
  final GlamourBlockStyle heading;
  final GlamourBlockStyle h1;
  final GlamourBlockStyle h2;
  final GlamourBlockStyle h3;
  final GlamourBlockStyle h4;
  final GlamourBlockStyle h5;
  final GlamourBlockStyle h6;
  final GlamourPrimitiveStyle text;
  final GlamourPrimitiveStyle strikethrough;
  final GlamourPrimitiveStyle emph;
  final GlamourPrimitiveStyle strong;
  final GlamourPrimitiveStyle horizontalRule;
  final GlamourPrimitiveStyle item;
  final GlamourPrimitiveStyle enumeration;
  final GlamourTaskStyle task;
  final GlamourPrimitiveStyle link;
  final GlamourPrimitiveStyle linkText;
  final GlamourPrimitiveStyle image;
  final GlamourPrimitiveStyle imageText;
  final GlamourBlockStyle code;
  final GlamourCodeBlockStyle codeBlock;
  final GlamourTableStyle table;
  final GlamourBlockStyle definitionList;
  final GlamourPrimitiveStyle definitionTerm;
  final GlamourPrimitiveStyle definitionDescription;
  final GlamourBlockStyle htmlBlock;
  final GlamourBlockStyle htmlSpan;

  factory GlamourTheme.fromJson(Map<String, dynamic> json) {
    GlamourBlockStyle blockStyle(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return GlamourBlockStyle.fromJson(value);
      }
      return const GlamourBlockStyle();
    }

    GlamourPrimitiveStyle primitiveStyle(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return GlamourPrimitiveStyle.fromJson(value);
      }
      return const GlamourPrimitiveStyle();
    }

    GlamourListStyle listStyle(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return GlamourListStyle.fromJson(value);
      }
      return const GlamourListStyle();
    }

    GlamourTaskStyle taskStyle(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return GlamourTaskStyle.fromJson(value);
      }
      return const GlamourTaskStyle();
    }

    GlamourCodeBlockStyle codeBlockStyle(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return GlamourCodeBlockStyle.fromJson(value);
      }
      return const GlamourCodeBlockStyle();
    }

    GlamourTableStyle tableStyle(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return GlamourTableStyle.fromJson(value);
      }
      return const GlamourTableStyle();
    }

    return GlamourTheme(
      document: blockStyle('document'),
      blockQuote: blockStyle('block_quote'),
      paragraph: blockStyle('paragraph'),
      list: listStyle('list'),
      heading: blockStyle('heading'),
      h1: blockStyle('h1'),
      h2: blockStyle('h2'),
      h3: blockStyle('h3'),
      h4: blockStyle('h4'),
      h5: blockStyle('h5'),
      h6: blockStyle('h6'),
      text: primitiveStyle('text'),
      strikethrough: primitiveStyle('strikethrough'),
      emph: primitiveStyle('emph'),
      strong: primitiveStyle('strong'),
      horizontalRule: primitiveStyle('hr'),
      item: primitiveStyle('item'),
      enumeration: primitiveStyle('enumeration'),
      task: taskStyle('task'),
      link: primitiveStyle('link'),
      linkText: primitiveStyle('link_text'),
      image: primitiveStyle('image'),
      imageText: primitiveStyle('image_text'),
      code: blockStyle('code'),
      codeBlock: codeBlockStyle('code_block'),
      table: tableStyle('table'),
      definitionList: blockStyle('definition_list'),
      definitionTerm: primitiveStyle('definition_term'),
      definitionDescription: primitiveStyle('definition_description'),
      htmlBlock: blockStyle('html_block'),
      htmlSpan: blockStyle('html_span'),
    );
  }

  // Standard Themes

  static final GlamourTheme dark = GlamourTheme(
    document: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        blockPrefix: '\n',
        blockSuffix: '\n',
        color: BasicColor('252'), // #D6D6D6
      ),
      margin: 2,
    ),
    blockQuote: GlamourBlockStyle(indent: 1, indentToken: '│ '),
    list: GlamourListStyle(levelIndent: 2),
    heading: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        blockSuffix: '\n',
        color: BasicColor('39'), // #00AFAF
        bold: true,
      ),
    ),
    h1: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        prefix: ' ',
        suffix: ' ',
        color: BasicColor('228'), // #FFFF87
        backgroundColor: BasicColor('63'), // #5F5FFF
        bold: true,
        blockSuffix: '\n',
      ),
    ),
    h2: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '## ', blockSuffix: '\n'),
    ),
    h3: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '### ', blockSuffix: '\n'),
    ),
    h4: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '#### ', blockSuffix: '\n'),
    ),
    h5: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '##### ', blockSuffix: '\n'),
    ),
    h6: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        prefix: '###### ',
        color: BasicColor('35'), // #00AF5F
        bold: false,
        blockSuffix: '\n',
      ),
    ),
    strikethrough: GlamourPrimitiveStyle(crossedOut: true),
    emph: GlamourPrimitiveStyle(italic: true),
    strong: GlamourPrimitiveStyle(bold: true),
    horizontalRule: GlamourPrimitiveStyle(
      color: BasicColor('240'), // #585858
      format: '\n--------\n',
    ),
    item: GlamourPrimitiveStyle(blockPrefix: '• '),
    enumeration: GlamourPrimitiveStyle(blockPrefix: '. '),
    task: GlamourTaskStyle(ticked: '[✓] ', unticked: '[ ] '),
    link: GlamourPrimitiveStyle(
      color: BasicColor('30'), // #008787
      underline: true,
    ),
    linkText: GlamourPrimitiveStyle(
      color: BasicColor('35'), // #00AF5F
      bold: true,
    ),
    image: GlamourPrimitiveStyle(
      color: BasicColor('212'), // #FF5FD7
      underline: true,
    ),
    imageText: GlamourPrimitiveStyle(
      color: BasicColor('243'), // #767676
      format: 'Image: {{.text}} →',
    ),
    code: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        prefix: '\u00a0',
        suffix: '\u00a0',
        color: BasicColor('203'), // #FF5F5F
        backgroundColor: BasicColor('236'), // #303030
      ),
    ),
    codeBlock: GlamourCodeBlockStyle(
      style: GlamourBlockStyle(
        style: GlamourPrimitiveStyle(
          color: BasicColor('244'), // #808080
        ),
        margin: 2,
      ),
      chroma: ChromaTheme.dark,
    ),
    table: GlamourTableStyle(
      // centerSeparator: '|', // Implemented in renderer/table component
      // columnSeparator: '|',
      // rowSeparator: '-',
    ),
    definitionDescription: GlamourPrimitiveStyle(blockPrefix: '\n🠶 '),
  );

  static final GlamourTheme light = GlamourTheme(
    document: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        blockPrefix: '\n',
        blockSuffix: '\n',
        color: BasicColor('234'), // #1C1C1C
      ),
      margin: 2,
    ),
    blockQuote: GlamourBlockStyle(indent: 1, indentToken: '│ '),
    list: GlamourListStyle(levelIndent: 2),
    heading: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        blockSuffix: '\n',
        color: BasicColor('27'), // #005FFF
        bold: true,
      ),
    ),
    h1: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        prefix: ' ',
        suffix: ' ',
        color: BasicColor('228'),
        backgroundColor: BasicColor('63'),
        bold: true,
        blockSuffix: '\n',
      ),
    ),
    h2: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '## ', blockSuffix: '\n'),
    ),
    h3: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '### ', blockSuffix: '\n'),
    ),
    h4: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '#### ', blockSuffix: '\n'),
    ),
    h5: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '##### ', blockSuffix: '\n'),
    ),
    h6: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        prefix: '###### ',
        bold: false,
        blockSuffix: '\n',
      ),
    ),
    strikethrough: GlamourPrimitiveStyle(crossedOut: true),
    emph: GlamourPrimitiveStyle(italic: true),
    strong: GlamourPrimitiveStyle(bold: true),
    horizontalRule: GlamourPrimitiveStyle(
      color: BasicColor('249'), // #B2B2B2
      format: '\n--------\n',
    ),
    item: GlamourPrimitiveStyle(blockPrefix: '• '),
    enumeration: GlamourPrimitiveStyle(blockPrefix: '. '),
    task: GlamourTaskStyle(ticked: '[✓] ', unticked: '[ ] '),
    link: GlamourPrimitiveStyle(
      color: BasicColor('36'), // #00AF87
      underline: true,
    ),
    linkText: GlamourPrimitiveStyle(
      color: BasicColor('29'), // #00875F
      bold: true,
    ),
    image: GlamourPrimitiveStyle(
      color: BasicColor('205'), // #FF5F87
      underline: true,
    ),
    imageText: GlamourPrimitiveStyle(
      color: BasicColor('243'),
      format: 'Image: {{.text}} →',
    ),
    code: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        prefix: '\u00a0',
        suffix: '\u00a0',
        color: BasicColor('203'),
        backgroundColor: BasicColor('254'), // #E4E4E4
      ),
    ),
    codeBlock: GlamourCodeBlockStyle(
      style: GlamourBlockStyle(
        style: GlamourPrimitiveStyle(color: BasicColor('242')),
        margin: 2,
      ),
      chroma: ChromaTheme.light,
    ),
    definitionDescription: GlamourPrimitiveStyle(blockPrefix: '\n🠶 '),
  );

  static final GlamourTheme ascii = GlamourTheme(
    document: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(blockPrefix: '\n', blockSuffix: '\n'),
      margin: 2,
    ),
    blockQuote: GlamourBlockStyle(indent: 1, indentToken: '| '),
    list: GlamourListStyle(levelIndent: 4),
    heading: GlamourBlockStyle(style: GlamourPrimitiveStyle(blockSuffix: '\n')),
    h1: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '# ', blockSuffix: '\n'),
    ),
    h2: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '## ', blockSuffix: '\n'),
    ),
    h3: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '### ', blockSuffix: '\n'),
    ),
    h4: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '#### ', blockSuffix: '\n'),
    ),
    h5: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '##### ', blockSuffix: '\n'),
    ),
    h6: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '###### ', blockSuffix: '\n'),
    ),
    strikethrough: GlamourPrimitiveStyle(blockPrefix: '~~', blockSuffix: '~~'),
    emph: GlamourPrimitiveStyle(blockPrefix: '*', blockSuffix: '*'),
    strong: GlamourPrimitiveStyle(blockPrefix: '**', blockSuffix: '**'),
    horizontalRule: GlamourPrimitiveStyle(format: '\n--------\n'),
    item: GlamourPrimitiveStyle(blockPrefix: '* '),
    enumeration: GlamourPrimitiveStyle(blockPrefix: '. '),
    task: GlamourTaskStyle(ticked: '[x] ', unticked: '[ ] '),
    code: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(blockPrefix: '`', blockSuffix: '`'),
    ),
    codeBlock: GlamourCodeBlockStyle(style: GlamourBlockStyle(margin: 2)),
    definitionDescription: GlamourPrimitiveStyle(blockPrefix: '\n* '),
  );

  static final GlamourTheme pink = GlamourTheme(
    document: GlamourBlockStyle(margin: 2),
    blockQuote: GlamourBlockStyle(indent: 1, indentToken: '│ '),
    list: GlamourListStyle(levelIndent: 2),
    heading: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        blockSuffix: '\n',
        color: BasicColor('212'),
        bold: true,
      ),
    ),
    h1: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        blockPrefix: '\n',
        blockSuffix: '\n',
        prefix: '',
      ),
    ),
    h2: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '▌ ', blockSuffix: '\n'),
    ),
    h3: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '┃ ', blockSuffix: '\n'),
    ),
    h4: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '│ ', blockSuffix: '\n'),
    ),
    h5: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(prefix: '┆ ', blockSuffix: '\n'),
    ),
    h6: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        prefix: '┊ ',
        bold: false,
        blockSuffix: '\n',
      ),
    ),
    strikethrough: GlamourPrimitiveStyle(crossedOut: true),
    emph: GlamourPrimitiveStyle(italic: true),
    strong: GlamourPrimitiveStyle(bold: true),
    horizontalRule: GlamourPrimitiveStyle(
      color: BasicColor('212'),
      format: '\n──────\n',
    ),
    item: GlamourPrimitiveStyle(blockPrefix: '• '),
    enumeration: GlamourPrimitiveStyle(blockPrefix: '. '),
    task: GlamourTaskStyle(ticked: '[✓] ', unticked: '[ ] '),
    link: GlamourPrimitiveStyle(
      color: BasicColor('99'), // #875FFF
      underline: true,
    ),
    linkText: GlamourPrimitiveStyle(bold: true),
    image: GlamourPrimitiveStyle(underline: true),
    imageText: GlamourPrimitiveStyle(format: 'Image: {{.text}}'),
    code: GlamourBlockStyle(
      style: GlamourPrimitiveStyle(
        color: BasicColor('212'),
        backgroundColor: BasicColor('236'),
        prefix: '\u00a0',
        suffix: '\u00a0',
      ),
    ),
    definitionDescription: GlamourPrimitiveStyle(blockPrefix: '\n🠶 '),
  );
}

/// Represents `StyleBlock` in glamour.
class GlamourBlockStyle {
  const GlamourBlockStyle({
    this.style = const GlamourPrimitiveStyle(),
    this.margin,
    this.indent,
    this.indentToken,
  });

  final GlamourPrimitiveStyle style;
  final int? margin;
  final int? indent;
  final String? indentToken;

  factory GlamourBlockStyle.fromJson(Map<String, dynamic> json) {
    int? readInt(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    return GlamourBlockStyle(
      style: GlamourPrimitiveStyle.fromJson(json),
      margin: readInt('margin'),
      indent: readInt('indent'),
      indentToken: json['indent_token'] as String?,
    );
  }
}

/// Represents `StylePrimitive` in glamour.
///
/// This maps closely to artisanal's [Style], but includes additional
/// structure properties like prefixes and suffixes.
class GlamourPrimitiveStyle {
  const GlamourPrimitiveStyle({
    this.blockPrefix,
    this.blockSuffix,
    this.prefix,
    this.suffix,
    this.color,
    this.backgroundColor,
    this.bold,
    this.italic,
    this.underline,
    this.blink,
    this.crossedOut,
    this.faint,
    this.conceal,
    this.inverse,
    this.upper,
    this.lower,
    this.title,
    this.format,
  });

  final String? blockPrefix;
  final String? blockSuffix;
  final String? prefix;
  final String? suffix;
  final Color? color;
  final Color? backgroundColor;
  final bool? bold;
  final bool? italic;
  final bool? underline;
  final bool? blink;
  final bool? crossedOut;
  final bool? faint;
  final bool? conceal;
  final bool? inverse;
  final bool? upper;
  final bool? lower;
  final bool? title;
  final String? format;

  factory GlamourPrimitiveStyle.fromJson(Map<String, dynamic> json) {
    Color? parseColor(String key) {
      if (json.containsKey(key)) {
        return BasicColor(json[key].toString());
      }
      return null;
    }

    return GlamourPrimitiveStyle(
      blockPrefix: json['block_prefix'] as String?,
      blockSuffix: json['block_suffix'] as String?,
      prefix: json['prefix'] as String?,
      suffix: json['suffix'] as String?,
      color: parseColor('color'),
      backgroundColor: parseColor('background_color'),
      bold: json['bold'] as bool?,
      italic: json['italic'] as bool?,
      underline: json['underline'] as bool?,
      blink: json['blink'] as bool?,
      crossedOut: json['crossed_out'] as bool?,
      faint: json['faint'] as bool?,
      conceal: json['conceal'] as bool?,
      inverse: json['inverse'] as bool?,
      upper: json['upper'] as bool?,
      lower: json['lower'] as bool?,
      title: json['title'] as bool?,
      format: json['format'] as String?,
    );
  }

  /// Converts to an artisanal Style builder, excluding structure props.
  Style get toStyle {
    var s = Style();
    if (color != null) s = s.foreground(color!);
    if (backgroundColor != null) s = s.background(backgroundColor!);
    if (bold == true) s = s.bold();
    if (italic == true) s = s.italic();
    if (underline == true) s = s.underline();
    if (blink == true) s = s.blink();
    if (crossedOut == true) s = s.strikethrough();
    if (faint == true) s = s.faint();
    if (inverse == true) s = s.inverse();
    return s;
  }
}

/// Represents `StyleList` in glamour.
class GlamourListStyle {
  const GlamourListStyle({
    this.style = const GlamourBlockStyle(),
    this.levelIndent,
  });

  final GlamourBlockStyle style;
  final int? levelIndent;

  factory GlamourListStyle.fromJson(Map<String, dynamic> json) {
    int? readInt(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    return GlamourListStyle(
      style: GlamourBlockStyle.fromJson(json),
      levelIndent: readInt('level_indent'),
    );
  }
}

/// Represents `StyleTask` in glamour.
class GlamourTaskStyle {
  const GlamourTaskStyle({
    this.style = const GlamourPrimitiveStyle(),
    this.ticked = '[x] ',
    this.unticked = '[ ] ',
  });

  final GlamourPrimitiveStyle style;
  final String ticked;
  final String unticked;

  factory GlamourTaskStyle.fromJson(Map<String, dynamic> json) {
    return GlamourTaskStyle(
      style: GlamourPrimitiveStyle.fromJson(json),
      ticked: json['ticked'] as String? ?? '[x] ',
      unticked: json['unticked'] as String? ?? '[ ] ',
    );
  }
}

/// Represents `StyleCodeBlock` in glamour.
class GlamourCodeBlockStyle {
  const GlamourCodeBlockStyle({
    this.style = const GlamourBlockStyle(),
    this.theme,
    this.chroma,
  });

  final GlamourBlockStyle style;
  final String? theme;
  final ChromaTheme? chroma;

  factory GlamourCodeBlockStyle.fromJson(Map<String, dynamic> json) {
    ChromaTheme? chroma;
    if (json.containsKey('chroma') && json['chroma'] is Map) {
      chroma = ChromaTheme.fromJson(json['chroma'] as Map<String, dynamic>);
    }

    return GlamourCodeBlockStyle(
      style: GlamourBlockStyle.fromJson(json),
      theme: json['theme'] as String?,
      chroma: chroma,
    );
  }
}

/// Represents `StyleTable` in glamour.
class GlamourTableStyle {
  const GlamourTableStyle({
    this.style = const GlamourBlockStyle(),
    this.centerSeparator,
    this.columnSeparator,
    this.rowSeparator,
  });

  final GlamourBlockStyle style;
  final String? centerSeparator;
  final String? columnSeparator;
  final String? rowSeparator;

  factory GlamourTableStyle.fromJson(Map<String, dynamic> json) {
    return GlamourTableStyle(
      style: GlamourBlockStyle.fromJson(json),
      centerSeparator: json['center_separator'] as String?,
      columnSeparator: json['column_separator'] as String?,
      rowSeparator: json['row_separator'] as String?,
    );
  }
}
