import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('DecisionSignal', () {
    test('has correct labels', () {
      expect(DecisionSignal.green.label, equals('OK'));
      expect(DecisionSignal.yellow.label, equals('WARN'));
      expect(DecisionSignal.red.label, equals('ALERT'));
    });
  });

  group('DisclosureLevel', () {
    test('has four levels', () {
      expect(DisclosureLevel.values, hasLength(4));
    });
  });

  group('EvidenceDirection', () {
    test('has three directions', () {
      expect(EvidenceDirection.values, hasLength(3));
      expect(EvidenceDirection.values, contains(EvidenceDirection.supporting));
      expect(EvidenceDirection.values, contains(EvidenceDirection.opposing));
      expect(EvidenceDirection.values, contains(EvidenceDirection.neutral));
    });
  });

  group('EvidenceTerm', () {
    test('creates with required fields', () {
      const term = EvidenceTerm(
        label: 'change_rate',
        factor: 3.5,
        direction: EvidenceDirection.supporting,
      );
      expect(term.label, equals('change_rate'));
      expect(term.factor, equals(3.5));
      expect(term.direction, equals(EvidenceDirection.supporting));
    });
  });

  group('DecisionDetails', () {
    test('creates with required fields', () {
      const details = DecisionDetails(
        logPosterior: 2.0,
        confidenceLow: 0.7,
        confidenceHigh: 0.95,
        expectedLoss: 0.1,
        lossAvoided: 0.4,
      );
      expect(details.logPosterior, equals(2.0));
      expect(details.confidenceLow, equals(0.7));
      expect(details.confidenceHigh, equals(0.95));
      expect(details.expectedLoss, equals(0.1));
      expect(details.lossAvoided, equals(0.4));
    });
  });

  group('DecisionCard', () {
    test('renders level 0: badge + action label', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecisionCard(
          data: const DecisionData(
            signal: DecisionSignal.green,
            actionLabel: 'full_redraw',
          ),
        ),
      );

      expect(tester.locateText('OK'), isNotNull);
      expect(tester.locateText('full_redraw'), isNotNull);
    });

    test('renders yellow signal as WARN', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecisionCard(
          data: const DecisionData(
            signal: DecisionSignal.yellow,
            actionLabel: 'review',
          ),
        ),
      );

      expect(tester.locateText('WARN'), isNotNull);
      expect(tester.locateText('review'), isNotNull);
    });

    test('renders red signal as ALERT', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecisionCard(
          data: const DecisionData(
            signal: DecisionSignal.red,
            actionLabel: 'abort',
          ),
        ),
      );

      expect(tester.locateText('ALERT'), isNotNull);
      expect(tester.locateText('abort'), isNotNull);
    });

    test('renders level 1: explanation', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecisionCard(
          data: const DecisionData(
            signal: DecisionSignal.green,
            actionLabel: 'proceed',
            level: DisclosureLevel.plainEnglish,
            explanation: 'High confidence in strategy selection.',
          ),
        ),
      );

      expect(tester.locateText('OK'), isNotNull);
      expect(tester.locateText('proceed'), isNotNull);
      expect(
        tester.locateText('High confidence in strategy selection.'),
        isNotNull,
      );
    });

    test('renders level 2: evidence terms', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecisionCard(
          data: const DecisionData(
            signal: DecisionSignal.green,
            actionLabel: 'full_redraw',
            level: DisclosureLevel.evidenceTerms,
            explanation: 'Good strategy.',
            evidence: [
              EvidenceTerm(
                label: 'change_rate',
                factor: 3.5,
                direction: EvidenceDirection.supporting,
              ),
              EvidenceTerm(
                label: 'frame_cost',
                factor: 0.8,
                direction: EvidenceDirection.opposing,
              ),
              EvidenceTerm(
                label: 'stability',
                factor: 1.0,
                direction: EvidenceDirection.neutral,
              ),
            ],
          ),
        ),
      );

      expect(tester.locateText('Evidence:'), isNotNull);
      expect(tester.locateText('+ change_rate: BF=3.50'), isNotNull);
      expect(tester.locateText('- frame_cost: BF=0.80'), isNotNull);
      expect(tester.locateText('~ stability: BF=1.00'), isNotNull);
    });

    test('renders level 3: full details', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecisionCard(
          data: const DecisionData(
            signal: DecisionSignal.green,
            actionLabel: 'full_redraw',
            level: DisclosureLevel.fullDetails,
            details: DecisionDetails(
              logPosterior: 2.0,
              confidenceLow: 0.7,
              confidenceHigh: 0.95,
              expectedLoss: 0.1,
              lossAvoided: 0.4,
            ),
          ),
        ),
      );

      expect(tester.locateText('OK'), isNotNull);
      // Check that stats line contains log_post
      final hasStats = tester.view.contains('log_post');
      expect(hasStats, isTrue, reason: 'Should contain log_post stats');
    });

    test('renders level 3 without lossAvoided', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecisionCard(
          data: const DecisionData(
            signal: DecisionSignal.green,
            actionLabel: 'proceed',
            level: DisclosureLevel.fullDetails,
            details: DecisionDetails(
              logPosterior: 1.5,
              confidenceLow: 0.6,
              confidenceHigh: 0.9,
              expectedLoss: 0.2,
            ),
          ),
        ),
      );

      final hasLoss = tester.view.contains('loss=');
      expect(hasLoss, isTrue);
      final hasAvoided = tester.view.contains('avoided=');
      expect(hasAvoided, isFalse);
    });

    test('minHeight for level 0', () {
      final card = DecisionCard(
        data: const DecisionData(
          signal: DecisionSignal.green,
          actionLabel: 'OK',
        ),
      );
      expect(card.minHeight, equals(3));
    });

    test('minHeight for level 1 with explanation', () {
      final card = DecisionCard(
        data: const DecisionData(
          signal: DecisionSignal.green,
          actionLabel: 'OK',
          level: DisclosureLevel.plainEnglish,
          explanation: 'Test explanation.',
        ),
      );
      expect(card.minHeight, equals(4));
    });

    test('minHeight for level 2 with evidence', () {
      final card = DecisionCard(
        data: const DecisionData(
          signal: DecisionSignal.green,
          actionLabel: 'OK',
          level: DisclosureLevel.evidenceTerms,
          evidence: [
            EvidenceTerm(
              label: 'e1',
              factor: 1.0,
              direction: EvidenceDirection.supporting,
            ),
            EvidenceTerm(
              label: 'e2',
              factor: 2.0,
              direction: EvidenceDirection.opposing,
            ),
          ],
        ),
      );
      // 3 base + 1 evidence header + 2 evidence lines = 6
      expect(card.minHeight, equals(6));
    });

    test('minHeight for level 3', () {
      final card = DecisionCard(
        data: const DecisionData(
          signal: DecisionSignal.green,
          actionLabel: 'OK',
          level: DisclosureLevel.fullDetails,
          details: DecisionDetails(
            logPosterior: 1.0,
            confidenceLow: 0.5,
            confidenceHigh: 0.9,
            expectedLoss: 0.1,
          ),
        ),
      );
      // 3 base + 2 bayesian = 5
      expect(card.minHeight, equals(5));
    });

    test('with square border', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecisionCard(
          data: const DecisionData(
            signal: DecisionSignal.green,
            actionLabel: 'OK',
          ),
          border: Border.normal,
        ),
      );

      expect(tester.locateText('OK'), isNotNull);
    });

    test('with custom background', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        DecisionCard(
          data: const DecisionData(
            signal: DecisionSignal.green,
            actionLabel: 'OK',
          ),
          background: Colors.black,
        ),
      );

      expect(tester.locateText('OK'), isNotNull);
    });
  });
}
