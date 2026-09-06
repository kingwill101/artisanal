import 'dart:io' as io;

import 'package:artisanal/editor_core.dart';
import 'package:artisanal/markdown.dart' as md;
import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

import '../../../example/tui/examples/media-composer/main.dart' as composer;

tui.KeyMsg _ctrl(int rune) => tui.KeyMsg(
  tui.Key(tui.KeyType.runes, runes: [rune], ctrl: true),
);

tui.KeyMsg _enter() => tui.KeyMsg(tui.Key(tui.KeyType.enter));

void main() {
  group('pasted file paths', () {
    test('recognizes plain, quoted, and file:// paths', () {
      expect(extractPastedFilePaths('/tmp/shot.png'), ['/tmp/shot.png']);
      expect(
        extractPastedFilePaths("'/tmp/my photo.jpg'"),
        ['/tmp/my photo.jpg'],
      );
      expect(
        extractPastedFilePaths('"C:/pics/shot.png"'),
        ['C:/pics/shot.png'],
      );
      expect(
        extractPastedFilePaths('file:///tmp/shot.png'),
        ['/tmp/shot.png'],
      );
    });

    test('decodes percent-escaped file URLs', () {
      expect(
        extractPastedFilePaths('file:///tmp/my%20photo.png'),
        ['/tmp/my photo.png'],
      );
    });

    test('unescapes shell-escaped posix paths only', () {
      expect(
        extractPastedFilePaths(r'/tmp/my\ photo.png'),
        ['/tmp/my photo.png'],
      );
      expect(
        extractPastedFilePaths(r'/tmp/paren\(1\).png'),
        ['/tmp/paren(1).png'],
      );
      // Windows backslashes are separators, not escapes.
      expect(
        extractPastedFilePaths(r'C:\pics\shot.png'),
        [r'C:\pics\shot.png'],
      );
    });

    test('normalizes windows spellings', () {
      expect(
        extractPastedFilePaths(r'C:\pics\shot.png'),
        [r'C:\pics\shot.png'],
      );
      expect(
        extractPastedFilePaths(r'\\server\share\shot.png'),
        [r'\\server\share\shot.png'],
      );
      expect(
        extractPastedFilePaths(r'\\?\C:\pics\shot.png'),
        [r'C:\pics\shot.png'],
      );
      expect(
        extractPastedFilePaths(r'\\?\UNC\server\share\s.png'),
        [r'\\server\share\s.png'],
      );
    });

    test('ignores prose and deduplicates', () {
      expect(extractPastedFilePaths('just some words'), isEmpty);
      expect(extractPastedFilePaths(''), isEmpty);
      expect(extractPastedFilePaths('   '), isEmpty);
      expect(
        extractPastedFilePaths('/tmp/a.png\n/tmp/a.png'),
        ['/tmp/a.png'],
      );
    });

    test('handles mixed multi-line payloads line by line', () {
      expect(
        extractPastedFilePaths('see this\n/tmp/a.png\nlooks good'),
        ['/tmp/a.png'],
      );
      expect(
        extractPastedFilePaths('/tmp/a.png\n/tmp/b.gif'),
        ['/tmp/a.png', '/tmp/b.gif'],
      );
    });

    test('accepts relative paths with extensions', () {
      expect(extractPastedFilePaths('assets/shot.png'), ['assets/shot.png']);
      expect(extractPastedFilePaths('shot.png'), ['shot.png']);
    });

    test('decoder probe follows package:image, not a hand list', () {
      expect(isImagePath('/tmp/SHOT.JPG'), isTrue);
      expect(isImagePath('/tmp/photo.heic'), isFalse);
      expect(isImagePath('/tmp/vector.svg'), isFalse);
      expect(isImagePath('/tmp/noext'), isFalse);
      final partitioned = partitionImagePaths(['/tmp/a.png', '/tmp/b.txt']);
      expect(partitioned.images, ['/tmp/a.png']);
      expect(partitioned.other, ['/tmp/b.txt']);
    });

    test('byte probe validates pasted content', () {
      expect(isDecodableImageBytes([]), isFalse);
      // Full PNG signature + IHDR chunk header.
      expect(
        isDecodableImageBytes(const [
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // signature
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00,
        ]),
        isTrue,
      );
      expect(isDecodableImageBytes(const [0x00, 0x01, 0x02]), isFalse);
    });
  });
  group('inline elements', () {
    test('creates, hit-tests, and filters by kind', () {
      final store = InlineElementStore();
      final image = store.create(kind: inlineElementImage, startOffset: 0, endOffset: 10);
      store.create(kind: inlineElementPaste, startOffset: 12, endOffset: 20);
      expect(store.elementAt(5)?.id, image);
      expect(store.elementAt(10), isNull); // end-exclusive
      expect(store.elementAtOfKind(5, inlineElementPaste), isNull);
      expect(store.ofKind(inlineElementImage), hasLength(1));
      expect(store.liveIds, contains(image));
    });

    test('right-edge lookup finds chips at the cursor edge', () {
      final store = InlineElementStore();
      final id = store.create(kind: inlineElementImage, startOffset: 0, endOffset: 10);
      expect(store.elementEndingAtOfKind(10, inlineElementImage)?.id, id);
      expect(store.elementEndingAtOfKind(9, inlineElementImage), isNull);
    });

    test('edits shift ranges and drop covered chips', () {
      final store = InlineElementStore();
      final chip = store.create(kind: inlineElementImage, startOffset: 4, endOffset: 8);
      store.applyInsertion(offset: 0, length: 2);
      expect(store.get(chip)!.startOffset, 6);
      store.applyDeletion(startOffset: 0, endOffset: 20);
      expect(store.get(chip), isNull);
    });

    test('ranges update preserving identity', () {
      final store = InlineElementStore();
      final id = store.create(kind: inlineElementImage, startOffset: 0, endOffset: 4);
      expect(store.updateRange(id: id, startOffset: 2, endOffset: 6), isTrue);
      expect(store.get(id)!.startOffset, 2);
      expect(store.updateRange(id: 999, startOffset: 0, endOffset: 1), isFalse);
    });

    test('reconcile drops orphaned sidecar records', () {
      final records = <int, String>{1: 'a', 2: 'b'};
      final removed = reconcileExternalRecords(records, {2});
      expect(removed, ['a']);
      expect(records.keys, [2]);
    });
  });

  group('media attachments', () {
    test('preview transitions pending to ready', () {
      final attachment = MediaAttachment(
        elementId: 1,
        displayNumber: 1,
        mimeType: 'image/png',
      );
      expect(attachment.preview.isPending, isTrue);
      expect(attachment.chipText, '[Image #1]');
      attachment.preview.markReady(payload: [1, 2, 3], width: 8, height: 6);
      expect(attachment.preview.payload, [1, 2, 3]);
      expect(imageChipText(2), '[Image #2]');
    });

    test('release frees source bytes only', () {
      final attachment = MediaAttachment(
        elementId: 1,
        displayNumber: 1,
        mimeType: 'image/png',
        sourceBytes: [9],
      );
      attachment.preview.markReady(payload: [9], width: 1, height: 1);
      attachment.releaseSourceBytes();
      expect(attachment.sourceBytes, isNull);
      expect(attachment.preview.payload, [9]);
    });

    test('affordance matrix prefers fallback without a protocol', () {
      expect(
        resolveMediaAffordance(protocolSupported: true),
        MediaAffordance.imageOverlay,
      );
      expect(
        resolveMediaAffordance(protocolSupported: false),
        MediaAffordance.textFallback,
      );
      expect(
        resolveMediaAffordance(protocolSupported: true, forceTextFallback: true),
        MediaAffordance.textFallback,
      );
    });

    test('viewer defers while pending and completes on load', () {
      final attachment = MediaAttachment(
        elementId: 1,
        displayNumber: 3,
        mimeType: 'image/png',
        sourceLabel: 'shot.png',
      );
      final viewer = MediaViewerState.open(attachment);
      expect(viewer.loading, isTrue);
      expect(viewer.title, 'shot.png');
      attachment.preview.markReady(payload: [1], width: 2, height: 2);
      viewer.applyLoaded();
      expect(viewer.showingPixels, isTrue);
    });

    test('viewer surfaces preview errors', () {
      final attachment = MediaAttachment(
        elementId: 1,
        displayNumber: 1,
        mimeType: 'image/png',
      )..preview.markFailed('decode error');
      final viewer = MediaViewerState.open(attachment);
      expect(viewer.error, 'decode error');
      expect(viewer.showingPixels, isFalse);
    });
  });

  group('media composer example', () {
    test('attach, preview, open viewer, submit survivors', () async {
      var model = composer.MediaComposerModel.initial();

      var (next, cmd) = model.update(_ctrl(0x76)); // ctrl+v: attach
      model = next as composer.MediaComposerModel;
      expect(model.elements.ofKind(inlineElementImage), hasLength(1));
      expect(model.composer.value, contains('[Image #1]'));
      expect(cmd, isNotNull); // deferred preparation tick

      // Preparation completes off the draw loop.
      final elementId = model.elements.ofKind(inlineElementImage).single.id;
      (next, _) = model.update(composer.ImagePreparedMsg(elementId));
      model = next as composer.MediaComposerModel;
      expect(
        model.attachments.values.single.preview.status,
        AttachmentPreviewStatus.ready,
      );

      // Cursor rests on the chip: preview line shows.
      expect(model.view(), contains('Preview:'));

      // Enter on the chip opens the viewer instead of a newline.
      (next, _) = model.update(_enter());
      model = next as composer.MediaComposerModel;
      expect(model.viewer, isNotNull);
      expect(model.view(), contains('demo-image-1.png'));
      expect(model.view(), contains('▀')); // real halfblock pixels
      expect(model.composer.value.contains('\n'), isFalse);

      // The open modal captures input; Esc closes it first.
      (next, _) = model.update(
        tui.KeyMsg(tui.Key(tui.KeyType.escape)),
      );
      model = next as composer.MediaComposerModel;
      expect(model.viewer, isNull);

      // Submit reconciles and lists the survivor.
      (next, _) = model.update(_ctrl(0x74));
      model = next as composer.MediaComposerModel;
      expect(model.submitted.single, contains('[attached:'));
      expect(model.elements.isEmpty, isTrue);
    });

    test('deleting chip text drops the attachment', () {
      var model = composer.MediaComposerModel.initial();
      var (next, _) = model.update(_ctrl(0x76));
      model = next as composer.MediaComposerModel;
      expect(model.attachments, hasLength(1));
      model.composer.setText('');
      (next, _) = model.update(_ctrl(0x74));
      model = next as composer.MediaComposerModel;
      expect(model.attachments, isEmpty);
    });

    test('forced fallback shows text instead of pixels', () {      var model = composer.MediaComposerModel.initial()
        ..forceTextFallback = true;
      var (next, _) = model.update(_ctrl(0x76));
      model = next as composer.MediaComposerModel;
      (next, _) = model.update(_enter());
      model = next as composer.MediaComposerModel;
      expect(model.viewer, isNotNull);
      expect(model.view(), contains('[Open '));
      expect(model.view(), isNot(contains('▀')));
    });

    test('pasted image paths auto-attach; other text pastes through', () async {      final temp = io.Directory.systemTemp.createTempSync('media_paste_');
      try {
        final file = io.File('${temp.path}/shot.png')
          ..writeAsBytesSync([1, 2, 3]);
        var model = composer.MediaComposerModel.initial();

        var (next, _) = model.update(tui.PasteMsg(file.path));
        model = next as composer.MediaComposerModel;
        expect(model.elements.ofKind(inlineElementImage), hasLength(1));
        final attachment = model.attachments.values.single;
        expect(attachment.sourceLabel, 'shot.png');
        expect(attachment.mimeType, 'image/png');
        expect(model.composer.value, contains('[Image #1]'));

        (next, _) = model.update(const tui.PasteMsg('just words'));
        model = next as composer.MediaComposerModel;
        expect(model.composer.value, contains('just words'));
        expect(model.elements.ofKind(inlineElementImage), hasLength(1));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
    test('protocol override cycles and labels', () {
      var model = composer.MediaComposerModel.initial();
      // CI has no terminal markers: auto falls back to halfblock.
      expect(model.paintProtocol.name, 'halfblock');
      var (next, _) = model.update(_ctrl(0x70)); // ctrl+p
      model = next as composer.MediaComposerModel;
      expect(model.protocolOverride, isNotNull);
      expect(model.view(), contains('Paint protocol:'));
      // Full cycle returns to default.
      for (var i = 0; i < 4; i++) {
        (next, _) = model.update(_ctrl(0x70));
        model = next as composer.MediaComposerModel;
      }
      expect(model.protocolOverride, isNull);
      expect(model.paintProtocol.name, 'halfblock');
    });

    test('Kitty viewer reserves its full image height inside the modal', () {
      var model = composer.MediaComposerModel.initial()
        ..width = 80
        ..height = 32
        ..protocolOverride = md.ImageProtocol.kitty;
      var (next, _) = model.update(_ctrl(0x76));
      model = next as composer.MediaComposerModel;
      final elementId = model.elements.ofKind(inlineElementImage).single.id;
      (next, _) = model.update(composer.ImagePreparedMsg(elementId));
      model = next as composer.MediaComposerModel;
      (next, _) = model.update(_enter());
      model = next as composer.MediaComposerModel;

      final view = model.view();
      final imageStart = view.indexOf('\x1b_G');
      final footer = view.indexOf('kitty [ctrl+p protocol]');

      expect(imageStart, isNonNegative);
      expect(footer, greaterThan(imageStart));
      expect(
        '\n'.allMatches(view.substring(imageStart, footer)).length,
        greaterThanOrEqualTo(20),
        reason: 'The 20-row Kitty placement must end before modal footer.',
      );
    });

    test('viewer closes on q as well as escape', () {
      var model = composer.MediaComposerModel.initial();
      var (next, _) = model.update(_ctrl(0x76));
      model = next as composer.MediaComposerModel;
      (next, _) = model.update(_enter());
      model = next as composer.MediaComposerModel;
      expect(model.viewer, isNotNull);
      (next, _) = model.update(
        tui.KeyMsg(tui.Key(tui.KeyType.runes, runes: [0x71])),
      );
      model = next as composer.MediaComposerModel;
      expect(model.viewer, isNull);
    });

    test('marker-looking pasted text cannot hijack elements', () {
      var model = composer.MediaComposerModel.initial();
      var (next, _) = model.update(_ctrl(0x76)); // chip [0, 10)
      model = next as composer.MediaComposerModel;
      final before = model.elements.all().single;
      (next, _) = model.update(const tui.PasteMsg('[Image #1] fake'));
      model = next as composer.MediaComposerModel;
      // Pasted text is just text: the live element keeps its range.
      expect(model.elements.all(), hasLength(1));
      final after = model.elements.all().single;
      expect(after.startOffset, before.startOffset);
      expect(after.endOffset, before.endOffset);
      expect(model.composer.value, contains('[Image #1] fake'));
    });

    test('typing inside a chip destroys it', () {
      var model = composer.MediaComposerModel.initial();
      var (next, _) = model.update(_ctrl(0x76));
      model = next as composer.MediaComposerModel;
      expect(model.attachments, hasLength(1));
      model.composer.setCursor(0, 5); // strictly inside [0, 10)
      (next, _) = model.update(
        tui.KeyMsg(tui.Key(tui.KeyType.runes, runes: [0x58])),
      );
      model = next as composer.MediaComposerModel;
      expect(model.elements.isEmpty, isTrue);
      expect(model.attachments, isEmpty);
      expect(model.view(), contains('removed (chip edited)'));
    });

    test('attaching inside a chip is refused, not nested', () {
      var model = composer.MediaComposerModel.initial();
      var (next, _) = model.update(_ctrl(0x76));
      model = next as composer.MediaComposerModel;
      model.composer.setCursor(0, 5);
      (next, _) = model.update(_ctrl(0x76));
      model = next as composer.MediaComposerModel;
      expect(model.elements.all(), hasLength(1));
      expect(model.attachments, hasLength(1));
      expect(model.view(), contains('Cannot nest chips'));
    });

    test('attachments cap at ten per prompt', () {
      var model = composer.MediaComposerModel.initial();
      for (var i = 0; i < 10; i++) {
        final (next, _) = model.update(_ctrl(0x76));
        model = next as composer.MediaComposerModel;
      }
      expect(model.attachments, hasLength(10));
      final (next, _) = model.update(_ctrl(0x76));
      model = next as composer.MediaComposerModel;
      expect(model.attachments, hasLength(10));
      expect(model.view(), contains('Image limit reached'));
    });
  });
}
