/// Keymap surfaces + which-key integration for artisanal widgets.
///
/// Prefer [KeymapHubScope] + [ShortcutSurfaceScope] with a [tui.KeymapHub]
/// (OpenTUI-style layers). [ChordController] / [ChordHost] remain as a
/// compatibility facade over chord messages.
///
/// [WhichKeySlot] reads pending state from the hub (or chord controller).
library;

export 'chord_controller.dart';
export 'chord_host.dart';
export 'chord_scope.dart';
export 'keymap_hub_scope.dart';
export 'shortcut_surface_scope.dart';
export 'shortcuts_sheet.dart';
export 'which_key_slot.dart';
