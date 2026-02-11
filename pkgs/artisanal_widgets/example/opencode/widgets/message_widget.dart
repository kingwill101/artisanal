/// Message widget for the OpenCode chat UI.
///
/// Renders chat messages matching the real OpenCode style:
/// - User messages: left ┃ border colored by agent, backgroundPanel bg
/// - Assistant messages: text parts with paddingLeft:3, tool parts inline/block
/// - Footer: ▣ agent · model · duration
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/markdown.dart' as markdown;
import 'package:artisanal/tui.dart' show Cmd;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

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
    this.showDiffContextBackground = false,
    this.onExpandDelta,
    super.key,
  });

  final ChatMessage message;
  final int index;
  final bool showDiffContextBackground;
  final void Function(int delta)? onExpandDelta;

  @override
  w.Widget build(w.BuildContext context) {
    if (message.role == MessageRole.user) {
      return _UserMessage(message: message, index: index);
    }
    return _AssistantMessage(
      key: w.ValueKey('assistant-${message.id}'),
      message: message,
      showDiffContextBackground: showDiffContextBackground,
      onExpandDelta: onExpandDelta,
    );
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

    return w.Padding(
      padding: w.EdgeInsets.only(top: index == 0 ? 0 : 1),
      child: LeftAccentPane(
        accentColor: color,
        backgroundColor: OC.backgroundPanel,
        padding: const w.EdgeInsets.only(left: 2, top: 1, bottom: 1),
        child: w.Text(
          message.text ?? '',
          style: style.Style()..foreground(OC.text),
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
    required this.showDiffContextBackground,
    this.onExpandDelta,
    super.key,
  });

  final ChatMessage message;
  final bool showDiffContextBackground;
  final void Function(int delta)? onExpandDelta;

  @override
  w.State createState() => _AssistantMessageState();
}

class _AssistantMessageState extends w.State<_AssistantMessage> {
  /// Tracks which block tools are expanded (by index in the parts list).
  final Set<int> _expandedBlocks = {};

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
            parts.add(_buildBlockTool(context, part, i));
          } else {
            parts.add(_buildInlineTool(context, part));
          }
        case DiffPart():
          parts.add(_buildDiffPart(context, part, i));
      }
    }

    // Footer: ▣ Agent · model · duration
    if (widget.message.isLast || widget.message.duration != null) {
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

    return markdown.AnsiRendererOptions(
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
  }

  style.Color _themeColor(String key, style.Color fallback) {
    return openCodeThemeColor(key, fallback: fallback);
  }

  w.DiffStyles _diffStyles() {
    final added = _themeColor('diffAdded', OC.diffAdded);
    final removed = _themeColor('diffRemoved', OC.diffRemoved);
    final context = _themeColor('diffContext', OC.textMuted);
    final text = _themeColor('text', OC.text);
    final hunk = _themeColor('diffHunkHeader', context);
    final addedBg = _themeColor(
      'diffAddedBg',
      const style.BasicColor('#17361f'),
    );
    final removedBg = _themeColor(
      'diffRemovedBg',
      const style.BasicColor('#3f1a1f'),
    );
    final contextBg = _themeColor('diffContextBg', OC.backgroundPanel);
    final lineNumber = _themeColor('diffLineNumber', OC.textMuted);
    final addedNumberBg = _themeColor('diffAddedLineNumberBg', addedBg);
    final removedNumberBg = _themeColor('diffRemovedLineNumberBg', removedBg);
    final highlightAdded = _themeColor('diffHighlightAdded', added);
    final highlightRemoved = _themeColor('diffHighlightRemoved', removed);

    return w.DiffStyles(
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

  /// Block tool: bordered panel with title + content.
  ///
  /// When the tool has a [ToolPart.diff], renders a collapsible trigger row
  /// (icon + toolName + filePath + +N/-M) that expands to reveal a
  /// [w.GitDiffViewer] — matching the real OpenCode "Collapsible" pattern.
  w.Widget _buildBlockTool(w.BuildContext context, ToolPart part, int index) {
    final hasDiff = part.diff != null && part.diff!.isNotEmpty;
    final expanded = _expandedBlocks.contains(index);

    // Collapsible trigger row for diff tools
    if (hasDiff) {
      return _buildDiffCollapsible(context, part, index, expanded);
    }

    // Non-diff block: bordered panel with title + content/spinner
    final isRunning = part.status == ToolStatus.running;
    final isPending = part.status == ToolStatus.pending;
    final borderColor = isRunning ? OC.primary : OC.borderSubtle;

    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1),
      child: LeftAccentPane(
        accentColor: borderColor,
        backgroundColor: OC.backgroundPanel,
        padding: const w.EdgeInsets.only(left: 2, top: 1, bottom: 1),
        child: w.Column(
          gap: 1,
          children: [
            // Title row with spinner
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
                    part.title.isNotEmpty ? part.title : '# ${part.toolName}',
                    style: style.Style()
                      ..foreground(
                        isRunning || isPending ? OC.text : OC.textMuted,
                      ),
                  ),
                ],
              ),
            ),
            // Output (only when completed)
            if (part.output.isNotEmpty && !isRunning && !isPending)
              w.Padding(
                padding: const w.EdgeInsets.only(left: 3),
                child: w.Text(
                  part.output,
                  style: style.Style()..foreground(OC.text),
                ),
              ),
            // Error
            if (part.error != null)
              w.Padding(
                padding: const w.EdgeInsets.only(left: 3),
                child: w.Text(
                  part.error!,
                  style: style.Style()..foreground(OC.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Collapsible diff panel — matches real OpenCode Collapsible component.
  ///
  /// ```
  /// ┌───────────────────────────────────────────────┐
  /// │  [Icon] Edit  filename.dart  dir/  +5 -3  ▾  │  ← trigger
  /// ├───────────────────────────────────────────────┤
  /// │  (GitDiffViewer — pretty mode)                │  ← content
  /// └───────────────────────────────────────────────┘
  /// ```
  w.Widget _buildDiffCollapsible(
    w.BuildContext context,
    ToolPart part,
    int index,
    bool expanded,
  ) {
    final fileName = part.filePath?.split('/').last ?? '';
    final dirPath = part.filePath != null && part.filePath!.contains('/')
        ? part.filePath!.substring(0, part.filePath!.lastIndexOf('/') + 1)
        : '';
    final diffHeight = _expandedDiffHeight(part.diff ?? '');

    // Parse additions/deletions from the diff string
    final addCount = '+'
        .allMatches(
          part.diff!
              .split('\n')
              .where((l) => l.startsWith('+') && !l.startsWith('+++'))
              .join(),
        )
        .length;
    final delCount = '-'
        .allMatches(
          part.diff!
              .split('\n')
              .where((l) => l.startsWith('-') && !l.startsWith('---'))
              .join(),
        )
        .length;

    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1),
      child: LeftAccentPane(
        accentColor: OC.borderSubtle,
        backgroundColor: OC.backgroundPanel,
        child: w.Column(
          gap: 0,
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            // Trigger row
            w.GestureDetector(
              onTap: () {
                var becameExpanded = false;
                setState(() {
                  if (expanded) {
                    _expandedBlocks.remove(index);
                  } else {
                    _expandedBlocks.add(index);
                    becameExpanded = true;
                  }
                });
                if (becameExpanded) {
                  widget.onExpandDelta?.call((diffHeight ~/ 3).clamp(3, 10));
                }
                return Cmd.repaint();
              },
              child: w.Container(
                padding: const w.EdgeInsets.only(
                  left: 2,
                  right: 2,
                  top: 1,
                  bottom: 1,
                ),
                child: w.Row(
                  children: [
                    // Icon
                    w.Text(
                      part.icon,
                      style: style.Style()..foreground(OC.textMuted),
                    ),
                    w.SizedBox(width: 1),
                    // Tool name
                    w.Text(
                      part.title.isNotEmpty ? part.title : part.toolName,
                      style: style.Style()..foreground(OC.text),
                    ),
                    w.SizedBox(width: 1),
                    // Filename (bright)
                    w.Text(
                      fileName,
                      style: style.Style()..foreground(OC.text),
                      softWrap: false,
                    ),
                    w.SizedBox(width: 1),
                    // Directory (muted)
                    if (dirPath.isNotEmpty)
                      w.Text(
                        dirPath,
                        style: style.Style()..foreground(OC.textMuted),
                        softWrap: false,
                      ),
                    w.Spacer(),
                    // +N -M counts
                    w.Text(
                      '+$addCount',
                      style: style.Style()..foreground(OC.diffAdded),
                    ),
                    w.SizedBox(width: 1),
                    w.Text(
                      '-$delCount',
                      style: style.Style()..foreground(OC.diffRemoved),
                    ),
                    w.SizedBox(width: 1),
                    // Expand/collapse indicator
                    w.Text(
                      expanded ? '\u25bc' : '\u25b6',
                      style: style.Style()..foreground(OC.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            // Diff content (visible when expanded)
            if (expanded) ...[
              // Separator
              w.Container(color: OC.borderSubtle, height: 1),
              // Diff viewer
              w.GitDiffViewer(
                diff: part.diff!,
                viewMode: w.DiffViewMode.pretty,
                showLineNumbers: true,
                wrapLines: true,
                handleKeys: false,
                scrollable: false,
                fitContentHeight: true,
                styles: _diffStyles(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Compute expanded diff height that fills more of the chat body.
  int _expandedDiffHeight(String diff) {
    final lines = diff.split('\n').length;
    return lines < 1 ? 1 : lines;
  }

  /// Standalone diff part — collapsible file diff viewer.
  ///
  /// Renders a file header row (icon + filename + dir + +N/-M + chevron)
  /// that expands to show a [w.GitDiffViewer].
  w.Widget _buildDiffPart(w.BuildContext context, DiffPart part, int index) {
    final expanded = _expandedBlocks.contains(index);
    final fileName = part.filePath.split('/').last;
    final dirPath = part.filePath.contains('/')
        ? part.filePath.substring(0, part.filePath.lastIndexOf('/') + 1)
        : '';
    final diffHeight = _expandedDiffHeight(part.diff);

    return w.Padding(
      padding: const w.EdgeInsets.only(top: 1),
      child: LeftAccentPane(
        accentColor: OC.borderSubtle,
        backgroundColor: OC.backgroundPanel,
        child: w.Column(
          gap: 0,
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            // Header row — clickable trigger
            w.GestureDetector(
              onTap: () {
                var becameExpanded = false;
                setState(() {
                  if (expanded) {
                    _expandedBlocks.remove(index);
                  } else {
                    _expandedBlocks.add(index);
                    becameExpanded = true;
                  }
                });
                if (becameExpanded) {
                  widget.onExpandDelta?.call((diffHeight ~/ 3).clamp(3, 10));
                }
                return Cmd.repaint();
              },
              child: w.Container(
                padding: const w.EdgeInsets.only(
                  left: 2,
                  right: 2,
                  top: 1,
                  bottom: 1,
                ),
                child: w.Row(
                  children: [
                    // File icon
                    w.Text(
                      '\u{1F4C4}',
                      style: style.Style()..foreground(OC.textMuted),
                    ),
                    w.SizedBox(width: 1),
                    // Filename (bright)
                    w.Text(
                      fileName,
                      style: style.Style()
                        ..foreground(OC.text)
                        ..bold(),
                      softWrap: false,
                    ),
                    w.SizedBox(width: 1),
                    // Directory (muted)
                    if (dirPath.isNotEmpty)
                      w.Text(
                        dirPath,
                        style: style.Style()..foreground(OC.textMuted),
                        softWrap: false,
                      ),
                    w.Spacer(),
                    // +N -M counts
                    w.Text(
                      '+${part.additions}',
                      style: style.Style()..foreground(OC.diffAdded),
                    ),
                    w.SizedBox(width: 1),
                    w.Text(
                      '-${part.deletions}',
                      style: style.Style()..foreground(OC.diffRemoved),
                    ),
                    w.SizedBox(width: 1),
                    // Change bar visualization (up to 5 blocks)
                    _buildChangeBar(part.additions, part.deletions),
                    w.SizedBox(width: 1),
                    // Expand/collapse indicator
                    w.Text(
                      expanded ? '\u25bc' : '\u25b6',
                      style: style.Style()..foreground(OC.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            // Diff content (visible when expanded)
            if (expanded) ...[
              // Separator
              w.Container(color: OC.borderSubtle, height: 1),
              // Diff viewer
              w.GitDiffViewer(
                diff: part.diff,
                viewMode: w.DiffViewMode.pretty,
                showLineNumbers: true,
                wrapLines: true,
                handleKeys: false,
                scrollable: false,
                fitContentHeight: true,
                styles: _diffStyles(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a small colored bar showing change proportions (like GitHub).
  /// Up to 5 blocks: green for additions, red for deletions.
  w.Widget _buildChangeBar(int additions, int deletions) {
    final total = additions + deletions;
    if (total == 0) return w.SizedBox(width: 5);

    const maxBlocks = 5;
    final addBlocks = (additions / total * maxBlocks).round().clamp(
      0,
      maxBlocks,
    );
    final delBlocks = maxBlocks - addBlocks;

    final blocks = <w.Widget>[];
    for (var i = 0; i < addBlocks; i++) {
      blocks.add(
        w.Text('\u2588', style: style.Style()..foreground(OC.diffAdded)),
      );
    }
    for (var i = 0; i < delBlocks; i++) {
      blocks.add(
        w.Text('\u2588', style: style.Style()..foreground(OC.diffRemoved)),
      );
    }
    return w.Row(gap: 0, children: blocks);
  }

  /// Footer: `▣ Agent · model · duration`
  w.Widget _buildFooter(w.BuildContext context) {
    final color = agentColor(widget.message.agent);
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
        ],
      ),
    );
  }
}
