import 'dart:io';

import '../example/widget_catalog_support.dart';
import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

File _goldenFile(String preset) {
  final relativePath = 'test/testdata/widget_catalog/$preset.golden';
  final candidates = [File(relativePath), File('pkgs/artisanal/$relativePath')];
  return candidates.firstWhere(
    (file) => file.existsSync(),
    orElse: () => candidates.first,
  );
}

void main() {
  group('widget catalog', () {
    test('maps every built-in preset name', () {
      expect(componentThemePresetNames, hasLength(9));
      for (final name in componentThemePresetNames) {
        expect(componentThemeForName(name), isA<Object>());
      }
    });

    test('rejects unknown preset names', () {
      expect(() => componentThemeForName('missing'), throwsArgumentError);
    });

    test('catalog spans all major widget families', () {
      final entries = buildWidgetCatalog();
      final categories = entries.map((entry) => entry.category).toSet();

      expect(entries.length, greaterThanOrEqualTo(35));
      expect(
        categories,
        containsAll([
          'Input',
          'Selection',
          'Flow',
          'Feedback',
          'Navigation',
          'Data',
          'Display',
        ]),
      );
      expect(
        entries.map((entry) => entry.id).toSet(),
        containsAll(showcaseWidgetIds),
      );
    });

    test('public registry supports category and text filtering', () {
      expect(widgetCatalogEntries, isNotEmpty);
      expect(widgetCatalogCategories, contains('Display'));

      final display = filterWidgetCatalog(category: 'display');
      expect(display, isNotEmpty);
      expect(display.every((entry) => entry.category == 'Display'), isTrue);

      final searchable = filterWidgetCatalog(query: 'progress');
      expect(
        searchable.map((entry) => entry.id),
        containsAll(['progress-model', 'progress-bar', 'progress']),
      );
    });

    test('every catalog entry has a plain-text preview', () {
      for (final entry in buildWidgetCatalog()) {
        final preview = renderWidgetPreview(
          entry,
          theme: ComponentTheme.ocean,
          colorProfile: ColorProfile.ascii,
        );

        expect(preview, isNotEmpty, reason: entry.name);
        expect(preview, isNot(contains('\x1b')), reason: entry.name);
      }
    });

    test('theme previews use the requested palette', () {
      final entry = buildWidgetCatalog().firstWhere(
        (entry) => entry.id == 'select',
      );
      final preview = renderWidgetPreview(entry, theme: ComponentTheme.hacker);

      expect(preview, contains('Choose an environment'));
      expect(preview, contains('staging'));
    });

    test('every preset showcase matches its golden snapshot', () {
      for (final preset in componentThemePresetNames) {
        final actual = renderPresetShowcaseSnapshot(
          preset,
          componentThemeForName(preset),
        ).replaceAll('\x1b', '<ESC>').trimRight();
        final golden = _goldenFile(preset).readAsStringSync().trimRight();

        expect(actual, golden, reason: preset);
      }
    });
  });
}
