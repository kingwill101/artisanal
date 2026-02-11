library;

import 'dart:convert';
import 'dart:io';

import 'package:artisanal/style.dart' as style;

enum OpenCodeThemeMode { dark, light }

sealed class OpenCodeThemeAtom {
  const OpenCodeThemeAtom();

  factory OpenCodeThemeAtom.fromJson(Object? raw) {
    if (raw is int) {
      if (raw < 0 || raw > 255) {
        throw FormatException('ANSI color out of range: $raw');
      }
      return OpenCodeThemeAnsi(raw);
    }
    if (raw is String) {
      if (raw == 'none') return const OpenCodeThemeNone();
      if (_hexRegex.hasMatch(raw)) return OpenCodeThemeHex(raw);
      if (_nameRegex.hasMatch(raw)) return OpenCodeThemeRef(raw);
    }
    throw FormatException('Invalid color value: $raw');
  }

  static final RegExp _hexRegex = RegExp(r'^#[0-9a-fA-F]{6}$');
  static final RegExp _nameRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
}

class OpenCodeThemeHex extends OpenCodeThemeAtom {
  const OpenCodeThemeHex(this.value);
  final String value;
}

class OpenCodeThemeAnsi extends OpenCodeThemeAtom {
  const OpenCodeThemeAnsi(this.value);
  final int value;
}

class OpenCodeThemeNone extends OpenCodeThemeAtom {
  const OpenCodeThemeNone();
}

class OpenCodeThemeRef extends OpenCodeThemeAtom {
  const OpenCodeThemeRef(this.name);
  final String name;
}

sealed class OpenCodeThemeValue {
  const OpenCodeThemeValue();

  factory OpenCodeThemeValue.fromJson(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final darkRaw = raw['dark'];
      final lightRaw = raw['light'];
      if (darkRaw == null || lightRaw == null) {
        throw const FormatException(
          'Theme variant must include dark and light',
        );
      }
      return OpenCodeThemeVariant(
        dark: OpenCodeThemeAtom.fromJson(darkRaw),
        light: OpenCodeThemeAtom.fromJson(lightRaw),
      );
    }
    return OpenCodeThemeSingle(OpenCodeThemeAtom.fromJson(raw));
  }

  OpenCodeThemeAtom atomForMode(OpenCodeThemeMode mode);
}

class OpenCodeThemeSingle extends OpenCodeThemeValue {
  const OpenCodeThemeSingle(this.value);
  final OpenCodeThemeAtom value;

  @override
  OpenCodeThemeAtom atomForMode(OpenCodeThemeMode mode) => value;
}

class OpenCodeThemeVariant extends OpenCodeThemeValue {
  const OpenCodeThemeVariant({required this.dark, required this.light});

  final OpenCodeThemeAtom dark;
  final OpenCodeThemeAtom light;

  @override
  OpenCodeThemeAtom atomForMode(OpenCodeThemeMode mode) {
    return mode == OpenCodeThemeMode.dark ? dark : light;
  }
}

class OpenCodeThemeDocument {
  OpenCodeThemeDocument({this.schema, required this.defs, required this.theme});

  final String? schema;
  final Map<String, OpenCodeThemeAtom> defs;
  final Map<String, OpenCodeThemeValue> theme;

  factory OpenCodeThemeDocument.fromJsonMap(Map<String, dynamic> json) {
    final defsJson = json['defs'];
    final themeJson = json['theme'];

    if (themeJson is! Map<String, dynamic>) {
      throw const FormatException('Missing or invalid theme object');
    }

    final defs = <String, OpenCodeThemeAtom>{};
    if (defsJson is Map<String, dynamic>) {
      for (final entry in defsJson.entries) {
        defs[entry.key] = OpenCodeThemeAtom.fromJson(entry.value);
      }
    }

    final theme = <String, OpenCodeThemeValue>{};
    for (final entry in themeJson.entries) {
      theme[entry.key] = OpenCodeThemeValue.fromJson(entry.value);
    }

    final schema = json[r'$schema'];
    return OpenCodeThemeDocument(
      schema: schema is String ? schema : null,
      defs: defs,
      theme: theme,
    );
  }

  factory OpenCodeThemeDocument.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Theme file root must be an object');
    }
    return OpenCodeThemeDocument.fromJsonMap(decoded);
  }

  static Future<OpenCodeThemeDocument> loadFromFile(String path) async {
    final source = await File(path).readAsString();
    return OpenCodeThemeDocument.fromJsonString(source);
  }

  style.Color resolveColor(String name) {
    final dark = _resolveThemeName(name, OpenCodeThemeMode.dark, <String>{});
    final light = _resolveThemeName(name, OpenCodeThemeMode.light, <String>{});
    if (dark == light) return dark;
    return style.AdaptiveColor(light: light, dark: dark);
  }

  Map<String, style.Color> resolveThemeColors() {
    final out = <String, style.Color>{};
    for (final key in theme.keys) {
      out[key] = resolveColor(key);
    }
    return out;
  }

  style.Color _resolveThemeName(
    String name,
    OpenCodeThemeMode mode,
    Set<String> stack,
  ) {
    final marker = '${mode.name}:$name';
    if (stack.contains(marker)) {
      throw FormatException('Circular color reference: $marker');
    }

    final value = theme[name];
    if (value == null) {
      throw FormatException('Unknown theme color key: $name');
    }

    stack.add(marker);
    final resolved = _resolveAtom(value.atomForMode(mode), mode, stack);
    stack.remove(marker);
    return resolved;
  }

  style.Color _resolveAtom(
    OpenCodeThemeAtom atom,
    OpenCodeThemeMode mode,
    Set<String> stack,
  ) {
    if (atom is OpenCodeThemeHex) return style.BasicColor(atom.value);
    if (atom is OpenCodeThemeAnsi) return style.AnsiColor(atom.value);
    if (atom is OpenCodeThemeNone) return const style.NoColor();
    if (atom is OpenCodeThemeRef) {
      final def = defs[atom.name];
      if (def != null) {
        return _resolveAtom(def, mode, stack);
      }
      return _resolveThemeName(atom.name, mode, stack);
    }
    throw FormatException('Unsupported color atom: $atom');
  }
}
