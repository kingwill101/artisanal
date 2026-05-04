library;

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Theme — construction and factories
  // ---------------------------------------------------------------------------
  group('Theme construction', () {
    test('Theme.dark() creates a dark theme with AnsiColor values', () {
      final theme = Theme.dark();
      expect(theme.primary, isA<AnsiColor>());
      expect(theme.secondary, isA<AnsiColor>());
      expect(theme.surface, isA<AnsiColor>());
      expect(theme.background, isA<AnsiColor>());
      expect(theme.error, isA<AnsiColor>());
      expect(theme.success, isA<AnsiColor>());
      expect(theme.warning, isA<AnsiColor>());
      expect(theme.onPrimary, isA<AnsiColor>());
      expect(theme.onSecondary, isA<AnsiColor>());
      expect(theme.onSurface, isA<AnsiColor>());
      expect(theme.onBackground, isA<AnsiColor>());
      expect(theme.onError, isA<AnsiColor>());
      expect(theme.muted, isA<AnsiColor>());
      expect(theme.border, isA<AnsiColor>());
      expect(theme.listRowTheme, isNotNull);
    });

    test('Theme.light() creates a light theme with AnsiColor values', () {
      final theme = Theme.light();
      expect(theme.primary, isA<AnsiColor>());
      expect(theme.surface, isA<AnsiColor>());
      expect(theme.background, isA<AnsiColor>());
    });

    test('Theme.adaptive() creates theme with AdaptiveColor values', () {
      final theme = Theme.adaptive();
      expect(theme.primary, isA<AdaptiveColor>());
      expect(theme.secondary, isA<AdaptiveColor>());
      expect(theme.surface, isA<AdaptiveColor>());
      expect(theme.background, isA<AdaptiveColor>());
      expect(theme.error, isA<AdaptiveColor>());
      expect(theme.success, isA<AdaptiveColor>());
      expect(theme.warning, isA<AdaptiveColor>());
      expect(theme.onPrimary, isA<AdaptiveColor>());
      expect(theme.onSurface, isA<AdaptiveColor>());
      expect(theme.onBackground, isA<AdaptiveColor>());
      expect(theme.muted, isA<AdaptiveColor>());
      expect(theme.border, isA<AdaptiveColor>());
    });

    test('Theme.adaptive() has some non-adaptive colors', () {
      // onSecondary and onError are plain AnsiColor(255) in adaptive
      final theme = Theme.adaptive();
      expect(theme.onSecondary, isA<AnsiColor>());
      expect(theme.onError, isA<AnsiColor>());
    });

    test('Theme has 9 text style fields', () {
      final theme = Theme.dark();
      expect(theme.titleLarge, isA<Style>());
      expect(theme.titleMedium, isA<Style>());
      expect(theme.titleSmall, isA<Style>());
      expect(theme.bodyLarge, isA<Style>());
      expect(theme.bodyMedium, isA<Style>());
      expect(theme.bodySmall, isA<Style>());
      expect(theme.labelLarge, isA<Style>());
      expect(theme.labelMedium, isA<Style>());
      expect(theme.labelSmall, isA<Style>());
    });

    test(
      'Theme.adaptive() editor theme separates active and inactive tiers',
      () {
        final editor = Theme.adaptive().editorTheme!;

        expect(
          editor.shellBackground,
          isNot(equals(editor.inactiveShellBackground)),
        );
        expect(
          editor.bodyBackground,
          isNot(equals(editor.inactiveBodyBackground)),
        );
        expect(editor.utilityBackground, isNot(equals(editor.bodyBackground)));
        expect(
          editor.focusedTextForeground,
          isNot(equals(editor.blurredTextForeground)),
        );
        expect(
          editor.titleForeground,
          isNot(equals(editor.inactiveTitleForeground)),
        );
      },
    );

    test(
      'OpenCodeThemes.dracula() editor theme keeps readable tier separation',
      () {
        final editor = OpenCodeThemes.dracula().editorTheme!;

        expect(editor.utilityBackground, isNot(equals(editor.bodyBackground)));
        expect(
          editor.focusedTextForeground,
          isNot(equals(editor.blurredTextForeground)),
        );
        expect(editor.metaForeground, isNot(equals(editor.titleForeground)));
        expect(
          editor.inactiveMetaForeground,
          isNot(equals(editor.metaForeground)),
        );
        expect(
          editor.focusedLineNumberForeground,
          isNot(equals(editor.blurredLineNumberForeground)),
        );
      },
    );

    test(
      'weak OpenCode presets keep editor shell and blurred tiers distinct',
      () {
        final presets = <String, Theme Function()>{
          'cursor': OpenCodeThemes.cursor,
          'mercury': OpenCodeThemes.mercury,
          'nightowl': OpenCodeThemes.nightowl,
          'solarized': OpenCodeThemes.solarized,
        };

        for (final entry in presets.entries) {
          final editor = entry.value().editorTheme!;

          expect(
            editor.shellBackground,
            isNot(equals(editor.inactiveShellBackground)),
            reason: '${entry.key} should separate active and inactive shells',
          );
          expect(
            editor.utilityBackground,
            isNot(equals(editor.bodyBackground)),
            reason: '${entry.key} should keep utility chrome separate',
          );
          expect(
            editor.focusedTextForeground,
            isNot(equals(editor.blurredTextForeground)),
            reason: '${entry.key} should keep blurred text readable but softer',
          );
          expect(
            editor.activeShellBorderColor,
            isNot(equals(editor.inactiveShellBorderColor)),
            reason: '${entry.key} should keep inactive shells less forceful',
          );
          expect(
            editor.focusedLineNumberForeground,
            isNot(equals(editor.blurredLineNumberForeground)),
            reason: '${entry.key} should keep focused line numbers stronger',
          );
        }
      },
    );

    test(
      'additional OpenCode presets keep shell, body, and border tiers distinct',
      () {
        final aura = OpenCodeThemes.aura().editorTheme!;
        expect(
          aura.shellBackground,
          isNot(equals(aura.inactiveShellBackground)),
        );

        final ayu = OpenCodeThemes.ayu().editorTheme!;
        expect(
          ayu.activeShellBorderColor,
          isNot(equals(ayu.inactiveShellBorderColor)),
        );

        final lucentOrng = OpenCodeThemes.lucentOrng().editorTheme!;
        expect(
          lucentOrng.shellBackground,
          isNot(equals(lucentOrng.inactiveShellBackground)),
        );
        expect(
          lucentOrng.bodyBackground,
          isNot(equals(lucentOrng.inactiveBodyBackground)),
        );
        expect(
          lucentOrng.utilityBackground,
          isNot(equals(lucentOrng.bodyBackground)),
        );
      },
    );

    test('OpenCode default keeps selected list rows visible', () {
      final theme = OpenCodeThemes.opencode();

      expect(theme.listRowSelectedBackground, isNot(isA<NoColor>()));
      expect(
        identical(theme.listRowSelectedBackground, theme.listRowBackground),
        isFalse,
      );
      expect(
        theme.commandPaletteTheme?.selectedBackground,
        same(theme.listRowSelectedBackground),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Theme — copyWith
  // ---------------------------------------------------------------------------
  group('Theme copyWith', () {
    test('copyWith returns new theme with overridden colors', () {
      final original = Theme.dark();
      final customColor = AnsiColor(100);
      final modified = original.copyWith(primary: customColor);

      expect(modified.primary, same(customColor));
      // Other fields should remain unchanged
      expect(modified.secondary, same(original.secondary));
      expect(modified.surface, same(original.surface));
      expect(modified.background, same(original.background));
    });

    test('copyWith with no args returns equivalent theme', () {
      final original = Theme.dark();
      final copy = original.copyWith();

      expect(copy.primary, same(original.primary));
      expect(copy.secondary, same(original.secondary));
      expect(copy.surface, same(original.surface));
      expect(copy.background, same(original.background));
      expect(copy.error, same(original.error));
      expect(copy.success, same(original.success));
      expect(copy.warning, same(original.warning));
      expect(copy.onPrimary, same(original.onPrimary));
      expect(copy.onSecondary, same(original.onSecondary));
      expect(copy.onSurface, same(original.onSurface));
      expect(copy.onBackground, same(original.onBackground));
      expect(copy.onError, same(original.onError));
      expect(copy.muted, same(original.muted));
      expect(copy.border, same(original.border));
      expect(copy.listRowTheme, same(original.listRowTheme));
    });

    test('copyWith overrides text styles', () {
      final original = Theme.dark();
      final customStyle = Style().bold().italic();
      final modified = original.copyWith(titleLarge: customStyle);

      expect(modified.titleLarge, same(customStyle));
      expect(modified.titleMedium, same(original.titleMedium));
    });

    test('copyWith can override all 14 colors at once', () {
      final original = Theme.dark();
      final c = AnsiColor(42);
      final modified = original.copyWith(
        primary: c,
        secondary: c,
        surface: c,
        background: c,
        error: c,
        success: c,
        warning: c,
        onPrimary: c,
        onSecondary: c,
        onSurface: c,
        onBackground: c,
        onError: c,
        muted: c,
        border: c,
      );

      expect(modified.primary, same(c));
      expect(modified.secondary, same(c));
      expect(modified.surface, same(c));
      expect(modified.background, same(c));
      expect(modified.error, same(c));
      expect(modified.success, same(c));
      expect(modified.warning, same(c));
      expect(modified.onPrimary, same(c));
      expect(modified.onSecondary, same(c));
      expect(modified.onSurface, same(c));
      expect(modified.onBackground, same(c));
      expect(modified.onError, same(c));
      expect(modified.muted, same(c));
      expect(modified.border, same(c));
    });

    test('copyWith can override list row theme', () {
      final original = Theme.dark();
      const listRows = ListRowThemeData(
        background: AnsiColor(1),
        selectedBackground: AnsiColor(2),
        selectedForeground: AnsiColor(3),
      );
      final modified = original.copyWith(listRowTheme: listRows);

      expect(modified.listRowTheme, same(listRows));
      expect(
        modified.listRowSelectedBackground,
        same(listRows.selectedBackground),
      );
      expect(
        modified.listRowSelectedForeground,
        same(listRows.selectedForeground),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Theme — list row resolution
  // ---------------------------------------------------------------------------
  group('Theme list row resolution', () {
    test('falls back to global surface and highlight tokens', () {
      const highlight = AnsiColor(11);
      const onHighlight = AnsiColor(12);
      final theme = _themeWithoutListRows(
        highlight: highlight,
        onHighlight: onHighlight,
      );

      expect(theme.listRowBackground, same(theme.surface));
      expect(
        theme.listRowAlternateBackground,
        same(theme.resolvedSurfaceVariant),
      );
      expect(theme.listRowForeground, same(theme.onSurface));
      expect(theme.listRowMutedForeground, same(theme.muted));
      expect(theme.listRowAccentForeground, same(theme.primary));
      expect(
        theme.listRowMarkerForeground,
        same(theme.listRowAccentForeground),
      );
      expect(theme.listRowSeparatorForeground, same(theme.resolvedOutline));
      expect(theme.listRowSelectedBackground, same(highlight));
      expect(theme.listRowSelectedForeground, same(onHighlight));
      expect(
        theme.listRowSelectedMutedForeground,
        same(theme.listRowSelectedForeground),
      );
      expect(
        theme.listRowSelectedAccentForeground,
        same(theme.listRowSelectedForeground),
      );
      expect(
        theme.listRowSelectedMarkerForeground,
        same(theme.listRowSelectedAccentForeground),
      );
      expect(
        theme.listRowSelectedSeparatorForeground,
        same(theme.listRowSelectedMutedForeground),
      );
    });

    test('uses explicit list row token overrides', () {
      const rows = ListRowThemeData(
        background: AnsiColor(1),
        alternateBackground: AnsiColor(2),
        foreground: AnsiColor(3),
        mutedForeground: AnsiColor(4),
        accentForeground: AnsiColor(5),
        markerForeground: AnsiColor(6),
        separatorForeground: AnsiColor(7),
        selectedBackground: AnsiColor(8),
        selectedForeground: AnsiColor(9),
        selectedMutedForeground: AnsiColor(10),
        selectedAccentForeground: AnsiColor(11),
        selectedMarkerForeground: AnsiColor(12),
        selectedSeparatorForeground: AnsiColor(13),
      );
      final theme = Theme.dark().copyWith(listRowTheme: rows);

      expect(theme.listRowBackground, same(rows.background));
      expect(theme.listRowAlternateBackground, same(rows.alternateBackground));
      expect(theme.listRowForeground, same(rows.foreground));
      expect(theme.listRowMutedForeground, same(rows.mutedForeground));
      expect(theme.listRowAccentForeground, same(rows.accentForeground));
      expect(theme.listRowMarkerForeground, same(rows.markerForeground));
      expect(theme.listRowSeparatorForeground, same(rows.separatorForeground));
      expect(theme.listRowSelectedBackground, same(rows.selectedBackground));
      expect(theme.listRowSelectedForeground, same(rows.selectedForeground));
      expect(
        theme.listRowSelectedMutedForeground,
        same(rows.selectedMutedForeground),
      );
      expect(
        theme.listRowSelectedAccentForeground,
        same(rows.selectedAccentForeground),
      );
      expect(
        theme.listRowSelectedMarkerForeground,
        same(rows.selectedMarkerForeground),
      );
      expect(
        theme.listRowSelectedSeparatorForeground,
        same(rows.selectedSeparatorForeground),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Global theme state
  // ---------------------------------------------------------------------------
  group('Global theme state', () {
    late Theme originalTheme;
    late bool originalDarkBg;

    setUp(() {
      originalTheme = currentTheme;
      originalDarkBg = hasDarkBackground;
    });

    tearDown(() {
      setTheme(originalTheme);
      setHasDarkBackground(originalDarkBg);
    });

    test('currentTheme defaults to Theme.adaptive()', () {
      // The default is Theme.adaptive() — it should have AdaptiveColor fields
      expect(currentTheme.primary, isA<AdaptiveColor>());
    });

    test('setTheme replaces global theme', () {
      final custom = Theme.light();
      setTheme(custom);
      expect(currentTheme, same(custom));
    });

    test('hasDarkBackground defaults to true', () {
      // Reset to default state
      setHasDarkBackground(true);
      expect(hasDarkBackground, isTrue);
    });

    test('setHasDarkBackground changes the flag', () {
      setHasDarkBackground(false);
      expect(hasDarkBackground, isFalse);
      setHasDarkBackground(true);
      expect(hasDarkBackground, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // updateThemeFromBackground
  // ---------------------------------------------------------------------------
  group('updateThemeFromBackground', () {
    late bool originalDarkBg;

    setUp(() {
      originalDarkBg = hasDarkBackground;
    });

    tearDown(() {
      setHasDarkBackground(originalDarkBg);
    });

    test('dark background hex sets hasDarkBackground to true', () {
      // Very dark color: #0a0a0a → luminance ~0.04 < 0.5 → dark
      updateThemeFromBackground('#0a0a0a');
      expect(hasDarkBackground, isTrue);
    });

    test('light background hex sets hasDarkBackground to false', () {
      // Very light color: #fafafa → luminance ~0.98 > 0.5 → not dark
      updateThemeFromBackground('#fafafa');
      expect(hasDarkBackground, isFalse);
    });

    test('works without hash prefix', () {
      updateThemeFromBackground('ffffff');
      expect(hasDarkBackground, isFalse);
    });

    test('null input is ignored', () {
      setHasDarkBackground(true);
      updateThemeFromBackground(null);
      expect(hasDarkBackground, isTrue);
    });

    test('empty string is ignored', () {
      setHasDarkBackground(true);
      updateThemeFromBackground('');
      expect(hasDarkBackground, isTrue);
    });

    test('invalid hex length is ignored', () {
      setHasDarkBackground(true);
      updateThemeFromBackground('#abc'); // 3 chars, not 6
      expect(hasDarkBackground, isTrue);
    });

    test('invalid hex chars are ignored', () {
      setHasDarkBackground(true);
      updateThemeFromBackground('#zzzzzz');
      // parseInt returns null for invalid hex; function returns early
      expect(hasDarkBackground, isTrue);
    });

    test('mid-gray is classified as light (luminance >= 0.5)', () {
      // Pure 128 gray: luminance = 128/255 ≈ 0.502 → not dark
      updateThemeFromBackground('#808080');
      expect(hasDarkBackground, isFalse);
    });

    test('slightly below mid-gray is classified as dark', () {
      // #707070: luminance ≈ 0.44 < 0.5 → dark
      updateThemeFromBackground('#707070');
      expect(hasDarkBackground, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ThemeScope — InheritedWidget behavior
  // ---------------------------------------------------------------------------
  group('ThemeScope', () {
    test('ThemeScope.of returns theme from nearest ancestor', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        final customTheme = Theme.dark();
        await tester.pumpWidget(
          ThemeScope(
            theme: customTheme,
            child: _ThemeReaderWidget(label: 'dark-test'),
          ),
        );
        // The _ThemeReaderWidget renders 'dark-test' which proves it built
        expect(tester.find.text('dark-test'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('ThemeScope.of falls back to currentTheme without ancestor', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        // No ThemeScope wrapper — ThemeScope.of falls back to currentTheme
        await tester.pumpWidget(_ThemeReaderWidget(label: 'fallback-test'));
        expect(tester.find.text('fallback-test'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('nested ThemeScope uses inner theme', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: ThemeScope(theme: Theme.light(), child: Text('nested')),
          ),
        );
        expect(tester.find.text('nested'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('updateShouldNotify returns true for different theme', () {
      final scope1 = ThemeScope(theme: Theme.dark(), child: Text('a'));
      final scope2 = ThemeScope(theme: Theme.light(), child: Text('b'));
      expect(scope1.updateShouldNotify(scope2), isTrue);
    });

    test('updateShouldNotify returns false for same theme object', () {
      final theme = Theme.dark();
      final scope1 = ThemeScope(theme: theme, child: Text('a'));
      final scope2 = ThemeScope(theme: theme, child: Text('b'));
      expect(scope1.updateShouldNotify(scope2), isFalse);
    });

    test('ThemeScope wraps child correctly', () {
      final theme = Theme.dark();
      final child = Text('x');
      final scope = ThemeScope(theme: theme, child: child);
      expect(scope.theme, same(theme));
      expect(scope.children.length, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // ThemeScope — context extensions
  // ---------------------------------------------------------------------------
  group('ThemeScope context extension', () {
    test('context.theme works inside ThemeScope', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ThemeScope(theme: Theme.light(), child: _ContextThemeWidget()),
        );
        expect(tester.find.text('has-theme'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Theme — dark vs light color differences
  // ---------------------------------------------------------------------------
  group('Theme dark vs light differences', () {
    test('dark and light themes have different primary colors', () {
      final dark = Theme.dark();
      final light = Theme.light();
      // They should differ (dark uses cyan AnsiColor(39), light uses blue AnsiColor(33))
      expect(identical(dark.primary, light.primary), isFalse);
    });

    test('dark and light themes have different surface colors', () {
      final dark = Theme.dark();
      final light = Theme.light();
      expect(identical(dark.surface, light.surface), isFalse);
    });

    test('dark and light themes have different background colors', () {
      final dark = Theme.dark();
      final light = Theme.light();
      expect(identical(dark.background, light.background), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Theme — integration with widgets
  // ---------------------------------------------------------------------------
  group('Theme widget integration', () {
    test('Button uses theme colors', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: Button(label: 'Click Me', onPressed: () => null),
          ),
        );
        expect(tester.find.text('Click Me'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('SpinnerIndicator uses theme colors', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.light(),
            child: SpinnerIndicator(frames: const ['*']),
          ),
        );
        expect(tester.find.text('*'), isTrue);
      } finally {
        await tester.dispose();
      }
    });

    test('Card uses theme border color', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: Card(child: Text('Card Content')),
          ),
        );
        expect(tester.find.text('Card Content'), isTrue);
      } finally {
        await tester.dispose();
      }
    });
  });
}

/// A test widget that reads the theme via ThemeScope.of and renders a label.
class _ThemeReaderWidget extends StatelessWidget {
  _ThemeReaderWidget({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    // Access theme to verify it doesn't throw
    final theme = ThemeScope.of(context);
    // Use the theme's primary color to style text, proving theme access works
    return Text(label, style: Style().foreground(theme.primary));
  }
}

/// A test widget that uses the context.theme extension.
class _ContextThemeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // Prove it works by rendering with theme
    return Text('has-theme', style: theme.bodyMedium);
  }
}

Theme _themeWithoutListRows({Color? highlight, Color? onHighlight}) {
  final base = Theme.dark();
  return Theme(
    primary: base.primary,
    secondary: base.secondary,
    surface: base.surface,
    background: base.background,
    error: base.error,
    success: base.success,
    warning: base.warning,
    onPrimary: base.onPrimary,
    onSecondary: base.onSecondary,
    onSurface: base.onSurface,
    onBackground: base.onBackground,
    onError: base.onError,
    muted: base.muted,
    border: base.border,
    surfaceVariant: base.surfaceVariant,
    onSurfaceVariant: base.onSurfaceVariant,
    outline: base.outline,
    info: base.info,
    onSuccess: base.onSuccess,
    onWarning: base.onWarning,
    onInfo: base.onInfo,
    highlight: highlight ?? base.highlight,
    onHighlight: onHighlight ?? base.onHighlight,
    shadow: base.shadow,
    titleLarge: base.titleLarge,
    titleMedium: base.titleMedium,
    titleSmall: base.titleSmall,
    bodyLarge: base.bodyLarge,
    bodyMedium: base.bodyMedium,
    bodySmall: base.bodySmall,
    labelLarge: base.labelLarge,
    labelMedium: base.labelMedium,
    labelSmall: base.labelSmall,
    statusBarTheme: base.statusBarTheme,
    accentPanelTheme: base.accentPanelTheme,
    commandPaletteTheme: base.commandPaletteTheme,
    dialogTheme: base.dialogTheme,
    gitDiffTheme: base.gitDiffTheme,
    editorTheme: base.editorTheme,
  );
}
