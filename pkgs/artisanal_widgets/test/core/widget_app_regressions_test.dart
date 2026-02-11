import 'package:artisanal/style.dart' show AdaptiveColor, BasicColor;
import 'package:artisanal/tui.dart' show View;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('WidgetApp regressions', () {
    test('backgroundColorBuilder updates terminal View background', () {
      var active = const BasicColor('#111111');
      final app = w.WidgetApp(
        w.Text('hello'),
        backgroundColorBuilder: () => active,
      );

      final first = app.view();
      expect(first, isA<View>());
      expect(
        (first as View).backgroundColor,
        equals(const BasicColor('#111111')),
      );

      active = const BasicColor('#eeeeee');
      final second = app.view();
      expect(second, isA<View>());
      expect(
        (second as View).backgroundColor,
        equals(const BasicColor('#eeeeee')),
      );
    });

    test('backgroundColorBuilder uses post-build route background', () {
      var active = const BasicColor('#111111');
      final app = w.WidgetApp(
        _SetBackgroundInBuild(() {
          active = const BasicColor('#eeeeee');
        }),
        backgroundColorBuilder: () => active,
      );

      final first = app.view();
      expect(first, isA<View>());
      expect(
        (first as View).backgroundColor,
        equals(const BasicColor('#eeeeee')),
      );
    });

    test('AdaptiveColor background resolves with terminal dark-mode state', () {
      w.setHasDarkBackground(false);
      final app = w.WidgetApp(
        w.Text('hello'),
        backgroundColorBuilder: () => const AdaptiveColor(
          light: BasicColor('#f6f8fa'),
          dark: BasicColor('#0d1117'),
        ),
      );

      final lightView = app.view() as View;
      expect(lightView.backgroundColor, equals(const BasicColor('#f6f8fa')));

      w.setHasDarkBackground(true);
      final darkView = app.view() as View;
      expect(darkView.backgroundColor, equals(const BasicColor('#0d1117')));
    });

    test('build exceptions render TUIErrorWidget fallback', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(_ThrowInBuild());

      expect(tester.find.text('Build failed in _ThrowInBuild:'), isTrue);
      expect(tester.find.text('boom from build'), isTrue);
    });
  });
}

class _ThrowInBuild extends w.StatelessWidget {
  @override
  w.Widget build(w.BuildContext context) {
    throw StateError('boom from build');
  }
}

class _SetBackgroundInBuild extends w.StatelessWidget {
  _SetBackgroundInBuild(this.onBuild);

  final void Function() onBuild;

  @override
  w.Widget build(w.BuildContext context) {
    onBuild();
    return w.Text('ok');
  }
}
