import 'package:markdown/markdown.dart' show Element;

import '../../style/style.dart';
import '../../style/color.dart';
import 'package:ultraviolet/rendering.dart' as uv_wrap;
import 'render_context.dart';

// ─────────────────────────────────────────────────────────────────────────────
// List Rendering
// ─────────────────────────────────────────────────────────────────────────────

void renderStartListItem(MarkdownRenderContext ctx, Element element) {
  if (ctx.inBlockquote) {
    renderWriteBlockquotePrefix(ctx);
  }

  final indent = ' ' * ((ctx.listDepth - 1) * ctx.options.listIndent);
  ctx.buffer.write(indent);

  final parentList = renderParentList(ctx);
  final ordered = parentList != null && parentList.tag == 'ol';
  final startAttr = parentList?.attributes['start'];
  final start = startAttr != null ? int.tryParse(startAttr) ?? 1 : 1;
  final taskInput = _firstTaskListInput(element);
  final taskCheckbox = taskInput == null
      ? null
      : (taskInput.attributes['checked'] != null
            ? ctx.options.checkboxChecked
            : ctx.options.checkboxUnchecked);
  final counter = ctx.listCounters.isNotEmpty ? ctx.listCounters.last : start;
  final marker = ordered
      ? (taskCheckbox == null ? '$counter. ' : '$counter. $taskCheckbox ')
      : (taskCheckbox == null
            ? '${ctx.options.bulletChar} '
            : '$taskCheckbox ');

  if (ordered) {
    ctx.buffer.write(marker);
    if (ctx.listCounters.isNotEmpty) {
      ctx.listCounters[ctx.listCounters.length - 1] = counter + 1;
    }
  } else {
    ctx.buffer.write(marker);
  }

  ctx.listItemStack.add(
    ListItemContext(
      continuationIndent:
          Style.visibleLength(indent) + Style.visibleLength(marker),
      taskCheckboxRendered: taskCheckbox != null,
    ),
  );
}

Element? renderParentList(MarkdownRenderContext ctx) {
  for (var i = ctx.elementStack.length - 1; i >= 0; i--) {
    final tag = ctx.elementStack[i].tag;
    if (tag == 'ul' || tag == 'ol') {
      return ctx.elementStack[i];
    }
  }
  return null;
}

bool renderHasNestedList(Element element) {
  for (final child in element.children ?? <Element>[]) {
    if (child is Element && (child.tag == 'ul' || child.tag == 'ol')) {
      return true;
    }
  }
  return false;
}

bool renderIsTaskListInput(Element element) {
  if (element.children == null) return false;
  for (final child in element.children!) {
    if (child is Element &&
        child.tag == 'input' &&
        child.attributes['type'] == 'checkbox') {
      return true;
    }
  }
  return false;
}

void renderFlushCurrentListItem(MarkdownRenderContext ctx) {
  if (ctx.listItemStack.isEmpty) return;
  final item = ctx.listItemStack.removeLast();
  final content = item.buffer.toString();
  if (content.isEmpty) return;
  if (ctx.options.width == null) {
    ctx.buffer.write(content);
    return;
  }

  final width = ctx.options.width! - item.continuationIndent;
  final wrapped = uv_wrap.wrapAnsiPreserving(
    content,
    width > 0 ? width : ctx.options.width!,
  );
  ctx.buffer.write(
    renderIndentContinuationLines(wrapped, item.continuationIndent),
  );
}

Element? _firstTaskListInput(Element element) {
  final children = element.children;
  if (children == null) return null;

  for (final child in children) {
    if (child is Element &&
        child.tag == 'input' &&
        child.attributes['type'] == 'checkbox') {
      return child;
    }
    if (child is Element && child.tag == 'p') {
      final nested = _firstTaskListInput(child);
      if (nested != null) return nested;
    }
  }

  return null;
}

String renderIndentContinuationLines(String text, int indent) {
  if (indent <= 0 || !text.contains('\n')) return text;

  final prefix = ' ' * indent;
  final lines = text.split('\n');
  return lines
      .asMap()
      .entries
      .map((e) => e.key == 0 ? e.value : '$prefix${e.value}')
      .join('\n');
}

Style defaultBlockquoteStyle() => Style().italic().dim();

void renderWriteBlockquotePrefix(MarkdownRenderContext ctx) {
  ctx.buffer.write(_blockquotePrefix(ctx));

  ctx.buffer.write(
    ctx.styleToAnsi(ctx.options.blockquoteStyle ?? defaultBlockquoteStyle()),
  );
}

String renderApplyBlockquotePrefix(MarkdownRenderContext ctx, String text) {
  if (!ctx.inBlockquote || !text.contains('\n')) return text;

  final lines = text.split('\n');
  if (lines.length <= 1) return text;

  final prefix = _blockquotePrefix(ctx);
  return [
    lines.first,
    ...lines.skip(1).map((line) => '$prefix$line'),
  ].join('\n');
}

String renderApplyBlockquotePrefixAll(MarkdownRenderContext ctx, String text) {
  if (!ctx.inBlockquote || !text.contains('\n')) return text;

  final prefix = _blockquotePrefix(ctx);
  return text.split('\n').map((line) => '$prefix$line').join('\n');
}

Color defaultBlockquoteBorderColor() => Colors.gray;

String _blockquotePrefix(MarkdownRenderContext ctx) {
  final color =
      ctx.options.blockquoteBorderColor ?? defaultBlockquoteBorderColor();
  final seq = color.toAnsi(ColorProfile.trueColor);
  final border = '│' * ctx.blockquoteDepth;
  return '$seq$border ${MarkdownRenderContext.ansiReset}';
}
