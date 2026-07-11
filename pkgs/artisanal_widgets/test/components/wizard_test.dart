import 'package:artisanal/terminal.dart' as terminal_keys;
import 'package:artisanal/tui.dart' show InterruptMsg, KeyMsg;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('Wizard', () {
    test(
      'completes text, select, and multi-select steps from keyboard',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(() => tester.dispose());

        Map<String, dynamic>? completedAnswers;

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: FocusScope(
              child: Wizard(
                title: 'Create project',
                steps: [
                  WizardFormStep.textInput(key: 'name', prompt: 'Project name'),
                  WizardFormStep.select(
                    key: 'template',
                    prompt: 'Choose a template',
                    options: const ['console', 'package'],
                  ),
                  WizardFormStep.multiSelect(
                    key: 'features',
                    prompt: 'Select features',
                    options: const ['Testing', 'Docs'],
                    defaultSelected: const [0],
                  ),
                ],
                onCompleted: (answers) {
                  completedAnswers = answers;
                  return null;
                },
              ),
            ),
          ),
        );

        tester.sendKey('A');
        tester.sendKey('d');
        tester.sendKey('a');
        tester.sendSpecialKey(terminal_keys.KeyType.enter);

        expect(tester.find.text('Choose a template'), isTrue);

        tester.sendSpecialKey(terminal_keys.KeyType.down);
        tester.sendSpecialKey(terminal_keys.KeyType.enter);

        expect(tester.find.text('Select features'), isTrue);

        tester.sendSpecialKey(terminal_keys.KeyType.down);
        tester.sendKey(' ');
        tester.sendSpecialKey(terminal_keys.KeyType.enter);

        expect(completedAnswers, isNotNull);
        expect(completedAnswers!['name'], 'Ada');
        expect(completedAnswers!['template'], 'package');
        expect(completedAnswers!['features'], equals(['Testing', 'Docs']));
      },
    );

    test('skips conditional steps when their condition is false', () async {
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() => tester.dispose());

      Map<String, dynamic>? completedAnswers;

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.dark(),
          child: FocusScope(
            child: Wizard(
              steps: [
                WizardFormStep.confirm(
                  key: 'subscribe',
                  prompt: 'Subscribe to release emails?',
                  defaultValue: false,
                ),
                WizardFormStep.conditional(
                  step: WizardFormStep.textInput(
                    key: 'email',
                    prompt: 'Email address',
                  ),
                  condition: (answers) => answers['subscribe'] == true,
                ),
              ],
              onCompleted: (answers) {
                completedAnswers = answers;
                return null;
              },
            ),
          ),
        ),
      );

      tester.sendSpecialKey(terminal_keys.KeyType.enter);

      expect(completedAnswers, isNotNull);
      expect(completedAnswers!['subscribe'], isFalse);
      expect(completedAnswers!.containsKey('email'), isFalse);
    });

    test(
      'flattens grouped steps and restores previous text when going back',
      () async {
        final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: FocusScope(
              child: Wizard(
                title: 'Author setup',
                steps: [
                  WizardFormStep.group(
                    key: 'author',
                    title: 'Author',
                    steps: [
                      WizardFormStep.textInput(
                        key: 'name',
                        prompt: 'Author name',
                      ),
                      WizardFormStep.textInput(
                        key: 'email',
                        prompt: 'Author email',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        tester.sendKey('A');
        tester.sendKey('d');
        tester.sendKey('a');
        tester.sendSpecialKey(terminal_keys.KeyType.enter);

        expect(tester.find.text('Author email'), isTrue);

        tester.tap(tester.find.textLocation('Back'));

        expect(tester.find.text('Author name'), isTrue);
        expect(tester.view, contains('Ada'));
      },
    );

    test(
      'shows responsive exit affordances without stealing q from text input',
      () async {
        final tester = WidgetTester(screenWidth: 44, screenHeight: 18);
        addTearDown(() => tester.dispose());

        var exited = false;

        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: FocusScope(
              child: Wizard(
                steps: [
                  WizardFormStep.textInput(key: 'name', prompt: 'Project name'),
                ],
                onExit: () {
                  exited = true;
                  return null;
                },
              ),
            ),
          ),
        );

        expect(tester.find.text('Finish'), isTrue);
        expect(tester.find.text('Quit'), isTrue);
        expect(tester.find.text('enter'), isTrue);
        expect(tester.find.text('finish'), isTrue);
        expect(tester.find.text('ctrl+c'), isTrue);
        expect(tester.find.text('quit'), isTrue);

        tester.sendKey('q');

        expect(tester.view, contains('> q'));
        expect(exited, isFalse);

        tester.sendMsg(
          KeyMsg(
            terminal_keys.Key(
              terminal_keys.KeyType.runes,
              runes: const [0x63],
              ctrl: true,
            ),
          ),
        );

        expect(exited, isTrue);
      },
    );

    test('exits on runtime interrupt messages and raw ctrl+c bytes', () async {
      final tester = WidgetTester(screenWidth: 44, screenHeight: 18);
      addTearDown(() => tester.dispose());

      var exits = 0;

      Future<void> pumpWizard() async {
        await tester.pumpWidget(
          ThemeScope(
            theme: Theme.dark(),
            child: FocusScope(
              child: Wizard(
                steps: [
                  WizardFormStep.textInput(key: 'name', prompt: 'Project name'),
                ],
                onExit: () {
                  exits++;
                  return null;
                },
              ),
            ),
          ),
        );
      }

      await pumpWizard();
      tester.sendMsg(const InterruptMsg());
      expect(exits, 1);

      await pumpWizard();
      tester.sendMsg(
        KeyMsg(
          terminal_keys.Key(terminal_keys.KeyType.runes, runes: const [0x03]),
        ),
      );
      expect(exits, 2);
    });
  });
}
