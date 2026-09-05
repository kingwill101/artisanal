/// Observer pattern primitives for the animation system.
///
/// Backed by `package:listen` — the pure-Dart notifier package from
/// Flutter (`Listenable`, `ValueListenable`, `ChangeNotifier`,
/// `ValueNotifier`). This library is a compatibility re-export so existing
/// `src/widgets/animation/listenable.dart` imports keep working; new code
/// should import `package:listen/listen.dart` directly.
///
/// These types are the foundation that `Animation`, `AnimationController`,
/// and `AnimatedBuilder` are built on.
library;

export 'package:listen/listen.dart';
