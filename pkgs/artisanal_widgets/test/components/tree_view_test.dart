import 'package:artisanal/artisanal.dart';
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
  });
}
