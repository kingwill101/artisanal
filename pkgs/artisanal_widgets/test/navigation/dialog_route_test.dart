import 'package:artisanal/terminal.dart' show KeyType;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

/// Zero-duration animation style — animation completes synchronously.
final _zeroAnimation = w.AnimationStyle(
  duration: Duration.zero,
  reverseDuration: Duration.zero,
);

void main() {
  group('DialogRoute', () {
    test('creates one overlay entry', () {
      final route = w.DialogRoute<void>(
        builder: (_) => w.Text('dialog'),
        settings: w.RouteSettings(name: '/test-dialog'),
      );
      route.install();
      expect(route.overlayEntries.length, 1);
      expect(route.overlayEntries.first.opaque, isFalse);
      expect(route.overlayEntries.first.maintainState, isTrue);
    });

    test('has /dialog route name constant', () {
      expect(w.DialogRoute.routeName, '/dialog');
    });
  });

  group('showDialog', () {
    test('renders dialog on top of home', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _ShowDialogPage(
            label: 'Home',
            dialogLabel: 'Hello Dialog',
            animationStyle: _zeroAnimation,
          ),
        ),
      );

      expect(tester.find.text('Home'), isTrue);
      expect(tester.find.text('Hello Dialog'), isFalse);

      // Press 'd' to show the dialog.
      tester.sendKey('d');

      expect(tester.find.text('Hello Dialog'), isTrue);
    });

    test('escape dismisses the dialog', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _ShowDialogPage(
            label: 'Home',
            dialogLabel: 'Dialog',
            animationStyle: _zeroAnimation,
          ),
        ),
      );

      // Show dialog.
      tester.sendKey('d');
      expect(tester.find.text('Dialog'), isTrue);

      // Escape should dismiss it.
      tester.sendSpecialKey(KeyType.escape);
      tester.sendKey(' ');

      expect(tester.find.text('Dialog'), isFalse);
      expect(tester.find.text('Home'), isTrue);
    });

    test('barrier tap dismisses the dialog', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _ShowDialogPage(
            label: 'Home',
            dialogLabel: 'Tap Test',
            animationStyle: _zeroAnimation,
          ),
        ),
      );

      tester.sendKey('d');
      expect(tester.find.text('Tap Test'), isTrue);

      // Escape dismisses (same as barrier tap).
      tester.sendSpecialKey(KeyType.escape);
      tester.sendKey(' ');

      expect(tester.find.text('Tap Test'), isFalse);
    });

    test('barrierDismissible=false prevents dismissal on escape', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Navigator(
          home: _ShowDialogPage(
            label: 'Home',
            dialogLabel: 'Sticky',
            barrierDismissible: false,
            animationStyle: _zeroAnimation,
          ),
        ),
      );

      tester.sendKey('d');
      expect(tester.find.text('Sticky'), isTrue);

      // Escape should NOT dismiss when barrierDismissible is false.
      tester.sendSpecialKey(KeyType.escape);
      tester.sendKey(' ');

      expect(tester.find.text('Sticky'), isTrue);
    });

    test('showDialog returns Future that completes with pop result',
        () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      String? dialogResult;

      await tester.pumpWidget(
        w.Navigator(
          home: _ResultDialogPage(
            label: 'Home',
            result: 'done',
            animationStyle: _zeroAnimation,
            onDialogCreated: (f) {
              f.then((r) {
                dialogResult = r;
              });
            },
          ),
        ),
      );

      expect(tester.find.text('Home'), isTrue);

      // Show the dialog.
      tester.sendKey('d');
      expect(tester.find.text('Dialog'), isTrue);

      // Pop with result via 'b'.
      tester.sendKey('b');

      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      tester.sendKey(' ');

      expect(tester.find.text('Home'), isTrue);
      expect(dialogResult, 'done');
    });

    test('dismiss via null pop returns null', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      String? dialogResult = 'not-null';
      await tester.pumpWidget(
        w.Navigator(
          home: _ResultDialogPage(
            label: 'Home',
            result: null,
            animationStyle: _zeroAnimation,
            onDialogCreated: (f) {
              f.then((r) {
                dialogResult = r;
              });
            },
          ),
        ),
      );

      tester.sendKey('d');
      tester.sendKey('b');

      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      tester.sendKey(' ');

      expect(dialogResult, isNull);
    });
  });
}

/// A page that shows a dialog when 'd' is pressed.
class _ShowDialogPage extends w.StatefulWidget {
  _ShowDialogPage({
    required this.label,
    required this.dialogLabel,
    this.barrierDismissible = true,
    this.animationStyle,
  });

  final String label;
  final String dialogLabel;
  final bool barrierDismissible;
  final w.AnimationStyle? animationStyle;

  @override
  w.State<_ShowDialogPage> createState() => _ShowDialogPageState();
}

class _ShowDialogPageState extends w.State<_ShowDialogPage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      if (String.fromCharCodes(msg.key.runes) == 'd') {
        w.showDialog<void>(
          context: context,
          builder: (_) => w.Text(widget.dialogLabel),
          barrierDismissible: widget.barrierDismissible,
          animationStyle: widget.animationStyle,
        );
        return tui.Cmd.none();
      }
    }
    return null;
  }
}

/// A page that shows a dialog that can pop with a result.
class _ResultDialogPage extends w.StatefulWidget {
  _ResultDialogPage({
    required this.label,
    this.result,
    this.animationStyle,
    this.onDialogCreated,
  });

  final String label;
  final String? result;
  final w.AnimationStyle? animationStyle;
  final void Function(Future<String?>)? onDialogCreated;

  @override
  w.State<_ResultDialogPage> createState() => _ResultDialogPageState();
}

class _ResultDialogPageState extends w.State<_ResultDialogPage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text(widget.label);
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      final char = String.fromCharCodes(msg.key.runes);
      if (char == 'd') {
        final future = w.showDialog<String>(
          context: context,
          builder: (_) => _PopResultPage(result: widget.result),
          animationStyle: widget.animationStyle,
        );
        widget.onDialogCreated?.call(future);
        return tui.Cmd.none();
      }
    }
    return null;
  }
}

class _PopResultPage extends w.StatefulWidget {
  _PopResultPage({this.result});

  final String? result;

  @override
  w.State<_PopResultPage> createState() => _PopResultPageState();
}

class _PopResultPageState extends w.State<_PopResultPage> {
  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('Dialog');
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.type == KeyType.runes) {
      if (String.fromCharCodes(msg.key.runes) == 'b') {
        w.Navigator.of(context).pop(widget.result);
        return null;
      }
    }
    return null;
  }
}
