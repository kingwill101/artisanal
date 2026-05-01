import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('WidgetStormProfile', () {
    test('keyboard storms generate deterministic key steps', () {
      final profile = WidgetStormProfile.keyboardStorm(
        count: 4,
        seed: 42,
        keyAlphabet: 'a',
      );

      final first = profile.generate();
      final second = profile.generate();

      expect(
        first.map((step) => step.toString()),
        equals(<String>[
          '#0 key "a"',
          '#1 key "a"',
          '#2 key "a"',
          '#3 key "a"',
        ]),
      );
      expect(
        first.map((step) => step.toJson()).toList(),
        equals(second.map((step) => step.toJson()).toList()),
      );
    });

    test('resize sweep includes start and end sizes', () {
      final profile = WidgetStormProfile.resizeSweep(
        startWidth: 40,
        startHeight: 10,
        endWidth: 100,
        endHeight: 30,
        steps: 3,
      );

      final steps = profile.generate();

      expect(steps.map((step) => '${step.width}x${step.height}'), [
        '40x10',
        '70x20',
        '100x30',
      ]);
    });

    test('runStorm applies steps and records frames', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());
      await tester.pumpWidget(_TypedRecorder());

      final result = tester.runStorm(
        WidgetStormProfile.keyboardStorm(
          count: 3,
          seed: 7,
          keyAlphabet: 'x',
          captureFrames: true,
        ),
      );

      expect(result.passed, isTrue);
      expect(result.completedSteps, 3);
      expect(result.frames, hasLength(4));
      expect(tester.find.text('typed: xxx'), isTrue);
    });
  });

  group('FlickerAnalyzer', () {
    test('accepts synchronized visible output', () {
      final analysis = FlickerAnalyzer.analyze(
        '\x1b[?2026hhello\x1b[?2026l',
        requireSynchronizedOutput: true,
      );

      expect(analysis.isFlickerFree, isTrue);
      expect(analysis.stats.frameStarts, 1);
      expect(analysis.stats.frameEnds, 1);
      expect(analysis.stats.syncCoverage, 1.0);
    });

    test('reports visible sync gaps when required', () {
      final analysis = FlickerAnalyzer.analyze(
        'hello',
        requireSynchronizedOutput: true,
      );

      expect(analysis.isFlickerFree, isFalse);
      expect(
        analysis.events.any((event) => event.type == FlickerEventType.syncGap),
        isTrue,
      );
      expect(
        () => analysis.assertFlickerFree(),
        throwsA(isA<FlickerFailure>()),
      );
    });

    test('reports partial clears as warnings', () {
      final analysis = FlickerAnalyzer.analyze('\x1b[?2026h\x1b[2J\x1b[?2026l');

      expect(analysis.isFlickerFree, isTrue);
      expect(
        analysis.events.any(
          (event) => event.type == FlickerEventType.partialClear,
        ),
        isTrue,
      );
      expect(analysis.stats.warningCount, 1);
    });
  });

  group('HarnessArtifactManifest', () {
    test('validates required fields and oversize entries', () {
      final missing = HarnessArtifactEntry(
        artifactClass: HarnessArtifactClass.runMeta,
        path: 'run_meta.json',
        sizeBytes: 12,
        fields: <String>{'runId'},
      ).validate();

      expect(missing.passes, isFalse);
      expect(missing.missingFields, contains('createdAt'));
      expect(missing.oversize, isFalse);

      final oversize = HarnessArtifactEntry(
        artifactClass: HarnessArtifactClass.summary,
        path: 'summary.txt',
        sizeBytes: HarnessArtifactClass.summary.maxSizeBytes + 1,
        fields: <String>{'runId', 'createdAt'},
      ).validate();

      expect(oversize.passes, isFalse);
      expect(oversize.missingFields, isEmpty);
      expect(oversize.oversize, isTrue);
    });

    test('detects redaction-sensitive fields', () {
      expect(shouldRedactHarnessField('api_key'), isTrue);
      expect(shouldRedactHarnessField('workingDir'), isTrue);
      expect(shouldRedactHarnessField('frameCount'), isFalse);
    });
  });

  group('WidgetGauntlet', () {
    test('runs storm profiles and produces a valid manifest', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final gauntlet = WidgetGauntlet(
        config: WidgetGauntletConfig(
          runId: 'gauntlet-test',
          stormProfiles: <WidgetStormProfile>[
            WidgetStormProfile.keyboardStorm(
              count: 3,
              seed: 1,
              keyAlphabet: 'a',
              captureFrames: true,
            ),
          ],
          analyzeFlicker: true,
          nowProvider: () => DateTime.utc(2026, 5, 1),
        ),
      );

      final result = await gauntlet.run(
        tester: tester,
        widget: _TypedRecorder(),
        width: 40,
        height: 10,
      );

      expect(result.passed, isTrue);
      expect(result.stormResults, hasLength(1));
      expect(result.flickerAnalysis, isNotNull);
      expect(result.manifest.validate(), isEmpty);
      expect(result.manifest.entries, hasLength(5));
      expect(tester.find.text('typed: aaa'), isTrue);
      expect(
        result.summaryLines().first,
        'WidgetGauntlet gauntlet-test: passed',
      );
    });
  });
}

class _TypedRecorder extends w.StatefulWidget {
  _TypedRecorder();

  @override
  w.State createState() => _TypedRecorderState();
}

class _TypedRecorderState extends w.State<_TypedRecorder> {
  var _typed = '';

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg case tui.KeyMsg(:final key) when key.char != null) {
      setState(() => _typed += key.char!);
    } else if (msg case tui.PasteMsg(:final content)) {
      setState(() => _typed += content);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('typed: $_typed');
  }
}
