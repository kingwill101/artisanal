import 'package:test/test.dart';
import 'package:ultraviolet/src/uv/uv.dart';

void main() {
  group('link id codec boundaries', () {
    test('round trips ids across bit 32 and keeps generation-only changes', () {
      const slot = 7;
      final before = debugEncodeLinkId(slot: slot, generation: 4095);
      final after = debugEncodeLinkId(slot: slot, generation: 4096);

      expect(before, lessThan(1 << 32));
      expect(after, greaterThan(1 << 32));
      expect(debugDecodeLinkSlot(after), slot);
      expect(debugDecodeLinkGeneration(after), 4096);
      expect(after - before, 1 << 20);
    });

    test('round trips the maximum exactly representable link id', () {
      const maxSafeId = 0xFFFFFFFFFFFFF; // 2^52 - 1
      final id = debugEncodeLinkId(slot: (1 << 20) - 2, generation: 0xFFFFFFFF);

      expect(id, maxSafeId);
      expect(debugDecodeLinkSlot(id), (1 << 20) - 2);
      expect(debugDecodeLinkGeneration(id), 0xFFFFFFFF);
    });

    test('high-generation packed links survive clone and copyFrom', () {
      final source = debugCellWithLinkGeneration(
        const Link(url: 'https://codec-high-generation.example/source'),
        4096,
      );
      final id = source.linkId!;
      final clone = source.clone();
      final copied = Cell();
      copied.copyFrom(source);

      expect(id, greaterThan(1 << 32));
      expect(clone.linkId, id);
      expect(copied.linkId, id);
      expect(clone.packed.word3, id);
      expect(copied.packed.word3, id);
      expect(debugLinkRefCount(id), 3);

      clone.dispose();
      copied.dispose();
      source.dispose();
      expect(debugLinkRefCount(id), 0);
    });

    test(
      'stale high-generation packed identity does not alias replacement',
      () {
        final old = debugCellWithLinkGeneration(
          const Link(url: 'https://codec-stale.example/old'),
          4096,
        );
        final oldId = old.linkId!;
        final stale = old.packed;
        final slot = debugLinkSlot(oldId);
        old.dispose();

        final current = Cell(
          link: const Link(url: 'https://codec-stale.example/current'),
        );
        final currentId = current.linkId!;

        expect(debugLinkSlot(currentId), slot);
        expect(debugLinkGeneration(currentId), 4097);
        expect(currentId, isNot(oldId));
        expect(stale.word3, oldId);
        expect(stale, isNot(current.packed));
        expect(debugLinkRefCount(oldId), 0);
        current.dispose();
      },
    );

    test('released slots clear payload before generation reuse', () {
      final old = Cell(
        link: const Link(
          url: 'https://payload-cleanup.example/old',
          params: 'id=large',
        ),
      );
      final oldId = old.linkId!;
      final slot = debugLinkSlot(oldId);
      final oldGeneration = debugLinkGeneration(oldId);
      expect(
        debugLinkPayload(oldId),
        const Link(
          url: 'https://payload-cleanup.example/old',
          params: 'id=large',
        ),
      );
      old.dispose();

      expect(debugLinkRefCount(oldId), 0);
      expect(debugLinkPayload(oldId), const Link());

      final replacement = Cell(
        link: const Link(
          url: 'https://payload-cleanup.example/new',
          params: 'id=next',
        ),
      );
      expect(debugLinkSlot(replacement.linkId!), slot);
      expect(debugLinkGeneration(replacement.linkId!), oldGeneration + 1);
      replacement.dispose();
    });

    test('repeated release of a stale id is safe', () {
      final cell = Cell(
        link: const Link(url: 'https://repeated-release.example'),
      );
      final id = cell.linkId!;
      cell.dispose();
      cell.dispose();

      expect(debugLinkRefCount(id), 0);
      expect(debugLinkPayload(id), const Link());
    });

    test(
      'live clone and copy retain the payload until their final release',
      () {
        final source = Cell(
          link: const Link(
            url: 'https://payload-cleanup.example/live',
            params: 'kind=clone',
          ),
        );
        final id = source.linkId!;
        final clone = source.clone();
        final copied = Cell()..copyFrom(source);

        source.dispose();
        expect(debugLinkRefCount(id), 2);
        expect(
          debugLinkPayload(id),
          const Link(
            url: 'https://payload-cleanup.example/live',
            params: 'kind=clone',
          ),
        );

        clone.dispose();
        expect(debugLinkRefCount(id), 1);
        expect(
          debugLinkPayload(id),
          const Link(
            url: 'https://payload-cleanup.example/live',
            params: 'kind=clone',
          ),
        );

        copied.dispose();
        expect(debugLinkRefCount(id), 0);
        expect(debugLinkPayload(id), const Link());
      },
    );
  });
}
