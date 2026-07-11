import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('ProgramRenderFeed', () {
    test('publishes live render events with native frames', () async {
      final feed = ProgramRenderFeed();
      final terminal = StringTerminal(terminalWidth: 12, terminalHeight: 4);
      final program = Program<_RenderFeedModel>(
        const _RenderFeedModel(),
        options: ProgramOptions(
          signalHandlers: false,
          altScreen: false,
          interceptor: feed,
        ),
        terminal: terminal,
      );

      final eventFuture = feed.stream.first.timeout(const Duration(seconds: 2));
      await program.run();
      final event = await eventFuture;

      expect(event.renderGeneration, greaterThanOrEqualTo(1));
      expect(event.degradationLevel, DegradationLevel.full);
      expect(event.nativeFrame, isNotNull);
      expect(event.nativeDelta, isNotNull);
      expect(event.nativeDelta!.isEmpty, isFalse);
      expect(event.nativeCellDelta, isNotNull);
      expect(event.nativeCellDelta!.isEmpty, isFalse);
      expect(event.nativeSpanDelta, isNotNull);
      expect(event.nativeSpanDelta!, isNotEmpty);
      expect(event.changeSummary.hasChanges, isTrue);
      expect(event.changeSummary.dirtyLineCount, greaterThan(0));
      expect(event.changeSummary.changedLineCount, greaterThan(0));
      expect(event.changeSummary.changedCellCount, greaterThan(0));
      expect(event.changeSummary.changedSpanCount, greaterThan(0));
      expect(event.nativeFrame!.width, equals(12));
      expect(
        event.nativeFrame!.lines.first.plainText.trimRight(),
        equals('hi'),
      );
    });
  });
}

final class _RenderFeedModel implements Model {
  const _RenderFeedModel();

  @override
  Cmd? init() => Cmd.message(const QuitMsg());

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  Object view() => const View(content: 'hi');
}
