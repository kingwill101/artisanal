import 'dart:async';

import 'package:artisanal/runtime.dart' as tui;
import 'package:artisanal_widgets/src/widgets/core/element.dart'
    show ElementTree, elementOf;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

ElementTree boundedTree(Widget root, {double width = 80, double height = 24}) {
  final tree = ElementTree(root);
  tree.setRootConstraints(BoxConstraints(maxWidth: width, maxHeight: height));
  addTearDown(tree.unmount);
  return tree;
}

void main() {
  test(
    'layout-created child initialization runs without another input event',
    () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 5);
      addTearDown(tester.dispose);
      final initialized = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        LayoutBuilder(
          builder: (context, constraints) => _InitProbe(
            onRun: () {
              calls++;
              if (!initialized.isCompleted) initialized.complete();
            },
          ),
        ),
      );
      await initialized.future.timeout(const Duration(seconds: 2));
      expect(calls, 1);
      tester.resize(20, 5);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1, reason: 'a retained child must not initialize twice');
    },
  );

  test('uses the padded parent content box, not MediaQuery dimensions', () {
    late BoxConstraints received;
    final tree = boundedTree(
      MediaQuery(
        data: MediaQueryData(size: const Size(120, 40)),
        child: Container(
          width: 24,
          height: 8,
          padding: const EdgeInsets.all(2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              received = constraints;
              return Text('content');
            },
          ),
        ),
      ),
    );
    expect(tree.render(), contains('content'));
    expect(received, BoxConstraints.tight(const Size(20, 4)));
  });

  test(
    'resize-created initialization runs after layout without another event',
    () async {
      final tester = WidgetTester(screenWidth: 30, screenHeight: 5);
      addTearDown(tester.dispose);
      final wide = Completer<void>();
      final narrow = Completer<void>();
      await tester.pumpWidget(
        LayoutBuilder(
          builder: (context, constraints) {
            final small = constraints.maxWidth < 25;
            return _InitProbe(
              key: ValueKey(small),
              onRun: () {
                final completed = small ? narrow : wide;
                if (!completed.isCompleted) completed.complete();
              },
            );
          },
        ),
      );
      await wide.future.timeout(const Duration(seconds: 2));
      tester.resize(20, 5);
      await narrow.future.timeout(const Duration(seconds: 2));
    },
  );

  test(
    'mixed finite and stream initialization survives late mounting',
    () async {
      final tester = WidgetTester();
      addTearDown(tester.dispose);
      final finite = Completer<void>();
      final managed = Completer<void>();
      await tester.pumpWidget(
        LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              _InitProbe(
                onRun: () {
                  if (!finite.isCompleted) finite.complete();
                },
              ),
              _ManagedProbe(
                onReady: () {
                  if (!managed.isCompleted) managed.complete();
                },
              ),
            ],
          ),
        ),
      );
      await Future.wait([
        finite.future,
        managed.future,
      ]).timeout(const Duration(seconds: 2));
    },
  );

  test('flex allocation and parent resize reach the builder', () {
    final seen = <BoxConstraints>[];
    final builder = LayoutBuilder(
      builder: (context, constraints) {
        seen.add(constraints);
        return Text('body');
      },
    );
    Widget root(int width) => Row(
      width: width,
      gap: 2,
      children: [
        SizedBox(width: 10, child: Text('nav')),
        Expanded(child: builder),
      ],
    );
    final tree = boundedTree(root(40));
    tree.render();
    expect(seen.last.minWidth, 28);
    expect(seen.last.maxWidth, 28);
    tree.update(root(32));
    tree.render();
    expect(seen.last.minWidth, 20);
    expect(seen.last.maxWidth, 20);
  });

  test('unchanged constraints do not invoke the builder again', () {
    var calls = 0;
    final builder = LayoutBuilder(
      builder: (context, constraints) {
        calls++;
        return Text('stable');
      },
    );
    final tree = boundedTree(SizedBox(width: 20, height: 3, child: builder));
    expect(calls, 0, reason: 'building is deferred until layout');
    tree.render();
    final initialCalls = calls;
    final render = elementOf(builder)!.renderObject!;
    render.layout(render.constraints);
    tree.render();
    expect(calls, initialCalls);
  });

  test('configuration changes rebuild under unchanged constraints', () {
    Widget root(String label) => SizedBox(
      width: 20,
      height: 3,
      child: LayoutBuilder(
        key: const ValueKey('builder'),
        builder: (context, constraints) => Text(label),
      ),
    );
    final tree = boundedTree(root('before'));
    expect(tree.render(), contains('before'));
    tree.update(root('after'));
    expect(tree.render(), contains('after'));
    expect(tree.render(), isNot(contains('before')));
  });

  test('inherited updates preserve keyed child state at equal constraints', () {
    var calls = 0;
    var mounts = 0;
    late _CounterState state;
    final builder = LayoutBuilder(
      builder: (context, constraints) {
        calls++;
        final value = context
            .dependOnInheritedWidgetOfExactType<_Value>()!
            .value;
        return _Counter(
          key: const ValueKey('counter'),
          label: '$value',
          onMount: (mounted) {
            state = mounted;
            mounts++;
          },
        );
      },
    );
    Widget root(int value, int width) => _Value(
      value: value,
      child: SizedBox(width: width, height: 3, child: builder),
    );
    final tree = boundedTree(root(1, 20));
    expect(tree.render(), contains('1:0'));
    final originalState = state;
    final initialCalls = calls;
    state.increment();
    expect(tree.render(), contains('1:1'));
    expect(calls, initialCalls);
    tree.update(root(2, 20));
    expect(tree.render(), contains('2:1'));
    expect(state, same(originalState));
    expect(mounts, 1);
    tree.update(root(2, 12));
    expect(tree.render(), contains('2:1'));
    expect(state, same(originalState));
    expect(mounts, 1);
  });

  test(
    'unbounded parent axes are passed through without viewport fallback',
    () {
      late BoxConstraints received;
      final tree = boundedTree(
        Row(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                received = constraints;
                return Text('x');
              },
            ),
          ],
        ),
      );
      tree.render();
      expect(received.hasBoundedWidth, isFalse);
      expect(received.maxHeight, 24);
    },
  );

  test('recursive layout from a builder is rejected rather than queued', () {
    late LayoutBuilder builder;
    builder = LayoutBuilder(
      builder: (context, constraints) {
        expect(
          () => elementOf(
            builder,
          )!.renderObject!.layout(BoxConstraints.tight(const Size(1, 1))),
          throwsStateError,
        );
        expect(elementOf(builder)!.renderObject!.constraints, constraints);
        return Text('guarded');
      },
    );
    final tree = boundedTree(builder);
    expect(tree.render(), contains('guarded'));
  });

  test('builder errors use the normal error boundary and can recover', () {
    Widget root(bool fail) => LayoutBuilder(
      key: const ValueKey('builder'),
      builder: (context, constraints) {
        if (fail) throw StateError('layout builder failure');
        return Text('recovered');
      },
    );
    final tree = boundedTree(root(true));
    expect(tree.render(), contains('layout builder failure'));
    tree.update(root(false));
    expect(tree.render(), contains('recovered'));
  });

  test(
    'standalone view has an unbounded layout context instead of empty output',
    () {
      final builder = LayoutBuilder(
        builder: (context, constraints) {
          expect(constraints.hasBoundedWidth, isFalse);
          return Text('standalone');
        },
      );
      expect(builder.view().toString(), contains('standalone'));
    },
  );
}

