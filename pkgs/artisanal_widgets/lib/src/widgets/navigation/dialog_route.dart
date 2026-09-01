/// A route that displays a dialog modal with an animated overlay barrier.
///
/// Wraps the content in a single overlay entry that renders both the barrier
/// and the dialog. The barrier fades in with a configurable [AnimationStyle].
/// Tapping the barrier dismisses the dialog when [barrierDismissible] is true.
library;

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/runtime.dart' show Cmd, KeyMsg, Msg;

import '../animation/animation_controller.dart' show AnimationController;
import '../animation/animation_mixin.dart' show AnimationMixin;
import '../animation/animations.dart' show AnimationStatus;
import '../animation/curves.dart' show Curves;
import '../components/overlay.dart' show OverlayEntry;
import '../core/framework.dart' show BuildContext, State, StatefulWidget;
import '../core/widget.dart';
import '../focus/focus.dart' show FocusScope;
import '../layout/_layout_core.dart';
import '../theme/theme.dart' show Theme;
import '../theme/theme_scope.dart' show ThemeScope;
import 'animation_style.dart' show AnimationStyle;
import 'navigator.dart' show Navigator;
import 'route.dart' show Route, RouteWidgetBuilder;
import 'route_settings.dart' show RouteSettings;

/// A route that displays a modal dialog with an animated barrier.
///
/// Unlike [ModalRoute] which uses a separate [FadeModalBarrier] with its own
/// [AnimationController], [DialogRoute] owns the animation and renders both
/// the barrier and the dialog in a single overlay entry.
///
/// This provides a more Flutter-like dialog experience with coordinated
/// barrier and content animation, theme capture, and safe area support.
///
/// ```dart
/// Navigator.of(context).push(
///   DialogRoute<bool>(
///     builder: (context) => MyDialog(),
///     barrierDismissible: true,
///   ),
/// );
/// ```
class DialogRoute<T> extends Route<T> {
  /// Creates a dialog route.
  DialogRoute({
    required this.builder,
    this.barrierDismissible = true,
    this.barrierColor,
    this.barrierLabel,
    this.useSafeArea = true,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.animationStyle,
    this.capturedTheme,
    super.settings,
  });

  /// Builds the dialog content.
  final RouteWidgetBuilder builder;

  /// Whether tapping the barrier dismisses the dialog.
  final bool barrierDismissible;

  /// The color of the barrier behind the dialog.
  ///
  /// When null, no visible barrier color is rendered but the barrier still
  /// intercepts taps when [barrierDismissible] is true.
  final Color? barrierColor;

  /// Accessibility label for the barrier.
  ///
  /// Used by screen readers to describe the dismiss action.
  final String? barrierLabel;

  /// Whether to wrap the dialog with [SafeArea].
  ///
  /// When true, the dialog avoids terminal insets if any are reported.
  final bool useSafeArea;

  /// How to align the dialog within the overlay.
  final Alignment alignment;

  /// Optional width constraint for the dialog.
  final num? width;

  /// Optional height constraint for the dialog.
  final num? height;

  /// Animation style for the barrier and dialog entrance/exit.
  final AnimationStyle? animationStyle;

  /// The theme to apply to the dialog content.
  ///
  /// Captured from the caller's build context at push time so the dialog
  /// inherits the correct theme even though it renders above the navigator.
  final Theme? capturedTheme;

  /// The [RouteSettings] name used for this dialog route.
  static const String routeName = '/dialog';

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    return <OverlayEntry>[
      OverlayEntry(
        opaque: false,
        maintainState: true,
        builder: _buildDialogFrame,
      ),
    ];
  }

  Widget _buildDialogFrame(BuildContext context) {
    return _DialogFrame<T>(
      builder: builder,
      capturedTheme: capturedTheme,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      alignment: alignment,
      width: width,
      height: height,
      animationStyle: animationStyle,
    );
  }
}

// ---------------------------------------------------------------------------
// _DialogFrame — StatefulWidget that owns the animation controller
// ---------------------------------------------------------------------------

/// A stateful widget that provides the animation lifecycle for a [DialogRoute].
///
/// Renders the barrier (colored overlay + gesture detector) and the dialog
/// content in a single [Stack]. The barrier fades in/out driven by the
/// animation controller managed via [AnimationMixin].
class _DialogFrame<T> extends StatefulWidget {
  _DialogFrame({
    required this.builder,
    this.capturedTheme,
    this.barrierColor,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.useSafeArea = true,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.animationStyle,
  });

