/// Helpers for GitHub's light/dark image variants.
///
/// GitHub uses URL fragments as presentation-only markers. They are not a
/// general-purpose link visibility mechanism: only image sources, and links
/// whose content is an image, use these markers.
library;

const _lightMarker = 'gh-light-mode-only';
const _darkMarker = 'gh-dark-mode-only';

/// Whether [url] is a GitHub light/dark variant visible on this background.
bool githubImageVariantVisible(String url, {required bool hasDarkBackground}) {
  final marker = _githubModeMarker(url);
  return marker == null ||
      marker == (hasDarkBackground ? _darkMarker : _lightMarker);
}

/// Returns [url] without a GitHub presentation marker.
String githubImageCacheKey(String url) {
  final index = url.lastIndexOf('#');
  if (index < 0) return url;
  final marker = url.substring(index + 1);
  return marker == _lightMarker || marker == _darkMarker
      ? url.substring(0, index)
      : url;
}

String? _githubModeMarker(String url) {
  final index = url.lastIndexOf('#');
  if (index < 0) return null;
  final fragment = url.substring(index + 1);
  return fragment == _lightMarker || fragment == _darkMarker ? fragment : null;
}
