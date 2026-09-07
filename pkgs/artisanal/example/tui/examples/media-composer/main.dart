/// Media-composer example: image chips, cursor preview, and a modal viewer.
///
/// Mirrors the reference workflow for inline media in a prompt composer:
/// attached images live as typed chip elements (`[Image #N]`) in the buffer,
/// the chip under the cursor drives a preview line, `enter` on a chip opens
/// a modal viewer (checked *before* the textarea sees Enter, which otherwise
/// inserts a newline), capability gating falls back to text, deleting chip
/// text drops the attachment, and submit reconciles survivors.
///
/// Keys:
/// - type normally; `enter` inserts a newline (or opens the viewer on a chip)
/// - `ctrl+v` attaches an image (chip + deferred preview preparation)
/// - pasting or dropping image file paths auto-attaches them (other text
///   pastes normally; terminal file drops arrive as bracketed pastes)
/// - `ctrl+t` submits (reconciles attachments, lists survivors)
/// - `ctrl+f` toggles forced text fallback (capability gating demo)
/// - `ctrl+p` cycles the paint protocol (auto → kitty → iterm2 → sixel →
///   halfblock) so any terminal can be driven by hand
/// - `esc` closes the viewer; `ctrl+c` / `q` (when empty) quits
///
/// Runs full-screen (alt-screen) with bracketed paste enabled.
library;

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:artisanal/bubbles.dart' as b;
import 'package:artisanal/editor_core.dart' as core;
import 'package:artisanal/markdown.dart' as md;
import 'package:artisanal/tui.dart' as tui;
import 'package:characters/characters.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Stand-in image bytes (a valid 2x2 PNG) for the deferred preview
/// pipeline. Production code decodes real files here; the lifecycle is
/// identical.
const _demoPngBytes = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
  0x08, 0x02, 0x00, 0x00, 0x00, 0xFD, 0xD4, 0x9A, 0x73, 0x00, 0x00, 0x00,
  0x16, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF9, 0xCF, 0xC0, 0xC0,
  0xF8, 0x9F, 0x81, 0x85, 0x91, 0xE1, 0xFF, 0x7F, 0x06, 0x06, 0x00, 0x1D,
  0x55, 0x04, 0x07, 0x27, 0xCB, 0xE4, 0xCA, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

/// Fires when deferred preview preparation finishes for [elementId].
/// Public so tests and hosts can drive the pipeline deterministically.
final class ImagePreparedMsg extends tui.Msg {
  const ImagePreparedMsg(this.elementId);
  final int elementId;
}

final class MediaComposerModel implements tui.Model {
  MediaComposerModel({required this.composer}) {
    composer.focus();
  }

  factory MediaComposerModel.initial() {
    final composer = b.TextAreaModel(
      prompt: '❯ ',
      placeholder: 'Compose… (ctrl+v attaches; drop image files here)',
      showLineNumbers: false,
    );
    return MediaComposerModel(composer: composer);
  }

  b.TextAreaModel composer;
  final core.InlineElementStore elements = core.InlineElementStore();
  final Map<int, core.MediaAttachment> attachments = <int, core.MediaAttachment>{};
  final core.DisplayNumberAssigner numbers = core.DisplayNumberAssigner();
  final List<String> submitted = <String>[];
  core.MediaViewerState? viewer;
  bool forceTextFallback = false;
  md.ImageProtocol? protocolOverride;
  String? status;
  String? lastKey;
  int width = 80;
  int height = 24;

  /// Maximum chips per prompt; pastes beyond it stay text.
  static const maxImages = 10;

  /// Chip under the cursor (on-chip wins; right edge counts too).
  core.InlineElement? get hoveredImage {
    final offset = composer.cursorOffset;
    return elements.elementAtOfKind(offset, core.inlineElementImage) ??
        elements.elementEndingAtOfKind(offset, core.inlineElementImage);
  }

