import 'dart:io' as dart_io;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/bubbles.dart' as bubbles;

/// Returns the public registry used by this example's preview renderer.
List<WidgetCatalogEntry> buildWidgetCatalog() => widgetCatalogEntries;

/// IDs used by the static preset showcase.
const showcaseWidgetIds = [
  'text-input',
  'password',
  'confirm',
  'number-input',
  'select',
  'multi-select',
  'search',
  'suggest',
  'data-table',
  'file-picker',
  'box',
  'panel',
  'table-component',
  'progress-bar',
  'tree',
];

/// Renders a non-interactive preview for a catalog entry.
String renderWidgetPreview(
  WidgetCatalogEntry entry, {
  ComponentTheme theme = ComponentTheme.dark,
  int terminalWidth = 72,
  ColorProfile colorProfile = ColorProfile.trueColor,
}) {
  final config = bubbles.RenderConfig(
    terminalWidth: terminalWidth,
    colorProfile: colorProfile,
  );

  final preview = switch (entry.id) {
    'cursor' => _view(
      bubbles.CursorModel(mode: bubbles.CursorMode.static, char: '█'),
    ),
    'key-binding' => _keyBindingPreview(),
    'text-input' => _view(
      bubbles.TextInputModel(
        prompt: '› ',
        placeholder: 'Type a command',
        styles: theme.textInputStyles(config),
      )..value = 'deploy --env ',
    ),
    'text-area' => _view(
      bubbles.TextAreaModel(
        prompt: '│ ',
        placeholder: 'Write a release note',
        width: terminalWidth - 4,
        height: 4,
      ),
    ),
    'password' => _view(
      bubbles.PasswordModel(
        prompt: 'Password: ',
        styles: theme.passwordStyles(config),
      ),
    ),
    'confirm' => _view(
      bubbles.ConfirmModel(
        prompt: 'Deploy now?',
        styles: theme.confirmStyles(config),
      ),
    ),
    'number-input' => _view(
      bubbles.NumberInputModel(
        prompt: 'Workers: ',
        defaultValue: 4,
        min: 1,
        max: 12,
        hint: 'Use ↑/↓ to adjust',
        styles: theme.numberInputStyles(config),
      ),
    ),
    'anticipate' => _view(
      bubbles.AnticipateModel(
        prompt: 'Branch: ',
        suggestions: const ['main', 'staging', 'production'],
        defaultValue: 'st',
        promptStyle: theme.promptStyle(config),
        textStyle: theme.textStyle(config),
        placeholderStyle: theme.mutedStyle(config),
        suggestionStyle: theme.textStyle(config),
        selectedSuggestionStyle: theme.promptStyle(config),
      ),
    ),
    'suggest' => _view(
      bubbles.SuggestModel(
        prompt: 'Language: ',
        options: const ['Dart', 'Go', 'Rust', 'TypeScript'],
        defaultValue: 'Da',
        styles: theme.suggestStyles(config),
      ),
    ),
    'select' => _view(
      bubbles.SelectModel<String>(
        title: 'Choose an environment',
        items: const ['staging', 'production', 'local'],
        styles: theme.selectStyles(config),
      ),
    ),
    'multi-select' => _view(
      bubbles.MultiSelectModel<String>(
        title: 'Select services',
        items: const ['api', 'worker', 'web'],
        initialSelected: {0, 2},
        styles: theme.multiSelectStyles(config),
      ),
    ),
    'search' => _view(
      bubbles.SearchModel<String>(
        title: 'Find a package',
        items: const ['artisanal', 'ultraviolet', 'artisanal_widgets'],
        styles: theme.searchStyles(config),
      ),
    ),
    'multi-search' => _view(
      bubbles.MultiSearchModel<String>(
        title: 'Choose packages',
        items: const ['artisanal', 'ultraviolet', 'artisanal_widgets'],
        styles: theme.searchStyles(config),
      ),
    ),
    'data-table' => _view(
      bubbles.DataTableModel<String>(
        title: 'Deployments',
        columns: [
          bubbles.Column(title: 'Service', width: 16),
          bubbles.Column(title: 'State', width: 12),
        ],
        items: const ['api', 'worker'],
        rowBuilder: (item) => [item, 'ready'],
        styles: theme.dataTableStyles(config),
      ),
    ),
    'file-picker' => _view(
      bubbles.FilePickerModel(
        currentDirectory: dart_io.Directory.current.path,
        height: 4,
        styles: theme.filePickerStyles(config),
      ),
    ),
    'wizard' => _view(
      bubbles.WizardModel(
        title: 'New project',
        steps: [
          bubbles.WizardStep.textInput(key: 'name', prompt: 'Project name: '),
          bubbles.WizardStep.confirm(key: 'ready', prompt: 'Create it?'),
        ],
      ),
    ),
    'spinner' => _view(bubbles.SpinnerModel(spinner: bubbles.Spinners.line)),
    'progress-model' => _view(
      bubbles.ProgressModel(targetPercent: 0.68, percentShown: 0.68),
    ),
    'timer' => _view(bubbles.TimerModel(timeout: const Duration(seconds: 42))),
    'stopwatch' => _view(bubbles.StopwatchModel()),
    'paginator' => _view(
      bubbles.PaginatorModel(
        type: bubbles.PaginationType.dots,
        page: 1,
        totalPages: 4,
      ),
    ),
    'viewport' => _view(
      bubbles.ViewportModel(
        width: terminalWidth,
        height: 3,
        lines: const [
          'Recent builds',
          'Build #104 passed',
          'Build #103 passed',
        ],
      ),
    ),
    'viewport-scroll-pane' => _view(
      bubbles.ViewportScrollPane(
        viewport: bubbles.ViewportModel(
          width: terminalWidth - 2,
          height: 3,
          lines: const ['Scrollable content', 'with a scrollbar'],
        ),
      ),
    ),
    'help' => _helpPreview(),
    'list' => _view(
      bubbles.ListModel(
        title: 'Packages',
        width: terminalWidth,
        height: 5,
        items: [
          bubbles.StringItem('artisanal'),
          bubbles.StringItem('ultraviolet'),
        ],
      ),
    ),
    'table' => _view(
      bubbles.TableModel(
        columns: [
          bubbles.Column(title: 'Name', width: 14),
          bubbles.Column(title: 'Status', width: 10),
        ],
        rows: const [
          ['api', 'ready'],
          ['worker', 'idle'],
        ],
        width: terminalWidth,
        height: 4,
      ),
    ),
    'sequence-diagram' => _view(
      bubbles.SequenceDiagramModel(
        width: terminalWidth,
        mermaid: '''
sequenceDiagram
  participant CLI
  participant API
  CLI->>API: deploy()
  API-->>CLI: ready
''',
      ),
    ),
    'composite' => _render(
      bubbles.CompositeComponent(
        children: const [
          bubbles.Text('First component'),
          bubbles.Text('Second component'),
        ],
      ),
      config,
    ),
    'column-component' => _render(
      bubbles.ColumnComponent(
        children: const [bubbles.Text('Top'), bubbles.Text('Bottom')],
        spacing: 1,
      ),
      config,
    ),
    'row-component' => _render(
      bubbles.RowComponent(
        children: const [bubbles.Text('Left'), bubbles.Text('Right')],
        separator: ' · ',
      ),
      config,
    ),
    'key-value' => _render(
      bubbles.KeyValue(
        key: 'Status',
        value: 'ready',
        width: terminalWidth,
        renderConfig: config,
      ),
      config,
    ),
    'text' => _render(const bubbles.Text('A tiny display component.'), config),
    'styled-text' => _render(
      bubbles.StyledText.heading('A semantic heading'),
      config,
    ),
    'rule' => _render(bubbles.Rule(text: 'Display components'), config),
    'alert' => _render(
      bubbles.AlertComponent(
        message: 'Everything is ready.',
        type: bubbles.AlertType.success,
        renderConfig: config,
      ),
      config,
    ),
    'styled-block' => _render(
      bubbles.StyledBlockComponent(
        message: 'A larger message block.',
        blockStyle: bubbles.BlockStyleType.info,
        renderConfig: config,
      ),
      config,
    ),
    'markdown' => _render(
      bubbles.Markdown(
        '# Markdown\n\n**Bold** and `code` in a terminal component.',
        renderConfig: config,
      ),
      config,
    ),
    'link' => _render(
      bubbles.LinkComponent(
        url: 'https://artisanal.dev',
        text: 'artisanal.dev',
        renderConfig: config,
      ),
      config,
    ),
    'task' => _render(
      bubbles.TaskComponent(
        description: 'Build package',
        status: bubbles.TaskStatus.success,
        renderConfig: config,
      ),
      config,
    ),
    'box' => _render(
      bubbles.Box(
        title: 'Box',
        content: theme.textStyle(config).render('Bordered content'),
        borderStyle: bubbles.BorderStyle.rounded,
        renderConfig: config,
      ),
      config,
    ),
    'panel' => _render(
      bubbles.PanelComponent(
        title: 'Panel',
        content: 'Aligned dashboard content',
        borderStyle: theme.mutedStyle(config),
        renderConfig: config,
      ),
      config,
    ),
    'columns' => _render(
      bubbles.ColumnsComponent(
        items: const ['Build', 'Test', 'Deploy', 'Monitor'],
        columnCount: 2,
        renderConfig: config,
      ),
      config,
    ),
    'bullet-list' => _render(
      bubbles.BulletList(
        items: const ['Fast startup', 'Typed styles', 'Composable widgets'],
        renderConfig: config,
        bullet: theme.promptStyle(config).render('•'),
      ),
      config,
    ),
    'definition-list' => _render(
      bubbles.DefinitionListComponent(
        items: const {'Version': '0.5.0', 'Renderer': 'Ultraviolet'},
        renderConfig: config,
      ),
      config,
    ),
    'table-component' => _render(
      bubbles.TableComponent(
        headers: const ['Service', 'State'],
        rows: const [
          ['api', 'ready'],
          ['worker', 'idle'],
        ],
        renderConfig: config,
        styleFunc: (row, column, value) =>
            column == 1 ? theme.successStyle(config) : theme.textStyle(config),
      ),
      config,
    ),
    'horizontal-table' => _render(
      bubbles.HorizontalTableComponent(
        data: const {'Name': 'artisanal', 'Version': '0.5.0'},
        renderConfig: config,
      ),
      config,
    ),
    'progress-bar' => _render(
      bubbles.ProgressBarComponent(
        current: 68,
        total: 100,
        renderConfig: config,
      ),
      config,
    ),
    'progress' => _render(
      const bubbles.ProgressBar(current: 68, total: 100, width: 24),
      config,
    ),
    'spinner-frame' => _render(
      bubbles.SpinnerFrame(
        frame: '⠋',
        message: 'Working',
        renderConfig: config,
      ),
      config,
    ),
    'tree' => _render(
      bubbles.TreeComponent(
        data: const {
          'lib': {
            'src': ['console.dart', 'component_theme.dart'],
          },
          'test': ['component_theme_test.dart'],
        },
        showRoot: true,
        renderConfig: config,
      ),
      config,
    ),
    'two-column-detail' => _render(
      bubbles.TwoColumnDetailComponent(
        left: 'Status',
        right: 'Ready',
        renderConfig: config,
      ),
      config,
    ),
    'titled-block' => _render(
      bubbles.TitledBlockComponent(
        title: 'Info',
        message: 'A titled message block.',
        titleStyle: theme.infoStyle(config),
        renderConfig: config,
      ),
      config,
    ),
    'comment' => _render(
      bubbles.CommentComponent(
        text: 'This is a quiet comment.',
        renderConfig: config,
      ),
      config,
    ),
    'exception' => _render(
      bubbles.ExceptionComponent(
        exception: StateError('Preview exception'),
        renderConfig: config,
      ),
      config,
    ),
    _ => 'No preview registered for ${entry.name}.',
  };

  return colorProfile == ColorProfile.ascii
      ? Style.stripAnsi(preview)
      : preview;
}

