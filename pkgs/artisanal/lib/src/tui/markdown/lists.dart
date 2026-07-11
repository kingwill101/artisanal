import 'package:markdown/markdown.dart' show Element;

import '../../style/style.dart';
import '../../style/color.dart';
import 'render_context.dart';

// ─────────────────────────────────────────────────────────────────────────────
// List Rendering
// ─────────────────────────────────────────────────────────────────────────────

void renderStartListItem(MarkdownRenderContext ctx, Element element) {
  // Add blockquote prefix if inside a blockquote
  if (ctx.inBlockquote) {
    renderWriteBlockquotePrefix(ctx);
  }

  // Add indentation based on nesting level
  final indent = ' ' * ((ctx.listDepth - 1) * ctx.options.listIndent);
  ctx.buffer.write(indent);

  // Get the list style from the parent list element
  final parentList = renderParentList(ctx);
  final ordered = parentList != null && parentList.tag == 'ol';
  final startAttr = parentList?.attributes['start'];
  final start = startAttr != null ? int.tryParse(startAttr) ?? 1 : 1;

  if (ordered) {
    // Use the counter for this nesting level
    final counter = ctx.listCounters.isNotEmpty ? ctx.listCounters.last : start;
    ctx.buffer.write('$counter. ');
  } else {
    // Check for task list items
    if (renderIsTaskListInput(element)) {
      ctx.buffer.write('');
    } else {
      ctx.buffer.write('${ctx.options.bulletChar} ');
    }
  }

  ctx.listItemStack.add(
    ListItemContext(trimLeadingWhitespace: true),
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
  final content = item.buffer.toString().trim();
  if (content.isEmpty) return;
  ctx.buffer.write(content);
  ctx.buffer.write('\n');
}

String renderIndentContinuationLines(String text, int indent) {
  if (indent <= 0 || !text.contains('\n')) return text;

  final prefix = ' ' * indent;
  final lines = text.split('\n');
  return lines.asMap().entries.map((e) => e.key == 0 ? e.value : '$prefix${e.value}').join('\n');
}

Style defaultBlockquoteStyle() => Style().italic().dim();

void renderWriteBlockquotePrefix(MarkdownRenderContext ctx) {
  final color = ctx.options.blockquoteBorderColor;
  if (color == null) {
    ctx.buffer.write('│ ');
  } else {
    final seq = color.toAnsi(ColorProfile.trueColor);
    ctx.buffer.write('$seq│ ${MarkdownRenderContext.ansiReset}');
  }

  ctx.buffer.write(ctx.styleToAnsi(ctx.options.blockquoteStyle ?? defaultBlockquoteStyle()));
}

String renderApplyBlockquotePrefix(MarkdownRenderContext ctx, String text) {
  if (!ctx.inBlockquote || !text.contains('\n')) return text;

  final color = ctx.options.blockquoteBorderColor;
  final prefix = color != null
      ? '${color.toAnsi(ColorProfile.trueColor)}│ ${MarkdownRenderContext.ansiReset}'
      : '│ ';
  final lines = text.split('\n');
  return lines.map((line) => '$prefix$line').join('\n');
}
