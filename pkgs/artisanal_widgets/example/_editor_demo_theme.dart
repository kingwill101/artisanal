import 'package:artisanal_widgets/widgets.dart' as w;

final List<String> editorDemoThemePresetNames = <String>[
  'adaptive',
  'dark',
  'light',
  ...w.OpenCodeThemes.names,
];

w.Theme resolveEditorDemoTheme(String preset) {
  return switch (preset) {
    'adaptive' => w.Theme.adaptive(),
    'dark' => w.Theme.dark(),
    'light' => w.Theme.light(),
    _ => w.OpenCodeThemes.byName(preset),
  };
}

String editorDemoThemeLabel(String preset) {
  return switch (preset) {
    'adaptive' => 'Adaptive core',
    'dark' => 'Dark core',
    'light' => 'Light core',
    _ => 'OpenCode ${_editorDemoThemeDisplayName(preset)}',
  };
}

String nextEditorDemoThemePreset(String current, {required bool forward}) {
  final currentIndex = editorDemoThemePresetNames.indexOf(current);
  final startIndex = currentIndex < 0 ? 0 : currentIndex;
  final delta = forward ? 1 : -1;
  final nextIndex =
      (startIndex + delta + editorDemoThemePresetNames.length) %
      editorDemoThemePresetNames.length;
  return editorDemoThemePresetNames[nextIndex];
}

String _editorDemoThemeDisplayName(String preset) {
  if (preset.isEmpty) {
    return preset;
  }
  final spaced = preset.replaceAllMapped(
    RegExp(r'(?<!^)([A-Z])'),
    (match) => ' ${match[1]}',
  );
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
