/// Dialog / palette search fields should autofocus over background prompts.
library;

import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  test('dialog TextField autofocus steals focus from background field', () async {
    final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      ThemeScope(
        theme: Theme.dark(),
        child: Navigator(
          onGenerateRoute: (settings) {
            if (settings.name == '/dialog') {
              return null;
            }
            return PageRoute<void>(
              builder: (context) => Column(
                children: [
                  TextField(
                    focusId: 'background-prompt',
                    autofocus: true,
                    placeholder: 'background',
                  ),
                  Button(
                    onPressed: () {
                      Navigator.of(context).showDialog<void>(
                        builder: (_) => SizedBox(
                          width: 40,
                          height: 10,
                          child: Column(
                            children: [
                              Text('dialog'),
                              TextField(
                                focusId: 'dialog-search',
                                autofocus: true,
                                placeholder: 'Search sessions...',
                              ),
                            ],
                          ),
                        ),
                      );
                      return null;
                    },
                    child: Text('open'),
                  ),
                ],
              ),
            );
          },
          initialRoute: '/',
        ),
      ),
    );
    tester.pump();

    // Background field starts focused.
    tester.sendKey('x');
    expect(tester.view.contains('x'), isTrue, reason: tester.view);

    final open = tester.locateText('open');
    expect(open, isNotNull, reason: tester.view);
    tester.tapAt(open!.x, open.y);
    tester.pump();

    expect(tester.find.text('dialog'), isTrue, reason: tester.view);

    // Typing should go to dialog search (not only append on the buried prompt).
    tester.sendKey('q');
    expect(tester.view.contains('q'), isTrue, reason: tester.view);
  });

  test('FocusController trap clears outside focus for autofocus', () {
    final controller = FocusController();
    controller.register('outer-scope', focusable: false);
    controller.register('prompt', parentId: 'outer-scope');
    controller.register(
      'dialog-scope',
      parentId: 'outer-scope',
      focusable: false,
    );
    controller.register('search', parentId: 'dialog-scope');

    controller.requestFocus('prompt');
    expect(controller.focusedId, 'prompt');

    controller.setTrap('outer-scope');
    controller.setTrap('dialog-scope');
    expect(controller.focusedId, isNull, reason: 'outside trap must clear');

    final ok = controller.requestFocus('search');
    expect(ok, isTrue);
    expect(controller.focusedId, 'search');

    // Deny focus back to prompt while dialog trap is active.
    expect(controller.requestFocus('prompt'), isFalse);
    expect(controller.focusedId, 'search');

    controller.setTrap(null); // pop dialog
    expect(controller.trapId, 'outer-scope');
    controller.setTrap(null); // pop outer
    expect(controller.trapId, isNull);
  });
}
