/// Auto which-key chrome driven by [KeymapHub] or [ChordController].
library;

import 'package:artisanal/style.dart' as style show Color, Style;
import 'package:artisanal/runtime.dart' as tui;

import '../components/which_key.dart';
import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../core/widget.dart' show Widget;
import '../layout/column.dart';
import '../layout/container.dart';
import '../layout/enums.dart' show CrossAxisAlignment;
import '../layout/padding.dart';
import '../layout/sized_box.dart';
import '../layout/spacing.dart' show EdgeInsets;
import '../layout/text.dart';
import 'chord_controller.dart';
import 'keymap_hub_scope.dart';

/// Renders nothing when idle; when a sequence/chord is pending, paints a
/// banner + [WhichKeyPanel] from the nearest [tui.KeymapHub] (preferred) or
/// [ChordController].
///
/// ```dart
/// WhichKeySlot(
///   bannerColor: theme.primary,
///   bannerForeground: theme.background,
/// )
/// ```
class WhichKeySlot extends StatelessWidget {
  WhichKeySlot({
    this.hub,
    this.controller,
    this.showBanner = true,
    this.bannerColor,
    this.bannerForeground,
    this.title = 'which-key',
    this.layout = WhichKeyLayout.dock,
    this.background,
    this.borderColor,
    this.keyBackground,
    this.keyForeground,
    this.descriptionForeground,
    this.mutedForeground,
    this.accentForeground,
    super.key,
  });

  /// Explicit hub; defaults to [KeymapHubScope.maybeOf].
  final tui.KeymapHub? hub;

  /// Explicit chord controller (legacy); used if no hub pending state.
  final ChordController? controller;

  /// Whether to paint the bright prefix banner above the panel.
  final bool showBanner;

  final style.Color? bannerColor;
  final style.Color? bannerForeground;

  final String title;
  final WhichKeyLayout layout;

  final style.Color? background;
  final style.Color? borderColor;
  final style.Color? keyBackground;
  final style.Color? keyForeground;
  final style.Color? descriptionForeground;
  final style.Color? mutedForeground;
  final style.Color? accentForeground;

  @override
  Widget build(BuildContext context) {
    final resolvedHub = hub ?? KeymapHubScope.maybeOf(context);
    if (resolvedHub != null && resolvedHub.isSequencePending) {
      return _build(
        prefixLabel: resolvedHub.pendingPrefixLabel,
        entries: whichKeyEntriesFromContinuations(
          resolvedHub.activeContinuations,
        ),
        bannerText: _hubBanner(resolvedHub),
      );
    }

    final chord = controller ?? ChordController.maybeOf(context);
    if (chord == null || !chord.isActive) {
      return SizedBox.shrink();
    }

    return _build(
      prefixLabel: chord.prefixLabel,
      entries: chord.entries,
      bannerText: chord.whichKeyBanner(title: title),
    );
  }

  String _hubBanner(tui.KeymapHub h) {
    final keys = h.activeContinuations.map((c) => c.keyLabel).join(' ');
    final prefix = h.pendingPrefixLabel;
    if (keys.isEmpty) return ' $title  $prefix ';
    return ' $title  $prefix then:  $keys ';
  }

  Widget _build({
    required String prefixLabel,
    required List<WhichKeyEntry> entries,
    required String bannerText,
  }) {
    final bannerFg = bannerForeground;
    final bannerBg = bannerColor;
    final bannerStyle = style.Style()..bold();
    if (bannerFg != null) {
      bannerStyle.foreground(bannerFg);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBanner && bannerBg != null)
          Container(
            color: bannerBg,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(bannerText, style: bannerStyle),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: WhichKeyPanel(
            prefixLabel: prefixLabel,
            title: title,
            entries: entries,
            layout: layout,
            background: background,
            borderColor: borderColor,
            keyBackground: keyBackground,
            keyForeground: keyForeground,
            descriptionForeground: descriptionForeground,
            mutedForeground: mutedForeground,
            accentForeground: accentForeground,
          ),
        ),
      ],
    );
  }
}
