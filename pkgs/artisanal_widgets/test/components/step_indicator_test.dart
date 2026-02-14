import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  group('StepItem', () {
    test('fromMap parses label and defaults', () {
      final item = StepItem.fromMap({'label': 'Install'});
      expect(item.label, equals('Install'));
      expect(item.status, equals(StepStatus.pending));
      expect(item.description, isNull);
    });

    test('fromMap parses all status values', () {
      expect(
        StepItem.fromMap({'label': 'a', 'status': 'pending'}).status,
        equals(StepStatus.pending),
      );
      expect(
        StepItem.fromMap({'label': 'a', 'status': 'active'}).status,
        equals(StepStatus.active),
      );
      expect(
        StepItem.fromMap({'label': 'a', 'status': 'completed'}).status,
        equals(StepStatus.completed),
      );
      expect(
        StepItem.fromMap({'label': 'a', 'status': 'error'}).status,
        equals(StepStatus.error),
      );
      expect(
        StepItem.fromMap({'label': 'a', 'status': 'skipped'}).status,
        equals(StepStatus.skipped),
      );
    });

    test('fromMap defaults unknown status to pending', () {
      final item = StepItem.fromMap({'label': 'x', 'status': 'unknown'});
      expect(item.status, equals(StepStatus.pending));
    });

    test('fromMap parses description', () {
      final item = StepItem.fromMap({
        'label': 'Build',
        'description': 'Compile the project',
      });
      expect(item.description, equals('Compile the project'));
    });

    test('fromMap defaults label to empty string', () {
      final item = StepItem.fromMap({});
      expect(item.label, equals(''));
    });
  });

  group('StepIndicator', () {
    test('renders step labels', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StepIndicator(
          steps: [
            StepItem(label: 'Install'),
            StepItem(label: 'Configure'),
            StepItem(label: 'Deploy'),
          ],
        ),
      );

      expect(tester.find.text('Install'), isTrue);
      expect(tester.find.text('Configure'), isTrue);
      expect(tester.find.text('Deploy'), isTrue);
    });

    test('renders pending status icon', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StepIndicator(
          steps: [StepItem(label: 'Pending', status: StepStatus.pending)],
        ),
      );

      expect(tester.find.text('○'), isTrue);
    });

    test('renders active status icon', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StepIndicator(
          steps: [StepItem(label: 'Active', status: StepStatus.active)],
        ),
      );

      expect(tester.find.text('●'), isTrue);
    });

    test('renders completed status icon', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StepIndicator(
          steps: [StepItem(label: 'Done', status: StepStatus.completed)],
        ),
      );

      expect(tester.find.text('✓'), isTrue);
    });

    test('renders error status icon', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StepIndicator(
          steps: [StepItem(label: 'Failed', status: StepStatus.error)],
        ),
      );

      expect(tester.find.text('✗'), isTrue);
    });

    test('renders skipped status icon', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StepIndicator(
          steps: [StepItem(label: 'Skipped', status: StepStatus.skipped)],
        ),
      );

      expect(tester.find.text('⊘'), isTrue);
    });

    test('renders connector between steps', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StepIndicator(
          steps: [
            StepItem(label: 'First'),
            StepItem(label: 'Second'),
          ],
        ),
      );

      // Connector line between steps.
      expect(tester.find.text('│'), isTrue);
    });

    test('no connector after last step', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 10);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(StepIndicator(steps: [StepItem(label: 'Only')]));

      expect(tester.find.text('Only'), isTrue);
      // Single step should have no connector.
      expect(tester.find.text('│'), isFalse);
    });

    test('renders step description', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StepIndicator(
          steps: [
            StepItem(
              label: 'Install',
              description: 'Download and install dependencies',
            ),
          ],
        ),
      );

      expect(tester.find.text('Install'), isTrue);
      expect(tester.find.text('Download and install dependencies'), isTrue);
    });

    test('current index overrides step statuses', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StepIndicator(
          current: 1,
          steps: [
            StepItem(label: 'Step1', status: StepStatus.pending),
            StepItem(label: 'Step2', status: StepStatus.pending),
            StepItem(label: 'Step3', status: StepStatus.pending),
          ],
        ),
      );

      // Step 0 (before current) → completed (✓).
      expect(tester.find.text('✓'), isTrue);
      // Step 1 (current) → active (●).
      expect(tester.find.text('●'), isTrue);
      // Step 2 (after current) → pending (○).
      expect(tester.find.text('○'), isTrue);
    });

    test('current at 0 marks first as active, rest as pending', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        StepIndicator(
          current: 0,
          steps: [
            StepItem(label: 'A'),
            StepItem(label: 'B'),
          ],
        ),
      );

      expect(tester.find.text('●'), isTrue); // A is active
      expect(tester.find.text('○'), isTrue); // B is pending
    });

    test('empty steps list renders without error', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(StepIndicator(steps: []));

      // Should render without throwing — empty step list produces empty output.
    });

    test('StepStatus enum has 5 values', () {
      expect(StepStatus.values, hasLength(5));
      expect(StepStatus.values, contains(StepStatus.pending));
      expect(StepStatus.values, contains(StepStatus.active));
      expect(StepStatus.values, contains(StepStatus.completed));
      expect(StepStatus.values, contains(StepStatus.error));
      expect(StepStatus.values, contains(StepStatus.skipped));
    });

    test('has unique id', () {
      final s1 = StepIndicator(steps: []);
      final s2 = StepIndicator(steps: []);
      expect(s1.id, isNot(equals(s2.id)));
    });

    test('respects key', () {
      final s = StepIndicator(key: ValueKey('step-key'), steps: []);
      expect(s.id, equals('step-key'));
    });
  });
}
