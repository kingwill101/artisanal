import 'package:artisanal/src/tui/bubbles/paginator.dart';
import 'package:artisanal/src/tui/component.dart';
import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('PaginatorModel', () {
    group('New', () {
      test('creates paginator with default values', () {
        final paginator = PaginatorModel();
        expect(paginator.page, 0);
        expect(paginator.perPage, 1);
        expect(paginator.totalPages, 1);
        expect(paginator.type, PaginationType.arabic);
      });

      test('creates paginator with custom values', () {
        final paginator = PaginatorModel(
          page: 2,
          perPage: 10,
          totalPages: 5,
          type: PaginationType.dots,
        );
        expect(paginator.page, 2);
        expect(paginator.perPage, 10);
        expect(paginator.totalPages, 5);
        expect(paginator.type, PaginationType.dots);
      });

      test('creates paginator with custom dot characters', () {
        final paginator = PaginatorModel(activeDot: '●', inactiveDot: '○');
        expect(paginator.activeDot, '●');
        expect(paginator.inactiveDot, '○');
      });
    });

    group('SetTotalPages', () {
      test('calculates pages from items', () {
        final paginator = PaginatorModel(perPage: 10);
        final updated = paginator.setTotalPages(25);
        expect(updated.totalPages, 3);
      });

      test('handles exact division', () {
        final paginator = PaginatorModel(perPage: 10);
        final updated = paginator.setTotalPages(20);
        expect(updated.totalPages, 2);
      });

      test('handles single page', () {
        final paginator = PaginatorModel(perPage: 10);
        final updated = paginator.setTotalPages(5);
        expect(updated.totalPages, 1);
      });

      test('handles zero items', () {
        final paginator = PaginatorModel(perPage: 10);
        final updated = paginator.setTotalPages(0);
        // Should not update for zero items
        expect(updated.totalPages, paginator.totalPages);
      });

      test('handles negative items', () {
        final paginator = PaginatorModel(perPage: 10);
        final updated = paginator.setTotalPages(-5);
        // Should not update for negative items
        expect(updated.totalPages, paginator.totalPages);
      });
    });

    group('PrevPage', () {
      test('decrements page', () {
        final paginator = PaginatorModel(page: 2, totalPages: 5);
        final updated = paginator.prevPage();
        expect(updated.page, 1);
      });

      test('stops at first page', () {
        final paginator = PaginatorModel(page: 0, totalPages: 5);
        final updated = paginator.prevPage();
        expect(updated.page, 0);
      });

      test('moves from page 1 to page 0', () {
        final paginator = PaginatorModel(page: 1, totalPages: 5);
        final updated = paginator.prevPage();
        expect(updated.page, 0);
      });
    });

    group('NextPage', () {
      test('increments page', () {
        final paginator = PaginatorModel(page: 0, totalPages: 5);
        final updated = paginator.nextPage();
        expect(updated.page, 1);
      });

      test('stops at last page', () {
        final paginator = PaginatorModel(page: 4, totalPages: 5);
        final updated = paginator.nextPage();
        expect(updated.page, 4);
      });

      test('allows moving to last page', () {
        final paginator = PaginatorModel(page: 3, totalPages: 5);
        final updated = paginator.nextPage();
        expect(updated.page, 4);
      });
    });

    group('OnLastPage', () {
      test('returns true when on last page', () {
        final paginator = PaginatorModel(page: 4, totalPages: 5);
        expect(paginator.onLastPage, isTrue);
      });

      test('returns false when not on last page', () {
        final paginator = PaginatorModel(page: 0, totalPages: 5);
        expect(paginator.onLastPage, isFalse);
      });

      test('returns true for single page', () {
        final paginator = PaginatorModel(page: 0, totalPages: 1);
        expect(paginator.onLastPage, isTrue);
      });
    });

    group('OnFirstPage', () {
      test('returns true when on first page', () {
        final paginator = PaginatorModel(page: 0, totalPages: 5);
        expect(paginator.onFirstPage, isTrue);
      });

      test('returns false when not on first page', () {
        final paginator = PaginatorModel(page: 2, totalPages: 5);
        expect(paginator.onFirstPage, isFalse);
      });
    });

    group('GoToPage', () {
      test('goes to specified page', () {
        final paginator = PaginatorModel(page: 0, totalPages: 5);
        final updated = paginator.goToPage(3);
        expect(updated.page, 3);
      });

      test('clamps to last page when exceeding', () {
        final paginator = PaginatorModel(page: 0, totalPages: 5);
        final updated = paginator.goToPage(10);
        expect(updated.page, 4);
      });

      test('clamps to first page for negative', () {
        final paginator = PaginatorModel(page: 2, totalPages: 5);
        final updated = paginator.goToPage(-5);
        expect(updated.page, 0);
      });
    });

    group('ItemsOnPage', () {
      test('returns full page items for middle pages', () {
        final paginator = PaginatorModel(page: 0, perPage: 10, totalPages: 3);
        final updated = paginator.setTotalPages(25);
        expect(updated.itemsOnPage(25), 10);
      });

      test('returns remaining items for last page', () {
        final paginator = PaginatorModel(page: 2, perPage: 10, totalPages: 3);
        expect(paginator.itemsOnPage(25), 5);
      });

      test('returns 0 for empty list', () {
        final paginator = PaginatorModel(page: 0, perPage: 10);
        expect(paginator.itemsOnPage(0), 0);
      });

      test('returns correct items when fewer than perPage', () {
        final paginator = PaginatorModel(page: 0, perPage: 10, totalPages: 1);
        expect(paginator.itemsOnPage(5), 5);
      });
    });

    group('GetSliceBounds', () {
      test('returns correct bounds for first page', () {
        final paginator = PaginatorModel(page: 0, perPage: 10);
        final (start, end) = paginator.getSliceBounds(25);
        expect(start, 0);
        expect(end, 10);
      });

      test('returns correct bounds for middle page', () {
        final paginator = PaginatorModel(page: 1, perPage: 10);
        final (start, end) = paginator.getSliceBounds(25);
        expect(start, 10);
        expect(end, 20);
      });

      test('returns correct bounds for last page', () {
        final paginator = PaginatorModel(page: 2, perPage: 10);
        final (start, end) = paginator.getSliceBounds(25);
        expect(start, 20);
        expect(end, 25);
      });

      test('clamps end to list length', () {
        final paginator = PaginatorModel(page: 0, perPage: 10);
        final (start, end) = paginator.getSliceBounds(5);
        expect(start, 0);
        expect(end, 5);
      });
    });

    group('View', () {
      test('renders arabic format', () {
        final paginator = PaginatorModel(
          page: 0,
          totalPages: 5,
          type: PaginationType.arabic,
        );
        expect(paginator.view(), '1/5');
      });

      test('renders custom arabic format', () {
        final paginator = PaginatorModel(
          page: 2,
          totalPages: 10,
          type: PaginationType.arabic,
          arabicFormat: 'Page %d of %d',
        );
        expect(paginator.view(), 'Page 3 of 10');
      });

      test('renders dots format', () {
        final paginator = PaginatorModel(
          page: 0,
          totalPages: 5,
          type: PaginationType.dots,
        );
        expect(paginator.view(), '•○○○○');
      });

      test('renders dots with custom characters', () {
        final paginator = PaginatorModel(
          page: 2,
          totalPages: 5,
          type: PaginationType.dots,
          activeDot: '●',
          inactiveDot: '○',
        );
        expect(paginator.view(), '○○●○○');
      });

      test('renders single dot for one page', () {
        final paginator = PaginatorModel(
          page: 0,
          totalPages: 1,
          type: PaginationType.dots,
        );
        expect(paginator.view(), '•');
      });
    });

    group('CopyWith', () {
      test('creates copy with changed values', () {
        final original = PaginatorModel(page: 0, totalPages: 5);
        final copy = original.copyWith(page: 3);
        expect(copy.page, 3);
        expect(copy.totalPages, 5);
        expect(original.page, 0);
      });

      test('preserves unchanged values', () {
        final original = PaginatorModel(
          page: 0,
          totalPages: 5,
          perPage: 10,
          type: PaginationType.dots,
        );
        final copy = original.copyWith(page: 2);
        expect(copy.totalPages, 5);
        expect(copy.perPage, 10);
        expect(copy.type, PaginationType.dots);
      });
    });

    group('Init', () {
      test('returns null command', () {
        final paginator = PaginatorModel();
        expect(paginator.init(), isNull);
      });
    });

    test('is a ViewComponent and updates via base type', () {
      final paginator = PaginatorModel(totalPages: 3);
      ViewComponent model = paginator;
      final (updated, _) = model.update(const KeyMsg(Key(KeyType.right)));
      expect(updated, isA<PaginatorModel>());
    });
  });

  group('PaginatorKeyMap', () {
    test('creates with default bindings', () {
      final keyMap = PaginatorKeyMap();
      expect(keyMap.prevPage.keys, isNotEmpty);
      expect(keyMap.nextPage.keys, isNotEmpty);
    });

    test('shortHelp returns bindings', () {
      final keyMap = PaginatorKeyMap();
      final help = keyMap.shortHelp();
      expect(help, hasLength(2));
    });

    test('fullHelp returns grouped bindings', () {
      final keyMap = PaginatorKeyMap();
      final help = keyMap.fullHelp();
      expect(help, isNotEmpty);
      expect(help.first, hasLength(2));
    });
  });
}
