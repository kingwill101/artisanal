/// Hit-test behavior enum for controlling how gesture detectors
/// participate in hit testing.
library;

/// Controls how a widget behaves during hit testing.
///
/// This determines whether a widget absorbs hit test events or allows
/// them to pass through to widgets behind it in the paint order.
enum HitTestBehavior {
  /// Only receives events if a child was hit.
  ///
  /// The widget itself will not be added to the hit test result unless
  /// one of its children reports a hit. This is the default for
  /// [GestureDetector].
  deferToChild,

  /// Receives events within its bounds and blocks targets behind it.
  ///
  /// The widget always adds itself to the hit test result when the
  /// pointer is within bounds, preventing siblings painted earlier
  /// (behind) from receiving the event.
  opaque,

  /// Receives events within its bounds but allows targets behind it
  /// to also receive the event.
  ///
  /// The widget adds itself to the hit test result but returns
  /// `false` from hit testing when no child was hit, allowing
  /// earlier-painted siblings to also participate.
  translucent,
}
