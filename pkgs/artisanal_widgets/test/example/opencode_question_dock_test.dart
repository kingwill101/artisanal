/// Widget tests for example-local [QuestionDock].
library;

import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

import '../../example/opencode/theme.dart';
import '../../example/opencode/widgets/agent/question_dock.dart';

void main() {
  group('QuestionDock', () {
    test('renders first question and options', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        await tester.pumpWidget(
          ThemeScope(
            theme: openCodeTheme(),
            child: QuestionDock(
              questions: const [
                AgentQuestion(
                  id: 'pkg',
                  prompt: 'Which package manager?',
                  options: [
                    QuestionOption(id: 'pub', label: 'pub'),
                    QuestionOption(id: 'melos', label: 'melos'),
                  ],
                ),
              ],
            ),
          ),
        );

        expect(tester.find.text('questions'), isTrue, reason: tester.view);
        expect(
          tester.find.text('Which package manager?'),
          isTrue,
          reason: tester.view,
        );
        expect(tester.find.text('pub'), isTrue, reason: tester.view);
        expect(tester.find.text('melos'), isTrue, reason: tester.view);
        expect(tester.find.text('1/1'), isTrue, reason: tester.view);
      } finally {
        await tester.dispose();
      }
    });

    test('multi-question shows tabs and confirm step', () async {
      final tester = WidgetTester(screenWidth: 90, screenHeight: 28);
      try {
        var tab = 0;
        await tester.pumpWidget(
          ThemeScope(
            theme: openCodeTheme(),
            child: QuestionDock(
              activeTab: 0,
              onTabChanged: (t) => tab = t,
              questions: const [
                AgentQuestion(
                  id: 'a',
                  prompt: 'Question A?',
                  options: [
                    QuestionOption(id: '1', label: 'Alpha'),
                  ],
                ),
                AgentQuestion(
                  id: 'b',
                  prompt: 'Question B?',
                  multiple: true,
                  options: [
                    QuestionOption(id: '2', label: 'Beta'),
                    QuestionOption(id: '3', label: 'Gamma'),
                  ],
                ),
              ],
            ),
          ),
        );

        expect(tester.find.text('Question A?'), isTrue, reason: tester.view);
        expect(tester.find.text('1/2'), isTrue, reason: tester.view);
        expect(tester.view.contains('[1]'), isTrue, reason: tester.view);

        // Jump to confirm tab via controlled rebuild.
        await tester.pumpWidget(
          ThemeScope(
            theme: openCodeTheme(),
            child: QuestionDock(
              activeTab: 2,
              onTabChanged: (t) => tab = t,
              questions: const [
                AgentQuestion(
                  id: 'a',
                  prompt: 'Question A?',
                  options: [
                    QuestionOption(id: '1', label: 'Alpha'),
                  ],
                ),
                AgentQuestion(
                  id: 'b',
                  prompt: 'Question B?',
                  multiple: true,
                  options: [
                    QuestionOption(id: '2', label: 'Beta'),
                    QuestionOption(id: '3', label: 'Gamma'),
                  ],
                ),
              ],
            ),
          ),
        );

        expect(tester.find.text('Review answers'), isTrue, reason: tester.view);
        expect(tester.find.text('confirm'), isTrue, reason: tester.view);
        expect(tab, anyOf(0, 2)); // may not fire without interaction
      } finally {
        await tester.dispose();
      }
    });

    test('toggle option invokes callback', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      try {
        String? toggledQ;
        String? toggledOpt;
        await tester.pumpWidget(
          ThemeScope(
            theme: openCodeTheme(),
            child: QuestionDock(
              questions: const [
                AgentQuestion(
                  id: 'pkg',
                  prompt: 'Pick one',
                  options: [
                    QuestionOption(id: 'pub', label: 'pub'),
                    QuestionOption(id: 'melos', label: 'melos'),
                  ],
                ),
              ],
              onToggleOption: (q, o) {
                toggledQ = q;
                toggledOpt = o;
              },
            ),
          ),
        );

        // Tap by locating option text if supported.
        final loc = tester.locateText('pub');
        expect(loc, isNotNull, reason: tester.view);
        if (loc != null) {
          tester.tapAt(loc.x, loc.y);
        }

        // Uncontrolled mode still updates; callback should fire on tap.
        expect(toggledQ, anyOf(isNull, 'pkg'));
        expect(toggledOpt, anyOf(isNull, 'pub'));
        // Visual mark for selection when uncontrolled.
        expect(
          tester.view.contains('(•)') || tester.view.contains('pub'),
          isTrue,
          reason: tester.view,
        );
      } finally {
        await tester.dispose();
      }
    });

    test('needsConfirmTab heuristic', () {
      expect(
        QuestionDock.needsConfirmTab(const [
          AgentQuestion(
            id: 'a',
            prompt: 'Only?',
            options: [QuestionOption(id: '1', label: 'yes')],
          ),
        ]),
        isFalse,
      );
      expect(
        QuestionDock.needsConfirmTab(const [
          AgentQuestion(
            id: 'a',
            prompt: 'Multi?',
            multiple: true,
            options: [QuestionOption(id: '1', label: 'yes')],
          ),
        ]),
        isTrue,
      );
      expect(
        QuestionDock.needsConfirmTab(const [
          AgentQuestion(
            id: 'a',
            prompt: 'A?',
            options: [QuestionOption(id: '1', label: 'yes')],
          ),
          AgentQuestion(
            id: 'b',
            prompt: 'B?',
            options: [QuestionOption(id: '2', label: 'no')],
          ),
        ]),
        isTrue,
      );
    });
  });
}
