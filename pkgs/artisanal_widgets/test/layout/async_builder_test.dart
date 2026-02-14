import 'dart:async';

import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('FutureBuilder', () {
    test('renders waiting then completed data', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final completer = Completer<String>();
      await tester.pumpWidget(
        FutureBuilder<String>(
          future: completer.future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == AsyncConnectionState.waiting) {
              return Text('waiting');
            }
            if (snapshot.hasData) {
              return Text('data:${snapshot.data}');
            }
            return Text('idle');
          },
        ),
      );

      expect(tester.find.text('waiting'), isTrue);
      completer.complete('ready');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      tester.sendKey(' ');
      expect(tester.find.text('data:ready'), isTrue);
    });

    test('ignores stale future completion after widget update', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final first = Completer<String>();
      final second = Completer<String>();
      var useSecond = false;

      Widget build() {
        return FutureBuilder<String>(
          future: useSecond ? second.future : first.future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('value:${snapshot.data}');
            }
            if (snapshot.hasError) {
              return Text('error');
            }
            return Text('waiting');
          },
        );
      }

      await tester.pumpWidget(build());
      expect(tester.find.text('waiting'), isTrue);

      useSecond = true;
      await tester.pumpWidget(build());
      second.complete('second');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      tester.sendKey(' ');
      expect(tester.find.text('value:second'), isTrue);

      first.complete('stale');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      tester.sendKey(' ');
      expect(tester.find.text('value:second'), isTrue);
      expect(tester.find.text('value:stale'), isFalse);
    });
  });

  group('StreamBuilder', () {
    test('renders stream data and done state', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final controller = StreamController<int>();
      await tester.pumpWidget(
        StreamBuilder<int>(
          stream: controller.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == AsyncConnectionState.waiting) {
              return Text('waiting');
            }
            if (snapshot.connectionState == AsyncConnectionState.done) {
              return Text('done:${snapshot.data}');
            }
            if (snapshot.hasData) {
              return Text('data:${snapshot.data}');
            }
            return Text('idle');
          },
        ),
      );

      expect(tester.find.text('waiting'), isTrue);

      controller.add(7);
      await Future<void>.delayed(Duration.zero);
      tester.sendKey(' ');
      expect(tester.find.text('data:7'), isTrue);

      await controller.close();
      await Future<void>.delayed(Duration.zero);
      tester.sendKey(' ');
      expect(tester.find.text('done:7'), isTrue);
    });

    test('ignores events from replaced stream', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final first = StreamController<String>();
      final second = StreamController<String>();
      var useSecond = false;

      Widget build() {
        return StreamBuilder<String>(
          stream: useSecond ? second.stream : first.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('value:${snapshot.data}');
            }
            return Text('waiting');
          },
        );
      }

      await tester.pumpWidget(build());
      first.add('one');
      await Future<void>.delayed(Duration.zero);
      tester.sendKey(' ');
      expect(tester.find.text('value:one'), isTrue);

      useSecond = true;
      await tester.pumpWidget(build());
      second.add('two');
      await Future<void>.delayed(Duration.zero);
      tester.sendKey(' ');
      expect(tester.find.text('value:two'), isTrue);

      first.add('stale');
      await Future<void>.delayed(Duration.zero);
      tester.sendKey(' ');
      expect(tester.find.text('value:two'), isTrue);
      expect(tester.find.text('value:stale'), isFalse);

      await first.close();
      await second.close();
    });
  });
}
