import 'dart:convert';

/// One generated variant and the evidence available for it.
final class GalleryEntry {
  /// Creates a gallery entry, retaining warnings rather than hiding failures.
  const GalleryEntry({
    required this.scenario,
    required this.sourceFile,
    required this.stem,
    required this.columns,
    required this.rows,
    required this.imageWidth,
    required this.imageHeight,
    required this.hasAnsi,
    required this.hasCapture,
    required this.warnings,
    required this.overflowRows,
    required this.error,
  });

  final String scenario;
  final String? sourceFile;
  final String stem;
  final int columns;
  final int? rows;
  final int? imageWidth;
  final int? imageHeight;
  final bool hasAnsi;
  final bool hasCapture;
  final List<String> warnings;
  final List<int> overflowRows;
  final String? error;

  Map<String, Object?> toJson() => {
    'scenario': scenario,
    'columns': columns,
    'rows': rows,
    'source': sourceFile,
    'png': imageWidth == null ? null : '$stem.png',
    'html': imageWidth == null ? null : '$stem.html',
    'ansi': hasAnsi ? '$stem.ansi' : null,
    'capture': hasCapture ? '$stem.json' : null,
    'warnings': warnings,
    'overflowRows': overflowRows,
    'error': error,
  };
}

/// Builds a local, script-free gallery at native image dimensions.
String galleryHtml(List<GalleryEntry> entries) {
  const escape = HtmlEscape();
  String text(String value) => escape.convert(value);
  String link(String filename, String label) =>
      '<a href="${text(Uri.encodeComponent(filename))}">${text(label)}</a>';
  final groups = <String, List<GalleryEntry>>{};
  for (final entry in entries) {
    groups.putIfAbsent(entry.scenario, () => []).add(entry);
  }
  final flagged = entries
      .where((e) => e.error != null || e.warnings.isNotEmpty)
      .length;
  final body = StringBuffer();
  var index = 0;
  for (final group in groups.entries) {
    body.write('<section id="scenario-${index++}"><h2>${text(group.key)}</h2>');
    final source = group.value.first.sourceFile;
    if (source != null) body.write('<p>${link(source, 'Markdown source')}</p>');
    body.write('<div class="variants">');
    for (final entry in group.value) {
      final status = entry.error != null
          ? 'Failed'
          : entry.warnings.isEmpty
          ? 'Rendered'
          : 'Inspect diagnostics';
      body.write(
        '<article><header><h3>${entry.columns} columns</h3>'
        '<span class="${status == 'Rendered' ? 'ok' : 'flag'}">${text(status)}</span></header>',
      );
      if (entry.error != null) {
        body.write('<p class="flag">${text(entry.error!)}</p>');
      }
      if (entry.warnings.isNotEmpty) {
        body.write(
          '<details><summary>${entry.warnings.length} diagnostics</summary><ul>',
        );
        for (final warning in entry.warnings) {
          body.write('<li>${text(warning)}</li>');
        }
        body.write('</ul></details>');
      }
      final links = [
        if (entry.imageWidth != null) link('${entry.stem}.png', 'PNG'),
        if (entry.imageWidth != null)
          link('${entry.stem}.html', 'Full preview'),
        if (entry.hasAnsi) link('${entry.stem}.ansi', 'ANSI'),
        if (entry.hasCapture) link('${entry.stem}.json', 'Cells'),
      ];
      body.write('<p class="links">${links.join(' · ')}</p>');
      if (entry.imageWidth != null) {
        body.write(
          '<div class="frame"><img loading="lazy" '
          'src="${text(Uri.encodeComponent('${entry.stem}.png'))}" '
          'width="${entry.imageWidth}" height="${entry.imageHeight}" '
          'alt="${text('${entry.scenario} at ${entry.columns} columns')}"></div>',
        );
      }
      body.write('</article>');
    }
    body.write('</div></section>');
  }
  final navigation = groups.keys.indexed
      .map((pair) => '<a href="#scenario-${pair.$1}">${text(pair.$2)}</a>')
      .join();
  return '''<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src 'self' data: file:; style-src 'unsafe-inline'">
<title>Markdown scenario gallery</title>
<style>
:root { color-scheme: dark; }
* { box-sizing: border-box; }
body { margin: 0; background: #151719; color: #e4e7e9; font: 14px/1.5 monospace; }
a { color: #99d7cc; text-underline-offset: 3px; }
a:focus-visible, summary:focus-visible { outline: 2px solid #fff; outline-offset: 4px; }
.masthead { padding: 28px; border-bottom: 1px solid #3a4044; }
h1 { margin: 0 0 8px; font-size: 24px; letter-spacing: -.5px; }
.masthead p { margin: 6px 0; color: #b8bfc3; }
.layout { display: grid; grid-template-columns: 250px minmax(0, 1fr); }
nav { padding: 24px; border-right: 1px solid #3a4044; }
nav a { display: block; overflow-wrap: anywhere; margin: 0 0 10px; font-size: 12px; }
main { min-width: 0; padding: 0 24px 48px; }
section { padding-top: 28px; }
h2 { font-size: 17px; overflow-wrap: anywhere; margin: 0; }
h3 { font-size: 14px; margin: 0; }
.variants { display: flex; gap: 16px; overflow: auto; align-items: flex-start; padding-bottom: 20px; }
article { flex: 0 0 auto; max-width: 100%; min-width: 260px; border: 1px solid #3a4044; }
article header { display: flex; justify-content: space-between; gap: 20px; padding: 12px; background: #23272a; }
article p, details { padding: 0 12px; max-width: 700px; overflow-wrap: anywhere; }
summary { cursor: pointer; color: #edc384; }
.ok { color: #a1c6b6; } .flag { color: #edc384; }
.frame { max-height: 640px; overflow: auto; }
img { display: block; max-width: none; }
@media (max-width: 760px) {
  .layout { display: block; } nav { border-right: 0; border-bottom: 1px solid #3a4044; }
  nav a { display: inline-block; margin-right: 16px; } main { padding: 0 12px 24px; }
}
</style></head><body>
<header class="masthead"><h1>Markdown / render matrix</h1>
<p>${groups.length} scenarios · ${entries.length} width variants · $flagged flagged for inspection</p>
<p>Native PNGs, unscaled. Scroll within a frame or open its full preview. “Rendered” is not a correctness verdict.</p>
<p>${link('manifest.json', 'Manifest and render profile')}</p></header>
<div class="layout"><nav aria-label="Scenarios">$navigation</nav><main>$body</main></div>
</body></html>
''';
}
