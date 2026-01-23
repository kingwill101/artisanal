import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import 'key_binding.dart';

/// Pagination rendering type.
enum PaginationType {
  /// Arabic numerals: "1/10"
  arabic,

  /// Dots: "●○○○○"
  dots,
}

/// Key bindings for paginator navigation.
class PaginatorKeyMap implements KeyMap {
  PaginatorKeyMap({KeyBinding? prevPage, KeyBinding? nextPage})
    : prevPage =
          prevPage ??
          KeyBinding.withHelp(['pgup', 'left', 'h'], '←/pgup', 'prev page'),
      nextPage =
          nextPage ??
          KeyBinding.withHelp(['pgdown', 'right', 'l'], '→/pgdn', 'next page');

  /// Key binding for previous page.
  final KeyBinding prevPage;

  /// Key binding for next page.
  final KeyBinding nextPage;

  @override
  List<KeyBinding> shortHelp() => [prevPage, nextPage];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [prevPage, nextPage],
  ];
}

/// A paginator widget for handling pagination state and rendering.
///
/// The paginator manages page state and provides rendering for pagination
/// indicators. It can display pages as Arabic numerals ("1/10") or dots ("●○○").
///
/// ## Example
///
/// ```dart
/// class ListModel implements Model {
///   final List<String> items;
///   final PaginatorModel paginator;
///
///   ListModel({required this.items, PaginatorModel? paginator})
///       : paginator = paginator ?? PaginatorModel(perPage: 10)
///           ..setTotalPages(items.length);
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     final (newPaginator, cmd) = paginator.update(msg);
///     return (
///       ListModel(items: items, paginator: newPaginator as PaginatorModel),
///       cmd,
///     );
///   }
///
///   @override
///   String view() {
///     final (start, end) = paginator.getSliceBounds(items.length);
///     final visibleItems = items.sublist(start, end);
///     return '''
/// ${visibleItems.map((i) => '• $i').join('\n')}
///
/// ${paginator.view()}
/// ''';
///   }
/// }
/// ```
class PaginatorModel extends ViewComponent {
  /// Creates a new paginator model.
  PaginatorModel({
    this.type = PaginationType.arabic,
    this.page = 0,
    this.perPage = 1,
    this.totalPages = 1,
    this.activeDot = '•',
    this.inactiveDot = '○',
    this.arabicFormat = '%d/%d',
    PaginatorKeyMap? keyMap,
  }) : keyMap = keyMap ?? PaginatorKeyMap();

  /// The type of pagination display.
  final PaginationType type;

  /// The current page (0-indexed).
  final int page;

  /// Number of items per page.
  final int perPage;

  /// Total number of pages.
  final int totalPages;

  /// Character for the active page dot.
  final String activeDot;

  /// Character for inactive page dots.
  final String inactiveDot;

  /// Format string for Arabic pagination (e.g., "%d/%d").
  final String arabicFormat;

  /// Key bindings for navigation.
  final PaginatorKeyMap keyMap;

  /// Creates a copy with the given fields replaced.
  PaginatorModel copyWith({
    PaginationType? type,
    int? page,
    int? perPage,
    int? totalPages,
    String? activeDot,
    String? inactiveDot,
    String? arabicFormat,
    PaginatorKeyMap? keyMap,
  }) {
    return PaginatorModel(
      type: type ?? this.type,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      totalPages: totalPages ?? this.totalPages,
      activeDot: activeDot ?? this.activeDot,
      inactiveDot: inactiveDot ?? this.inactiveDot,
      arabicFormat: arabicFormat ?? this.arabicFormat,
      keyMap: keyMap ?? this.keyMap,
    );
  }

  /// Calculates the total number of pages from the given item count.
  ///
  /// This also updates the totalPages field and returns the new paginator.
  PaginatorModel setTotalPages(int items) {
    if (items < 1) return this;
    var n = items ~/ perPage;
    if (items % perPage > 0) n++;
    return copyWith(totalPages: n);
  }

  /// Returns the number of items on the current page.
  int itemsOnPage(int totalItems) {
    if (totalItems < 1) return 0;
    final (start, end) = getSliceBounds(totalItems);
    return end - start;
  }

  /// Returns the slice bounds for the current page.
  ///
  /// Use this to slice your item list:
  /// ```dart
  /// final (start, end) = paginator.getSliceBounds(items.length);
  /// final visibleItems = items.sublist(start, end);
  /// ```
  (int start, int end) getSliceBounds(int length) {
    final start = page * perPage;
    final end = (page * perPage + perPage).clamp(0, length);
    return (start, end);
  }

  /// Navigates to the previous page.
  PaginatorModel prevPage() {
    if (page > 0) {
      return copyWith(page: page - 1);
    }
    return this;
  }

  /// Navigates to the next page.
  PaginatorModel nextPage() {
    if (!onLastPage) {
      return copyWith(page: page + 1);
    }
    return this;
  }

  /// Navigates to a specific page.
  PaginatorModel goToPage(int p) {
    return copyWith(page: p.clamp(0, totalPages - 1));
  }

  /// Whether we're on the last page.
  bool get onLastPage => page >= totalPages - 1;

  /// Whether we're on the first page.
  bool get onFirstPage => page <= 0;

  @override
  Cmd? init() => null;

  @override
  (PaginatorModel, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) {
      if (msg.matches([keyMap.nextPage])) {
        return (nextPage(), null);
      }
      if (msg.matches([keyMap.prevPage])) {
        return (prevPage(), null);
      }
    }
    return (this, null);
  }

  @override
  String view() {
    switch (type) {
      case PaginationType.dots:
        return _dotsView();
      case PaginationType.arabic:
        return _arabicView();
    }
  }

  String _dotsView() {
    final buffer = StringBuffer();
    for (var i = 0; i < totalPages; i++) {
      buffer.write(i == page ? activeDot : inactiveDot);
    }
    return buffer.toString();
  }

  String _arabicView() {
    // Replace %d placeholders with page values
    var result = arabicFormat;
    result = result.replaceFirst('%d', '${page + 1}');
    result = result.replaceFirst('%d', '$totalPages');
    return result;
  }
}
