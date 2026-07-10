import 'package:artisanal/bubbles.dart'
    show
        CodeLanguageProfile,
        CursorModel,
        TextAreaKeyMap,
        TextAreaModel,
        TextAreaStyles,
        TextDecorationRange,
        TextSyntaxBuildResult,
        TextSyntaxDecorationPatch,
        TextSyntaxSession,
        TextSyntaxSnapshot,
        TextSyntaxProvider,
        TextDocument,
        TextDocumentChange,
        keyMatchesSingle,
        codeHandleClosingDelimiterAlignment,
        codeHandlePairBackspace,
        codeHandleAutoPair,
        codeInsertIndentedNewline,
        codeToggleBlockComments,
        resolveCodeLanguageProfile,
        textSyntaxChangeWindow,
        textSyntaxDecorationLayerKey,
        textSyntaxDecorationLayerPriority;
import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart' show Color, Border, Style, Colors;

/// A higher-level Markdown editor with a live rendered preview.
///
/// `MarkdownEditor` composes [TextEditor] with [MarkdownText] so the editing
/// surface and rendered preview stay in sync while sharing the same controller.
///
/// ```dart
/// final controller = TextAreaController(
///   text: '# Notes\n\n- Ship MarkdownEditor',
/// );
///
/// MarkdownEditor(
///   title: 'README.md',
///   controller: controller,
///   height: 8,
///   previewHeight: 10,
/// )
/// ```
class MarkdownEditor extends StatefulWidget {
  MarkdownEditor({
    this.title = 'Markdown',
    this.controller,
    this.model,
    this.focusController,
    this.focusId,
    this.autofocus = false,
    this.enabled = true,
    this.prompt,
    this.placeholder,
    this.width,
    this.height = 8,
    this.showLineNumbers = true,
    this.softWrap = true,
    this.useVirtualCursor,
    this.keyMap,
    this.styles,
    this.cursor,
    this.showHelpBar = true,
    this.helpExpanded = false,
    this.headerTrailing,
    this.footer,
    this.onChanged,
    this.onSave,
    this.showSaveStatus = true,
    this.cleanLabel = 'saved',
    this.dirtyLabel = 'modified',
    this.indentWidth = 2,
    this.showPreview = true,
    this.previewTitle = 'Preview',
    this.previewHeight = 10,
    this.previewWrap = true,
    this.previewController,
    this.showPreviewScrollbar = true,
    this.previewMaxWidth,
    this.markdownOptions,
    super.key,
  });

  final String title;
  final TextAreaController? controller;
  final TextAreaModel? model;
  final FocusController? focusController;
  final String? focusId;
  final bool autofocus;
  final bool enabled;
  final String? prompt;
  final String? placeholder;
  final int? width;
  final int height;
  final bool showLineNumbers;
  final bool softWrap;
  final bool? useVirtualCursor;
  final TextAreaKeyMap? keyMap;
  final TextAreaStyles? styles;
  final CursorModel? cursor;
  final bool showHelpBar;
  final bool helpExpanded;
  final Widget? headerTrailing;
  final Widget? footer;
  final TextChangedCallback? onChanged;
  final ValueCmdCallback<String>? onSave;
  final bool showSaveStatus;
  final String cleanLabel;
  final String dirtyLabel;
  final int indentWidth;
  final bool showPreview;
  final String previewTitle;
  final int previewHeight;
  final bool previewWrap;
  final ScrollController? previewController;
  final bool showPreviewScrollbar;
  final int? previewMaxWidth;
  final AnsiRendererOptions? markdownOptions;

  @override
  State createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  TextAreaController? _internalController;
  TextAreaController get _controller =>
      widget.controller ??
      (_internalController ??= TextAreaController(model: widget.model));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  Cmd? didUpdateWidget(covariant MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(
        _handleControllerChanged,
      );
      _controller.addListener(_handleControllerChanged);
    }
    if (oldWidget.model != widget.model && widget.model != null) {
      _controller.model = widget.model!;
    }
    return null;
  }

  @override
  void dispose() {
    (widget.controller ?? _internalController)?.removeListener(
      _handleControllerChanged,
    );
    _internalController?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final previewTitle = widget.previewTitle.isEmpty
        ? 'markdown'
        : '${widget.previewTitle} · markdown';

    return Column(
      gap: 1,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextEditor(
          title: widget.title,
          controller: _controller,
          focusController: widget.focusController,
          focusId: widget.focusId,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          prompt: widget.prompt,
          placeholder: widget.placeholder,
          width: widget.width,
          height: widget.height,
          showLineNumbers: widget.showLineNumbers,
          softWrap: widget.softWrap,
          useVirtualCursor: widget.useVirtualCursor,
          keyMap: widget.keyMap,
          styles: widget.styles,
          cursor: widget.cursor,
          showHelpBar: widget.showHelpBar,
          helpExpanded: widget.helpExpanded,
          headerTrailing: widget.headerTrailing,
          footer: widget.footer,
          onChanged: widget.onChanged,
          onSave: widget.onSave,
          showSaveStatus: widget.showSaveStatus,
          cleanLabel: widget.cleanLabel,
          dirtyLabel: widget.dirtyLabel,
          indentWidth: widget.indentWidth,
        ),
        if (widget.showPreview)
          PanelBox(
            title: previewTitle,
            child: ScrollArea(
              controller: widget.previewController,
              height: widget.previewHeight,
              showScrollbar: widget.showPreviewScrollbar,
              child: MarkdownText(
                data: _controller.text,
                options: widget.markdownOptions,
                softWrap: widget.previewWrap,
                maxWidth: widget.previewMaxWidth,
                textStyle: Style().foreground(theme.onSurface),
              ),
            ),
          ),
      ],
    );
  }
}