  final RouteWidgetBuilder builder;
  final Theme? capturedTheme;
  final Color? barrierColor;
  final bool barrierDismissible;
  final String? barrierLabel;
  final bool useSafeArea;
  final Alignment alignment;
  final num? width;
  final num? height;
  final AnimationStyle? animationStyle;

  @override
  State<_DialogFrame<T>> createState() => _DialogFrameState<T>();
}

class _DialogFrameState<T> extends State<_DialogFrame<T>> with AnimationMixin {
  late AnimationController _controller;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = createAnimationController(
      duration:
          widget.animationStyle?.duration ?? const Duration(milliseconds: 150),
      reverseDuration: widget.animationStyle?.reverseDuration,
    );
    _controller.addListener(() => setState(() {}));
    _controller.addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _isDismissing) {
      _isDismissing = false;
      // The reverse animation completed; now pop the route.
      // The navigator is an ancestor of this context since this widget
      // lives inside the navigator's overlay entries.
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }

  /// Starts the reverse animation and pops the route when it completes.
  ///
  /// Returns the [Cmd] from [AnimationController.reverse] so the caller
  /// (e.g. [handleIntercept] or a gesture callback) can execute the
  /// animation. Returns `null` if already dismissing.
  Cmd? _dismiss() {
    if (_isDismissing) return null;
    _isDismissing = true;
    return _controller.reverse(
      curve:
          widget.animationStyle?.reverseCurve ??
          widget.animationStyle?.curve ??
          Curves.easeOut,
    );
  }

  @override
  Cmd? handleInit() {
    return _controller.forward(
      curve: widget.animationStyle?.curve ?? Curves.easeOut,
    );
  }

  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is KeyMsg && msg.key.type == terminal_keys.KeyType.escape) {
      if (widget.barrierDismissible) {
        return _dismiss();
      }
      // Consume escape even when non-dismissible to prevent the Navigator
      // from popping the route via its default escape-button handling.
      return Cmd.none();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = _controller.value.clamp(0.0, 1.0);
    final theme = ThemeScope.of(context);

    // -- Barrier layer --
    Widget barrier = GestureDetector(
      onTap: widget.barrierDismissible ? _dismiss : null,
      child: Opacity(
        opacity: effectiveOpacity,
        child: Container(color: widget.barrierColor ?? theme.background),
      ),
    );

    // -- Dialog content --
    Widget dialog = Builder(builder: widget.builder);

    // Apply captured theme so the dialog sees the caller's theme.
    final capturedTheme = widget.capturedTheme;
    if (capturedTheme != null) {
      dialog = ThemeScope(theme: capturedTheme, child: dialog);
    }

    // SafeArea is not applicable to terminal environments (no system status bars).
    // The useSafeArea parameter is accepted for API parity with Flutter.

    if (widget.width != null || widget.height != null) {
      dialog = SizedBox(
        width: widget.width,
        height: widget.height,
        child: dialog,
      );
    }
    dialog = Align(alignment: widget.alignment, child: dialog);

    // Trap focus inside the dialog so search/prompt TextFields with autofocus
    // claim the caret instead of the field behind the modal (e.g. home prompt).
    dialog = FocusScope(isTrapped: true, child: dialog);

    // -- Assemble stack --
    return Stack(fit: StackFit.expand, children: <Widget>[barrier, dialog]);
  }
}

// ---------------------------------------------------------------------------
// Navigator helpers — top-level showDialog matching Flutter's API
// ---------------------------------------------------------------------------

/// Shows a material design dialog.
///
/// The dialog route is created and pushed onto the navigator that most
/// closely encloses the given [context].
///
/// Returns a [Future] that resolves to the value passed to
/// [Navigator.pop] when the dialog is dismissed.
///
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (ctx) => DialogConfirm(
///     title: 'Delete?',
///     message: 'This cannot be undone.',
///   ),
/// );
/// ```
Future<T?> showDialog<T>({
  required BuildContext context,
  required RouteWidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  Alignment alignment = Alignment.center,
  num? width,
  num? height,
  RouteSettings? routeSettings,
  AnimationStyle? animationStyle,
}) {
  // Capture the caller's theme so the dialog inherits the correct theme
  // even though it renders in the navigator's overlay (which may have a
  // different ThemeScope ancestor).
  final capturedTheme = ThemeScope.maybeOf(context);

  final route = DialogRoute<T>(
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    alignment: alignment,
    width: width,
    height: height,
    animationStyle: animationStyle,
    capturedTheme: capturedTheme,
    settings: routeSettings ?? RouteSettings(name: DialogRoute.routeName),
  );

  return Navigator.of(context).push<T>(route);
}
