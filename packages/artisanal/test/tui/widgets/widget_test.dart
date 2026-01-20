import 'package:artisanal/src/tui/widgets/widgets.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/cmd.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/layout/layout.dart';
import 'package:test/test.dart';

void main() {
  group('Widget', () {
    test('has unique id', () {
      final w1 = Label('a');
      final w2 = Label('b');
      expect(w1.id, isNot(equals(w2.id)));
    });

    test('provides theme access', () {
      final widget = Label('test');
      expect(widget.theme, isNotNull);
      expect(widget.theme.primary, isNotNull);
    });

    test('children defaults to empty list', () {
      final widget = Label('test');
      expect(widget.children, isEmpty);
    });

    test('focusable defaults to false', () {
      final widget = Label('test');
      expect(widget.focusable, isFalse);
    });
  });

  group('Widget message forwarding', () {
    test('update forwards to children', () {
      final child = _CounterWidget();
      final parent = _ParentWidget(children: [child]);

      expect(child.updateCount, equals(0));

      parent.update(const _TestMsg());

      expect(child.updateCount, equals(1));
    });

    test('update collects commands from children', () {
      final child = _CmdWidget();
      final parent = _ParentWidget(children: [child]);

      final (_, cmd) = parent.update(const _TestMsg());

      expect(cmd, isNotNull);
    });

    test('init collects commands from children', () {
      final child = _InitCmdWidget();
      final parent = _ParentWidget(children: [child]);

      final cmd = parent.init();

      expect(cmd, isNotNull);
    });
  });

  group('Label', () {
    test('renders plain text', () {
      final text = Label('Hello');
      expect(text.view(), equals('Hello'));
    });

    test('renders styled text', () {
      final style = Style().bold();
      final text = Label.styled('Bold', style: style);
      final output = text.view() as String;
      expect(output, contains('Bold'));
      // Should contain ANSI bold codes
      expect(output, contains('\x1B['));
    });

    test('has no children', () {
      final text = Label('test');
      expect(text.children, isEmpty);
    });
  });

  group('HBox', () {
    test('joins children horizontally', () {
      final row = HBox(children: [Label('A'), Label('B'), Label('C')]);

      final output = row.view() as String;
      expect(output, contains('A'));
      expect(output, contains('B'));
      expect(output, contains('C'));
    });

    test('respects gap', () {
      final row = HBox(gap: 3, children: [Label('A'), Label('B')]);

      final output = row.view() as String;
      // Gap of 3 spaces between A and B
      expect(output, equals('A   B'));
    });

    test('empty children returns empty string', () {
      final row = HBox(children: []);
      expect(row.view(), equals(''));
    });

    test('children are accessible', () {
      final a = Label('A');
      final b = Label('B');
      final row = HBox(children: [a, b]);
      expect(row.children, equals([a, b]));
    });
  });

  group('VBox', () {
    test('joins children vertically', () {
      final col = VBox(children: [Label('Line 1'), Label('Line 2')]);

      final output = col.view() as String;
      final lines = output.split('\n');
      expect(lines.length, greaterThanOrEqualTo(2));
    });

    test('respects gap', () {
      final col = VBox(gap: 1, children: [Label('A'), Label('B')]);

      final output = col.view() as String;
      final lines = output.split('\n');
      // With gap 1, there should be an empty line between A and B
      expect(lines.length, equals(3));
    });

    test('empty children returns empty string', () {
      final col = VBox(children: []);
      expect(col.view(), equals(''));
    });
  });

  group('Container', () {
    test('renders child', () {
      final container = Container(child: Label('Content'));

      final output = container.view() as String;
      expect(output, contains('Content'));
    });

    test('applies padding', () {
      final container = Container(
        padding: const EdgeInsets.all(1),
        child: Label('X'),
      );

      final output = container.view() as String;
      final lines = output.split('\n');
      // Should have top padding, content row, bottom padding
      expect(lines.length, equals(3));
    });

    test('applies width constraint', () {
      final container = Container(width: 10, child: Label('Hi'));

      final output = container.view() as String;
      // All lines should be 10 chars wide
      for (final line in output.split('\n')) {
        expect(Layout.getWidth(line), equals(10));
      }
    });

    test('empty container returns empty string', () {
      final container = Container();
      expect(container.view(), equals(''));
    });
  });

  group('EdgeInsets', () {
    test('all creates uniform insets', () {
      const insets = EdgeInsets.all(5);
      expect(insets.top, equals(5));
      expect(insets.right, equals(5));
      expect(insets.bottom, equals(5));
      expect(insets.left, equals(5));
    });

    test('symmetric creates mirrored insets', () {
      const insets = EdgeInsets.symmetric(vertical: 2, horizontal: 4);
      expect(insets.top, equals(2));
      expect(insets.bottom, equals(2));
      expect(insets.left, equals(4));
      expect(insets.right, equals(4));
    });

    test('only creates specific insets', () {
      const insets = EdgeInsets.only(top: 1, left: 2);
      expect(insets.top, equals(1));
      expect(insets.left, equals(2));
      expect(insets.right, equals(0));
      expect(insets.bottom, equals(0));
    });

    test('zero is all zeros', () {
      expect(EdgeInsets.zero.top, equals(0));
      expect(EdgeInsets.zero.right, equals(0));
      expect(EdgeInsets.zero.bottom, equals(0));
      expect(EdgeInsets.zero.left, equals(0));
    });
  });

  group('Spacer', () {
    test('renders fill characters', () {
      final spacer = Spacer(size: 5);
      expect(spacer.view(), equals('     '));
    });

    test('custom fill character', () {
      final spacer = Spacer(size: 3, fill: '-');
      expect(spacer.view(), equals('---'));
    });
  });

  group('Divider', () {
    test('renders line', () {
      final divider = Divider(width: 10, char: '-');
      final output = divider.view() as String;
      // Should contain 10 dashes (may have ANSI codes)
      expect(output, contains('----------'));
    });
  });

  group('Theme', () {
    test('dark theme has expected colors', () {
      final theme = Theme.dark();
      expect(theme.primary, isNotNull);
      expect(theme.error, isNotNull);
      expect(theme.success, isNotNull);
    });

    test('light theme has expected colors', () {
      final theme = Theme.light();
      expect(theme.primary, isNotNull);
      expect(theme.error, isNotNull);
      expect(theme.success, isNotNull);
    });

    test('copyWith creates modified theme', () {
      final theme = Theme.dark();
      final modified = theme.copyWith(primary: const AnsiColor(100));
      expect(modified.primary, equals(const AnsiColor(100)));
      // Other properties unchanged
      expect(modified.error, equals(theme.error));
    });

    test('setTheme changes current theme', () {
      final original = currentTheme;
      final newTheme = Theme.light();
      setTheme(newTheme);
      expect(currentTheme, equals(newTheme));
      // Restore
      setTheme(original);
    });
  });

  group('StaticWidget', () {
    test('renders static content', () {
      final widget = StaticWidget('Static content');
      expect(widget.view(), equals('Static content'));
    });

    test('has auto-generated id', () {
      final w1 = StaticWidget('a');
      final w2 = StaticWidget('b');
      expect(w1.id, startsWith('static-'));
      expect(w1.id, isNot(equals(w2.id)));
    });

    test('accepts custom id', () {
      final widget = StaticWidget('test', id: 'my-id');
      expect(widget.id, equals('my-id'));
    });
  });

  group('Composition', () {
    test('nested HBox and VBox', () {
      final layout = VBox(
        children: [
          Label('Header'),
          HBox(children: [Label('Left'), Label('Right')]),
          Label('Footer'),
        ],
      );

      final output = layout.view() as String;
      expect(output, contains('Header'));
      expect(output, contains('Left'));
      expect(output, contains('Right'));
      expect(output, contains('Footer'));
    });

    test('Container with HBox child', () {
      final layout = Container(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: HBox(children: [Label('A'), Label('B')]),
      );

      final output = layout.view() as String;
      expect(output, contains('A'));
      expect(output, contains('B'));
    });
  });
}

// Test helpers

class _TestMsg extends Msg {
  const _TestMsg();
}

class _CounterWidget extends Widget {
  int updateCount = 0;

  @override
  String get id => 'counter';

  @override
  (Widget, Cmd?) handleUpdate(Msg msg) {
    updateCount++;
    return (this, null);
  }

  @override
  Object view() => 'count: $updateCount';
}

class _CmdWidget extends Widget {
  @override
  String get id => 'cmd';

  @override
  (Widget, Cmd?) handleUpdate(Msg msg) {
    return (this, Cmd.none());
  }

  @override
  Object view() => '';
}

class _InitCmdWidget extends Widget {
  @override
  String get id => 'init-cmd';

  @override
  Cmd? handleInit() => Cmd.none();

  @override
  Object view() => '';
}

class _ParentWidget extends Widget {
  _ParentWidget({required this.children});

  @override
  final List<Widget> children;

  @override
  String get id => 'parent';

  @override
  Object view() => children.map((c) => c.view()).join();
}
