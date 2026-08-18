/// Public metadata for Artisanal's built-in prompt and display components.
///
/// Import this registry when an application wants to build its own catalog,
/// documentation page, command palette, or help screen without depending on
/// the example preview renderer.
///
/// {@category Core}
library;

/// A catalog entry for one reusable Artisanal widget or display component.
class WidgetCatalogEntry {
  /// Creates a catalog entry.
  const WidgetCatalogEntry({
    required this.name,
    required this.category,
    required this.description,
    required this.id,
  });

  /// Stable identifier used by the preview renderer.
  final String id;

  /// Public widget or component name.
  final String name;

  /// High-level grouping shown in the catalog.
  final String category;

  /// Short explanation of what the widget does.
  final String description;
}

/// Every built-in Artisanal Bubble and display component in catalog order.
const List<WidgetCatalogEntry> widgetCatalogEntries = [
  WidgetCatalogEntry(
    id: 'cursor',
    name: 'CursorModel',
    category: 'Primitives',
    description: 'Blinking cursor state shared by text-oriented Bubbles.',
  ),
  WidgetCatalogEntry(
    id: 'key-binding',
    name: 'KeyBinding',
    category: 'Primitives',
    description: 'Declarative keys and help text for keyboard interaction.',
  ),
  WidgetCatalogEntry(
    id: 'text-input',
    name: 'TextInputModel',
    category: 'Input',
    description: 'Single-line text editing with cursor and selection support.',
  ),
  WidgetCatalogEntry(
    id: 'text-area',
    name: 'TextAreaModel',
    category: 'Input',
    description: 'Multi-line text editing with wrapping and line numbers.',
  ),
  WidgetCatalogEntry(
    id: 'password',
    name: 'PasswordModel',
    category: 'Input',
    description: 'Masked password entry with validation hooks.',
  ),
  WidgetCatalogEntry(
    id: 'confirm',
    name: 'ConfirmModel',
    category: 'Input',
    description: 'Yes/no confirmation with keyboard navigation.',
  ),
  WidgetCatalogEntry(
    id: 'number-input',
    name: 'NumberInputModel',
    category: 'Input',
    description: 'Numeric input with bounded arrow-key increments.',
  ),
  WidgetCatalogEntry(
    id: 'anticipate',
    name: 'AnticipateModel',
    category: 'Input',
    description: 'Autocomplete input with filtered suggestions.',
  ),
  WidgetCatalogEntry(
    id: 'suggest',
    name: 'SuggestModel',
    category: 'Input',
    description: 'Prefix-matched input with a navigable suggestion list.',
  ),
  WidgetCatalogEntry(
    id: 'select',
    name: 'SelectModel',
    category: 'Selection',
    description: 'Single-choice list with cursor navigation.',
  ),
  WidgetCatalogEntry(
    id: 'multi-select',
    name: 'MultiSelectModel',
    category: 'Selection',
    description: 'Toggle several choices before confirming.',
  ),
  WidgetCatalogEntry(
    id: 'search',
    name: 'SearchModel',
    category: 'Selection',
    description: 'Fuzzy-filtered single-choice selection.',
  ),
  WidgetCatalogEntry(
    id: 'multi-search',
    name: 'MultiSearchModel',
    category: 'Selection',
    description: 'Fuzzy-filtered multi-choice selection.',
  ),
  WidgetCatalogEntry(
    id: 'data-table',
    name: 'DataTableModel',
    category: 'Selection',
    description: 'Searchable table with row selection and pagination.',
  ),
  WidgetCatalogEntry(
    id: 'file-picker',
    name: 'FilePickerModel',
    category: 'Selection',
    description: 'Directory browser with file, permission, and size styling.',
  ),
  WidgetCatalogEntry(
    id: 'wizard',
    name: 'WizardModel',
    category: 'Flow',
    description: 'Sequential multi-step form flow.',
  ),
  WidgetCatalogEntry(
    id: 'spinner',
    name: 'SpinnerModel',
    category: 'Feedback',
    description: 'Animated spinner frames for background work.',
  ),
  WidgetCatalogEntry(
    id: 'progress-model',
    name: 'ProgressModel',
    category: 'Feedback',
    description: 'Animated progress with spring-damped motion.',
  ),
  WidgetCatalogEntry(
    id: 'timer',
    name: 'TimerModel',
    category: 'Feedback',
    description: 'Countdown timer with start, stop, and reset controls.',
  ),
  WidgetCatalogEntry(
    id: 'stopwatch',
    name: 'StopwatchModel',
    category: 'Feedback',
    description: 'Elapsed-time stopwatch with tick updates.',
  ),
  WidgetCatalogEntry(
    id: 'paginator',
    name: 'PaginatorModel',
    category: 'Navigation',
    description: 'Arabic, dot, and roman pagination indicators.',
  ),
  WidgetCatalogEntry(
    id: 'viewport',
    name: 'ViewportModel',
    category: 'Navigation',
    description: 'Scrollable content viewport with optional gutters.',
  ),
  WidgetCatalogEntry(
    id: 'viewport-scroll-pane',
    name: 'ViewportScrollPane',
    category: 'Navigation',
    description: 'Viewport wrapper with a draggable scrollbar.',
  ),
  WidgetCatalogEntry(
    id: 'help',
    name: 'HelpModel',
    category: 'Navigation',
    description: 'Compact or expanded key-binding help display.',
  ),
  WidgetCatalogEntry(
    id: 'list',
    name: 'ListModel',
    category: 'Data',
    description: 'Filterable list with status, pagination, and help bars.',
  ),
  WidgetCatalogEntry(
    id: 'table',
    name: 'TableModel',
    category: 'Data',
    description: 'Scrollable table with column sizing and row navigation.',
  ),
  WidgetCatalogEntry(
    id: 'sequence-diagram',
    name: 'SequenceDiagramModel',
    category: 'Data',
    description: 'Mermaid sequence diagram rendered inside a TUI view.',
  ),
  WidgetCatalogEntry(
    id: 'text',
    name: 'Text',
    category: 'Display',
    description: 'Smallest display component for plain text.',
  ),
  WidgetCatalogEntry(
    id: 'composite',
    name: 'CompositeComponent',
    category: 'Display',
    description: 'Composes display components without adding separators.',
  ),
  WidgetCatalogEntry(
    id: 'column-component',
    name: 'ColumnComponent',
    category: 'Display',
    description: 'Stacks display components vertically.',
  ),
  WidgetCatalogEntry(
    id: 'row-component',
    name: 'RowComponent',
    category: 'Display',
    description: 'Joins display components horizontally.',
  ),
  WidgetCatalogEntry(
    id: 'key-value',
    name: 'KeyValue',
    category: 'Display',
    description: 'Dot-filled key/value row for compact status output.',
  ),
  WidgetCatalogEntry(
    id: 'styled-text',
    name: 'StyledText',
    category: 'Display',
    description: 'Semantic info, success, warning, error, and heading text.',
  ),
  WidgetCatalogEntry(
    id: 'rule',
    name: 'Rule',
    category: 'Display',
    description: 'Terminal-width separator with optional centered label.',
  ),
  WidgetCatalogEntry(
    id: 'alert',
    name: 'AlertComponent',
    category: 'Display',
    description: 'Compact semantic alert with status prefix.',
  ),
  WidgetCatalogEntry(
    id: 'styled-block',
    name: 'StyledBlockComponent',
    category: 'Display',
    description: 'Symfony-style block for important messages.',
  ),
  WidgetCatalogEntry(
    id: 'box',
    name: 'Box',
    category: 'Display',
    description: 'Bordered content box with title and padding.',
  ),
  WidgetCatalogEntry(
    id: 'panel',
    name: 'PanelComponent',
    category: 'Display',
    description: 'Aligned bordered panel for dashboard content.',
  ),
  WidgetCatalogEntry(
    id: 'columns',
    name: 'ColumnsComponent',
    category: 'Display',
    description: 'Responsive multi-column item layout.',
  ),
  WidgetCatalogEntry(
    id: 'bullet-list',
    name: 'BulletList',
    category: 'Display',
    description: 'Bulleted or numbered collection display.',
  ),
  WidgetCatalogEntry(
    id: 'definition-list',
    name: 'DefinitionListComponent',
    category: 'Display',
    description: 'Aligned term and definition pairs.',
  ),
  WidgetCatalogEntry(
    id: 'table-component',
    name: 'TableComponent',
    category: 'Display',
    description: 'Static bordered table with per-cell style callbacks.',
  ),
  WidgetCatalogEntry(
    id: 'horizontal-table',
    name: 'HorizontalTableComponent',
    category: 'Display',
    description: 'Row-as-headers table for detail views.',
  ),
  WidgetCatalogEntry(
    id: 'markdown',
    name: 'Markdown',
    category: 'Display',
    description: 'Terminal markdown renderer with adaptive syntax styling.',
  ),
  WidgetCatalogEntry(
    id: 'link',
    name: 'LinkComponent',
    category: 'Display',
    description: 'OSC-8 terminal hyperlink component.',
  ),
  WidgetCatalogEntry(
    id: 'task',
    name: 'TaskComponent',
    category: 'Display',
    description: 'Static Laravel-style task status row.',
  ),
  WidgetCatalogEntry(
    id: 'progress-bar',
    name: 'ProgressBarComponent',
    category: 'Display',
    description: 'Static progress bar for one-shot output.',
  ),
  WidgetCatalogEntry(
    id: 'progress',
    name: 'ProgressBar',
    category: 'Display',
    description: 'Compact static progress indicator.',
  ),
  WidgetCatalogEntry(
    id: 'spinner-frame',
    name: 'SpinnerFrame',
    category: 'Display',
    description: 'One styled frame from a spinner animation.',
  ),
  WidgetCatalogEntry(
    id: 'tree',
    name: 'TreeComponent',
    category: 'Display',
    description: 'Hierarchical data rendered with branch characters.',
  ),
  WidgetCatalogEntry(
    id: 'two-column-detail',
    name: 'TwoColumnDetailComponent',
    category: 'Display',
    description: 'Dot-filled key/value detail row.',
  ),
  WidgetCatalogEntry(
    id: 'titled-block',
    name: 'TitledBlockComponent',
    category: 'Display',
    description: 'Styled title followed by indented message lines.',
  ),
  WidgetCatalogEntry(
    id: 'comment',
    name: 'CommentComponent',
    category: 'Display',
    description: 'Dimmed comment output with a conventional prefix.',
  ),
  WidgetCatalogEntry(
    id: 'exception',
    name: 'ExceptionComponent',
    category: 'Display',
    description: 'Readable exception and optional stack trace rendering.',
  ),
];

/// The categories represented by [widgetCatalogEntries].
const List<String> widgetCatalogCategories = [
  'Primitives',
  'Input',
  'Selection',
  'Flow',
  'Feedback',
  'Navigation',
  'Data',
  'Display',
];

/// Returns catalog entries matching an optional category and fuzzy text query.
///
/// Matching is case-insensitive and checks the stable ID, public name,
/// category, and description. An empty query returns every entry in the
/// selected category.
List<WidgetCatalogEntry> filterWidgetCatalog({
  String? category,
  String query = '',
}) {
  final normalizedCategory = category?.trim().toLowerCase();
  final normalizedQuery = query.trim().toLowerCase();
  return widgetCatalogEntries
      .where((entry) {
        final categoryMatches =
            normalizedCategory == null ||
            normalizedCategory.isEmpty ||
            entry.category.toLowerCase() == normalizedCategory;
        if (!categoryMatches) return false;
        if (normalizedQuery.isEmpty) return true;
        final haystack =
            '${entry.id} ${entry.name} ${entry.category} '
                    '${entry.description}'
                .toLowerCase();
        return haystack.contains(normalizedQuery);
      })
      .toList(growable: false);
}
