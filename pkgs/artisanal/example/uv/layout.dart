import 'package:artisanal/uv.dart';
import 'package:artisanal/style.dart';
import 'dart:io';
import 'dart:math';

void main() async {
  final t = Terminal();
  if (!stdin.hasTerminal) {
    print('Not a TTY');
    return;
  }

  await t.start();
  t.enterAltScreen();
  t.enableMouse();
  t.hideCursor();

  try {
    final size = await t.getSize();
    var width = size.width;

    // Colors
    final subtle = Colors.gray;
    final highlight = Colors.purple;
    final special = Colors.pink;

    // Styles
    final tab = Style().foreground(subtle).padding(0, 1);

    final activeTab = tab
        .copy()
        .bold()
        .foreground(highlight)
        .border(Border.rounded)
        .borderSides(
          const BorderSides(top: true, left: true, right: true, bottom: false),
        );

    final tabGap = Style()
        .border(Border.normal)
        .borderSides(const BorderSides(bottom: true));

    final titleStyle = Style()
        .margin(0, 0, 1, 2)
        .padding(0, 1)
        .italic()
        .foreground(Colors.white);

    final descStyle = Style().margin(1, 2);

    final infoStyle = Style()
        .border(Border.normal)
        .borderSides(const BorderSides(left: true))
        .padding(0, 1)
        .margin(0, 2);

    final dialogBoxStyle = Style()
        .border(Border.rounded)
        .borderForeground(highlight)
        .padding(1, 0)
        .borderSides(BorderSides.all)
        .align(HorizontalAlign.center);

    final buttonStyle = Style()
        .foreground(Colors.white)
        .background(Colors.gray700)
        .padding(0, 3)
        .margin(0, 1);

    final activeButtonStyle = buttonStyle
        .copy()
        .foreground(Colors.white)
        .background(special)
        .margin(0, 1)
        .underline();

    final listStyle = Style()
        .border(Border.normal)
        .borderSides(const BorderSides(left: true))
        .padding(0, 1)
        .margin(1, 2);

    final listHeaderStyle = Style()
        .bold()
        .italic()
        .foreground(highlight)
        .margin(0, 0, 1, 0);

    final listItemStyle = Style().padding(0, 0, 0, 1);

    final listDoneStyle = Style()
        .foreground(subtle)
        .strikethrough()
        .padding(0, 0, 0, 1);

    final historyStyle = Style()
        .width(24)
        .align(HorizontalAlign.left)
        .margin(1, 3, 0, 0);

    final statusBarStyle = Style()
        .background(Colors.gray800)
        .foreground(Colors.white);

    final statusStyle = Style()
        .bold()
        .background(highlight)
        .foreground(Colors.white)
        .padding(0, 1)
        .margin(0, 1, 0, 0);

    final encodingStyle = Style()
        .background(Colors.gray700)
        .foreground(Colors.white)
        .padding(0, 1);

    final statusText = Style().foreground(Colors.gray400);

    final fishCakeStyle = Style()
        .background(Colors.hex('#6124DF'))
        .foreground(Colors.white)
        .padding(0, 1);

    final docStyle = Style().padding(1, 2, 1, 2);

    Future<void> render() async {
      final size = await t.getSize();
      width = size.width;

      final doc = StringBuffer();

      // Tabs
      {
        final tabs = Layout.joinHorizontal(VerticalAlign.bottom, [
          activeTab.render('Lip Gloss'),
          tab.render('Blush'),
          tab.render('Eye Shadow'),
          tab.render('Mascara'),
          tab.render('Foundation'),
        ]);

        final rowWidth = Layout.visibleLength(tabs);
        final gapWidth = max(
          0,
          width - rowWidth - 4,
        ); // -4 for docStyle padding
        final gap = tabGap.render(' ' * gapWidth);

        doc.writeln(Layout.joinHorizontal(VerticalAlign.bottom, [tabs, gap]));
        doc.writeln();
      }

      // Title & Description
      {
        final title = titleStyle
            .copy()
            .background(Colors.hex('#7D56F4'))
            .render('Lip Gloss');

        final desc = Layout.joinVertical(HorizontalAlign.left, [
          descStyle.render('Style Definitions for Nice Terminal Layouts'),
          infoStyle.render(
            'From Charm: https://github.com/charmbracelet/lipgloss',
          ),
        ]);

        doc.writeln(Layout.joinHorizontal(VerticalAlign.top, [title, desc]));
        doc.writeln();
      }

      // Dialog
      {
        final question = Style()
            .width(50)
            .align(HorizontalAlign.center)
            .render('Are you sure you want to eat marmalade?');

        final buttons = Layout.joinHorizontal(VerticalAlign.top, [
          activeButtonStyle.render('Yes'),
          buttonStyle.render('Maybe'),
        ]);

        final dialogUI = Layout.joinVertical(HorizontalAlign.center, [
          question,
          buttons,
        ]);

        final dialog = Layout.place(
          width: width - 4,
          height: 9,
          horizontal: HorizontalAlign.center,
          vertical: VerticalAlign.center,
          content: dialogBoxStyle.render(dialogUI),
        );

        doc.writeln(dialog);
        doc.writeln();
      }

      // Lists
      {
        final list1 = Layout.joinVertical(HorizontalAlign.left, [
          listHeaderStyle.render('Citrus Fruits to Try'),
          listDoneStyle.render('Grapefruit'),
          listDoneStyle.render('Yuzu'),
          listItemStyle.render('Citron'),
          listItemStyle.render('Kumquat'),
          listItemStyle.render('Pomelo'),
        ]);

        final list2 = Layout.joinVertical(HorizontalAlign.left, [
          listHeaderStyle.render('Actual Lip Gloss Vendors'),
          listItemStyle.render('Glossier'),
          listItemStyle.render('Claire‘s Boutique'),
          listDoneStyle.render('Nyx'),
          listItemStyle.render('Mac'),
          listDoneStyle.render('Milk'),
        ]);

        doc.writeln(
          Layout.joinHorizontal(VerticalAlign.top, [
            listStyle.render(list1),
            listStyle.render(list2),
          ]),
        );
        doc.writeln();
      }

      // History
      {
        final historyA =
            'The Romans learned from the Greeks that quinces slowly cooked with honey would “set” when cool.';
        final historyB =
            'Medieval quince preserves, which went by the French name cotignac, produced in a clear version.';
        final historyC =
            'In 1524, Henry VIII, King of England, received a “box of marmalade” from Mr. Hull of Exeter.';

        doc.writeln(
          Layout.joinHorizontal(VerticalAlign.top, [
            historyStyle.copy().align(HorizontalAlign.right).render(historyA),
            historyStyle.copy().align(HorizontalAlign.center).render(historyB),
            historyStyle.copy().render(historyC),
          ]),
        );
        doc.writeln();
      }

      // Status Bar
      {
        final statusKey = statusStyle.render('STATUS');
        final encoding = encodingStyle.render('UTF-8');
        final fishCake = fishCakeStyle.render('🍥 Fish Cake');

        final usedWidth =
            Layout.visibleLength(statusKey) +
            Layout.visibleLength(encoding) +
            Layout.visibleLength(fishCake);

        final statusVal = statusText
            .copy()
            .width(max(0, width - usedWidth - 4))
            .render('Ravishingly Dark!');

        final bar = Layout.joinHorizontal(VerticalAlign.top, [
          statusKey,
          statusVal,
          encoding,
          fishCake,
        ]);

        doc.writeln(statusBarStyle.copy().width(width - 4).render(bar));
      }

      final mainDoc = docStyle.render(doc.toString());
      final ss = StyledString(mainDoc);

      t.clear();
      ss.draw(t, t.bounds());
      t.draw();
    }

    await render();

    await for (final event in t.events) {
      if (event is KeyPressEvent) {
        final key = event.keystroke();
        if (key == 'q' || key == 'esc' || key == 'ctrl+c') {
          break;
        }
      }
      if (event is WindowSizeEvent) {
        await render();
      }
    }
  } finally {
    t.exitAltScreen();
    t.showCursor();
    t.stop();
  }
}
