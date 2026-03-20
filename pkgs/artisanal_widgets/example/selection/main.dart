// Cross-component selection showcase
//
// Demonstrates one SelectionArea spanning multiple selectable component types:
// SelectableText, SelectableRichText, and SelectableView.
//
// Run with: dart run example/selection/main.dart

import 'package:artisanal/app.dart' as app;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/selection.dart' as s;
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' show View;
import 'package:artisanal/widgets.dart' as w;

Future<void> main() async {
  await app.runArtisanalApp(
    app.ArtisanalApp(
      title: 'Selection Across View Demo',
      home: SelectionShowcase(),
    ),
  );
}

class SelectionShowcase extends w.StatefulWidget {
  SelectionShowcase({super.key, this.controller, this.scrollController});

  final s.SelectionController? controller;
  final w.WidgetScrollController? scrollController;

  @override
  w.State createState() => _SelectionShowcaseState();
}

class _SelectionShowcaseState extends w.State<SelectionShowcase> {
  late final w.WidgetScrollController _scrollController =
      widget.scrollController ?? w.WidgetScrollController();
  final w.WidgetScrollController _snapshotScrollController =
      w.WidgetScrollController();
  final w.TextAreaController _editorPreviewController = w.TextAreaController(
    text:
        'Editor-backed preview\n'
        'This read-only fragment follows the textarea controller.\n'
        'Dragging through it should stay in the same selection buffer.',
  );
  s.SelectionController? _ownController;
  s.SelectionController? _listeningController;
  String _selectedText = '';

  s.SelectionController get _selectionController =>
      widget.controller ?? (_ownController ??= s.SelectionController());

  @override
  void initState() {
    super.initState();
    _attachSelectionController();
  }

