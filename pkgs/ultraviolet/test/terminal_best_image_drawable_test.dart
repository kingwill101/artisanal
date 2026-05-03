import 'dart:io' as io;

import 'package:ultraviolet/src/uv/uv.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

void main() {
  group('Terminal.bestImageDrawable', () {
    test('prefers kitty, then iTerm2, then sixel', () {
      final term = Terminal(output: io.stdout, env: const []);
      final image = img.Image(width: 1, height: 1);

      term.capabilities
        ..hasKittyGraphics = true
        ..hasITerm2 = true
        ..hasSixel = true;
      expect(
        Terminal.bestImageDrawable(image, capabilities: term.capabilities),
        isA<KittyImageDrawable>(),
      );

      term.capabilities
        ..hasKittyGraphics = false
        ..hasITerm2 = true
        ..hasSixel = true;
      expect(
        Terminal.bestImageDrawable(image, capabilities: term.capabilities),
        isA<ITerm2ImageDrawable>(),
      );

      term.capabilities
        ..hasKittyGraphics = false
        ..hasITerm2 = false
        ..hasSixel = true;
      expect(
        Terminal.bestImageDrawable(image, capabilities: term.capabilities),
        isA<SixelImageDrawable>(),
      );
    });

    test(
      'falls back to HalfBlockImageDrawable when no protocol is supported',
      () {
        final term = Terminal(output: io.stdout, env: const []);
        final image = img.Image(width: 1, height: 1);

        term.capabilities
          ..hasKittyGraphics = false
          ..hasITerm2 = false
          ..hasSixel = false;

        expect(
          Terminal.bestImageDrawable(
            image,
            capabilities: term.capabilities,
            columns: 10,
            rows: 4,
          ),
          isA<HalfBlockImageDrawable>(),
        );
      },
    );

    test('Kitty drawable can clear a stable image id before display', () {
      final image = img.Image(width: 1, height: 1);
      image.setPixelRgba(0, 0, 255, 0, 0, 255);
      final canvas = Canvas(2, 3);

      KittyImageDrawable(
        image,
        id: 42,
        columns: 2,
        rows: 3,
        clearBeforeDraw: true,
      ).draw(canvas, canvas.bounds());

      expect(canvas.cellAt(0, 0)?.width, 2);
      expect(canvas.cellAt(1, 0)?.isZero, isTrue);
      expect(canvas.cellAt(0, 1)?.isZero, isTrue);
      expect(canvas.cellAt(1, 1)?.isZero, isTrue);
      expect(canvas.cellAt(0, 2)?.isZero, isTrue);
      expect(canvas.cellAt(1, 2)?.isZero, isTrue);

      final rendered = canvas.render();
      expect(rendered, startsWith('\x1b_Ga=d,d=I,i=42,q=2\x1b\\'));
      expect(rendered, contains('\x1b_Ga=T,f=100,i=42,c=2,r=3,C=1,q=2'));
    });
  });
}