String _view(dynamic model) => model.view().toString().trimRight();

String _render(
  bubbles.DisplayComponent component,
  bubbles.RenderConfig config,
) => component.render().trimRight();

String _keyBindingPreview() {
  final binding = bubbles.KeyBinding.withHelp(
    ['enter'],
    '↵',
    'confirm selection',
  );
  return '${binding.help.key}  ${binding.help.desc}';
}

String _helpPreview() {
  final keyMap = bubbles.KeyMap()
    ..shortHelp = [
      bubbles.KeyBinding.withHelp(['enter'], 'enter', 'select'),
      bubbles.KeyBinding.withHelp(['esc'], 'esc', 'cancel'),
    ];
  return bubbles.HelpModel().view(keyMap);
}

/// Renders one preset's visual showcase to [io].
void renderPresetShowcase(
  Console io,
  String presetName,
  ComponentTheme theme, {
  int terminalWidth = 72,
}) {
  io.componentTheme = theme;
  io.title('Artisanal ComponentTheme — $presetName');
  io.text(
    'The same built-in widgets rendered with the ${presetName.replaceAll('-', ' ')} palette.',
  );
  io.newLine();

  io.components.info(
    'Prompt widgets',
    'These are render-only snapshots of interactive Bubbles.',
  );
  for (final id in showcaseWidgetIds.take(10)) {
    final entry = buildWidgetCatalog().firstWhere((item) => item.id == id);
    io.section(entry.name);
    io.writeln(
      renderWidgetPreview(
        entry,
        theme: theme,
        terminalWidth: terminalWidth,
        colorProfile: io.renderConfig.colorProfile,
      ),
    );
  }

  io.components.info(
    'Display components',
    'The same palette carried into static CLI output.',
  );
  for (final id in showcaseWidgetIds.skip(10)) {
    final entry = buildWidgetCatalog().firstWhere((item) => item.id == id);
    io.section(entry.name);
    io.writeln(
      renderWidgetPreview(
        entry,
        theme: theme,
        terminalWidth: terminalWidth,
        colorProfile: io.renderConfig.colorProfile,
      ),
    );
  }
  io.newLine();
}

