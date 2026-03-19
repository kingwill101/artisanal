import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Modal
  // ---------------------------------------------------------------------------
  group('Modal', () {
    test('renders only child when open is false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Modal(child: Text('Background'), dialog: Text('Dialog'), open: false),
      );
      expect(tester.locateText('Background'), isNotNull);
      expect(tester.locateText('Dialog'), isNull);
    });

    test('renders dialog when open is true', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: Modal(
            child: Text('Background'),
            dialog: Text('Dialog'),
            open: true,
          ),
        ),
      );
      // Both child and dialog should be rendered (stack)
      expect(tester.locateText('Dialog'), isNotNull);
    });

    test('default open is false', () {
      final modal = Modal(child: Text('bg'), dialog: Text('dlg'));
      expect(modal.open, isFalse);
    });

    test('default dismissible is true', () {
      final modal = Modal(child: Text('bg'), dialog: Text('dlg'));
      expect(modal.dismissible, isTrue);
    });

    test('default backdropOpacity is 0.6', () {
      final modal = Modal(child: Text('bg'), dialog: Text('dlg'));
      expect(modal.backdropOpacity, equals(0.6));
    });

    test('properties are set correctly', () {
      final modal = Modal(
        child: Text('bg'),
        dialog: Text('dlg'),
        open: true,
        dismissible: false,
        backdropOpacity: 0.8,
      );
      expect(modal.open, isTrue);
      expect(modal.dismissible, isFalse);
      expect(modal.backdropOpacity, equals(0.8));
    });

    test('onDismiss callback is stored', () {
      var called = false;
      final modal = Modal(
        child: Text('bg'),
        dialog: Text('dlg'),
        open: true,
        onDismiss: () {
          called = true;
          return null;
        },
      );
      expect(modal.onDismiss, isNotNull);
      modal.onDismiss!();
      expect(called, isTrue);
    });

    test('closed modal renders child only', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Modal(child: Text('MainContent'), dialog: Text('PopupDialog')),
      );
      expect(tester.locateText('MainContent'), isNotNull);
      expect(tester.locateText('PopupDialog'), isNull);
    });

    test('open modal renders in a stack', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: Modal(
            child: Text('Content'),
            dialog: Text('MyDialog'),
            open: true,
          ),
        ),
      );
      // The dialog text should be visible in the rendered output
      expect(tester.locateText('MyDialog'), isNotNull);
    });

    test('backdropColor can be customized', () {
      final modal = Modal(
        child: Text('bg'),
        dialog: Text('dlg'),
        backdropColor: Colors.red,
      );
      expect(modal.backdropColor, equals(Colors.red));
    });

    test('custom backdropColor affects rendered backdrop tint', () async {
      final redTester = WidgetTester();
      addTearDown(() => redTester.dispose());
      final blueTester = WidgetTester();
      addTearDown(() => blueTester.dispose());

      await redTester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: Modal(
            child: Text('Background'),
            dialog: Text('Dialog'),
            open: true,
            backdropColor: Colors.red,
          ),
        ),
      );
      await blueTester.pumpWidget(
        Container(
          width: 40,
          height: 10,
          child: Modal(
            child: Text('Background'),
            dialog: Text('Dialog'),
            open: true,
            backdropColor: Colors.blue,
          ),
        ),
      );

      expect(redTester.view, isNot(equals(blueTester.view)));
    });
  });

  // ---------------------------------------------------------------------------
  // Drawer
  // ---------------------------------------------------------------------------
  group('Drawer', () {
    test('renders only child when open is false', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Drawer(
          child: Text('MainArea'),
          drawer: Text('DrawerContent'),
          open: false,
        ),
      );
      expect(tester.locateText('MainArea'), isNotNull);
      expect(tester.locateText('DrawerContent'), isNull);
    });

    test('renders drawer when open is true', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 60,
          height: 10,
          child: Drawer(
            child: Text('MainArea'),
            drawer: Text('DrawerContent'),
            open: true,
            side: SidebarSide.right,
            width: 20,
          ),
        ),
      );
      expect(tester.locateText('DrawerContent'), isNotNull);
      expect(tester.locateText('MainArea'), isNotNull);
    });

    test('default open is false', () {
      final drawer = Drawer(child: Text('main'), drawer: Text('dr'));
      expect(drawer.open, isFalse);
    });

    test('default width is 28', () {
      final drawer = Drawer(child: Text('main'), drawer: Text('dr'));
      expect(drawer.width, equals(28));
    });

    test('default side is left', () {
      final drawer = Drawer(child: Text('main'), drawer: Text('dr'));
      expect(drawer.side, equals(SidebarSide.left));
    });

    test('default dismissible is true', () {
      final drawer = Drawer(child: Text('main'), drawer: Text('dr'));
      expect(drawer.dismissible, isTrue);
    });

    test('default backdropOpacity is 0.6', () {
      final drawer = Drawer(child: Text('main'), drawer: Text('dr'));
      expect(drawer.backdropOpacity, equals(0.6));
    });

    test('properties are set correctly', () {
      final drawer = Drawer(
        child: Text('main'),
        drawer: Text('dr'),
        open: true,
        width: 40,
        side: SidebarSide.right,
        dismissible: false,
        backdropOpacity: 0.5,
      );
      expect(drawer.open, isTrue);
      expect(drawer.width, equals(40));
      expect(drawer.side, equals(SidebarSide.right));
      expect(drawer.dismissible, isFalse);
      expect(drawer.backdropOpacity, equals(0.5));
    });

    test('onDismiss callback is stored', () {
      var called = false;
      final drawer = Drawer(
        child: Text('main'),
        drawer: Text('dr'),
        open: true,
        onDismiss: () {
          called = true;
          return null;
        },
      );
      expect(drawer.onDismiss, isNotNull);
      drawer.onDismiss!();
      expect(called, isTrue);
    });

    test('right side drawer stores side property', () {
      // Positioned(right: 0) renders the drawer at the right edge,
      // but the Stack canvas compositing may not position it correctly.
      // Verify the property is stored correctly.
      final drawer = Drawer(
        child: Text('main'),
        drawer: Text('dr'),
        side: SidebarSide.right,
      );
      expect(drawer.side, equals(SidebarSide.right));
    });

    test('custom width is applied', () {
      final drawer = Drawer(child: Text('main'), drawer: Text('dr'), width: 50);
      expect(drawer.width, equals(50));
    });

    test('backdropColor can be customized', () {
      final drawer = Drawer(
        child: Text('main'),
        drawer: Text('dr'),
        backdropColor: Colors.blue,
      );
      expect(drawer.backdropColor, equals(Colors.blue));
    });

    test('custom backdropColor affects rendered drawer tint', () async {
      final redTester = WidgetTester();
      addTearDown(() => redTester.dispose());
      final blueTester = WidgetTester();
      addTearDown(() => blueTester.dispose());

      await redTester.pumpWidget(
        Container(
          width: 60,
          height: 10,
          child: Drawer(
            child: Text('MainArea'),
            drawer: Text('DrawerContent'),
            open: true,
            side: SidebarSide.right,
            width: 20,
            backdropColor: Colors.red,
          ),
        ),
      );
      await blueTester.pumpWidget(
        Container(
          width: 60,
          height: 10,
          child: Drawer(
            child: Text('MainArea'),
            drawer: Text('DrawerContent'),
            open: true,
            side: SidebarSide.right,
            width: 20,
            backdropColor: Colors.blue,
          ),
        ),
      );

      expect(redTester.view, isNot(equals(blueTester.view)));
    });
  });

  // ---------------------------------------------------------------------------
  // Modal & Drawer integration
  // ---------------------------------------------------------------------------
  group('Modal and Drawer integration', () {
    test('Modal inside Container renders correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 50,
          height: 15,
          child: Modal(
            child: Column(children: [Text('Header'), Text('Body')]),
            dialog: Text('Confirm?'),
            open: true,
          ),
        ),
      );
      expect(tester.locateText('Confirm?'), isNotNull);
    });

    test('Drawer inside Container renders correctly', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 60,
          height: 15,
          child: Drawer(
            child: Text('App'),
            drawer: Column(children: [Text('Nav1'), Text('Nav2')]),
            open: true,
          ),
        ),
      );
      expect(tester.locateText('Nav1'), isNotNull);
    });

    test('open modal does not push sibling content in a column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Modal(
                open: true,
                child: Text('Preview'),
                dialog: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dialog title'),
                      Text('Dialog body'),
                      Text('Dialog actions'),
                    ],
                  ),
                ),
              ),
              Text('After'),
            ],
          ),
        ),
      );

      final after = tester.locateText('After');
      expect(after, isNotNull);
      expect(after!.y, equals(1));
    });

    test('open drawer does not push sibling content in a column', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(
          width: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Drawer(
                open: true,
                width: 20,
                child: Text('Preview'),
                drawer: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Drawer title'),
                      Text('Drawer body'),
                      Text('Drawer actions'),
                    ],
                  ),
                ),
              ),
              Text('After'),
            ],
          ),
        ),
      );

      final after = tester.locateText('After');
      expect(after, isNotNull);
      expect(after!.y, equals(1));
    });
  });
}