class _Value extends InheritedWidget {
  _Value({required this.value, required super.child});
  final int value;

  @override
  bool updateShouldNotify(_Value oldWidget) => value != oldWidget.value;
}

class _Counter extends StatefulWidget {
  _Counter({required this.label, required this.onMount, super.key});
  final String label;
  final void Function(_CounterState) onMount;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var count = 0;

  @override
  void initState() {
    super.initState();
    widget.onMount(this);
  }

  void increment() => setState(() => count++);

  @override
  Widget build(BuildContext context) => Text('${widget.label}:$count');
}

class _InitProbe extends StatefulWidget {
  _InitProbe({required this.onRun, super.key});
  final void Function() onRun;
  @override
  State<_InitProbe> createState() => _InitProbeState();
}

class _InitProbeState extends State<_InitProbe> {
  @override
  tui.Cmd? handleInit() => tui.Cmd(() async {
    widget.onRun();
    return null;
  });
  @override
  Widget build(BuildContext context) => Text('ready');
}

class _ManagedReady extends tui.Msg {
  const _ManagedReady();
}

class _ManagedProbe extends StatefulWidget {
  _ManagedProbe({required this.onReady});
  final void Function() onReady;
  @override
  State<_ManagedProbe> createState() => _ManagedProbeState();
}

class _ManagedProbeState extends State<_ManagedProbe> {
  @override
  tui.Cmd? handleInit() => tui.Cmd.listen<int>(
    Stream<int>.value(1),
    onData: (_) => const _ManagedReady(),
  );
  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is _ManagedReady) widget.onReady();
    return null;
  }

  @override
  Widget build(BuildContext context) => Text('stream');
}