/// Captures a deterministic showcase suitable for text-based golden tests.
String renderPresetShowcaseSnapshot(
  String presetName,
  ComponentTheme theme, {
  int terminalWidth = 72,
  ColorProfile colorProfile = ColorProfile.ansi256,
}) {
  final output = StringBuffer();
  final io = Console(
    interactive: false,
    renderer: StringRenderer(colorProfile: colorProfile),
    terminalWidth: terminalWidth,
    componentTheme: theme,
    out: output.writeln,
    err: (_) {},
  );
  renderPresetShowcase(io, presetName, theme, terminalWidth: terminalWidth);
  return output
      .toString()
      .split('\n')
      .map((line) => line.trimRight())
      .join('\n')
      .trimRight();
}

/// Renders the interactive catalog menu.
Future<void> runInteractiveCatalog(
  Console io, {
  ComponentTheme theme = ComponentTheme.dark,
}) async {
  io.componentTheme = theme;
  io.title('Artisanal Widget Catalog');
  io.text('Browse a preview of every built-in Bubble and display component.');
  io.text('Type to fuzzy-search; press Esc to change the category filter.');
  io.newLine();

  var activeCategory = 'All';
  var chooseCategory = false;
  while (true) {
    if (chooseCategory) {
      final category = await io.selectChoice<String>(
        'Filter by category',
        choices: ['All', ...widgetCatalogCategories],
        defaultIndex: activeCategory == 'All'
            ? 0
            : widgetCatalogCategories.indexOf(activeCategory) + 1,
      );
      if (category == null) {
        io.newLine();
        io.comment('Catalog closed.');
        return;
      }
      activeCategory = category;
      chooseCategory = false;
    }

    final selected = await io.search<WidgetCatalogEntry>(
      'Search $activeCategory widgets',
      items: filterWidgetCatalog(
        category: activeCategory == 'All' ? null : activeCategory,
      ),
      display: (entry) => '${entry.name} — ${entry.description}',
      placeholder: 'Type a name, category, or capability...',
      noResultsText: 'No widgets match that search.',
    );
    if (selected != null) {
      io.newLine();
      io.section('${selected.name} · ${selected.category}');
      io.writeln(selected.description);
      io.writeln(
        renderWidgetPreview(
          selected,
          theme: theme,
          colorProfile: io.renderConfig.colorProfile,
        ),
      );
      io.newLine();
      chooseCategory = true;
      continue;
    }
    chooseCategory = true;
  }
}
