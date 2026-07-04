/// Model list dialog — searchable list of available models.
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/chat_model.dart';
import '../theme.dart';

class ModelListDialog extends w.StatefulWidget {
  ModelListDialog({
    required this.child,
    required this.models,
    required this.currentModelName,
    this.open = false,
    this.onDismiss,
    this.onSelect,
    super.key,
  });

  final w.Widget child;
  final List<ModelOption> models;
  final String currentModelName;
  final bool open;
  final w.CmdCallback? onDismiss;
  final void Function(ModelOption model)? onSelect;

  @override
  w.State createState() => _ModelListDialogState();
}

class _ModelListDialogState extends w.State<ModelListDialog> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  late w.TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = w.TextEditingController();
  }

  @override
  tui.Cmd? didUpdateWidget(covariant ModelListDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open && !oldWidget.open) {
      _searchQuery = '';
      _searchController.clear();
      _selectedIndex = _indexOfModel(widget.currentModelName);
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _indexOfModel(String modelName) {
    final index = _filteredModels.indexWhere(
      (model) => model.modelName == modelName,
    );
    return index < 0 ? 0 : index;
  }

  List<ModelOption> get _filteredModels {
    if (_searchQuery.isEmpty) return widget.models;
    final q = _searchQuery.toLowerCase();
    return widget.models
        .where(
          (model) =>
              model.modelName.toLowerCase().contains(q) ||
              model.providerName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  w.Widget build(w.BuildContext context) {
    if (!widget.open) return widget.child;

    final theme = w.ThemeScope.of(context);
    final cpTheme = theme.commandPaletteTheme;
    final dialogBg = cpTheme?.background ?? OC.backgroundPanel;
    final dialogFg = cpTheme?.foreground ?? OC.text;
    final selectedBg = cpTheme?.selectedBackground ?? OC.backgroundElement;
    final selectedFg = cpTheme?.selectedForeground ?? OC.text;
    final shortcutFg = cpTheme?.shortcutForeground ?? OC.textMuted;
    final searchBg = cpTheme?.searchBackground ?? OC.backgroundElement;

    final filtered = _filteredModels;
    if (_selectedIndex >= filtered.length) {
      _selectedIndex = filtered.isEmpty ? 0 : filtered.length - 1;
    }

    final rows = <w.Widget>[];
    for (var i = 0; i < filtered.length; i++) {
      final model = filtered[i];
      final selected = i == _selectedIndex;
      final active = model.modelName == widget.currentModelName;
      final rowFg = selected ? selectedFg : dialogFg;
      final rowHintFg = selected ? selectedFg : shortcutFg;
      final markerFg = selected ? selectedFg : OC.primary;

      rows.add(
        w.GestureDetector(
          onTap: () {
            widget.onSelect?.call(model);
            return null;
          },
          child: w.Container(
            color: selected ? selectedBg : null,
            padding: const w.EdgeInsets.only(left: 3, right: 3),
            child: w.Row(
              children: [
                w.Text(
                  active ? '\u00b7' : ' ',
                  style: style.Style()
                    ..foreground(active ? markerFg : rowHintFg),
                ),
                w.SizedBox(width: 1),
                w.Expanded(
                  child: w.Text(
                    model.modelName,
                    style: style.Style()..foreground(rowFg),
                    softWrap: false,
                  ),
                ),
                w.Text(
                  model.providerName,
                  style: style.Style()
                    ..foreground(rowHintFg)
                    ..dim(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dialog = w.SizedBox(
      width: 64,
      height: 22,
      child: w.Container(
        color: dialogBg,
        child: w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Container(
              padding: const w.EdgeInsets.only(left: 4, right: 4, top: 1),
              child: w.Row(
                children: [
                  w.Text(
                    'Models',
                    style: style.Style()
                      ..foreground(dialogFg)
                      ..bold(),
                  ),
                  w.Spacer(),
                  w.Text(
                    'esc',
                    style: style.Style()
                      ..foreground(shortcutFg)
                      ..dim(),
                  ),
                ],
              ),
            ),
            w.SizedBox(height: 1),
            w.Container(
              padding: const w.EdgeInsets.only(left: 4, right: 4),
              child: w.Container(
                color: searchBg,
                padding: const w.EdgeInsets.only(left: 1, right: 1),
                child: w.Row(
                  children: [
                    w.Text('/', style: style.Style()..foreground(shortcutFg)),
                    w.SizedBox(width: 1),
                    w.Expanded(
                      child: w.TextField(
                        controller: _searchController,
                        focusId: 'model-list-search',
                        prompt: '',
                        placeholder: 'Search models...',
                        autofocus: true,
                        onChanged: (text) {
                          setState(() {
                            _searchQuery = text;
                            _selectedIndex = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            w.SizedBox(height: 1),
            w.Expanded(
              child: w.Container(
                color: dialogBg,
                padding: const w.EdgeInsets.only(left: 1, right: 1),
                child: w.SingleChildScrollView(
                  child: w.Column(
                    crossAxisAlignment: w.CrossAxisAlignment.stretch,
                    children: rows.isEmpty
                        ? [
                            w.Padding(
                              padding: const w.EdgeInsets.only(
                                left: 3,
                                right: 3,
                              ),
                              child: w.Text(
                                'No models matching "$_searchQuery"',
                                style: style.Style()..foreground(shortcutFg),
                              ),
                            ),
                          ]
                        : rows,
                  ),
                ),
              ),
            ),
            w.Container(
              padding: const w.EdgeInsets.only(left: 4, right: 4, bottom: 1),
              child: w.Row(
                children: [
                  _hintKey('up/down'),
                  w.SizedBox(width: 1),
                  _hintLabel('navigate'),
                  w.SizedBox(width: 2),
                  _hintKey('enter'),
                  w.SizedBox(width: 1),
                  _hintLabel('apply'),
                  w.Spacer(),
                  w.Text(
                    '${filtered.length} model${filtered.length == 1 ? '' : 's'}',
                    style: style.Style()
                      ..foreground(shortcutFg)
                      ..dim(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return w.Modal(
      open: true,
      onDismiss: widget.onDismiss,
      backdropOpacity: 0.72,
      child: widget.child,
      dialog: dialog,
    );
  }

  w.Widget _hintKey(String text) {
    return w.Text(
      text,
      style: style.Style()
        ..foreground(OC.textMuted)
        ..dim(),
    );
  }

  w.Widget _hintLabel(String text) {
    return w.Text(
      text,
      style: style.Style()
        ..foreground(OC.textMuted)
        ..dim(),
    );
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (!widget.open) return null;
    if (msg is! tui.KeyMsg) return null;

    final key = msg.key;
    final filtered = _filteredModels;

    if (key.type == tui.KeyType.escape) {
      widget.onDismiss?.call();
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.enter && filtered.isNotEmpty) {
      final selected = filtered[_selectedIndex];
      widget.onSelect?.call(selected);
      widget.onDismiss?.call();
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.up && filtered.isNotEmpty) {
      _selectedIndex = (_selectedIndex - 1) % filtered.length;
      if (_selectedIndex < 0) _selectedIndex = filtered.length - 1;
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.down && filtered.isNotEmpty) {
      _selectedIndex = (_selectedIndex + 1) % filtered.length;
      return tui.Cmd.none();
    }

    if (key.ctrl || key.alt || key.type == tui.KeyType.tab) {
      return tui.Cmd.none();
    }

    return null;
  }
}
