import 'dart:math' as math;

import '../../style/ranges.dart' as ranges;
import '../../style/style.dart';
import '../../uv/wrap.dart' as uv_wrap;
import '../cmd.dart';
import '../msg.dart';
import 'viewport.dart';

/// A high-level text component that supports selection, scrolling, and wrapping.
/// It is built on top of [ViewportModel] but defaults to auto-height and soft-wrap.
class TextModel extends ViewportModel {
  final List<ranges.StyleRange> styleRanges;

  TextModel.withOptions({
    super.width = 80,
    super.height,
    super.gutter = 0,
    super.yOffset = 0,
    super.xOffset = 0,
    super.mouseWheelEnabled = true,
    super.mouseWheelDelta = 3,
    super.horizontalStep = 0,
    super.softWrap = true,
    super.fillHeight = false,
    super.showLineNumbers = false,
    super.leftGutterFunc,
    super.style,
    super.highlightStyle,
    super.selectedHighlightStyle,
    super.styleLineFunc,
    super.highlights = const [],
    super.currentHighlightIndex = -1,
    super.selectionStart,
    super.selectionEnd,
    super.lastClickTime,
    super.lastClickPos,
    super.keyMap,
    super.lines,
    super.wrappedLines,
    super.originalLines,
    this.styleRanges = const [],
  });

  factory TextModel(String content, {int width = 80}) {
    return TextModel.withOptions(
      width: width,
      softWrap: true,
      height: null,
    ).setContent(content);
  }

  @override
  TextModel copyWith({
    int? width,
    int? height,
    int? yOffset,
    int? xOffset,
    bool? mouseWheelEnabled,
    int? mouseWheelDelta,
    int? horizontalStep,
    ViewportKeyMap? keyMap,
    List<String>? lines,
    int? gutter,
    bool? softWrap,
    bool? fillHeight,
    bool? showLineNumbers,
    GutterFunc? leftGutterFunc,
    Style? style,
    Style? highlightStyle,
    Style? selectedHighlightStyle,
    Style Function(int lineIndex)? styleLineFunc,
    List<HighlightInfo>? highlights,
    int? currentHighlightIndex,
    Object? selectionStart = undefined,
    Object? selectionEnd = undefined,
    DateTime? lastClickTime,
    (int, int)? lastClickPos,
    List<String>? wrappedLines,
    List<String>? originalLines,
    List<ranges.StyleRange>? styleRanges,
  }) {
    final newWidth = width ?? this.width;
    final newGutter = gutter ?? this.gutter;
    final newSoftWrap = softWrap ?? this.softWrap;
    final newOriginalLines = lines ?? originalLines ?? internalOriginalLines;
    final newStyleRanges = styleRanges ?? this.styleRanges;

    // Apply style ranges to original lines
    var styledLines = lines ?? internalLines;
    if (lines != null || styleRanges != null) {
      styledLines = newOriginalLines;
      if (newStyleRanges.isNotEmpty) {
        final content = newOriginalLines.join('\n');
        final styled = ranges.styleRanges(content, newStyleRanges);
        styledLines = styled.split('\n');
      }
    }

    List<String>? newWrappedLines = wrappedLines ?? internalWrappedLines;
    if (newSoftWrap &&
        (lines != null ||
            width != null ||
            gutter != null ||
            softWrap != null ||
            styleRanges != null)) {
      final contentWidth = math.max(0, newWidth - newGutter);
      final content = styledLines.join('\n');
      final wrapped = uv_wrap.wrapAnsiPreserving(content, contentWidth);
      newWrappedLines = wrapped.split('\n');
    }

    final newSelectionStart = selectionStart == undefined
        ? this.selectionStart
        : selectionStart as (int, int)?;
    final newSelectionEnd = selectionEnd == undefined
        ? this.selectionEnd
        : selectionEnd as (int, int)?;

    return TextModel.withOptions(
      width: newWidth,
      height: height ?? this.height,
      gutter: newGutter,
      yOffset: yOffset ?? this.yOffset,
      xOffset: xOffset ?? this.xOffset,
      mouseWheelEnabled: mouseWheelEnabled ?? this.mouseWheelEnabled,
      mouseWheelDelta: mouseWheelDelta ?? this.mouseWheelDelta,
      horizontalStep: horizontalStep ?? this.horizontalStep,
      softWrap: newSoftWrap,
      fillHeight: fillHeight ?? this.fillHeight,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      leftGutterFunc: leftGutterFunc ?? this.leftGutterFunc,
      style: style ?? this.style,
      highlightStyle: highlightStyle ?? this.highlightStyle,
      selectedHighlightStyle:
          selectedHighlightStyle ?? this.selectedHighlightStyle,
      styleLineFunc: styleLineFunc ?? this.styleLineFunc,
      highlights: highlights ?? this.highlights,
      currentHighlightIndex:
          currentHighlightIndex ?? this.currentHighlightIndex,
      selectionStart: newSelectionStart,
      selectionEnd: newSelectionEnd,
      lastClickTime: lastClickTime ?? this.lastClickTime,
      lastClickPos: lastClickPos ?? this.lastClickPos,
      keyMap: keyMap ?? this.keyMap,
      lines: styledLines,
      wrappedLines: newWrappedLines,
      originalLines: newOriginalLines,
      styleRanges: newStyleRanges,
    );
  }

  @override
  TextModel setContent(String content) {
    return super.setContent(content) as TextModel;
  }

  @override
  (TextModel, Cmd?) update(Msg msg) {
    final (newModel, cmd) = super.update(msg);
    return (newModel as TextModel, cmd);
  }
}
