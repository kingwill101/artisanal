import 'package:markdown/markdown.dart' show Element, Text;

import '../../style/style.dart';
import 'package:ultraviolet/rendering.dart' as uv_wrap;
import 'render_context.dart';

// ─────────────────────────────────────────────────────────────────────────────
// List Rendering
// ─────────────────────────────────────────────────────────────────────────────

void renderStartListItem(MarkdownRenderContext ctx, Element element) {
  final indent = ' ' * ((ctx.listDepth - 1) * ctx.options.listIndent);
  ctx.buffer.write(indent);

  final parentList = renderParentList(ctx);
  final ordered = parentList != null && parentList.tag == 'ol';
  final startAttr = parentList?.attributes['start'];
  final start = startAttr != null ? int.tryParse(startAttr) ?? 1 : 1;
  final taskInput = firstTaskListInput(element);
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
  final item = ctx.listItemStack.last;
  final content = item.buffer.toString();
  if (content.isEmpty) return;
  item.buffer.clear();
  final availableWidth = ctx.options.width;
  final width = availableWidth == null
      ? null
      : availableWidth - item.continuationIndent;
  final wrapped = width == null
      ? content
      : uv_wrap.wrapAnsiPreserving(
          content,
          width > 0 ? width : availableWidth!,
        );
  if (item.hasFlushedContent) {
    ctx.buffer.write(' ' * item.continuationIndent);
  }
  ctx.buffer.write(
    renderIndentContinuationLines(wrapped, item.continuationIndent),
  );
  item.hasFlushedContent = true;
}

/// Finds a leading task checkbox, including the paragraph of a loose list item.
Element? firstTaskListInput(Element element) {
  final children = element.children;
  if (children == null) return null;

  for (final child in children) {
    if (child is Text && child.text.trim().isEmpty) continue;
    if (child is Element &&
        child.tag == 'input' &&
        child.attributes['type'] == 'checkbox') {
      return child;
    }
    if (child is Element && child.tag == 'p') {
      return firstTaskListInput(child);
    }
    return null;
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
      .map((e) {
        if (e.key == 0 || (e.key == lines.length - 1 && e.value.isEmpty)) {
          return e.value;
        }
        return '$prefix${e.value}';
      })
      .join('\n');
}
