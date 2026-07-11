/// Message widget for the OpenCode chat UI.
///
/// Renders chat messages matching the real OpenCode style.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/artisanal.dart' as markdown;
import 'package:artisanal/tui.dart' show Cmd;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/message.dart';
import '../theme.dart';
import 'left_accent_pane.dart';
import 'prompt_input.dart' show agentColor;

/// Braille spinner frames matching the real OpenCode spinner.
const _brailleFrames = [
  '\u280b', // ⠋
  '\u2819', // ⠙
  '\u2839', // ⠹
  '\u2838', // ⠸
  '\u283c', // ⠼
  '\u2834', // ⠴
  '\u2826', // ⠦
  '\u2827', // ⠧
  '\u2807', // ⠇
  '\u280f', // ⠏
];

/// Renders a single [ChatMessage].
class MessageWidget extends w.StatelessWidget {
  MessageWidget({
    required this.message,
    this.index = 0,
    this.showDiffs = true,
    this.showDiffContextBackground = false,
    super.key,
  });

  final ChatMessage message;
  final int index;
  final bool showDiffs;
  final bool showDiffContextBackground;

  @override
  w.Widget build(w.BuildContext context) {
    switch (message.role) {
      case MessageRole.user:
        return _UserMessage(message: message, index: index);
      case MessageRole.system:
        return _SystemMessage(message: message, index: index);
      case MessageRole.assistant:
        return _AssistantMessage(
          key: w.ValueKey('assistant-${message.id}'),
          message: message,
          showDiffs: showDiffs,
          showDiffContextBackground: showDiffContextBackground,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User message
// ─────────────────────────────────────────────────────────────────────────────

class _UserMessage extends w.StatelessWidget {
  _UserMessage({required this.message, this.index = 0});

  final ChatMessage message;
  final int index;

  @override
  w.Widget build(w.BuildContext context) {
    final color = agentColor(message.agent);
    final content = <w.Widget>[
      w.Text(message.text ?? '', style: style.Style()..foreground(OC.text)),
    ];
    if (message.files.isNotEmpty) {
      content.add(
        w.Wrap(
          spacing: 1,
          runSpacing: 1,
          children: [for (final file in message.files) _buildFileChip(file)],
        ),
      );
    }

    final metadata = _buildMetadata();
    if (metadata != null) {
      content.add(metadata);
    }

    final children = <w.Widget>[
      LeftAccentPane(
        accentColor: color,
        backgroundColor: OC.backgroundPanel,
        padding: const w.EdgeInsets.only(left: 2, top: 1, bottom: 1),
        child: w.Column(
          gap: 1,
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: content,
        ),
      ),
    ];
    if (message.showCompaction) {
      children.add(_buildCompactionMarker());
    }

    return w.Padding(
      padding: w.EdgeInsets.only(top: index == 0 ? 0 : 1),
      child: w.Column(gap: 0, children: children),
    );
  }

  w.Widget _buildFileChip(UserFilePart file) {
    final badgeColor = switch (file.mime) {
      'application/pdf' => OC.primary,
      _ when file.mime.startsWith('image/') => OC.accent,
      _ => OC.secondary,
    };
    final badge = _mimeBadge(file.mime);

    return w.Row(
      gap: 1,
      children: [
        w.Text(
          ' $badge ',
          style: style.Style()
            ..foreground(OC.background)
            ..background(badgeColor)
            ..bold(),
        ),
        w.Text(
          ' ${file.filename} ',
          style: style.Style()
            ..foreground(OC.textMuted)
            ..background(OC.backgroundElement),
        ),
      ],
    );
  }

  w.Widget? _buildMetadata() {
    if (message.queued) {
      return w.Text(
        ' QUEUED ',
        style: style.Style()
          ..foreground(OC.background)
          ..background(agentColor(message.agent))
          ..bold(),
      );
    }
    final timestamp = message.timestamp;
    if (timestamp == null) return null;
    return w.Text(
      _formatTimestamp(timestamp),
      style: style.Style()..foreground(OC.textMuted),
    );
  }

  w.Widget _buildCompactionMarker() {
    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1),
      child: w.Row(
        children: [
          w.Expanded(child: w.Container(color: OC.borderActive, height: 1)),
          w.Text(
            ' Compaction ',
            style: style.Style()..foreground(OC.textMuted),
          ),
          w.Expanded(child: w.Container(color: OC.borderActive, height: 1)),
        ],
      ),
    );
  }

  String _mimeBadge(String mime) {
    return switch (mime) {
      'text/plain' => 'txt',
      'application/pdf' => 'pdf',
      _ when mime.startsWith('image/') => 'img',
      _ when mime == 'application/x-directory' => 'dir',
      _ => mime,
    };
  }

  String _formatTimestamp(DateTime value) {
    final now = DateTime.now();
    final sameDay =
        now.year == value.year &&
        now.month == value.month &&
        now.day == value.day;
    if (sameDay) {
      final hh = value.hour.toString().padLeft(2, '0');
      final mm = value.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return '${value.month}/${value.day}';
  }
}

class _SystemMessage extends w.StatelessWidget {
  _SystemMessage({required this.message, this.index = 0});

  final ChatMessage message;
  final int index;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Padding(
      padding: w.EdgeInsets.only(top: index == 0 ? 0 : 1),
      child: LeftAccentPane(
        accentColor: OC.borderSubtle,
        backgroundColor: OC.backgroundPanel,
        padding: const w.EdgeInsets.only(left: 2, top: 1, bottom: 1),
        child: w.Text(
          message.text ?? '',
          style: style.Style()..foreground(OC.textMuted),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assistant message
// ─────────────────────────────────────────────────────────────────────────────

class _AssistantMessage extends w.StatefulWidget {
  _AssistantMessage({
    required this.message,
    required this.showDiffs,
    required this.showDiffContextBackground,
    super.key,
  });

  final ChatMessage message;
  final bool showDiffs;
  final bool showDiffContextBackground;

  @override
  w.State createState() => _AssistantMessageState();
}

class _AssistantMessageState extends w.State<_AssistantMessage> {
  w.DiffStyles? _cachedDiffStyles;
  bool? _cachedDiffStylesContextBg;
  markdown.AnsiRendererOptions? _cachedMarkdownOptions;

  @override
  Cmd? didUpdateWidget(covariant _AssistantMessage oldWidget) {
    final cmd = super.didUpdateWidget(oldWidget);
    if (oldWidget.showDiffContextBackground !=
        widget.showDiffContextBackground) {
      _cachedDiffStyles = null;
      _cachedDiffStylesContextBg = null;
    }
    if (oldWidget.showDiffs != widget.showDiffs) {
      _cachedDiffStyles = null;
      _cachedDiffStylesContextBg = null;
    }
    if (oldWidget.message.id != widget.message.id) {
      _cachedMarkdownOptions = null;
    }
    return cmd;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final parts = <w.Widget>[];

    for (var i = 0; i < widget.message.parts.length; i++) {
      final part = widget.message.parts[i];
      switch (part) {
        case TextPart():
          if (part.text.trim().isNotEmpty) {
            parts.add(_buildTextPart(context, part));
          }
        case ReasoningPart():
          if (part.text.trim().isNotEmpty) {
            parts.add(_buildReasoningPart(context, part));
          }
        case ToolPart():
          if (part.isBlock) {
            parts.add(_buildBlockTool(context, part));
          } else {
            parts.add(_buildInlineTool(context, part));
          }
        case DiffPart():
          parts.add(_buildDiffPart(context, part));
      }
    }

    if (widget.message.errorMessage != null && !widget.message.interrupted) {
      parts.add(_buildAssistantError(context, widget.message.errorMessage!));
    }

    if (widget.message.isLast ||
        widget.message.duration != null ||
        widget.message.errorMessage != null ||
        widget.message.interrupted) {
      parts.add(_buildFooter(context));
    }

    return w.Column(gap: 0, children: parts);
  }

  /// Text part: paddingLeft 3, marginTop 1, markdown rendered.
  w.Widget _buildTextPart(w.BuildContext context, TextPart part) {
    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1),
      child: w.MarkdownText(
        data: part.text.trim(),
        textStyle: style.Style()
          ..foreground(_themeColor('markdownText', OC.text)),
        options: _markdownOptions(),
      ),
    );
  }

  markdown.AnsiRendererOptions _markdownOptions() {
    final cached = _cachedMarkdownOptions;
    if (cached != null) return cached;

    final text = _themeColor('markdownText', OC.text);
    final heading = _themeColor('markdownHeading', OC.accent);
    final linkText = _themeColor(
      'markdownLinkText',
      _themeColor('markdownLink', OC.primary),
    );
    final code = _themeColor('markdownCode', OC.success);
    final quote = _themeColor('markdownBlockQuote', OC.warning);
    final emph = _themeColor('markdownEmph', OC.warning);
    final strong = _themeColor('markdownStrong', OC.warning);
    final hr = _themeColor('markdownHorizontalRule', OC.textMuted);
    final listItem = _themeColor('markdownListItem', OC.primary);
    final codeBlock = _themeColor('markdownCodeBlock', text);
    final syntaxComment = _themeColor('syntaxComment', OC.textMuted);
    final syntaxKeyword = _themeColor('syntaxKeyword', OC.accent);
    final syntaxFunction = _themeColor('syntaxFunction', OC.secondary);
    final syntaxVariable = _themeColor('syntaxVariable', text);
    final syntaxString = _themeColor('syntaxString', OC.info);
    final syntaxNumber = _themeColor('syntaxNumber', OC.warning);
    final syntaxType = _themeColor('syntaxType', OC.warning);
    final syntaxOperator = _themeColor('syntaxOperator', OC.accent);
    final syntaxPunctuation = _themeColor('syntaxPunctuation', text);

    final options = markdown.AnsiRendererOptions(
      textStyle: style.Style().foreground(text),
      h1Style: style.Style().bold().foreground(heading),
      h2Style: style.Style().bold().foreground(heading),
      h3Style: style.Style().bold().foreground(heading),
      h4Style: style.Style().bold().foreground(heading),
      h5Style: style.Style().bold().foreground(heading),
      h6Style: style.Style().bold().foreground(heading),
      emphasisStyle: style.Style().italic().foreground(emph),
      strongStyle: style.Style().bold().foreground(strong),
      codeStyle: style.Style().foreground(code),
      codeBlockStyle: style.Style().foreground(codeBlock),
      linkStyle: style.Style().foreground(linkText).underline(),
      blockquoteStyle: style.Style().foreground(quote),
      blockquoteBorderColor: quote,
      tableHeaderStyle: style.Style().bold().foreground(listItem),
      tableCellStyle: style.Style().foreground(text),
      tableBorderStyle: style.Style().foreground(hr),
      bulletChar: '-',
      syntaxHighlighting: true,
      syntaxTheme: markdown.ChromaTheme(
        text: style.Style().foreground(text),
        comment: style.Style().foreground(syntaxComment).italic(),
        keyword: style.Style().foreground(syntaxKeyword),
        keywordReserved: style.Style().foreground(syntaxKeyword).italic(),
        keywordType: style.Style().foreground(syntaxType),
        operator: style.Style().foreground(syntaxOperator),
        punctuation: style.Style().foreground(syntaxPunctuation),
        name: style.Style().foreground(text),
        nameFunction: style.Style().foreground(syntaxFunction),
        nameClass: style.Style().foreground(syntaxType).bold(),
        nameBuiltin: style.Style().foreground(syntaxKeyword),
        literalString: style.Style().foreground(syntaxString),
        literalNumber: style.Style().foreground(syntaxNumber),
        nameOther: style.Style().foreground(syntaxVariable),
      ),
    );
    _cachedMarkdownOptions = options;
    return options;
  }

  style.Color _themeColor(String key, style.Color fallback) {
    return openCodeThemeColor(key, fallback: fallback);
  }

  w.DiffStyles _diffStyles() {
    if (_cachedDiffStyles != null &&
        _cachedDiffStylesContextBg == widget.showDiffContextBackground) {
      return _cachedDiffStyles!;
    }

    final added = _themeColor('diffAdded', OC.diffAdded);
    final removed = _themeColor('diffRemoved', OC.diffRemoved);
    final context = _themeColor('diffContext', OC.textMuted);
    final text = _themeColor('text', OC.text);
    final hunk = _themeColor('diffHunkHeader', context);
    final addedBg = _themeColor('diffAddedBg', OC.backgroundElement);
    final removedBg = _themeColor('diffRemovedBg', OC.backgroundElement);
    final contextBg = _themeColor('diffContextBg', OC.backgroundPanel);
    final lineNumber = _themeColor('diffLineNumber', OC.textMuted);
    final addedNumberBg = _themeColor('diffAddedLineNumberBg', addedBg);
    final removedNumberBg = _themeColor('diffRemovedLineNumberBg', removedBg);
    final highlightAdded = _themeColor('diffHighlightAdded', added);
    final highlightRemoved = _themeColor('diffHighlightRemoved', removed);

    final styles = w.DiffStyles(
      addedLine: style.Style().foreground(text),
      removedLine: style.Style().foreground(text),
      contextLine: style.Style().foreground(text),
      fileHeader: style.Style().bold().foreground(text),
      hunkHeader: style.Style().foreground(hunk),
      addedGutter: style.Style().bold().foreground(added),
      removedGutter: style.Style().bold().foreground(removed),
      contextGutter: style.Style().foreground(lineNumber),
      lineNumber: style.Style().foreground(lineNumber),
      prettyAddedLine: style.Style().foreground(text).background(addedBg),
      prettyRemovedLine: style.Style().foreground(text).background(removedBg),
      prettyContextLine: widget.showDiffContextBackground
          ? style.Style().foreground(text).background(contextBg)
          : style.Style().foreground(text),
      prettyFileHeader: style.Style().foreground(OC.textMuted),
      prettyAddedLineNumber: style.Style()
          .foreground(lineNumber)
          .background(addedNumberBg),
      prettyRemovedLineNumber: style.Style()
          .foreground(lineNumber)
          .background(removedNumberBg),
      prettyContextLineNumber: style.Style().foreground(lineNumber),
      sideBySideSeparator: style.Style().foreground(OC.borderSubtle),
      sideBySideAddedLine: style.Style().foreground(text).background(addedBg),
      sideBySideRemovedLine: style.Style()
          .foreground(text)
          .background(removedBg),
      sideBySideContextLine: widget.showDiffContextBackground
          ? style.Style().foreground(text).background(contextBg)
          : style.Style().foreground(text),
      sideBySideLineNumber: style.Style().foreground(lineNumber),
      sideBySideEmptyCell: style.Style().foreground(OC.textMuted),
      sideBySideAddedMarker: style.Style().foreground(added),
      sideBySideRemovedMarker: style.Style().foreground(removed),
      sideBySideContextMarker: style.Style().foreground(lineNumber),
      inlineAddedHighlight: style.Style().background(highlightAdded),
      inlineRemovedHighlight: style.Style().background(highlightRemoved),
    );
    _cachedDiffStyles = styles;
    _cachedDiffStylesContextBg = widget.showDiffContextBackground;
    return styles;
  }

  /// Reasoning part: left ┃ border, muted text, "Thinking: " prefix.
  w.Widget _buildReasoningPart(w.BuildContext context, ReasoningPart part) {
    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1),
      child: LeftAccentPane(
        accentColor: OC.backgroundElement,
        padding: const w.EdgeInsets.only(left: 1),
        child: w.Text(
          '_Thinking:_ ${part.text}',
          style: style.Style()
            ..foreground(OC.textMuted)
            ..dim(),
        ),
      ),
    );
  }

  /// Inline tool: single line with icon + description.
  ///
  /// When pending/running, shows a braille spinner. When completed, shows icon.
  /// `{icon/spinner} {toolName} {input}`
  w.Widget _buildInlineTool(w.BuildContext context, ToolPart part) {
    final isRunning = part.status == ToolStatus.running;
    final isPending =
        part.status == ToolStatus.pending || part.status == ToolStatus.running;
    final isError = part.status == ToolStatus.error;

    final fg = isPending
        ? OC.text
        : isError
        ? OC.error
        : OC.textMuted;

    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1),
      child: w.Column(
        gap: 0,
        children: [
          w.Row(
            gap: 1,
            children: [
              if (isRunning)
                w.SpinnerIndicator(
                  frames: _brailleFrames,
                  interval: const Duration(milliseconds: 80),
                  color: OC.primary,
                )
              else if (isPending)
                w.Text('\u22ef', style: style.Style()..foreground(OC.textMuted))
              else if (isError)
                w.Text('\u2717', style: style.Style()..foreground(OC.error))
              else
                w.Text(part.icon, style: style.Style()..foreground(fg)),
              w.Text(
                _inlineLabel(part),
                style: style.Style()..foreground(fg),
                softWrap: false,
              ),
            ],
          ),
          if (part.error != null)
            w.Padding(
              padding: const w.EdgeInsets.only(left: 2),
              child: w.Text(
                part.error!,
                style: style.Style()..foreground(OC.error),
              ),
            ),
        ],
      ),
    );
  }

  String _inlineLabel(ToolPart part) {
    if (part.filePath != null) {
      return '${part.title.isNotEmpty ? part.title : part.toolName} '
          '${part.filePath}';
    }
    if (part.input.isNotEmpty) {
      return '${part.title.isNotEmpty ? part.title : part.toolName} '
          '${part.input}';
    }
    return part.title.isNotEmpty ? part.title : part.toolName;
  }

  w.Widget _buildBlockTool(w.BuildContext context, ToolPart part) {
    final hasDiff = part.diff != null && part.diff!.isNotEmpty;
    final isRunning = part.status == ToolStatus.running;
    final isPending = part.status == ToolStatus.pending;
    final title = part.title.isNotEmpty ? part.title : '# ${part.toolName}';

    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1),
      child: LeftAccentPane(
        accentColor: isRunning ? OC.primary : OC.backgroundElement,
        backgroundColor: OC.backgroundPanel,
        padding: const w.EdgeInsets.only(left: 2, top: 1, bottom: 1),
        child: w.Column(
          gap: 1,
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Padding(
              padding: const w.EdgeInsets.only(left: 3),
              child: w.Row(
                gap: 1,
                children: [
                  if (isRunning)
                    w.SpinnerIndicator(
                      frames: _brailleFrames,
                      interval: const Duration(milliseconds: 80),
                      color: OC.primary,
                    )
                  else if (isPending)
                    w.Text(
                      '\u22ef',
                      style: style.Style()..foreground(OC.textMuted),
                    ),
                  w.Text(
                    title,
                    style: style.Style()
                      ..foreground(
                        isRunning || isPending ? OC.text : OC.textMuted,
                      ),
                  ),
                ],
              ),
            ),
            if (hasDiff && widget.showDiffs)
              w.Padding(
                padding: const w.EdgeInsets.only(left: 1),
                child: _buildDiffViewer(part.diff!),
              )
            else if (hasDiff)
              w.Padding(
                padding: const w.EdgeInsets.only(left: 1),
                child: w.Text(
                  '[diff disabled]',
                  style: style.Style()..foreground(OC.textMuted),
                ),
              )
            else if (part.output.isNotEmpty && !isRunning && !isPending)
              w.Text(part.output, style: style.Style()..foreground(OC.text)),
            if (part.error != null)
              w.Text(part.error!, style: style.Style()..foreground(OC.error)),
          ],
        ),
      ),
    );
  }

  w.Widget _buildDiffViewer(String diff) {
    return w.GitDiffViewer(
      diff: diff,
      viewMode: w.DiffViewMode.pretty,
      showLineNumbers: true,
      wrapLines: true,
      handleKeys: false,
      scrollable: false,
      fitContentHeight: true,
      styles: _diffStyles(),
    );
  }

  w.Widget _buildDiffPart(w.BuildContext context, DiffPart part) {
    if (!widget.showDiffs) {
      return w.Padding(
        padding: const w.EdgeInsets.only(top: 1, left: 3),
        child: w.Text(
          '[diff disabled]',
          style: style.Style()..foreground(OC.textMuted),
        ),
      );
    }

    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1, left: 3),
      child: _buildDiffViewer(part.diff),
    );
  }

  w.Widget _buildAssistantError(w.BuildContext context, String errorMessage) {
    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1),
      child: LeftAccentPane(
        accentColor: OC.error,
        backgroundColor: OC.backgroundPanel,
        padding: const w.EdgeInsets.only(left: 2, top: 1, bottom: 1),
        child: w.Text(
          errorMessage,
          style: style.Style()..foreground(OC.textMuted),
        ),
      ),
    );
  }

  /// Footer: `▣ Agent · model · duration`
  w.Widget _buildFooter(w.BuildContext context) {
    final interrupted = widget.message.interrupted;
    final color = interrupted ? OC.textMuted : agentColor(widget.message.agent);
    final agentLabel =
        '${widget.message.agent[0].toUpperCase()}${widget.message.agent.substring(1)}';
    final modelId = widget.message.modelId ?? '';
    final dur = widget.message.duration;
    final durStr = dur != null ? '${dur.inSeconds}s' : null;

    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1),
      child: w.Row(
        gap: 0,
        children: [
          w.Text('\u25a3 ', style: style.Style()..foreground(color)),
          w.Text(agentLabel, style: style.Style()..foreground(OC.text)),
          if (modelId.isNotEmpty)
            w.Text(
              ' \u00b7 $modelId',
              style: style.Style()..foreground(OC.textMuted),
            ),
          if (durStr != null)
            w.Text(
              ' \u00b7 $durStr',
              style: style.Style()..foreground(OC.textMuted),
            ),
          if (interrupted)
            w.Text(
              ' \u00b7 interrupted',
              style: style.Style()..foreground(OC.textMuted),
            ),
        ],
      ),
    );
  }
}
