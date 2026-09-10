import 'package:artisanal/bubbles.dart' as bubbles;
import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/tui.dart'
    show Cmd, Msg, MouseAction, MouseButton, MouseMsg;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('TreeViewNode', () {
    test('fromMap parses basic node', () {
      final node = TreeViewNode.fromMap({'label': 'Root'});
      expect(node.label, equals('Root'));
      expect(node.children, isEmpty);
      expect(node.icon, isNull);
      expect(node.expanded, isTrue);
    });

    test('fromMap accepts "name" as alternative to "label"', () {
      final node = TreeViewNode.fromMap({'name': 'Alt'});
      expect(node.label, equals('Alt'));
    });

    test('fromMap defaults to empty string when no label/name', () {
      final node = TreeViewNode.fromMap({});
      expect(node.label, equals(''));
    });

    test('fromMap parses children recursively', () {
      final node = TreeViewNode.fromMap({
        'label': 'Parent',
        'children': [
          {'label': 'Child1'},
          {'label': 'Child2', 'icon': '📄'},
        ],
      });
      expect(node.children, hasLength(2));
      expect(node.children[0].label, equals('Child1'));
      expect(node.children[1].label, equals('Child2'));
      expect(node.children[1].icon, equals('📄'));
    });

    test('fromMap parses icon', () {
      final node = TreeViewNode.fromMap({'label': 'F', 'icon': '📁'});
      expect(node.icon, equals('📁'));
    });

    test('fromMap parses expanded flag', () {
      final collapsed = TreeViewNode.fromMap({'label': 'C', 'expanded': false});
      expect(collapsed.expanded, isFalse);

      final expanded = TreeViewNode.fromMap({'label': 'E', 'expanded': true});
      expect(expanded.expanded, isTrue);
    });

    test('fromMap defaults expanded to true', () {
      final node = TreeViewNode.fromMap({'label': 'X'});
      expect(node.expanded, isTrue);
    });
  });

  group('TreeView', () {
    test('renders single root node label', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(TreeView(nodes: [TreeViewNode(label: 'Root')]));

      expect(tester.find.text('Root'), isTrue);
    });

    test('renders multiple root nodes', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TreeView(
          nodes: [
            TreeViewNode(label: 'First'),
            TreeViewNode(label: 'Second'),
            TreeViewNode(label: 'Third'),
          ],
        ),
      );

      expect(tester.find.text('First'), isTrue);
      expect(tester.find.text('Second'), isTrue);
      expect(tester.find.text('Third'), isTrue);
    });

    test('renders child nodes with connectors', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TreeView(
          nodes: [
            TreeViewNode(
              label: 'Parent',
              children: [TreeViewNode(label: 'Child')],
            ),
          ],
        ),
      );

      expect(tester.find.text('Parent'), isTrue);
      expect(tester.find.text('Child'), isTrue);
      // The last child uses └─ connector.
      expect(tester.find.text('└'), isTrue);
    });

    test('renders branch connector for non-last siblings', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TreeView(
          nodes: [
            TreeViewNode(
              label: 'Root',
              children: [
                TreeViewNode(label: 'A'),
                TreeViewNode(label: 'B'),
              ],
            ),
          ],
        ),
      );

      // First child (non-last) uses ├─ connector.
      expect(tester.find.text('├'), isTrue);
      // Last child uses └─ connector.
      expect(tester.find.text('└'), isTrue);
    });

    test('renders icons when provided', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TreeView(
          nodes: [
            TreeViewNode(
              label: 'src',
              icon: '📁',
              children: [TreeViewNode(label: 'main.dart', icon: '📄')],
            ),
          ],
        ),
      );

      expect(tester.find.text('📁'), isTrue);
      expect(tester.find.text('📄'), isTrue);
      expect(tester.find.text('src'), isTrue);
      expect(tester.find.text('main.dart'), isTrue);
    });

    test('hides children when expanded is false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TreeView(
          nodes: [
            TreeViewNode(
              label: 'Collapsed',
              expanded: false,
              children: [TreeViewNode(label: 'Hidden')],
            ),
          ],
        ),
      );

      expect(tester.find.text('Collapsed'), isTrue);
      expect(tester.find.text('Hidden'), isFalse);
    });

    test('shows children when expanded is true', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TreeView(
          nodes: [
            TreeViewNode(
              label: 'Open',
              expanded: true,
              children: [TreeViewNode(label: 'Visible')],
            ),
          ],
        ),
      );

      expect(tester.find.text('Open'), isTrue);
      expect(tester.find.text('Visible'), isTrue);
    });

    test('renders deeply nested tree', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TreeView(
          nodes: [
            TreeViewNode(
              label: 'L0',
              children: [
                TreeViewNode(
                  label: 'L1',
                  children: [
                    TreeViewNode(
                      label: 'L2',
                      children: [TreeViewNode(label: 'L3')],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      expect(tester.find.text('L0'), isTrue);
      expect(tester.find.text('L1'), isTrue);
      expect(tester.find.text('L2'), isTrue);
      expect(tester.find.text('L3'), isTrue);
    });

    test('renders continuation lines for deep nesting', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TreeView(
          nodes: [
            TreeViewNode(
              label: 'Root',
              children: [
                TreeViewNode(
                  label: 'A',
                  children: [TreeViewNode(label: 'Deep')],
                ),
                TreeViewNode(label: 'B'),
              ],
            ),
          ],
        ),
      );

      // Continuation line '│' should appear for non-last children.
      expect(tester.find.text('│'), isTrue);
    });

    test('indentSize controls connector width', () async {
      final narrowTester = WidgetTester(screenWidth: 60);
      addTearDown(() => narrowTester.dispose());
      final wideTester = WidgetTester(screenWidth: 60);
      addTearDown(() => wideTester.dispose());

      final tree = [
        TreeViewNode(
          label: 'Root',
          children: [TreeViewNode(label: 'Child')],
        ),
      ];

      await narrowTester.pumpWidget(TreeView(nodes: tree, indentSize: 2));
      await wideTester.pumpWidget(TreeView(nodes: tree, indentSize: 4));

      // With indentSize 4, there should be more dashes (└─── vs └─).
      expect(wideTester.find.text('───'), isTrue);
      // With indentSize 2, there's only one dash.
      expect(narrowTester.find.text('───'), isFalse);
    });

    test('indentSize below 2 is clamped to 2', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TreeView(
          nodes: [
            TreeViewNode(
              label: 'Root',
              children: [TreeViewNode(label: 'Child')],
            ),
          ],
          indentSize: 0,
        ),
      );

      // Should still render with minimum indent.
      expect(tester.find.text('Root'), isTrue);
      expect(tester.find.text('Child'), isTrue);
      expect(tester.find.text('└'), isTrue);
    });

    test('empty nodes list renders without error', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(TreeView(nodes: []));

      // Should render without throwing — empty tree produces empty output.
    });

    test('has unique id', () {
      final t1 = TreeView(nodes: []);
      final t2 = TreeView(nodes: []);
      expect(t1.id, isNot(equals(t2.id)));
    });

    test('respects key', () {
      final t = TreeView(key: ValueKey('tree-key'), nodes: []);
      expect(t.id, equals('tree-key'));
    });

    test('model constructor toggles branches from pointer input', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final model = bubbles.TreeModel<String>(
        items: [
          bubbles.TreeItem(
            id: 'lib',
            label: 'lib',
            value: 'lib',
            children: [
              bubbles.TreeItem(
                id: 'lib/main.dart',
                label: 'main.dart',
                value: 'lib/main.dart',
              ),
            ],
          ),
        ],
      );
      bool? expanded;

      await tester.pumpWidget(
        TreeView<String>.model(
          model: model,
          onToggle: (item, value) {
            expanded = value;
            return null;
          },
        ),
      );

      final location = tester.locateText('lib');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);

      expect(model.isExpanded('lib'), isFalse);
      expect(expanded, isFalse);
      expect(tester.find.text('main.dart'), isFalse);
    });

    test('model constructor activates leaves from pointer input', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final model = bubbles.TreeModel<String>(
        items: [
          bubbles.TreeItem(
            id: 'README.md',
            label: 'README.md',
            value: 'readme',
          ),
        ],
      );
      String? activated;

      await tester.pumpWidget(
        TreeView<String>.model(
          model: model,
          onActivated: (item) {
            activated = item.value;
            return null;
          },
        ),
      );
      final location = tester.locateText('README.md');
      expect(location, isNotNull);
      tester.tapAt(location!.x, location.y);

      expect(activated, 'readme');
    });

    test('focused model tree delegates keyboard navigation', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      final model = bubbles.TreeModel<String>(
        items: [
          bubbles.TreeItem(id: 'one', label: 'one', value: 'one'),
          bubbles.TreeItem(id: 'two', label: 'two', value: 'two'),
        ],
      );
      String? selected;

      await tester.pumpWidget(
        TreeView<String>.model(
          model: model,
          autofocus: true,
          onSelected: (item) {
            selected = item.value;
            return null;
          },
        ),
      );
      tester.sendSpecialKey(KeyType.down);

      expect(model.selectedItem?.id, 'two');
      expect(selected, 'two');
    });

    test('model activation preserves model and callback commands', () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final model = bubbles.TreeModel<String>(
        items: [bubbles.TreeItem(id: 'one', label: 'one', value: 'one')],
      );
      var modelActivations = 0;
      var callbackActivations = 0;

      await tester.pumpWidget(
        _TreeActivationHost(
          onModelActivation: () => modelActivations++,
          child: TreeView<String>.model(
            model: model,
            autofocus: true,
            onActivated: (_) => Cmd(() async {
              callbackActivations++;
              return null;
            }),
          ),
        ),
      );
      tester.sendSpecialKey(KeyType.enter);
      await Future<void>.delayed(Duration.zero);

      expect(modelActivations, 1);
      expect(callbackActivations, 1);
    });

    test('replaces an externally owned model on rebuild', () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final first = bubbles.TreeModel<String>(
        items: [bubbles.TreeItem(id: 'first', label: 'first', value: 'first')],
      );
      final second = bubbles.TreeModel<String>(
        items: [
          bubbles.TreeItem(id: 'second', label: 'second', value: 'second'),
        ],
      );

      await tester.pumpWidget(
        _ModelReplacementHost(first: first, second: second),
      );
      expect(tester.view, contains('first'));
      tester.sendMsg(const _ReplaceTreeModelMsg());

      expect(tester.view, contains('second'));
      expect(tester.view, isNot(contains('first')));
    });

    test('compatibility rebuild preserves collapsed branches', () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);

      await tester.pumpWidget(_CompatibilityRebuildHost());
      tester.tapAt(tester.locateText('lib')!.x, tester.locateText('lib')!.y);
      expect(tester.view, isNot(contains('main.dart')));
      tester.sendMsg(const _RebuildCompatibilityTreeMsg());

      expect(tester.view, isNot(contains('main.dart')));
    });

    test('horizontal panning preserves emoji and wide labels', () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final model = bubbles.TreeModel<String>(
        items: [
          bubbles.TreeItem(
            id: 'unicode',
            label: '你好.dart',
            value: 'unicode',
            icon: '📁',
          ),
        ],
      )..setHorizontalOffset(1);

      await tester.pumpWidget(
        TreeView<String>.model(model: model, showExpandIndicators: false),
      );
      expect(tester.view, contains('📁'));
      expect(tester.view, isNot(contains('\uFFFD')));

      model.setHorizontalOffset(4);
      await tester.pumpWidget(
        TreeView<String>.model(model: model, showExpandIndicators: false),
      );
      expect(tester.view, contains('你'));
      expect(tester.view, isNot(contains('\uFFFD')));
    });

    test('constrained model tree exposes shared scroll state', () async {
      final tester = WidgetTester(screenHeight: 8);
      addTearDown(() => tester.dispose());
      final model = bubbles.TreeModel<int>(
        items: [
          for (var index = 0; index < 12; index++)
            bubbles.TreeItem(id: '$index', label: 'item $index', value: index),
        ],
      );

      await tester.pumpWidget(TreeView<int>.model(model: model, height: 4));
      final location = tester.locateText('item 1');
      expect(location, isNotNull);
      tester.sendMsg(
        MouseMsg(
          action: MouseAction.wheel,
          button: MouseButton.wheelDown,
          x: location!.x,
          y: location.y,
        ),
      );

      expect(model.offset, greaterThan(0));
    });
  });
}