  core.MediaAffordance get affordance => core.resolveMediaAffordance(
    protocolSupported: true,
    forceTextFallback: forceTextFallback,
  );

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(:final key):
        lastKey = _describeKey(key);
        if (viewer != null) {
          // Esc closes; plain `q` too, since lone-Esc delivery varies
          // across terminals and multiplexers.
          if (key.type == tui.KeyType.escape || _isPlainRune(key, 0x71)) {
            viewer = null;
            status = 'Viewer closed.';
          }
          return (this, null);
        }
        if (_isCtrlRune(key, 0x63)) return (this, tui.Cmd.quit());
        if (_isCtrlRune(key, 0x76)) return (this, _attachImage());
        if (_isCtrlRune(key, 0x74) || _isCtrlRune(key, 0x73)) {
          _submit();
          return (this, null);
        }
        if (_isCtrlRune(key, 0x66)) {
          forceTextFallback = !forceTextFallback;
          status = forceTextFallback
              ? 'Text fallback forced (minimal-mode demo).'
              : 'Image overlay affordance restored.';
          return (this, null);
        }
        if (_isCtrlRune(key, 0x70)) {
          protocolOverride = _nextProtocol(protocolOverride);
          status = 'Paint protocol: ${_protocolLabel()}.';
          return (this, null);
        }
        // Element interaction first: Enter on an image chip previews it.
        // Enter elsewhere falls through and inserts a newline.
        if (key.type == tui.KeyType.enter && _openViewerAtCursor()) {
          return (this, null);
        }
        if (_isPlainRune(key, 0x71) && composer.value.isEmpty) {
          return (this, tui.Cmd.quit());
        }
      case tui.InterruptMsg():
        return (this, tui.Cmd.quit());
      case b.TextAreaPasteMsg(:final content):
      case tui.PasteMsg(:final content):
      case tui.PasteTextMsg(:final content):
        // Pastes and terminal file drops share one pipeline: image paths
        // become chips, anything else falls through to the textarea.
        return _handlePaste(content);
      case ImagePreparedMsg(:final elementId):
        _finishPreparation(elementId);
        return (this, null);
      case tui.WindowSizeMsg(width: final w, height: final h):
        width = w;
        height = h;
        composer.setWidth((w - 4).clamp(20, w));
        composer.setHeight((h - 12).clamp(4, h));
    }
    final before = composer.value;
    final (next, cmd) = composer.update(msg);
    composer = next;
    _trackEdit(before, composer.value);
    return (this, cmd);
  }

  /// Graphemes of [text] for diffing in document coordinates.
  static List<String> _graphemes(String text) =>
      text.characters.toList(growable: false);

  /// Minimal contiguous change between grapheme lists.
  static ({int start, int oldEnd, int newEnd}) _diffRegion(
    List<String> before,
    List<String> after,
  ) {
    var start = 0;
    while (start < before.length &&
        start < after.length &&
        before[start] == after[start]) {
      start++;
    }
    var oldEnd = before.length;
    var newEnd = after.length;
    while (oldEnd > start &&
        newEnd > start &&
        before[oldEnd - 1] == after[newEnd - 1]) {
      oldEnd--;
      newEnd--;
    }
    return (start: start, oldEnd: oldEnd, newEnd: newEnd);
  }

  /// Maps element ranges through one document change. Pure insertions
  /// strictly inside a chip destroy it (its text was edited); anything
  /// else follows the shared shift/drop rule. Marker-looking pasted text
  /// can never hijack an element: ranges track positions, not text.
  void _trackEdit(String before, String after) {
    if (before == after) return;
    final diff = _diffRegion(_graphemes(before), _graphemes(after));
    if (diff.start == diff.oldEnd) {
      for (final element in elements.all().toList(growable: false)) {
        if (element.startOffset < diff.start &&
            diff.start < element.endOffset) {
          elements.delete(element.id);
          final dropped = attachments.remove(element.id);
          if (dropped != null) {
            status =
                'Image #${dropped.displayNumber} removed (chip edited).';
          }
        }
      }
    }
    elements.applyReplacement(
      startOffset: diff.start,
      endOffset: diff.oldEnd,
      insertLength: diff.newEnd - diff.start,
    );
  }

  /// Inserts [text] at the cursor and tracks element ranges through the
  /// change. Returns the inserted span for chip binding.
  ({int start, int end}) _insertTracked(String text) {
    final before = composer.value;
    composer.insertString(text);
    final diff = _diffRegion(
      _graphemes(before),
      _graphemes(composer.value),
    );
    _trackEdit(before, composer.value);
    return (start: diff.start, end: diff.newEnd);
  }

  /// Attaches an image chip at the cursor with deferred preview prep.
  /// [filePath] labels file-backed attaches (bytes + dimensions decoded
  /// for real; mime derived via package:mime); without one the chip uses
  /// demo bytes. Refuses when capped or when the cursor sits strictly
  /// inside another chip — chips are atomic and cannot nest.
  tui.Cmd? _attachImage({
    String? filePath,
    List<int>? bytes,
  }) {
    if (attachments.length >= maxImages) {
      status = 'Image limit reached (max $maxImages).';
      return null;
    }
    final cursor = composer.cursorOffset;
    final inside = elements.elementAt(cursor);
    if (inside != null &&
        inside.startOffset < cursor &&
        cursor < inside.endOffset) {
      status = 'Cannot nest chips: move outside the current chip.';
      return null;
    }
    var payload = bytes;
    if (filePath != null && payload == null) {
      try {
        payload = io.File(filePath).readAsBytesSync();
      } catch (_) {
        status = 'Could not read $filePath.';
        return null;
      }
    }
    payload ??= _demoPngBytes;
    // Real dimensions from the bytes; undecodable files keep null dims
    // and fail visibly at preparation time instead of lying here.
    // (decodeImage throws on garbage — never returns null for it.)
    ({int width, int height})? dims;
    try {
      final decoded = img.decodeImage(Uint8List.fromList(payload));
      if (decoded != null) dims = (width: decoded.width, height: decoded.height);
    } catch (_) {}
    final number = numbers.assign();
    final chip = core.imageChipText(number);
    // Diff-located: no text search, so marker-looking pasted text can
    // never hijack the new element's range.
    final span = _insertTracked(chip);
    final id = elements.create(
      kind: core.inlineElementImage,
      startOffset: span.start,
      endOffset: span.end,
    );
    final label = filePath == null ? null : p.basename(filePath);
    attachments[id] = core.MediaAttachment(
      elementId: id,
      displayNumber: number,
      mimeType: filePath == null
          ? 'image/png'
          : lookupMimeType(filePath) ?? 'application/octet-stream',
      dimensions: dims,
      sourceLabel: label ?? 'demo-image-$number.png',
      sourceBytes: payload,
    );
    status = 'Image #$number attached; preparing preview…';
    // Deferred preparation off the draw loop; the tick completes it.
    return tui.Cmd.tick(
      const Duration(milliseconds: 300),
      (_) => ImagePreparedMsg(id),
    );
  }

  /// Shared paste/drop pipeline: image file paths become chips, anything
  /// else falls through to the textarea untouched.
  (tui.Model, tui.Cmd?) _handlePaste(String content) {
    final lines = content.split('\n');
    final textLines = <String>[];
    final cmds = <tui.Cmd>[];
    for (final line in lines) {
      final candidates = core.extractPastedFilePaths(line);
      final wholeLine =
          candidates.length == 1 && candidates.single == line.trim();
      final path = wholeLine ? candidates.single : null;
      if (path != null && _isExistingImage(path)) {
        _flushPasteText(textLines);
        final cmd = _attachImage(filePath: path);
        if (cmd != null) cmds.add(cmd);
        continue;
      }
      textLines.add(line);
    }
    _flushPasteText(textLines, trailingNewline: content.endsWith('\n'));
    if (cmds.isEmpty) return (this, null);
    return (this, tui.Cmd.batch(cmds));
  }

  void _flushPasteText(List<String> lines, {bool trailingNewline = false}) {
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }
    if (lines.isEmpty) return;
    var text = lines.join('\n');
    if (trailingNewline) text += '\n';
    _insertTracked(text);
    lines.clear();
  }

  bool _isExistingImage(String path) {
    try {
      return core.isImagePath(path) && io.File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  void _finishPreparation(int elementId) {
    final attachment = attachments[elementId];
    if (attachment == null) return;
    attachment.preview.markReady(
      payload: attachment.sourceBytes ?? _demoPngBytes,
      width: attachment.dimensions?.width ?? 0,
      height: attachment.dimensions?.height ?? 0,
    );
    status = 'Preview ready for Image #${attachment.displayNumber}.';
    viewer?.applyLoaded();
  }

  /// Active paint protocol: manual override, else detected, else the
  /// universal halfblock fallback.
  md.ImageProtocol get paintProtocol {
    final override = protocolOverride;
    if (override != null) return override;
    final detected = md.detectImageProtocol();
    return detected == md.ImageProtocol.none
        ? md.ImageProtocol.halfblock
        : detected;
  }

  String _protocolLabel() {
    final override = protocolOverride;
    if (override != null) return '${override.name} (manual)';
    return '${paintProtocol.name} (auto)';
  }

  static md.ImageProtocol? _nextProtocol(md.ImageProtocol? current) {
    const order = [
      md.ImageProtocol.halfblock,
      md.ImageProtocol.kitty,
      md.ImageProtocol.iterm2,
      md.ImageProtocol.sixel,
    ];
    if (current == null) return order.first;
    final next = order.indexOf(current) + 1;
    return next >= order.length ? null : order[next];
  }
  /// Painting uses the detected protocol with halfblock fallback; forced
  /// text mode shows metadata instead of pixels. Returns whether a viewer
  /// opened (consuming Enter either way when on a chip).
  bool _openViewerAtCursor() {
    final element = hoveredImage;
    if (element == null) return false;
    final attachment = attachments[element.id];
    if (attachment == null) return false;
    viewer = core.MediaViewerState.open(attachment);
    status = viewer!.loading
        ? 'Loading image…'
        : 'Viewer open: ${viewer!.title}.';
    return true;
  }

  void _submit() {
    final orphans = core.reconcileExternalRecords(
      attachments,
      elements.liveIds,
    );
    if (orphans.isNotEmpty) {
      status = '${orphans.length} orphaned attachment(s) cleaned up.';
    }
    final expanded = composer.value;
    if (expanded.isEmpty && attachments.isEmpty) {
      status ??= 'Nothing to submit.';
      return;
    }
    final buffer = StringBuffer(expanded);
    final survivors = attachments.values.toList(growable: false)
      ..sort((a, b) => a.displayNumber.compareTo(b.displayNumber));
    for (final attachment in survivors) {
      buffer.writeln();
      buffer.writeln(
        '[attached: ${attachment.sourceLabel ?? attachment.chipText} '
        '${attachment.mimeType} '
        '${attachment.dimensions?.width}x${attachment.dimensions?.height}]',
      );
    }
    submitted.add(buffer.toString());
    composer.setText('');
    elements.clear();
    attachments.clear();
    numbers.reset();
    status = 'Submitted with ${survivors.length} attachment(s).';
  }

  static bool _isCtrlRune(tui.Key key, int rune) {
    if (key.type != tui.KeyType.runes ||
        key.runes.length != 1 ||
        key.alt ||
        key.meta) {
      return false;
    }
    final code = key.runes.first;
    return (key.ctrl && code == rune) || code == rune - 0x60;
  }

  static bool _isPlainRune(tui.Key key, int rune) =>
      !key.ctrl &&
      !key.alt &&
      key.type == tui.KeyType.runes &&
      key.runes.length == 1 &&
      key.runes.first == rune;

  static String _describeKey(tui.Key key) {
    final runes = key.runes
        .map((rune) => '0x${rune.toRadixString(16).padLeft(2, '0')}')
        .join(' ');
    final mods = [
      if (key.ctrl) 'ctrl',
      if (key.alt) 'alt',
      if (key.shift) 'shift',
      if (key.meta) 'meta',
    ].join('+');
    return '${key.type.name} [$runes]${mods.isEmpty ? '' : ' $mods'}';
  }

  @override
  String view() {
    final buffer = StringBuffer();
    buffer.writeln('Media composer demo');
    buffer.writeln(composer.view());
    final hovered = hoveredImage;
    if (hovered != null) {
      final attachment = attachments[hovered.id];
      if (attachment != null) {
        buffer.writeln(
          'Preview: ${attachment.sourceLabel ?? attachment.chipText} '
          '(${_dimsLabel(attachment.dimensions)}, ${attachment.mimeType}) '
          '[${attachment.preview.status.name}]',
        );
      }
    }
    if (elements.ofKind(core.inlineElementImage).isNotEmpty) {
      buffer.writeln(
        'Chips: ${elements.ofKind(core.inlineElementImage).length} tracked.',
      );
    }
    buffer.writeln(
      'Affordance: ${affordance.name} '
      '(ctrl+f toggles text fallback).',
    );
    if (status != null) buffer.writeln(status);
    if (lastKey != null) buffer.writeln('Last key: $lastKey');
    if (submitted.isNotEmpty) {
      buffer.writeln('--- submitted (${submitted.length}) ---');
      buffer.writeln(submitted.last);
    }
    buffer.writeln('[ctrl+v attach] [enter preview] [ctrl+t submit] [q quit]');
    final base = buffer.toString();
    final active = viewer;
    if (active == null) return base;
    return b.renderModal(
      base,
      _viewerBody(active),
      chrome: b.ModalChrome(title: active.title, footer: [_viewerFooter()]),
      screenW: width,
      screenH: height,
    );
  }

  /// Viewer body: real pixels via the image subsystem (detected protocol,
  /// halfblock fallback), or the text fallback in forced text mode.
  List<String> _viewerBody(core.MediaViewerState viewer) {
    final attachment = viewer.attachment;
    if (forceTextFallback) {
      return [
        '${_dimsLabel(attachment.dimensions)} ${attachment.mimeType}',
        '[Open ${attachment.sourceLabel ?? attachment.chipText}]',
      ];
    }
    if (viewer.loading) return ['loading…'];
    if (viewer.error != null) return [viewer.error!];
    final bytes =
        attachment.preview.payload ?? attachment.sourceBytes ?? _demoPngBytes;
    img.Image? decoded;
    try {
      decoded = img.decodeImage(Uint8List.fromList(bytes));
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) return ['Could not decode image bytes.'];
    final protocol = paintProtocol;
    final columns = (width - 10).clamp(20, 60);
    final rows = (height - 12).clamp(6, 20);
    final ansi = md.renderImageToAnsi(
      decoded,
      protocol,
      columns: columns,
      rows: rows,
    );
    if (ansi == null || ansi.isEmpty) return ['Could not render image.'];
    final lines = ansi.split('\n');
    // Cell-based fallbacks contain one string per visual row. Terminal image
    // protocols instead encode the whole columns × rows placement in one
    // control sequence, so reserve the remaining rows explicitly. Without
    // these rows the modal places its footer directly beneath the control
    // sequence and the terminal image paints over the footer and border.
    if (protocol != md.ImageProtocol.halfblock && lines.length < rows) {
      lines.addAll(List<String>.filled(rows - lines.length, ''));
    }
    return lines;
  }

  String _dimsLabel(({int width, int height})? dims) =>
      dims == null ? 'size unknown' : '${dims.width}x${dims.height}';

  String _viewerFooter() =>
      '${paintProtocol.name} [ctrl+p protocol] [esc/q close]';
}

Future<void> main() async {
  await tui.runProgram(
    MediaComposerModel.initial(),
    // Full alt-screen mode with bracketed paste: terminal file drops
    // arrive as paste messages on the same pipeline as path pastes.
    options: const tui.ProgramOptions(bracketedPaste: true),
  );
}
