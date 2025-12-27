import 'package:artisanal/artisanal.dart';
import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/uv.dart';

// #region enabling_uv_example
void runWithUv() async {
  final program = Program(
    const CounterModel(),
    // Ultraviolet is enabled by default.
  );
  await program.run();
}
// #endregion

// #region compositor_layers_example
void compositorLayers() {
  final compositor = Compositor();
  // Note: backgroundLayer, myBackground, etc. are placeholders for the example
  final backgroundLayer = newLayer('Background');

  compositor.addLayers([backgroundLayer]);
  compositor.addLayers([
    newLayer('Popup')
        .setId('popup')
        .setX(10)
        .setY(5)
        .setZ(100), // Higher Z-index renders on top
  ]);
}
// #endregion

// #region custom_msg_example
class IncrementMsg extends Msg {
  const IncrementMsg();
}

class UserDataReceivedMsg extends Msg {
  final String data;
  const UserDataReceivedMsg(this.data);
}
// #endregion

// #region custom_cmd_example
Cmd fetchData() {
  return Cmd(() async {
    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));
      return const UserDataReceivedMsg('Some data');
    } catch (e) {
      return null; // Or an ErrorMsg
    }
  });
}
// #endregion

// #region batch_cmd_example
Cmd batchExample() {
  return Cmd.batch([
    fetchData(),
    Cmd.tick(Duration(seconds: 5), (t) => const IncrementMsg()),
  ]);
}
// #endregion

// #region program_options_example
void runWithOpts() async {
  await runProgram(
    const CounterModel(),
    options: ProgramOptions(
      altScreen: true, // Use the alternate screen buffer
    ),
  );
}
// #endregion

// #region theme_usage_example
void themeUsage() {
  final theme = ThemePalette.dark;

  final titleStyle = Style()
      .foreground(theme.accent)
      .background(theme.background ?? Colors.none)
      .bold();

  final errorStyle = Style().foreground(theme.error);
  titleStyle.render('Title');
  errorStyle.render('Error');
}
// #endregion

// #region basic_color_example
final red = Colors.red;
final brightBlue = Colors.blue;
// #endregion

// #region ansi_color_example
final orange = Colors.ansi(208);
// #endregion

// #region renderer_usage_example
void rendererUsage(Console console) {
  // The high-level Renderer is used by Console and Style
  final style = Style().foreground(Colors.blue).bold();

  // Render a styled string to the console
  console.write(style.render('Hello, Artisanal!'));

  // You can also use a StringRenderer to capture output
  final stringRenderer = StringRenderer();
  final output = style.renderTo(stringRenderer, 'Captured text');
  print('Captured: $output');
}
// #endregion

// #region uv_metrics_example
void checkMetrics(UvTerminalRenderer renderer) {
  // Access performance metrics from the UV renderer
  print('Current FPS: ${renderer.metrics.averageFps}');
  print('Render Summary: ${renderer.metrics.summary()}');
}
// #endregion

// #region tui_renderer_options_example
void customRenderer() async {
  final program = Program(
    const CounterModel(),
    options: ProgramOptions(
      // Ultraviolet is the default renderer and input decoder
      // useUltravioletRenderer: true,
      // useUltravioletInputDecoder: true,

      // To use the simpler FullScreenTuiRenderer instead:
      // useUltravioletRenderer: false,

      // Run in inline mode (doesn't take over the screen)
      altScreen: false,
    ),
  );
  await program.run();
}
// #endregion

// #region true_color_example
final custom = Colors.rgb(255, 100, 50);
final hex = Colors.hex('#ff6432');
// #endregion

// #region adaptive_color_example
final text = AdaptiveColor(light: Colors.black, dark: Colors.white);
// #endregion

// #region custom_theme_example
final myTheme = ThemePalette(
  accent: Colors.hex('#ff00ff'),
  accentBold: Colors.hex('#ff00ff'),
  text: Colors.white,
  textDim: Colors.gray,
  textBold: Colors.white,
  border: Colors.gray,
  success: Colors.green,
  warning: Colors.yellow,
  error: Colors.red,
  info: Colors.blue,
  highlight: Colors.purple,
  background: Colors.black,
);
// #endregion

// #region join_horizontal_example
String horizontalLayout() {
  final style1 = Style().foreground(Colors.red);
  final style2 = Style().foreground(Colors.blue);

  return Layout.joinHorizontal(VerticalAlign.top, [
    style1.render('Left'),
    style2.render('Right'),
  ]);
}
// #endregion