final class _TreeActivationHost extends StatefulWidget {
  _TreeActivationHost({required this.child, required this.onModelActivation});

  final Widget child;
  final void Function() onModelActivation;

  @override
  State<_TreeActivationHost> createState() => _TreeActivationHostState();
}

final class _TreeActivationHostState extends State<_TreeActivationHost> {
  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is bubbles.TreeItemActivatedMsg<String>) {
      widget.onModelActivation();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

final class _ReplaceTreeModelMsg extends Msg {
  const _ReplaceTreeModelMsg();
}

final class _ModelReplacementHost extends StatefulWidget {
  _ModelReplacementHost({required this.first, required this.second});

  final bubbles.TreeModel<String> first;
  final bubbles.TreeModel<String> second;

  @override
  State<_ModelReplacementHost> createState() => _ModelReplacementHostState();
}

final class _ModelReplacementHostState extends State<_ModelReplacementHost> {
  late bubbles.TreeModel<String> _model = widget.first;

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is _ReplaceTreeModelMsg) {
      setState(() => _model = widget.second);
      return Cmd.none();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => TreeView<String>.model(model: _model);
}

final class _RebuildCompatibilityTreeMsg extends Msg {
  const _RebuildCompatibilityTreeMsg();
}

final class _CompatibilityRebuildHost extends StatefulWidget {
  @override
  State<_CompatibilityRebuildHost> createState() =>
      _CompatibilityRebuildHostState();
}

final class _CompatibilityRebuildHostState
    extends State<_CompatibilityRebuildHost> {
  int _generation = 0;

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is _RebuildCompatibilityTreeMsg) {
      setState(() => _generation++);
      return Cmd.none();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TreeView<String>(
      key: const ValueKey('compatibility-tree'),
      nodes: [
        TreeViewNode(
          id: 'lib',
          label: 'lib',
          value: 'lib:$_generation',
          children: [
            TreeViewNode(id: 'main', label: 'main.dart', value: 'main.dart'),
          ],
        ),
      ],
    );
  }
}
