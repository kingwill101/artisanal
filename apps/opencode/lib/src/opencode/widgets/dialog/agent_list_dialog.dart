/// Agent picker dialog (OpenCode agent list).
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../models/chat_model.dart';
import '../../theme.dart';
import 'open_code_overlay.dart';

class AgentListDialog extends w.StatefulWidget {
  AgentListDialog({
    required this.agents,
    required this.currentAgentName,
    this.onSelect,
    this.onDismiss,
    super.key,
  });

  final List<AgentOption> agents;
  final String currentAgentName;
  final void Function(AgentOption agent)? onSelect;
  final void Function()? onDismiss;

  @override
  w.State createState() => _AgentListDialogState();
}

class _AgentListDialogState extends w.State<AgentListDialog> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  late w.TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = w.TextEditingController();
    final i = widget.agents.indexWhere(
      (a) => a.name == widget.currentAgentName,
    );
    if (i >= 0) _selectedIndex = i;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AgentOption> get _filtered {
    if (_searchQuery.isEmpty) return widget.agents;
    final q = _searchQuery.toLowerCase();
    return widget.agents
        .where(
          (a) =>
              a.name.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final cp = theme.commandPaletteTheme;
    final dialogFg = cp?.foreground ?? OC.text;
    final selectedBg = cp?.selectedBackground ?? OC.backgroundElement;
    final selectedFg = cp?.selectedForeground ?? OC.text;
    final shortcutFg = cp?.shortcutForeground ?? OC.textMuted;
    final searchBg = cp?.searchBackground ?? OC.backgroundElement;

    final filtered = _filtered;
    if (_selectedIndex >= filtered.length) {
      _selectedIndex = filtered.isEmpty ? 0 : filtered.length - 1;
    }

    final rows = <w.Widget>[];
    for (var i = 0; i < filtered.length; i++) {
      final agent = filtered[i];
      final selected = i == _selectedIndex;
      final active = agent.name == widget.currentAgentName;
      final rowFg = selected ? selectedFg : dialogFg;
      final rowHintFg = selected ? selectedFg : shortcutFg;
      final markerFg = selected ? selectedFg : OC.primary;

      rows.add(
        w.GestureDetector(
          onTap: () {
            widget.onSelect?.call(agent);
            return null;
          },
          child: w.Container(
            color: selected ? selectedBg : null,
            padding: const w.EdgeInsets.only(left: 3, right: 3),
            child: w.Row(
              children: [
                w.Text(
                  active ? '·' : ' ',
                  style: style.Style()
                    ..foreground(active ? markerFg : rowHintFg),
                ),
                w.SizedBox(width: 1),
                w.Expanded(
                  child: w.Column(
                    crossAxisAlignment: w.CrossAxisAlignment.stretch,
                    children: [
                      w.Text(
                        agent.name,
                        style: style.Style()
                          ..foreground(rowFg)
                          ..bold(),
                        softWrap: false,
                      ),
                      w.Text(
                        agent.description,
                        style: style.Style()
                          ..foreground(rowHintFg)
                          ..dim(),
                        softWrap: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final search = w.Container(
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
                focusId: 'agent-list-search',
                prompt: '',
                placeholder: 'Search agents...',
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
    );

    return OpenCodePickerShell(
      title: 'Agents',
      search: search,
      body: w.Container(
        color: cp?.background ?? OC.backgroundPanel,
        padding: const w.EdgeInsets.only(left: 1, right: 1),
        child: w.SingleChildScrollView(
          child: w.Column(
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: rows.isEmpty
                ? [
                    w.Padding(
                      padding: const w.EdgeInsets.only(left: 3, right: 3),
                      child: w.Text(
                        'No agents matching "$_searchQuery"',
                        style: style.Style()..foreground(shortcutFg),
                      ),
                    ),
                  ]
                : rows,
          ),
        ),
      ),
      footer: w.Row(
        children: openCodePickerHints(
          countLabel:
              '${filtered.length} agent${filtered.length == 1 ? '' : 's'}',
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;
    final key = msg.key;
    final filtered = _filtered;

    if (key.isEscape) {
      widget.onDismiss?.call();
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.enter && filtered.isNotEmpty) {
      widget.onSelect?.call(filtered[_selectedIndex]);
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.up && filtered.isNotEmpty) {
      setState(() {
        _selectedIndex =
            (_selectedIndex - 1 + filtered.length) % filtered.length;
      });
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.down && filtered.isNotEmpty) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % filtered.length;
      });
      return tui.Cmd.none();
    }

    return null;
  }
}
