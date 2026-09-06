library;

/// Media attachment lifecycle for prompt composers.
///
/// Binds an [InlineElementStore] id to everything an image (or video
/// poster) needs: source bytes, mime, dimensions, a preview pipeline
/// (`pending → ready | failed | unsupported`), and a modal viewer state.
/// Decoding, resizing, and protocol conversion are host-side (they need
/// image codecs and terminal capability probes); this module owns the
/// states every host shares so pixels never block the draw loop.

/// Readiness of the terminal pixel payload for an attachment.
enum AttachmentPreviewStatus { pending, ready, failed, unsupported }

/// Prepared pixel payload (or failure) for one attachment.
final class AttachmentPreview {
  AttachmentPreview() : _status = AttachmentPreviewStatus.pending;

  AttachmentPreviewStatus _status;
  List<int>? _payload;
  int? _width;
  int? _height;
  String? _error;

  AttachmentPreviewStatus get status => _status;
  List<int>? get payload =>
      _status == AttachmentPreviewStatus.ready ? _payload : null;
  int? get width => _width;
  int? get height => _height;
  String? get error => _error;

  bool get isPending => _status == AttachmentPreviewStatus.pending;

  void markReady({
    required List<int> payload,
    required int width,
    required int height,
  }) {
    _payload = List<int>.unmodifiable(payload);
    _width = width;
    _height = height;
    _error = null;
    _status = AttachmentPreviewStatus.ready;
  }

  void markFailed([String? error]) {
    _payload = null;
    _error = error;
    _status = AttachmentPreviewStatus.failed;
  }

  void markUnsupported({int? width, int? height}) {
    _payload = null;
    _width = width ?? _width;
    _height = height ?? _height;
    _status = AttachmentPreviewStatus.unsupported;
  }
}

/// One attached media item bound to an inline element id.
final class MediaAttachment {
  MediaAttachment({
    required this.elementId,
    required this.displayNumber,
    required this.mimeType,
    this.dimensions,
    this.sourceLabel,
    List<int>? sourceBytes,
  }) : _sourceBytes = sourceBytes;

  /// Id of the `image` element rendering this attachment's chip.
  final int elementId;

  /// 1-based number for the current prompt (the `1` in `[Image #1]`).
  final int displayNumber;
  final String mimeType;
  final ({int width, int height})? dimensions;

  /// User-visible origin (file path or description) for overlays.
  final String? sourceLabel;
  List<int>? _sourceBytes;
  final AttachmentPreview preview = AttachmentPreview();

  List<int>? get sourceBytes => _sourceBytes;

  /// Frees source bytes (e.g. after session persistence); the prepared
  /// preview payload is unaffected.
  void releaseSourceBytes() => _sourceBytes = null;

  String get chipText => imageChipText(displayNumber);
}

/// Chip text for an attachment. Always path-free: origins appear only in
/// hover/cursor overlays, never in the buffer.
String imageChipText(int displayNumber) => '[Image #$displayNumber]';

/// Monotonic display-number assigner; reset when the prompt clears.
final class DisplayNumberAssigner {
  int _next = 1;

  int assign() => _next++;
  void reset() => _next = 1;
}

/// What the composer may do with an attachment right now.
enum MediaAffordance {
  /// Render pixels (overlay/modal).
  imageOverlay,

  /// Protocols unavailable: show the text fallback (`[Open …]`).
  textFallback,
}

/// Resolves the affordance from capability probes. Hosts read the real
/// probes (ultraviolet terminal capabilities); [forceTextFallback] covers
/// minimal/scrollback-only modes that never paint pixels.
MediaAffordance resolveMediaAffordance({
  required bool protocolSupported,
  bool forceTextFallback = false,
}) {
  if (forceTextFallback || !protocolSupported) {
    return MediaAffordance.textFallback;
  }
  return MediaAffordance.imageOverlay;
}

/// State for a modal media viewer.
///
/// [MediaViewerState.open] returns instantly with `loading: true` when the
/// attachment preview is still pending; the host prepares pixels off the
/// draw loop, then completes with [applyLoaded]. Ready attachments open
/// synchronously.
final class MediaViewerState {
  MediaViewerState._({
    required this.attachment,
    required this.title,
    required this.loading,
    this.error,
  });

  /// Opens a viewer, deferring when pixels are not ready yet.
  factory MediaViewerState.open(MediaAttachment attachment) {
    final title =
        attachment.sourceLabel ?? 'Image #${attachment.displayNumber}';
    if (attachment.preview.isPending) {
      return MediaViewerState._(
        attachment: attachment,
        title: title,
        loading: true,
      );
    }
    if (attachment.preview.status == AttachmentPreviewStatus.ready) {
      return MediaViewerState._(
        attachment: attachment,
        title: title,
        loading: false,
      );
    }
    return MediaViewerState._(
      attachment: attachment,
      title: title,
      loading: false,
      error:
          attachment.preview.error ?? 'Preview unavailable for this media.',
    );
  }

  final MediaAttachment attachment;
  final String title;
  bool loading;
  String? error;

  bool get showingPixels =>
      !loading &&
      error == null &&
      attachment.preview.status == AttachmentPreviewStatus.ready;

  /// Completes a deferred open once preparation finished.
  void applyLoaded() {
    loading = false;
    if (attachment.preview.status != AttachmentPreviewStatus.ready) {
      error =
          attachment.preview.error ?? 'Preview unavailable for this media.';
    } else {
      error = null;
    }
  }
}