// #region join_vertical_example
String verticalLayout() {
  return Layout.joinVertical(HorizontalAlign.center, [
    'Header',
    'Content',
    'Footer',
  ]);
}
// #endregion

// #region alignment_usage_example
void alignmentUsage() {
  final box = Style()
      .width(20)
      .height(5)
      .align(HorizontalAlign.center)
      .alignVertical(VerticalAlign.center)
      .border(Border.normal);

  print(box.render('Centered Text'));
}
// #endregion

// #region stack_example
void stackUsage() {
  final background = Style()
      .width(20)
      .height(5)
      .background(Colors.blue)
      .render('');

  final foreground = Style().bold().foreground(Colors.white).render('Overlay');

  // Stack foreground on top of background
  final stacked = Style.stack([background, foreground]);
  print(stacked);
}
// #endregion

// #region custom_border_example
final customBorder = Border(
  top: '-',
  bottom: '-',
  left: '|',
  right: '|',
  topLeft: '+',
  topRight: '+',
  bottomLeft: '+',
  bottomRight: '+',
);
// #endregion

// #region lipgloss_list_example
void lipglossList() {
  final list = LipList.create([
    'First item',
    'Second item',
    'Third item',
  ]).enumerator(ListEnumerators.bullet);

  print(list.render());
}
// #endregion

// #region lipgloss_table_example
void lipglossTable() {
  final table = Table()
      .headers(['ID', 'Name', 'Status'])
      .row(['1', 'Kasm', 'Running'])
      .row(['2', 'Vault', 'Stopped'])
      .border(Border.rounded)
      .padding(1);

  print(table.render());
}
// #endregion

// #region console_output_example
void consoleOutput() {
  final console = Console();

  console.write('Hello');
  console.writeln('World');
}
// #endregion

// #region console_task_example
void consoleTask() async {
  final console = Console();
  await console.task(
    'Downloading data...',
    run: () async {
      await Future.delayed(Duration(seconds: 2));
      return TaskResult.success;
    },
  );
}
// #endregion

// #region verbosity_usage_example
void verbosityUsage() {
  final console = Console(verbosity: Verbosity.verbose);

  console.write('Normal message'); // Always shown unless quiet
}
// #endregion

// #region program_direct_usage_example
void runProgramDirect() async {
  final program = Program(const CounterModel());
  await program.run();
}
// #endregion

// #region global_verbosity_example
void setGlobalVerbosity() {
  // Verbosity control is usually via Console or global settings
}
// #endregion

// #region console_components_example
void consoleComponents() async {
  final console = Console();
  // Components are available on the console
  console.write('');
}
// #endregion

// #region hyperlink_style_example
final linkStyle = Style()
    .foreground(Colors.blue)
    .underline()
    .hyperlink("https://github.com/kingwill101/ormed");
// #endregion

// #region styled_view_example
String styledView() {
  final style = Style().foreground(Colors.blue).bold();
  return style.render('Hello, Styled World!');
}
// #endregion

// #region layout_view_example
String layoutView() {
  return Layout.joinVertical(HorizontalAlign.center, [
    'Header',
    Layout.joinHorizontal(VerticalAlign.top, ['Left Column', 'Right Column']),
    'Footer',
  ]);
}
// #endregion

// #region layer_example
final layer = newLayer('Sidebar').setId('sidebar').setX(0).setY(0).setZ(10);
// #endregion

// #region compositor_example
void compositorUsage() {
  final compositor = Compositor();

  // Add layers (placeholders for example)
  final backgroundLayer = newLayer('Background');
  final sidebarLayer = newLayer('Sidebar');
  final modalLayer = newLayer('Modal');
  final targetBuffer = Buffer.create(80, 24);
  targetBuffer.touch(0, 0);

  compositor.addLayers([backgroundLayer, sidebarLayer, modalLayer]);

  // Render all layers into a target buffer
  // Note: Compositor implements Drawable, so it can be drawn to a Screen
  // compositor.draw(screen, area);
}
// #endregion

// #region canvas_example
String drawCanvas() {
  final canvas = Canvas(160, 100);
  // Canvas is a ScreenBuffer that can be drawn to
  canvas.setCell(0, 0, Cell(content: 'X'));

  // Render canvas to a string
  return canvas.render();
}
// #endregion

// #region half_block_example
String drawHalfBlock() {
  // HalfBlockImageDrawable can be used for images
  // final hb = HalfBlockImageDrawable(image);
  return '';
}
// #endregion

class CounterModel implements Model {
  const CounterModel();
  @override
  Cmd? init() => null;
  @override
  (Model, Cmd?) update(Msg msg) => (this, null);
  @override
  String view() => '';
}
