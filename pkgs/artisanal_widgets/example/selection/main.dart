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
  SelectionShowcase({super.key, this.controller});

  final s.SelectionController? controller;

  @override
  w.State createState() => _SelectionShowcaseState();
}

class _SelectionShowcaseState extends w.State<SelectionShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
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
                child: w.Text(previewText, style: bodyStyle),
              ),
              _documentCard(
                theme: theme,
                controller: _selectionController,
                sectionTitleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                subtleStyle: subtleStyle,
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
  required Style sectionTitleStyle,
  required Style bodyStyle,
  required Style subtleStyle,
}) {
  return _sectionCard(
    theme: theme,
    title: 'Shared document surface',
    child: s.SelectionArea(
      controller: controller,
      child: w.Column(
        gap: 0,
        children: [
          s.SelectableText(
            'Cross-component selection document',
            style: sectionTitleStyle.copy()..bold(),
          ),
          s.SelectableText(
            'Drag from this title through the footer to copy one combined '
            'buffer across component types.',
            style: bodyStyle,
          ),
          _documentBlock(
            theme: theme,
            title: 'Plain text section',
            child: s.SelectableText(
              'SelectableText content should merge cleanly with the sections '
              'below when you drag across the document.',
              style: bodyStyle,
            ),
          ),
          _documentBlock(
            theme: theme,
            title: 'Rich text section',
            child: s.SelectableRichText(
              text: w.TextSpan(
                text: 'Styled spans stay visible on screen while ',
                style: bodyStyle,
                children: [
                  w.TextSpan(
                    text: 'TODO',
                    style: Style().bold().foreground(theme.warning),
                  ),
                  w.TextSpan(text: ' labels, '),
                  w.TextSpan(
                    text: 'status flags',
                    style: Style().underline().foreground(theme.primary),
                  ),
                  w.TextSpan(text: ' and emphasis still copy as plain text.'),
                ],
              ),
            ),
          ),
          _documentBlock(
            theme: theme,
            title: 'Markdown section',
            child: s.SelectableMarkdownText(
              data:
                  '## Shared markdown\n'
                  '- bullets still join the same selection buffer\n'
                  '- inline `code` copies as plain text\n'
                  '- **bold** emphasis stays readable while dragging',
              textStyle: bodyStyle,
              maxWidth: 60,
            ),
          ),
          _documentBlock(
            theme: theme,
            title: 'View-backed section',
            child: s.SelectableView(
              View(
                content:
                    '${Style().foreground(theme.secondary).render('VIEW')} :: '
                    'Raw View() content joins the same drag selection area.',
              ),
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
          s.SelectableText(
            'Footer: this line proves the selection can span the full document.',
            style: subtleStyle,
          ),
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
        s.SelectableText(
          title,
          style: theme.labelLarge.copy()..foreground(theme.primary),
        ),
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
