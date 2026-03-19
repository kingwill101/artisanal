/// High-level app shell for artisanal widgets.
library;

import 'package:artisanal/tui.dart' show View;

import '../components/components_widgets.dart'
    show
        DebugConsoleController,
        DebugConsoleHost,
        DebugOverlayPosition;
import '../core/framework.dart' show BuildContext, StatelessWidget;
import '../core/widget.dart';
import '../layout/layout_widgets.dart' show ImageAutoMode;
import '../navigation/navigation.dart'
    show
        Navigator,
        NavigatorObserver,
        PopBehavior,
        RouteFactory,
        RouteWidgetBuilder;
import '../theme/theme.dart' show Theme, hasDarkBackground;
import '../theme/theme_scope.dart' show ThemeScope;
import 'widget_app.dart';

/// Controls how [ArtisanalApp] resolves its shell theme.
enum ThemeMode {
  /// Follow the terminal background when possible.
  system,

  /// Always use the light/base theme.
  light,

  /// Always use the dark theme.
  dark,
}

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
///   themeMode: ThemeMode.system,
///   home: HomeScreen(),
/// );
/// ```
///
/// If you already have a fully composed widget tree, pass [child] instead.
final class ArtisanalApp extends WidgetApp {
  ArtisanalApp({
    this.title,
    this.theme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.themeBuilder,
    ImageAutoMode imageAutoMode = ImageAutoMode.environment,
    this.child,
    this.home,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.popBehavior = PopBehavior.defaultBehavior,
    this.observers = const [],
    this.debugConsoleController,
    this.debugConsoleHeight = 8,
    this.debugConsoleCapturePrint = false,
    this.debugConsoleCaptureErrors = false,
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
           darkTheme: darkTheme,
           themeMode: themeMode,
           themeBuilder: themeBuilder,
           child: child,
           home: home,
           routes: routes,
           initialRoute: initialRoute,
           onGenerateRoute: onGenerateRoute,
           onUnknownRoute: onUnknownRoute,
           popBehavior: popBehavior,
           observers: observers,
           debugConsoleController: debugConsoleController,
           debugConsoleHeight: debugConsoleHeight,
         ),
         backgroundColorBuilder: () =>
         _resolveArtisanalTheme(
               theme: theme,
               darkTheme: darkTheme,
               themeMode: themeMode,
               themeBuilder: themeBuilder,
             ).background,
         imageAutoMode: imageAutoMode,
       );

  /// Terminal window title published via [View.windowTitle].
  final String? title;

  /// Explicit theme for the app shell.
  ///
  /// When omitted, [Theme.adaptive] is used.
  final Theme? theme;

  /// Explicit dark theme used when [themeMode] resolves to [ThemeMode.dark] or
  /// a terminal-driven dark system theme.
  final Theme? darkTheme;

  /// Controls whether the shell follows the terminal background or forces a
  /// specific light/dark theme choice.
  final ThemeMode themeMode;

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

  /// Optional developer console controller exposed to the app subtree.
  ///
  /// When provided, [ArtisanalApp] mounts a built-in bottom console pane that
  /// can be toggled with `F10`.
  final DebugConsoleController? debugConsoleController;

  /// Number of visible log rows in the built-in debug console.
  final int debugConsoleHeight;

  /// Whether `runArtisanalApp` should capture `print()` output into the
  /// attached [debugConsoleController].
  final bool debugConsoleCapturePrint;

  /// Whether `runArtisanalApp` should capture uncaught zone errors into the
  /// attached [debugConsoleController].
  final bool debugConsoleCaptureErrors;

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
    this.darkTheme,
    required this.themeMode,
    this.themeBuilder,
    this.child,
    this.home,
    this.routes,
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    required this.popBehavior,
    required this.observers,
    this.debugConsoleController,
    required this.debugConsoleHeight,
  });

  final Theme? appTheme;
  final Theme? darkTheme;
  final ThemeMode themeMode;
  final Theme Function()? themeBuilder;
  final Widget? child;
  final Widget? home;
  final Map<String, RouteWidgetBuilder>? routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final RouteFactory? onUnknownRoute;
  final PopBehavior popBehavior;
  final List<NavigatorObserver> observers;
  final DebugConsoleController? debugConsoleController;
  final int debugConsoleHeight;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = _resolveArtisanalTheme(
      theme: appTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      themeBuilder: themeBuilder,
    );
    var root =
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

    final consoleController = debugConsoleController;
    if (consoleController != null) {
      root = DebugConsoleHost(
        controller: consoleController,
        consoleHeight: debugConsoleHeight,
        child: root,
      );
    }

    return ThemeScope(theme: resolvedTheme, child: root);
  }
}

Theme _resolveArtisanalTheme({
  Theme? theme,
  Theme? darkTheme,
  required ThemeMode themeMode,
  Theme Function()? themeBuilder,
}) {
  final builtTheme = themeBuilder?.call();
  if (builtTheme != null) return builtTheme;

  return switch (themeMode) {
    ThemeMode.light => theme ?? darkTheme ?? Theme.light(),
    ThemeMode.dark => darkTheme ?? theme ?? Theme.dark(),
    ThemeMode.system => switch ((theme, darkTheme)) {
      (null, null) => Theme.adaptive(),
      _ => hasDarkBackground
          ? darkTheme ?? theme ?? Theme.dark()
          : theme ?? darkTheme ?? Theme.light(),
    },
  };
}
