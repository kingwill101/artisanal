/// High-level app shell for artisanal widgets.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

import 'package:artisanal/tui.dart' show View;

import '../components/components_widgets.dart' show DebugOverlayPosition;
import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../core/widget.dart';
import '../navigation/navigation.dart'
    show
        Navigator,
        NavigatorObserver,
        PopBehavior,
        RouteFactory,
        RouteWidgetBuilder;
import '../theme/theme.dart' show Theme;
import '../theme/theme_scope.dart' show ThemeScope;
import 'widget_app.dart';

/// A high-level root shell for artisanal widget applications.
///
/// [ArtisanalApp] configures theming, terminal background publication,
/// navigation, and window title handling on top of [WidgetApp].
///
/// For simple apps, pass a [home] widget and optional named [routes]:
///
/// ```dart
/// final app = ArtisanalApp(
///   title: 'Demo',
///   home: HomeScreen(),
///   theme: Theme.adaptive(),
/// );
/// ```
///
/// If you already have a fully composed widget tree, pass [child] instead.
final class ArtisanalApp extends WidgetApp {
  ArtisanalApp({
    this.title,
    this.theme,
    this.themeBuilder,
    this.child,
    this.home,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.popBehavior = PopBehavior.defaultBehavior,
    this.observers = const [],
    super.scanZones = false,
    super.useHitTesting = true,
    super.handleFrameTick = false,
    super.enableRenderMetrics = true,
    super.enableRenderMetricsInjection = true,
    super.debugOverlay = false,
    super.debugOverlayPosition = DebugOverlayPosition.topRight,
    super.debugRebuilds = false,
  }) : assert(
         child != null ||
             home != null ||
             routes != null ||
             onGenerateRoute != null,
         'Provide child, home, routes, or onGenerateRoute.',
       ),
       assert(
         child == null ||
             (home == null &&
                 routes == null &&
                 initialRoute == null &&
                 onGenerateRoute == null &&
                 onUnknownRoute == null),
         'child cannot be combined with navigation parameters.',
       ),
       super(
         _ArtisanalAppRoot(
           appTheme: theme,
           themeBuilder: themeBuilder,
           child: child,
           home: home,
           routes: routes,
           initialRoute: initialRoute,
           onGenerateRoute: onGenerateRoute,
           onUnknownRoute: onUnknownRoute,
           popBehavior: popBehavior,
           observers: observers,
         ),
         backgroundColorBuilder: () =>
             (themeBuilder?.call() ?? theme ?? Theme.adaptive()).background,
       );

  /// Terminal window title published via [View.windowTitle].
  final String? title;

  /// Explicit theme for the app shell.
  ///
  /// When omitted, [Theme.adaptive] is used.
  final Theme? theme;

  /// Optional dynamic theme callback evaluated during each view build.
  ///
  /// This allows the app shell to follow external theme state while still
  /// publishing the correct terminal background color.
  final Theme Function()? themeBuilder;

  /// Fully composed widget tree to render directly.
  final Widget? child;

  /// Root widget for the navigator's default `'/'` route.
  final Widget? home;

  /// Named routes for the app shell navigator.
  final Map<String, RouteWidgetBuilder>? routes;

  /// Initial named route to display.
  final String? initialRoute;

  /// Route factory used when [routes] cannot resolve a route.
  final RouteFactory? onGenerateRoute;

  /// Fallback route factory for unknown routes.
  final RouteFactory? onUnknownRoute;

  /// Keyboard pop behavior for the navigator.
  final PopBehavior popBehavior;

  /// Navigation observers attached to the shell navigator.
  final List<NavigatorObserver> observers;

  @override
  Object view() {
    final base = super.view();
    if (title == null || title!.isEmpty) return base;

    if (base is View) {
      return View(
        content: base.content,
        onMouse: base.onMouse,
        cursor: base.cursor,
        backgroundColor: base.backgroundColor,
        foregroundColor: base.foregroundColor,
        windowTitle: title,
        progressBar: base.progressBar,
        altScreen: base.altScreen,
        reportFocus: base.reportFocus,
        bracketedPaste: base.bracketedPaste,
        mouseMode: base.mouseMode,
        keyboardEnhancements: base.keyboardEnhancements,
      );
    }

    if (base is String) {
      return View(content: base, windowTitle: title);
    }

    return base;
  }
}

final class _ArtisanalAppRoot extends StatelessWidget {
  _ArtisanalAppRoot({
    this.appTheme,
    this.themeBuilder,
    this.child,
    this.home,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    required this.popBehavior,
    required this.observers,
  });

  final Theme? appTheme;
  final Theme Function()? themeBuilder;
  final Widget? child;
  final Widget? home;
  final Map<String, RouteWidgetBuilder>? routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final RouteFactory? onUnknownRoute;
  final PopBehavior popBehavior;
  final List<NavigatorObserver> observers;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme =
        themeBuilder?.call() ?? appTheme ?? Theme.adaptive();
    final root =
        child ??
        Navigator(
          home: home,
          routes: routes,
          initialRoute: initialRoute,
          onGenerateRoute: onGenerateRoute,
          onUnknownRoute: onUnknownRoute,
          popBehavior: popBehavior,
          observers: observers,
        );

    return ThemeScope(theme: resolvedTheme, child: root);
  }
}
