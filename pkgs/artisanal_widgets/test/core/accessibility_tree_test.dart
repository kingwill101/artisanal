/// Tests for deterministic accessibility tree construction and diffs.
library;

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  group('Accessibility tree', () {
    test('builds from widget hierarchy with stable IDs', () {
      final leafA = _AccessibleNode(
        key: const w.ValueKey('node-a'),
        label: 'first node',
        role: 'heading',
        text: 'Node A',
      );
      final leafB = _AccessibleNode(
        key: const w.ValueKey('node-b'),
        label: 'second node',
        role: 'label',
        text: 'Node B',
      );
      final app = tui.WidgetApp(_StaticA11yTree(children: [leafA, leafB]));
      app.view();

      final tree = app.buildAccessibilityTree();
      final root = tree.root;
      expect(root, isNotNull);
      expect(root!.children, hasLength(1));

      final accessibleLeaves = tree.nodes.values
          .where((node) => node.widget is _AccessibleNode)
          .toList(growable: false);
      expect(accessibleLeaves, hasLength(2));

      final firstNode = tree.nodeForWidget(leafA);
      final secondNode = tree.nodeForWidget(leafB);
      expect(firstNode, isNotNull);
      expect(secondNode, isNotNull);
      expect(firstNode!.label, equals('first node'));
      expect(secondNode!.label, equals('second node'));
      expect(firstNode.role, equals('heading'));
      expect(secondNode.role, equals('label'));
      expect(firstNode.id, isNot(secondNode.id));
    });

    test('keeps IDs stable for unchanged keyed nodes across rebuilds', () {
      final leaf = _AccessibleNode(
        key: const w.ValueKey('leaf'),
        label: 'stable',
        role: 'status',
        text: 'value',
      );
      final app = tui.WidgetApp(_CounterA11yRoot(child: leaf));
      app.view();

      final before = app.buildAccessibilityTree();
      app.update(_IncrementA11yCounterMsg());
      final after = app.buildAccessibilityTree();

      expect(
        before.nodeForWidget(leaf)?.id,
        equals(after.nodeForWidget(leaf)?.id),
      );
    });

    test('detects node changes and added/removed nodes', () {
      final first = _AccessibleNode(
        key: const w.ValueKey('first'),
        label: 'first node',
        role: 'item',
        text: 'First',
      );
      final second = _AccessibleNode(
        key: const w.ValueKey('second'),
        label: 'second node',
        role: 'item',
        text: 'Second',
      );
      final app = tui.WidgetApp(_ToggleA11yRoot(first: first, second: second));
      app.view();
      final baseline = app.buildAccessibilityTree();
      expect(
        baseline.nodes.values.where((node) => node.widget is _AccessibleNode),
        hasLength(1),
      );

      app.update(_ToggleA11yNodesMsg());
      final withSecond = app.buildAccessibilityTree();
      final addDiff = withSecond.diff(baseline);
      expect(
        addDiff.added.where((node) => node.widget is _AccessibleNode),
        hasLength(1),
      );
      expect(
        addDiff.changed.where((node) => node.widget is _AccessibleNode),
        isEmpty,
      );
      expect(addDiff.removed, isEmpty);

      app.update(_ToggleA11yNodesMsg());
      final withoutSecond = app.buildAccessibilityTree();
      final removeDiff = withoutSecond.diff(withSecond);
      expect(
        removeDiff.removed.where((node) => node.widget is _AccessibleNode),
        hasLength(1),
      );
      expect(removeDiff.added, isEmpty);
      expect(
        removeDiff.changed.where((node) => node.widget is _AccessibleNode),
        isEmpty,
      );
    });
  });
}

class _AccessibleNode extends w.StatelessWidget {
  _AccessibleNode({
    super.key,
    required this.label,
    required this.role,
    required this.text,
  });

  final String label;
  final String role;
  final String text;

  @override
  String get accessibilityLabel => label;

  @override
  String get accessibilityRole => role;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(text);
  }
}

class _StaticA11yTree extends w.StatelessWidget {
  _StaticA11yTree({required this.children});

  @override
  final List<w.Widget> children;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(children: children);
  }
}

class _CounterA11yRoot extends w.StatefulWidget {
  _CounterA11yRoot({required this.child});

  final w.Widget child;

  @override
  w.State createState() => _CounterA11yRootState();
}

class _CounterA11yRootState extends w.State<_CounterA11yRoot> {
  int _count = 0;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(children: [w.Text('count: $_count'), widget.child]);
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _IncrementA11yCounterMsg) {
      setState(() => _count += 1);
    }
    return null;
  }
}

class _ToggleA11yRoot extends w.StatefulWidget {
  _ToggleA11yRoot({required this.first, required this.second});

  final _AccessibleNode first;
  final _AccessibleNode second;

  @override
  w.State createState() => _ToggleA11yRootState();
}

class _ToggleA11yRootState extends w.State<_ToggleA11yRoot> {
  bool _showSecond = false;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(children: [widget.first, if (_showSecond) widget.second]);
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _ToggleA11yNodesMsg) {
      setState(() => _showSecond = !_showSecond);
    }
    return null;
  }
}

class _IncrementA11yCounterMsg extends tui.Msg {
  _IncrementA11yCounterMsg();
}

class _ToggleA11yNodesMsg extends tui.Msg {
  _ToggleA11yNodesMsg();
}