  @override
  runtime.Cmd? didUpdateWidget(covariant SelectionShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _detachSelectionController();
      _attachSelectionController();
    }
    return null;
  }

  @override
  void dispose() {
    _detachSelectionController();
    _editorPreviewController.dispose();
    super.dispose();
  }

  void _attachSelectionController() {
    final ctrl = _selectionController;
    _listeningController = ctrl;
    _selectedText = ctrl.getSelectedRegisteredText();
    ctrl.addListener(_handleSelectionChanged);
  }

  void _detachSelectionController() {
    _listeningController?.removeListener(_handleSelectionChanged);
    _listeningController = null;
  }

  void _handleSelectionChanged() {
    if (!mounted) return;
    setState(() {
      _selectedText = _selectionController.getSelectedRegisteredText();
    });
  }

  @override
  runtime.Cmd? handleUpdate(runtime.Msg msg) {
    if (msg is runtime.KeyMsg && msg.key.char == 'q') {
      return runtime.Cmd.quit();
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final titleStyle = theme.titleLarge.copy()..foreground(theme.onBackground);
    final sectionTitleStyle = theme.titleSmall.copy()
      ..foreground(theme.onSurface);
    final bodyStyle = theme.bodyMedium.copy()..foreground(theme.onSurface);
    final labelStyle = theme.labelSmall.copy()..foreground(theme.onBackground);
    final subtleStyle = theme.bodySmall.copy()..foreground(theme.onBackground);
  final previewText = _selectedText.isEmpty
        ? 'Drag from the title to the footer. Triple-click selects a full line.'
        : _selectedText;
    final plainSelectionStyle = Style()
      ..background(theme.primary)
      ..foreground(theme.onPrimary);
    final richSelectionStyle = Style()
      ..background(theme.warning)
      ..foreground(theme.resolvedOnWarning);
    final markdownSelectionStyle = Style()
      ..background(theme.success)
      ..foreground(theme.resolvedOnSuccess);
    final viewSelectionStyle = Style()
      ..background(theme.secondary)
      ..foreground(theme.onSecondary);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        enableHover: true,
        trackChar: ' ',
        thumbChar: ' ',
        trackUsesBackground: true,
        thumbUsesBackground: true,
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Column(
            gap: 0,
            children: [
              w.Text('Selection Across View Demo', style: titleStyle),
              w.Text(
                'One SelectionArea wraps the mixed document below. Ctrl+C copies. q quits.',
                style: labelStyle,
              ),
              _sectionCard(
                theme: theme,
                title: 'Selection snapshot (${_selectedText.length} chars)',
                child: w.SizedBox(
                  height: 4,
                  child: w.Scrollbar(
                    controller: _snapshotScrollController,
                    thickness: 1,
                    gap: 1,
                    enableHover: true,
                    trackChar: ' ',
                    thumbChar: ' ',
                    trackUsesBackground: true,
                    thumbUsesBackground: true,
                    child: w.ScrollView(
                      controller: _snapshotScrollController,
                      handleKeys: true,
                      child: w.Text(previewText, style: bodyStyle),
                    ),
                  ),
                ),
              ),
              _documentCard(
                theme: theme,
                controller: _selectionController,
                scrollController: _scrollController,
                editorPreviewController: _editorPreviewController,
                sectionTitleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                subtleStyle: subtleStyle,
                plainSelectionStyle: plainSelectionStyle,
                richSelectionStyle: richSelectionStyle,
                markdownSelectionStyle: markdownSelectionStyle,
                viewSelectionStyle: viewSelectionStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

w.Widget _documentCard({
  required w.Theme theme,
  required s.SelectionController controller,
  required w.ScrollController scrollController,
  required w.TextAreaController editorPreviewController,
  required Style sectionTitleStyle,
  required Style bodyStyle,
  required Style subtleStyle,
  required Style plainSelectionStyle,
  required Style richSelectionStyle,
  required Style markdownSelectionStyle,
  required Style viewSelectionStyle,
}) {
  return _sectionCard(
    theme: theme,
    title: 'Shared document surface',
    child: s.SelectionArea(
      controller: controller,
      scrollController: scrollController,
      child: w.Column(
        gap: 0,
        children: [
          w.Text(
            'Cross-component selection document',
            style: sectionTitleStyle.copy()..bold(),
          ).selectable(),
          w.Text(
            'Drag from this title through the footer to copy one combined '
            'buffer across component types.',
            style: bodyStyle,
          ).selectable(),
          _documentBlock(
            theme: theme,
            title: 'Plain text section',
            child: w.Text(
              'SelectableText content should merge cleanly with the sections '
              'below when you drag across the document.',
              style: bodyStyle,
            ).selectable(selectionHighlightStyle: plainSelectionStyle),
          ),
          _documentBlock(
            theme: theme,
            title: 'Rich text section',
            child: w.RichText(
              text: w.TextSpan(
                text: 'Styled spans stay visible on screen while ',
                style: bodyStyle,
                children: [
                  w.TextSpan(
                    text: 'TODO',
                    style: Style().bold().foreground(theme.warning),
                    selectionHighlightStyle: Style()
                      ..background(theme.error)
                      ..foreground(theme.onError),
                  ),
                  w.TextSpan(text: ' labels, '),
                  w.TextSpan(
                    text: 'status flags',
                    style: Style().underline().foreground(theme.primary),
                    selectionHighlightStyle: Style()
                      ..background(theme.secondary)
                      ..foreground(theme.onSecondary),
                  ),
                  w.TextSpan(text: ' and emphasis still copy as plain text.'),
                ],
              ),
            ).selectable(selectionHighlightStyle: richSelectionStyle),
          ),
          _documentBlock(
            theme: theme,
            title: 'Markdown section',
            child: w.MarkdownText(
              data:
                  '## Shared markdown\n'
                  '- bullets still join the same selection buffer\n'
                  '- inline `code` copies as plain text\n'
                  '- **bold** emphasis stays readable while dragging',
              textStyle: bodyStyle,
              maxWidth: 60,
            ).selectable(selectionHighlightStyle: markdownSelectionStyle),
          ),
          _documentBlock(
            theme: theme,
            title: 'View-backed section',
            child: View(
              content:
                  '${Style().foreground(theme.secondary).render('VIEW')} :: '
                  'Raw View() content joins the same drag selection area.',
            ).selectable(
              controller: controller,
              selectionHighlightStyle: viewSelectionStyle,
            ),
          ),
          _documentBlock(
            theme: theme,
            title: 'Editor-backed section',
            child: w.SelectableTextAreaView(
              controller: editorPreviewController,
              selectionController: controller,
              maxWidth: 60,
            ),
          ),
          _documentBlock(
            theme: theme,
            title: 'Checklist section',
            child: w.Column(
              gap: 0,
              children: [
                s.SelectableText(
                  '- Drag from the title to here to copy one combined block.',
                  style: bodyStyle,
                ),
                s.SelectableText(
                  '- Triple-click any line to select that entire line.',
                  style: bodyStyle,
                ),
                s.SelectableText(
                  '- Ctrl+C copies the shared selection buffer.',
                  style: bodyStyle,
                ),
              ],
            ),
          ),
          w.Text(
            'Footer: this line proves the selection can span the full document.',
            style: subtleStyle,
          ).selectable(),
        ],
      ),
    ),
  );
}

w.Widget _documentBlock({
  required w.Theme theme,
  required String title,
  required w.Widget child,
}) {
  return w.Container(
    decoration: w.BoxDecoration(border: Border.normal, color: theme.surface),
    padding: const w.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
    child: w.Column(
      gap: 0,
      children: [
        w.Text(
          title,
          style: theme.labelLarge.copy()..foreground(theme.primary),
        ).selectable(),
        child,
      ],
    ),
  );
}

w.Widget _sectionCard({
  required w.Theme theme,
  required String title,
  required w.Widget child,
}) {
  return w.Container(
    decoration: w.BoxDecoration(border: Border.rounded, color: theme.surface),
    padding: const w.EdgeInsets.all(1),
    child: w.Column(
      gap: 0,
      children: [
        w.Text(
          title,
          style: theme.labelLarge.copy()..foreground(theme.onSurface),
        ),
        child,
      ],
    ),
  );
}
